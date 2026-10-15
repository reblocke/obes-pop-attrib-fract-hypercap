# Primary patient-level association workflow. No input is read on sourcing.
triangulation_columns <- c(
  "patient_id", "encounter_id", "encounter_date", "age_at_encounter",
  "encounter_type", "bmi", "sex", "race_ethnicity", "location",
  "has_abg", "has_vbg", "abg_pco2", "vbg_pco2", "icd_hypercapnia"
)
triangulation_frames <- c(
  severe_obesity = "BMI >=40", abg_drawn = "ABG obtained",
  any_gas_drawn = "Either gas obtained"
)
triangulation_outcomes <- c(
  icd = "ICD composite", abg = "ABG >=45", any_gas = "ABG >=45 or VBG >=50"
)
triangulation_adjustment <- c("bmi", "age_at_encounter", "sex", "race_ethnicity", "location")
triangulation_index_day_columns <- c(
  "abg_pco2_index_day", "vbg_pco2_index_day",
  "abg_index_day_available", "vbg_index_day_available"
)
triangulation_counterfactual <- "BMI >30 reduced by 1 kg/m2; BMI <=30 unchanged; no floor"
triangulation_scenario_id <- "bmi_gt30_minus1_v1"

triangulation_registry <- function() {
  within_frame <- data.frame(
    outcome = c("icd", "abg", "abg", "any_gas", "any_gas"),
    ascertainment_window = c("encounter", "encounter", "index_calendar_day", "encounter", "index_calendar_day"),
    analysis_role = c("primary", "primary", "sensitivity", "primary", "sensitivity"),
    stringsAsFactors = FALSE
  )
  registry <- do.call(rbind, lapply(names(triangulation_frames), function(frame) {
    data.frame(frame = frame, within_frame, stringsAsFactors = FALSE)
  }))
  registry$cell_id <- with(registry, paste(frame, outcome, ascertainment_window, sep = "/"))
  registry$display_order <- seq_len(nrow(registry))
  rownames(registry) <- NULL
  registry
}

tri_encounter_key <- function(data) paste(nchar(data$patient_id), data$patient_id, data$encounter_id, sep = ":")

shift_bmi_above30 <- function(bmi) ifelse(bmi > 30, bmi - 1, bmi)

require_tri_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Missing packages (not installed automatically): ", paste(missing, collapse = ", "))
}

