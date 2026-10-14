# Aggregate-only persistence and display. No clinical input is read on sourcing.
tri_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
tri_run_id <- function(prefix) paste0(prefix, "-", format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "-", Sys.getpid())
tri_count <- function(x) ifelse(is.na(x), "—", format(x, big.mark = ",", trim = TRUE, scientific = FALSE))

tri_repo_root <- function() {
  root <- Sys.getenv("TRI_REPO_ROOT", unset = getwd())
  while (!file.exists(file.path(root, "R", "bmi_hypercapnia_triangulation.R"))) {
    parent <- dirname(root)
    if (identical(parent, root)) stop("Cannot locate the repository root.")
    root <- parent
  }
  normalizePath(root, mustWork = TRUE)
}

tri_legacy_context <- function() {
  root <- file.path(tri_repo_root(), "archive", "2026-10-13-bmi-to-40")
  provenance <- jsonlite::read_json(file.path(root, "provenance.json"), simplifyVector = TRUE)
  for (path in c("R/bmi_hypercapnia_triangulation.R", "R/triangulation_reporting.R", "reports/bmi_hypercapnia_triangulation.qmd")) {
    if (!identical(tri_sha256(file.path(root, path)), provenance$files[[path]])) stop("Archived source hash mismatch: ", path)
  }
  context <- new.env(parent = globalenv())
  source(file.path(root, "R", "bmi_hypercapnia_triangulation.R"), local = context)
  source(file.path(root, "R", "triangulation_reporting.R"), local = context)
  list(root = root, context = context)
}

tri_registry_hash <- function(registry) digest::digest(paste(apply(registry, 1, paste, collapse = "|"), collapse = "\n"), algo = "sha256", serialize = FALSE)
tri_specification <- function() list(
  scenario_id = triangulation_scenario_id, counterfactual = triangulation_counterfactual,
  population = "Age >=18; 2022 ED/inpatient; first qualifying encounter per patient within each frame",
  frames = as.list(triangulation_frames), outcomes = as.list(triangulation_outcomes),
  adjustment = triangulation_adjustment, bmi_age_form = "linear log odds",
  interval = "pointwise full-coefficient delta method; empirical covariates fixed",
  windows = c("encounter", "index_calendar_day")
)

