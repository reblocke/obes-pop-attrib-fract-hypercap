# Common-index study. Source base helpers first; no input is read on sourcing.
common_design_id <- "common_index_bmi_ge30_v1"
common_windows <- c("encounter", "index_calendar_day")
common_risk_odds <- c(.25, .5, 1, 2, 4)
common_gradient_odds <- c(.5, 1, 2)
common_formula <- .outcome ~ bmi + age_at_encounter + factor(sex) + factor(race_ethnicity) + factor(location)

common_specification <- function() list(
  study_design = common_design_id, scenario_id = triangulation_scenario_id,
  counterfactual = triangulation_counterfactual,
  population_policy = "first_2022_adult_ED_inpatient_BMI_ge30_before_gas_and_completeness",
  reference_policy = "resolved indexes with complete inherited adjustment; same target for both gas projections",
  severe_obesity_policy = "BMI >=40 at original common index; reuse BMI >=30 models",
  adjustment = triangulation_adjustment, bmi_age_form = "linear log odds",
  gas_outcomes = c("PaCO2 >=45", "PaCO2 >=45 or PvCO2 >=50; available evidence"),
  windows = common_windows, missingness = "outcome regression MAR benchmark; observation status fixed",
  mnar = "logit(q0)=eta+log(r)+log(g)*(BMI-40)/5; evaluate at shifted BMI too",
  risk_odds = common_risk_odds, gradient_odds = common_gradient_odds,
  interval = "pointwise full-coefficient delta; empirical reference, observation status and sensitivity parameters fixed",
  icd = "J96.02|J96.12|J96.22|J96.92|E66.2; separate matched arterial and either-gas pairs"
)

common_registry <- function() {
  methods <- rbind(data.frame(method = c("observed", "mar"), r = 1, g = 1),
    data.frame(method = "mnar", expand.grid(r = common_risk_odds, g = common_gradient_odds)))
  rows <- list()
  for (target in c("bmi_ge30", "bmi_ge40")) for (window in common_windows) for (outcome in c("abg", "any_gas")) {
    rows[[length(rows) + 1L]] <- data.frame(target_id = target, outcome = outcome, window = window,
      methods, model_id = paste(outcome, window, sep = "/"), stringsAsFactors = FALSE)
  }
  for (pair in c("abg", "any_gas")) for (outcome in c("icd", pair)) {
    rows[[length(rows) + 1L]] <- data.frame(target_id = paste0("matched_", pair), outcome = outcome,
      window = "encounter", method = "matched", r = 1, g = 1,
      model_id = paste0("matched_", pair, "/", outcome), stringsAsFactors = FALSE)
  }
  registry <- do.call(rbind, rows)
  registry$cell_id <- with(registry, paste(target_id, outcome, window, method, r, g, sep = "/"))
  registry$display_order <- seq_len(nrow(registry))
  rownames(registry) <- NULL
  registry
}

common_source_policy <- function() jsonlite::read_json(
  file.path(tri_repo_root(), "config", "common_index_source_policy.json"), simplifyVector = FALSE)

load_common_input <- function(input_path, manifest_path) {
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  policy <- common_source_policy()
  if (!identical(manifest$source_policy_id, policy$source_policy_id)) stop("New clinical input requires unadjusted_pco2_v1 source policy.")
  loaded <- load_triangulation_input(input_path, manifest_path, schema_version = 3L, study_design = common_design_id)
  entry <- loaded$manifest$source_evidence_files$fields
  field_path <- entry$path
  if (!grepl("^(/|[A-Za-z]:)", field_path)) field_path <- file.path(dirname(manifest_path), field_path)
  fields <- jsonlite::read_json(field_path, simplifyVector = FALSE)
  if (!isTRUE(all.equal(fields$source_policy, policy, check.attributes = FALSE))) stop("Field evidence does not bind the exact unadjusted gas/ICD policy.")
  for (gas in c("abg", "vbg")) {
    bounds <- policy[[if (gas == "abg") "arterial_validity" else "venous_validity"]]
    names <- c(paste0(gas, "_pco2"), paste0(gas, "_pco2_index_day"))
    for (name in intersect(names, colnames(loaded$data))) {
      value <- loaded$data[[name]]
      if (any(value <= bounds$lower_exclusive | value >= bounds$upper_exclusive, na.rm = TRUE)) stop("Gas outside the bound source validity policy: ", name)
    }
  }
  if (!identical(tri_sha256(field_path), tolower(entry$sha256))) stop("Field evidence changed during loading.")
  allowed_audits <- list(gas_audit = c("unavailable_domain", "unavailable_field", "specimen_conflict", "unspecified_specimen",
    "temperature_adjusted_excluded", "unreviewed_code", "unusable_numeric", "unusable_units", "outside_validity_limits",
    "valid_unadjusted", "valid_value_unknown_collection_date", "temperature_adjusted_source_records",
    "encounters_with_temperature_adjusted_records", paste0(rep(c("abg", "vbg"), each = 3), "_", rep(c("below", "at", "above"), 2), "_threshold_records")),
    icd_audit = c("target_records", "unavailable_domain", "unavailable_field"))
  loaded$source_audit <- list()
  for (name in names(allowed_audits)) {
    values <- fields[[name]]
    if (length(setdiff(names(values), allowed_audits[[name]]))) stop("Unexpected source audit fields.")
    for (value in values) if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value < 0 || value != round(value)) stop("Invalid aggregate source audit count.")
    loaded$source_audit[[name]] <- values
  }
  loaded
}

