# Fixed natural-spline basis and complete registered-model output.
resolve_bmi_basis <- function(reference,config) {
  k<-if(nrow(reference))as.numeric(stats::quantile(reference$bmi,unlist(config$knot_probabilities),type=config$quantile_type))else rep(NA_real_,4)
  list(knots=k,quantile_type=config$quantile_type,status=if(any(!is.finite(k))||anyDuplicated(k))"duplicated_or_unavailable_knots"else"resolved",
    basis_id=digest::digest(list(k,config$quantile_type,"splines::ns",FALSE),algo="sha256"))
}
bmi_add_basis <- function(d,basis) {
  b<-splines::ns(d$bmi,knots=basis$knots[2:3],Boundary.knots=basis$knots[c(1,4)],intercept=FALSE)
  for(j in 1:3)d[[paste0("bmi_ns",j)]]<-b[,j]
  d
}
bmi_model_registry <- function(day_status, role="full") {
  rows<-list();add<-function(id,family,outcome,window,population,field,form="spline") {
    rows[[length(rows)+1L]]<<-data.frame(model_id=id,family=family,outcome_id=outcome,window=window,
      training_population_id=population,field=field,model_form=form,source_status=if(window=="index_calendar_day")day_status else "qualified",stringsAsFactors=FALSE)
  }
  for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","any_gas","icd")else c("abg","any_gas"))for(f in c("spline","linear")) {
    pop<-if(o=="icd")"C_icd"else paste("C",o,w,sep="_")
    add(paste(o,w,f,sep="/"),if(f=="linear")"functional_form"else if(w=="encounter")"primary"else"timing",o,w,pop,if(w=="encounter")o else paste0(o,"_index_calendar_day"),f)
  }
  for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","vbg","any_gas","icd")else c("abg","vbg","any_gas"))
    add(paste("observation",o,w,sep="/"),"observation",o,w,"C",paste0("observed_",o,"_",w))
  for(pair in c("abg","any_gas"))for(o in c("icd",pair))add(paste("matched",pair,o,sep="/"),"matched",o,"encounter",paste0("M_",pair),o)
  result <- bmi_bind(rows)
  if (role == "supporting") {
    result <- result[result$family=="primary",,drop=FALSE]
    result$family <- "supporting"
  }
  result
}
bmi_observation_fields <- function(d) {
  for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","vbg","any_gas","icd")else c("abg","vbg","any_gas")) {
    field<-if(o=="vbg")if(w=="encounter")"vbg_pco2"else"vbg_pco2_index_day" else if(w=="encounter")o else paste0(o,"_index_calendar_day")
    d[[paste0("observed_",o,"_",w)]]<-as.integer(!is.na(d[[field]]))
  }
  d
}
fit_bmi_model <- function(spec,d,basis,config,n_reference=nrow(d)) {
  start<-proc.time()[3]
  formula<-stats::as.formula(paste(".outcome ~",if(spec$model_form=="spline")"bmi_ns1 + bmi_ns2 + bmi_ns3"else"bmi","+ age_at_encounter + sex + race_ethnicity + location"))
  row<-cbind(spec,data.frame(formula_text=paste(deparse(formula),collapse=" "),basis_id=basis$basis_id,
    weight_specification="none",covariance_method="model-based binomial; empirical reference fixed",
    n_eligible=if(spec$source_status=="pending")NA_integer_ else n_reference,
    n_excluded_outcome=if(spec$source_status=="pending")NA_integer_ else n_reference-nrow(d),n_excluded_adjustment=0L,
    n_model=if(spec$source_status=="pending")NA_integer_ else nrow(d),n_patients=if(spec$source_status=="pending")NA_integer_ else length(unique(d$patient_id)),
    n_events=if(spec$source_status=="pending")NA_integer_ else sum(d[[spec$field]]==1),n_nonevents=if(spec$source_status=="pending")NA_integer_ else sum(d[[spec$field]]==0),
    n_parameters=NA_integer_,model_rank=NA_integer_,status="not_attempted",failure_reason="",warnings="",fit_runtime=0))
  fail<-function(status,reason){row$status<-status;row$failure_reason<-reason;row$fit_runtime<-unname(proc.time()[3]-start);list(row=row,fit=NULL,data=d,basis=basis,coefficients=data.frame(),covariance=data.frame(),references=data.frame())}
  if(spec$source_status=="pending")return(fail("pending_source",if("source_reason" %in% names(spec))spec$source_reason else "Index-calendar-day source evidence unavailable"))
  if(!nrow(d))return(fail("no_evaluable_sample","Empty registered training population"))
  d$.outcome<-d[[spec$field]]
  if(anyNA(d[c(triangulation_adjustment,".outcome")]))stop("Registered sample contains hidden missing model fields")
  if(length(unique(d$.outcome))<2)return(fail("constant_outcome","Outcome has no variation; raw proportions remain available"))
  if(spec$model_form=="spline"&&basis$status!="resolved")return(fail("rank_deficiency",basis$status))
  refs<-list()
  for(v in c("sex","race_ethnicity","location")) {
    ref<-config$factor_references[[v]];lev<-sort(unique(as.character(d[[v]])))
    if(!ref %in% lev)return(fail("rank_deficiency",paste("Declared reference absent:",v,ref)))
    d[[v]]<-factor(d[[v]],levels=c(ref,setdiff(lev,ref)))
    refs[[v]]<-data.frame(model_id=spec$model_id,variable_id=v,level=levels(d[[v]]),is_reference=levels(d[[v]])==ref)
  }
  if(spec$model_form=="spline")d<-bmi_add_basis(d,basis)
  x<-tryCatch(stats::model.matrix(formula,d),error=function(e)e)
  if(inherits(x,"error"))return(fail("rank_deficiency",conditionMessage(x)))
  row$n_parameters<-ncol(x);row$model_rank<-qr(x)$rank
  if(qr(x)$rank<ncol(x)||nrow(x)<=ncol(x))return(fail("rank_deficiency","Design is rank deficient or undersized"))
  separation<-tryCatch(detect_tri_separation(x,d$.outcome),error=function(e)e)
  if(inherits(separation,"error"))return(fail("diagnostic_failure",conditionMessage(separation)))
  if(separation)return(fail("separation","Complete or quasi-complete separation"))
  warnings<-character()
  fit<-tryCatch(withCallingHandlers(stats::glm(formula,d,family=stats::binomial(),na.action=stats::na.fail,control=stats::glm.control(maxit=config$maxit),
    contrasts=list(sex="contr.treatment",race_ethnicity="contr.treatment",location="contr.treatment")),
    warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e)e)
  row$warnings<-paste(unique(warnings),collapse=" | ")
  if(inherits(fit,"error"))return(fail("convergence_failure",conditionMessage(fit)))
  if(stats::nobs(fit)!=nrow(d))stop("GLM changed the registered sample")
  if(!fit$converged||isTRUE(fit$boundary))return(fail("convergence_failure","GLM convergence or boundary failure"))
  cf<-summary(fit)$coefficients;vv<-stats::vcov(fit)
  if(any(!is.finite(c(cf,vv))))return(fail("rank_deficiency","Nonfinite coefficient/covariance"))
  coefficients<-data.frame(model_id=spec$model_id,term=rownames(cf),estimate=cf[,1],std_error=cf[,2],
    conf_low=cf[,1]-stats::qnorm(.975)*cf[,2],conf_high=cf[,1]+stats::qnorm(.975)*cf[,2],statistic=cf[,3],p_value=cf[,4],
    df=Inf,status="estimated",clinical_or_interpretation=ifelse(grepl("bmi_ns",rownames(cf)),"basis coefficient; no standalone clinical OR","log-odds contrast"),row.names=NULL)
  reference_table<-bmi_bind(refs)
  references<-reference_table[reference_table$is_reference,,drop=FALSE]
  for(i in seq_len(nrow(references)))coefficients<-bmi_bind(list(coefficients,data.frame(model_id=spec$model_id,
    term=paste0(references$variable_id[i],"=",references$level[i]),status="reference_not_estimated",clinical_or_interpretation="reference level")))
  cov<-expand.grid(term1=colnames(vv),term2=colnames(vv),stringsAsFactors=FALSE)
  cov$model_id<-spec$model_id;cov$covariance<-as.vector(vv);cov$correlation<-as.vector(stats::cov2cor(vv))
  row$status<-if(length(warnings))"fitted_with_concerns"else"successful";row$fit_runtime<-unname(proc.time()[3]-start)
  list(row=row,fit=fit,data=d,basis=basis,coefficients=coefficients,covariance=cov,references=reference_table)
}
bmi_model_diagnostics <- function(model,config) {
  id<-model$row$model_id
  if(is.null(model$fit))return(list(model_fit_diagnostics=data.frame(model_id=id,metric="unavailable",value=NA_real_,note=model$row$failure_reason),model_residual_bins=data.frame(),model_influence_summary=data.frame(),model_support=data.frame()))
  fit<-model$fit;d<-model$data;y<-d$.outcome;p<-stats::fitted(fit);n<-length(y);clipped<-pmin(1-1e-15,pmax(1e-15,p))
  x<-stats::model.matrix(fit); norm<-sqrt(colSums(x*x));norm[norm==0]<-1
  vals<-c(log_likelihood=as.numeric(stats::logLik(fit)),null_deviance=fit$null.deviance,residual_deviance=fit$deviance,
    AIC=stats::AIC(fit),Brier=mean((y-p)^2),log_loss=-mean(y*log(clipped)+(1-y)*log(1-clipped)),
    iterations=fit$iter,residual_df=fit$df.residual,scaled_condition_number=kappa(sweep(x,2,norm,"/")),events_per_parameter=sum(y)/ncol(x),nonevents_per_parameter=sum(1-y)/ncol(x))
  metrics<-data.frame(model_id=id,metric=names(vals),value=as.numeric(vals),note="apparent in-sample diagnostic; no validation or causal claim")
  bins<-list();group<-function(kind,g) {
    for(level in sort(unique(g))) {
      ix<-which(g==level);bins[[length(bins)+1L]]<<-data.frame(model_id=id,diagnostic=kind,group=as.character(level),n=length(ix),events=sum(y[ix]),
        observed=mean(y[ix]),fitted=mean(p[ix]),mean_response_residual=mean(y[ix]-p[ix]),mean_deviance_residual=mean(stats::residuals(fit,type="deviance")[ix]))
    }
  }
  group("BMI",config$bmi_bin_width*floor(d$bmi/config$bmi_bin_width));group("age",10*floor(d$age_at_encounter/10))
  for(v in c("sex","race_ethnicity","location"))group(v,as.character(d[[v]]))
  cuts<-unique(stats::quantile(p,seq(0,1,.1),type=config$quantile_type))
  group("fitted_probability",if(length(cuts)>1)cut(p,c(-Inf,cuts[-c(1,length(cuts))],Inf),labels=FALSE)else rep(1,n))
  # Fixed-bin residual/probability histograms prevent export of individual predictions.
  for(v in c("probability","deviance_residual","response_residual")) {
    z<-switch(v,probability=p,deviance_residual=stats::residuals(fit,type="deviance"),response_residual=y-p)
    br<-if(v=="probability")seq(0,1,length.out=21)else seq(min(z)-1e-8,max(z)+1e-8,length.out=21)
    h<-hist(z,breaks=br,plot=FALSE,include.lowest=TRUE)
    bins[[length(bins)+1L]]<-data.frame(model_id=id,diagnostic=paste0("hist_",v),group=seq_along(h$counts),n=h$counts,lower=head(br,-1),upper=tail(br,-1))
    grid<-seq(min(z),max(z),length.out=config$ecdf_grid_size)
    bins[[length(bins)+1L]]<-data.frame(model_id=id,diagnostic=paste0("ecdf_",v),group=seq_along(grid),x=grid,cumulative=stats::ecdf(z)(grid))
  }
  influence<-tryCatch({
    h<-stats::hatvalues(fit);co<-stats::cooks.distance(fit);dfb<-stats::dfbetas(fit)
    items<-list(leverage=list(z=h,threshold=2*ncol(x)/n),cooks=list(z=co,threshold=4/n),max_abs_dfbeta=list(z=apply(abs(dfb),1,max),threshold=2/sqrt(n)))
    bmi_bind(lapply(names(items),function(name){item<-items[[name]];q<-stats::quantile(item$z,c(0,.5,.95,.99,1),type=config$quantile_type)
      data.frame(model_id=id,metric=name,n=n,minimum=q[1],median=q[2],q95=q[3],q99=q[4],maximum=q[5],threshold=item$threshold,n_flagged=sum(item$z>item$threshold),status="full_sample_assessed; flags do not exclude patients",row.names=NULL)}))
  },error=function(e)data.frame(model_id=id,metric="influence",status=paste("unavailable:",conditionMessage(e))))
  support<-list()
  for(v in c("age_at_encounter","sex","race_ethnicity","location")) {
    grp<-if(v=="age_at_encounter")as.character(10*floor(d[[v]]/10))else as.character(d[[v]])
    key<-paste(config$bmi_bin_width*floor(d$bmi/config$bmi_bin_width),grp,sep=":")
    support[[v]]<-bmi_bind(lapply(split(seq_len(n),key),function(ix)data.frame(model_id=id,variable_id=v,level=grp[ix[1]],bin_low=config$bmi_bin_width*floor(d$bmi[ix[1]]/config$bmi_bin_width),n=length(ix),events=sum(y[ix]),nonevents=sum(1-y[ix]),sparse=length(ix)<config$sparse_n||min(sum(y[ix]),sum(1-y[ix]))<config$sparse_events)))
  }
  list(model_fit_diagnostics=metrics,model_residual_bins=bmi_bind(bins),model_influence_summary=influence,model_support=bmi_bind(support))
}
fit_registered_models <- function(ctx,basis,config) {
  registry<-bmi_model_registry(ctx$day_status,if(is.null(config$fit_role))"full"else config$fit_role);models<-list()
  for(i in seq_len(nrow(registry))) {
    spec<-registry[i,,drop=FALSE];d<-ctx$members[[spec$training_population_id]]
    message(sprintf("[model %d/%d] %s",i,nrow(registry),spec$model_id))
    d<-bmi_observation_fields(d)
    models[[spec$model_id]]<-fit_bmi_model(spec,d,basis,config,nrow(ctx$members$C))
    message("[model result] ",spec$model_id,": ",models[[spec$model_id]]$row$status)
  }
  models
}
