#!/usr/bin/env Rscript
# Bounded index selection before gas extraction. No outcome models are fitted.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L || file.exists(args[2]) || file.exists(args[3])) stop("Use partition directory and fresh selected CSV/audit paths.")
source("R/analysis.R")
require_tri_packages("jsonlite")
parts <- sort(list.files(args[1], pattern = "\\.csv$", full.names = TRUE))
if (!length(parts)) stop("No source mapping partitions.")
counts <- scope <- NULL
candidate_covariates <- list()
seen <- character()
fields <- c("patient_id", "encounter_id", "encounter_date", "age_at_encounter", "encounter_type",
  "bmi", "sex", "race_ethnicity", "location", "bmi_evidence_state",
  setdiff(bmi_metadata_fields,c(bmi_same_day_fields,bmi_icd_fields)))
for (i in seq_along(parts)) {
  header <- names(utils::read.csv(parts[i], nrows = 0, check.names = FALSE))
  if (!setequal(header, fields)) stop("Unexpected mapping partition columns.")
  classes <- ifelse(header %in% c("bmi", "age_at_encounter",bmi_rfs_fields,"reported_bmi","height_inches","weight_pounds"), "numeric", "character")
  raw <- utils::read.csv(parts[i], colClasses = classes, na.strings = "", check.names = FALSE)
  patients <- unique(raw$patient_id)
  if (any(patients %in% seen)) stop("Patient split across source partitions.")
  seen <- c(seen, patients)
  for(name in c("encounter_date","reported_date","height_date","weight_date"))raw[[name]]<-as.Date(raw[[name]],format="%Y-%m-%d")
  for (name in setdiff(triangulation_columns, names(raw))) raw[[name]] <- NA_real_
  candidate_covariates[[i]] <- raw
  data <- derive_triangulation_variables(validate_triangulation_input(raw))
  data$common_valid_bmi <- ifelse(is.na(data$bmi), NA, is.finite(data$bmi))
  data$common_valid_bmi[data$bmi_evidence_state == "missing"] <- FALSE
  selected <- select_frame_indexes(data, "common_valid_bmi")
  current <- data.frame(input_encounters = nrow(raw), exact_duplicates_removed = attr(data, "exact_duplicates_removed"),
    distinct_encounter_versions = nrow(data), n_conflicting_keys = attr(data, "n_conflicting_keys"),
    in_scope = sum(data$in_scope %in% TRUE), out_of_scope = sum(data$in_scope %in% FALSE), uncertain_scope = sum(is.na(data$in_scope)))
  if (is.null(counts)) { counts <- selected$counts; scope <- current } else {
    for (name in setdiff(names(counts), "frame")) counts[[name]] <- counts[[name]] + selected$counts[[name]]
    scope <- scope + current
  }
  utils::write.table(selected$indexes[fields], args[2], sep = ",", row.names = FALSE,
    col.names = i == 1L, append = i != 1L, na = "", qmethod = "double")
  message("Completed bounded index partition ", i, "/", length(parts))
  rm(raw, data, selected); invisible(gc(FALSE))
}
jsonlite::write_json(list(bmi_policy_id = "available_encounter_or_prior_bmi_v1",
  selection = "same R select_frame_indexes; whole-patient partitions; before gas extraction",
  counts = as.list(counts[1, ]), scope = as.list(scope[1, ]),
  partitions = length(parts), clinical_models_fitted = 0L), args[3], auto_unbox = TRUE, pretty = TRUE)
Sys.chmod(c(args[2], args[3]), mode = "0600")

# Existing mapped covariates only. No pre-index gas pull or clinical models.
# Exact profiles require the bounded candidate columns, not averages of partition quantiles.
companion_path <- file.path(dirname(args[3]), "cohort-audit-companion.rds")
if (file.exists(companion_path)) stop("Cohort companion output must be fresh")
companion <- bmi_make_companion(do.call(rbind, candidate_covariates))
saveRDS(companion, companion_path)
Sys.chmod(companion_path, "0600")
