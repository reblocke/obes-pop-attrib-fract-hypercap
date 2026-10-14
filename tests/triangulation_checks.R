# The same named checks run under testthat or the dependency-free runner.
# Source the analysis helper and the artificial fixture before this file.
tri_check <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
  invisible(TRUE)
}

tri_equal <- function(actual, expected, message, tolerance = 1e-10) {
  tri_check(isTRUE(all.equal(actual, expected, tolerance = tolerance,
                            check.attributes = FALSE)), message)
}

tri_error <- function(expression, pattern, message) {
  error <- tryCatch({ force(expression); NULL }, error = function(e) e)
  tri_check(inherits(error, "error") && grepl(pattern, conditionMessage(error)), message)
}

tri_rows <- function(n = 1L) {
  data.frame(
    patient_id = sprintf("ARTIFICIAL-P%03d", seq_len(n)),
    encounter_id = sprintf("ARTIFICIAL-E%03d", seq_len(n)),
    encounter_date = rep(as.Date("2022-06-01"), n),
    age_at_encounter = rep(50, n), encounter_type = rep("EMER", n),
    bmi = rep(42, n), sex = rep("Female", n),
    race_ethnicity = rep("Race group A", n), location = rep("ED", n),
    has_abg = rep(1L, n), has_vbg = rep(0L, n),
    abg_pco2 = rep(44, n), vbg_pco2 = rep(NA_real_, n),
    icd_hypercapnia = rep(0L, n), stringsAsFactors = FALSE
  )
}

tri_derive <- function(data) derive_triangulation_variables(validate_triangulation_input(data))

check_inclusive_thresholds_and_combined_outcomes <- function() {
  x <- tri_rows(9)
  x$bmi <- c(39.999, 40, 40.001, rep(42, 6))
  x$abg_pco2 <- c(44.999, 45, NA, NA, NA, 44, 45, 44, NA)
  x$vbg_pco2 <- c(NA, NA, 49.999, 50, NA, NA, 49, 51, NA)
  x$has_abg <- c(1L, 1L, 0L, 0L, 1L, 1L, 1L, 1L, 0L)
  x$has_vbg <- c(0L, 0L, 1L, 1L, 0L, 0L, 1L, 1L, 0L)
  y <- tri_derive(x)
  tri_equal(y$severe_obesity[1:3], c(FALSE, TRUE, TRUE), "BMI 40 must be inclusive")
  tri_equal(y$abg[1:2], c(0L, 1L), "PaCO2 45 must be inclusive")
  tri_equal(y$any_gas, c(0L, 1L, 0L, 1L, NA, 0L, 1L, 1L, NA),
            "Combined gas outcome must retain single-result negatives, either positivity, and missingness")
  tri_check(y$abg_drawn[5] && is.na(y$abg[5]),
            "A draw with no usable result stays in its frame and has unknown outcome")
}

check_adult_setting_and_calendar_scope <- function() {
  x <- tri_rows(9)
  x$age_at_encounter <- c(17.99, 18, 50, 50, 50, 50, NA, 50, 50)
  x$encounter_date <- as.Date(c("2022-06-01", "2022-01-01", "2022-12-31", "2023-01-01",
                                "2021-12-31", "2022-06-01", "2022-06-01", NA, "2022-06-01"))
  x$encounter_type[c(3, 6, 9)] <- c("IMP", "AMB", NA)
  tri_equal(tri_derive(x)$in_scope, c(FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, NA, NA, NA),
            "Scope must include age 18 and both 2022 date boundaries, excluding ambulatory encounters")
}

check_first_indexes_and_no_missingness_advancement <- function() {
  x <- tri_rows(5)
  x$patient_id <- rep("ARTIFICIAL-SAME-PATIENT", 5)
  x$encounter_date <- as.Date("2022-01-01") + 0:4
  x$bmi <- c(35, 41, 42, 43, 44)
  x$has_abg <- c(0L, 0L, 1L, 1L, 1L)
  x$has_vbg <- c(0L, 1L, 0L, 0L, 0L)
  x$abg_pco2 <- c(NA, NA, NA, 60, 60)
  x$vbg_pco2 <- c(NA, 52, NA, NA, NA)
  x$sex[3] <- NA_character_
  y <- tri_derive(x)
  abg <- select_frame_indexes(y, "abg_drawn")$indexes
  gas <- select_frame_indexes(y, "any_gas_drawn")$indexes
  severe <- select_frame_indexes(y, "severe_obesity")$indexes
  tri_equal(abg$encounter_id, x$encounter_id[3], "ABG frame must select its first draw, even with missing result/covariate")
  tri_equal(gas$encounter_id, x$encounter_id[2], "Either-gas frame must select the earlier venous encounter")
  tri_equal(severe$encounter_id, x$encounter_id[2], "BMI frame must select its own first qualifying encounter")
  fit <- fit_triangulation_cell(abg, "abg_drawn", "abg")
  tri_check(fit$n_model == 0L && fit$n_outcome_missing == 1L,
            "Missing index outcome must not be replaced by a later measured encounter")
  fit_icd <- fit_triangulation_cell(abg, "abg_drawn", "icd")
  tri_check(fit_icd$n_missing_adjustment == 1L && fit_icd$n_model == 0L,
            "Missing index covariate must not be replaced by a later complete encounter")
}

check_ambiguous_indexes_and_membership <- function() {
  x <- tri_rows(8)
  x$patient_id <- c("ARTIFICIAL-TIE", "ARTIFICIAL-TIE", "ARTIFICIAL-UNKNOWN", "ARTIFICIAL-UNKNOWN",
                    "ARTIFICIAL-LATER", "ARTIFICIAL-LATER", "ARTIFICIAL-ONLY-UNKNOWN", "ARTIFICIAL-UNDATED")
  x$encounter_date <- as.Date("2022-01-01") + c(0, 0, 0, 1, 0, 1, 0, 0)
  x$bmi[c(3, 6, 7)] <- NA_real_
  dated <- x[8, ]
  dated$encounter_id <- "ARTIFICIAL-DATED-ENCOUNTER"
  dated$encounter_date <- as.Date("2022-03-01")
  x$encounter_date[8] <- as.Date(NA)
  result <- select_frame_indexes(tri_derive(rbind(x, dated)), "severe_obesity")
  audit <- setNames(result$audit$status, result$audit$patient_id)
  tri_equal(unname(audit[c("ARTIFICIAL-TIE", "ARTIFICIAL-UNKNOWN", "ARTIFICIAL-LATER", "ARTIFICIAL-UNDATED")]),
            c("earliest_date_tie", "uncertain_earlier_membership", "resolved", "uncertain_earlier_membership"),
            "Earliest ties and possibly earlier qualifying encounters must remain unresolved")
  tri_check(result$counts$n_frame_patients == 4L && result$counts$n_index_unresolved == 3L &&
              result$counts$n_membership_uncertain == 1L,
            "Ambiguous and solely uncertain membership counts must reconcile")
}

