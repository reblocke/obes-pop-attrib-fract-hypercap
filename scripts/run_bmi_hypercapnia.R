#!/usr/bin/env Rscript
args<-commandArgs(trailingOnly=TRUE)
if(!length(args)||!args[1] %in% c("fixture","preflight","cohort-audit","analyze"))stop("Use fixture [CONFIG] | preflight/cohort-audit/analyze INPUT MANIFEST [CONFIG]")
mode<-args[1];if(mode!="fixture"&&!length(args)%in%c(3,4))stop("Explicit INPUT MANIFEST required")
Sys.setenv(BMI_REPO_ROOT=normalizePath("."));source("R/analysis.R")
require_tri_packages(c("jsonlite","digest","ggplot2","knitr","rmarkdown","lpSolve","nnet"))
config_path<-if(mode=="fixture"){if(length(args)>1)args[2]else"config/bmi_hypercapnia_analysis.json"}else if(length(args)>3)args[4]else"config/bmi_hypercapnia_analysis.json"
config<-bmi_config(config_path)
git<-function(...) {x<-system2("git",c(...),stdout=TRUE,stderr=FALSE);if(!is.null(attr(x,"status")))stop("Git identity unavailable");x}
identity<-tryCatch(list(commit=git("rev-parse","HEAD"),tree=git("rev-parse","HEAD^{tree}"),working_tree_clean=!length(git("status","--porcelain","--untracked-files=all"))),error=function(e)list(commit=NA_character_,tree=NA_character_,working_tree_clean=FALSE,note="Git identity unavailable; nonclinical audit uses per-file hashes"))
if(mode=="analyze") {
  if(!isTRUE(identity$working_tree_clean)||!grepl("mini",Sys.info()[["nodename"]],ignore.case=TRUE)||!identical(identity$commit,git("rev-parse","origin/main")))stop("Clinical estimation requires a clean merged Mini checkout matching origin/main")
}
receipt<-list(launcher_sha256=tri_sha256("scripts/run_bmi_hypercapnia.R"),mode=mode,source_status="artificial_only",code_identity=identity,clinical_data_opened=FALSE,clinical_models_fitted=0L,human_review="not asserted",scientific_review="pending")
companion<-NULL
if(mode=="fixture") {
  source("tests/fixtures/bmi_curve_fixture.R");raw<-make_bmi_curve_fixture()
  receipt$source_identity<-"ARTIFICIAL fixture; seed 20261016"
}else{
  receipt$clinical_input_access_attempted<-TRUE
  attempt<-tryCatch(bmi_load_input(normalizePath(args[2],mustWork=TRUE),normalizePath(args[3],mustWork=TRUE),audit_only=mode!="analyze"),error=function(e)e)
  if(inherits(attempt,"error")) {
    reason<-conditionMessage(attempt)
    out<-file.path("artifacts","triangulation",paste0("source-audit-blocked-",format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid()))
    receipt$clinical_data_opened<-NA
    receipt$source_status<-"qualification_failed";receipt$failure_reason<-reason
    a<-bmi_partial_audit(reason,config);bmi_write_bundle(a,out,config,receipt,"source_audit")
    cat("Partial source audit saved:",out,"\nNo clinical models fitted.\n")
    stop(reason)
  }
  raw<-attempt$data;companion<-attempt$companion
  receipt$clinical_data_opened<-TRUE;receipt$source_status<-"identity_bound_source_declarations_passed"
  receipt$input_sha256<-attempt$input_sha256;receipt$manifest_sha256<-attempt$manifest_sha256;receipt$source_identity<-attempt$manifest$source_identity
  receipt$source_policy_id<-attempt$manifest$source_policy_id;receipt$existing_source_audit<-attempt$source_audit
  receipt$source_evidence_files<-attempt$manifest$source_evidence_files
  receipt$source_policy_definition<-common_source_policy()
  receipt$population_scope_id<-attempt$manifest$population_scope_id;receipt$bmi_policy_id<-attempt$manifest$bmi_policy_id
  fields_entry<-attempt$manifest$source_evidence_files$fields;fields_path<-fields_entry$path
  if(!grepl("^(/|[A-Za-z]:)",fields_path))fields_path<-file.path(dirname(normalizePath(args[3])),fields_path)
  fields<-jsonlite::read_json(fields_path,simplifyVector=FALSE)
  if(!identical(tri_sha256(fields_path),fields_entry$sha256))stop("Field evidence changed while binding audit metadata")
  receipt$source_method_counts<-fields$bmi_methods;receipt$base_missingness<-fields$base_missingness
  if(!is.null(companion))receipt$cohort_companion_sha256<-attempt$manifest$source_evidence_files$cohort_audit$sha256
}
started<-proc.time()[3]
before<-bmi_hash_files(bmi_estimation_files());before_config<-tri_sha256(config_path)
if(mode=="preflight") {
  # Validate the companion and ledger, without fitting outcome or observation models.
  analysis<-bmi_run_analysis(raw,config,receipt$source_status,audit_only=TRUE,companion=companion)
}else analysis<-bmi_run_analysis(raw,config,receipt$source_status,audit_only=mode=="cohort-audit",companion=companion)
if(mode!="fixture") {
  e<-attempt$rfs_evidence
  analysis$rfs_semantics<-bmi_bind(lapply(names(e$families),function(name) {
    x<-e$families[[name]]
    data.frame(requirement=name,status="authenticated historical source membership",note=paste(unlist(x),collapse="; "))
  }))
  comparison<-attempt$manifest$source_evidence_files$prior_comparison
  if(!is.null(comparison))analysis$prior_run_reconciliation<-bmi_bind(list(utils::read.csv(comparison$path,stringsAsFactors=FALSE),analysis$prior_run_reconciliation[analysis$prior_run_reconciliation$requirement!="prior_run_keys_and_fields",]))
  counters<-attempt$source_audit
  counters$bmi_methods<-receipt$source_method_counts;counters$base_missingness<-receipt$base_missingness
  for(domain in names(counters))for(counter in names(counters[[domain]])) {
    value<-counters[[domain]][[counter]]
    if(length(value)!=1||!is.numeric(value)||!is.finite(value)||value<0||value!=round(value))stop("Invalid aggregate source counter")
    grain<-if(domain %in% c("bmi_audit","bmi_methods"))"mapped_encounter"else if(domain=="base_missingness")"selected_index"else if(counter %in% c("unavailable_domain","unavailable_field"))"transport_item"else if(grepl("^encounters_",counter))"encounter"else"source_record"
    scope<-if(domain %in% c("bmi_audit","bmi_methods"))"original candidate mapping"else"selected-index source transport"
    analysis$source_audit<-bmi_bind(list(analysis$source_audit,data.frame(requirement=paste(domain,counter,sep="/"),status="identity-bound producer counter",note="Overlapping source diagnostics; do not add as a population partition",n=value,grain=grain,scope=scope)))
  }
}
if(!identical(before,bmi_hash_files(bmi_estimation_files()))||!identical(before_config,tri_sha256(config_path)))stop("Analysis/configuration changed during execution")
if(mode!="fixture"&&(!identical(receipt$input_sha256,tri_sha256(args[2]))||!identical(receipt$manifest_sha256,tri_sha256(args[3]))))stop("Input/manifest changed during execution")
receipt$analysis_elapsed_seconds<-unname(proc.time()[3]-started)
receipt$peak_memory<-"not measured"
receipt$clinical_models_fitted<-if(mode=="analyze")sum(analysis$model_registry$status %in% c("successful","fitted_with_concerns"))else 0L
out<-file.path("artifacts","triangulation",paste0("curve-",mode,"-",format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid()))
bmi_write_bundle(analysis,out,config,receipt,if(mode=="fixture")"fixture"else if(mode=="analyze")"clinical"else"source_audit")
cat("Saved run:",out,"\n")
if(mode=="fixture") {
  status<-system2(file.path(R.home("bin"),"Rscript"),c("--vanilla","scripts/render_bmi_hypercapnia.R",shQuote(out),"all"))
  if(status!=0)stop("Fixture estimation saved; render failed. Rerender this exact saved run.")
}
