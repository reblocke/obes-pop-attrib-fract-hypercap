#!/usr/bin/env Rscript
args<-commandArgs(trailingOnly=TRUE)
if(!length(args)%in%c(1,2)|| (length(args)==2&&!args[2]%in%c("all","html","pdf")))stop("Use explicit saved RUN [all/html/pdf]")
root<-normalizePath(".");Sys.setenv(BMI_REPO_ROOT=root);source("R/analysis.R")
require_tri_packages(c("jsonlite","digest","ggplot2","knitr","rmarkdown"))
run<-normalizePath(args[1],mustWork=TRUE);bundle<-bmi_read_bundle(run)
format<-if(length(args)==2)args[2]else"all"
review<-file.path(run,"reviews",paste0(format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid()))
dir.create(review,recursive=TRUE,mode="0700");review<-normalizePath(review)
# Tripwires remain active in this process and each independent Quarto session.
load_common_input<-load_triangulation_input<-bmi_load_input<-fit_bmi_model<-fit_registered_models<-bmi_run_analysis<-function(...)stop("Rendering may not open clinical inputs or fit models")
receipt<-list(status="started",bundle_manifest_sha256=tri_sha256(file.path(run,"bundle_manifest.json")),clinical_input_reads=0L,model_refits=0L,
  render_sources=bmi_hash_files(c("R/reporting.R","scripts/render_bmi_hypercapnia.R","reports/bmi_hypercapnia.qmd","reports/bmi_hypercapnia_audit.qmd","reports/bmi_report.css")))
jsonlite::write_json(receipt,file.path(review,"render-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
bmi_export_figures(bundle,file.path(review,"figures"))
Sys.setenv(BMI_RUN_DIR=run,BMI_REVIEW_DIR=review)
formats<-if(format=="all")c("html","pdf")else format
failures<-character()
for(report in c("bmi_hypercapnia","bmi_hypercapnia_audit"))for(f in formats) {
  log<-file.path(review,paste0(report,"-",f,".log"))
  status<-system2("quarto",c("render",shQuote(file.path(root,"reports",paste0(report,".qmd"))),"--to",f,"--output-dir",shQuote(review)),stdout=log,stderr=log)
  if(status!=0||!file.exists(file.path(review,paste0(report,".",f))))failures<-c(failures,paste(report,f))
}
receipt$status<-if(length(failures))"failed"else"completed";receipt$failed_outputs<-failures
receipt$outputs<-list.files(review,pattern="\\.(html|pdf)$")
receipt$bundle_unchanged<-identical(receipt$bundle_manifest_sha256,tri_sha256(file.path(run,"bundle_manifest.json")))
receipt$sources_unchanged<-identical(receipt$render_sources,bmi_hash_files(names(receipt$render_sources)))
jsonlite::write_json(receipt,file.path(review,"render-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Review:",review,"\nStatus:",receipt$status,"\n")
if(length(failures)||!receipt$bundle_unchanged||!receipt$sources_unchanged)stop("Rendering incomplete; saved analysis preserved")