validate_triangulation_input <- function(data) {
  if (!is.data.frame(data)) stop("Input must be a data frame.")
  missing <- setdiff(triangulation_columns, names(data))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))
  day_present <- triangulation_index_day_columns %in% names(data)
  if (any(day_present) && !all(day_present)) stop("Incomplete index-calendar-day columns.")
  day <- if (all(day_present)) data[c("patient_id", "encounter_id", triangulation_index_day_columns)] else NULL
  data <- as.data.frame(data[triangulation_columns])
  for (name in c("patient_id", "encounter_id")) {
    if (!is.character(data[[name]]) || anyNA(data[[name]]) || any(!nzchar(trimws(data[[name]])))) {
      stop(name, " must contain verified, nonmissing character keys; no row-number fallback.")
    }
  }
  if (!inherits(data$encounter_date, "Date")) stop("encounter_date must be Date, with a reviewed source origin.")
  for (name in c("age_at_encounter", "bmi", "abg_pco2", "vbg_pco2")) {
    x <- data[[name]]
    if (!is.numeric(x) || is.factor(x) || any(!is.finite(x) & !is.na(x))) stop(name, " must be finite numeric or NA.")
  }
  for (name in c("bmi", "abg_pco2", "vbg_pco2")) {
    if (any(data[[name]] <= 0, na.rm = TRUE)) stop(name, " has nonpositive values; review units/source rather than exclude silently.")
  }
  for (name in c("has_abg", "has_vbg", "icd_hypercapnia")) {
    x <- data[[name]]
    if (!(is.numeric(x) || is.logical(x)) || is.factor(x) || any(!is.na(x) & !x %in% c(0, 1))) {
      stop(name, " must be explicitly mapped to 0/1/NA; factor level numbers are not codes.")
    }
  }
  for (name in c("encounter_type", "sex", "race_ethnicity", "location")) {
    if (!(is.character(data[[name]]) || is.factor(data[[name]]))) stop(name, " must have reviewed character/factor categories.")
    data[[name]] <- as.character(data[[name]])
    data[[name]][!is.na(data[[name]]) & !nzchar(trimws(data[[name]]))] <- NA_character_
  }
  for (gas in c("abg", "vbg")) {
    available <- !is.na(data[[paste0(gas, "_pco2")]])
    if (any(available & !(data[[paste0("has_", gas)]] %in% 1))) {
      stop(gas, " result exists without a confirmed draw flag; resolve the source mapping.")
    }
    if (!is.null(day)) {
      value <- day[[paste0(gas, "_pco2_index_day")]]
      availability <- day[[paste0(gas, "_index_day_available")]]
      if (!is.numeric(value) || is.factor(value) || any(!is.na(value) & (!is.finite(value) | value <= 0))) {
        stop(gas, " index-day result must be positive finite numeric or NA.")
      }
      if (!(is.numeric(availability) || is.logical(availability)) || is.factor(availability) ||
          any(!is.na(availability) & !availability %in% c(0, 1))) stop("Index-day availability must be 0/1/NA.")
      if (any((availability %in% 1) != !is.na(value))) stop("Index-day availability and maximum disagree.")
      if (any(!is.na(value) & (!available | !(data[[paste0("has_", gas)]] %in% 1)))) {
        stop("Index-day gas requires an encounter result and confirmed draw.")
      }
      if (any(value > data[[paste0(gas, "_pco2")]] + 1e-8, na.rm = TRUE)) stop("Index-day maximum exceeds encounter maximum.")
    }
  }
  n_input <- nrow(data)
  data <- unique(data)
  keys <- data[c("patient_id", "encounter_id")]
  data$.key_conflict <- duplicated(keys) | duplicated(keys, fromLast = TRUE)
  # Deduplication/index ambiguity use primary fields only. Discordant early
  # evidence cannot alter a primary index or promote another encounter.
  data$.index_day_conflict <- FALSE
  if (!is.null(day)) {
    day <- unique(day)
    day_keys <- tri_encounter_key(day)
    conflict <- duplicated(day_keys) | duplicated(day_keys, fromLast = TRUE)
    position <- match(tri_encounter_key(data), day_keys)
    data$.index_day_conflict <- day_keys[position] %in% day_keys[conflict]
    for (name in triangulation_index_day_columns) {
      data[[name]] <- day[[name]][position]
      data[[name]][data$.index_day_conflict] <- NA
    }
  } else {
    for (name in triangulation_index_day_columns) data[[name]] <- rep(NA_real_, nrow(data))
  }
  attr(data, "exact_duplicates_removed") <- n_input - nrow(data)
  attr(data, "n_conflicting_keys") <- nrow(unique(keys[data$.key_conflict, , drop = FALSE]))
  attr(data, "index_day_source_status") <- if (is.null(day)) "pending" else "qualified"
  data
}

derive_triangulation_variables <- function(data) {
  setting <- ifelse(is.na(data$encounter_type), NA, data$encounter_type %in% c("EMER", "IMP"))
  data$in_scope <- data$age_at_encounter >= 18 & setting &
    data$encounter_date >= as.Date("2022-01-01") & data$encounter_date < as.Date("2023-01-01")
  data$severe_obesity <- data$bmi >= 40
  data$abg_drawn <- data$has_abg == 1
  data$any_gas_drawn <- data$has_abg == 1 | data$has_vbg == 1
  data$icd <- data$icd_hypercapnia
  data$abg <- ifelse(is.na(data$abg_pco2), NA_integer_, as.integer(data$abg_pco2 >= 45))
  has_result <- !is.na(data$abg_pco2) | !is.na(data$vbg_pco2)
  positive <- data$abg_pco2 >= 45 | data$vbg_pco2 >= 50
  data$any_gas <- ifelse(positive %in% TRUE, 1L, ifelse(has_result, 0L, NA_integer_))
  data$abg_index_calendar_day <- ifelse(is.na(data$abg_pco2_index_day), NA_integer_, as.integer(data$abg_pco2_index_day >= 45))
  day_result <- !is.na(data$abg_pco2_index_day) | !is.na(data$vbg_pco2_index_day)
  day_positive <- data$abg_pco2_index_day >= 45 | data$vbg_pco2_index_day >= 50
  data$any_gas_index_calendar_day <- ifelse(day_positive %in% TRUE, 1L, ifelse(day_result, 0L, NA_integer_))
  data
}