validate_tri_aggregates <- function(analysis) {
  members <- c("results", "registry", "frame_counts", "scope", "timing_audit", "bmi_diagnostics", "bmi_summary")
  if (!setequal(names(analysis), members) || !all(vapply(analysis, is.data.frame, logical(1)))) stop("Unexpected aggregate bundle members.")
  if (any(vapply(analysis, function(x) any(grepl("patient_id|encounter_id|selected_row|index_date", names(x))), logical(1)))) stop("Patient-level fields are forbidden in aggregate bundles.")
  r <- analysis$results
  allowed <- c("frame", "outcome", "ascertainment_window", "analysis_role", "cell_id", "source_status",
    "n_index_resolved", "n_outcome_known", "n_outcome_missing", "n_missing_adjustment", "n_model", "n_events",
    "beta", "se", "odds_ratio", "conf_low", "conf_high", "status", "reason", "warnings", "p_observed",
    "p_counterfactual", "absolute_difference", "impact_fraction", "impact_conf_low", "impact_conf_high",
    "se_log_probability_ratio", "n_bmi_shifted", "pct_bmi_shifted", "n_index_day_conflicts", "n_counterfactual_outside_support",
    "impact_status", "impact_reason", "counterfactual", "scenario_id", "n_frame_patients", "n_index_unresolved",
    "n_membership_uncertain", "n_earliest_ties", "n_earlier_uncertainty", "n_conflicting_indexes")
  table_fields <- list(
    registry = names(triangulation_registry()),
    frame_counts = c("frame", "n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_membership_uncertain", "n_earliest_ties", "n_earlier_uncertainty", "n_conflicting_indexes"),
    scope = c("input_encounters", "exact_duplicates_removed", "distinct_encounter_versions", "n_conflicting_keys", "in_scope", "out_of_scope", "uncertain_scope"),
    timing_audit = c("frame", "outcome", "primary_state", "index_day_state", "n"),
    bmi_diagnostics = c("cell_id", "bin_low", "bin_high", "n", "events", "observed_fraction", "mean_fitted"),
    bmi_summary = c("cell_id", "n", "minimum", "q25", "median", "q75", "maximum", "n_below30", "n_at30", "n_above30", "n_near40", "n_at_least50")
  )
  if (!setequal(names(r), allowed) || any(vapply(names(table_fields), function(name) !setequal(names(analysis[[name]]), table_fields[[name]]), logical(1)))) stop("Unrecognized fields in aggregate bundle.")
  registry <- triangulation_registry()
  if (!isTRUE(all.equal(analysis$registry, registry, check.attributes = FALSE)) || nrow(r) != 15L ||
      anyDuplicated(r$cell_id) || !identical(r$cell_id, registry$cell_id)) stop("Bundle must contain the exact ordered fifteen cells.")
  for (field in c("frame", "outcome", "ascertainment_window", "analysis_role")) if (!identical(r[[field]], registry[[field]])) stop("Cell identity mismatch: ", field)
  if (any(r$scenario_id != triangulation_scenario_id) || any(r$counterfactual != triangulation_counterfactual)) stop("Counterfactual specification mismatch.")
  if (any(!r$source_status %in% c("qualified", "pending")) || any(r$source_status[r$analysis_role == "primary"] != "qualified")) stop("Invalid source qualification status.")
  if (length(unique(r$source_status[r$analysis_role == "sensitivity"])) != 1L) stop("Sensitivity source module must have one declared status.")
  available <- r$source_status == "qualified"
  pending <- !available
  if (!all(r$n_frame_patients == r$n_index_resolved + r$n_index_unresolved) ||
      !all(r$n_index_resolved[available] == r$n_outcome_known[available] + r$n_outcome_missing[available]) ||
      !all(r$n_outcome_known[available] == r$n_model[available] + r$n_missing_adjustment[available])) stop("Aggregate denominator reconciliation failed.")
  unknown_counts <- c("n_outcome_known", "n_outcome_missing", "n_missing_adjustment", "n_model", "n_events", "n_bmi_shifted", "pct_bmi_shifted", "n_index_day_conflicts", "n_counterfactual_outside_support")
  if (any(!is.na(as.matrix(r[pending, unknown_counts]))) || any(r$status[pending] != "awaiting_source_evidence") ||
      any(r$impact_status[pending] != "awaiting_source_evidence")) stop("Pending source evidence cannot become measured zero or model failure.")
  for (name in names(r)[grepl("^n_", names(r))]) {
    x <- r[[name]]
    if (!is.numeric(x) || any(!is.na(x) & (!is.finite(x) | x < 0 | x != round(x)))) stop("Invalid aggregate counts.")
  }
  if (any(r$n_events[available] > r$n_model[available]) || any(r$n_bmi_shifted[available] > r$n_model[available])) stop("Counts exceed model denominator.")
  pct <- available & r$n_model > 0
  if (any(abs(r$pct_bmi_shifted[pct] - 100 * r$n_bmi_shifted[pct] / r$n_model[pct]) > 1e-10)) stop("Shift percentage disagrees with counts.")
  if (any(!r$impact_status %in% c("estimated", "not_estimable", "awaiting_source_evidence")) ||
      any(!r$status %in% c("estimated", "not_estimable", "awaiting_source_evidence"))) stop("Unrecognized estimation status.")
  ok <- r$impact_status == "estimated"
  quantities <- c("p_observed", "p_counterfactual", "absolute_difference", "impact_fraction", "impact_conf_low", "impact_conf_high", "se_log_probability_ratio")
  if (any(!is.finite(as.matrix(r[ok, quantities]))) || any(!is.na(as.matrix(r[!ok, quantities])))) stop("Estimated cells require finite quantities; unavailable cells require missing quantities.")
  if (any(r$p_observed[ok] <= 0 | r$p_observed[ok] > 1 | r$p_counterfactual[ok] <= 0 | r$p_counterfactual[ok] > 1) ||
      any(r$impact_conf_low[ok] > r$impact_fraction[ok] | r$impact_conf_high[ok] < r$impact_fraction[ok])) stop("Invalid probabilities or interval ordering.")
  if (any(abs(r$impact_fraction[ok] - (1 - r$p_counterfactual[ok] / r$p_observed[ok])) > 1e-10) ||
      any(abs(r$absolute_difference[ok] - (r$p_observed[ok] - r$p_counterfactual[ok])) > 1e-10)) stop("Standardized probabilities and fractions disagree.")
  f <- analysis$frame_counts
  if (nrow(f) != 3L || anyDuplicated(f$frame) || !setequal(f$frame, names(triangulation_frames))) stop("Invalid frame audit.")
  for (name in intersect(names(f), names(r))) if (name != "frame" && !isTRUE(all.equal(r[[name]], f[[name]][match(r$frame, f$frame)], check.attributes = FALSE))) stop("Frame/results audit mismatch: ", name)
  if (nrow(analysis$scope) != 1L || analysis$scope$input_encounters != analysis$scope$exact_duplicates_removed + analysis$scope$distinct_encounter_versions ||
      analysis$scope$distinct_encounter_versions != analysis$scope$in_scope + analysis$scope$out_of_scope + analysis$scope$uncertain_scope) stop("Invalid scope audit.")
  b <- analysis$bmi_summary
  if (nrow(b) != 15L || !identical(b$cell_id, r$cell_id) || !isTRUE(all.equal(b$n, r$n_model, check.attributes = FALSE))) stop("BMI summary/model denominator mismatch.")
  if (any(b$n_below30[available] + b$n_at30[available] + b$n_above30[available] != b$n[available]) ||
      any(b$n_above30[available] != r$n_bmi_shifted[available])) stop("BMI-shift summary mismatch.")
  d <- analysis$bmi_diagnostics
  if (any(!d$cell_id %in% r$cell_id[r$status == "estimated"]) || anyDuplicated(d[c("cell_id", "bin_low")]) ||
      any(d$bin_high - d$bin_low != 5) || any(d$events < 0 | d$events > d$n | d$n <= 0) ||
      any(!is.finite(as.matrix(d[c("observed_fraction", "mean_fitted")]))) ||
      any(d$mean_fitted < 0 | d$mean_fitted > 1) || any(abs(d$observed_fraction - d$events / d$n) > 1e-10)) stop("Invalid BMI diagnostics.")
  for (id in r$cell_id[r$status == "estimated"]) if (sum(d$n[d$cell_id == id]) != r$n_model[match(id, r$cell_id)] ||
      sum(d$events[d$cell_id == id]) != r$n_events[match(id, r$cell_id)]) stop("BMI-bin denominator mismatch.")
  t <- analysis$timing_audit
  for (frame in names(triangulation_frames)) for (outcome in c("abg", "any_gas")) {
    rows <- t[t$frame == frame & t$outcome == outcome, ]
    sensitivity <- r[r$frame == frame & r$outcome == outcome & r$analysis_role == "sensitivity", ]
    if (sensitivity$source_status == "pending") {
      if (nrow(rows) != 1L || !is.na(rows$n) || rows$index_day_state != "awaiting_source_evidence") stop("Invalid pending timing audit.")
    } else {
      states <- c("positive", "available_negative", "unknown")
      if (nrow(rows) != 9L || anyDuplicated(rows[c("primary_state", "index_day_state")]) ||
          any(!rows$primary_state %in% states | !rows$index_day_state %in% states) ||
          any(is.na(rows$n) | rows$n < 0 | rows$n != round(rows$n)) || sum(rows$n) != sensitivity$n_index_resolved ||
          sum(rows$n[rows$index_day_state != "unknown"]) != sensitivity$n_outcome_known ||
          sum(rows$n[rows$index_day_state == "positive" & rows$primary_state != "positive"]) != 0) stop("Timing audit does not reconcile.")
    }
  }
  if (any(!t$frame %in% names(triangulation_frames) | !t$outcome %in% c("abg", "any_gas"))) stop("Unexpected timing audit keys.")
  invisible(TRUE)
}