common_outcome_field <- function(outcome, window) {
  if (window == "encounter") outcome else paste0(outcome, "_index_calendar_day")
}

fit_common_model <- function(data, field, model_id, source_status = "qualified") {
  row <- data.frame(model_id = model_id, source_status = source_status,
    n_training = nrow(data), n_training_events = sum(data[[field]] == 1),
    beta_bmi = NA_real_, se_bmi = NA_real_, odds_ratio = NA_real_,
    status = "not_estimable", reason = "", warnings = "", stringsAsFactors = FALSE)
  fail <- function(reason) { row$reason <- reason; list(row = row, fit = NULL, data = data) }
  if (source_status == "pending") {
    row$n_training <- row$n_training_events <- NA_integer_
    row$status <- "awaiting_source_evidence"
    return(fail("Calendar-day source evidence pending"))
  }
  if (!nrow(data)) return(fail("No observed complete model cases"))
  if (length(unique(data[[field]])) != 2L) return(fail("Outcome has no variation"))
  if (length(unique(data$bmi)) < 2L) return(fail("BMI has no variation"))
  data$.outcome <- data[[field]]
  matrix <- tryCatch(stats::model.matrix(common_formula, data), error = function(e) e)
  if (inherits(matrix, "error")) return(fail(conditionMessage(matrix)))
  if (qr(matrix)$rank < ncol(matrix) || nrow(matrix) <= ncol(matrix)) return(fail("Rank deficient or undersized model"))
  separation <- tryCatch(detect_tri_separation(matrix, data$.outcome), error = function(e) e)
  if (inherits(separation, "error")) return(fail(conditionMessage(separation)))
  if (separation) return(fail("Complete or quasi-complete separation"))
  warning_log <- new.env(parent = emptyenv())
  warning_log$messages <- character()
  fit <- tryCatch(withCallingHandlers(stats::glm(common_formula, data = data, family = stats::binomial()),
    warning = function(w) { warning_log$messages <- c(warning_log$messages, conditionMessage(w)); invokeRestart("muffleWarning") }), error = function(e) e)
  warnings <- warning_log$messages
  row$warnings <- paste(unique(warnings), collapse = " | ")
  if (inherits(fit, "error")) return(fail(conditionMessage(fit)))
  if (!isTRUE(fit$converged) || isTRUE(fit$boundary) || length(warnings)) return(fail("GLM convergence/boundary warning; review required"))
  b <- stats::coef(summary(fit))["bmi", ]
  if (!all(is.finite(c(b[1:2], exp(b[1])))) || b[2] <= 0) return(fail("Invalid BMI coefficient/covariance"))
  row$beta_bmi <- b[1]; row$se_bmi <- b[2]; row$odds_ratio <- exp(b[1]); row$status <- "estimated"
  list(row = row, fit = fit, data = data)
}

# Exposed for independent numerical-gradient checks. Observation membership is
# empirical and held fixed; no observation model or fitted weights enter here.
common_probability <- function(matrix, coefficients, bmi, observed, delta0 = 0, delta1 = 0) {
  offset <- ifelse(observed, 0, delta0 + delta1 * (bmi - 40) / 5)
  q <- stats::plogis(drop(matrix %*% coefficients) + offset)
  list(probability = mean(q), gradient = colMeans(matrix * (q * (1 - q))))
}