select_frame_indexes <- function(data, frame) {
  eligible <- data$in_scope & data[[frame]]
  # Conflicting versions may establish membership by consensus, but never
  # supply a resolved index. Disagreement/unknown eligibility remains unknown.
  conflict_rows <- which(data$.key_conflict)
  key <- paste(nchar(data$patient_id), data$patient_id, data$encounter_id, sep = ":")
  for (rows in split(conflict_rows, key[conflict_rows])) {
    states <- eligible[rows]
    eligible[rows] <- if (all(states %in% TRUE)) TRUE else if (all(states %in% FALSE)) FALSE else NA
  }
  confirmed <- data[eligible %in% TRUE, , drop = FALSE]
  possible <- data[is.na(eligible), , drop = FALSE]
  groups <- split(seq_len(nrow(confirmed)), confirmed$patient_id)
  possible_groups <- split(possible$encounter_date, possible$patient_id)
  patient_ids <- names(groups)
  possible_positions <- match(patient_ids, names(possible_groups))
  audits <- lapply(seq_along(groups), function(group_index) {
    id <- patient_ids[group_index]
    rows <- groups[[group_index]]
    first_date <- min(confirmed$encounter_date[rows])
    earliest <- rows[confirmed$encounter_date[rows] == first_date]
    possible_index <- possible_positions[group_index]
    uncertain_dates <- if (is.na(possible_index)) NULL else possible_groups[[possible_index]]
    earlier_uncertainty <- length(uncertain_dates) && any(is.na(uncertain_dates) | uncertain_dates <= first_date)
    status <- if (earlier_uncertainty) "uncertain_earlier_membership" else if (any(confirmed$.key_conflict[earliest])) "conflicting_index_evidence" else if (length(earliest) > 1L) "earliest_date_tie" else "resolved"
    data.frame(patient_id = id, frame = frame, index_date = first_date, status = status,
               selected_row = if (status == "resolved") earliest else NA_integer_)
  })
  # Index audits contain identifiers: keep in memory, never export from the report.
  audit <- if (length(audits)) do.call(rbind, audits) else data.frame(
    patient_id = character(), frame = character(), index_date = as.Date(character()), status = character(), selected_row = integer())
  selected <- audit$selected_row[!is.na(audit$selected_row)]
  indexes <- confirmed[selected, , drop = FALSE]
  rownames(indexes) <- NULL
  counts <- data.frame(
    frame = frame, n_frame_patients = length(groups), n_index_resolved = nrow(indexes),
    n_index_unresolved = sum(audit$status != "resolved"),
    n_membership_uncertain = length(setdiff(unique(possible$patient_id), names(groups))),
    n_earliest_ties = sum(audit$status == "earliest_date_tie"),
    n_earlier_uncertainty = sum(audit$status == "uncertain_earlier_membership"),
    n_conflicting_indexes = sum(audit$status == "conflicting_index_evidence")
  )
  list(indexes = indexes, audit = audit, counts = counts)
}

detect_tri_separation <- function(x, y) {
  # A separating direction has signed X*b >= 0, with at least one strict
  # inequality. An L1 bound makes the linear program finite; split b into
  # nonnegative positive/negative parts. This detects complete AND quasi separation.
  require_tri_packages("lpSolve")
  scale <- apply(abs(x), 2L, max)
  scale[scale == 0] <- 1
  z <- sweep(x, 2L, scale, "/") * (2 * y - 1)
  z <- unique(z)
  a <- cbind(z, -z)
  solution <- lpSolve::lp("max", colSums(a), rbind(a, rep(1, ncol(a))),
                          c(rep(">=", nrow(a)), "<="), c(rep(0, nrow(a)), 1))
  if (solution$status != 0) stop("Separation diagnostic could not be solved.")
  solution$objval > 1e-7
}

