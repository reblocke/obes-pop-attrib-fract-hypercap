#!/usr/bin/env Rscript
# Aggregate-only numerical release review; never opens clinical input or fits models.
args<-commandArgs(TRUE)
if(length(args)!=1L)stop("Use one saved RUN; prior-run index/field comparisons belong to source qualification, not coefficient equality across RFS populations")
source("R/analysis.R");bundle<-bmi_read_bundle(args[1]);a<-bundle$analysis;checks<-list()
add<-function(id,ok)checks[[length(checks)+1L]]<<-data.frame(check_id=id,passed=isTRUE(ok))
near<-function(x,y)isTRUE(all.equal(x,y,tolerance=1e-9,check.attributes=FALSE))
add("ledger",!any(bmi_validate_ledger(a)$passed %in% FALSE))
add("observed_only",all(a$policy_totals$method=="observed")&&!nrow(a$sensitivity_results)&&!nrow(a$implied_missing_probabilities))
for(id in a$model_registry$model_id){
 r<-a$model_registry[a$model_registry$model_id==id,]
 if(r$status %in% c("successful","fitted_with_concerns"))add(paste("events",id),r$n_events+r$n_nonevents==r$n_model)
 z<-a$probability_curves[a$probability_curves$model_id==id,]
 if(nrow(z)){add(paste("reference",id),all(z$reference_id==r$training_population_id));if(!is.na(r$n_model))add(paste("reference N",id),all(z$n_reference==r$n_model))}
}
for(i in seq_len(nrow(a$policy_totals))){
 t<-a$policy_totals[i,];if(t$status!="estimated")next
 z<-a$policy_contributions[a$policy_contributions$model_id==t$model_id & a$policy_contributions$policy_id==t$policy_id,]
 v<-a$policy_contribution_covariance[a$policy_contribution_covariance$model_id==t$model_id & a$policy_contribution_covariance$policy_id==t$policy_id,]
 add(paste("paired means",t$model_id),near(sum(z$A),t$p_observed)&&near(sum(z$G),t$p_shifted))
 add(paste("difference and PIF",t$model_id),near(sum(z$D),t$absolute_difference)&&near(t$PIF,1-t$p_shifted/t$p_observed))
 add(paste("contribution N/variance",t$model_id),sum(z$n)==t$n_reference&&near(sum(v$covariance),t$variance_difference))
 add(paste("shift support",t$model_id),t$n_shifted<=t$n_reference&&near(100*t$n_shifted/t$n_reference,t$pct_shifted))
}
x<-bmi_bind(checks)
receipt<-list(bundle_manifest_sha256=tri_sha256(file.path(args[1],"bundle_manifest.json")),analysis_id=bundle$manifest$analysis_id,
 reviewer_source_sha256=tri_sha256("scripts/review_bmi_run.R"),
 automated_numerical_review=if(all(x$passed))"passed"else"failed",checks=x,
 clinical_input_reads=0L,model_refits=0L,investigator_scientific_review="not asserted")
path<-file.path(args[1],paste0("numerical-review-",format(Sys.time(),"%Y%m%dT%H%M%S"),".json"))
jsonlite::write_json(receipt,path,auto_unbox=TRUE,pretty=TRUE,digits=NA)
cat(nrow(x),"checks;",sum(!x$passed),"failures. Receipt:",path,"\n")
if(any(!x$passed)){print(x[!x$passed,]);stop("Numerical review failed")}