tri_bundle_tables <- c(results = "aggregate_results.csv", registry = "specification_registry.csv", frame_counts = "frame_counts.csv",
  scope = "scope_counts.csv", timing_audit = "timing_audit.csv", bmi_diagnostics = "bmi_diagnostics.csv", bmi_summary = "bmi_summary.csv")

write_tri_bundle <- function(analysis, run_dir, input_receipt, source_hashes, mode, run_id) {
  require_tri_packages(c("jsonlite", "digest"))
  validate_tri_aggregates(analysis)
  manifest_path <- file.path(run_dir, "bundle_manifest.json")
  if (file.exists(manifest_path)) stop("Refusing to replace a saved analysis bundle.")
  saveRDS(analysis, file.path(run_dir, "aggregate_bundle.rds"))
  for (name in names(tri_bundle_tables)) utils::write.csv(analysis[[name]], file.path(run_dir, tri_bundle_tables[[name]]), row.names = FALSE, na = "")
  jsonlite::write_json(input_receipt, file.path(run_dir, "input_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(run_dir, "session_info.txt"))
  files <- c("aggregate_bundle.rds", unname(tri_bundle_tables), "input_receipt.json", "session_info.txt")
  manifest <- list(schema_version = 2L, run_id = run_id, mode = mode, specification = tri_specification(),
    registry_sha256 = tri_registry_hash(analysis$registry), analysis_source_sha256 = source_hashes,
    files = as.list(setNames(vapply(file.path(run_dir, files), tri_sha256, character(1)), files)))
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)
  jsonlite::write_json(list(run_id = run_id, status = "analysis_completed", analysis_evaluations = 1L,
    bundle_manifest_sha256 = tri_sha256(manifest_path), clinical_results_qualified = FALSE,
    sensitivity_source_status = unique(analysis$results$source_status[analysis$results$analysis_role == "sensitivity"]),
    models_attempted = sum(analysis$results$source_status == "qualified")),
    file.path(run_dir, "analysis_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(manifest)
}

read_tri_bundle <- function(run_dir) {
  require_tri_packages(c("jsonlite", "digest"))
  path <- file.path(run_dir, "bundle_manifest.json")
  receipt <- jsonlite::read_json(file.path(run_dir, "analysis_receipt.json"), simplifyVector = TRUE)
  if (!identical(tri_sha256(path), receipt$bundle_manifest_sha256)) stop("Bundle manifest hash mismatch.")
  manifest <- jsonlite::read_json(path, simplifyVector = TRUE)
  if (identical(manifest$schema_version, 1L)) {
    legacy <- tri_legacy_context()
    bundle <- legacy$context$read_tri_bundle(run_dir)
    bundle$legacy_source_root <- legacy$root
    return(bundle)
  }
  if (!identical(manifest$schema_version, 2L) || !manifest$mode %in% c("fixture", "clinical")) stop("Invalid bundle manifest.")
  if (!isTRUE(all.equal(manifest$specification, tri_specification(), check.attributes = FALSE))) stop("Bundle specification mismatch.")
  files <- unlist(manifest$files, use.names = TRUE)
  if (!setequal(names(files), c("aggregate_bundle.rds", unname(tri_bundle_tables), "input_receipt.json", "session_info.txt"))) stop("Unexpected bundle files.")
  for (name in names(files)) if (!file.exists(file.path(run_dir, name)) || !identical(tri_sha256(file.path(run_dir, name)), unname(files[name]))) stop("Bundle file hash mismatch: ", name)
  analysis <- readRDS(file.path(run_dir, "aggregate_bundle.rds"))
  validate_tri_aggregates(analysis)
  if (!identical(manifest$registry_sha256, tri_registry_hash(analysis$registry))) stop("Registry hash mismatch.")
  list(analysis = analysis, manifest = manifest,
    input_receipt = jsonlite::read_json(file.path(run_dir, "input_receipt.json"), simplifyVector = TRUE),
    bundle_manifest_sha256 = receipt$bundle_manifest_sha256)
}

tri_percent <- function(x, digits = 2L) vapply(x, function(value) {
  if (is.na(value)) return("—")
  value <- 100 * value
  if (value != 0 && round(value, digits) == 0) formatC(value, format = "g", digits = 2) else sprintf(paste0("%.", digits, "f"), value)
}, character(1), USE.NAMES = FALSE)

prepare_tri_display <- function(results) {
  registry <- triangulation_registry()
  if (nrow(results) != 15L || anyDuplicated(results$cell_id) || !setequal(results$cell_id, registry$cell_id)) stop("Current display requires fifteen unique cells.")
  r <- results[match(registry$cell_id, results$cell_id), , drop = FALSE]
  if (any(r$scenario_id != triangulation_scenario_id)) stop("Display scenario mismatch.")
  ok <- r$impact_status == "estimated"
  values <- c(0, r$impact_conf_low[ok], r$impact_conf_high[ok])
  span <- diff(range(values))
  padded <- if (span < .005) range(values) + c(-1, 1) * .0025 else range(values) + c(-1, 1) * .07 * span
  ticks <- sort(unique(c(pretty(padded, n = 4), 0)))
  limits <- range(ticks)
  if (length(ticks) > 5L) ticks <- ticks[sort(unique(c(round(seq(1, length(ticks), length.out = 4)), which(ticks == 0))))]
  r$estimate_label <- ifelse(ok, paste0(tri_percent(r$impact_fraction), "% (", tri_percent(r$impact_conf_low), " to ", tri_percent(r$impact_conf_high), ")"),
    ifelse(r$impact_status == "awaiting_source_evidence", "Source pending", "Not estimable"))
  r$estimate_multiline <- ifelse(ok, paste0(tri_percent(r$impact_fraction), "%\n(", tri_percent(r$impact_conf_low), " to ", tri_percent(r$impact_conf_high), ")"), r$estimate_label)
  r$model_label <- paste0("N = ", tri_count(r$n_model))
  r$shift_label <- ifelse(is.na(r$pct_bmi_shifted), "Shifted: —", paste0("Shifted: ", sprintf("%.1f", r$pct_bmi_shifted), "%"))
  r$window_label <- ifelse(r$ascertainment_window == "encounter", "Encounter", "Index calendar day")
  list(data = r, limits = limits, ticks = sort(unique(ticks)))
}

tri_figure_caption <- paste(
  "Observed BMI >30 reduced by 1 kg/m²; BMI ≤30 unchanged. No floor at 30. First qualifying index per frame.",
  "Adults, 2022 ED/inpatient; overlapping frames and cell-specific complete cases. Shifted = % of model N with BMI >30.",
  "PIF = 1 − mean(p shifted)/mean(p observed); pointwise delta-method 95% CI, empirical covariates fixed.",
  "Adjustment: linear BMI/age, sex, race/ethnicity and region. Filled points: encounter; open points: index calendar day.",
  "ICD = J96.02/J96.12/J96.22/J96.92/E66.2. ABG/VBG = arterial/venous gas; PCO₂ thresholds in mm Hg.",
  "Unknown measurements remain unknown. Source pending has no estimate or model N. Causal prevention is not established.", sep = "\n")
tri_outcome_text <- c(icd = "ICD composite", abg = "ABG ≥45", any_gas = "ABG ≥45 or VBG ≥50")
tri_frame_text <- function(r) c(severe_obesity = "BMI ≥40", abg_drawn = "ABG obtained", any_gas_drawn = "ABG or VBG obtained")[[r$frame[1]]]
tri_font <- function(size = 9.5, bold = FALSE, color = "#222222") grid::gpar(fontfamily = "Arial", fontsize = size, fontface = if (bold) "bold" else "plain", col = color)
tri_text <- function(label, x = .5, y = .5, size = 9.5, bold = FALSE, just = "centre", color = "#222222") grid::textGrob(label, x = x, y = y, just = just, gp = tri_font(size, bold, color))
tri_at <- function(grob, x, y, width, height) grid::grobTree(grob, vp = grid::viewport(x = x, y = y, width = width, height = height))

tri_interval_panel <- function(r, y, display, ylim) {
  r$.y <- y
  r <- r[r$impact_status == "estimated", , drop = FALSE]
  p <- ggplot2::ggplot(r, ggplot2::aes(y = .y)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = .4) +
    ggplot2::geom_segment(ggplot2::aes(x = impact_conf_low, xend = impact_conf_high, yend = .y, linetype = analysis_role), color = "#184F64", linewidth = .7) +
    ggplot2::geom_point(ggplot2::aes(x = impact_fraction, shape = analysis_role), color = "#184F64", size = 2.5, stroke = .7) +
    ggplot2::scale_shape_manual(values = c(primary = 16, sensitivity = 1), guide = "none") +
    ggplot2::scale_linetype_manual(values = c(primary = "solid", sensitivity = "solid"), guide = "none") +
    ggplot2::coord_cartesian(xlim = display$limits, ylim = ylim, expand = FALSE) +
    ggplot2::theme_void(base_family = "Arial") + ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0))
  ggplot2::ggplotGrob(p)
}
tri_axis <- function(display) {
  coords <- (display$ticks - display$limits[1]) / diff(display$limits)
  children <- list(grid::segmentsGrob(x0 = 0, x1 = 1, y0 = .85, y1 = .85, gp = grid::gpar(col = "grey50")))
  for (i in seq_along(coords)) children <- c(children, list(
    grid::segmentsGrob(x0 = coords[i], x1 = coords[i], y0 = .85, y1 = .72),
    tri_text(paste0(format(100 * display$ticks[i], trim = TRUE, digits = 3), "%"), coords[i], .38, 9.5)))
  grid::grobTree(children = do.call(grid::gList, children))
}
tri_figure_shell <- function(body, candidate, artificial) grid::grobTree(
  tri_at(tri_text("Modeled hypercapnia under a one-unit BMI reduction above 30", .01, .5, 12, TRUE, "left"), .5, .965, .96, .045),
  tri_at(tri_text(paste0(candidate, " | ", if (artificial) "ARTIFICIAL DATA — DESIGN VALIDATION" else "DRAFT CLINICAL RESULTS — REVIEW REQUIRED"), .01, .5, 9.5, TRUE, "left"), .5, .925, .96, .035),
  tri_at(body, .5, .55, .96, .70),
  tri_at(tri_text(tri_figure_caption, .01, .5, 9, FALSE, "left"), .5, .105, .96, .15)
)

plot_tri_compact <- function(display, artificial) {
  r <- display$data
  y <- unlist(lapply(0:2, function(i) 17:13 - 6 * i))
  position <- function(value) .12 + .84 * value / 19
  children <- list(tri_at(tri_interval_panel(r, y, display, c(0, 19)), .36, .54, .22, .84),
    tri_at(tri_axis(display), .36, .075, .22, .06), tri_text("PIF (%)", .36, .018, 9.5),
    tri_text("Outcome / window", .01, .99, 9.5, TRUE, "left"),
    tri_text("PIF (95% CI)", .50, .99, 9.5, TRUE, "left"), tri_text("Model / shifted", .80, .99, 9.5, TRUE, "left"))
  for (i in seq_len(nrow(r))) children <- c(children, list(
    tri_text(paste0(tri_outcome_text[[r$outcome[i]]], "\n", r$window_label[i]), .01, position(y[i]), 9.5, just = "left"),
    tri_text(r$estimate_multiline[i], .50, position(y[i]), 9.5, just = "left"),
    tri_text(paste0(r$model_label[i], "\n", r$shift_label[i]), .80, position(y[i]), 9.5, just = "left")))
  for (i in seq_len(3)) {
    rr <- r[r$frame == names(triangulation_frames)[i], ]
    children <- c(children, list(tri_text(tri_frame_text(rr), .01, position(18 - 6 * (i - 1)), 9.5, TRUE, "left"),
      tri_text(paste0("Frame N = ", tri_count(rr$n_frame_patients[1])), .50, position(18 - 6 * (i - 1)), 9.5, TRUE, "left")))
  }
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "A — Forest / table", artificial)
}
plot_tri_triptych <- function(display, artificial) {
  r <- display$data
  children <- list()
  for (j in seq_len(3)) {
    outcome <- names(triangulation_outcomes)[j]
    cells <- list(tri_text(tri_outcome_text[[outcome]], .5, .985, 10, TRUE))
    for (i in seq_len(3)) {
      group <- r[r$frame == names(triangulation_frames)[i] & r$outcome == outcome, ]
      top <- .90 - (i - 1) * .30
      cells <- c(cells, list(tri_text(tri_frame_text(group), .5, top, 9.5, TRUE)))
      for (k in seq_len(nrow(group))) {
        rr <- group[k, , drop = FALSE]
        y <- top - .055 - (k - 1) * .12
        cells <- c(cells, list(tri_text(rr$window_label, .5, y + .025, 9.5),
          tri_at(tri_interval_panel(rr, 1, display, c(.5, 1.5)), .5, y, .86, .030),
          tri_text(rr$estimate_multiline, .5, y - .030, 9.5),
          tri_text(paste0("N ", tri_count(rr$n_model), "; ", rr$shift_label), .5, y - .065, 9.5)))
      }
    }
    cells <- c(cells, list(tri_at(tri_axis(display), .5, .018, .86, .045)))
    children <- c(children, list(tri_at(grid::grobTree(children = do.call(grid::gList, cells)), (j - .5) / 3, .5, .32, 1)))
  }
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "B — Outcome-first panels; shared PIF scale", artificial)
}
plot_tri_matrix <- function(display, artificial) {
  r <- display$data
  children <- list()
  for (j in seq_len(3)) {
    x <- .17 + (j - .5) * .83 / 3
    children <- c(children, list(tri_text(tri_outcome_text[[names(triangulation_outcomes)[j]]], x, .985, 9.5, TRUE),
      tri_at(tri_axis(display), x, .02, .22, .05)))
  }
  for (i in seq_len(3)) {
    y <- .81 - (i - 1) * .30
    group <- r[r$frame == names(triangulation_frames)[i], ]
    label <- gsub("ABG or VBG obtained", "ABG or VBG\nobtained", tri_frame_text(group), fixed = TRUE)
    children <- c(children, list(tri_at(tri_text(label, .02, .5, 9.5, TRUE, "left"), .08, y, .16, .25)))
    for (j in seq_len(3)) {
      cell <- group[group$outcome == names(triangulation_outcomes)[j], ]
      pieces <- list()
      for (k in seq_len(nrow(cell))) {
        rr <- cell[k, , drop = FALSE]
        top <- if (nrow(cell) == 1L) .76 else .94 - (k - 1) * .51
        pieces <- c(pieces, list(tri_text(rr$window_label, .5, top, 9.5),
          tri_at(tri_interval_panel(rr, 1, display, c(.5, 1.5)), .5, top - .08, .22 / .26, .05),
          tri_text(rr$estimate_multiline, .5, top - .20, 9.5),
          tri_text(paste0(rr$model_label, "\n", rr$shift_label), .5, top - .35, 9.5)))
      }
      children <- c(children, list(tri_at(grid::grobTree(children = do.call(grid::gList, pieces)), .17 + (j - .5) * .83 / 3, y, .26, .29)))
    }
  }
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "C — Frame × outcome; paired gas windows", artificial)
}
tri_figure_candidates <- function(results, artificial = FALSE) {
  opened <- grDevices::dev.cur() == 1L
  if (opened) grDevices::pdf(file = NULL)
  on.exit(if (opened) grDevices::dev.off(), add = TRUE)
  display <- prepare_tri_display(results)
  list(A = plot_tri_compact(display, artificial), B = plot_tri_triptych(display, artificial), C = plot_tri_matrix(display, artificial))
}