check_duplicates_and_strict_source_coding <- function() {
  x <- tri_rows(2)
  clean <- validate_triangulation_input(rbind(x, x[1, ]))
  tri_check(nrow(clean) == 2L && attr(clean, "exact_duplicates_removed") == 1L,
            "Only byte-equivalent analysis rows may collapse as exact duplicates")
  conflict <- x[1, ]; conflict$bmi <- 43
  conflict_only <- select_frame_indexes(tri_derive(rbind(x, conflict)), "severe_obesity")
  tri_check(!x$patient_id[1] %in% conflict_only$indexes$patient_id &&
              conflict_only$counts$n_conflicting_indexes == 1L &&
              conflict_only$counts$n_frame_patients == 2L,
            "Consensus membership may be retained, but conflicting index evidence must remain unresolved")
  later <- x[1, ]; later$encounter_id <- "ARTIFICIAL-LATER"; later$encounter_date <- later$encounter_date + 1
  conflicts <- rbind(x, conflict, later)
  blocked <- select_frame_indexes(tri_derive(conflicts), "severe_obesity")
  tri_check(!x$patient_id[1] %in% blocked$indexes$patient_id && blocked$counts$n_conflicting_indexes == 1L,
            "An earlier conflicting encounter must block substitution of a later confirmed index")
  tri_check(run_triangulation(conflicts)$scope$n_conflicting_keys == 1L,
            "The aggregate scope audit must count unresolved conflicting keys")
  conflict$bmi <- 38
  disagreement <- select_frame_indexes(tri_derive(rbind(x, conflict)), "severe_obesity")
  tri_check(disagreement$counts$n_membership_uncertain == 1L && disagreement$counts$n_frame_patients == 1L,
            "Versions disagreeing about frame eligibility must leave patient membership uncertain")
  blocked <- select_frame_indexes(tri_derive(rbind(x, conflict, later)), "severe_obesity")
  tri_check(!x$patient_id[1] %in% blocked$indexes$patient_id && blocked$counts$n_earlier_uncertainty == 1L,
            "Earlier conflicting membership must block promotion of a later record")
  bad <- x; bad$has_abg <- factor(c("0", "1"))
  tri_error(validate_triangulation_input(bad), "factor level", "Binary factor storage must not become numeric clinical codes")
  bad <- x; bad$bmi <- factor(c("40", "41"))
  tri_error(validate_triangulation_input(bad), "finite numeric", "Factor BMI must fail validation")
  bad <- x; bad$patient_id <- 1:2
  tri_error(validate_triangulation_input(bad), "character keys", "Numeric or row-number patient identifiers must fail")
  bad <- x; bad$encounter_date <- as.numeric(bad$encounter_date)
  tri_error(validate_triangulation_input(bad), "must be Date", "Unreviewed numeric date origins must fail")
  bad <- x; bad$has_abg[1] <- 0
  tri_error(validate_triangulation_input(bad), "without a confirmed draw", "Available results require a confirmed draw")
  bad <- x; bad$icd_hypercapnia[1] <- 2
  tri_error(validate_triangulation_input(bad), "0/1/NA", "Undocumented binary levels must fail")
  bad <- x; bad$bmi[1] <- Inf
  tri_error(validate_triangulation_input(bad), "finite numeric", "Infinite exposures must fail")
}

check_nonestimable_models_are_explicit <- function() {
  x <- tri_derive(make_triangulation_fixture(300L))
  x <- x[complete.cases(x[triangulation_adjustment]), ]
  x$icd <- 0L
  fit <- fit_triangulation_cell(x, "severe_obesity", "icd")
  tri_check(fit$status == "not_estimable" && grepl("Outcome has no variation", fit$reason), "Constant outcomes require an explicit reason")
  x$icd <- rep(c(0L, 1L), length.out = nrow(x))
  constant <- x; constant$bmi <- 42
  tri_check(grepl("BMI has no variation", fit_triangulation_cell(constant, "severe_obesity", "icd")$reason), "Constant BMI must not produce an estimate")
  deficient <- x; deficient$age_at_encounter <- deficient$bmi
  tri_check(grepl("rank deficient", fit_triangulation_cell(deficient, "severe_obesity", "icd")$reason), "Collinearity must not silently remove an adjustment variable")
  empty <- x; empty$icd <- NA_integer_
  tri_check(grepl("No complete model cases", fit_triangulation_cell(empty, "severe_obesity", "icd")$reason), "No-case cells need a readable explanation")
  x$icd <- as.integer(x$bmi > stats::median(x$bmi))
  separated <- fit_triangulation_cell(x, "severe_obesity", "icd")
  tri_check(grepl("separation", separated$reason) && is.na(separated$odds_ratio), "Separated cells must never display finite-looking BMI effects")
  quasi_matrix <- cbind(`(Intercept)` = 1, bmi = c(-1, 0, 0, 1))
  tri_check(detect_tri_separation(quasi_matrix, c(0L, 0L, 1L, 1L)),
            "Separation detection must include quasi separation with overlapping boundary observations")
  tri_check(!detect_tri_separation(quasi_matrix, c(0L, 1L, 0L, 0L)),
            "An overlapping outcome pattern must not be falsely declared separated")
}

