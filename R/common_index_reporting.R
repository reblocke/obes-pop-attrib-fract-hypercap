# Version-3 aggregate contract and saved-run display; no input or model fitting.
common_tables <- c(results = "aggregate_results.csv", registry = "specification_registry.csv",
  population = "population_counts.csv", models = "model_diagnostics.csv", observation = "observation_patterns.csv",
  observation_bmi = "observation_by_bmi.csv", bmi_diagnostics = "model_shape_by_bmi.csv",
  covariate_coverage = "covariate_coverage.csv",
  timing_audit = "timing_audit.csv", scope = "scope_counts.csv")
common_quantities <- c("p_observed", "p_counterfactual", "absolute_difference", "absolute_conf_low", "absolute_conf_high",
  "difference_per1000", "difference_low_per1000", "difference_high_per1000", "impact_fraction", "impact_conf_low", "impact_conf_high")

validate_common_aggregates <- function(a) {
  if (!setequal(names(a), names(common_tables)) || !all(vapply(a, is.data.frame, logical(1)))) stop("Unexpected common-index aggregate members.")
  fields <- list(
    results = c(names(common_registry()), "n_target", "n_reference", "n_reference_observed", "n_reference_unobserved",
      "n_training", "n_training_events", "n_shifted", "pct_shifted", "n_index_day_conflicts", "source_status", "study_design", "scenario_id",
      common_quantities, "n_observed_bmi_outside_support", "n_shifted_bmi_outside_support", "n_unseen_categories", "status", "reason"),
    registry = names(common_registry()),
    population = c("frame", "n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_membership_uncertain", "n_earliest_ties",
      "n_earlier_uncertainty", "n_conflicting_indexes", "n_missing_adjustment", "n_reference", "n_reference_ge40", "n_known_icd", "n_matched_abg", "n_matched_any_gas"),
    models = c("model_id", "source_status", "n_training", "n_training_events", "beta_bmi", "se_bmi", "odds_ratio", "status", "reason", "warnings"),
    observation = c("window", "evidence_pattern", "abg_testing", "vbg_testing", "n", "n_abg_positive", "n_combined_positive"),
    observation_bmi = c("window", "outcome", "bin_low", "n_target", "n_observed", "n_positive", "observation_fraction", "positivity", "source_status"),
    covariate_coverage = c("window", "outcome", "variable", "category", "n_target", "n_observed", "n_positive", "source_status"),
    bmi_diagnostics = c("cell_id", "bin_low", "bin_high", "n", "events", "observed_fraction", "mean_fitted"),
    timing_audit = c("frame", "outcome", "primary_state", "index_day_state", "n"),
    scope = c("input_encounters", "exact_duplicates_removed", "distinct_encounter_versions", "n_conflicting_keys", "in_scope", "out_of_scope", "uncertain_scope"))
  for (name in names(fields)) if (!setequal(names(a[[name]]), fields[[name]])) stop("Forbidden or missing aggregate fields: ", name)
  for (table in a) for (name in names(table)) {
    if (is.list(table[[name]]) || inherits(table[[name]], c("Date", "POSIXt"))) stop("Patient/model objects forbidden in aggregates.")
    if (grepl("^n_|^events$|^n$|^input_encounters$|^.*_scope$|^distinct_encounter_versions$|^exact_duplicates_removed$", name)) {
      x <- table[[name]]
      if (!is.numeric(x) || any(!is.na(x) & (!is.finite(x) | x < 0 | x != round(x)))) stop("Invalid aggregate count: ", name)
    }
  }
  registry <- common_registry(); r <- a$results; p <- a$population; m <- a$models
  if (!isTRUE(all.equal(a$registry, registry, check.attributes = FALSE)) || nrow(r) != nrow(registry)) stop("Common-index registry mismatch.")
  for (name in names(registry)) if (!identical(r[[name]], registry[[name]])) stop("Result identity mismatch: ", name)
  if (any(r$study_design != common_design_id | r$scenario_id != triangulation_scenario_id)) stop("Design/scenario mismatch.")
  if (nrow(p) != 1L || p$frame != "common_obesity" || p$n_frame_patients != p$n_index_resolved + p$n_index_unresolved ||
      p$n_index_resolved != p$n_missing_adjustment + p$n_reference || p$n_reference_ge40 > p$n_reference ||
      p$n_known_icd > p$n_reference || p$n_matched_abg > p$n_matched_any_gas || p$n_matched_any_gas > p$n_known_icd) stop("Population reconciliation failed.")
  if (anyDuplicated(m$model_id) || !setequal(m$model_id, unique(registry$model_id)) ||
      any(!m$source_status %in% c("qualified", "pending")) || any(!m$status %in% c("estimated", "not_estimable", "awaiting_source_evidence"))) stop("Invalid model registry/status.")
  pos <- match(r$model_id, m$model_id)
  for (name in c("n_training", "n_training_events", "source_status")) if (!isTRUE(all.equal(r[[name]], m[[name]][pos], check.attributes = FALSE))) stop("Model/result disagreement: ", name)
  for (target in unique(r$target_id)) {
    rows <- r[r$target_id == target, ]
    expected <- switch(target, bmi_ge30 = p$n_reference, bmi_ge40 = p$n_reference_ge40,
      matched_abg = p$n_matched_abg, matched_any_gas = p$n_matched_any_gas)
    if (any(rows$n_target != expected)) stop("Reference target changed between outcomes.")
  }
  pending <- r$source_status == "pending"; available <- !pending; ok <- r$status == "estimated"
  if (any(pending & r$window != "index_calendar_day") || any(r$status[pending] != "awaiting_source_evidence") ||
      any(!is.na(as.matrix(r[pending, c("n_reference", "n_reference_observed", "n_reference_unobserved", "n_training", "n_training_events", "n_shifted", "pct_shifted", "n_index_day_conflicts")])))) stop("Pending evidence cannot become measured counts.")
  if (any(!r$status %in% c("estimated", "not_estimable", "awaiting_source_evidence")) ||
      any(!is.finite(as.matrix(r[ok, common_quantities]))) || any(!is.na(as.matrix(r[!ok, common_quantities])))) stop("Estimate/status inconsistency.")
  if (any(r$n_reference[available] != r$n_reference_observed[available] + r$n_reference_unobserved[available]) ||
      any(r$n_reference[available] > r$n_target[available] | r$n_shifted[available] > r$n_reference[available]) ||
      any(r$n_training_events[available] > r$n_training[available])) stop("Projection denominator reconciliation failed.")
  obs <- available & r$method == "observed"
  if (any(r$n_reference_unobserved[obs] != 0)) stop("Observed benchmark contains unobserved outcomes.")
  full <- available & r$method %in% c("mar", "mnar", "matched")
  if (any(r$n_reference[full] != r$n_target[full])) stop("Full-reference population was silently reduced.")
  fraction <- available & r$n_reference > 0
  if (any(abs(r$pct_shifted[fraction] - 100 * r$n_shifted[fraction] / r$n_reference[fraction]) > 1e-10)) stop("Shift fraction mismatch.")
  if (any(r$p_observed[ok] <= 0 | r$p_observed[ok] > 1 | r$p_counterfactual[ok] <= 0 | r$p_counterfactual[ok] > 1) ||
      any(r$absolute_conf_low[ok] > r$absolute_difference[ok] | r$absolute_conf_high[ok] < r$absolute_difference[ok]) ||
      any(r$impact_conf_low[ok] > r$impact_fraction[ok] | r$impact_conf_high[ok] < r$impact_fraction[ok])) stop("Invalid probability/interval.")
  if (any(abs(r$absolute_difference[ok] - r$p_observed[ok] + r$p_counterfactual[ok]) > 1e-10) ||
      any(abs(r$impact_fraction[ok] - (1 - r$p_counterfactual[ok] / r$p_observed[ok])) > 1e-10) ||
      any(abs(r$difference_per1000[ok] - 1000 * r$absolute_difference[ok]) > 1e-10) ||
      any(abs(r$difference_low_per1000[ok] - 1000 * r$absolute_conf_low[ok]) > 1e-10) ||
      any(abs(r$difference_high_per1000[ok] - 1000 * r$absolute_conf_high[ok]) > 1e-10)) stop("Probability/contrast arithmetic mismatch.")
  for (target in c("bmi_ge30", "bmi_ge40")) for (window in common_windows) for (outcome in c("abg", "any_gas")) {
    rows <- r[r$target_id == target & r$window == window & r$outcome == outcome, ]
    anchor <- rows[rows$method == "mnar" & rows$r == 1 & rows$g == 1, common_quantities]
    mar <- rows[rows$method == "mar", common_quantities]
    if (!isTRUE(all.equal(anchor, mar, check.attributes = FALSE))) stop("MAR and MNAR anchor disagree.")
    for (name in c("n_reference", "n_reference_observed", "n_reference_unobserved", "n_shifted")) {
      x <- rows[[name]][rows$method != "observed"]
      if (length(unique(x)) != 1L) stop("Sensitivity assumption changed reference membership.")
    }
  }
  for (pair in c("matched_abg", "matched_any_gas")) {
    rows <- r[r$target_id == pair, ]
    if (length(unique(rows$n_training)) != 1L || any(rows$n_training != rows$n_reference) || any(rows$n_reference_unobserved != 0)) stop("Matched comparison rows differ.")
  }
  for (window in common_windows) {
    o <- a$observation[a$observation$window == window, ]
    pending_window <- all(r$source_status[r$window == window] == "pending")
    if (pending_window) {
      if (nrow(o) != 1L || !is.na(o$n) || o$evidence_pattern != "awaiting_source_evidence") stop("Invalid pending observation audit.")
    } else {
      if (sum(o$n) != p$n_reference || any(o$n_abg_positive > o$n | o$n_combined_positive > o$n)) stop("Observation patterns do not reconcile.")
      for (outcome in c("abg", "any_gas")) {
        bins <- a$observation_bmi[a$observation_bmi$window == window & a$observation_bmi$outcome == outcome, ]
        model <- m[m$model_id == paste(outcome, window, sep = "/"), ]
        if (sum(bins$n_target) != p$n_reference || sum(bins$n_observed) != model$n_training || sum(bins$n_positive) != model$n_training_events ||
            any(bins$n_positive > bins$n_observed | bins$n_observed > bins$n_target) ||
            any(abs(bins$observation_fraction - bins$n_observed / bins$n_target) > 1e-10)) stop("BMI observation audit does not reconcile.")
        for (variable in c("sex", "race_ethnicity", "location", "age_decade")) {
          c <- a$covariate_coverage
          c <- c[c$window == window & c$outcome == outcome & c$variable == variable, ]
          if (sum(c$n_target) != p$n_reference || sum(c$n_observed) != model$n_training || sum(c$n_positive) != model$n_training_events ||
              anyDuplicated(c$category) || any(c$n_positive > c$n_observed | c$n_observed > c$n_target)) stop("Covariate coverage does not reconcile.")
        }
      }
    }
  }
  s <- a$scope
  if (nrow(s) != 1L || s$input_encounters != s$exact_duplicates_removed + s$distinct_encounter_versions ||
      s$distinct_encounter_versions != s$in_scope + s$out_of_scope + s$uncertain_scope) stop("Scope audit mismatch.")
  for (outcome in c("abg", "any_gas")) {
    t <- a$timing_audit[a$timing_audit$outcome == outcome, ]
    pending_day <- all(r$source_status[r$window == "index_calendar_day"] == "pending")
    if (pending_day) {
      if (nrow(t) != 1L || !is.na(t$n) || t$index_day_state != "awaiting_source_evidence") stop("Invalid pending timing audit.")
    } else {
      states <- c("positive", "available_negative", "unknown")
      if (nrow(t) != 9L || anyDuplicated(t[c("primary_state", "index_day_state")]) ||
          any(!t$primary_state %in% states | !t$index_day_state %in% states) || anyNA(t$n) ||
          sum(t$n) != p$n_index_resolved || sum(t$n[t$index_day_state == "positive" & t$primary_state != "positive"]) != 0) stop("Timing transitions do not reconcile.")
    }
  }
  for (id in m$model_id[m$status == "estimated"]) {
    d <- a$bmi_diagnostics[a$bmi_diagnostics$cell_id == id, ]
    row <- m[m$model_id == id, ]
    if (sum(d$n) != row$n_training || sum(d$events) != row$n_training_events ||
        any(d$events > d$n | d$n <= 0 | d$bin_high - d$bin_low != 5) ||
        any(!is.finite(d$mean_fitted) | d$mean_fitted < 0 | d$mean_fitted > 1)) stop("Model-shape audit mismatch.")
  }
  invisible(TRUE)
}