common_standardize <- function(model, reference, observed, method, r = 1, g = 1) {
  result <- list(p_observed = NA_real_, p_counterfactual = NA_real_, absolute_difference = NA_real_,
    absolute_conf_low = NA_real_, absolute_conf_high = NA_real_,
    difference_per1000 = NA_real_, difference_low_per1000 = NA_real_, difference_high_per1000 = NA_real_,
    impact_fraction = NA_real_, impact_conf_low = NA_real_, impact_conf_high = NA_real_,
    n_observed_bmi_outside_support = NA_integer_, n_shifted_bmi_outside_support = NA_integer_,
    n_unseen_categories = NA_integer_, status = model$row$status, reason = model$row$reason)
  fail <- function(reason) { result$status <- "not_estimable"; result$reason <- reason; result }
  if (is.null(model$fit)) return(result)
  if (!nrow(reference)) return(fail("Empty reference population"))
  fit <- model$fit
  shifted <- reference
  shifted$bmi <- shift_bmi_above30(reference$bmi)
  bounds <- range(model$data$bmi)
  result$n_observed_bmi_outside_support <- sum(reference$bmi < bounds[1] | reference$bmi > bounds[2])
  result$n_shifted_bmi_outside_support <- sum(shifted$bmi < bounds[1] | shifted$bmi > bounds[2])
  unseen <- rep(FALSE, nrow(reference))
  for (name in c("sex", "race_ethnicity", "location")) unseen <- unseen | !reference[[name]] %in% unique(model$data[[name]])
  result$n_unseen_categories <- sum(unseen)
  if (any(unseen)) return(fail("Unseen categorical level in reference; target not silently restricted"))
  terms <- stats::delete.response(stats::terms(fit))
  matrices <- tryCatch(lapply(list(reference, shifted), function(d) stats::model.matrix(terms, d,
    contrasts.arg = fit$contrasts, xlev = fit$xlevels)), error = function(e) e)
  if (inherits(matrices, "error")) return(fail(conditionMessage(matrices)))
  beta <- stats::coef(fit); covariance <- stats::vcov(fit)
  if (!all(vapply(matrices, function(x) identical(colnames(x), names(beta)), logical(1))) ||
      any(!is.finite(c(beta, covariance)))) return(fail("Invalid paired model matrix/covariance"))
  delta0 <- if (method == "mnar") log(r) else 0
  delta1 <- if (method == "mnar") log(g) else 0
  p0 <- common_probability(matrices[[1]], beta, reference$bmi, observed, delta0, delta1)
  p1 <- common_probability(matrices[[2]], beta, shifted$bmi, observed, delta0, delta1)
  if (any(!is.finite(c(p0$probability, p1$probability))) || p0$probability <= 0 || p1$probability <= 0) return(fail("Invalid paired probabilities"))
  grad_diff <- p0$gradient - p1$gradient
  grad_ratio <- p1$gradient / p1$probability - p0$gradient / p0$probability
  variances <- vapply(list(grad_diff, grad_ratio), function(grad) drop(t(grad) %*% covariance %*% grad), numeric(1))
  if (any(!is.finite(variances)) || any(variances < -1e-12)) return(fail("Invalid delta-method variance"))
  difference <- p0$probability - p1$probability
  diff_ci <- difference + c(-1, 1) * stats::qnorm(.975) * sqrt(max(variances[1], 0))
  impact_ci <- 1 - exp(log(p1$probability / p0$probability) + c(1, -1) * stats::qnorm(.975) * sqrt(max(variances[2], 0)))
  if (any(!is.finite(c(diff_ci, impact_ci)))) return(fail("Nonfinite confidence limits"))
  result[c("p_observed", "p_counterfactual", "absolute_difference", "absolute_conf_low", "absolute_conf_high",
    "difference_per1000", "difference_low_per1000", "difference_high_per1000", "impact_fraction", "impact_conf_low", "impact_conf_high")] <-
    list(p0$probability, p1$probability, difference, diff_ci[1], diff_ci[2],
      1000 * difference, 1000 * diff_ci[1], 1000 * diff_ci[2], 1 - p1$probability / p0$probability, impact_ci[1], impact_ci[2])
  result$status <- "estimated"; result$reason <- ""
  result
}