check_models_match_independent_glm_and_counts <- function() {
  data <- make_triangulation_fixture()
  tri_check(identical(attr(data, "data_status"), "ARTIFICIAL FIXTURE - NOT CLINICAL RESULTS"), "Fixture must advertise its artificial status")
  derived <- tri_derive(data)
  output <- run_triangulation(data)
  tri_check(nrow(output$results) == 15L && !anyDuplicated(output$results$cell_id), "The result ledger must contain exactly fifteen unique cells")
  tri_check(all(output$results$status == "estimated"), "Default artificial fixture should exercise fifteen successfully estimated models")
  for (frame in names(triangulation_frames)) {
    index <- select_frame_indexes(derived, frame)$indexes
    tri_check(!anyDuplicated(index$patient_id), paste("One row per patient required in", frame))
    for (outcome in names(triangulation_outcomes)) {
      z <- index[!is.na(index[[outcome]]) & complete.cases(index[triangulation_adjustment]), ]
      direct <- stats::glm(stats::reformulate(c("bmi", "age_at_encounter", "factor(sex)",
                         "factor(race_ethnicity)", "factor(location)"), response = outcome),
                         data = z, family = stats::binomial())
      coefficients <- stats::coef(summary(direct))["bmi", ]
      cell <- output$results[output$results$frame == frame & output$results$outcome == outcome & output$results$analysis_role == "primary", ]
      tri_equal(c(cell$beta, cell$se, cell$odds_ratio, cell$conf_low, cell$conf_high),
                c(unname(coefficients[1:2]), exp(coefficients[1]),
                  exp(coefficients[1] + c(-1, 1) * stats::qnorm(.975) * coefficients[2])),
                paste("Independent direct GLM parity failed for", frame, outcome))
      tri_check(cell$n_model == nrow(z) && cell$n_events == sum(z[[outcome]]), "Model counts must match its actual complete-case population")
      counterfactual <- z
      counterfactual$bmi <- ifelse(counterfactual$bmi > 30, counterfactual$bmi - 1, counterfactual$bmi)
      p_observed <- mean(stats::predict(direct, newdata = z, type = "response"))
      p_counterfactual <- mean(stats::predict(direct, newdata = counterfactual, type = "response"))
      tri_check(cell$impact_status == "estimated", "Successful fixture GLMs must have qualified impact-fraction standardization")
      tri_equal(c(cell$p_observed, cell$p_counterfactual, cell$absolute_difference, cell$impact_fraction),
                c(p_observed, p_counterfactual, p_observed - p_counterfactual, 1 - p_counterfactual / p_observed),
                paste("One-unit BMI shift standardization must use the original complete-case target in", frame, outcome))
      tri_check(cell$n_bmi_shifted == sum(z$bmi > 30), "Counterfactual shift counts must come from the fixed original model cases")
    }
  }
  r <- output$results
  tri_check(all(r$n_frame_patients == r$n_index_resolved + r$n_index_unresolved) &&
              all(r$n_index_resolved == r$n_outcome_known + r$n_outcome_missing) &&
              all(r$n_outcome_known == r$n_model + r$n_missing_adjustment),
            "Each exclusion stage must reconcile separately in all nine cells")
  tri_check(output$scope$input_encounters == output$scope$exact_duplicates_removed + output$scope$distinct_encounter_versions &&
              output$scope$distinct_encounter_versions == output$scope$in_scope + output$scope$out_of_scope + output$scope$uncertain_scope,
            "Scope accounting must reconcile to the input encounter count")
}

tri_standardization_example <- function() {
  x <- tri_derive(make_triangulation_fixture(300L))
  x <- x[!is.na(x$icd) & complete.cases(x[triangulation_adjustment]), ]
  x$bmi[1:3] <- c(29.999, 30, 30.001)
  x$.outcome <- x$icd
  fit <- stats::glm(.outcome ~ bmi + age_at_encounter + factor(sex) +
                      factor(race_ethnicity) + factor(location),
                    data = x, family = stats::binomial())
  list(data = x, fit = fit)
}

tri_direct_standardization <- function(fit, data) {
  counterfactual <- data
  counterfactual$bmi <- ifelse(data$bmi > 30, data$bmi - 1, data$bmi)
  observed <- mean(stats::predict(fit, newdata = data, type = "response"))
  counter <- mean(stats::predict(fit, newdata = counterfactual, type = "response"))
  model_terms <- stats::delete.response(stats::terms(fit))
  x <- stats::model.matrix(model_terms, data = data,
                           contrasts.arg = fit$contrasts, xlev = fit$xlevels)
  x_counter <- stats::model.matrix(model_terms, data = counterfactual,
                                   contrasts.arg = fit$contrasts, xlev = fit$xlevels)
  beta <- stats::coef(fit)
  log_ratio <- function(coefficients) {
    log(mean(stats::plogis(x_counter %*% coefficients))) -
      log(mean(stats::plogis(x %*% coefficients)))
  }
  # Independent central differences check the full-coefficient analytic gradient.
  step <- 1e-6
  gradient <- vapply(seq_along(beta), function(i) {
    plus <- minus <- beta
    plus[i] <- plus[i] + step
    minus[i] <- minus[i] - step
    (log_ratio(plus) - log_ratio(minus)) / (2 * step)
  }, numeric(1))
  se <- sqrt(drop(t(gradient) %*% stats::vcov(fit) %*% gradient))
  interval <- 1 - exp(log_ratio(beta) + c(1, -1) * stats::qnorm(.975) * se)
  list(p_observed = observed, p_counterfactual = counter,
       absolute_difference = observed - counter, impact_fraction = 1 - counter / observed,
       se_log_probability_ratio = se, impact_conf_low = interval[1], impact_conf_high = interval[2])
}

check_bmi_shift_standardization_and_full_covariance_interval <- function() {
  example <- tri_standardization_example()
  original <- example$data
  result <- standardize_bmi_shift(example$fit, example$data)
  expected <- tri_direct_standardization(example$fit, original)
  tri_check(result$impact_status == "estimated", "Finite standardization must be estimated")
  for (field in names(expected)) {
    tri_equal(result[[field]], expected[[field]],
              paste("Direct prediction/full-covariance finite-difference mismatch:", field), tolerance = 1e-7)
  }
  tri_check(identical(example$data, original), "Standardization must not modify original rows, indexes, BMI, or covariates")
  tri_check(result$n_bmi_shifted == sum(original$bmi > 30) &&
              result$n_bmi_shifted < nrow(original),
            "The one-unit intervention changes only observed BMI above 30, including the 30.001 boundary")
  tri_check(result$n_counterfactual_outside_support == 0L,
            "One-unit BMI shift predictions in a mixed-BMI target remain inside its observed BMI range")
  severe <- original[original$bmi > 40, ]
  severe_fit <- stats::glm(stats::formula(example$fit), data = severe, family = stats::binomial())
  severe_result <- standardize_bmi_shift(severe_fit, severe)
  tri_check(severe_result$impact_status == "estimated" &&
              severe_result$n_counterfactual_outside_support == sum((severe$bmi - 1) < min(severe$bmi)),
            "One-unit shifts near the lower severe-obesity boundary fall outside observed support")
}

