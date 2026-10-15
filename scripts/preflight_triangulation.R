#!/usr/bin/env Rscript
# Schema/aggregate audit only: no selection, model fitting, or identifier export.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(1L, 2L)) stop("Usage: Rscript scripts/preflight_triangulation.R INPUT [MANIFEST]")
source("R/bmi_hypercapnia_triangulation.R")
source("R/triangulation_reporting.R")
source("R/common_index_hypercapnia.R")
require_tri_packages(c("jsonlite", "digest"))
input <- normalizePath(args[1], mustWork = TRUE)
ext <- tolower(tools::file_ext(input))
if (ext == "dta") require_tri_packages("haven")
data <- switch(ext, rds = readRDS(input), dta = haven::read_dta(input), stop("Only explicit RDS/DTA inputs supported."))
if (!is.data.frame(data)) stop("Source is not a data frame.")
output <- file.path("artifacts", "triangulation", tri_run_id("preflight"))
dir.create(output, recursive = TRUE)
schema <- data.frame(column = names(data), class = vapply(data, function(x) paste(class(x), collapse = ";"), character(1)),
                     n_missing = vapply(data, function(x) sum(is.na(x)), numeric(1)),
                     n_levels = vapply(data, function(x) if (is.factor(x)) nlevels(x) else NA_integer_, integer(1)), row.names = NULL)
utils::write.csv(schema, file.path(output, "schema.csv"), row.names = FALSE, na = "")
# Never write values or levels for identifiers, dates, free text or facility names.
keys <- intersect(c("patient_id", "encounter_id", "original_patient_id", "original_encounter_id"), names(data))
key_audit <- data.frame(column = keys, class = schema$class[match(keys, schema$column)],
                        n_distinct_nonmissing = vapply(data[keys], function(x) length(unique(x[!is.na(x)])), numeric(1)),
                        n_missing = vapply(data[keys], function(x) sum(is.na(x)), numeric(1)))
utils::write.csv(key_audit, file.path(output, "key_aggregate_audit.csv"), row.names = FALSE)
selected <- intersect(c("bmi", "curr_bmi", "age_at_encounter", "has_abg", "has_vbg", "paco2", "highest_paco2", "vbg_co2", "highest_vbg_co2", "hypercap_resp_failure"), names(data))
characteristics <- lapply(selected, function(name) {
  x <- data[[name]]
  numeric_source <- is.numeric(x) && !is.factor(x)
  data.frame(column = name, n_missing = sum(is.na(x)), n_nonmissing = sum(!is.na(x)),
             minimum = if (numeric_source && any(!is.na(x))) min(x, na.rm = TRUE) else NA_real_,
             maximum = if (numeric_source && any(!is.na(x))) max(x, na.rm = TRUE) else NA_real_)
})
if (length(characteristics)) utils::write.csv(do.call(rbind, characteristics), file.path(output, "aggregate_characteristics.csv"), row.names = FALSE, na = "")
# Presence of normal results is a coverage diagnostic, not lineage proof.
gas_names <- intersect(c("paco2", "highest_paco2", "vbg_co2", "highest_vbg_co2", "abg_pco2", "vbg_pco2"), names(data))
gas_counts <- lapply(gas_names, function(name) {
  x <- data[[name]]
  if (!is.numeric(x) || is.factor(x)) return(NULL)
  cutoff <- if (grepl("vbg", name)) 50 else 45
  data.frame(column = name, cutoff = cutoff, n_below = sum(x < cutoff, na.rm = TRUE),
    n_at = sum(x == cutoff, na.rm = TRUE), n_above = sum(x > cutoff, na.rm = TRUE), n_unavailable = sum(is.na(x)))
})
gas_counts <- gas_counts[!vapply(gas_counts, is.null, logical(1))]
if (length(gas_counts)) utils::write.csv(do.call(rbind, gas_counts), file.path(output, "gas_threshold_coverage.csv"), row.names = FALSE)
# Small, explicitly selected categorical code dictionaries only.
category_names <- intersect(c("sex", "race_ethnicity", "ethnicity", "location", "encounter_type", "has_abg", "has_vbg", "hypercap_resp_failure"), names(data))
categories <- lapply(category_names, function(name) {
  x <- data[[name]]
  values <- if (inherits(x, "haven_labelled")) as.character(haven::zap_labels(x)) else as.character(x)
  values <- values[!is.na(values)]
  if (!length(values)) return(data.frame(column = name, code = "[ALL VALUES MISSING]", n = length(x)))
  if (length(unique(values)) > 30L) return(data.frame(column = name, code = "[NOT EXPORTED: >30 distinct values]", n = length(values)))
  t <- table(values)
  data.frame(column = name, code = names(t), n = as.numeric(t))
})
if (length(categories)) utils::write.csv(do.call(rbind, categories), file.path(output, "category_codes.csv"), row.names = FALSE)
receipt <- list(status = "schema_audited_not_authenticated", input_sha256 = tri_sha256(input),
                input_bytes = unname(file.info(input)$size), input_rows = nrow(data), input_columns = ncol(data),
                required_names_absent = setdiff(triangulation_columns, names(data)),
                identifier_values_exported = FALSE, models_fitted = 0L,
                provenance_authenticated = FALSE, clinical_results_qualified = FALSE,
                schema_sha256 = tri_sha256(file.path(output, "schema.csv")),
                audit_source_sha256 = tri_sha256("scripts/preflight_triangulation.R"))
qualification_error <- NULL
if (length(args) == 2L) {
  loaded <- tryCatch(load_common_input(input, args[2]), error = function(e) e)
  if (inherits(loaded, "error")) {
    qualification_error <- conditionMessage(loaded)
    receipt$status <- "source_qualification_failed"
    receipt$qualification_error <- qualification_error
  } else {
    receipt$status <- "reviewed_primary_input_identity_and_mapping_passed"
    receipt$provenance_authenticated <- TRUE
    receipt$manifest_sha256 <- tri_sha256(args[2])
    receipt$index_day_source_status <- loaded$manifest$index_day$status
    receipt$qualification_scope <- "Identity-bound reviewed declarations; no independent raw-source comparison performed by this CLI"
  }
}
jsonlite::write_json(receipt, file.path(output, "preflight_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
writeLines(c("# Input preflight", "", paste("Status:", receipt$status), "", "Schema and aggregates do not establish producer lineage or population completeness. With a manifest, this CLI additionally verifies reviewed mappings and referenced evidence-file hashes; it does not perform an independent raw-source comparison.", "", "No clinical models were fitted. Normal gas records do not alone prove complete common-target coverage.", "", paste("Rows:", nrow(data), "; columns:", ncol(data)), paste("Required names absent:", paste(receipt$required_names_absent, collapse = ", ")), "", "See docs/TRIANGULATION_SOURCE_ASSESSMENT.md and docs/TRIANGULATION_INPUT_HANDOFF.md for the bounded source assessment."), file.path(output, "preflight_review.md"))
cat("Preflight saved:", output, "\nStatus:", receipt$status, "\nModels fitted: 0\n")
if (!is.null(qualification_error)) stop("Qualification failed; receipt retained: ", qualification_error)
