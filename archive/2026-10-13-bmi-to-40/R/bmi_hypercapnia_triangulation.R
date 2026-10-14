# Separate patient-level association workflow. No input is read on sourcing.
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

require_tri_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Missing packages (not installed automatically): ", paste(missing, collapse = ", "))
}

validate_triangulation_input <- function(data) {
  if (!is.data.frame(data)) stop("Input must be a data frame.")
  missing <- setdiff(triangulation_columns, names(data))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))
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
  }
  n_input <- nrow(data)
  data <- unique(data)
  keys <- data[c("patient_id", "encounter_id")]
  data$.key_conflict <- duplicated(keys) | duplicated(keys, fromLast = TRUE)
  attr(data, "exact_duplicates_removed") <- n_input - nrow(data)
  attr(data, "n_conflicting_keys") <- nrow(unique(keys[data$.key_conflict, , drop = FALSE]))
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

standardize_bmi40 <- function(fit, model_data) {
  # Standardize both scenarios to the SAME observed model cases. Do not
  # re-select indexes, frames, or outcomes after changing BMI.
  counterfactual <- model_data
  counterfactual$bmi <- pmin(model_data$bmi, 40)
  support <- range(model_data$bmi)
  result <- list(
    p_observed = NA_real_, p_counterfactual = NA_real_, absolute_difference = NA_real_,
    impact_fraction = NA_real_, impact_conf_low = NA_real_, impact_conf_high = NA_real_,
    se_log_probability_ratio = NA_real_, n_bmi_shifted = sum(model_data$bmi > 40),
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
  if (!result$n_bmi_shifted) result$impact_reason <- "No BMI above 40: observed and counterfactual scenarios are identical"
  result
}

fit_triangulation_cell <- function(indexes, frame, outcome) {
  observed <- !is.na(indexes[[outcome]])
  complete <- complete.cases(indexes[triangulation_adjustment])
  model_data <- indexes[observed & complete, , drop = FALSE]
  result <- data.frame(
    frame = frame, outcome = outcome, n_index_resolved = nrow(indexes),
    n_outcome_known = sum(observed), n_outcome_missing = sum(!observed),
    n_missing_adjustment = sum(observed & !complete), n_model = nrow(model_data),
    n_events = sum(model_data[[outcome]] == 1), beta = NA_real_, se = NA_real_,
    odds_ratio = NA_real_, conf_low = NA_real_, conf_high = NA_real_,
    status = "not_estimable", reason = "", warnings = "",
    p_observed = NA_real_, p_counterfactual = NA_real_, absolute_difference = NA_real_,
    impact_fraction = NA_real_, impact_conf_low = NA_real_, impact_conf_high = NA_real_,
    se_log_probability_ratio = NA_real_, n_bmi_shifted = sum(model_data$bmi > 40),
    n_counterfactual_outside_support = NA_integer_,
    impact_status = "not_estimable", impact_reason = "Model not estimated",
    counterfactual = "BMI above 40 set to 40; BMI <=40 unchanged", stringsAsFactors = FALSE
  )
  fail <- function(reason) { result$reason <- reason; result$impact_reason <- reason; result }
  if (!nrow(model_data)) return(fail("No complete model cases"))
  if (length(unique(model_data[[outcome]])) != 2L) return(fail("Outcome has no variation"))
  if (length(unique(model_data$bmi)) < 2L) return(fail("BMI has no variation"))
  model_data$.outcome <- model_data[[outcome]]
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
  standardized <- tryCatch(standardize_bmi40(fit, model_data), error = function(e) e)
  if (inherits(standardized, "error")) {
    result$impact_reason <- paste("Standardization:", conditionMessage(standardized))
  } else {
    result[names(standardized)] <- standardized
  }
  result
}

run_triangulation <- function(data) {
  clean <- validate_triangulation_input(data)
  duplicates <- attr(clean, "exact_duplicates_removed")
  conflicts <- attr(clean, "n_conflicting_keys")
  derived <- derive_triangulation_variables(clean)
  frames <- lapply(names(triangulation_frames), function(frame) select_frame_indexes(derived, frame))
  names(frames) <- names(triangulation_frames)
  results <- do.call(rbind, lapply(names(frames), function(frame) {
    do.call(rbind, lapply(names(triangulation_outcomes), function(outcome) {
      fit_triangulation_cell(frames[[frame]]$indexes, frame, outcome)
    }))
  }))
  frame_counts <- do.call(rbind, lapply(frames, `[[`, "counts"))
  rownames(results) <- rownames(frame_counts) <- NULL
  stopifnot(nrow(results) == 9L, !anyDuplicated(results[c("frame", "outcome")]))
  results <- merge(results, frame_counts[setdiff(names(frame_counts), "n_index_resolved")], by = "frame", sort = FALSE)
  results <- results[order(match(results$frame, names(triangulation_frames)), match(results$outcome, names(triangulation_outcomes))), ]
  rownames(results) <- NULL
  stopifnot(all(results$n_frame_patients == results$n_index_resolved + results$n_index_unresolved),
            all(results$n_index_resolved == results$n_outcome_known + results$n_outcome_missing),
            all(results$n_outcome_known == results$n_model + results$n_missing_adjustment))
  list(results = results, frame_counts = frame_counts, scope = data.frame(
    input_encounters = nrow(data), exact_duplicates_removed = duplicates,
    distinct_encounter_versions = nrow(clean), n_conflicting_keys = conflicts,
    in_scope = sum(derived$in_scope %in% TRUE),
    out_of_scope = sum(derived$in_scope %in% FALSE), uncertain_scope = sum(is.na(derived$in_scope))
  ))
}

load_triangulation_input <- function(input_path, manifest_path) {
  require_tri_packages(c("jsonlite", "digest", "haven"))
  if (!nzchar(input_path) || !nzchar(manifest_path)) stop("Clinical mode requires explicit input and reviewed manifest paths.")
  if (!file.exists(input_path) || !file.exists(manifest_path)) stop("Input or manifest does not exist.")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  required <- c("schema_version", "input_sha256", "source_identity", "reviewed_by", "reviewed_on", "evidence_reference", "columns", "binary_codes", "encounter_type_codes", "category_values", "semantics")
  if (length(setdiff(required, names(manifest))) || !identical(manifest$schema_version, 1L)) stop("Invalid manifest schema; use the example template.")
  for (name in c("source_identity", "reviewed_by", "reviewed_on", "evidence_reference")) {
    if (!is.character(manifest[[name]]) || length(manifest[[name]]) != 1 || !nzchar(manifest[[name]]) || grepl("PENDING", manifest[[name]], fixed = TRUE)) stop("Manifest review metadata incomplete: ", name)
  }
  expected <- c(
    keys = "original_patient_and_encounter", date = "encounter_start_Date",
    bmi = "legacy_derived_kg_m2", gases = "selected_encounter_max_valid_PCO2_mmHg_specimen_verified",
    draws = "selected_encounter_draw_not_result", icd = "J96.02|J96.12|J96.22|J96.92|E66.2",
    icd_negative = "documented_composite_absent_with_capture", adjustment = "legacy_stata_codes_and_missingness"
  )
  for (name in names(expected)) if (!identical(manifest$semantics[[name]], unname(expected[[name]]))) stop("Unreviewed semantics: ", name)
  hash <- digest::digest(file = input_path, algo = "sha256")
  if (!identical(hash, tolower(manifest$input_sha256))) stop("Input SHA-256 does not match the reviewed manifest.")
  ext <- tolower(tools::file_ext(input_path))
  raw <- switch(ext, rds = readRDS(input_path), dta = haven::read_dta(input_path), stop("Only explicitly supplied RDS or DTA inputs are supported."))
  mapping <- unlist(manifest$columns, use.names = TRUE)
  if (!setequal(names(mapping), triangulation_columns) || anyDuplicated(mapping) || !all(mapping %in% names(raw))) stop("Incomplete, duplicate, or unavailable source column mapping.")
  data <- as.data.frame(raw[unname(mapping[triangulation_columns])])
  names(data) <- triangulation_columns
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
  # Preserve exact duplicates until the analysis records their removal count.
  list(data = data, manifest = manifest, input_sha256 = hash)
}

plot_triangulation <- function(results, artificial = FALSE) {
  require_tri_packages("ggplot2")
  plot_data <- results
  plot_data$frame_label <- factor(unname(triangulation_frames[plot_data$frame]), levels = unname(triangulation_frames))
  plot_data$outcome_label <- factor(unname(triangulation_outcomes[plot_data$outcome]), levels = rev(unname(triangulation_outcomes)))
  ok <- plot_data$impact_status == "estimated"
  values <- c(0, plot_data$impact_conf_low[ok], plot_data$impact_conf_high[ok])
  width <- max(diff(range(values)), .05)
  lo <- min(values) - .08 * width
  hi <- max(values) + .08 * width
  text_x <- hi + .10 * width
  limit_hi <- hi + 1.8 * width
  plot_data$label <- ifelse(ok,
    sprintf("%.1f%% (%.1f to %.1f)   n=%s", 100 * plot_data$impact_fraction, 100 * plot_data$impact_conf_low, 100 * plot_data$impact_conf_high, format(plot_data$n_model, big.mark = ",", trim = TRUE)),
    paste0("Not estimable   n=", plot_data$n_model))
  ticks <- sort(unique(c(pretty(c(lo, hi), n = 4), 0)))
  ticks <- ticks[ticks >= lo & ticks <= hi]
  ggplot2::ggplot(plot_data, ggplot2::aes(y = outcome_label)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = .45) +
    ggplot2::geom_segment(data = plot_data[ok, ], ggplot2::aes(x = impact_conf_low, xend = impact_conf_high, yend = outcome_label), linewidth = .65, colour = "#184F64") +
    ggplot2::geom_point(data = plot_data[ok, ], ggplot2::aes(x = impact_fraction), size = 2.6, shape = 18, colour = "#184F64") +
    ggplot2::geom_text(ggplot2::aes(x = text_x, label = label), hjust = 0, size = 3.4, colour = "grey15") +
    ggplot2::facet_grid(frame_label ~ ., scales = "fixed") +
    ggplot2::scale_x_continuous(limits = c(lo, limit_hi), breaks = ticks, labels = function(x) paste0(format(100 * x, trim = TRUE, digits = 3), "%")) +
    ggplot2::labs(
      title = if (artificial) "ARTIFICIAL FIXTURE - layout and workflow validation" else "Hypercapnia under the BMI-to-40 scenario",
      subtitle = "BMI above 40 set to 40 kg/m2; points and delta-method 95% intervals",
      x = "Potential impact fraction", y = NULL,
      caption = paste("Rows: ICD composite, arterial CO2 >=45, and arterial >=45 or venous >=50 mm Hg.",
                      "First qualifying 2022 adult ED/inpatient index per frame; overlapping frames.",
                      "Adjustment: age, sex, race/ethnicity, location; same model cases in both scenarios.",
                      "BMI <=40 unchanged. Intervals condition on covariates; no causal prevention claim.", sep = "\n")
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank(),
      strip.text.y = ggplot2::element_text(angle = 0, face = "bold", size = 10),
      plot.title = ggplot2::element_text(face = "bold", size = 13),
      plot.subtitle = ggplot2::element_text(size = 10), plot.caption = ggplot2::element_text(hjust = 0, size = 8.5),
      plot.margin = ggplot2::margin(12, 18, 12, 12), panel.spacing = grid::unit(1, "lines"))
}

export_triangulation_figure <- function(plot, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  base <- file.path(output_dir, "bmi_hypercapnia_forest")
  devices <- list(svg = grDevices::svg, pdf = grDevices::cairo_pdf,
                  png = function(...) grDevices::png(..., units = "in", res = 300, type = "cairo"),
                  jpg = function(...) grDevices::jpeg(..., units = "in", res = 300, quality = 95, type = "cairo"))
  for (ext in names(devices)) ggplot2::ggsave(paste0(base, ".", ext), plot, device = devices[[ext]], width = 9, height = 7, units = "in", bg = "white")
  invisible(base)
}
