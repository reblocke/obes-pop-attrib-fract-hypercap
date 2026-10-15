# Artificial-only checks shared by testthat and the standalone base-R runner.
common_expect_error <- function(expression, pattern = NULL) {
  error <- tryCatch({ force(expression); NULL }, error = function(e) e)
  if (is.null(error) || (!is.null(pattern) && !grepl(pattern, conditionMessage(error)))) stop("Expected failure did not occur: ", pattern)
}
common_fixture_context <- function() {
  data <- derive_triangulation_variables(validate_triangulation_input(make_triangulation_fixture()))
  data$common_obesity <- data$bmi >= 30
  indexes <- select_frame_indexes(data, "common_obesity")$indexes
  reference <- indexes[complete.cases(indexes[triangulation_adjustment]), ]
  list(data = data, reference = reference)
}
common_checks <- list(
  "Index is selected before gas availability and completeness" = function() {
    d <- make_triangulation_fixture(2)
    d$bmi <- c(30, 45, 29.9, 30.2); d$sex <- "Female"
    d$has_abg <- d$has_vbg <- 0L; d$abg_pco2 <- d$vbg_pco2 <- NA_real_
    d[triangulation_index_day_columns] <- NULL
    d$has_abg[c(2,4)] <- 1L; d$abg_pco2[c(2,4)] <- 50
    v <- derive_triangulation_variables(validate_triangulation_input(d)); v$common_obesity <- v$bmi >= 30
    x <- select_frame_indexes(v, "common_obesity")$indexes
    stopifnot(identical(x$encounter_id, d$encounter_id[c(1,4)]), is.na(x$abg[1]), x$bmi[1] == 30)
    d$bmi[1] <- NA_real_; v <- derive_triangulation_variables(validate_triangulation_input(d)); v$common_obesity <- v$bmi >= 30
    stopifnot(select_frame_indexes(v, "common_obesity")$counts$n_index_unresolved == 1)
  },
  "Exact shift and usable specimen rules" = function() {
    stopifnot(identical(shift_bmi_above30(c(29.9,30,30.2,40)), c(29.9,30,29.2,39)))
    d <- make_triangulation_fixture(2, with_index_day = FALSE)
    d$has_abg <- c(1L,0L,1L,1L);d$has_vbg <- c(0L,1L,1L,1L)
    d$abg_pco2 <- c(45,NA,44,NA);d$vbg_pco2 <- c(NA,50,NA,NA)
    v <- derive_triangulation_variables(validate_triangulation_input(d))
    stopifnot(identical(v$abg, c(1L,NA_integer_,0L,NA_integer_)), identical(v$any_gas,c(1L,1L,0L,NA_integer_)))
  },
  "One common target, model reuse and separate matched pairs" = function() {
    a <- run_common_index(make_triangulation_fixture());validate_common_aggregates(a)
    r <- a$results
    mar <- r[r$method == "mar" & r$window == "encounter" & r$target_id == "bmi_ge30", ]
    stopifnot(length(unique(mar$n_reference)) == 1, length(unique(mar$n_training)) == 2, nrow(a$models) == 8)
    for (outcome in c("abg","any_gas")) {
      rows <- r[r$outcome == outcome & r$window == "encounter" & r$method == "mar", ]
      stopifnot(length(unique(rows$model_id)) == 1, length(unique(rows$n_training)) == 1,
        rows$n_reference[rows$target_id == "bmi_ge40"] == a$population$n_reference_ge40)
    }
    stopifnot(a$population$n_matched_abg < a$population$n_matched_any_gas)
  },
  "Independent GLM and MAR prediction parity" = function() {
    context <- common_fixture_context(); reference <- context$reference
    a <- run_common_index(make_triangulation_fixture())
    for (outcome in c("abg", "any_gas")) {
      training <- reference[!is.na(reference[[outcome]]), ];training$.outcome <- training[[outcome]]
      fit <- stats::glm(common_formula, training, family = stats::binomial())
      shifted <- reference;shifted$bmi <- shift_bmi_above30(shifted$bmi)
      expected <- c(mean(predict(fit, reference, type="response")),mean(predict(fit,shifted,type="response")))
      row <- a$results[a$results$outcome == outcome & a$results$window == "encounter" & a$results$method == "mar" & a$results$target_id == "bmi_ge30", ]
      stopifnot(max(abs(c(row$p_observed,row$p_counterfactual)-expected)) < 1e-12)
    }
  },
  "MNAR gradients, shifted offsets and conditional delta intervals" = function() {
    ref <- common_fixture_context()$reference
    train <- ref[!is.na(ref$abg), ]; model <- fit_common_model(train,"abg","abg/encounter")
    fit <- model$fit; beta <- coef(fit)
    shifted <- ref;shifted$bmi <- shift_bmi_above30(shifted$bmi)
    matrix <- function(d) model.matrix(delete.response(terms(fit)),d,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
    x0 <- matrix(ref); x1 <- matrix(shifted);observed <- !is.na(ref$abg)
    fun <- function(b) {
      p0 <- common_probability(x0,b,ref$bmi,observed,log(.5),log(2))$probability
      p1 <- common_probability(x1,b,shifted$bmi,observed,log(.5),log(2))$probability
      c(p0-p1,log(p1/p0))
    }
    eps <- 1e-6; numeric <- sapply(seq_along(beta),function(i) { step<-rep(0,length(beta));step[i]<-eps;(fun(beta+step)-fun(beta-step))/(2*eps) })
    p0 <- common_probability(x0,beta,ref$bmi,observed,log(.5),log(2));p1<-common_probability(x1,beta,shifted$bmi,observed,log(.5),log(2))
    analytic <- rbind(p0$gradient-p1$gradient,p1$gradient/p1$probability-p0$gradient/p0$probability)
    stopifnot(max(abs(numeric-analytic))<1e-7)
    actual <- common_standardize(model,ref,observed,"mnar",.5,2)
    sigma <- sqrt(diag(analytic%*%vcov(fit)%*%t(analytic)))
    stopifnot(abs(actual$absolute_conf_low-(fun(beta)[1]-qnorm(.975)*sigma[1]))<1e-10,
      abs(actual$impact_conf_low-(1-exp(fun(beta)[2]+qnorm(.975)*sigma[2])))<1e-10)
  },
  "No unobserved evidence makes sensitivity assumptions irrelevant" = function() {
    ref <- common_fixture_context()$reference;ref<-ref[!is.na(ref$abg), ]
    model<-fit_common_model(ref,"abg","test")
    a<-common_standardize(model,ref,rep(TRUE,nrow(ref)),"mar")
    b<-common_standardize(model,ref,rep(TRUE,nrow(ref)),"mnar",4,.5)
    stopifnot(identical(a,b))
    ref$bmi<-30
    z<-common_standardize(model,ref,rep(TRUE,nrow(ref)),"mar")
    stopifnot(z$absolute_difference==0,z$impact_fraction==0,z$absolute_conf_low==0,z$impact_conf_high==0)
  },
  "Unseen reference categories fail without dropping target rows" = function() {
    ref<-common_fixture_context()$reference;train<-ref[!is.na(ref$abg), ]
    model<-fit_common_model(train,"abg","test");ref$sex[1]<-"Unseen artificial category"
    z<-common_standardize(model,ref,!is.na(ref$abg),"mar")
    stopifnot(z$status=="not_estimable",z$n_unseen_categories==1,is.na(z$impact_fraction))
  },
  "Pending timing is unassessed and preserves primary results" = function() {
    a<-run_common_index(make_triangulation_fixture());b<-run_common_index(make_triangulation_fixture(with_index_day=FALSE))
    validate_common_aggregates(b)
    primary<-a$results$window=="encounter";pending<-b$results$window=="index_calendar_day"
    stopifnot(isTRUE(all.equal(a$results[primary, ],b$results[primary, ],check.attributes=FALSE)),
      all(b$results$status[pending]=="awaiting_source_evidence"),all(is.na(b$results$n_reference[pending])))
  },
  "Failure and negative contrasts remain explicit" = function() {
    ref<-common_fixture_context()$reference;train<-ref[!is.na(ref$abg), ];train$abg<-1L
    stopifnot(fit_common_model(train,"abg","constant")$row$status=="not_estimable")
    a<-run_common_index(make_triangulation_fixture());neg<-a$results[a$results$impact_fraction<0 & !is.na(a$results$impact_fraction), ]
    stopifnot(nrow(neg)>0,all(neg$impact_conf_low<=neg$impact_fraction),all(neg$absolute_conf_low<=neg$absolute_difference))
  },
  "Aggregate allowlists, identities and denominators reject corruption" = function() {
    a<-run_common_index(make_triangulation_fixture());bad<-a;bad$results$patient_id<-"ARTIFICIAL"
    common_expect_error(validate_common_aggregates(bad),"fields")
    bad<-a;bad$results$n_reference[2]<-bad$results$n_reference[2]-1;common_expect_error(validate_common_aggregates(bad))
    bad<-a;bad$results$study_design<-"old";common_expect_error(validate_common_aggregates(bad),"Design")
    bad<-a;bad$results$impact_conf_low[1]<-bad$results$impact_fraction[1]+1;common_expect_error(validate_common_aggregates(bad),"interval")
  },
  "Saved aggregate consumption cannot load inputs or fit models" = function() {
    a<-run_common_index(make_triangulation_fixture());root<-tempfile("common-bundle-");dir.create(root)
    on.exit(unlink(root,recursive=TRUE),add=TRUE)
    write_common_bundle(a,root,list(source_identity="ARTIFICIAL TEST",mode="fixture"),list(test="artificial"),"fixture","ARTIFICIAL-TEST")
    helper_env <- environment(run_common_index)
    originals <- mget(c("run_common_index","fit_common_model","load_common_input"), helper_env)
    on.exit(for (name in names(originals)) assign(name, originals[[name]], helper_env), add=TRUE)
    for(name in names(originals)) assign(name,function(...) stop("Forbidden estimator/input access"),helper_env)
    b<-read_common_bundle(root);stopifnot(isTRUE(all.equal(b$analysis,a,check.attributes=FALSE)))
    cat("tamper\n",file=file.path(root,"aggregate_results.csv"),append=TRUE)
    common_expect_error(read_common_bundle(root),"hash mismatch")
  },
  "Figure quantities, tiny values and signed axes" = function() {
    a<-run_common_index(make_triangulation_fixture())
    rows<-a$results[a$results$method=="mnar" & a$results$target_id=="bmi_ge30" & a$results$window=="encounter", ]
    axis<-common_axis_range(rows,"relative")
    stopifnot(axis$limits[1]<=min(c(0,100*rows$impact_conf_low)),axis$limits[2]>=max(c(0,100*rows$impact_conf_high)),
      common_number(1e-7)!="0.00",common_number(0)=="0.00")
    root<-tempfile(fileext=".pdf");grDevices::cairo_pdf(root,family="Arial")
    on.exit({dev.off();unlink(root)},add=TRUE)
    candidates<-common_candidates(a)
    base<-a$results[a$results$target_id=="bmi_ge30" & a$results$window=="encounter" & a$results$method%in%c("observed","mar"), ]
    stopifnot(identical(candidates$primary,base),nrow(candidates$sensitivity)==30,all(candidates$sensitivity$r%in%common_risk_odds))
  },
  "New manifests bind the design, expanded population and evidence hashes" = function() {
    dir<-tempfile("common-loader-");dir.create(dir);on.exit(unlink(dir,recursive=TRUE),add=TRUE)
    input<-file.path(dir,"ARTIFICIAL.rds");d<-make_triangulation_fixture(8,with_index_day=FALSE);saveRDS(d,input)
    m<-jsonlite::read_json(file.path(tri_repo_root(), "config/triangulation_input.example.json"),simplifyVector=TRUE)
    m$input_sha256<-tri_sha256(input);m$source_identity<-"ARTIFICIAL TEST ONLY";m$reviewed_by<-"fixture check"
    m$reviewed_on<-"2026-10-14";m$evidence_reference<-"ARTIFICIAL; not clinical acceptance"
    m$columns<-as.list(setNames(triangulation_columns,triangulation_columns))
    m$encounter_type_codes<-list(EMER="EMER",IMP="IMP")
    for(name in c("sex","race_ethnicity","location"))m$category_values[[name]]<-unique(d[[name]][!is.na(d[[name]])])
    m$source_qualification<-as.list(setNames(rep("accepted",7),names(m$source_qualification)))
    evidence<-file.path(dir,"ARTIFICIAL-evidence.json")
    jsonlite::write_json(list(source_policy=common_source_policy(), note="ARTIFICIAL; no source acceptance"),evidence,auto_unbox=TRUE,digits=NA)
    entry<-list(path=basename(evidence),sha256=tri_sha256(evidence));m$source_evidence_files<-list(lineage=entry,population=entry,fields=entry)
    manifest<-file.path(dir,"manifest.json");write_m<-function(x)jsonlite::write_json(x,manifest,auto_unbox=TRUE,pretty=TRUE)
    write_m(m);loaded<-load_common_input(input,manifest);stopifnot(nrow(loaded$data)==nrow(d))
    upper<-m;upper$source_evidence_files$fields$sha256<-toupper(upper$source_evidence_files$fields$sha256)
    write_m(upper);stopifnot(nrow(load_common_input(input,manifest)$data)==nrow(d))
    old<-m;old$schema_version<-2L;write_m(old);common_expect_error(load_common_input(input,manifest),"version 3")
    bad<-m;bad$population_policy<-"first gas encounter";write_m(bad);common_expect_error(load_common_input(input,manifest),"population")
    bad<-m;bad$source_policy_id<-"temperature_adjusted";write_m(bad);common_expect_error(load_common_input(input,manifest),"source policy")
    d$has_abg[1]<-1L;d$abg_pco2[1]<-200;saveRDS(d,input);bad<-m;bad$input_sha256<-tri_sha256(input);write_m(bad)
    common_expect_error(load_common_input(input,manifest),"validity policy")
    d$abg_pco2[1]<-50;saveRDS(d,input);m$input_sha256<-tri_sha256(input)
    write_m(m);writeLines("tampered",evidence);common_expect_error(load_common_input(input,manifest),"hash mismatch")
  },
  "Version-2 archived sources and original hashes remain unchanged" = function() {
    for(root in c("archive/2026-10-14-frame-specific","archive/2026-10-13-bmi-to-40")) {
      root<-file.path(tri_repo_root(),root)
      p<-jsonlite::read_json(file.path(root,"provenance.json"),simplifyVector=TRUE)
      for(name in names(p$files)) stopifnot(identical(tri_sha256(file.path(root,name)),p$files[[name]]))
    }
  }
)