common_observation_audit <- function(reference, window, source_status) {
  empty <- data.frame(window = window, evidence_pattern = "awaiting_source_evidence",
    abg_testing = "unassessed", vbg_testing = "unassessed", n = NA_integer_,
    n_abg_positive = NA_integer_, n_combined_positive = NA_integer_)
  if (source_status == "pending") return(empty)
  abg <- reference[[common_outcome_field("abg", window)]]
  combined <- reference[[common_outcome_field("any_gas", window)]]
  a <- !is.na(abg)
  v <- !is.na(reference[[if (window == "encounter") "vbg_pco2" else "vbg_pco2_index_day"]])
  pattern <- ifelse(a & v, "both_usable", ifelse(a, "abg_only_usable", ifelse(v, "vbg_only_usable", "no_usable_gas")))
  testing <- function(x) ifelse(is.na(x), "testing_unknown", ifelse(x == 1, "confirmed_testing", "no_captured_testing_evidence"))
  key <- data.frame(evidence_pattern = pattern, abg_testing = testing(reference$has_abg), vbg_testing = testing(reference$has_vbg))
  groups <- split(seq_len(nrow(reference)), interaction(key, drop = TRUE))
  if (!length(groups)) { empty$evidence_pattern <- "empty_reference"; empty$n <- empty$n_abg_positive <- empty$n_combined_positive <- 0L; return(empty) }
  do.call(rbind, lapply(groups, function(rows) data.frame(window = window, key[rows[1], , drop = FALSE],
    n = length(rows), n_abg_positive = sum(abg[rows] == 1, na.rm = TRUE), n_combined_positive = sum(combined[rows] == 1, na.rm = TRUE))))
}

