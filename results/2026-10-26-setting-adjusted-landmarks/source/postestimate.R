#!/usr/bin/env Rscript
# Private prediction-only extraction; no fitted objects, dates, keys or rows are exported.
args<-commandArgs(TRUE);if(length(args)!=4L)stop('Use RUN INPUT MANIFEST OUTPUT; fixture/fixture for artificial verification')
script<-gsub('~+~',' ',sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE)[1]),fixed=TRUE)
source('R/analysis.R');source(file.path(dirname(normalizePath(script)),'verify_gradients.R'))
b<-bmi_read_bundle(normalizePath(args[1]));a<-b$analysis;config<-b$config
out<-args[4];if(dir.exists(out))stop('Fresh output directory required');dir.create(out,recursive=TRUE,mode='0700')
before<-bmi_hash_files(bmi_estimation_files());bundle_sha<-tri_sha256(file.path(args[1],'bundle_manifest.json'))
# Real clinical fit entrypoints and low-level glm are forbidden in this process.
fit_bmi_model<-bmi_multinomial_fit<-bmi_firth_multinomial<-bmi_run_analysis<-function(...)stop('Post-estimation may not fit models')
trace('glm',where=asNamespace('stats'),tracer=quote(stop('No glm fits during post-estimation')),print=FALSE)
trace('glm.fit',where=asNamespace('stats'),tracer=quote(stop('No glm.fit during post-estimation')),print=FALSE)
receipt<-list(status='started',scope='fixed saved-fit BMI 30/40 post-estimation; not a clinical model rerun',clinical_models_fitted=0L,bundle_manifest_sha256=bundle_sha,estimation_sources=before)
if(args[2]=='fixture'&&args[3]=='fixture') {
  if(b$manifest$mode!='fixture')stop('Fixture sentinel with clinical bundle')
  source('tests/fixtures/bmi_curve_fixture.R');raw<-make_bmi_curve_fixture();receipt$input_source<-'ARTIFICIAL fixture'
}else{
  if(b$manifest$mode!='clinical')stop('Clinical input requires clinical bundle')
  old<-jsonlite::read_json(file.path(args[1],'input_receipt.json'))
  if(tri_sha256(args[2])!=old$input_sha256||tri_sha256(args[3])!=old$manifest_sha256)stop('Input/manifest identity differs from accepted run')
  loaded<-bmi_load_input(normalizePath(args[2]),normalizePath(args[3]),audit_only=FALSE)
  raw<-loaded$data;receipt$input_sha256<-loaded$input_sha256;receipt$input_manifest_sha256<-loaded$manifest_sha256
}
ctx<-construct_cohort_and_memberships(raw);q<-ctx$members$Q;q<-q[q$rfs_group=='primary',,drop=FALSE]
ctxp<-bmi_fixed_population(ctx,q);C<-ctxp$members$C
for(key in c('Q','C','C_abg_encounter','C_any_gas_encounter')) {
  expected<-a$cohort_nodes$n[a$cohort_nodes$population_id==paste0('primary::',key)]
  if(length(expected)!=1L||nrow(ctxp$members[[key]])!=expected)stop('Reference population mismatch: ',key)
}
k<-a$bmi_basis[a$bmi_basis$analysis_population_id=='primary',];k<-k[order(k$knot_probability),]
basis<-list(knots=k$knot,quantile_type=7,status='resolved',basis_id=k$basis_id[1]);stopifnot(nrow(k)==4L)
formula<-bmi_model_formula()
covariate_factors<-function(d,id) {
  r<-a$factor_references[a$factor_references$model_id==id,]
  for(v in bmi_adjustment_factors) {
    z<-r[r$variable_id==v,,drop=FALSE];lev<-as.character(z$level)
    if(anyNA(d[[v]])||!setequal(unique(as.character(d[[v]])),lev))stop('Factor evidence/level mismatch: ',id,' ',v)
    d[[v]]<-factor(d[[v]],levels=lev)
  };d
}
parameters<-function(id) {
  cf<-a$coefficients[a$coefficients$model_id==id&a$coefficients$status=='estimated',];beta<-setNames(cf$estimate,cf$term)
  cv<-a$coefficient_covariance[a$coefficient_covariance$model_id==id,]
  v<-matrix(NA_real_,length(beta),length(beta),dimnames=list(names(beta),names(beta)))
  v[cbind(match(cv$term1,names(beta)),match(cv$term2,names(beta)))]<-cv$covariance
  if(anyNA(v)||max(abs(v-t(v)))>1e-10)stop('Saved covariance/parameter mismatch: ',id)
  list(beta=beta,v=v)
}
results<-reproduction<-gradchecks<-list();z<-qnorm(.975)
add<-function(id,metric,estimate,g,v,scale=1,logit=FALSE,n=NA_real_) {
  variance<-bmi_delta_variance(g,v)
  ci<-if(logit)bmi_probability_interval(estimate,g,v)else estimate+c(-1,1)*z*sqrt(variance)
  results[[length(results)+1L]]<<-data.frame(model_id=id,metric=metric,estimate=scale*estimate,conf_low=scale*ci[1],conf_high=scale*ci[2],variance=scale^2*variance,scale=scale,n_reference=n)
}
reproduce<-function(id,outcome,bmi,p,g,v) {
  old<-a$probability_curves[a$probability_curves$model_id==id&a$probability_curves$outcome_id==outcome&a$probability_curves$bmi==bmi,]
  ci<-bmi_probability_interval(p,g,v);error<-max(abs(c(old$probability-p,old$conf_low-ci[1],old$conf_high-ci[2])))
  if(nrow(old)!=1L||!is.finite(error)||error>1e-10)stop('Saved curve/interval did not reproduce: ',id,' ',bmi)
  reproduction[[length(reproduction)+1L]]<<-data.frame(model_id=id,outcome_id=outcome,bmi=bmi,maximum_probability_or_interval_error=error)
}
for(outcome in c('abg','any_gas')) {
  id<-paste0('primary::',outcome,'/encounter/spline');row<-a$model_registry[a$model_registry$model_id==id,]
  d<-covariate_factors(ctxp$members[[paste0('C_',outcome,'_encounter')]],id);par<-parameters(id)
  fit<-list(terms=terms(formula),coefficients=par$beta,xlevels=lapply(d[bmi_adjustment_factors],levels),contrasts=bmi_factor_contrasts)
  m<-list(row=row,fit=fit,data=d,basis=basis);vals<-lapply(c(30,35,40,45),function(x)bmi_mean_prediction(m,d,config,bmi=x));names(vals)<-c('30','35','40','45')
  for(bmi in c(30,35,40,45)){r<-vals[[as.character(bmi)]];reproduce(id,outcome,bmi,r$probability,r$gradient,par$v)}
  for(bmi in c(30,40)){r<-vals[[as.character(bmi)]];add(id,paste0('probability_at_',bmi),r$probability,r$gradient,par$v,100,TRUE,nrow(d))}
  g<-vals[['40']]$gradient-vals[['30']]$gradient
  add(id,'difference_40_minus_30_pp',vals[['40']]$probability-vals[['30']]$probability,g,par$v,100,n=nrow(d))
  old<-a$fixed_bmi_contrasts[a$fixed_bmi_contrasts$model_id==id,];difference<-vals[['45']]$probability-vals[['40']]$probability;se<-sqrt(bmi_delta_variance(vals[['45']]$gradient-vals[['40']]$gradient,par$v))
  stopifnot(nrow(old)==1L,max(abs(c(difference, difference-z*se,difference+z*se)-c(old$difference_per1000,old$conf_low_per1000,old$conf_high_per1000)/1000))<1e-10)
  gradchecks[[id]]<-verify_gradient(par$beta,function(beta)bmi_mean_prediction(m,d,config,bmi=40,coefficients=beta)$probability-bmi_mean_prediction(m,d,config,bmi=30,coefficients=beta)$probability,g,id)
}
id<-'primary::same_day_abg/encounter/multinomial_spline';par<-parameters(id)
d<-C[C$same_day_abg_state=='coobserved_day',,drop=FALSE];d<-covariate_factors(d,id)
row<-a$model_registry[a$model_registry$model_id==id,];stopifnot(nrow(d)==row$n_model)
x<-model.matrix(formula,bmi_add_basis(d[1:min(10,nrow(d)),],basis),contrasts.arg=bmi_factor_contrasts)
expected_names<-unlist(lapply(bmi_same_day_classes[-1],function(cl)paste(cl,colnames(x),sep='::')))
stopifnot(identical(names(par$beta),expected_names))
m<-list(row=row,data=d,basis=basis,spec=bmi_same_day_spec(),beta=par$beta,v=par$v,formula=formula,design_names=colnames(x))
vals<-lapply(c(30,35,40,45),function(x)bmi_multinomial_mean(m,x,config));names(vals)<-c('30','35','40','45')
for(bmi in c(30,35,40,45))for(j in 1:4){r<-vals[[as.character(bmi)]];reproduce(id,c(bmi_same_day_classes,'any_hypercapnia')[j],bmi,r$p[j],r$g[j,],par$v)}
for(j in 2:4) {
  delta<-vals[['40']]$p[j]-vals[['30']]$p[j];g<-vals[['40']]$g[j,]-vals[['30']]$g[j,]
  add(id,paste0(c(bmi_same_day_classes,'any_hypercapnia')[j],'_difference_40_minus_30_pp'),delta,g,par$v,100,n=nrow(d))
}
stopifnot(abs(sum(results[[length(results)-2]]$estimate,results[[length(results)-1]]$estimate)-results[[length(results)]]$estimate)<1e-10)
share<-function(v)list(p=v$p[3]/v$p[4],g=v$g[3,]/v$p[4]-v$p[3]*v$g[4,]/v$p[4]^2)
s0<-share(vals[['30']]);s1<-share(vals[['40']])
for(bmi in c(30,40)) {
  r<-vals[[as.character(bmi)]];s<-share(r);add(id,paste0('acidemia_share_at_',bmi),s$p,s$g,par$v,100,TRUE,nrow(d))
  cv<-a$same_day_probability_covariance;cv<-cv[cv$model_id==id&cv$bmi==bmi,]
  C2<-matrix(NA_real_,2,2);lev<-c('with_acidemia','any_hypercapnia')
  for(j in 1:2)for(k in 1:2)C2[j,k]<-cv$covariance[cv$outcome1==lev[j]&cv$outcome2==lev[k]]
  sg<-c(1/r$p[4],-r$p[3]/r$p[4]^2)
  stopifnot(abs(bmi_delta_variance(s$g,par$v)-drop(t(sg)%*%C2%*%sg))<1e-12)
}
add(id,'acidemia_share_change_40_minus_30_pp',s1$p-s0$p,s1$g-s0$g,par$v,100,n=nrow(d))
DA<-vals[['40']]$p[3]-vals[['30']]$p[3];DT<-vals[['40']]$p[4]-vals[['30']]$p[4]
gA<-vals[['40']]$g[3,]-vals[['30']]$g[3,];gT<-vals[['40']]$g[4,]-vals[['30']]$g[4,]
if(abs(DT)<1e-8)stop('Total change too small for contribution ratio')
add(id,'acidemia_fraction_of_total_probability_increase',DA/DT,gA/DT-DA*gT/DT^2,par$v,100,n=nrow(d))
add(id,'with_minus_without_probability_increase_pp',2*DA-DT,2*gA-gT,par$v,100,n=nrow(d))
for(j in 2:4) {
 old<-a$same_day_contrasts[a$same_day_contrasts$model_id==id&a$same_day_contrasts$bmi_low==40&a$same_day_contrasts$bmi_high==45&a$same_day_contrasts$outcome_id==c(bmi_same_day_classes,'any_hypercapnia')[j],]
 delta<-vals[['45']]$p[j]-vals[['40']]$p[j];se<-sqrt(bmi_delta_variance(vals[['45']]$g[j,]-vals[['40']]$g[j,],par$v))
 stopifnot(nrow(old)==1L,max(abs(c(delta,delta-z*se,delta+z*se)-c(old$difference_per1000,old$conf_low_per1000,old$conf_high_per1000)/1000))<1e-10)
}
fun_share<-function(beta){mm<-m;mm$beta<-beta;share(bmi_multinomial_mean(mm,40,config))$p-share(bmi_multinomial_mean(mm,30,config))$p}
gradchecks[[id]]<-verify_gradient(par$beta,fun_share,s1$g-s0$g,'joint acidemia-share change')
utils::write.csv(bmi_bind(results),file.path(out,'landmark-estimands.csv'),row.names=FALSE)
utils::write.csv(bmi_bind(reproduction),file.path(out,'prediction-reproduction.csv'),row.names=FALSE)
utils::write.csv(bmi_bind(gradchecks),file.path(out,'finite-difference-checks.csv'),row.names=FALSE)
if(!identical(before,bmi_hash_files(bmi_estimation_files()))||bundle_sha!=tri_sha256(file.path(args[1],'bundle_manifest.json')))stop('Scientific source or saved bundle changed')
if(args[2]!='fixture'&&(receipt$input_sha256!=tri_sha256(args[2])||receipt$input_manifest_sha256!=tri_sha256(args[3])))stop('Input changed')
receipt$status<-'numerically_verified';receipt$predictor_source_sha256<-tri_sha256(script);receipt$clinical_input_read<-args[2]!='fixture';receipt$primary_n<-nrow(q);receipt$reference_n<-c(abg=nrow(ctxp$members$C_abg_encounter),any_gas=nrow(ctxp$members$C_any_gas_encounter),same_day=nrow(d));receipt$maximum_saved_prediction_error<-max(bmi_bind(reproduction)$maximum_probability_or_interval_error);receipt$basis_id<-basis$basis_id;receipt$definition<-'acidemia share = standardized p(with acidemia) / standardized p(total hypercapnia); pointwise model-based uncertainty, empirical reference fixed';receipt$scientific_review<-'pending investigator';receipt$release_actions<-FALSE
jsonlite::write_json(receipt,file.path(out,'postestimation-receipt.json'),auto_unbox=TRUE,pretty=TRUE)
cat('Prediction-only extraction passed; aggregate output:',out,'\n')
