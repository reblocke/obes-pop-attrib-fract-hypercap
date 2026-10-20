#!/usr/bin/env Rscript
args<-commandArgs(TRUE)
if(length(args)!=4||!args[1]%in%c("export","enrich"))stop("Use export/enrich INPUT MANIFEST OUTPUT")
source("R/analysis.R");input<-args[2];manifest<-args[3];out<-args[4]
loaded<-bmi_load_input(input,manifest,audit_only=TRUE);raw<-loaded$data
if(any(bmi_same_day_fields %in% names(raw)))stop("Input is already enriched; supply the immutable original input")
if(anyDuplicated(tri_encounter_key(raw)))stop("Co-occurrence enrichment requires unique original study keys")
if(args[1]=="export") {
  utils::write.csv(raw[c("patient_id","encounter_id")],file.path(out,"keys.csv"),row.names=FALSE)
} else {
  evidence<-jsonlite::read_json(file.path(out,"cooccurrence-evidence.json"),simplifyVector=FALSE)
  if(!identical(evidence$cooccurrence_summary_sha256,tri_sha256(file.path(out,"cooccurrence.csv"))))stop("Co-occurrence summary hash mismatch")
  p<-utils::read.csv(file.path(out,"cooccurrence.csv"),colClasses=c("character","character","character",rep("numeric",length(bmi_same_day_fields)-1)),na.strings="")
  key<-tri_encounter_key(p);pos<-match(tri_encounter_key(raw),key)
  if(anyDuplicated(key)||anyNA(pos)||length(key)!=nrow(raw))stop("Co-occurrence join changed original keys")
  for(v in bmi_same_day_fields)raw[[v]]<-p[[v]][pos]
  bmi_validate_cooccurrence(raw)
  unchanged<-vapply(names(loaded$data),function(v)identical(raw[[v]],loaded$data[[v]]),logical(1))
  before_attributes<-attributes(loaded$data);after_attributes<-attributes(raw)
  before_attributes$names<-after_attributes$names<-NULL
  if(!all(unchanged)||!setequal(names(before_attributes),names(after_attributes))||
      !all(vapply(names(before_attributes),function(v)identical(before_attributes[[v]],after_attributes[[v]]),logical(1))))stop("Existing study fields or source attributes changed during enrichment")
  before<-construct_cohort_and_memberships(loaded$data)$members$Q
  after<-construct_cohort_and_memberships(raw)$members$Q
  if(!identical(tri_encounter_key(before),tri_encounter_key(after)))stop("Co-occurrence metadata changed indexes")
  evidence<-jsonlite::read_json(file.path(out,"cooccurrence-evidence.json"),simplifyVector=FALSE)
  if(!identical(evidence$base_input_sha256,tri_sha256(input))||!identical(evidence$base_manifest_sha256,tri_sha256(manifest)))stop("Co-occurrence evidence belongs to another input")
  saveRDS(raw,file.path(out,"study-input.rds"))
  m<-jsonlite::read_json(manifest,simplifyVector=FALSE)
  for(name in names(m$source_evidence_files)) {
    path<-m$source_evidence_files[[name]]$path
    if(!grepl("^(/|[A-Za-z]:)",path))m$source_evidence_files[[name]]$path<-normalizePath(file.path(dirname(manifest),path))
  }
  m$input_sha256<-tri_sha256(file.path(out,"study-input.rds"))
  m$same_day_abg_extension<-list(schema_version=1L,policy_id=evidence$policy_id,
    base_input_sha256=evidence$base_input_sha256,base_manifest_sha256=evidence$base_manifest_sha256)
  for(v in bmi_same_day_fields)m$metadata_columns[[v]]<-v
  m$source_evidence_files$same_day_abg<-list(path=normalizePath(file.path(out,"cooccurrence-evidence.json")),sha256=tri_sha256(file.path(out,"cooccurrence-evidence.json")))
  jsonlite::write_json(m,file.path(out,"triangulation_input.same-day.json"),auto_unbox=TRUE,pretty=TRUE,digits=NA)
  jsonlite::write_json(list(original_fields_identical=TRUE,indexes_identical=TRUE,rows=nrow(raw),base_input_sha256=tri_sha256(input),enriched_input_sha256=m$input_sha256),file.path(out,"enrichment-invariance.json"),auto_unbox=TRUE,pretty=TRUE)
}
Sys.chmod(list.files(out,full.names=TRUE),"0600")
