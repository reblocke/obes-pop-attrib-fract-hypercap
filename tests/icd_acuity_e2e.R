# Independent classification/likelihood/gradient checks planned before production edits.
e2e_icd_acuity <- function(bundle,raw) {
  a<-bundle$analysis;id<-"primary::icd_acuity/encounter/multinomial_spline"
  q<-e2e_indexes(raw);q<-q[q$group=="primary" & complete.cases(q[triangulation_adjustment]),]
  p<-q[q$icd_capture_state=="complete",]
  classes<-c("no_target","chronic_ohs","acute_chronic","acute","unspecified")
  category<-with(p,ifelse(icd_J9622==1 | (icd_J9602==1 & (icd_J9612==1|icd_E662==1)),"acute_chronic",
    ifelse(icd_J9602==1,"acute",ifelse(icd_J9612==1|icd_E662==1,"chronic_ohs",ifelse(icd_J9692==1,"unspecified","no_target")))))
  y<-match(category,classes);r<-a$model_registry[a$model_registry$model_id==id,]
  stopifnot(nrow(r)==1,r$status=="successful",r$n_model==nrow(p),!any(a$policy_totals$model_id==id))
  e2e_near(a$icd_acuity_categories$n,tabulate(y,5))
  knots<-as.numeric(quantile(q$bmi,c(.05,.35,.65,.95),type=7))
  for(v in c("sex","race_ethnicity","location"))p[[v]]<-factor(p[[v]],levels=c("0",setdiff(sort(unique(p[[v]])),"0")))
  design<-function(bmi) {
    d<-p;b<-splines::ns(bmi,knots=knots[2:3],Boundary.knots=knots[c(1,4)])
    for(k in 1:3)d[[paste0("bmi_ns",k)]]<-b[,k]
    model.matrix(~bmi_ns1+bmi_ns2+bmi_ns3+age_at_encounter+sex+race_ethnicity+location,d)
  }
  x<-design(p$bmi);scale<-apply(abs(x),2,max);z<-sweep(x,2,scale,"/")
  softmax<-function(beta,x) {eta<-cbind(0,x%*%matrix(beta,ncol=4));eta<-eta-apply(eta,1,max);pr<-exp(eta);pr/rowSums(pr)}
  truth<-diag(5)[y,,drop=FALSE]
  fn<-function(beta)-sum(log(softmax(beta,z)[cbind(seq_along(y),y)]))
  gr<-function(beta)as.vector(crossprod(z,(softmax(beta,z)-truth)[,2:5]))
  fit<-optim(rep(0,4*ncol(x)),fn,gr,method="BFGS",control=list(maxit=3000,reltol=1e-12),hessian=TRUE)
  stopifnot(fit$convergence==0)
  theta<-fit$par/rep(scale,4);v<-solve(fit$hessian)/outer(rep(scale,4),rep(scale,4))
  terms<-unlist(lapply(classes[-1],function(k)paste(k,colnames(x),sep="::")))
  cf<-a$coefficients[a$coefficients$model_id==id,]
  e2e_near(cf$estimate[match(terms,cf$term)],theta,tolerance=3e-4)
  means<-function(beta,b) {pr<-colMeans(softmax(beta,design(rep(b,nrow(p)))));c(pr,sum(pr[-1]))}
  derivative<-function(fun) vapply(seq_along(theta),function(k){plus<-minus<-theta;plus[k]<-plus[k]+1e-5;minus[k]<-minus[k]-1e-5;(fun(plus)-fun(minus))/2e-5},numeric(1))
  curves<-a$probability_curves[a$probability_curves$model_id==id,]
  for(b in c(40,45))for(k in 1:6) {
    row<-curves[curves$bmi==b & curves$outcome_id==c(classes,"any_target")[k],]
    pp<-means(theta,b)[k];g<-derivative(function(beta)means(beta,b)[k]);se<-sqrt(drop(t(g)%*%v%*%g))/(pp*(1-pp))
    e2e_near(c(row$probability,row$conf_low,row$conf_high),c(pp,plogis(qlogis(pp)+c(-1,1)*qnorm(.975)*se)),tolerance=3e-4)
  }
  zc<-a$icd_acuity_contrasts;zc<-zc[zc$bmi_low==40 & zc$bmi_high==45,]
  for(i in 2:5)for(j in 2:5)if(i>j) {
    key<-paste0(classes[i],"_minus_",classes[j],"_change")
    row<-zc[zc$outcome_id==key,];stopifnot(nrow(row)==1)
    fun<-function(beta){delta<-means(beta,45)-means(beta,40);delta[i]-delta[j]}
    d<-fun(theta);g<-derivative(fun);se<-sqrt(drop(t(g)%*%v%*%g))
    e2e_near(c(row$difference_per1000,row$conf_low_per1000,row$conf_high_per1000),1000*c(d,d-qnorm(.975)*se,d+qnorm(.975)*se),tolerance=3e-4)
  }
  # All 32 patterns, independently enumerated, including unspecified co-coding.
  patterns<-expand.grid(rep(list(0:1),5));names(patterns)<-c("icd_J9602","icd_J9612","icd_J9622","icd_J9692","icd_E662")
  expected<-with(patterns,ifelse(icd_J9622==1 | (icd_J9602==1&(icd_J9612==1|icd_E662==1)),"acute_chronic",ifelse(icd_J9602==1,"acute",ifelse(icd_J9612==1|icd_E662==1,"chronic_ohs",ifelse(icd_J9692==1,"unspecified","no_target")))))
  patterns$icd_capture_state<-"complete"
  stopifnot(identical(as.character(bmi_icd_category(patterns)),expected))
  patterns$icd_capture_state<-"incomplete";stopifnot(all(is.na(bmi_icd_category(patterns))))
  absent<-bmi_run_analysis(raw[setdiff(names(raw),bmi_icd_fields)],bundle$config)
  stopifnot(absent$model_registry$status[absent$model_registry$model_id==id]=="pending_source")
  for(name in c("coefficients","coefficient_covariance","probability_curves","policy_totals","policy_contributions","policy_contribution_covariance")) {
    current<-a[[name]];base<-absent[[name]]
    current<-current[current$model_id!=id,,drop=FALSE];base<-base[base$model_id!=id,,drop=FALSE]
    rownames(current)<-rownames(base)<-NULL
    stopifnot(isTRUE(all.equal(current,base,tolerance=1e-10,check.attributes=FALSE)))
  }
  invalid<-raw;invalid$icd_J9602[1]<-2
  stopifnot(inherits(try(bmi_run_analysis(invalid,bundle$config),silent=TRUE),"try-error"))
  constant<-raw;constant$icd_J9692[constant$icd_J9692==1]<-0
  constant$icd_J9602[raw$icd_J9692==1]<-1
  failed<-bmi_run_analysis(constant,bundle$config)
  stopifnot(failed$model_registry$status[failed$model_registry$model_id==id]=="absent_category")
  data.frame(model_id=id,n=nrow(p),status="independent likelihood, intervals, signed comparisons and base invariance verified")
}
