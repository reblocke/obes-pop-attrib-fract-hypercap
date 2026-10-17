#!/usr/bin/env Rscript
args<-commandArgs(TRUE);if(length(args)!=1L)stop("Use actual REVIEW directory")
source("R/analysis.R");review<-normalizePath(args[1]);receipt<-jsonlite::read_json(file.path(review,"render-receipt.json"),simplifyVector=TRUE)
stopifnot(receipt$status=="completed",receipt$clinical_input_reads==0,receipt$model_refits==0,receipt$bundle_unchanged)
run<-dirname(dirname(review));a<-bmi_read_bundle(run)$analysis
coverage<-utils::read.csv(file.path(review,"audit-table-coverage.csv"),stringsAsFactors=FALSE)
for(format in c("html","pdf")) {
 z<-coverage[coverage$format==format,]
 for(table in c("variable_summary","category_counts","coefficients"))stopifnot(sum(z$rows[z$caption==table])==nrow(a[[table]]))
 stopifnot(sum(z$rows[z$caption=="Complete coefficient covariance"]*(z$columns[z$caption=="Complete coefficient covariance"]-1))==nrow(a$coefficient_covariance))
}
captions<-utils::read.csv(file.path(review,"figures/captions.csv"),stringsAsFactors=FALSE)
for(id in c("RFS-entry","RFS-flow",paste0(rep(c("primary","obesity_only"),each=3),"/",rep(c("F1-A","F1-B","F1-C"),2)))) {
 stopifnot(id %in% captions$figure_id)
 for(ext in c("svg","pdf","png","jpg"))stopifnot(file.exists(file.path(review,"figures",paste0(id,".",ext))))
}
jsonlite::write_json(list(status="passed",render_receipt_sha256=tri_sha256(file.path(review,"render-receipt.json")),scope="Automated integration/table coverage only; visual/scientific review separate"),file.path(review,"integration-review.json"),auto_unbox=TRUE,pretty=TRUE)
message("RFS aggregate-only render/coverage checks passed")
