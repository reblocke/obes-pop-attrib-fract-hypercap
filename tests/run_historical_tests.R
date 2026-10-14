#!/usr/bin/env Rscript
root <- normalizePath(".", mustWork = TRUE)
source(file.path(root, "tests", "historical_checks.R"))
result <- run_historical_checks(root)
output <- file.path(root, "artifacts", "historical-r", "regression-checks")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
saveRDS(result, file.path(output, "artificial-reproduction.rds"))
jsonlite::write_json(list(status = "passed", data_status = "ARTIFICIAL DATA ONLY",
  clinical_input_opened = FALSE, checks = c("unknown ventilation", "ICD factor decoding", "all-missing ICD", "missing gases", "branch attrition", "original archive hashes")),
  file.path(output, "receipt.json"), auto_unbox = TRUE, pretty = TRUE)
