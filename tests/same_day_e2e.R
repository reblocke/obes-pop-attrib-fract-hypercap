# Independent softmax likelihood and finite-difference oracle, written before
# replacing the supplemental binary estimator. No production prediction helpers.
e2e_same_day <- function(bundle,raw,population="primary") {
  a <- bundle$analysis
  id <- paste0(population,"::same_day_abg/encounter/multinomial_spline")
  classes <- c("no_hypercapnia","without_acidemia","with_acidemia")
  r <- a$model_registry[a$model_registry$model_id==id,,drop=FALSE]
  stopifnot(nrow(r)==1L,r$status=="successful",!any(a$policy_totals$model_id==id))
  q <- e2e_indexes(raw)
  q <- q[q$group=="primary" & complete.cases(q[c("bmi","age_at_encounter","sex","race_ethnicity","location","encounter_type")]),]
  if(population=="primary_bmi_ge30")q<-q[q$bmi>=30,,drop=FALSE]
  p <- q[q$same_day_abg_state=="coobserved_day",]
  y <- ifelse(p$hypercapnia_acidemia_same_day==1,3L,ifelse(p$hypercapnia_coobserved==1,2L,1L))
  stopifnot(all(p$hypercapnia_acidemia_same_day<=p$hypercapnia_coobserved),r$n_model==nrow(p))
  cats <- a$cooccurrence_categories[a$cooccurrence_categories$analysis_population_id==population,]
  e2e_near(cats$n[match(classes,cats$category_id)],tabulate(y,3))
  knots <- as.numeric(quantile(q$bmi,c(.05,.35,.65,.95),type=7))
  for(v in c("sex","race_ethnicity","location"))
    p[[v]] <- factor(p[[v]],levels=c("0",setdiff(sort(unique(p[[v]])),"0")))
  p$encounter_type <- factor(p$encounter_type,levels=c("EMER","IMP"))
  design <- function(bmi) {
    new <- p
    b <- splines::ns(bmi,knots=knots[2:3],Boundary.knots=knots[c(1,4)],intercept=FALSE)
    for(k in 1:3)new[[paste0("bmi_ns",k)]] <- b[,k]
    model.matrix(~bmi_ns1+bmi_ns2+bmi_ns3+age_at_encounter+sex+race_ethnicity+location+encounter_type,new)
  }
  x <- design(p$bmi);scale <- apply(abs(x),2,max);z <- sweep(x,2,scale,"/")
  softmax <- function(theta,x) {
    eta <- cbind(0,x%*%matrix(theta,ncol=2))
    eta <- eta-apply(eta,1,max);w <- exp(eta);w/rowSums(w)
  }
  target <- diag(3)[y,,drop=FALSE]
  fn <- function(theta)-sum(log(softmax(theta,z)[cbind(seq_along(y),y)]))
  gr <- function(theta)as.vector(crossprod(z,(softmax(theta,z)-target)[,2:3,drop=FALSE]))
  fit <- optim(rep(0,2*ncol(x)),fn,gr,method="BFGS",control=list(maxit=3000,reltol=1e-12),hessian=TRUE)
  stopifnot(fit$convergence==0L)
  theta <- fit$par/rep(scale,2)
  v <- solve(fit$hessian)/outer(rep(scale,2),rep(scale,2))
  terms <- unlist(lapply(classes[-1],function(k)paste(k,colnames(x),sep="::")))
  cf <- a$coefficients[a$coefficients$model_id==id & a$coefficients$status=="estimated",]
  e2e_near(cf$estimate[match(terms,cf$term)],theta,tolerance=2e-4)
  saved_cov <- a$coefficient_covariance[a$coefficient_covariance$model_id==id,]
  vm <- matrix(NA_real_,length(terms),length(terms))
  vm[cbind(match(saved_cov$term1,terms),match(saved_cov$term2,terms))] <- saved_cov$covariance
  e2e_near(vm,v,tolerance=2e-4)
  means <- function(beta,b) {
    pr <- colMeans(softmax(beta,design(rep(b,nrow(p)))))
    c(pr,sum(pr[2:3]))
  }
  derivative <- function(fun,beta) vapply(seq_along(beta),function(k) {
    plus<-minus<-beta;plus[k]<-plus[k]+1e-5;minus[k]<-minus[k]-1e-5
    (fun(plus)-fun(minus))/2e-5
  },numeric(1))
  curves <- a$probability_curves[a$probability_curves$model_id==id,]
  for(b in unique(c(head(curves$bmi,1),40,45,tail(curves$bmi,1)))) {
    means_b <- means(theta,b)
    for(k in 1:4) {
      key <- c(classes,"any_hypercapnia")[k]
      row <- curves[curves$bmi==b & curves$outcome_id==key,]
      if(!nrow(row))next
      g <- derivative(function(beta)means(beta,b)[k],theta)
      pp <- means_b[k];se <- sqrt(drop(t(g)%*%v%*%g))/(pp*(1-pp))
      ci <- plogis(qlogis(pp)+c(-1,1)*qnorm(.975)*se)
      e2e_near(c(row$probability,row$conf_low,row$conf_high),c(pp,ci),tolerance=2e-4)
    }
  }
  for(b in unique(curves$bmi)) {
    at <- curves[curves$bmi==b,]; pp <- setNames(at$probability,at$outcome_id)
    e2e_near(sum(pp[classes]),1);e2e_near(sum(pp[classes[-1]]),pp['any_hypercapnia'])
    stopifnot(all(pp>=0 & pp<=1))
  }
  contrasts <- a$same_day_contrasts[a$same_day_contrasts$model_id==id,]
  zc <- contrasts[contrasts$bmi_low==40 & contrasts$bmi_high==45,]
  for(k in 1:5) {
    key <- c(classes,"any_hypercapnia","with_minus_without_change")[k]
    fun <- function(beta) {
      delta <- means(beta,45)-means(beta,40)
      if(k<=4)delta[k]else delta[3]-delta[2]
    }
    d <- fun(theta);g <- derivative(fun,theta);variance <- drop(t(g)%*%v%*%g)
    row <- zc[zc$outcome_id==key,]
    stopifnot(nrow(row)==1)
    e2e_near(c(row$difference_per1000,row$conf_low_per1000,row$conf_high_per1000),
      1000*c(d,d-qnorm(.975)*sqrt(variance),d+qnorm(.975)*sqrt(variance)),tolerance=2e-4)
  }
  if(population=="primary") {
  # Original analysis must be unchanged when the optional module is absent.
  base <- bmi_run_analysis(raw[setdiff(names(raw),bmi_same_day_fields)],bundle$config)
  for(name in c("coefficients","coefficient_covariance","probability_curves","policy_totals","policy_contributions","policy_contribution_covariance")) {
    current<-a[[name]];original<-base[[name]]
    current<-current[!grepl("::same_day_abg/",current$model_id),,drop=FALSE];original<-original[!grepl("::same_day_abg/",original$model_id),,drop=FALSE]
    # Joint class labels add an all-NA metadata column to primary rows only.
    for(field in setdiff(names(current),names(original))) {
      stopifnot(all(is.na(current[[field]])));original[[field]]<-current[[field]][rep(NA_integer_,nrow(original))]
    }
    for(field in setdiff(names(original),names(current))) {
      stopifnot(all(is.na(original[[field]])));current[[field]]<-original[[field]][rep(NA_integer_,nrow(current))]
    }
    original<-original[names(current)]
    rownames(current)<-rownames(original)<-NULL
    stopifnot(isTRUE(all.equal(current,original,tolerance=1e-10,check.attributes=FALSE)))
  }
  pending <- base$model_registry[base$model_registry$model_id==id,]
  stopifnot(nrow(pending)==1L,pending$status=="pending_source",is.na(pending$n_model))
  bad <- raw;bad$hypercapnia_acidemia_same_day[bad$same_day_abg_state=="coobserved_day"]<-0L
  constant <- bmi_run_analysis(bad,bundle$config)
  stopifnot(constant$model_registry$status[constant$model_registry$model_id==id]=="absent_category",
    all(is.na(constant$probability_curves$probability[constant$probability_curves$model_id==id])))
  # Observable rank failure; do not silently pool a missing declared factor reference.
  bad <- raw;bad$sex[!is.na(bad$sex)] <- "1"
  deficient <- bmi_run_analysis(bad,bundle$config)
  stopifnot(deficient$model_registry$status[deficient$model_registry$model_id==id]=="rank_deficiency")
  }
  invisible(data.frame(model_id=id,n=nrow(p),status="independent likelihood, joint covariance and signed contrasts confirmed"))
}
