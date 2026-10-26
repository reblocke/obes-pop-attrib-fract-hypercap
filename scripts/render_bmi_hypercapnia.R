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
load_common_input<-load_triangulation_input<-bmi_load_input<-fit_bmi_model<-fit_registered_models<-bmi_multinomial_fit<-bmi_run_analysis<-function(...)stop("Rendering may not open clinical inputs or fit models")
receipt<-list(status="started",bundle_manifest_sha256=tri_sha256(file.path(run,"bundle_manifest.json")),clinical_input_reads=0L,model_refits=0L,
  render_sources=bmi_hash_files(c("R/reporting.R","R/report_views.R","R/rfs_reporting.R","scripts/render_bmi_hypercapnia.R","reports/bmi_hypercapnia.qmd","reports/bmi_hypercapnia_audit.qmd","reports/bmi_report.css","reports/table_passthrough.R")))
jsonlite::write_json(receipt,file.path(review,"render-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
reuse<-Sys.getenv("BMI_FIGURES_FROM")
if(nzchar(reuse)) {
  reuse<-normalizePath(reuse,mustWork=TRUE)
  previous<-jsonlite::read_json(file.path(reuse,"render-receipt.json"),simplifyVector=FALSE)
  if(!previous$status %in% c("completed","failed"))stop("Prior report job is still open; wait for its final receipt")
  figure_sources<-c("R/reporting.R","R/report_views.R","R/rfs_reporting.R")
  if(!identical(previous$bundle_manifest_sha256,receipt$bundle_manifest_sha256))stop("Reused figures belong to a different aggregate bundle")
  if(!identical(previous$render_sources[figure_sources],bmi_hash_files(figure_sources)))stop("Figure-source hash mismatch; regenerate figures from the saved run")
  marker<-file.path(reuse,"figures","figure-data-receipt.json")
  if(!file.exists(marker))stop("Prior figure export is incomplete")
  captions<-utils::read.csv(file.path(reuse,"figures","captions.csv"),stringsAsFactors=FALSE)
  for(id in captions$figure_id)for(ext in c("pdf","svg","png")) {
    path<-file.path(reuse,"figures",paste0(id,".",ext))
    if(!file.exists(path)||file.info(path)$size==0)stop("Incomplete reused figure: ",id)
  }
  if(!file.copy(file.path(reuse,"figures"),review,recursive=TRUE))stop("Figure copy failed")
  for(path in list.files(file.path(review,"figures"),pattern="figure-qc-manifest[.]csv$",recursive=TRUE,full.names=TRUE)) {
    z<-utils::read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
    for(name in intersect(c("file_path","export_paths"),names(z)))z[[name]]<-gsub(reuse,review,z[[name]],fixed=TRUE)
    utils::write.csv(z,path,row.names=FALSE)
  }
  receipt$figures_reused_from<-reuse
  receipt$previous_render_receipt_sha256<-tri_sha256(file.path(reuse,"render-receipt.json"))
  receipt$figure_data_receipt_sha256<-tri_sha256(marker)
} else bmi_export_figures(bundle,file.path(review,"figures"))
# Quarto writes intermediate files beside its input. Give each fresh review its
# own exact source copies so concurrent jobs cannot overwrite/clean each other.
report_inputs<-file.path(review,"report-inputs");dir.create(report_inputs)
for(name in c("bmi_hypercapnia.qmd","bmi_hypercapnia_audit.qmd","bmi_report.css")) {
  original<-file.path(root,"reports",name);staged<-file.path(report_inputs,name)
  if(!file.copy(original,staged)||!identical(tri_sha256(original),tri_sha256(staged)))stop("Report input staging failed: ",name)
}
receipt$report_input_directory<-report_inputs
jsonlite::write_json(receipt,file.path(review,"render-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
Sys.setenv(BMI_RUN_DIR=run,BMI_REVIEW_DIR=review)
formats<-if(format=="all")c("html","pdf")else format
failures<-character()
for(report in c("bmi_hypercapnia","bmi_hypercapnia_audit"))for(f in formats) {
  log<-file.path(review,paste0(report,"-",f,".log"))
  status<-system2("quarto",c("render",shQuote(file.path(report_inputs,paste0(report,".qmd"))),"--to",f,"--output-dir",shQuote(review)),stdout=log,stderr=log)
  if(status!=0||!file.exists(file.path(review,paste0(report,".",f))))failures<-c(failures,paste(report,f))
}
receipt$status<-if(length(failures))"failed"else"completed";receipt$failed_outputs<-failures
receipt$outputs<-list.files(review,pattern="\\.(html|pdf)$")
receipt$bundle_unchanged<-identical(receipt$bundle_manifest_sha256,tri_sha256(file.path(run,"bundle_manifest.json")))
receipt$sources_unchanged<-identical(receipt$render_sources,bmi_hash_files(names(receipt$render_sources)))
jsonlite::write_json(receipt,file.path(review,"render-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Review:",review,"\nStatus:",receipt$status,"\n")
if(length(failures)||!receipt$bundle_unchanged||!receipt$sources_unchanged)stop("Rendering incomplete; saved analysis preserved")
