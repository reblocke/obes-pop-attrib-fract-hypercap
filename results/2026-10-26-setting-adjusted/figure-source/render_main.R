#!/usr/bin/env Rscript
# Replay the preferred figure from authenticated aggregate CSVs; no clinical input.
args<-commandArgs(TRUE)
if(length(args)!=3L)stop("Use REPOSITORY SNAPSHOT FRESH_OUTPUT")
root<-normalizePath(args[1],mustWork=TRUE);snapshot<-normalizePath(args[2],mustWork=TRUE)
Sys.setenv(BMI_REPO_ROOT=root);source(file.path(root,"R/analysis.R"))
manifest<-jsonlite::read_json(file.path(snapshot,"manifest.json"),simplifyVector=FALSE)
if(!identical(manifest$analysis_id,"bmi_hypercapnia_rfs_curve_audit_v9") ||
   !identical(manifest$schema_version,14L) || !identical(manifest$mode,"clinical"))stop("Requires setting-adjusted clinical snapshot")
sources<-c(manifest$estimation_sources,manifest$render_sources)
for(name in unique(names(sources)))
  if(!identical(tri_sha256(file.path(root,name)),sources[[name]]))stop("Source/hash mismatch: ",name)
read_table<-function(name) {
 key<-paste0("tables/",name,".csv");path<-file.path(snapshot,key)
 if(!identical(tri_sha256(path),manifest$files[[key]]$sha256))stop("Table hash mismatch: ",name)
 utils::read.csv(path,check.names=FALSE,stringsAsFactors=FALSE)
}
config_path<-file.path(snapshot,"analysis_config.json")
if(!identical(tri_sha256(config_path),manifest$files[["analysis_config.json"]]$sha256))stop("Configuration hash mismatch")
names<-c("probability_curves","observation_curves","distribution_bins","model_registry","cohort_nodes")
bundle<-list(analysis=setNames(lapply(names,read_table),names),
 config=jsonlite::read_json(config_path,simplifyVector=FALSE),manifest=manifest)
if(file.exists(args[3]))stop("Use a fresh output directory")
invisible(bmi_main_relationship_figure(bundle,args[3]))
cat("F1-main recreated from five aggregate tables; clinical input reads 0; model refits 0.\n")
