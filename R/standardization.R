# Predictions are evaluated on actual reference covariates; no marginal-density integration.
bmi_matrix <- function(model,d) {
  for(v in names(model$fit$xlevels)) if(any(!as.character(d[[v]]) %in% model$fit$xlevels[[v]]))stop("Unseen reference category: ",v,"; reference not restricted")
  if(model$row$model_form=="spline")d<-bmi_add_basis(d,model$basis)
  x<-stats::model.matrix(stats::delete.response(stats::terms(model$fit)),d,contrasts.arg=model$fit$contrasts,xlev=model$fit$xlevels)
  if(!identical(colnames(x),names(stats::coef(model$fit))))stop("Prediction basis/column identity mismatch")
  x
}
bmi_mean_prediction <- function(model,reference,config,bmi=NULL,coefficients=NULL) {
  if(!nrow(reference))stop("Empty reference")
  beta<-if(is.null(coefficients))stats::coef(model$fit)else coefficients
  sums<-0;grad<-setNames(rep(0,length(beta)),names(beta));n<-nrow(reference)
  for(start in seq(1,n,by=config$chunk_size)) {
    ix<-start:min(n,start+config$chunk_size-1);d<-reference[ix,,drop=FALSE]
    if(!is.null(bmi))d$bmi<-if(length(bmi)==1)bmi else bmi[ix]
    x<-bmi_matrix(model,d)
    p<-stats::plogis(drop(x%*%beta))
    sums<-sums+sum(p);grad<-grad+colSums(x*(p*(1-p)))
  }
  list(probability=sums/n,gradient=grad/n)
}
bmi_delta_variance <- function(g,v) {
  z<-as.numeric(crossprod(g,v%*%g))
  if(!is.finite(z)||z < -1e-10)stop("Invalid full-covariance delta variance")
  max(z,0)
}
bmi_probability_interval <- function(p,g,v) {
  if(p<=0||p>=1)return(c(p,p))
  se<-sqrt(bmi_delta_variance(g/(p*(1-p)),v));stats::plogis(stats::qlogis(p)+c(-1,1)*stats::qnorm(.975)*se)
}
bmi_support <- function(model,ref,transformed=ref$bmi) {
  bounds<-range(model$data$bmi);old<-ref$bmi;new<-transformed
  gaps<-function(x)pmax(bounds[1]-x,x-bounds[2],0)
  unseen<-rep(FALSE,nrow(ref))
  for(v in names(model$fit$xlevels))unseen<-unseen|!as.character(ref[[v]]) %in% model$fit$xlevels[[v]]
  data.frame(model_id=model$row$model_id,fit_bmi_min=bounds[1],fit_bmi_max=bounds[2],n_reference=nrow(ref),
    n_observed_outside=sum(gaps(old)>0),n_transformed_outside=sum(gaps(new)>0),pct_transformed_outside=100*mean(gaps(new)>0),
    maximum_observed_gap=if(length(old))max(gaps(old))else NA_real_,maximum_transformed_gap=if(length(new))max(gaps(new))else NA_real_,n_unseen_categories=sum(unseen))
}
standardize_probability_curves <- function(model,reference,reference_id,config) {
  grid<-numeric()
  if(nrow(reference)) {
    bounds_reference<-range(reference$bmi)
    first<-ceiling(bounds_reference[1]/config$grid_step)*config$grid_step
    interior<-if(first<=bounds_reference[2])seq(first,bounds_reference[2],by=config$grid_step)else numeric()
    grid<-sort(unique(c(bounds_reference,interior)))
  }
  base<-data.frame(model_id=model$row$model_id,reference_id=reference_id,n_reference=if(model$row$status=="pending_source")NA_integer_ else nrow(reference),n_model=model$row$n_model,
    outcome_id=model$row$outcome_id,window=model$row$window,family=model$row$family)
  if(is.null(model$fit)||!length(grid))return(cbind(base,bmi=NA_real_,probability=NA_real_,conf_low=NA_real_,conf_high=NA_real_,within_training_bmi_range=NA,status=model$row$status,reason=model$row$failure_reason))
  bounds<-range(model$data$bmi);v<-stats::vcov(model$fit)
  bmi_bind(lapply(grid,function(b) {
    result<-tryCatch(bmi_mean_prediction(model,reference,config,bmi=b),error=function(e)e)
    if(inherits(result,"error"))return(cbind(base,bmi=b,probability=NA_real_,conf_low=NA_real_,conf_high=NA_real_,within_training_bmi_range=FALSE,status="prediction_unavailable",reason=conditionMessage(result)))
    ci<-bmi_probability_interval(result$probability,result$gradient,v)
    local <- model$data[abs(model$data$bmi-b) <= config$bmi_bin_width/2,,drop=FALSE]
    n_events <- sum(local[[model$row$field]]==1)
    n_nonevents <- nrow(local)-n_events
    coverage <- vapply(c("sex","race_ethnicity","location"), function(name)
      length(setdiff(unique(as.character(reference[[name]])), unique(as.character(local[[name]])))), integer(1))
    cbind(base,bmi=b,probability=result$probability,conf_low=ci[1],conf_high=ci[2],within_training_bmi_range=b>=bounds[1]&&b<=bounds[2],local_n=nrow(local),local_events=n_events,local_nonevents=n_nonevents,locally_sparse=nrow(local)<config$sparse_n||n_events<config$sparse_events||n_nonevents<config$sparse_events,missing_local_factor_levels=sum(coverage),status="estimated",reason="")
  }))
}
bmi_policy_transform <- function(bmi,policy) {
  switch(policy$transformation,minus_one=ifelse(bmi>policy$threshold,bmi-1,bmi),cap=pmin(bmi,policy$threshold),identity=bmi,stop("Unknown named policy"))
}
bmi_pair_quantities <- function(p0,p1,v) {
  a<-p0$probability;b<-p1$probability;g<-p0$gradient-p1$gradient
  variance<-bmi_delta_variance(g,v);ci<-(a-b)+c(-1,1)*stats::qnorm(.975)*sqrt(variance)
  ci0<-bmi_probability_interval(a,p0$gradient,v);ci1<-bmi_probability_interval(b,p1$gradient,v)
  rel<-relci<-rep(NA_real_,2)
  if(a>0&&b>0){s<-sqrt(bmi_delta_variance(p1$gradient/b-p0$gradient/a,v));relci<-1-exp(log(b/a)+c(1,-1)*stats::qnorm(.975)*s)}
  data.frame(p_observed=a,p_observed_low=ci0[1],p_observed_high=ci0[2],p_shifted=b,p_shifted_low=ci1[1],p_shifted_high=ci1[2],absolute_difference=a-b,difference_per1000=1000*(a-b),difference_low_per1000=1000*ci[1],difference_high_per1000=1000*ci[2],
    PIF=if(a>0)1-b/a else NA_real_,PIF_low=relci[1],PIF_high=relci[2],variance_difference=variance)
}
standardize_policy_and_contributions <- function(model,reference,reference_id,policy,config,method="observed") {
  if(method!="observed")stop("Full-cohort MAR/MNAR scenarios are historical only")
  base<-data.frame(model_id=model$row$model_id,reference_id=reference_id,policy_id=policy$policy_id,method=method,
    n_reference=if(model$row$status=="pending_source")NA_integer_ else nrow(reference),n_model=model$row$n_model,outcome_id=model$row$outcome_id,window=model$row$window)
  fail<-function(reason,status="prediction_unavailable")list(policy_totals=cbind(base,status=status,reason=reason),policy_contributions=data.frame(),policy_contribution_covariance=data.frame(),prediction_support=data.frame())
  if(is.null(model$fit))return(fail(model$row$failure_reason,model$row$status))
  if(!nrow(reference))return(fail("Empty reference population"))
  shifted<-bmi_policy_transform(reference$bmi,policy)
  attempt<-tryCatch({
    p0<-bmi_mean_prediction(model,reference,config)
    p1<-bmi_mean_prediction(model,reference,config,bmi=shifted)
    v<-stats::vcov(model$fit);support<-bmi_support(model,reference,shifted)
    total<-cbind(base,bmi_pair_quantities(p0,p1,v),n_shifted=sum(shifted!=reference$bmi),pct_shifted=100*mean(shifted!=reference$bmi),
      mean_decrement=mean(reference$bmi-shifted),maximum_decrement=max(reference$bmi-shifted),status="estimated",reason="")
    width<-config$bmi_bin_width;bin<-width*floor(reference$bmi/width)
    bands<-seq(min(bin),max(bin),by=width);rows<-list();grads<-list()
    for(b in bands) {
      ix<-which(bin==b);mass<-length(ix)/nrow(reference)
      if(length(ix)) {
        q0<-bmi_mean_prediction(model,reference[ix,,drop=FALSE],config)
        q1<-bmi_mean_prediction(model,reference[ix,,drop=FALSE],config,bmi=shifted[ix])
        contribution<-mass*(q0$probability-q1$probability);gradient<-mass*(q0$gradient-q1$gradient)
        a<-mass*q0$probability;g<-mass*q1$probability;se<-sqrt(bmi_delta_variance(gradient,v))
      }else{q0<-q1<-list(probability=NA_real_);contribution<-a<-g<-se<-0;gradient<-rep(0,ncol(v))}
      rows[[length(rows)+1L]]<-cbind(base,bin_low=b,bin_high=b+width,n=length(ix),mass=mass,mean_observed=q0$probability,mean_shifted=q1$probability,
        A=a,G=g,D=contribution,contribution_per1000=1000*contribution,conf_low_per1000=1000*(contribution-stats::qnorm(.975)*se),conf_high_per1000=1000*(contribution+stats::qnorm(.975)*se),status=if(length(ix))"estimated"else"empty_bin")
      grads[[length(grads)+1L]]<-gradient
    }
    contributions<-bmi_bind(rows);gradient_matrix<-do.call(rbind,grads);cv<-gradient_matrix%*%v%*%t(gradient_matrix)
    covariance<-expand.grid(bin1=bands,bin2=bands);covariance$covariance<-as.vector(cv)
    for(name in c("model_id","reference_id","policy_id","method"))covariance[[name]]<-base[[name]]
    if(max(abs(c(sum(contributions$A)-p0$probability,sum(contributions$G)-p1$probability,sum(contributions$D)-total$absolute_difference,sum(cv)-total$variance_difference)))>1e-9)stop("Paired contribution reconciliation failed")
    support$reference_id<-reference_id;support$policy_id<-policy$policy_id;support$method<-method
    list(policy_totals=total,policy_contributions=contributions,policy_contribution_covariance=covariance,prediction_support=support)
  },error=function(e)e)
  if(inherits(attempt,"error"))return(fail(conditionMessage(attempt)))
  attempt
}
bmi_fixed_contrast <- function(model,reference,id,config) {
  b<-unlist(config$fixed_bmi_contrast);base<-data.frame(model_id=model$row$model_id,reference_id=id,bmi_low=b[1],bmi_high=b[2],n_reference=nrow(reference),n_model=model$row$n_model)
  if(is.null(model$fit))return(cbind(base,status=model$row$status,reason=model$row$failure_reason))
  bounds<-range(model$data$bmi)
  if(any(b<bounds[1]|b>bounds[2]))return(cbind(base,status="unsupported_contrast",reason="BMI 40/45 outside training BMI support"))
  attempt<-tryCatch({p0<-bmi_mean_prediction(model,reference,config,bmi=b[1]);p1<-bmi_mean_prediction(model,reference,config,bmi=b[2]);v<-stats::vcov(model$fit)
    se<-sqrt(bmi_delta_variance(p1$gradient-p0$gradient,v));ratio<-p1$probability/p0$probability;s<-sqrt(bmi_delta_variance(p1$gradient/p1$probability-p0$gradient/p0$probability,v))
    cbind(base,probability_low_bmi=p0$probability,probability_high_bmi=p1$probability,difference_per1000=1000*(p1$probability-p0$probability),
      conf_low_per1000=1000*(p1$probability-p0$probability-stats::qnorm(.975)*se),conf_high_per1000=1000*(p1$probability-p0$probability+stats::qnorm(.975)*se),prevalence_ratio=ratio,ratio_low=ratio*exp(-stats::qnorm(.975)*s),ratio_high=ratio*exp(stats::qnorm(.975)*s),status="estimated",reason="")
  },error=function(e)e)
  if(inherits(attempt,"error"))return(cbind(base,status="prediction_unavailable",reason=conditionMessage(attempt)))
  attempt
}
bmi_run_population_analysis <- function(raw,config,source_status="artificial",audit_only=FALSE,companion=NULL) {
  message("[analysis] Constructing cohort, stage profiles and evidence ledger")
  ctx<-construct_cohort_and_memberships(raw);dict<-bmi_dictionary(ctx$data,config)
  ledger<-bmi_ledger(ctx);profiles<-profile_stage_variables(ctx$members,dict,config);evidence<-derive_evidence_states(ctx,config)
  tables<-c(ledger,profiles,evidence,list(variable_dictionary=dict,source_audit=data.frame(requirement=c("population","BMI","gas/ICD","timing","clinical_inference"),
    status=c(source_status,source_status,source_status,ctx$day_status,if(source_status=="artificial")"artificial_only"else"pending_scientific_review"),
    note=c("Authenticated original selected encounters only; broader mapping gap historical","Encounter/prior reported then observed height/weight; no imputation","Unadjusted, specimen-authenticated; unknown remains unknown", "Fixed selected index; calendar date not elapsed 24h","Observed-population associations do not establish population transport or causal interpretation"))))
  if(!is.null(companion))tables<-bmi_merge_companion(tables,companion,raw)
  tables$distribution_bins<-bmi_bind(list(tables$distribution_bins,bmi_pattern_bins(ctx,config)))
  tables$population_registry<-tables$cohort_nodes
  tables$stage_summary<-tables$variable_summary
  tables$policy_registry<-bmi_bind(lapply(config$policies,as.data.frame))
  for(name in c("model_registry","model_sample_audit","coefficients","coefficient_covariance","factor_references","model_fit_diagnostics","model_residual_bins","model_influence_summary","model_support","bmi_basis","prediction_support","probability_curves","observation_curves","fixed_bmi_contrasts","policy_totals","policy_contributions","policy_contribution_covariance","sensitivity_results","implied_missing_probabilities","linear_spline_comparison"))tables[[name]]<-data.frame()
  if(!audit_only) {
    message("[analysis] Resolving the common spline basis and fitting registered models")
    basis<-if(is.null(config$basis_override))resolve_bmi_basis(ctx$members$C,config)else config$basis_override
    tables$bmi_basis<-data.frame(basis_id=basis$basis_id,knot_probability=unlist(config$knot_probabilities),knot=basis$knots,kind=c("boundary","interior","interior","boundary"),quantile_type=basis$quantile_type,status=basis$status,reference_id="C",basis="splines::ns; intercept FALSE; 3 columns")
    models<-fit_registered_models(ctx,basis,config)
    tables$model_registry<-bmi_bind(lapply(models,`[[`,"row"));tables$model_sample_audit<-tables$model_registry
    tables$coefficients<-bmi_bind(lapply(models,`[[`,"coefficients"));tables$coefficient_covariance<-bmi_bind(lapply(models,`[[`,"covariance"));tables$factor_references<-bmi_bind(lapply(models,`[[`,"references"))
    message("[analysis] Computing complete model diagnostics and sample profiles")
    diagnostics<-lapply(models,bmi_model_diagnostics,config=config)
    for(name in names(diagnostics[[1]]))tables[[name]]<-bmi_bind(lapply(diagnostics,`[[`,name))
    model_members<-lapply(models,`[[`,"data");names(model_members)<-paste0("model:",names(model_members))
    for(id in names(model_members)) {
      node<-bmi_node(id,model_members[[id]]);tables$population_registry<-bmi_bind(list(tables$population_registry,node))
      mp<-bmi_profile(model_members[[id]],id,dict,config,model_members[[id]])
      for(name in names(mp))tables[[name]]<-bmi_bind(list(tables[[name]],mp[[name]]))
    }
    curves<-fixed<-policies<-implied<-curve_support<-list()
    for(id in names(models)) {
      message("[standardization] ",id)
      m<-models[[id]];spec<-m$row
      refid<-if(spec$family=="observation")"C"else spec$training_population_id
      ref<-ctx$members[[refid]]
      curves[[id]]<-standardize_probability_curves(m,ref,refid,config)
      if(!is.null(m$fit)&&nrow(ref)) {curve_support[[id]]<-bmi_support(m,ref,curves[[id]]$bmi);curve_support[[id]]$reference_id<-refid;curve_support[[id]]$policy_id<-"none; relationship";curve_support[[id]]$method<-"fixed_BMI_curve"}
      if(spec$family %in% c("primary","timing","matched","supporting")) {
        fixed[[id]]<-bmi_fixed_contrast(m,ref,refid,config)
        for(policy in config$policies)if(isTRUE(policy$enabled)) {
          if (!identical(policy$target,"model_observed")) stop("Unreviewed standardization target")
          policies[[paste(id,policy$policy_id,refid)]]<-standardize_policy_and_contributions(m,ref,refid,policy,config,"observed")
        }
      }
    }
    allcurves<-bmi_bind(curves);tables$probability_curves<-allcurves[allcurves$family!="observation",,drop=FALSE];tables$observation_curves<-allcurves[allcurves$family=="observation",,drop=FALSE]
    tables$fixed_bmi_contrasts<-bmi_bind(fixed);tables$implied_missing_probabilities<-bmi_bind(implied)
    for(name in c("policy_totals","policy_contributions","policy_contribution_covariance","prediction_support"))tables[[name]]<-bmi_bind(lapply(policies,`[[`,name))
    tables$prediction_support<-bmi_bind(c(list(tables$prediction_support),curve_support))
    tables$sensitivity_results<-tables$policy_totals[tables$policy_totals$method %in% "mnar",,drop=FALSE]
    comparison<-list()
    for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","any_gas","icd")else c("abg","any_gas")) {
      if(!is.null(config$fit_role) && config$fit_role=="supporting") next
      s<-models[[paste(o,w,"spline",sep="/")]];l<-models[[paste(o,w,"linear",sep="/")]]
      row<-data.frame(outcome_id=o,window=w,status="unavailable",n_model=s$row$n_model,reason="one or both models unavailable")
      if(!is.null(s$fit)&&!is.null(l$fit)) {
        if(!identical(tri_encounter_key(s$data),tri_encounter_key(l$data)))stop("Linear/spline rows differ")
        lr<-2*(as.numeric(stats::logLik(s$fit))-as.numeric(stats::logLik(l$fit)));df<-length(stats::coef(s$fit))-length(stats::coef(l$fit))
        row<-cbind(transform(row,status="assessed",reason="same-row nested comparison; no model selection"),likelihood_ratio=lr,df=df,p_value=stats::pchisq(lr,df,lower.tail=FALSE))
      };comparison[[length(comparison)+1L]]<-row
    };tables$linear_spline_comparison<-bmi_bind(comparison)
  }
  if(ctx$day_status=="pending") {
    pending_ids<-grep("index_calendar_day",tables$cohort_nodes$population_id,value=TRUE)
    if(nrow(tables$model_registry))pending_ids<-c(pending_ids,paste0("model:",tables$model_registry$model_id[tables$model_registry$source_status=="pending"]))
    for(name in c("cohort_nodes","population_registry")) {
      ix<-tables[[name]]$population_id %in% pending_ids
      for(v in intersect(c("n_records","n_encounters","n_patients","n"),names(tables[[name]])))tables[[name]][ix,v]<-NA_real_
      tables[[name]]$status[ix]<-"pending_source; membership unassessed"
    }
    for(name in c("variable_summary","category_counts","distribution_bins","distribution_curves")) {
      t<-tables[[name]];if(!nrow(t))next
      ix<-t$population_id %in% pending_ids | grepl("index_day|index_calendar_day",t$variable_id)
      if(name %in% c("distribution_bins","distribution_curves")){tables[[name]]<-t[!ix,,drop=FALSE];next}
      for(v in names(t)[vapply(t,is.numeric,logical(1))])t[ix,v]<-NA_real_
      if("status" %in% names(t))t$status[ix]<-"pending source module; evidence not assessed"
      tables[[name]]<-t
    }
    for(name in c("missingness_patterns","comissingness"))if(nrow(tables[[name]]))tables[[name]]<-tables[[name]][!tables[[name]]$population_id %in% pending_ids,,drop=FALSE]
  }
  tables$stage_summary<-tables$variable_summary
  message("[analysis] Validating coverage and numerical reconciliation")
  tables$coverage_index<-bmi_bind(list(
    data.frame(kind="population",item_id=tables$population_registry$population_id,table="population_registry",status=tables$population_registry$status),
    data.frame(kind="variable",item_id=dict$variable_id,table="variable_summary",status=ifelse(dict$variable_id %in% tables$variable_summary$variable_id,"profiled","unavailable/not derived in this run; dictionary and model status explain applicability")),
    if(nrow(tables$model_registry))data.frame(kind="model",item_id=tables$model_registry$model_id,table="model_registry",status=tables$model_registry$status)))
  diagnostic<-dict$variable_id[dict$role=="diagnostic"]
  for(v in diagnostic){ix<-tables$coverage_index$kind=="variable" & tables$coverage_index$item_id==v;tables$coverage_index$table[ix]<-if(v %in% c("leverage","cooks","max_abs_dfbeta"))"model_influence_summary"else"model_residual_bins";tables$coverage_index$status[ix]<-if(nrow(tables$model_residual_bins))"model audit distributions/quantiles; failed models explicitly unavailable"else"unavailable; no successful fitted model"}
  tables$numerical_reconciliation<-bmi_validate_ledger(tables)
  for(name in setdiff(bmi_table_names,names(tables)))tables[[name]]<-data.frame()
  tables
}
