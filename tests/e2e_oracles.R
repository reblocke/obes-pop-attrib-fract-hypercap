# Independent expectations for the public artificial analysis/report run.
# Failure rationale is in tests/README.md; no production selection or prediction
# helper is used to calculate the expected numerical results below.
e2e_near <- function(actual, expected, tolerance=1e-7) {
  if (!isTRUE(all.equal(as.numeric(actual), as.numeric(expected), tolerance=tolerance)))
    stop("Independent numerical expectation differs")
}

e2e_indexes <- function(raw) {
  d <- unique(raw)
  eligible <- d$encounter_date >= as.Date("2022-01-01") &
    d$encounter_date < as.Date("2023-01-01") & d$age_at_encounter >= 18 &
    ifelse(is.na(d$encounter_type), NA, d$encounter_type %in% c("EMER", "IMP")) &
    ifelse(d$bmi_evidence_state == "missing", FALSE, d$bmi >= 30)
  selected <- integer()
  for (rows in split(seq_len(nrow(d)), d$patient_id)) {
    confirmed <- rows[eligible[rows] %in% TRUE]
    if (!length(confirmed)) next
    first <- min(d$encounter_date[confirmed])
    candidate <- confirmed[d$encounter_date[confirmed] == first]
    uncertain <- rows[is.na(eligible[rows])]
    if (length(candidate) != 1L || any(is.na(d$encounter_date[uncertain]) |
        d$encounter_date[uncertain] <= first)) next
    selected <- c(selected, candidate)
  }
  q <- d[selected, , drop=FALSE]
  other <- as.matrix(q[paste0(c("ABG", "VBG", "RESPFAIL", "VENTSUPPORT", "PREDISPOSITION"), "_rfs")])
  positive <- rowSums(other == 1, na.rm=TRUE) > 0
  zero <- rowSums(other == 0, na.rm=TRUE) == 5
  q$group <- ifelse(positive, "primary", ifelse(q$OBESITY_rfs %in% 1 & zero, "obesity_only", "unresolved"))
  q$current <- q$bmi_method == "current" & q$reported_date >= q$encounter_date |
    grepl("^calculated", q$bmi_method) & q$height_date >= q$encounter_date & q$weight_date >= q$encounter_date
  for (window in c("encounter", "index_calendar_day")) {
    suffix <- if (window == "encounter") "" else "_index_day"
    arterial <- q[[paste0("abg_pco2", suffix)]]
    venous <- q[[paste0("vbg_pco2", suffix)]]
    q[[paste0("abg_", window)]] <- ifelse(is.na(arterial), NA_integer_, as.integer(arterial >= 45))
    q[[paste0("any_gas_", window)]] <- ifelse((arterial >= 45 | venous >= 50) %in% TRUE,
      1L, ifelse(!is.na(arterial) | !is.na(venous), 0L, NA_integer_))
    q[[paste0("vbg_", window)]] <- ifelse(is.na(venous), NA_integer_, as.integer(venous >= 50))
  }
  q$icd_encounter <- q$icd_hypercapnia
  q
}

e2e_model_ids <- function(config) {
  expected <- character()
  for (group in unlist(config$analysis_populations)) {
    keys <- paste(c("abg", "any_gas", "icd"), "encounter", "spline", sep="/")
    if (group %in% unlist(config$full_model_populations)) {
      keys <- c(keys, paste(c("abg", "any_gas", "icd"), "encounter", "linear", sep="/"),
        unlist(lapply(c("spline", "linear"), function(form)
          paste(c("abg", "any_gas"), "index_calendar_day", form, sep="/"))),
        paste("observation", c("abg", "vbg", "any_gas", "icd"), "encounter", sep="/"),
        paste("observation", c("abg", "vbg", "any_gas"), "index_calendar_day", sep="/"),
        c("matched/abg/icd", "matched/abg/abg", "matched/any_gas/icd", "matched/any_gas/any_gas"))
    }
    expected <- c(expected, paste0(group, "::", keys))
  }
  expected
}

