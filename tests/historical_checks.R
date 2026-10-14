# Pure artificial checks against the actual archived report helper chunks.
historical_report_functions <- function(path) {
  lines <- readLines(path, warn = FALSE)
  env <- new.env(parent = globalenv())
  for (name in c("mutate", "case_when", "if_else", "pick", "across", "all_of", "first")) env[[name]] <- getExportedValue("dplyr", name)
  env$tibble <- tibble::tibble
  env$CO2_ABG_CUTOFF <- 45
  env$CO2_VBG_CUTOFF <- 50
  env$PH_CUTOFF <- 7.35
  env$OBESITY_CUTOFF <- 30
  env$ICD_HRF_VARS <- c("has_j9612", "has_j9622", "has_j9692", "has_j9602")
  env$BMI_CATEGORY_LEVELS <- c("Underweight", "Normal weight", "Overweight", "Obesity I", "Obesity II", "Obesity III")
  for (label in c("helpers-validation", "helpers-derivation", "helpers-tables-models")) {
    start <- match(paste0("```{r ", label, "}"), lines)
    if (is.na(start)) stop("Missing historical helper chunk: ", label)
    end <- start + which(lines[(start + 1L):length(lines)] == "```")[1]
    eval(parse(text = lines[(start + 1L):(end - 1L)]), envir = env)
  }
  env
}

historical_artificial_rows <- function() {
  x <- data.frame(curr_bmi_num = rep(42, 4), niv_proc = c(NA, 0, 0, 1), imv_proc = c(0, 0, NA, 0),
    highest_paco2 = c(55, 44, NA, 55), abg_ph = c(7.2, 7.4, NA, 7.2), vbg_co2 = NA_real_, vbg_ph = NA_real_)
  for (name in c("has_j9602", "has_j9612", "has_j9622", "has_j9692")) x[[name]] <- factor(c("0", "0", NA, "0"), levels = c("0", "1"))
  x$has_j9602[4] <- "1"
  x
}

run_historical_checks <- function(root) {
  source(file.path(root, "R", "historical_hrf_helpers.R"), local = FALSE)
  old <- historical_report_functions(file.path(root, "archive", "2026-10-13-bmi-to-40", "reports", "obesity_hrf_paf_analysis.qmd"))
  repaired <- historical_report_functions(file.path(root, "archive", "r", "obesity_hrf_paf_analysis.qmd"))
  before <- old$derive_analysis_variables(historical_artificial_rows())
  after <- repaired$derive_analysis_variables(historical_artificial_rows())
  stopifnot(before$hrf_v1_numeric[1] == 0L, is.na(after$hrf_v1_numeric[1]), after$hrf_v1_numeric[2] == 0L,
    is.na(after$hrf_v1_numeric[3]), after$hrf_v1_numeric[4] == 1L)
  stopifnot(before$hrf_icd_v2[1] == 1L, before$hrf_icd_v2[3] == 0L,
    identical(after$hrf_icd_v2, c(0L, 0L, NA_integer_, 1L)), is.na(after$hrf_labs_v2[3]), is.na(after$hypercapnia_any[3]))
  stopifnot(identical(decode_historical_icd(factor(c("0", "1", NA), levels = c("1", "0"))), c(0L, 1L, NA_integer_)))
  error <- tryCatch(decode_historical_icd(factor("Unreviewed code")), error = identity)
  stopifnot(inherits(error, "error"))
  partial <- data.frame(a = c(1, 0, 0, NA), b = c(NA, 0, NA, NA))
  stopifnot(identical(historical_icd_union(partial), c(1L, 0L, NA_integer_, NA_integer_)))
  source <- data.frame(has_bmi = c(rep(TRUE, 80), rep(FALSE, 20)), has_any_gas_pair = c(rep(TRUE, 70), rep(FALSE, 30)))
  original_flow <- old$make_attrition_table(source, source[1:40, ], source[1:60, ], source[1:50, ])
  repaired_flow <- repaired$make_attrition_table(source, source[1:40, ], source[1:60, ], source[1:50, ])
  stopifnot(any(original_flow$n_excluded_from_previous_step < 0, na.rm = TRUE),
    all(repaired_flow$n_excluded_from_parent[4:6] == c(30, 10, 20)), !any(repaired_flow$n_excluded_from_parent < 0, na.rm = TRUE))
  provenance <- jsonlite::read_json(file.path(root, "archive", "2026-10-13-bmi-to-40", "provenance.json"), simplifyVector = TRUE)
  for (path in names(provenance$files)) stopifnot(identical(digest::digest(file = file.path(root, "archive", "2026-10-13-bmi-to-40", path), algo = "sha256"), provenance$files[[path]]))
  stopifnot(identical(digest::digest(file = file.path(root, "archive", "r", "reconstructed_obesity_hrf_from_pdf.qmd"), algo = "sha256"), provenance$files[["reports/reconstructed_obesity_hrf_from_pdf.qmd"]]))
  message("Historical defects reproduced; repaired truth tables, branch attrition and original hashes passed.")
  invisible(list(before = before[c("hrf_v1_numeric", "hrf_icd_v2", "hrf_labs_v2")],
    after = after[c("hrf_v1_numeric", "hrf_icd_v2", "hrf_labs_v2")], original_flow = original_flow, repaired_flow = repaired_flow))
}