check_null_negative_and_no_shift_impact_fractions <- function() {
  example <- tri_standardization_example()
  null_fit <- example$fit
  null_fit$coefficients["bmi"] <- 0
  null_result <- standardize_bmi_shift(null_fit, example$data)
  tri_check(null_result$impact_status == "estimated", "A zero BMI coefficient remains estimable")
  tri_equal(null_result$impact_fraction, 0, "A null BMI coefficient must yield zero impact fraction")
  tri_equal(null_result$absolute_difference, 0, "A null BMI coefficient must yield zero absolute probability difference")
  negative_fit <- example$fit
  negative_fit$coefficients["bmi"] <- -.08
  negative_result <- standardize_bmi_shift(negative_fit, example$data)
  negative_expected <- tri_direct_standardization(negative_fit, example$data)
  tri_check(negative_result$impact_status == "estimated" && negative_result$impact_fraction < 0 &&
              negative_result$impact_conf_low < 0,
            "Negative associations must retain negative impact fractions and confidence bounds")
  for (field in c("impact_fraction", "impact_conf_low", "impact_conf_high")) {
    tri_equal(negative_result[[field]], negative_expected[[field]],
              paste("Negative impact fractions must not be truncated:", field), tolerance = 1e-7)
  }
  below <- example$data[example$data$bmi <= 30, ]
  below_fit <- stats::glm(stats::formula(example$fit), data = below, family = stats::binomial())
  no_shift <- standardize_bmi_shift(below_fit, below)
  tri_check(no_shift$impact_status == "estimated" && no_shift$n_bmi_shifted == 0L,
            "A target entirely at or below BMI 30 has no shifted patients")
  tri_equal(c(no_shift$impact_fraction, no_shift$absolute_difference,
              no_shift$impact_conf_low, no_shift$impact_conf_high, no_shift$se_log_probability_ratio),
            rep(0, 5), "An identity counterfactual must yield zero impact and a zero-width confidence interval")
}

check_invalid_standardization_predictions_fail_explicitly <- function() {
  example <- tri_standardization_example()
  invalid <- example$fit
  invalid$coefficients["bmi"] <- NA_real_
  result <- suppressWarnings(standardize_bmi_shift(invalid, example$data))
  tri_check(result$impact_status == "not_estimable" && nzchar(result$impact_reason) &&
              is.na(result$impact_fraction),
            "Nonfinite predictions must return an explicit nonestimable impact status")
  zero_probability <- example$fit
  # Fault injection: normal binomial prediction clamps extreme logits above
  # zero, so supply actual zero predictions to exercise the probability guard.
  zero_probability$family$linkinv <- function(eta) rep(0, length(eta))
  result <- standardize_bmi_shift(zero_probability, example$data)
  tri_check(result$impact_status == "not_estimable" && nzchar(result$impact_reason) &&
              is.na(result$impact_fraction),
            "A zero modeled probability must not become an undefined reported probability ratio")
}

