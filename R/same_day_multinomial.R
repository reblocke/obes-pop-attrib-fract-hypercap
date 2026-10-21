# One joint recorded-day model. Patient rows and fit objects never enter bundles.
bmi_same_day_classes <- c("no_hypercapnia","without_acidemia","with_acidemia")
bmi_same_day_category <- function(d) {
  result <- rep(NA_character_,nrow(d))
  ok <- d$same_day_abg_state=="coobserved_day"
  result[ok] <- ifelse(d$hypercapnia_acidemia_same_day[ok]==1,"with_acidemia",
    ifelse(d$hypercapnia_coobserved[ok]==1,"without_acidemia","no_hypercapnia"))
  factor(result,levels=bmi_same_day_classes)
}

bmi_multinomial_separation <- function(x,y) {
  # Recession direction: each observed class's predictor >= every alternative,
  # with at least one strict inequality. Baseline coefficients are fixed to zero.
  blocks <- lapply(1:3,function(other) {
    ix <- which(y!=other)
    do.call(cbind,lapply(2:3,function(k)x[ix,,drop=FALSE]*((y[ix]==k)-(other==k))))
  })
  z <- unique(do.call(rbind,blocks));a <- cbind(z,-z)
  result <- lpSolve::lp("max",colSums(a),rbind(a,rep(1,ncol(a))),
    c(rep(">=",nrow(a)),"<="),c(rep(0,nrow(a)),1))
  if(result$status!=0L)stop("Multinomial separation diagnostic failed")
  result$objval>1e-7
}