export_tri_candidates <- function(bundle, output_dir) {
  if (identical(bundle$manifest$schema_version, 1L)) {
    legacy <- tri_legacy_context()
    previous <- Sys.getenv("TRI_REPO_ROOT")
    on.exit(Sys.setenv(TRI_REPO_ROOT = previous), add = TRUE)
    Sys.setenv(TRI_REPO_ROOT = legacy$root)
    return(legacy$context$export_tri_candidates(bundle, output_dir))
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  plots <- tri_figure_candidates(bundle$analysis$results, bundle$manifest$mode == "fixture")
  heights <- c(A = 275, B = 275, C = 275)
  devices <- list(svg = grDevices::svg, pdf = grDevices::cairo_pdf,
    png = function(...) grDevices::png(..., units = "in", res = 300, type = "cairo"),
    jpg = function(...) grDevices::jpeg(..., units = "in", res = 300, quality = 95, type = "cairo"))
  for (id in names(plots)) for (ext in names(devices)) ggplot2::ggsave(file.path(output_dir, paste0("candidate-", id, ".", ext)),
    plot = plots[[id]], device = devices[[ext]], width = 190 / 25.4, height = heights[id] / 25.4, units = "in", bg = "white")
  display <- prepare_tri_display(bundle$analysis$results)
  utils::write.csv(display$data, file.path(output_dir, "figure_display_ledger.csv"), row.names = FALSE, na = "")
  jsonlite::write_json(list(aggregate_results_sha256 = bundle$manifest$files$aggregate_results.csv,
    bundle_manifest_sha256 = bundle$bundle_manifest_sha256, scenario_id = triangulation_scenario_id,
    figure_ids = names(plots), cell_ids_by_candidate = setNames(rep(list(display$data$cell_id), 3), names(plots)),
    common_limits = display$limits, common_ticks = display$ticks, width_mm = 190, height_mm = as.list(heights),
    dpi = 300, minimum_data_font_pt = 9.5, source_sha256 = tri_sha256(file.path(tri_repo_root(), "R", "triangulation_reporting.R"))),
    file.path(output_dir, "figure_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  gallery_pdf <- file.path(dirname(output_dir), "figure-gallery.pdf")
  grDevices::cairo_pdf(gallery_pdf, width = 190 / 25.4, height = 275 / 25.4, onefile = TRUE)
  tryCatch({ for (id in names(plots)) { grid::grid.newpage(); grid::grid.draw(plots[[id]]) } }, finally = grDevices::dev.off())
  names <- c(A = "Forest / table", B = "Outcome-first panels", C = "Frame-by-outcome matrix")
  cards <- vapply(names(plots), function(id) sprintf('<article><h2>Candidate %s — %s</h2><a href="figures/candidate-%s.png"><img src="figures/candidate-%s.png" alt="Candidate %s: the same fifteen cells, PIF intervals, model denominators and BMI-shift percentages" /></a><p><a href="figures/candidate-%s.pdf">PDF</a> · <a href="figures/candidate-%s.svg">SVG</a> · <a href="figures/candidate-%s.jpg">JPG</a></p></article>', id, names[[id]], id, id, id, id, id, id), character(1))
  banner <- if (bundle$manifest$mode == "fixture") "ARTIFICIAL DATA — DESIGN VALIDATION" else "DRAFT CLINICAL RESULTS — REVIEW REQUIRED"
  html <- paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One-unit BMI shift: figure alternatives</title><style>body{font:17px Arial,sans-serif;color:#222;margin:2rem}main{max-width:1500px;margin:auto}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}article{border-top:3px solid #184f64}img{width:100%;height:auto}h1{font-size:28px}h2{font-size:20px}a{color:#184f64}code{overflow-wrap:anywhere}@media(max-width:950px){.grid{grid-template-columns:1fr}}</style></head><body><main><h1>One-unit BMI reduction above 30: exhibit alternatives</h1><p><strong>', banner, '</strong></p><p>A is the preferred starting candidate. B compares populations within outcomes; C shows the triangulation grid. Click each image for its full-size view.</p><p><a href="figure-gallery.pdf">PDF gallery</a> · <a href="rendered/bmi_hypercapnia_triangulation.html">Report</a> · <a href="figures/figure_display_ledger.csv">Shared display ledger</a></p><div class="grid">', paste(cards, collapse = ""), '</div><p>Each candidate displays the identical saved fifteen cells. Model N is cell-specific. Shifted is the percentage with observed BMI >30. Missing source evidence is explicitly pending.</p><p>Exports: 190 ×275 mm; PNG/JPG at 300 dpi. Editable R sources and SVG/PDF masters are retained. Aggregate CSV SHA-256: <code>', bundle$manifest$files$aggregate_results.csv, '</code>.</p></main></body></html>')
  writeLines(html, file.path(dirname(output_dir), "figure-gallery.html"))
  invisible(plots)
}