check_reviewed_loader_manifest <- function() {
  require_tri_packages(c("jsonlite", "digest", "haven"))
  directory <- tempfile("artificial-triangulation-loader-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  input <- file.path(directory, "artificial.rds")
  manifest_file <- file.path(directory, "artificial-manifest.json")
  data <- tri_rows(2)
  data$has_abg <- factor(c("Drawn", "Drawn"))
  saveRDS(data, input)
  manifest <- list(
    schema_version = 2L, input_sha256 = digest::digest(file = input, algo = "sha256"),
    source_identity = "ARTIFICIAL TEST ONLY", reviewed_by = "automated fixture check",
    reviewed_on = "2026-10-12", evidence_reference = "artificial source-map test",
    columns = as.list(stats::setNames(triangulation_columns, triangulation_columns)),
    binary_codes = list(has_abg = list(Drawn = "1"), has_vbg = list(`0` = "0", `1` = "1"),
                        icd_hypercapnia = list(`0` = "0", `1` = "1")),
    encounter_type_codes = list(EMER = "EMER", IMP = "IMP"),
    category_values = list(sex = "Female", race_ethnicity = "Race group A", location = "ED"),
    semantics = list(keys = "original_patient_and_encounter", date = "encounter_start_Date",
      bmi = "legacy_derived_kg_m2", gases = "selected_encounter_max_valid_PCO2_mmHg_specimen_verified",
      draws = "selected_encounter_draw_not_result", icd = "J96.02|J96.12|J96.22|J96.92|E66.2",
      icd_negative = "documented_composite_absent_with_capture", adjustment = "legacy_stata_codes_and_missingness")
  )
  evidence_file <- file.path(directory, "artificial-evidence.json")
  writeLines("ARTIFICIAL SOURCE EVIDENCE FOR LOADER TEST ONLY", evidence_file)
  manifest$source_qualification <- as.list(setNames(rep("accepted", 7), c("lineage", "population_scope", "keys_chronology", "bmi_adjustment", "gas_draws", "gas_units_windows", "icd_capture")))
  entry <- list(path = basename(evidence_file), sha256 = tri_sha256(evidence_file))
  manifest$source_evidence_files <- list(lineage = entry, population = entry, fields = entry)
  manifest$index_day <- list(status = "pending", columns = list())
  write_manifest <- function(x) jsonlite::write_json(x, manifest_file, auto_unbox = TRUE, pretty = TRUE)
  write_manifest(manifest)
  loaded <- load_triangulation_input(input, manifest_file)
  tri_equal(loaded$data$has_abg, c(1L, 1L), "Reviewed factor labels must be decoded by label, not level number")
  tri_error(load_triangulation_input("", manifest_file), "explicit input", "Clinical loader must require explicit paths")
  changed <- manifest; changed$input_sha256 <- paste(rep("0", 64), collapse = "")
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "SHA-256", "Changed input identity must fail before acceptance")
  changed <- manifest; changed$semantics$bmi <- "current_only"
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "Unreviewed semantics", "Unreviewed BMI substitutions must fail")
  changed <- manifest; changed$reviewed_by <- "PENDING"
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "metadata incomplete", "Placeholder review metadata must fail")
  changed <- manifest; changed$binary_codes$has_abg <- list(`1` = "1")
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "Unmapped source coding", "Factor level numbers must not bypass reviewed label mapping")
  changed <- manifest; changed$encounter_type_codes$EMER <- "EMERR"
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "encounter_type", "A misspelled encounter-type target must fail rather than exclude an entire frame")
  changed <- manifest; changed$schema_version <- 1L
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "version 2", "Historical input manifests cannot authorize new estimation")
  changed <- manifest; changed$source_qualification$population_scope <- "pending"
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "source qualification", "Population qualification must be explicit")
  changed <- manifest; changed$index_day$columns <- list(abg_pco2_index_day = "abg_pco2")
  write_manifest(changed)
  tri_error(load_triangulation_input(input, manifest_file), "Pending index-day", "Unqualified timing fields cannot be silently used")
  data$abg_pco2_index_day <- c(43, NA_real_)
  data$vbg_pco2_index_day <- NA_real_
  data$abg_index_day_available <- c(1L, 0L)
  data$vbg_index_day_available <- c(0L, 0L)
  saveRDS(data, input)
  changed <- manifest
  changed$input_sha256 <- tri_sha256(input)
  changed$source_evidence_files$index_day <- entry
  changed$index_day <- list(status = "qualified", semantics = "max_valid_specimen_PCO2_on_encounter_start_calendar_date",
    columns = as.list(setNames(triangulation_index_day_columns, triangulation_index_day_columns)),
    binary_codes = list(abg_index_day_available = list(`0` = "0", `1` = "1"), vbg_index_day_available = list(`0` = "0", `1` = "1")))
  write_manifest(changed)
  loaded <- load_triangulation_input(input, manifest_file)
  tri_equal(loaded$data$abg_pco2_index_day, c(43, NA), "Qualified calendar-day evidence must preserve its exact values")
  invalid <- changed; invalid$index_day$semantics <- "first24hours"
  write_manifest(invalid)
  tri_error(load_triangulation_input(input, manifest_file), "calendar-day evidence", "Calendar dates cannot be relabeled as elapsed hours")
  write_manifest(changed)
  cat("tampered", file = evidence_file, append = TRUE)
  tri_error(load_triangulation_input(input, manifest_file), "evidence file hash", "Source receipt tampering must fail before estimation")
  writeLines("ARTIFICIAL SOURCE EVIDENCE FOR LOADER TEST ONLY", evidence_file)
  write_manifest(changed)
  changing_loader <- load_triangulation_input
  local_environment <- new.env(parent = environment(changing_loader))
  environment(changing_loader) <- local_environment
  local_environment$readRDS <- function(path) {
    value <- base::readRDS(path)
    cat("changed during read", file = path, append = TRUE)
    value
  }
  tri_error(changing_loader(input, manifest_file), "changed during loading", "A changing input cannot be accepted under its earlier hash")
}