e2e_saved_values <- function(bundle, raw) {
  a <- bundle$analysis; config <- bundle$config; q <- e2e_indexes(raw)
  complete <- complete.cases(q[c("bmi", "age_at_encounter", "sex", "race_ethnicity", "location")])
  c <- q[complete, , drop=FALSE]
  e2e_near(a$cohort_nodes$n[a$cohort_nodes$population_id == "combined::Q"], nrow(q))
  for (group in c("primary", "obesity_only", "unresolved")) {
    z <- a$rfs_summary[a$rfs_summary$population_id == group, ]
    e2e_near(z$n, sum(q$group == group)); e2e_near(z$complete, sum(c$group == group))
  }
  stopifnot(setequal(a$model_registry$model_id, e2e_model_ids(config)),
    !anyDuplicated(a$model_registry$model_id), !any(grepl("^(combined|obesity_only)::", a$model_registry$model_id)))
  curves_all <- rbind(a$probability_curves,a$observation_curves)
  stopifnot(setequal(curves_all$model_id,e2e_model_ids(config)))
  policy_models <- e2e_model_ids(config)
  policy_models <- policy_models[grepl("/spline$|::matched/",policy_models) & !grepl("::observation/",policy_models)]
  enabled <- vapply(Filter(function(x)isTRUE(x$enabled),config$policies),`[[`,character(1),"policy_id")
  expected_policies <- as.vector(outer(policy_models,enabled,paste,sep="|"))
  actual_policies <- paste(a$policy_totals$model_id,a$policy_totals$policy_id,sep="|")
  stopifnot(setequal(actual_policies,expected_policies),!anyDuplicated(actual_policies))
  fitted <- list()
  for (i in seq_len(nrow(a$model_registry))) {
    row <- a$model_registry[i, ]; parts <- strsplit(row$model_id, "::", fixed=TRUE)[[1]]
    group <- parts[1]; key <- strsplit(parts[2], "/", fixed=TRUE)[[1]]
    form <- if(key[1] %in% c("observation","matched"))"spline"else key[3]
    outcome <- if(key[1]=="observation")key[2]else if(key[1]=="matched")key[3]else key[1]
    window <- if(key[1]=="matched")"encounter"else if(key[1]=="observation")key[3]else key[2]
    stopifnot(row$model_form==form,row$outcome_id==outcome,row$window==window)
    d <- c[if (group == "all_obesity") c$OBESITY_rfs %in% 1 else c$group == "primary", , drop=FALSE]
    if (group == "primary_current") d <- d[d$current %in% TRUE, , drop=FALSE]
    reference <- if (group == "primary_current") c[c$group == "primary", , drop=FALSE] else d
    knots <- as.numeric(quantile(reference$bmi, unlist(config$knot_probabilities), type=config$quantile_type))
    saved <- a$bmi_basis[a$bmi_basis$analysis_population_id == group, ]
    e2e_near(saved$knot, knots)
    if (key[1] == "observation") {
      d$y <- as.integer(!is.na(d[[paste(key[2], key[3], sep="_")]]))
    } else if (key[1] == "matched") {
      d <- d[!is.na(d$icd_encounter) & !is.na(d[[paste0(key[2], "_encounter")]]), , drop=FALSE]
      d$y <- d[[paste0(key[3], "_encounter")]]
    } else {
      d$y <- d[[paste(key[1], key[2], sep="_")]]
      d <- d[!is.na(d$y), , drop=FALSE]
    }
    e2e_near(c(row$n_model, row$n_events, row$n_nonevents), c(nrow(d), sum(d$y), sum(d$y == 0)))
    curves <- curves_all[curves_all$model_id==row$model_id,]
    z <- a$policy_totals[a$policy_totals$model_id==row$model_id,]
    failure <- if(!nrow(d))"no_evaluable_sample"else if(length(unique(d$y))<2)"constant_outcome"else NULL
    if(is.null(failure) && form=="spline" && (anyNA(knots)||anyDuplicated(knots)))failure <- "rank_deficiency"
    for (name in c("sex", "race_ethnicity", "location")) {
      levels <- sort(unique(d[[name]])); ref <- config$factor_references[[name]]
      if(is.null(failure) && !ref %in% levels)failure <- "rank_deficiency"
      d[[name]] <- factor(d[[name]], levels=c(ref, setdiff(levels, ref)))
    }
    add_basis <- function(data) {
      if (form == "spline") {
        ns <- splines::ns(data$bmi, knots=knots[2:3], Boundary.knots=knots[c(1,4)])
        for (j in 1:3) data[[paste0("bmi_ns", j)]] <- ns[,j]
      }
      data
    }
    formula <- as.formula(paste("y ~", if (form == "spline") "bmi_ns1 + bmi_ns2 + bmi_ns3" else "bmi",
      "+ age_at_encounter + sex + race_ethnicity + location"))
    if(is.null(failure)) {
      x <- tryCatch(model.matrix(formula,add_basis(d)),error=function(e)NULL)
      if(is.null(x)||qr(x)$rank<ncol(x)||nrow(x)<=ncol(x))failure <- "rank_deficiency"
    }
    if(is.null(failure)) {
      # Independent feasibility formulation: all signed margins nonnegative,
      # their sum exactly one. Unlike the estimator's bounded maximization,
      # this asks whether any strict positive margin is possible at all.
      margin <- x*(2*d$y-1); positive_negative <- cbind(margin,-margin)
      result <- lpSolve::lp("min",rep(1,2*ncol(x)),
        rbind(positive_negative,colSums(positive_negative)),c(rep(">=",nrow(x)),"="),c(rep(0,nrow(x)),1))
      stopifnot(result$status %in% c(0,2))
      if(result$status==0)failure <- "separation"
    }
    if(is.null(failure)) {
      fit <- suppressWarnings(glm(formula,data=add_basis(d),family=binomial(),na.action=na.fail,
        control=glm.control(maxit=config$maxit),
        contrasts=list(sex="contr.treatment",race_ethnicity="contr.treatment",location="contr.treatment")))
      if(!fit$converged||fit$boundary)failure <- "convergence_failure"
    }
    if(!is.null(failure)) {
      stopifnot(row$status==failure,nzchar(row$failure_reason),nrow(curves)==1L,
        all(is.na(curves$probability)),all(is.na(curves$conf_low)),all(is.na(curves$conf_high)),
        all(curves$status==failure),all(z$status==failure))
      fitted[[row$model_id]] <- data.frame(model_id=row$model_id,n_model=nrow(d),coefficients=0L,
        curve_points=1L,paired_scenarios=nrow(z),status=paste("independently confirmed",failure))
      next
    }
    stopifnot(row$status %in% c("successful","fitted_with_concerns"))
    cf <- a$coefficients[a$coefficients$model_id == row$model_id & a$coefficients$status == "estimated", ]
    stopifnot(setequal(cf$term,names(coef(fit))),!anyDuplicated(cf$term))
    e2e_near(cf$estimate[match(names(coef(fit)), cf$term)], coef(fit))
    cv <- a$coefficient_covariance[a$coefficient_covariance$model_id == row$model_id, ]
    pairs <- as.vector(outer(names(coef(fit)),names(coef(fit)),paste,sep="|"))
    actual <- paste(cv$term1,cv$term2,sep="|")
    stopifnot(length(actual)==length(pairs),!anyDuplicated(actual),setequal(actual,pairs))
    e2e_near(cv$covariance, vcov(fit)[cbind(match(cv$term1, names(coef(fit))), match(cv$term2, names(coef(fit))))])
    matrix_for <- function(data) model.matrix(delete.response(terms(fit)), add_basis(data), contrasts.arg=fit$contrasts)
    x0 <- matrix_for(d); shifted <- d; shifted$bmi <- ifelse(d$bmi > 30, d$bmi-1, d$bmi)
    x1 <- matrix_for(shifted)
    beta <- coef(fit); covariance <- vcov(fit)
    means <- function(beta) c(mean(plogis(drop(x0 %*% beta))), mean(plogis(drop(x1 %*% beta))))
    # Numerical derivatives avoid reusing the implementation's analytic gradient.
    eps <- 1e-6
    gradient <- vapply(seq_along(beta), function(j) {
      delta <- rep(0, length(beta)); delta[j] <- eps
      (means(beta+delta)-means(beta-delta))/(2*eps)
    }, numeric(2))
    probabilities <- means(beta); g0 <- gradient[1, ]; g1 <- gradient[2, ]
    variance <- function(g) drop(t(g) %*% covariance %*% g)
    probability_ci <- function(p, g) plogis(qlogis(p) + c(-1,1)*qnorm(.975)*sqrt(variance(g/(p*(1-p)))))
    if (nrow(z)) {
      stopifnot(nrow(z)==1L,z$status=="estimated")
      p0 <- probabilities[1]; p1 <- probabilities[2]
      absolute_ci <- p0-p1+c(-1,1)*qnorm(.975)*sqrt(variance(g0-g1))
      pif_ci <- 1-exp(log(p1/p0)+c(1,-1)*qnorm(.975)*sqrt(variance(g1/p1-g0/p0)))
      e2e_near(c(z$p_observed, z$p_shifted, z$absolute_difference, z$PIF), c(p0, p1, p0-p1, 1-p1/p0))
      e2e_near(c(z$p_observed_low, z$p_observed_high), probability_ci(p0, g0))
      e2e_near(c(z$p_shifted_low, z$p_shifted_high), probability_ci(p1, g1))
      e2e_near(c(z$difference_low_per1000, z$difference_high_per1000), 1000*absolute_ci, 1e-6)
      e2e_near(c(z$PIF_low, z$PIF_high), pif_ci, 1e-6)
      e2e_near(c(z$n_reference, z$n_shifted, z$pct_shifted), c(nrow(d), sum(d$bmi>30), 100*mean(d$bmi>30)))
      contributions <- a$policy_contributions[a$policy_contributions$model_id == row$model_id, ]
      observed <- plogis(drop(x0 %*% beta)); counterfactual <- plogis(drop(x1 %*% beta))
      bands <- seq(config$bmi_bin_width*floor(min(d$bmi)/config$bmi_bin_width),
        config$bmi_bin_width*floor(max(d$bmi)/config$bmi_bin_width),by=config$bmi_bin_width)
      stopifnot(setequal(contributions$bin_low,bands),!anyDuplicated(contributions$bin_low))
      band_gradient <- matrix(0,nrow=length(bands),ncol=length(beta),dimnames=list(as.character(bands),NULL))
      for (j in seq_len(nrow(contributions))) {
        band <- d$bmi >= contributions$bin_low[j] & d$bmi < contributions$bin_high[j]
        e2e_near(c(contributions$A[j], contributions$G[j], contributions$D[j]),
          c(sum(observed[band]), sum(counterfactual[band]), sum(observed[band]-counterfactual[band]))/nrow(d))
        gradient_band <- colSums(x0[band,,drop=FALSE]*observed[band]*(1-observed[band])-
          x1[band,,drop=FALSE]*counterfactual[band]*(1-counterfactual[band]))/nrow(d)
        band_gradient[as.character(contributions$bin_low[j]),] <- gradient_band
        interval <- 1000*(sum(observed[band]-counterfactual[band])/nrow(d)+c(-1,1)*qnorm(.975)*sqrt(variance(gradient_band)))
        e2e_near(c(contributions$conf_low_per1000[j],contributions$conf_high_per1000[j]),interval)
      }
      cv_band <- a$policy_contribution_covariance[a$policy_contribution_covariance$model_id == row$model_id, ]
      stopifnot(nrow(cv_band)==length(bands)^2,!anyDuplicated(cv_band[c("bin1","bin2")]),
        setequal(cv_band$bin1,bands),setequal(cv_band$bin2,bands))
      expected_covariance <- band_gradient %*% covariance %*% t(band_gradient)
      e2e_near(cv_band$covariance,expected_covariance[cbind(match(cv_band$bin1,bands),match(cv_band$bin2,bands))])
      e2e_near(sum(cv_band$covariance), variance(g0-g1))
    }
    first <- ceiling(min(d$bmi)/config$grid_step)*config$grid_step
    grid <- sort(unique(c(range(d$bmi),if(first<=max(d$bmi))seq(first,max(d$bmi),by=config$grid_step)else numeric())))
    stopifnot(!anyDuplicated(curves$bmi),all(curves$status=="estimated"))
    e2e_near(sort(curves$bmi),grid)
    for (j in seq_len(nrow(curves))) {
      constant <- d; constant$bmi <- curves$bmi[j]
      x <- matrix_for(constant);point <- mean(plogis(drop(x%*%beta)))
      derivative <- vapply(seq_along(beta),function(k) {
        delta <- rep(0,length(beta));delta[k] <- eps
        (mean(plogis(drop(x%*%(beta+delta))))-mean(plogis(drop(x%*%(beta-delta)))))/(2*eps)
      },numeric(1))
      e2e_near(curves$probability[j],point)
      e2e_near(c(curves$conf_low[j],curves$conf_high[j]),probability_ci(point,derivative),1e-6)
      stopifnot(curves$within_training_bmi_range[j] == (curves$bmi[j] >= min(d$bmi) && curves$bmi[j] <= max(d$bmi)))
    }
    fitted[[row$model_id]] <- data.frame(model_id=row$model_id, n_model=nrow(d), coefficients=length(coef(fit)),
      curve_points=nrow(curves), paired_scenarios=nrow(z), status="independent oracle matched")
  }
  stopifnot(length(fitted) > 0L)
  do.call(rbind, fitted)
}