standardize_bmi_shift <- function(fit, model_data) {
  # Standardize both scenarios to the SAME observed model cases. Do not
  # re-select indexes, frames, or outcomes after changing BMI.
  counterfactual <- model_data
  counterfactual$bmi <- shift_bmi_above30(model_data$bmi)
  support <- range(model_data$bmi)
  result <- list(
    p_observed = NA_real_, p_counterfactual = NA_real_, absolute_difference = NA_real_,
    impact_fraction = NA_real_, impact_conf_low = NA_real_, impact_conf_high = NA_real_,
    se_log_probability_ratio = NA_real_, n_bmi_shifted = sum(model_data$bmi > 30),
    n_counterfactual_outside_support = sum(counterfactual$bmi < support[1] | counterfactual$bmi > support[2]),
    impact_status = "not_estimable", impact_reason = ""
  )
  fail <- function(reason) { result$impact_reason <- reason; result }
  predictions <- tryCatch(list(
    observed = stats::predict(fit, newdata = model_data, type = "response"),
    counterfactual = stats::predict(fit, newdata = counterfactual, type = "response")
  ), error = function(e) e)
  if (inherits(predictions, "error")) return(fail(paste("Prediction:", conditionMessage(predictions))))
  if (!nrow(model_data) || any(lengths(predictions) != nrow(model_data)) ||
      any(!is.finite(unlist(predictions))) || any(unlist(predictions) < 0 | unlist(predictions) > 1)) {
    return(fail("Invalid paired standardization predictions"))
  }
  p0 <- mean(predictions$observed)
  p1 <- mean(predictions$counterfactual)
  if (p0 <= 0 || p1 <= 0) return(fail("Nonpositive standardized probability"))
  terms <- stats::delete.response(stats::terms(fit))
  matrices <- tryCatch(list(
    observed = stats::model.matrix(terms, model_data, contrasts.arg = fit$contrasts, xlev = fit$xlevels),
    counterfactual = stats::model.matrix(terms, counterfactual, contrasts.arg = fit$contrasts, xlev = fit$xlevels)
  ), error = function(e) e)
  if (inherits(matrices, "error")) return(fail(paste("Standardization matrix:", conditionMessage(matrices))))
  coefficient_names <- names(stats::coef(fit))
  if (!all(vapply(matrices, function(x) identical(colnames(x), coefficient_names), logical(1)))) {
    return(fail("Prediction matrix does not match fitted coefficients"))
  }
  # Delta method on log(mean(p_counterfactual) / mean(p_observed)). The
  # empirical patient/covariate distribution is held fixed in this interval.
  gradient0 <- colMeans(matrices$observed * (predictions$observed * (1 - predictions$observed)))
  gradient1 <- colMeans(matrices$counterfactual * (predictions$counterfactual * (1 - predictions$counterfactual)))
  gradient <- gradient1 / p1 - gradient0 / p0
  covariance <- stats::vcov(fit)
  if (any(!is.finite(c(gradient, covariance)))) return(fail("Nonfinite standardization gradient/covariance"))
  variance <- drop(t(gradient) %*% covariance %*% gradient)
  if (!is.finite(variance) || variance < -1e-12) return(fail("Invalid standardization variance"))
  se <- sqrt(max(variance, 0))
  log_ratio <- log(p1) - log(p0)
  interval <- 1 - exp(log_ratio + c(1, -1) * stats::qnorm(.975) * se)
  if (any(!is.finite(interval))) return(fail("Nonfinite impact-fraction interval"))
  result[c("p_observed", "p_counterfactual", "absolute_difference", "impact_fraction",
           "impact_conf_low", "impact_conf_high", "se_log_probability_ratio")] <-
    list(p0, p1, p0 - p1, 1 - p1 / p0, interval[1], interval[2], se)
  result$impact_status <- "estimated"
  if (!result$n_bmi_shifted) result$impact_reason <- "No BMI above 30: observed and counterfactual scenarios are identical"
  result
}