check_aggregate_bundle_roundtrip_and_tamper <- function() {
  a <- run_triangulation(make_triangulation_fixture(300L))
  directory <- tempfile("artificial-bundle-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  input <- file.path(directory, "explicit-artificial-input.rds")
  saveRDS(tri_rows(), input)
  write_tri_bundle(a, directory, list(mode = "fixture", input_sha256 = tri_sha256(input), source_identity = "ARTIFICIAL", input_path = input), list(estimator = "artificial check"), "fixture", "artificial-check")
  unlink(input)
  # Tripwires prove aggregate consumption requires neither loader nor estimator.
  original_loader <- load_triangulation_input; original_estimator <- run_triangulation
  target <- environment(read_tri_bundle)
  assign("load_triangulation_input", function(...) stop("Clinical input opened during review"), envir = target)
  assign("run_triangulation", function(...) stop("Analysis repeated during review"), envir = target)
  on.exit({ assign("load_triangulation_input", original_loader, envir = target); assign("run_triangulation", original_estimator, envir = target) }, add = TRUE)
  bundle <- read_tri_bundle(directory)
  tri_equal(bundle$analysis, a, "Bundle must preserve every full-precision aggregate")
  tri_check(length(tri_figure_candidates(bundle$analysis$results, TRUE)) == 3L, "All three figures must build from saved aggregates without an input or estimator")
  tri_error(write_tri_bundle(a, directory, list(), list(), "fixture", "replace"), "Refusing", "A frozen bundle cannot be overwritten")
  file <- file.path(directory, "aggregate_results.csv")
  cat("tampered", file = file, append = TRUE)
  tri_error(read_tri_bundle(directory), "hash mismatch", "Changed aggregate files must fail explicitly")
}

check_aggregate_contract_and_manifest_integrity <- function() {
  a <- run_triangulation(make_triangulation_fixture(300L))
  bad <- a; bad$results$patient_id <- "ARTIFICIAL-ID"
  tri_error(validate_tri_aggregates(bad), "Patient-level", "Identifier fields must not enter a bundle")
  bad <- a; bad$results$unexpected <- 1
  tri_error(validate_tri_aggregates(bad), "Unrecognized", "Unrecognized row-level additions must be rejected")
  bad <- a; bad$results$n_model[1] <- bad$results$n_model[1] + 1
  tri_error(validate_tri_aggregates(bad), "denominator", "Denominator corruption must fail")
  directory <- tempfile("artificial-manifest-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  write_tri_bundle(a, directory, list(source_identity = "ARTIFICIAL"), list(), "fixture", "test")
  cat(" ", file = file.path(directory, "bundle_manifest.json"), append = TRUE)
  tri_error(read_tri_bundle(directory), "manifest hash", "Changed manifest must fail before loading aggregates")
}

check_display_edges_and_estimator_parity <- function() {
  a <- run_triangulation(make_triangulation_fixture(300L))
  original <- a$results
  d <- prepare_tri_display(original)
  tri_equal(d$data[names(original)], original, "Display preparation must preserve the numerical ledger")
  r <- original
  r$impact_fraction[1:3] <- c(-.12, 0, .02)
  r$impact_conf_low[1:3] <- c(-.3, 0, -.4)
  r$impact_conf_high[1:3] <- c(.03, 0, .8)
  r$impact_reason[2] <- "No BMI above 30: identical scenarios"
  r$impact_status[4] <- "not_estimable"
  r$impact_reason[4] <- paste(rep("Long diagnostic explanation", 8), collapse = " ")
  r[4, c("impact_fraction", "impact_conf_low", "impact_conf_high")] <- NA_real_
  r$n_counterfactual_outside_support[5] <- r$n_model[5]
  r$n_counterfactual_outside_support[6] <- 0L
  d <- prepare_tri_display(r)
  tri_check(d$limits[1] < -.4 && d$limits[2] > .8 && 0 %in% d$ticks && any(d$ticks < 0), "Every finite endpoint and zero must remain on the shared axis")
  tri_check(d$data$estimate_label[4] == "Not estimable" && grepl("0.00%", d$data$estimate_label[2], fixed = TRUE), "Missing estimates and genuine zero must remain distinct")
  candidates <- tri_figure_candidates(r, TRUE)
  tri_check(identical(names(candidates), c("A", "B", "C")) && all(vapply(candidates, inherits, logical(1), "grob")), "Every edge case must remain buildable in all candidates")
  tri_equal(a$results, original, "Figure construction must not mutate analysis results")
}

check_positional_patient_indexes_preserve_membership <- function() {
  x <- tri_rows(11)
  x$patient_id <- paste0("ARTIFICIAL-", c("C", "A", "B", "A", "B", "D", "E", "E", "F", "F", "B"))
  x$encounter_date <- as.Date(c("2022-01-01", "2022-02-01", "2022-02-01", "2022-01-01",
                                "2022-03-01", "2022-01-01", "2022-02-01", NA,
                                "2022-01-01", "2022-01-01", "2022-04-01"))
  x$bmi[c(4, 5, 6)] <- NA_real_
  result <- select_frame_indexes(tri_derive(x), "severe_obesity")
  tri_equal(result$audit$patient_id, paste0("ARTIFICIAL-", c("A", "B", "C", "E", "F")),
            "Positional traversal must retain the original patient order")
  tri_equal(result$audit$status, c("uncertain_earlier_membership", "resolved", "resolved", "uncertain_earlier_membership", "earliest_date_tie"),
            "Possible groups must match patients, not their independent list positions")
  tri_equal(result$indexes$encounter_id, x$encounter_id[c(3, 1)],
            "Earlier uncertainty blocks selection; later uncertainty does not move the index")
  tri_equal(unlist(result$counts[c("n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_membership_uncertain")]),
            c(5L, 2L, 3L, 1L), "Membership and index denominators must remain unchanged")
  reversed <- select_frame_indexes(tri_derive(x[rev(seq_len(nrow(x))), ]), "severe_obesity")
  tri_equal(reversed$indexes, result$indexes, "Source order must not change selected encounters")
  tri_equal(reversed$counts, result$counts, "Source order must not change audit counts")
  uncertain_only <- select_frame_indexes(tri_derive(x[c(4, 5, 6), ]), "severe_obesity")
  tri_check(nrow(uncertain_only$indexes) == 0L && uncertain_only$counts$n_membership_uncertain == 3L,
            "An empty confirmed group list must retain solely uncertain membership")
}

check_preflight_all_missing_categories_complete <- function() {
  require_tri_packages(c("jsonlite", "digest"))
  repo_root <- normalizePath(getwd(), mustWork = TRUE)
  while (!file.exists(file.path(repo_root, "scripts", "preflight_triangulation.R"))) {
    parent <- dirname(repo_root)
    if (identical(parent, repo_root)) stop("Cannot locate preflight entrypoint")
    repo_root <- parent
  }
  directory <- tempfile("artificial-preflight-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  x <- tri_rows(3)
  x$has_vbg <- rep(NA_integer_, 3)
  x$sex <- factor(rep(NA_character_, 3), levels = c("Female", "Male"))
  run_root <- file.path(repo_root, "artifacts", "triangulation")
  for (case in c("all_missing", "empty_input")) {
    input <- file.path(directory, paste0(case, ".rds"))
    saveRDS(if (case == "all_missing") x else x[0, ], input)
    before <- list.dirs(run_root, recursive = FALSE, full.names = TRUE)
    log <- file.path(directory, paste0(case, ".log"))
    command <- paste("cd", shQuote(repo_root), "&&", shQuote(file.path(R.home("bin"), "Rscript")),
                     "--vanilla", shQuote("scripts/preflight_triangulation.R"), shQuote(input))
    status <- system2("sh", c("-c", shQuote(command)), stdout = log, stderr = log)
    created <- setdiff(list.dirs(run_root, recursive = FALSE, full.names = TRUE), before)
    on.exit(unlink(created, recursive = TRUE), add = TRUE)
    tri_check(identical(status, 0L), paste("Preflight must finish:", paste(readLines(log), collapse = " ")))
    tri_check(length(created) == 1L, "Preflight must create one fresh audit directory")
    receipt <- jsonlite::read_json(file.path(created, "preflight_receipt.json"), simplifyVector = TRUE)
    tri_check(receipt$models_fitted == 0L && !receipt$provenance_authenticated && !receipt$clinical_results_qualified,
              "All-missing/empty-input preflight must emit an honest final receipt without fitting models")
    tri_check(identical(receipt$input_sha256, tri_sha256(input)), "Audit receipt must identify the artificial input")
    codes <- utils::read.csv(file.path(created, "category_codes.csv"))
    for (field in c("has_vbg", "sex")) {
      row <- codes[codes$column == field, ]
      tri_check(nrow(row) == 1L && row$code == "[ALL VALUES MISSING]" && row$n == receipt$input_rows,
                "Entirely missing categories must have explicit markers and correct missing counts")
    }
    if (case == "all_missing") {
      row <- codes[codes$column == "has_abg", ]
      tri_check(nrow(row) == 1L && row$code == "1" && row$n == 3L,
                "The missingness fix must preserve observed code counts")
    }
    unlink(created, recursive = TRUE)
  }
}

check_exact_one_unit_shift_boundary <- function() {
  bmi <- c(29.999, 30, 30.001, 30.2, 40, 55, NA_real_)
  tri_equal(shift_bmi_above30(bmi), c(29.999, 30, 29.001, 29.2, 39, 54, NA),
    "Shift must use observed BMI >30, subtract exactly one, and permit crossing below 30")
}

check_primary_model_and_index_parity <- function() {
  data <- make_triangulation_fixture(300L)
  legacy <- tri_legacy_context()$context
  old <- legacy$run_triangulation(data)
  current <- run_triangulation(data)
  primary <- current$results[current$results$analysis_role == "primary", ]
  keys <- paste(primary$frame, primary$outcome)
  reference <- old$results[match(keys, paste(old$results$frame, old$results$outcome)), ]
  fields <- c("beta", "se", "odds_ratio", "conf_low", "conf_high", "p_observed", "n_model", "n_events",
    "n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_outcome_known", "n_outcome_missing", "n_missing_adjustment")
  tri_equal(primary[fields], reference[fields], "Changing the scenario must preserve fitted models, observed predictions and denominators")
  new_data <- tri_derive(data)
  old_data <- legacy$derive_triangulation_variables(legacy$validate_triangulation_input(data))
  for (frame in names(triangulation_frames)) {
    tri_equal(select_frame_indexes(new_data, frame)$indexes[triangulation_columns],
      legacy$select_frame_indexes(old_data, frame)$indexes[triangulation_columns], "Primary indexes must remain identical")
  }
}

check_calendar_day_states_and_fixed_indexes <- function() {
  x <- tri_rows(4)
  x$abg_pco2 <- c(60, 60, 44, NA)
  x$vbg_pco2 <- c(NA, NA, 55, 52)
  x$has_vbg <- c(0L, 0L, 1L, 1L)
  x$abg_pco2_index_day <- c(44, NA, 44, NA)
  x$vbg_pco2_index_day <- c(NA, NA, 50, 49)
  x$abg_index_day_available <- c(1L, 0L, 1L, NA)
  x$vbg_index_day_available <- c(NA, NA, 1L, 1L)
  y <- tri_derive(x)
  tri_equal(y$abg_index_calendar_day, c(0L, NA, 0L, NA), "Later-only arterial positivity must not become early positive or negative")
  tri_equal(y$any_gas_index_calendar_day, c(0L, NA, 1L, 0L), "Calendar-day combined classification must retain available negatives and inclusive venous positivity")
  bad <- x; bad$abg_pco2_index_day[1] <- 61
  tri_error(validate_triangulation_input(bad), "exceeds encounter", "Early maximum cannot exceed encounter maximum")
  bad <- x; bad$abg_index_day_available[1] <- 0L
  tri_error(validate_triangulation_input(bad), "availability and maximum", "Early availability must match usable results")
  bad <- x; bad$vbg_pco2_index_day <- NULL
  tri_error(validate_triangulation_input(bad), "Incomplete index", "Partially supplied timing source must not silently become pending")
  duplicate <- x[1, ]; duplicate$abg_pco2_index_day <- 45
  conflicted <- tri_derive(rbind(x, duplicate))
  tri_check(!any(conflicted$.key_conflict) && conflicted$.index_day_conflict[1] &&
    is.na(conflicted$abg_index_calendar_day[1]), "Early conflict must remain unknown without creating a primary conflict")
  tri_equal(select_frame_indexes(y, "abg_drawn")$indexes[triangulation_columns],
    select_frame_indexes(conflicted, "abg_drawn")$indexes[triangulation_columns], "Early conflict must not move a primary index")
}

check_outcome_variation_uses_selected_window <- function() {
  raw <- make_triangulation_fixture(600L)
  raw$has_abg <- 1L
  raw$abg_pco2 <- 60
  raw$abg_pco2_index_day <- ifelse(raw$icd_hypercapnia %in% 1L, 48, 43)
  raw$abg_index_day_available <- 1L
  raw$has_vbg <- 0L
  raw$vbg_pco2 <- raw$vbg_pco2_index_day <- NA_real_
  raw$vbg_index_day_available <- 0L
  indexes <- select_frame_indexes(tri_derive(raw), "abg_drawn")$indexes
  cases <- indexes[complete.cases(indexes[triangulation_adjustment]), , drop = FALSE]
  for (outcome in c("abg", "any_gas")) {
    day_field <- paste0(outcome, "_index_calendar_day")
    cases$.outcome <- cases[[day_field]]
    independent <- stats::glm(.outcome ~ bmi + age_at_encounter + factor(sex) +
      factor(race_ethnicity) + factor(location), data = cases, family = stats::binomial())
    expected <- standardize_bmi_shift(independent, cases)
    day <- fit_triangulation_cell(indexes, "abg_drawn", outcome, "index_calendar_day")
    tri_check(day$status == "estimated" && day$impact_status == "estimated",
      "Varying calendar-day outcomes must be estimated even when encounter outcomes are constant")
    tri_equal(day$beta, stats::coef(independent)["bmi"], "Sensitivity must fit the day-specific outcome")
    tri_equal(day$n_events, sum(cases[[day_field]] == 1L), "Sensitivity events must use day-specific cases")
    tri_equal(day$n_model, nrow(cases), "The variation check must not change the model denominator")
    for (field in c("p_observed", "p_counterfactual", "impact_fraction", "impact_conf_low", "impact_conf_high")) {
      tri_equal(day[[field]], expected[[field]], "Sensitivity predictions must match the independent day-specific model")
    }
    primary <- fit_triangulation_cell(indexes, "abg_drawn", outcome)
    tri_check(primary$status == "not_estimable" && primary$reason == "Outcome has no variation",
      "Constant encounter outcomes must remain nonestimable")
    constant_day <- indexes
    constant_day[[outcome]] <- constant_day[[day_field]]
    constant_day[[day_field]] <- 0L
    rejected <- fit_triangulation_cell(constant_day, "abg_drawn", outcome, "index_calendar_day")
    tri_check(rejected$status == "not_estimable" && rejected$reason == "Outcome has no variation" &&
      is.na(rejected$impact_fraction), "Constant calendar-day outcomes need their own variation rejection")
  }
}

check_fifteen_cell_registry_and_pending_module <- function() {
  registry <- triangulation_registry()
  tri_check(nrow(registry) == 15L && sum(registry$analysis_role == "primary") == 9L &&
    sum(registry$analysis_role == "sensitivity") == 6L && !anyDuplicated(registry$cell_id) &&
    !any(registry$outcome == "icd" & registry$analysis_role == "sensitivity"), "Registry must have nine primary and six gas-only sensitivity cells")
  a <- run_triangulation(make_triangulation_fixture(300L, with_index_day = FALSE))
  validate_tri_aggregates(a)
  pending <- a$results$analysis_role == "sensitivity"
  tri_check(all(a$results$impact_status[pending] == "awaiting_source_evidence") &&
    all(is.na(a$results$n_model[pending])) && all(is.na(a$results$n_outcome_known[pending])) &&
    all(a$results$status[!pending] == "estimated"), "Primary models must proceed while unassessed sensitivity counts remain missing")
  bad <- a; bad$results$n_model[pending] <- 0L
  tri_error(validate_tri_aggregates(bad), "Pending source", "Pending source must never become measured zero")
  tri_check(length(tri_figure_candidates(a$results, TRUE)) == 3L, "Pending positions must be buildable in every candidate")
}

check_bmi_and_timing_audit_reconciliation <- function() {
  a <- run_triangulation(make_triangulation_fixture(300L))
  validate_tri_aggregates(a)
  for (i in seq_len(nrow(a$results))) {
    r <- a$results[i, ]
    b <- a$bmi_diagnostics[a$bmi_diagnostics$cell_id == r$cell_id, ]
    tri_equal(sum(b$n * b$mean_fitted) / sum(b$n), r$p_observed, "BMI-bin predictions must reproduce observed standardization")
    tri_equal(sum(b$events), r$n_events, "BMI-bin events must match the model")
  }
  bad <- a; bad$timing_audit$n[1] <- bad$timing_audit$n[1] + 1L
  tri_error(validate_tri_aggregates(bad), "Timing audit", "Timing transition corruption must fail")
  bad <- a; bad$registry$ascertainment_window[1] <- "index_calendar_day"
  tri_error(validate_tri_aggregates(bad), "fifteen cells", "Registry mutation must fail")
  bad <- a; bad$results$scenario_id[1] <- "bmi_to40"
  tri_error(validate_tri_aggregates(bad), "Counterfactual", "Old scenario labels cannot enter the current ledger")
}

check_version1_bundles_keep_original_definition <- function() {
  legacy <- tri_legacy_context()
  source(file.path(legacy$root, "tests", "fixtures", "triangulation_fixture.R"), local = legacy$context)
  a <- legacy$context$run_triangulation(legacy$context$make_triangulation_fixture(300L))
  directory <- tempfile("artificial-v1-"); dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  legacy$context$write_tri_bundle(a, directory, list(source_identity = "ARTIFICIAL HISTORICAL FIXTURE"), list(), "fixture", "historical-check")
  bundle <- read_tri_bundle(directory)
  tri_equal(bundle$analysis, a, "Version-1 bundle values must remain unchanged")
  tri_check(bundle$manifest$schema_version == 1L && nrow(bundle$analysis$results) == 9L &&
    all(grepl("40", bundle$analysis$results$counterfactual)), "Historical BMI-to-40 must keep nine cells and original labels")
  tri_error(prepare_tri_display(bundle$analysis$results), "fifteen", "Old results cannot use the new display")
}

check_small_nonzero_display_precision <- function() {
  tri_check(tri_percent(0) == "0.00" && tri_percent(1e-7) != "0.00" && tri_percent(-1e-7) != "0.00",
    "Very small positive and negative quantities must remain distinct from exact zero")
}

triangulation_checks <- list(
  "inclusive thresholds and three-state gas outcomes" = check_inclusive_thresholds_and_combined_outcomes,
  "adult, encounter setting, and calendar boundaries" = check_adult_setting_and_calendar_scope,
  "frame-specific first indexes without missingness advancement" = check_first_indexes_and_no_missingness_advancement,
  "earliest ties and uncertain earlier membership" = check_ambiguous_indexes_and_membership,
  "duplicate keys and strict input coding" = check_duplicates_and_strict_source_coding,
  "nonestimable, rank-deficient, and separated cells" = check_nonestimable_models_are_explicit,
  "independent GLM parity and fifteen-cell denominator reconciliation" = check_models_match_independent_glm_and_counts,
  "One-unit BMI shift standardization and full covariance delta interval" = check_bmi_shift_standardization_and_full_covariance_interval,
  "null, negative, and identity BMI counterfactuals" = check_null_negative_and_no_shift_impact_fractions,
  "invalid standardization predictions remain nonestimable" = check_invalid_standardization_predictions_fail_explicitly,
  "reviewed manifest and input identity validation" = check_reviewed_loader_manifest,
  "aggregate roundtrip, absent input, review tripwires and file tamper" = check_aggregate_bundle_roundtrip_and_tamper,
  "aggregate-only schema and manifest integrity" = check_aggregate_contract_and_manifest_integrity,
  "shared display contract, edge cases and estimate preservation" = check_display_edges_and_estimator_parity,
  "positional patient matching preserves index and uncertainty semantics" = check_positional_patient_indexes_preserve_membership,
  "all-missing and empty preflight inputs complete without models" = check_preflight_all_missing_categories_complete,
  "exact one-unit shift above the observed BMI-30 boundary" = check_exact_one_unit_shift_boundary,
  "primary model, probability, denominator and index parity" = check_primary_model_and_index_parity,
  "calendar-day states and conflicts retain fixed primary indexes" = check_calendar_day_states_and_fixed_indexes,
  "outcome variation uses the selected ascertainment window" = check_outcome_variation_uses_selected_window,
  "fifteen-cell registry with six pending sensitivity positions" = check_fifteen_cell_registry_and_pending_module,
  "BMI-bin and timing-transition reconciliation" = check_bmi_and_timing_audit_reconciliation,
  "version-one bundles retain historical BMI-to-40 definitions" = check_version1_bundles_keep_original_definition,
  "tiny nonzero estimates remain visible" = check_small_nonzero_display_precision
)