e2e_adverse_cases <- function() {
  d <- make_bmi_curve_fixture(9, adverse=FALSE)
  d$bmi <- 40; d$bmi_evidence_state <- "valid"
  d$encounter_date <- as.Date("2022-01-01") + rep(c(0,30),9)
  d[bmi_rfs_fields] <- 0L; d$OBESITY_rfs <- 1L
  d$bmi[1] <- NA; d$bmi_evidence_state[1] <- "unresolved"
  d$bmi[3] <- NA; d$bmi_evidence_state[3] <- "missing"
  d$encounter_date[6] <- d$encounter_date[5]
  d$sex[7] <- NA
  d$ABG_rfs[c(10,11,13)] <- 1L; d$VBG_rfs[13] <- NA
  d$ABG_rfs[15] <- NA; d$OBESITY_rfs[17] <- 0L
  q <- construct_cohort_and_memberships(d)$members$Q
  stopifnot(setequal(q$encounter_id, d$encounter_id[c(4,7,9,11,13,15,17)]),
    q$rfs_group[q$encounter_id == d$encounter_id[9]] == "obesity_only",
    q$rfs_group[q$encounter_id == d$encounter_id[13]] == "primary",
    all(q$rfs_group[q$encounter_id %in% d$encounter_id[c(15,17)]] == "unresolved"))
  changed <- d; changed[bmi_rfs_fields] <- NA_real_
  stopifnot(setequal(construct_cohort_and_memberships(changed)$members$Q$encounter_id, q$encounter_id))
  policy <- bmi_config()$policies[[1]]
  e2e_near(bmi_policy_transform(c(29.9,30,30.2,40), policy), c(29.9,30,29.2,39))
  variance <- matrix(c(.04,.015,.015,.09), 2)
  positive <- list(probability=.2, gradient=c(.1,.02))
  negative <- list(probability=.3, gradient=c(.03,.04))
  stopifnot(bmi_pair_quantities(positive, negative, variance)$PIF < 0,
    bmi_pair_quantities(positive, positive, variance)$PIF == 0,
    bmi_pair_quantities(positive, positive, variance)$variance_difference == 0)
  # A smooth-looking numerical result must not replace a failed registered model.
  full <- make_bmi_curve_fixture(200, adverse=FALSE)
  ctx <- construct_cohort_and_memberships(full); cfg <- bmi_config()
  basis <- resolve_bmi_basis(ctx$members$C, cfg)
  spec <- bmi_model_registry("qualified")[1, ]; train <- ctx$members$C_abg_encounter
  train$abg <- 0L
  stopifnot(fit_bmi_model(spec,train,basis,cfg)$row$status == "constant_outcome")
  train$abg <- as.integer(train$bmi > median(train$bmi))
  stopifnot(fit_bmi_model(spec,train,basis,cfg)$row$status == "separation")
  basis$status <- "duplicated_or_unavailable_knots"
  stopifnot(fit_bmi_model(spec,train,basis,cfg)$row$status == "rank_deficiency")
  pending <- bmi_run_analysis(make_bmi_curve_fixture(12,with_index_day=FALSE),cfg)
  z <- pending$cohort_nodes[grepl("index_calendar_day",pending$cohort_nodes$population_id), ]
  stopifnot(nrow(z)>0, all(is.na(z$n)))
  z <- pending$model_registry[pending$model_registry$window=="index_calendar_day",]
  stopifnot(nrow(z)>0,all(z$status=="pending_source"),all(is.na(z$n_model)),all(is.na(z$n_events)),
    any(pending$model_registry$window=="encounter"))
  invisible(TRUE)
}
