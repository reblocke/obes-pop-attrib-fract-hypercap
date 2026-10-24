#!/usr/bin/env Rscript
# Private typed input only. No selection, fitting, or source acceptance.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || file.exists(args[2])) stop("Use private CSV and fresh RDS output paths.")
source("R/analysis.R")
header <- names(utils::read.csv(args[1], nrows = 0, check.names = FALSE))
required <- triangulation_columns
allowed <- c(required, "bmi_evidence_state", triangulation_index_day_columns, bmi_metadata_fields)
if (!all(required %in% header) || any(!header %in% allowed)) stop("Unexpected prepared fields.")
character_fields <- c("patient_id","encounter_id","encounter_type","sex","race_ethnicity","location",
  "bmi_evidence_state","bmi_method","bmi_reason","raw_race","raw_ethnicity","obesity_trigger",
  "same_day_abg_state","icd_capture_state")
date_fields <- c("encounter_date","reported_date","height_date","weight_date")
classes <- ifelse(header %in% c(character_fields,date_fields), "character", "numeric")
data <- utils::read.csv(args[1], colClasses=classes, na.strings="", check.names=FALSE)
for (name in intersect(date_fields,header)) {
  raw <- data[[name]]; data[[name]] <- as.Date(raw,format="%Y-%m-%d")
  if(any(!is.na(raw) & (is.na(data[[name]]) | format(data[[name]],"%Y-%m-%d")!=raw)))stop("Invalid prepared date")
}
bmi_validate_metadata(data)
invisible(validate_triangulation_input(data))
saveRDS(data, args[2])
Sys.chmod(args[2], mode = "0600")
cat("Typed private input written; no clinical models fitted.\n")
