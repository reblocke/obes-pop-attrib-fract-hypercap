#!/usr/bin/env Rscript
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=4L)stop("Use prior INPUT MANIFEST fresh preparation OUTPUT prior aggregate RUN")
Sys.setenv(BMI_REPO_ROOT=normalizePath("."));source("R/analysis.R")
input<-args[1];manifest<-args[2];out<-args[3]
prior<-load_common_input(input,manifest)
raw<-prior$data
oldrun<-args[4];oldmanifest<-jsonlite::read_json(file.path(oldrun,"bundle_manifest.json"),simplifyVector=FALSE)
for(name in names(oldmanifest$files))if(!identical(tri_sha256(file.path(oldrun,name)),oldmanifest$files[[name]]))stop("Historical bundle hash mismatch")
oldreceipt<-jsonlite::read_json(file.path(oldrun,"input_receipt.json"),simplifyVector=FALSE)
if(!identical(oldreceipt$input_sha256,tri_sha256(input))||!identical(oldreceipt$manifest_sha256,tri_sha256(manifest)))stop("Historical run does not authenticate this prior input/manifest")
csv<-file.path(out,"candidate-metadata.csv");header<-names(utils::read.csv(csv,nrows=0,check.names=FALSE))
numeric_fields<-c("bmi","age_at_encounter",bmi_rfs_fields,"reported_bmi","height_inches","weight_pounds")
candidate<-utils::read.csv(csv,colClasses=ifelse(header %in% numeric_fields,"numeric","character"),na.strings="",check.names=FALSE)
for(name in intersect(c("encounter_date","reported_date","height_date","weight_date"),names(candidate)))candidate[[name]]<-as.Date(candidate[[name]])
for(name in setdiff(triangulation_columns,names(candidate)))candidate[[name]]<-NA_real_
key<-tri_encounter_key(candidate);position<-match(tri_encounter_key(raw),key)
if(anyNA(position)||anyDuplicated(key)||anyDuplicated(tri_encounter_key(raw)))stop("Invalid metadata/index keys")
for(name in triangulation_adjustment)if(!isTRUE(all.equal(raw[[name]],candidate[[name]][position],check.attributes=FALSE)))stop("Existing clinical covariate changed: ",name)
for(name in intersect(bmi_metadata_fields,names(candidate)))raw[[name]]<-candidate[[name]][position]
if(!identical(raw[triangulation_columns],prior$data[triangulation_columns]))stop("Clinical fields changed during enrichment")
companion<-bmi_make_companion(candidate)
if(!identical(companion$selection_sha256,bmi_selection_hash(raw)))stop("Metadata enrichment altered index selection")
classified<-bmi_classify_rfs(raw)
if(any(classified$rfs_subgroup=="all_zero_discrepancy"))stop("All-six-zero source-consistency discrepancy requires investigation")
saveRDS(raw,file.path(out,"study-input.rds"));saveRDS(companion,file.path(out,"cohort-audit-companion.rds"))
checks<-data.frame(requirement=c("keys","indexes","BMI","adjustment","outcomes","source_partition"),status="passed",note=paste0("Exact original-key/input field comparison; prior bundle ",tri_sha256(file.path(oldrun,"bundle_manifest.json")),"; metadata additions only"))
# Supporting count only: removing obesity-only candidate entries may select a later visit.
candidate_class<-bmi_classify_rfs(candidate)
uncertain_patients<-unique(candidate_class$patient_id[candidate_class$rfs_group=="unresolved"])
alt<-construct_cohort_and_memberships(candidate[candidate_class$rfs_group=="primary",,drop=FALSE])$members$Q
known<-!raw$patient_id %in% uncertain_patients
position_alt<-match(raw$patient_id,alt$patient_id)
oldkey<-tri_encounter_key(raw);newkey<-tri_encounter_key(alt)[position_alt]
checks<-bmi_bind(list(checks,data.frame(requirement=c("alternative_index_same","alternative_index_changed","alternative_index_unavailable","alternative_index_membership_unresolved"),
 status="assessed; count only, no alternative model",n=c(sum(known&!is.na(newkey)&oldkey==newkey),sum(known&!is.na(newkey)&oldkey!=newkey),sum(known&is.na(newkey)),sum(!known)),note="Original indexed patients; alternate first eligible non-OBESITY-supported candidate. Earlier RFS uncertainty not converted to absence.")))
utils::write.csv(checks,file.path(out,"prior-input-reconciliation.csv"),row.names=FALSE)
m<-jsonlite::read_json(manifest,simplifyVector=FALSE)
# Resolve inherited evidence paths before moving the fresh manifest to another directory.
for(name in names(m$source_evidence_files)) {
 p<-m$source_evidence_files[[name]]$path
 if(!grepl("^(/|[A-Za-z]:)",p))m$source_evidence_files[[name]]$path<-normalizePath(file.path(dirname(manifest),p))
}
m$schema_version<-4L;m$input_sha256<-tri_sha256(file.path(out,"study-input.rds"));m$rfs_policy_id<-"historical_source_membership_v1"
m$metadata_columns<-as.list(setNames(intersect(bmi_metadata_fields,names(raw)),intersect(bmi_metadata_fields,names(raw))))
for(pair in list(c("rfs","rfs-evidence.json"),c("cohort_audit","cohort-audit-companion.rds"),c("prior_comparison","prior-input-reconciliation.csv")))m$source_evidence_files[[pair[1]]]<-list(path=normalizePath(file.path(out,pair[2])),sha256=tri_sha256(file.path(out,pair[2])))
m$metadata_review<-"Automated authenticated-source comparison; no new human approval asserted"
jsonlite::write_json(m,file.path(out,"triangulation_input.rfs.json"),auto_unbox=TRUE,pretty=TRUE,digits=NA)
Sys.chmod(list.files(out,full.names=TRUE),"0600")