bmi_multinomial_fit <- function(p,basis,config,qualified,reason) {
  started <- proc.time()[3]
  id <- "same_day_abg/encounter/multinomial_spline"
  formula <- ~bmi_ns1+bmi_ns2+bmi_ns3+age_at_encounter+sex+race_ethnicity+location
  p$.category <- bmi_same_day_category(p)
  row <- data.frame(model_id=id,family="same_day_abg",outcome_id="three_category",
    window="encounter",training_population_id="C_same_day_abg",field=".category",model_form="multinomial_spline",
    source_status=if(qualified)"qualified"else"pending",source_reason=reason,
    formula_text=paste("category",paste(deparse(formula),collapse=" ")),basis_id=basis$basis_id,
    weight_specification="none",covariance_method="joint multinomial observed information; empirical reference fixed",
    n_eligible=if(qualified)nrow(p)else NA_integer_,n_excluded_outcome=0L,n_excluded_adjustment=0L,
    n_model=if(qualified)nrow(p)else NA_integer_,n_patients=if(qualified)length(unique(p$patient_id))else NA_integer_,
    n_events=if(qualified)sum(p$.category!="no_hypercapnia")else NA_integer_,
    n_nonevents=if(qualified)sum(p$.category=="no_hypercapnia")else NA_integer_,
    n_parameters=NA_integer_,model_rank=NA_integer_,status="not_attempted",failure_reason="",warnings="",fit_runtime=0)
  fail <- function(status,why) {
    row$status<-status;row$failure_reason<-why;row$fit_runtime<-unname(proc.time()[3]-started)
    list(row=row,data=p,basis=basis,beta=NULL,coefficients=data.frame(),covariance=data.frame(),references=data.frame(),
      model_fit_diagnostics=data.frame(model_id=id,metric="unavailable",value=NA_real_,note=why),
      model_residual_bins=data.frame(),model_influence_summary=data.frame(model_id=id,metric="influence",status=paste("unavailable:",why)),model_support=data.frame())
  }
  if(!qualified)return(fail("pending_source",reason))
  if(!nrow(p))return(fail("no_evaluable_sample","No eligible co-observed patients"))
  if(anyNA(p[c(triangulation_adjustment,".category")]))stop("Hidden missing multinomial model fields")
  counts <- table(p$.category)
  if(any(counts==0))return(fail("absent_category",paste("Absent planned categories:",paste(names(counts)[counts==0],collapse=", "))))
  if(basis$status!="resolved")return(fail("rank_deficiency",basis$status))
  refs <- list(data.frame(model_id=id,variable_id="outcome",level=bmi_same_day_classes,is_reference=c(TRUE,FALSE,FALSE)))
  for(v in c("sex","race_ethnicity","location")) {
    ref<-config$factor_references[[v]];levels<-sort(unique(as.character(p[[v]])))
    if(!ref %in% levels||length(levels)<2)return(fail("rank_deficiency",paste("Missing factor variation/reference:",v)))
    p[[v]]<-factor(p[[v]],levels=c(ref,setdiff(levels,ref)))
    refs[[v]]<-data.frame(model_id=id,variable_id=v,level=levels(p[[v]]),is_reference=levels(p[[v]])==ref)
  }
  p<-bmi_add_basis(p,basis)
  x<-model.matrix(formula,p,contrasts.arg=list(sex="contr.treatment",race_ethnicity="contr.treatment",location="contr.treatment"))
  row$n_parameters<-2L*ncol(x);row$model_rank<-2L*qr(x)$rank
  if(qr(x)$rank<ncol(x)||nrow(x)<=row$n_parameters)return(fail("rank_deficiency","Joint design is rank deficient or undersized"))
  scale<-apply(abs(x),2,max);scale[scale==0]<-1
  z<-sweep(x,2,scale,"/");y<-as.integer(p$.category)
  separated<-tryCatch(bmi_multinomial_separation(z,y),error=function(e)e)
  if(inherits(separated,"error"))return(fail("diagnostic_failure",conditionMessage(separated)))
  if(separated)return(fail("separation","Complete or quasi-complete multinomial separation"))
  warnings<-character()
  fit<-tryCatch(withCallingHandlers(nnet::multinom(y~X-1,data=list(y=p$.category,X=z),Hess=TRUE,
    trace=FALSE,decay=0,maxit=config$multinomial_maxit,reltol=1e-12,abstol=1e-10,na.action=na.fail),
    warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e)e)
  row$warnings<-paste(unique(warnings),collapse=" | ")
  if(inherits(fit,"error"))return(fail("convergence_failure",conditionMessage(fit)))
  if(fit$convergence!=0L)return(fail("convergence_failure","Multinomial optimizer did not converge"))
  h<-fit$Hessian
  eigenvalues<-eigen(h,symmetric=TRUE,only.values=TRUE)$values
  if(any(!is.finite(h))||min(eigenvalues)<=max(eigenvalues)*1e-10)return(fail("rank_deficiency","Singular or ill-conditioned joint observed information"))
  beta<-as.vector(t(coef(fit)))/rep(scale,2)
  terms<-unlist(lapply(bmi_same_day_classes[-1],function(k)paste(k,colnames(x),sep="::")))
  names(beta)<-terms
  v<-solve(h)/outer(rep(scale,2),rep(scale,2));dimnames(v)<-list(terms,terms)
  if(any(!is.finite(c(beta,v))))return(fail("rank_deficiency","Nonfinite joint coefficients/covariance"))
  pr<-as.matrix(fitted(fit));truth<-diag(3)[y,,drop=FALSE]
  score<-as.vector(crossprod(z,(pr-truth)[,2:3,drop=FALSE]))
  if(max(abs(score))/nrow(p)>1e-6)return(fail("convergence_failure","Optimizer score remains above tolerance"))
  se<-sqrt(diag(v));stat<-beta/se
  coefficients<-data.frame(model_id=id,term=terms,category_id=rep(bmi_same_day_classes[-1],each=ncol(x)),
    estimate=beta,std_error=se,conf_low=beta-qnorm(.975)*se,conf_high=beta+qnorm(.975)*se,
    statistic=stat,p_value=2*pnorm(-abs(stat)),df=Inf,status="estimated",
    clinical_or_interpretation="log category-probability ratio versus no hypercapnia; spline terms have no standalone clinical interpretation",row.names=NULL)
  covariance<-expand.grid(term1=terms,term2=terms,stringsAsFactors=FALSE)
  covariance$model_id<-id;covariance$covariance<-as.vector(v);covariance$correlation<-as.vector(cov2cor(v))
  values<-c(log_likelihood=as.numeric(logLik(fit)),AIC=AIC(fit),multiclass_Brier=mean(rowSums((truth-pr)^2)),
    log_loss=-mean(log(pr[cbind(seq_len(nrow(p)),y)])),optimizer_code=fit$convergence,
    maximum_scaled_score_per_patient=max(abs(score))/nrow(p),information_condition_number=max(eigenvalues)/min(eigenvalues))
  diagnostics<-data.frame(model_id=id,metric=names(values),value=as.numeric(values),note="apparent in-sample diagnostic; not independent validation")
  residuals<-support<-list()
  for(k in 1:3)for(variable in c("bmi","age_at_encounter","sex","race_ethnicity","location")) {
    grp<-if(variable=="bmi")config$bmi_bin_width*floor(p$bmi/config$bmi_bin_width)else if(variable=="age_at_encounter")10*floor(p[[variable]]/10)else as.character(p[[variable]])
    for(g in unique(grp)) {
      ix<-which(grp==g)
      residuals[[length(residuals)+1L]]<-data.frame(model_id=id,category_id=bmi_same_day_classes[k],diagnostic=variable,group=g,n=length(ix),events=sum(y[ix]==k),observed=mean(y[ix]==k),fitted=mean(pr[ix,k]),mean_response_residual=mean((y[ix]==k)-pr[ix,k]))
    }
    if(variable!="bmi")for(ix in split(seq_len(nrow(p)),paste(floor(p$bmi/config$bmi_bin_width),grp)))
      support[[length(support)+1L]]<-data.frame(model_id=id,category_id=bmi_same_day_classes[k],variable_id=variable,level=grp[ix[1]],bin_low=config$bmi_bin_width*floor(p$bmi[ix[1]]/config$bmi_bin_width),n=length(ix),events=sum(y[ix]==k),nonevents=sum(y[ix]!=k),sparse=length(ix)<config$sparse_n||min(sum(y[ix]==k),sum(y[ix]!=k))<config$sparse_events)
  }
  row$status<-if(length(warnings))"fitted_with_concerns"else"successful";row$fit_runtime<-unname(proc.time()[3]-started)
  list(row=row,data=p,basis=basis,beta=beta,v=v,formula=formula,design_names=colnames(x),
    coefficients=coefficients,covariance=covariance,references=bmi_bind(refs),model_fit_diagnostics=diagnostics,
    model_residual_bins=bmi_bind(residuals),model_support=bmi_bind(support),
    model_influence_summary=data.frame(model_id=id,metric="case_deletion_influence",status="unavailable: no validated multinomial case-deletion implementation; no patients removed"))
}