run_common_index <- function(input) {
  data <- derive_triangulation_variables(validate_triangulation_input(input))
  data$common_obesity <- data$bmi >= 30
  selected <- select_frame_indexes(data, "common_obesity")
  indexes <- selected$indexes
  reference <- indexes[complete.cases(indexes[triangulation_adjustment]), , drop = FALSE]
  source_day <- attr(data, "index_day_source_status")
  registry <- common_registry(); models <- list(); matched <- list()
  for (window in common_windows) for (outcome in c("abg", "any_gas")) {
    field <- common_outcome_field(outcome, window)
    train <- reference[!is.na(reference[[field]]), , drop = FALSE]
    id <- paste(outcome, window, sep = "/")
    models[[id]] <- fit_common_model(train, field, id, if (window == "encounter") "qualified" else source_day)
  }
  for (pair in c("abg", "any_gas")) {
    matched[[pair]] <- reference[!is.na(reference[[pair]]) & !is.na(reference$icd), , drop = FALSE]
    for (outcome in c("icd", pair)) {
      id <- paste0("matched_", pair, "/", outcome)
      models[[id]] <- fit_common_model(matched[[pair]], outcome, id)
    }
  }
  results <- lapply(seq_len(nrow(registry)), function(i) {
    row <- registry[i, , drop = FALSE]; model <- models[[row$model_id]]
    field <- common_outcome_field(row$outcome, row$window)
    target <- switch(row$target_id, bmi_ge30 = reference, bmi_ge40 = reference[reference$bmi >= 40, , drop = FALSE],
      matched_abg = matched$abg, matched_any_gas = matched$any_gas)
    observed <- !is.na(target[[field]])
    prediction_reference <- if (row$method == "observed") target[observed, , drop = FALSE] else target
    prediction_observed <- if (row$method == "observed") rep(TRUE, nrow(prediction_reference)) else observed
    pending <- model$row$source_status == "pending"
    estimates <- common_standardize(model, prediction_reference, prediction_observed, row$method, row$r, row$g)
    counts <- data.frame(n_target = nrow(target), n_reference = if (pending) NA_integer_ else nrow(prediction_reference),
      n_reference_observed = if (pending) NA_integer_ else sum(prediction_observed),
      n_reference_unobserved = if (pending) NA_integer_ else sum(!prediction_observed),
      n_training = model$row$n_training, n_training_events = model$row$n_training_events,
      n_shifted = if (pending) NA_integer_ else sum(prediction_reference$bmi > 30),
      pct_shifted = if (pending || !nrow(prediction_reference)) NA_real_ else 100 * mean(prediction_reference$bmi > 30),
      n_index_day_conflicts = if (pending) NA_integer_ else if (row$window == "encounter") 0L else sum(target$.index_day_conflict),
      source_status = model$row$source_status, study_design = common_design_id, scenario_id = triangulation_scenario_id)
    cbind(row, counts, as.data.frame(estimates, stringsAsFactors = FALSE))
  })
  population <- selected$counts
  population$n_missing_adjustment <- nrow(indexes) - nrow(reference)
  population$n_reference <- nrow(reference)
  population$n_reference_ge40 <- sum(reference$bmi >= 40)
  population$n_known_icd <- sum(!is.na(reference$icd))
  population$n_matched_abg <- nrow(matched$abg)
  population$n_matched_any_gas <- nrow(matched$any_gas)
  observation <- do.call(rbind, lapply(common_windows, function(w) common_observation_audit(reference, w,
    if (w == "encounter") "qualified" else source_day)))
  bins <- list(); shapes <- list(); coverage <- list()
  for (window in common_windows) for (outcome in c("abg", "any_gas")) {
    field <- common_outcome_field(outcome, window)
    known <- !is.na(reference[[field]])
    for (variable in c("sex", "race_ethnicity", "location", "age_decade")) {
      category <- if (variable == "age_decade") paste0(10 * floor(reference$age_at_encounter / 10), "–", 10 * floor(reference$age_at_encounter / 10) + 9) else reference[[variable]]
      for (rows in split(seq_len(nrow(reference)), category)) {
        pending <- window == "index_calendar_day" && source_day == "pending"
        coverage[[length(coverage) + 1L]] <- data.frame(window = window, outcome = outcome,
          variable = variable, category = category[rows[1]], n_target = length(rows),
          n_observed = if (pending) NA_integer_ else sum(known[rows]),
          n_positive = if (pending) NA_integer_ else sum(reference[[field]][rows] == 1, na.rm = TRUE),
          source_status = if (pending) "pending" else "qualified")
      }
    }
    groups <- split(seq_len(nrow(reference)), 5 * floor(reference$bmi / 5))
    if (window == "index_calendar_day" && source_day == "pending") {
      bins[[length(bins) + 1L]] <- data.frame(window = window, outcome = outcome, bin_low = NA_real_,
        n_target = NA_integer_, n_observed = NA_integer_, n_positive = NA_integer_, observation_fraction = NA_real_, positivity = NA_real_, source_status = "pending")
    } else for (rows in groups) bins[[length(bins) + 1L]] <- data.frame(window = window, outcome = outcome,
      bin_low = 5 * floor(reference$bmi[rows[1]] / 5), n_target = length(rows), n_observed = sum(known[rows]),
      n_positive = sum(reference[[field]][rows] == 1, na.rm = TRUE), observation_fraction = mean(known[rows]),
      positivity = if (any(known[rows])) mean(reference[[field]][rows[known[rows]]]) else NA_real_, source_status = "qualified")
  }
  for (id in names(models)) if (!is.null(models[[id]]$fit)) shapes[[length(shapes) + 1L]] <- tri_bmi_diagnostics(models[[id]]$data, models[[id]]$fit, id)
  shape_empty <- tri_bmi_diagnostics(data.frame(), NULL, "empty")
  # Everything returned below is aggregate-only. Models, indexes and individual
  # predictions remain local to this function and are never persisted.
  list(results = do.call(rbind, results), registry = registry, population = population,
    models = do.call(rbind, lapply(models, function(m) m$row)), observation = observation,
    observation_bmi = if (length(bins)) do.call(rbind, bins) else data.frame(window = character(), outcome = character(), bin_low = numeric(), n_target = integer(), n_observed = integer(), n_positive = integer(), observation_fraction = numeric(), positivity = numeric(), source_status = character()),
    covariate_coverage = if (length(coverage)) do.call(rbind, coverage) else data.frame(window = character(), outcome = character(), variable = character(), category = character(), n_target = integer(), n_observed = integer(), n_positive = integer(), source_status = character()),
    bmi_diagnostics = if (length(shapes)) do.call(rbind, shapes) else shape_empty,
    timing_audit = tri_timing_audit(indexes, "common_obesity", source_day),
    scope = data.frame(input_encounters = nrow(input), exact_duplicates_removed = attr(data, "exact_duplicates_removed"),
      distinct_encounter_versions = nrow(data), n_conflicting_keys = attr(data, "n_conflicting_keys"),
      in_scope = sum(data$in_scope %in% TRUE), out_of_scope = sum(data$in_scope %in% FALSE), uncertain_scope = sum(is.na(data$in_scope))))
}