write_common_bundle <- function(analysis, run_dir, input_receipt, source_hashes, mode, run_id) {
  validate_common_aggregates(analysis)
  manifest_path <- file.path(run_dir, "bundle_manifest.json")
  if (file.exists(manifest_path)) stop("Refusing to replace saved analysis.")
  saveRDS(analysis, file.path(run_dir, "aggregate_bundle.rds"))
  for (name in names(common_tables)) utils::write.csv(analysis[[name]], file.path(run_dir, common_tables[[name]]), row.names = FALSE, na = "")
  jsonlite::write_json(input_receipt, file.path(run_dir, "input_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(run_dir, "session_info.txt"))
  files <- c("aggregate_bundle.rds", unname(common_tables), "input_receipt.json", "session_info.txt")
  manifest <- list(schema_version = 3L, run_id = run_id, mode = mode, specification = common_specification(),
    code_identity = input_receipt$code_identity,
    registry_sha256 = tri_registry_hash(analysis$registry), analysis_source_sha256 = source_hashes,
    files = as.list(setNames(vapply(file.path(run_dir, files), tri_sha256, character(1)), files)))
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)
  jsonlite::write_json(list(run_id = run_id, status = "analysis_completed", analysis_evaluations = 1L,
    bundle_manifest_sha256 = tri_sha256(manifest_path), clinical_results_qualified = FALSE,
    models_attempted = sum(analysis$models$source_status == "qualified"),
    sensitivity_source_status = unique(analysis$models$source_status[grepl("index_calendar_day", analysis$models$model_id)])),
    file.path(run_dir, "analysis_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(manifest)
}

read_common_bundle <- function(run_dir) {
  manifest_path <- file.path(run_dir, "bundle_manifest.json")
  receipt <- jsonlite::read_json(file.path(run_dir, "analysis_receipt.json"), simplifyVector = TRUE)
  if (!identical(tri_sha256(manifest_path), receipt$bundle_manifest_sha256)) stop("Bundle manifest hash mismatch.")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  if (!identical(manifest$schema_version, 3L) || !manifest$mode %in% c("fixture", "clinical") ||
      !isTRUE(all.equal(manifest$specification, common_specification(), check.attributes = FALSE))) stop("Common-index bundle specification mismatch.")
  files <- unlist(manifest$files, use.names = TRUE)
  if (!setequal(names(files), c("aggregate_bundle.rds", unname(common_tables), "input_receipt.json", "session_info.txt"))) stop("Unexpected bundle files.")
  for (name in names(files)) if (!file.exists(file.path(run_dir, name)) || !identical(tri_sha256(file.path(run_dir, name)), unname(files[name]))) stop("Bundle file hash mismatch: ", name)
  analysis <- readRDS(file.path(run_dir, "aggregate_bundle.rds"))
  validate_common_aggregates(analysis)
  if (!identical(manifest$registry_sha256, tri_registry_hash(analysis$registry))) stop("Registry hash mismatch.")
  list(analysis = analysis, manifest = manifest,
    input_receipt = jsonlite::read_json(file.path(run_dir, "input_receipt.json"), simplifyVector = TRUE),
    bundle_manifest_sha256 = receipt$bundle_manifest_sha256)
}

common_number <- function(x, digits = 2L) vapply(x, function(v) {
  if (!is.finite(v)) return("—")
  if (v != 0 && round(v, digits) == 0) formatC(v, format = "g", digits = 2) else sprintf(paste0("%.", digits, "f"), v)
}, character(1))
common_interval_label <- function(r, metric, multiline = TRUE) {
  if (metric == "absolute") { v <- r$difference_per1000; lo <- r$difference_low_per1000; hi <- r$difference_high_per1000 }
  else { v <- 100 * r$impact_fraction; lo <- 100 * r$impact_conf_low; hi <- 100 * r$impact_conf_high }
  ifelse(r$status == "estimated", paste0(common_number(v), if (multiline) "\n(" else " (", common_number(lo), " to ", common_number(hi), ")"),
    ifelse(r$status == "awaiting_source_evidence", "Source pending", "Not estimable"))
}
common_axis_range <- function(r, metric) {
  cols <- if (metric == "absolute") c("difference_per1000", "difference_low_per1000", "difference_high_per1000") else c("impact_fraction", "impact_conf_low", "impact_conf_high")
  values <- unlist(r[r$status == "estimated", cols]); values <- values[is.finite(values)]
  if (metric == "relative") values <- 100 * values
  limits <- range(c(0, values)); span <- diff(limits)
  pad <- if (span == 0) .5 else .08 * span
  limits <- limits + c(-pad, pad)
  ends <- range(c(0, values))
  ticks <- if (ends[1] < 0 && ends[2] > 0) c(ends[1], 0, ends[2]) else seq(ends[1], ends[2], length.out = 3)
  ticks <- sort(unique(signif(ticks, 2)))
  if (length(ticks) == 1L) ticks <- c(-.5, 0, .5)
  if (!0 %in% ticks) ticks <- sort(unique(c(ticks, 0)))
  if (diff(ends) > 0) ticks <- ticks[ticks == 0 | abs(ticks) / diff(ends) >= .22]
  list(limits = range(c(limits, ticks)), ticks = ticks)
}
common_axis <- function(axis) {
  coords <- (axis$ticks - axis$limits[1]) / diff(axis$limits)
  children <- list(grid::segmentsGrob(x0 = 0, x1 = 1, y0 = .8, y1 = .8, gp = grid::gpar(col = "grey50")))
  for (i in seq_along(coords)) children <- c(children, list(grid::segmentsGrob(x0 = coords[i], x1 = coords[i], y0 = .8, y1 = .7),
    tri_text(common_number(axis$ticks[i], 1), coords[i], .3, 9.5)))
  grid::grobTree(children = do.call(grid::gList, children))
}
common_interval_grob <- function(r, metric, axis, y, ylim) {
  if (metric == "absolute") { r$.v <- r$difference_per1000; r$.lo <- r$difference_low_per1000; r$.hi <- r$difference_high_per1000 }
  else { r$.v <- 100 * r$impact_fraction; r$.lo <- 100 * r$impact_conf_low; r$.hi <- 100 * r$impact_conf_high }
  r$.y <- y; r <- r[r$status == "estimated", ]
  p <- ggplot2::ggplot(r, ggplot2::aes(y = .y)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = .35) +
    ggplot2::geom_segment(ggplot2::aes(x = .lo, xend = .hi, yend = .y), linewidth = .6) +
    ggplot2::geom_point(ggplot2::aes(x = .v, shape = method), size = 2.5) +
    ggplot2::scale_shape_manual(values = c(observed = 1, mar = 16), guide = "none") +
    ggplot2::coord_cartesian(xlim = axis$limits, ylim = ylim, expand = FALSE) +
    ggplot2::theme_void(base_family = "Arial") + ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0))
  ggplot2::ggplotGrob(p)
}
common_caption <- paste(
  "Adults, 2022 ED/inpatient; first BMI ≥30 index selected before gas availability. Same covariate-complete target.",
  "BMI >30 reduced by 1 kg/m²; BMI =30 unchanged. No floor. ABG/VBG = arterial/venous blood gas, in mm Hg.",
  "Observed benchmark averages over usable-evidence cases. MAR projects to the full reference under conditional MAR.",
  "PIF = 1 − p shifted/p observed. Intervals: pointwise coefficient delta method; empirical reference and assumptions fixed.",
  "Linear BMI/age, sex, race/ethnicity and region. Missing evidence stays unknown; specimen mix and testing remain informative.",
  "Model N and reference N differ. Projected criteria do not establish physiologic prevalence or causal prevention.", sep = "\n")
common_shell <- function(body, candidate, artificial, caption = common_caption) grid::grobTree(
  tri_at(tri_text("Hypercapnia probability under a one-unit BMI reduction above 30", .01, .5, 11.5, TRUE, "left"), .5, .96, .96, .045),
  tri_at(tri_text(paste0(candidate, " | ", if (artificial) "ARTIFICIAL DATA — NOT CLINICAL RESULTS" else "DRAFT — ASSUMPTION-DEPENDENT RESULTS"), .01, .5, 9.5, TRUE, "left"), .5, .91, .96, .04),
  tri_at(body, .5, .53, .96, .67),
  tri_at(tri_text(caption, .01, .5, 9, FALSE, "left"), .5, .105, .96, .16))

common_candidates <- function(analysis, artificial = TRUE, source_policy_id = NULL) {
  r <- analysis$results
  base <- r[r$target_id == "bmi_ge30" & r$window == "encounter" & r$method %in% c("observed", "mar"), ]
  axes <- list(absolute = common_axis_range(base, "absolute"), relative = common_axis_range(base, "relative"))
  y <- c(.80, .63, .36, .19)
  children <- list(tri_text("Absolute change /1,000", .40, .98, 9.5, TRUE), tri_text("PIF (%)", .80, .98, 9.5, TRUE),
    tri_text("ABG PaCO₂ ≥45", .005, .91, 10, TRUE, "left"), tri_text("ABG ≥45 or VBG ≥50", .005, .47, 10, TRUE, "left"),
    tri_text(paste0("Usable evidence: ", common_number(100 * base$n_training[1] / base$n_target[1], 1), "%"), .99, .91, 9.5, FALSE, "right"),
    tri_text(paste0("Usable evidence: ", common_number(100 * base$n_training[3] / base$n_target[3], 1), "%"), .99, .47, 9.5, FALSE, "right"))
  for (i in seq_len(nrow(base))) {
    row <- base[i, ]; label <- if (row$method == "observed") "Observed benchmark" else "MAR projection"
    children <- c(children, list(tri_text(label, .005, y[i] + .025, 9.5, FALSE, "left"),
      tri_text(paste0("Model N ", tri_count(row$n_training), "\nReference N ", tri_count(row$n_reference)), .005, y[i] - .057, 9.5, FALSE, "left"),
      tri_text(common_interval_label(row, "absolute"), .485, y[i], 9.5),
      tri_text(common_interval_label(row, "relative"), .90, y[i], 9.5)))
  }
  children <- c(children, list(tri_at(common_interval_grob(base, "absolute", axes$absolute, y, c(.13, .87)), .29, .5, .15, .74),
    tri_at(common_interval_grob(base, "relative", axes$relative, y, c(.13, .87)), .71, .5, .15, .74),
    tri_at(common_axis(axes$absolute), .29, .035, .15, .08), tri_at(common_axis(axes$relative), .71, .035, .15, .08)))
  caption <- common_caption
  if (identical(source_policy_id, "unadjusted_pco2_v1")) caption <- sub("arterial/venous blood gas", "arterial/venous unadjusted gas", caption, fixed = TRUE)
  A <- common_shell(grid::grobTree(children = do.call(grid::gList, children)), "A — Paired forest/table", artificial, caption)
  panels <- list()
  for (j in 1:2) {
    rows <- base[base$outcome == c("abg", "any_gas")[j], ]
    ch <- list(tri_text(c("ABG PaCO₂ ≥45", "ABG ≥45 or VBG ≥50")[j], .5, .96, 10, TRUE))
    for (k in 1:2) {
      row <- rows[k, ]; yy <- c(.79, .35)[k]
      ch <- c(ch, list(tri_text(if (row$method == "observed") "Observed benchmark" else "MAR projection", .5, yy + .09, 9.5, TRUE),
        tri_text(paste0("Model N ", tri_count(row$n_training), "; reference N ", tri_count(row$n_reference)), .5, yy + .025, 9.5)))
      for (metric in c("absolute", "relative")) {
        x <- if (metric == "absolute") .25 else .75
        ch <- c(ch, list(tri_at(common_interval_grob(row, metric, axes[[metric]], 1, c(.5, 1.5)), x, yy - .05, .38, .055),
          tri_text(common_interval_label(row, metric), x, yy - .16, 9.5)))
      }
    }
    ch <- c(ch, list(tri_text("Change /1,000", .25, .05, 9.5), tri_text("PIF (%)", .75, .05, 9.5),
      tri_at(common_axis(axes$absolute), .25, .12, .38, .07), tri_at(common_axis(axes$relative), .75, .12, .38, .07)))
    panels <- c(panels, list(tri_at(grid::grobTree(children = do.call(grid::gList, ch)), c(.25, .75)[j], .5, .47, 1)))
  }
  B <- common_shell(grid::grobTree(children = do.call(grid::gList, panels)), "B — Outcome-first comparison", artificial, caption)
  maps <- list(); sensitivity <- r[r$target_id == "bmi_ge30" & r$window == "encounter" & r$method == "mnar", ]
  map_limits <- vapply(list(sensitivity$difference_per1000, 100 * sensitivity$impact_fraction), function(x) max(c(1, abs(x[is.finite(x)]))), numeric(1))
  for (j in 1:2) for (k in 1:2) {
    rows <- sensitivity[sensitivity$outcome == c("abg", "any_gas")[j], ]
    rows$.value <- if (k == 1) rows$difference_per1000 else 100 * rows$impact_fraction
    rows$.label <- ifelse(rows$status == "estimated", common_number(rows$.value), "—")
    rows$.r <- factor(rows$r, levels = common_risk_odds); rows$.g <- factor(rows$g, levels = common_gradient_odds)
    p <- ggplot2::ggplot(rows, ggplot2::aes(.r, .g)) + ggplot2::geom_tile(ggplot2::aes(fill = .value), color = "grey70", linewidth = .3) +
      ggplot2::geom_tile(data = rows[rows$r == 1 & rows$g == 1, ], fill = NA, color = "black", linewidth = 1) +
      ggplot2::geom_text(ggplot2::aes(label = .label), size = 3.35, family = "Arial") +
      ggplot2::scale_fill_gradient2(low = "#BEBEBE", mid = "white", high = "#DDDDDD", midpoint = 0,
        limits = c(-1, 1) * map_limits[k], guide = "none", na.value = "white") +
      ggplot2::labs(title = paste(c("ABG", "Combined gas")[j], c("change /1,000", "PIF (%)")[k]),
        x = "Missing-outcome odds at BMI 40 (r)", y = "Gradient multiplier (g)") +
      ggplot2::theme_minimal(base_size = 9.5, base_family = "Arial") +
      ggplot2::theme(panel.grid = ggplot2::element_blank(), plot.title = ggplot2::element_text(face = "bold", size = 10),
        plot.margin = ggplot2::margin(3, 3, 3, 3), axis.title = ggplot2::element_text(size = 9.5))
    maps <- c(maps, list(tri_at(ggplot2::ggplotGrob(p), c(.25, .75)[k], c(.76, .25)[j], .49, .47)))
  }
  C <- common_shell(grid::grobTree(children = do.call(grid::gList, maps)), "C — Missing-outcome assumptions", artificial,
    paste("Exploratory scenarios: r = missing/observed outcome odds at BMI 40; g = relative odds gradient per 5 BMI units.",
      "Outlined cell r=g=1 reproduces MAR. Values are paired BMI-shift contrasts; these maps do not show confidence intervals.",
      "Ranges are prespecified assumptions, not estimated or clinically validated bounds. Unknown gases are not recoded negative.", caption, sep = "\n"))
  list(plots = list(A = A, B = B, C = C), primary = base, sensitivity = sensitivity, axes = axes)
}

export_common_candidates <- function(bundle, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  measurement_device <- file.path(output_dir, ".measurement-device.pdf")
  grDevices::cairo_pdf(measurement_device, family = "Arial")
  on.exit({ grDevices::dev.off(); unlink(measurement_device) }, add = TRUE)
  candidates <- common_candidates(bundle$analysis, bundle$manifest$mode == "fixture", bundle$input_receipt$source_policy_id)
  heights <- c(A = 190, B = 190, C = 225)
  for (id in names(candidates$plots)) for (ext in c("svg", "pdf", "png", "jpg")) {
    path <- file.path(output_dir, paste0("candidate-", id, ".", ext))
    args <- list(filename = path, plot = candidates$plots[[id]], width = 190, height = heights[[id]], units = "mm", dpi = 300, bg = "white", limitsize = FALSE)
    if (ext == "pdf") args$device <- grDevices::cairo_pdf
    if (ext == "svg") args$device <- grDevices::svg
    if (ext %in% c("png", "jpg")) args$type <- "cairo"
    do.call(ggplot2::ggsave, args)
  }
  utils::write.csv(bundle$analysis$results, file.path(output_dir, "figure_display_ledger.csv"), row.names = FALSE, na = "")
  files <- list.files(output_dir, pattern = "candidate-.*\\.(svg|pdf|png|jpg)$", full.names = TRUE)
  jsonlite::write_json(list(study_design = common_design_id, aggregate_results_sha256 = bundle$manifest$files$aggregate_results.csv,
    candidate_cells = list(A = candidates$primary$cell_id, B = candidates$primary$cell_id, C = candidates$sensitivity$cell_id),
    absolute_axis = candidates$axes$absolute, relative_axis = candidates$axes$relative,
    width_mm = 190, height_mm = as.list(heights), raster_dpi = 300,
    files = as.list(setNames(vapply(files, tri_sha256, character(1)), basename(files)))),
    file.path(output_dir, "figure_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  output <- dirname(output_dir)
  grDevices::cairo_pdf(file.path(output, "figure-gallery.pdf"), width = 190 / 25.4, height = 235 / 25.4)
  for (plot in candidates$plots) { grid::grid.newpage(); grid::grid.draw(plot) }
  grDevices::dev.off()
  banner <- if (bundle$manifest$mode == "fixture") "ARTIFICIAL DATA — NOT CLINICAL RESULTS" else "DRAFT — SOURCE AND INTERPRETATION REVIEW REQUIRED"
  cards <- vapply(names(candidates$plots), function(id) paste0('<article><h2>Candidate ', id, '</h2><a href="figures/candidate-', id, '.png"><img src="figures/candidate-', id, '.png" alt="Common-index candidate ', id, ': ', c(A = 'absolute and relative observed/MAR contrasts', B = 'outcome-first observed/MAR comparison', C = 'explicit missing-outcome assumption grid')[[id]], '"></a><p><a href="figures/candidate-', id, '.pdf">PDF</a> · <a href="figures/candidate-', id, '.svg">SVG</a> · <a href="figures/candidate-', id, '.jpg">JPG</a></p></article>'), character(1))
  writeLines(paste0('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Common-index figure alternatives</title><style>body{font:17px Arial;margin:2rem;color:#222}main{max-width:1400px;margin:auto}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}img{width:100%}article{border-top:2px solid #444}@media(max-width:950px){.grid{grid-template-columns:1fr}}</style><main><h1>Common-index hypercapnia comparisons</h1><p><strong>', banner, '</strong></p><p>A is preferred. A/B show the same four observed/MAR benchmarks; C displays the prespecified assumption scenarios. Both scales remain visible.</p><p><a href="figure-gallery.pdf">PDF gallery</a> · <a href="rendered/bmi_hypercapnia_triangulation.html">Report</a> · <a href="figures/figure_display_ledger.csv">Ledger</a></p><div class="grid">', paste(cards, collapse = ''), '</div><p>Fixed first BMI ≥30 index; covariate-complete target. No clinical causal effect is established. All candidates use the same saved aggregate bundle.</p></main></html>'), file.path(output, "figure-gallery.html"))
  invisible(candidates)
}