fit_triangulation_cell <- function(indexes, frame, outcome, ascertainment_window = "encounter", source_status = "qualified") {
  outcome_field <- if (ascertainment_window == "encounter") outcome else paste0(outcome, "_index_calendar_day")
  observed <- !is.na(indexes[[outcome_field]])
  complete <- complete.cases(indexes[triangulation_adjustment])
  model_data <- indexes[observed & complete, , drop = FALSE]
  result <- data.frame(
    frame = frame, outcome = outcome, ascertainment_window = ascertainment_window,
    analysis_role = if (ascertainment_window == "encounter") "primary" else "sensitivity",
    cell_id = paste(frame, outcome, ascertainment_window, sep = "/"), source_status = source_status,
    n_index_resolved = nrow(indexes),
    n_outcome_known = sum(observed), n_outcome_missing = sum(!observed),
    n_missing_adjustment = sum(observed & !complete), n_model = nrow(model_data),
    n_events = sum(model_data[[outcome_field]] == 1), beta = NA_real_, se = NA_real_,
    odds_ratio = NA_real_, conf_low = NA_real_, conf_high = NA_real_,
    status = "not_estimable", reason = "", warnings = "",
    p_observed = NA_real_, p_counterfactual = NA_real_, absolute_difference = NA_real_,
    impact_fraction = NA_real_, impact_conf_low = NA_real_, impact_conf_high = NA_real_,
    se_log_probability_ratio = NA_real_, n_bmi_shifted = sum(model_data$bmi > 30),
    pct_bmi_shifted = if (nrow(model_data)) 100 * mean(model_data$bmi > 30) else NA_real_,
    n_index_day_conflicts = if (ascertainment_window == "encounter") 0L else sum(indexes$.index_day_conflict),
    n_counterfactual_outside_support = NA_integer_,
    impact_status = "not_estimable", impact_reason = "Model not estimated",
    counterfactual = triangulation_counterfactual, scenario_id = triangulation_scenario_id, stringsAsFactors = FALSE
  )
  if (source_status == "pending") {
    result[c("n_outcome_known", "n_outcome_missing", "n_missing_adjustment", "n_model", "n_events", "n_bmi_shifted", "pct_bmi_shifted", "n_index_day_conflicts")] <- NA_real_
    result$status <- result$impact_status <- "awaiting_source_evidence"
    result$reason <- result$impact_reason <- "Authenticated index-calendar-day source evidence unavailable"
    return(result)
  }
  fail <- function(reason) { result$reason <- reason; result$impact_reason <- reason; result }
  if (!nrow(model_data)) return(fail("No complete model cases"))
  if (length(unique(model_data[[outcome_field]])) != 2L) return(fail("Outcome has no variation"))
  if (length(unique(model_data$bmi)) < 2L) return(fail("BMI has no variation"))
  model_data$.outcome <- model_data[[outcome_field]]
  formula <- .outcome ~ bmi + age_at_encounter + factor(sex) + factor(race_ethnicity) + factor(location)
  matrix <- tryCatch(stats::model.matrix(formula, model_data), error = function(e) e)
  if (inherits(matrix, "error")) return(fail(paste("Model matrix:", conditionMessage(matrix))))
  if (qr(matrix)$rank < ncol(matrix) || nrow(matrix) <= ncol(matrix)) return(fail("Model matrix is rank deficient or undersized"))
  separation <- tryCatch(detect_tri_separation(matrix, model_data$.outcome), error = function(e) e)
  if (inherits(separation, "error")) return(fail(conditionMessage(separation)))
  if (separation) return(fail("Complete or quasi-complete separation"))
  warning_log <- new.env(parent = emptyenv())
  warning_log$messages <- character()
  fit <- tryCatch(withCallingHandlers(
    stats::glm(formula, data = model_data, family = stats::binomial()),
    warning = function(w) { warning_log$messages <- c(warning_log$messages, conditionMessage(w)); invokeRestart("muffleWarning") }
  ), error = function(e) e)
  warnings <- warning_log$messages
  result$warnings <- paste(unique(warnings), collapse = " | ")
  if (inherits(fit, "error")) return(fail(paste("GLM:", conditionMessage(fit))))
  if (!isTRUE(fit$converged) || isTRUE(fit$boundary) || length(warnings)) return(fail("GLM convergence/boundary warning; review required"))
  coefficients <- stats::coef(summary(fit))
  beta <- coefficients["bmi", "Estimate"]
  se <- coefficients["bmi", "Std. Error"]
  interval <- exp(beta + c(-1, 1) * stats::qnorm(.975) * se)
  if (!all(is.finite(c(beta, se, exp(beta), interval))) || se <= 0 || any(interval <= 0)) return(fail("Nonfinite or invalid estimate/interval"))
  result[c("beta", "se", "odds_ratio", "conf_low", "conf_high")] <- list(beta, se, exp(beta), interval[1], interval[2])
  result$status <- "estimated"
  standardized <- tryCatch(standardize_bmi_shift(fit, model_data), error = function(e) e)
  if (inherits(standardized, "error")) {
    result$impact_reason <- paste("Standardization:", conditionMessage(standardized))
  } else {
    result[names(standardized)] <- standardized
  }
  attr(result, "bmi_diagnostics") <- tri_bmi_diagnostics(model_data, fit, result$cell_id)
  result
}

tri_bmi_diagnostics <- function(model_data, fit, cell_id) {
  empty <- data.frame(cell_id = character(), bin_low = numeric(), bin_high = numeric(),
                      n = integer(), events = integer(), observed_fraction = numeric(), mean_fitted = numeric())
  if (!nrow(model_data)) return(empty)
  bin <- 5 * floor(model_data$bmi / 5)
  prediction <- stats::predict(fit, newdata = model_data, type = "response")
  do.call(rbind, lapply(sort(unique(bin)), function(low) {
    rows <- bin == low
    data.frame(cell_id = cell_id, bin_low = low, bin_high = low + 5,
      n = sum(rows), events = sum(model_data$.outcome[rows]),
      observed_fraction = mean(model_data$.outcome[rows]), mean_fitted = mean(prediction[rows]))
  }))
}