bmi_multinomial_mean <- function(m,b,config) {
  sums<-numeric(3);gradient<-matrix(0,3,length(m$beta));n<-nrow(m$data)
  for(start in seq(1,n,by=config$chunk_size)) {
    d<-m$data[start:min(n,start+config$chunk_size-1),,drop=FALSE];d$bmi<-b;d<-bmi_add_basis(d,m$basis)
    x<-model.matrix(m$formula,d,contrasts.arg=list(sex="contr.treatment",race_ethnicity="contr.treatment",location="contr.treatment"))
    if(!identical(colnames(x),m$design_names))stop("Joint prediction design changed")
    eta<-cbind(0,x%*%matrix(m$beta,ncol=2));eta<-eta-apply(eta,1,max)
    pr<-exp(eta);pr<-pr/rowSums(pr);sums<-sums+colSums(pr)
    for(k in 1:3)for(l in 2:3) {
      cols<-(l-2)*ncol(x)+seq_len(ncol(x))
      gradient[k,cols]<-gradient[k,cols]+colSums(x*(pr[,k]*((k==l)-pr[,l])))
    }
  }
  list(p=c(sums,sum(sums[2:3]))/n,g=rbind(gradient,colSums(gradient[2:3,,drop=FALSE]))/n)
}

bmi_multinomial_predictions <- function(m,config) {
  outcomes<-c(bmi_same_day_classes,"any_hypercapnia")
  base<-data.frame(model_id=m$row$model_id,reference_id="C_same_day_abg",n_reference=m$row$n_model,n_model=m$row$n_model,
    window="encounter",family="same_day_abg",ascertainment_window="encounter",model_form="multinomial_spline")
  if(is.null(m$beta))return(list(probability_curves=bmi_bind(lapply(outcomes,function(o)cbind(base,outcome_id=o,bmi=NA_real_,probability=NA_real_,conf_low=NA_real_,conf_high=NA_real_,within_training_bmi_range=NA,status=m$row$status,reason=m$row$failure_reason))),
    same_day_contrasts=cbind(base,outcome_id="with_minus_without_change",bmi_low=NA_real_,bmi_high=NA_real_,difference_per1000=NA_real_,conf_low_per1000=NA_real_,conf_high_per1000=NA_real_,status=m$row$status,reason=m$row$failure_reason),same_day_probability_covariance=data.frame(),same_day_curve_reconciliation=data.frame(status="not_assessed",reason=m$row$failure_reason)))
  bounds<-range(m$data$bmi);first<-ceiling(bounds[1]/config$grid_step)*config$grid_step
  grid<-sort(unique(c(bounds,if(first<=bounds[2])seq(first,bounds[2],by=config$grid_step)else numeric())))
  values<-lapply(grid,function(b)bmi_multinomial_mean(m,b,config));names(values)<-as.character(grid)
  curves<-covariances<-list()
  for(i in seq_along(grid)) {
    b<-grid[i];value<-values[[i]];v<-value$g%*%m$v%*%t(value$g)
    local<-m$data[abs(m$data$bmi-b)<=config$bmi_bin_width/2,,drop=FALSE]
    missing_levels<-sum(vapply(c("sex","race_ethnicity","location"),function(name)length(setdiff(unique(as.character(m$data[[name]])),unique(as.character(local[[name]])))),integer(1)))
    for(k in 1:4) {
      events<-if(k==4)sum(local$.category!="no_hypercapnia")else sum(local$.category==outcomes[k])
      ci<-bmi_probability_interval(value$p[k],value$g[k,],m$v)
      curves[[length(curves)+1L]]<-cbind(base,outcome_id=outcomes[k],bmi=b,probability=value$p[k],conf_low=ci[1],conf_high=ci[2],within_training_bmi_range=TRUE,
        local_n=nrow(local),local_events=events,local_nonevents=nrow(local)-events,locally_sparse=nrow(local)<config$sparse_n||min(events,nrow(local)-events)<config$sparse_events,
        missing_local_factor_levels=missing_levels,status="estimated",reason="")
    }
    cv<-expand.grid(outcome1=outcomes,outcome2=outcomes);cv$model_id<-m$row$model_id;cv$bmi<-b;cv$covariance<-as.vector(v)
    covariances[[i]]<-cv
  }
  # Fixed five-unit intervals throughout the observed range, plus the registered
  # contrast; never select intervals after inspecting estimated associations.
  starts<-seq(5*floor(bounds[1]/5),5*ceiling(bounds[2]/5),by=5)
  pairs<-data.frame(low=starts,high=starts+5);pairs<-pairs[pairs$low>=bounds[1]&pairs$high<=bounds[2],]
  pairs<-unique(rbind(pairs,data.frame(low=config$fixed_bmi_contrast[[1]],high=config$fixed_bmi_contrast[[2]])))
  contrasts<-list()
  for(i in seq_len(nrow(pairs))) {
    lo<-pairs$low[i];hi<-pairs$high[i]
    if(lo<bounds[1]||hi>bounds[2]) {
      contrasts[[length(contrasts)+1L]]<-cbind(base,outcome_id="with_minus_without_change",bmi_low=lo,bmi_high=hi,status="outside_training_range",reason="Registered contrast not estimated outside training BMI range")
      next
    }
    low<-bmi_multinomial_mean(m,lo,config);high<-bmi_multinomial_mean(m,hi,config)
    for(k in 1:5) {
      if(k<=4) {
        delta<-high$p[k]-low$p[k];g<-high$g[k,]-low$g[k,]
        cl<-bmi_probability_interval(low$p[k],low$g[k,],m$v);ch<-bmi_probability_interval(high$p[k],high$g[k,],m$v)
        ratio<-high$p[k]/low$p[k];se_ratio<-sqrt(bmi_delta_variance(high$g[k,]/high$p[k]-low$g[k,]/low$p[k],m$v))
        cr<-exp(log(ratio)+c(-1,1)*qnorm(.975)*se_ratio)
        fields<-data.frame(probability_low_bmi=low$p[k],probability_high_bmi=high$p[k],probability_low_bmi_low=cl[1],probability_low_bmi_high=cl[2],probability_high_bmi_low=ch[1],probability_high_bmi_high=ch[2],prevalence_ratio=ratio,ratio_low=cr[1],ratio_high=cr[2])
      }else {
        delta<-(high$p[3]-low$p[3])-(high$p[2]-low$p[2]);g<-(high$g[3,]-low$g[3,])-(high$g[2,]-low$g[2,]);fields<-data.frame(probability_low_bmi=NA_real_,probability_high_bmi=NA_real_)
      }
      variance<-bmi_delta_variance(g,m$v);ci<-delta+c(-1,1)*qnorm(.975)*sqrt(variance)
      involved<-if(k<=4)outcomes[k]else outcomes[2:3]
      local_sparse<-any(vapply(c(lo,hi),function(b){
        z<-m$data[abs(m$data$bmi-b)<=config$bmi_bin_width/2,,drop=FALSE]
        any(vapply(involved,function(o){n<-if(o=="any_hypercapnia")sum(z$.category!="no_hypercapnia")else sum(z$.category==o);nrow(z)<config$sparse_n||min(n,nrow(z)-n)<config$sparse_events},logical(1)))
      },logical(1)))
      contrasts[[length(contrasts)+1L]]<-cbind(base,outcome_id=c(outcomes,"with_minus_without_change")[k],bmi_low=lo,bmi_high=hi,fields,
        difference_per1000=1000*delta,conf_low_per1000=1000*ci[1],conf_high_per1000=1000*ci[2],variance_difference=variance,locally_sparse=local_sparse,status="estimated",reason="Pointwise descriptive contrast; not multiplicity adjusted")
    }
  }
  list(probability_curves=bmi_bind(curves),same_day_contrasts=bmi_bind(contrasts),same_day_probability_covariance=bmi_bind(covariances),
    same_day_curve_reconciliation=data.frame(model_id=m$row$model_id,n_grid=length(grid),maximum_probability_sum_error=max(vapply(values,function(v)abs(sum(v$p[1:3])-1),numeric(1))),maximum_component_sum_error=max(vapply(values,function(v)abs(sum(v$p[2:3])-v$p[4]),numeric(1))),status="assessed"))
}
