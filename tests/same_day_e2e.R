# Independent supplemental regression oracle. Updated before production replacement.
e2e_same_day <- function(bundle,raw) {
  a<-bundle$analysis
  ids<-paste0("primary::same_day_abg/encounter/",c("hypercapnia","hypercapnia_acidemia_cooccurrence"),"/spline")
  r<-a$model_registry[a$model_registry$model_id %in% ids,]
  stopifnot(nrow(r)==2L, !any(a$policy_totals$model_id %in% ids))
  q<-e2e_indexes(raw);q<-q[q$group=="primary" & complete.cases(q[triangulation_adjustment]),]
  p<-q[q$same_day_abg_state=="coobserved_day",]
  stopifnot(all(p$hypercapnia_acidemia_same_day<=p$hypercapnia_coobserved),all(r$n_model==nrow(p)),length(unique(r$basis_id))==1L)
  knots<-as.numeric(quantile(q$bmi,c(.05,.35,.65,.95),type=7))
  b<-splines::ns(p$bmi,knots=knots[2:3],Boundary.knots=knots[c(1,4)],intercept=FALSE)
  p$b1<-b[,1];p$b2<-b[,2];p$b3<-b[,3]
  for(v in c("sex","race_ethnicity","location"))p[[v]]<-factor(p[[v]],levels=c("0",setdiff(sort(unique(p[[v]])),"0")))
  for(i in seq_along(ids)) {
    p$y<-p[[c("hypercapnia_coobserved","hypercapnia_acidemia_same_day")[i]]]
    fit<-glm(y~b1+b2+b3+age_at_encounter+sex+race_ethnicity+location,data=p,family=binomial())
    saved<-a$coefficients[a$coefficients$model_id==ids[i] & a$coefficients$status=="estimated",]
    e2e_near(saved$estimate,coef(fit))
    curves<-a$probability_curves[a$probability_curves$model_id==ids[i],]
    for(j in unique(c(round(seq(1,nrow(curves),length.out=5)),which(curves$bmi %in% c(40,45))))) {
      new<-p;basis<-splines::ns(rep(curves$bmi[j],nrow(p)),knots=knots[2:3],Boundary.knots=knots[c(1,4)],intercept=FALSE)
      new$b1<-basis[,1];new$b2<-basis[,2];new$b3<-basis[,3]
      x<-model.matrix(~b1+b2+b3+age_at_encounter+sex+race_ethnicity+location,new)
      pr<-plogis(drop(x%*%coef(fit)));mean_p<-mean(pr)
      g<-colMeans(x*(pr*(1-pr)))/(mean_p*(1-mean_p))
      ci<-plogis(qlogis(mean_p)+c(-1,1)*qnorm(.975)*sqrt(drop(t(g)%*%vcov(fit)%*%g)))
      e2e_near(curves$probability[j],mean_p);e2e_near(c(curves$conf_low[j],curves$conf_high[j]),ci)
      contrast<-a$fixed_bmi_contrasts[a$fixed_bmi_contrasts$model_id==ids[i],]
      if(curves$bmi[j] %in% c(40,45) && contrast$status=="estimated") {
        label<-if(curves$bmi[j]==40)"low"else"high"
        e2e_near(unlist(contrast[paste0("probability_",label,"_bmi",c("","_low","_high"))]),c(mean_p,ci))
      }
    }
  }
  bins<-a$distribution_bins[a$distribution_bins$population_id=="primary::C_same_day_abg" & a$distribution_bins$variable_id=="bmi",]
  stopifnot(nrow(bins)>0,sum(bins$n)==nrow(p))
  # Run the full unchanged input without the optional module. Original models,
  # probabilities and PIFs must match; unavailable positions are not zero results.
  base<-bmi_run_analysis(raw[setdiff(names(raw),bmi_same_day_fields)],bundle$config)
  for(name in c("coefficients","coefficient_covariance","probability_curves","policy_totals","policy_contributions","policy_contribution_covariance")) {
    current<-a[[name]];original<-base[[name]]
    current<-current[!current$model_id %in% ids,,drop=FALSE]
    original<-original[!original$model_id %in% ids,,drop=FALSE]
    rownames(current)<-rownames(original)<-NULL
    stopifnot(isTRUE(all.equal(current,original,tolerance=1e-10,check.attributes=FALSE)))
  }
  pending<-base$model_registry[base$model_registry$model_id %in% ids,]
  stopifnot(nrow(base$model_registry)==nrow(a$model_registry),all(pending$status=="pending_source"),
    all(is.na(pending$n_model)),all(is.na(pending$n_events)))
  missing<-base$cohort_nodes[base$cohort_nodes$population_id=="primary::C_same_day_abg",]
  stopifnot(is.na(missing$n),!any(base$numerical_reconciliation$passed %in% FALSE))
  disabled_config<-bundle$config;disabled_config$same_day_abg_enabled<-FALSE
  disabled<-bmi_run_analysis(make_bmi_curve_fixture(12),disabled_config)
  stopifnot(disabled$cooccurrence_status$status=="disabled",all(disabled$model_registry$status[disabled$model_registry$model_id %in% ids]=="pending_source"))
  constant_raw<-make_bmi_curve_fixture(300,adverse=FALSE)
  constant_raw$hypercapnia_acidemia_same_day[constant_raw$same_day_abg_state=="coobserved_day"]<-0
  constant<-bmi_run_analysis(constant_raw,bundle$config)
  stopifnot(constant$model_registry$status[constant$model_registry$model_id==ids[2]]=="constant_outcome",
    all(is.na(constant$probability_curves$probability[constant$probability_curves$model_id==ids[2]])))
  invisible(data.frame(model_id=ids,n=nrow(p),status="independent co-occurrence models/curves/intervals confirmed"))
}