tri_bmi_summary <- function(indexes, result) {
  pending <- result$source_status == "pending"
  field <- if (result$ascertainment_window == "encounter") result$outcome else paste0(result$outcome, "_index_calendar_day")
  cases <- indexes[!is.na(indexes[[field]]) & complete.cases(indexes[triangulation_adjustment]), , drop = FALSE]
  quantiles <- if (nrow(cases) && !pending) unname(stats::quantile(cases$bmi, c(0, .25, .5, .75, 1))) else rep(NA_real_, 5)
  data.frame(cell_id = result$cell_id, n = if (pending) NA_integer_ else nrow(cases),
    minimum = quantiles[1], q25 = quantiles[2], median = quantiles[3], q75 = quantiles[4], maximum = quantiles[5],
    n_below30 = if (pending) NA_integer_ else sum(cases$bmi < 30),
    n_at30 = if (pending) NA_integer_ else sum(cases$bmi == 30),
    n_above30 = if (pending) NA_integer_ else sum(cases$bmi > 30),
    n_near40 = if (pending) NA_integer_ else sum(cases$bmi >= 39 & cases$bmi < 41),
    n_at_least50 = if (pending) NA_integer_ else sum(cases$bmi >= 50))
}

tri_timing_audit <- function(indexes, frame, source_status) {
  do.call(rbind, lapply(c("abg", "any_gas"), function(outcome) {
    if (source_status == "pending") return(data.frame(frame = frame, outcome = outcome,
      primary_state = "not_assessed", index_day_state = "awaiting_source_evidence", n = NA_integer_))
    state <- function(x) factor(ifelse(is.na(x), "unknown", ifelse(x == 1, "positive", "available_negative")),
      levels = c("positive", "available_negative", "unknown"))
    counts <- as.data.frame(table(primary_state = state(indexes[[outcome]]),
      index_day_state = state(indexes[[paste0(outcome, "_index_calendar_day")]])))
    names(counts)[3] <- "n"
    data.frame(frame = frame, outcome = outcome, counts, stringsAsFactors = FALSE)
  }))
}

run_triangulation <- function(data) {
  clean <- validate_triangulation_input(data)
  duplicates <- attr(clean, "exact_duplicates_removed")
  conflicts <- attr(clean, "n_conflicting_keys")
  day_status <- attr(clean, "index_day_source_status")
  derived <- derive_triangulation_variables(clean)
  frames <- lapply(names(triangulation_frames), function(frame) select_frame_indexes(derived, frame))
  names(frames) <- names(triangulation_frames)
  registry <- triangulation_registry()
  cells <- lapply(seq_len(nrow(registry)), function(i) {
    spec <- registry[i, ]
    fit_triangulation_cell(frames[[spec$frame]]$indexes, spec$frame, spec$outcome,
      spec$ascertainment_window, if (spec$analysis_role == "primary") "qualified" else day_status)
  })
  diagnostics <- lapply(cells, attr, which = "bmi_diagnostics")
  diagnostics <- diagnostics[!vapply(diagnostics, is.null, logical(1))]
  bmi_diagnostics <- if (length(diagnostics)) do.call(rbind, diagnostics) else tri_bmi_diagnostics(data.frame(), NULL, "")
  bmi_summary <- do.call(rbind, lapply(seq_along(cells), function(i) tri_bmi_summary(frames[[cells[[i]]$frame]]$indexes, cells[[i]])))
  results <- do.call(rbind, lapply(cells, function(x) { attr(x, "bmi_diagnostics") <- NULL; x }))
  frame_counts <- do.call(rbind, lapply(frames, `[[`, "counts"))
  rownames(results) <- rownames(frame_counts) <- NULL
  stopifnot(nrow(results) == 15L, !anyDuplicated(results$cell_id))
  results <- merge(results, frame_counts[setdiff(names(frame_counts), "n_index_resolved")], by = "frame", sort = FALSE)
  results <- results[match(registry$cell_id, results$cell_id), ]
  rownames(results) <- NULL
  available <- results$source_status == "qualified"
  stopifnot(all(results$n_frame_patients == results$n_index_resolved + results$n_index_unresolved),
            all(results$n_index_resolved[available] == results$n_outcome_known[available] + results$n_outcome_missing[available]),
            all(results$n_outcome_known[available] == results$n_model[available] + results$n_missing_adjustment[available]))
  list(results = results, registry = registry, frame_counts = frame_counts,
    timing_audit = do.call(rbind, lapply(names(frames), function(frame) tri_timing_audit(frames[[frame]]$indexes, frame, day_status))),
    bmi_diagnostics = bmi_diagnostics, bmi_summary = bmi_summary, scope = data.frame(
    input_encounters = nrow(data), exact_duplicates_removed = duplicates,
    distinct_encounter_versions = nrow(clean), n_conflicting_keys = conflicts,
    in_scope = sum(derived$in_scope %in% TRUE),
    out_of_scope = sum(derived$in_scope %in% FALSE), uncertain_scope = sum(is.na(derived$in_scope))
  ))
}

load_triangulation_input <- function(input_path, manifest_path, schema_version = 2L, study_design = NULL) {
  require_tri_packages(c("jsonlite", "digest", "haven"))
  if (!nzchar(input_path) || !nzchar(manifest_path)) stop("Clinical mode requires explicit input and reviewed manifest paths.")
  if (!file.exists(input_path) || !file.exists(manifest_path)) stop("Input or manifest does not exist.")
  manifest_hash <- digest::digest(file = manifest_path, algo = "sha256")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  required <- c("schema_version", "input_sha256", "source_identity", "reviewed_by", "reviewed_on", "evidence_reference", "columns", "binary_codes", "encounter_type_codes", "category_values", "semantics", "source_qualification", "source_evidence_files", "index_day")
  if (length(setdiff(required, names(manifest))) || !identical(manifest$schema_version, schema_version)) stop("Invalid manifest schema; estimation requires version ", schema_version, ".")
  if (schema_version == 3L && (!identical(manifest$study_design, study_design) ||
      !identical(manifest$population_policy, "first_2022_adult_ED_inpatient_BMI_ge30_before_gas_and_completeness"))) {
    stop("Manifest does not qualify the common-index BMI >=30 study population.")
  }
  for (name in c("source_identity", "reviewed_by", "reviewed_on", "evidence_reference")) {
    if (!is.character(manifest[[name]]) || length(manifest[[name]]) != 1 || !nzchar(trimws(manifest[[name]])) || grepl("pending", manifest[[name]], ignore.case = TRUE)) stop("Manifest review metadata incomplete: ", name)
  }
  expected <- c(
    keys = "original_patient_and_encounter", date = "encounter_start_Date",
    bmi = "legacy_derived_kg_m2", gases = "selected_encounter_max_valid_PCO2_mmHg_specimen_verified",
    draws = "selected_encounter_draw_not_result", icd = "J96.02|J96.12|J96.22|J96.92|E66.2",
    icd_negative = "documented_composite_absent_with_capture", adjustment = "legacy_stata_codes_and_missingness"
  )
  for (name in names(expected)) if (!identical(manifest$semantics[[name]], unname(expected[[name]]))) stop("Unreviewed semantics: ", name)
  gates <- c("lineage", "population_scope", "keys_chronology", "bmi_adjustment", "gas_draws", "gas_units_windows", "icd_capture")
  if (!setequal(names(manifest$source_qualification), gates) ||
      !all(vapply(gates, function(name) identical(manifest$source_qualification[[name]], "accepted"), logical(1)))) {
    stop("Primary source qualification incomplete; authenticate the specific unresolved requirement.")
  }
  evidence <- manifest$source_evidence_files
  if (!all(c("lineage", "population", "fields") %in% names(evidence))) stop("Missing identity-bound source evidence files.")
  for (name in names(evidence)) {
    entry <- evidence[[name]]
    if (!is.character(entry$path) || length(entry$path) != 1L || grepl("PENDING", entry$path, fixed = TRUE) ||
        !is.character(entry$sha256) || length(entry$sha256) != 1L || !grepl("^[a-fA-F0-9]{64}$", entry$sha256)) stop("Invalid source evidence reference: ", name)
    path <- entry$path
    if (!grepl("^(/|[A-Za-z]:)", path)) path <- file.path(dirname(manifest_path), path)
    if (!file.exists(path) || !identical(digest::digest(file = path, algo = "sha256"), tolower(entry$sha256))) stop("Source evidence file hash mismatch: ", name)
  }
  day_status <- manifest$index_day$status
  if (length(day_status) != 1L || !day_status %in% c("pending", "qualified")) stop("Index-day source status must be pending or qualified.")
  if (day_status == "qualified" && (!"index_day" %in% names(evidence) ||
      !identical(manifest$index_day$semantics, "max_valid_specimen_PCO2_on_encounter_start_calendar_date"))) stop("Unreviewed index-calendar-day evidence.")
  if (day_status == "pending" && length(manifest$index_day$columns)) stop("Pending index-day source cannot supply mapped columns.")
  hash <- digest::digest(file = input_path, algo = "sha256")
  if (!identical(hash, tolower(manifest$input_sha256))) stop("Input SHA-256 does not match the reviewed manifest.")
  ext <- tolower(tools::file_ext(input_path))
  raw <- switch(ext, rds = readRDS(input_path), dta = haven::read_dta(input_path), stop("Only explicitly supplied RDS or DTA inputs are supported."))
  mapping <- unlist(manifest$columns, use.names = TRUE)
  if (!setequal(names(mapping), triangulation_columns) || anyDuplicated(mapping) || !all(mapping %in% names(raw))) stop("Incomplete, duplicate, or unavailable source column mapping.")
  data <- as.data.frame(raw[unname(mapping[triangulation_columns])])
  names(data) <- triangulation_columns
  if (day_status == "qualified") {
    day_mapping <- unlist(manifest$index_day$columns, use.names = TRUE)
    if (!setequal(names(day_mapping), triangulation_index_day_columns) || anyDuplicated(day_mapping) ||
        any(day_mapping %in% mapping) || !all(day_mapping %in% names(raw))) stop("Incomplete or duplicate index-day source mapping.")
    data[triangulation_index_day_columns] <- raw[unname(day_mapping[triangulation_index_day_columns])]
  }
  # Decode reviewed values explicitly, never factor-level integers.
  source_values <- function(x) if (inherits(x, "haven_labelled")) as.character(haven::zap_labels(x)) else as.character(x)
  decode <- function(x, codes, name) {
    x <- source_values(x)
    codes <- unlist(codes, use.names = TRUE)
    if (!length(codes) || anyDuplicated(names(codes)) || any(!is.na(x) & !x %in% names(codes))) stop("Unmapped source coding: ", name)
    unname(codes[x])
  }
  for (name in c("has_abg", "has_vbg", "icd_hypercapnia")) {
    codes <- unlist(manifest$binary_codes[[name]], use.names = TRUE)
    if (!length(codes) || any(!codes %in% c("0", "1", "NA"))) stop("Invalid binary mapping for ", name)
    x <- decode(data[[name]], codes, name)
    x[x %in% "NA"] <- NA_character_
    data[[name]] <- as.integer(x)
  }
  if (day_status == "qualified") for (name in c("abg_index_day_available", "vbg_index_day_available")) {
    codes <- unlist(manifest$index_day$binary_codes[[name]], use.names = TRUE)
    if (!length(codes) || any(!codes %in% c("0", "1", "NA"))) stop("Invalid index-day binary mapping.")
    x <- decode(data[[name]], codes, name)
    x[x %in% "NA"] <- NA_character_
    data[[name]] <- as.integer(x)
  }
  setting_codes <- unlist(manifest$encounter_type_codes, use.names = TRUE)
  if (!length(setting_codes) || any(!setting_codes %in% c("EMER", "IMP", "OTHER", "NA"))) stop("Invalid encounter_type_codes target; use EMER/IMP/OTHER/NA.")
  data$encounter_type <- decode(data$encounter_type, setting_codes, "encounter_type")
  data$encounter_type[data$encounter_type == "NA"] <- NA_character_
  for (name in c("sex", "race_ethnicity", "location")) {
    data[[name]] <- source_values(data[[name]])
    allowed <- manifest$category_values[[name]]
    if (!length(allowed) || any(!is.na(data[[name]]) & !data[[name]] %in% allowed)) stop("Unreviewed categories in ", name)
  }
  validate_triangulation_input(data)
  if (!identical(hash, digest::digest(file = input_path, algo = "sha256")) ||
      !identical(manifest_hash, digest::digest(file = manifest_path, algo = "sha256"))) stop("Input or manifest changed during loading.")
  # Preserve exact duplicates until the analysis records their removal count.
  list(data = data, manifest = manifest, input_sha256 = hash, manifest_sha256 = manifest_hash)
}
