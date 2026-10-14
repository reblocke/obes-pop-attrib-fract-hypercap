# Aggregate-only persistence and display; no clinical input is read on sourcing.
tri_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
tri_run_id <- function(prefix) paste0(prefix, "-", format(Sys.time(), "%Y%m%dT%H%M%S"), "-", Sys.getpid())
tri_count <- function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)

validate_tri_aggregates <- function(analysis) {
  if (!identical(sort(names(analysis)), sort(c("results", "frame_counts", "scope")))) stop("Unexpected aggregate bundle members.")
  if (!all(vapply(analysis, is.data.frame, logical(1)))) stop("Aggregate members must be tables.")
  if (any(vapply(analysis, function(x) any(grepl("patient_id|encounter_id|selected_row|index_date", names(x))), logical(1)))) stop("Patient-level fields are forbidden in aggregate bundles.")
  r <- analysis$results
  required <- c("frame", "outcome", "n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_membership_uncertain", "n_outcome_known", "n_outcome_missing", "n_missing_adjustment", "n_model", "n_events", "impact_status", "impact_reason", "p_observed", "p_counterfactual", "absolute_difference", "impact_fraction", "impact_conf_low", "impact_conf_high", "n_bmi_shifted", "n_counterfactual_outside_support")
  allowed_results <- c(required, "beta", "se", "odds_ratio", "conf_low", "conf_high", "status", "reason", "warnings", "se_log_probability_ratio", "counterfactual", "n_earliest_ties", "n_earlier_uncertainty", "n_conflicting_indexes")
  allowed_frames <- c("frame", "n_frame_patients", "n_index_resolved", "n_index_unresolved", "n_membership_uncertain", "n_earliest_ties", "n_earlier_uncertainty", "n_conflicting_indexes")
  allowed_scope <- c("input_encounters", "exact_duplicates_removed", "distinct_encounter_versions", "n_conflicting_keys", "in_scope", "out_of_scope", "uncertain_scope")
  if (!setequal(names(r), allowed_results) || !setequal(names(analysis$frame_counts), allowed_frames) || !setequal(names(analysis$scope), allowed_scope)) stop("Unrecognized fields in aggregate bundle.")
  if (length(setdiff(required, names(r)))) stop("Incomplete aggregate results.")
  expected <- as.vector(outer(names(triangulation_frames), names(triangulation_outcomes), paste, sep = "/"))
  if (nrow(r) != 9L || anyDuplicated(r[c("frame", "outcome")]) || !setequal(paste(r$frame, r$outcome, sep = "/"), expected)) stop("Bundle must contain the exact nine cells.")
  if (!all(r$n_frame_patients == r$n_index_resolved + r$n_index_unresolved) ||
      !all(r$n_index_resolved == r$n_outcome_known + r$n_outcome_missing) ||
      !all(r$n_outcome_known == r$n_model + r$n_missing_adjustment)) stop("Aggregate denominator reconciliation failed.")
  counts <- r[grepl("^n_", names(r))]
  if (any(vapply(counts, function(x) any(!is.na(x) & (!is.finite(x) | x < 0 | x != round(x))), logical(1)))) stop("Invalid aggregate counts.")
  ok <- r$impact_status == "estimated"
  if (any(!r$impact_status %in% c("estimated", "not_estimable"))) stop("Unrecognized impact status.")
  if (any(!is.finite(as.matrix(r[ok, c("p_observed", "p_counterfactual", "impact_fraction", "impact_conf_low", "impact_conf_high")])))) stop("Estimated cells require finite probabilities and intervals.")
  if (any(r$impact_conf_low[ok] > r$impact_fraction[ok] | r$impact_conf_high[ok] < r$impact_fraction[ok])) stop("Interval does not contain estimate.")
  if (any(abs(r$impact_fraction[ok] - (1 - r$p_counterfactual[ok] / r$p_observed[ok])) > 1e-10) ||
      any(abs(r$absolute_difference[ok] - (r$p_observed[ok] - r$p_counterfactual[ok])) > 1e-10)) stop("Standardized probabilities and fractions disagree.")
  f <- analysis$frame_counts
  if (nrow(f) != 3L || anyDuplicated(f$frame) || !setequal(f$frame, names(triangulation_frames))) stop("Invalid frame audit.")
  for (name in intersect(names(f), names(r))) {
    if (name != "frame" && !isTRUE(all.equal(r[[name]], f[[name]][match(r$frame, f$frame)], check.attributes = FALSE))) stop("Frame/results audit mismatch: ", name)
  }
  if (nrow(analysis$scope) != 1L) stop("Scope audit must be one aggregate row.")
  invisible(TRUE)
}

write_tri_bundle <- function(analysis, run_dir, input_receipt, source_hashes, mode, run_id) {
  require_tri_packages(c("jsonlite", "digest"))
  validate_tri_aggregates(analysis)
  manifest_path <- file.path(run_dir, "bundle_manifest.json")
  if (file.exists(manifest_path)) stop("Refusing to replace a saved analysis bundle.")
  saveRDS(analysis, file.path(run_dir, "aggregate_bundle.rds"))
  for (pair in list(c("results", "aggregate_results.csv"), c("frame_counts", "frame_counts.csv"), c("scope", "scope_counts.csv"))) {
    utils::write.csv(analysis[[pair[1]]], file.path(run_dir, pair[2]), row.names = FALSE, na = "")
  }
  jsonlite::write_json(input_receipt, file.path(run_dir, "input_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(run_dir, "session_info.txt"))
  files <- c("aggregate_bundle.rds", "aggregate_results.csv", "frame_counts.csv", "scope_counts.csv", "input_receipt.json", "session_info.txt")
  manifest <- list(schema_version = 1L, run_id = run_id, mode = mode,
                   analysis_source_sha256 = source_hashes,
                   files = as.list(setNames(vapply(file.path(run_dir, files), tri_sha256, character(1)), files)))
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)
  jsonlite::write_json(list(run_id = run_id, status = "analysis_completed", analysis_evaluations = 1L,
                           bundle_manifest_sha256 = tri_sha256(manifest_path), clinical_results_qualified = FALSE),
                      file.path(run_dir, "analysis_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(manifest)
}

read_tri_bundle <- function(run_dir) {
  require_tri_packages(c("jsonlite", "digest"))
  manifest_path <- file.path(run_dir, "bundle_manifest.json")
  receipt <- jsonlite::read_json(file.path(run_dir, "analysis_receipt.json"), simplifyVector = TRUE)
  if (!identical(tri_sha256(manifest_path), receipt$bundle_manifest_sha256)) stop("Bundle manifest hash mismatch.")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  if (!identical(manifest$schema_version, 1L) || !manifest$mode %in% c("fixture", "clinical")) stop("Invalid bundle manifest.")
  files <- unlist(manifest$files, use.names = TRUE)
  expected <- c("aggregate_bundle.rds", "aggregate_results.csv", "frame_counts.csv", "scope_counts.csv", "input_receipt.json", "session_info.txt")
  if (!setequal(names(files), expected)) stop("Unexpected bundle files.")
  for (name in names(files)) if (!file.exists(file.path(run_dir, name)) || !identical(tri_sha256(file.path(run_dir, name)), unname(files[name]))) stop("Bundle file hash mismatch: ", name)
  analysis <- readRDS(file.path(run_dir, "aggregate_bundle.rds"))
  validate_tri_aggregates(analysis)
  list(analysis = analysis, manifest = manifest,
       input_receipt = jsonlite::read_json(file.path(run_dir, "input_receipt.json"), simplifyVector = TRUE),
       bundle_manifest_sha256 = receipt$bundle_manifest_sha256)
}

prepare_tri_display <- function(results) {
  order <- order(match(results$frame, names(triangulation_frames)), match(results$outcome, names(triangulation_outcomes)))
  r <- results[order, , drop = FALSE]
  if (nrow(r) != 9L || anyDuplicated(r[c("frame", "outcome")])) stop("Display requires nine unique cells.")
  ok <- r$impact_status == "estimated"
  values <- c(0, r$impact_conf_low[ok], r$impact_conf_high[ok])
  span <- max(diff(range(values)), .05)
  limits <- range(values) + c(-1, 1) * .07 * span
  ticks <- sort(unique(c(pretty(limits, n = 4), 0)))
  ticks <- ticks[ticks >= limits[1] & ticks <= limits[2]]
  if (min(values) < 0 && !any(ticks < 0)) ticks <- c(min(values), ticks)
  if (max(values) > 0 && !any(ticks > 0)) ticks <- c(ticks, max(values))
  ticks <- sort(unique(ticks))
  r$estimate_label <- ifelse(ok, sprintf("%.1f%% (%.1f to %.1f)", 100 * r$impact_fraction, 100 * r$impact_conf_low, 100 * r$impact_conf_high), "Not estimable")
  r$model_label <- paste0("N = ", tri_count(r$n_model))
  r$support_label <- ifelse(is.na(r$n_counterfactual_outside_support) | r$n_model == 0, "Outside: not assessed", paste0("Outside: ", tri_count(r$n_counterfactual_outside_support), " (", sprintf("%.1f", 100 * r$n_counterfactual_outside_support / pmax(1, r$n_model)), "%)"))
  r$diagnostic_label <- paste0("Unknown: ", tri_count(r$n_outcome_missing), "\n", r$support_label)
  list(data = r, limits = limits, ticks = ticks)
}

tri_figure_caption <- paste(
  "BMI >40 set to 40 kg/m²; BMI ≤40 unchanged. First qualifying 2022 adult ED/inpatient index per frame.",
  "Frames overlap. N = same complete cases in both scenarios; adjustment: age, sex, race/ethnicity, location.",
  "PIF = 1 − mean(pBMI-to-40)/mean(pobserved); delta-method 95% CI, empirical covariates fixed.",
  "Unknown = outcome missing at resolved indexes. Out/Outside = BMI-to-40 outside observed BMI range (% N).",
  "Frame N = confirmed patients. Uncertain = uncertain membership only. Range is a marginal support check.",
  "ICD = J96.02/J96.12/J96.22/J96.92/E66.2. ABG/VBG = arterial/venous gas; PCO₂ thresholds in mm Hg.",
  "Documented index hypercapnia; causal prevention is not established.", sep = "\n")

tri_frame_text <- function(r, short = FALSE) {
  label <- c(severe_obesity = "BMI ≥40", abg_drawn = "ABG drawn", any_gas_drawn = "ABG or VBG drawn")[[r$frame[1]]]
  if (short) return(paste0(label, "\nFrame N ", tri_count(r$n_frame_patients[1]), "; unresolved ", tri_count(r$n_index_unresolved[1]), "\nUncertain ", tri_count(r$n_membership_uncertain[1])))
  paste0(label, "   |   Frame N ", tri_count(r$n_frame_patients[1]), "; unresolved indexes ", tri_count(r$n_index_unresolved[1]), "; uncertain membership ", tri_count(r$n_membership_uncertain[1]))
}
tri_outcome_text <- c(icd = "ICD composite", abg = "ABG ≥45", any_gas = "ABG ≥45 or\nVBG ≥50")
tri_font <- function(size = 9.5, bold = FALSE, color = "#222222") grid::gpar(fontfamily = "Arial", fontsize = size, fontface = if (bold) "bold" else "plain", col = color)
tri_text <- function(label, x = .5, y = .5, size = 9.5, bold = FALSE, just = "centre", color = "#222222") grid::textGrob(label, x = x, y = y, just = just, gp = tri_font(size, bold, color))
tri_at <- function(grob, x, y, width, height) grid::grobTree(grob, vp = grid::viewport(x = x, y = y, width = width, height = height))

tri_interval_panel <- function(r, y, display, ylim) {
  r$.y <- y
  p <- ggplot2::ggplot(r, ggplot2::aes(y = .y)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey50", linewidth = .4) +
    ggplot2::geom_segment(data = r[r$impact_status == "estimated", ], ggplot2::aes(x = impact_conf_low, xend = impact_conf_high, yend = .y), color = "#184F64", linewidth = .7) +
    ggplot2::geom_point(data = r[r$impact_status == "estimated", ], ggplot2::aes(x = impact_fraction), shape = 18, color = "#184F64", size = 2.5) +
    ggplot2::coord_cartesian(xlim = display$limits, ylim = ylim, expand = FALSE) +
    ggplot2::theme_void(base_family = "Arial") + ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0))
  ggplot2::ggplotGrob(p)
}

tri_axis <- function(display) {
  coords <- (display$ticks - display$limits[1]) / diff(display$limits)
  children <- list(grid::segmentsGrob(x0 = 0, x1 = 1, y0 = .85, y1 = .85, gp = grid::gpar(col = "grey50")))
  for (i in seq_along(coords)) {
    children <- c(children, list(grid::segmentsGrob(x0 = coords[i], x1 = coords[i], y0 = .85, y1 = .72), tri_text(paste0(format(100 * display$ticks[i], trim = TRUE, digits = 3), "%"), coords[i], .38, size = 9)))
  }
  grid::grobTree(children = do.call(grid::gList, children))
}

tri_figure_shell <- function(body, candidate, artificial, body_height = .66) {
  title <- "Model-standardized hypercapnia under a BMI-to-40 scenario"
  banner <- if (artificial) "ARTIFICIAL DATA — DESIGN VALIDATION" else "DRAFT CLINICAL RESULTS — SOURCE AND SCIENTIFIC REVIEW REQUIRED"
  grid::grobTree(
    tri_at(tri_text(title, .02, .5, 12, TRUE, "left"), .5, .955, .96, .06),
    tri_at(tri_text(paste0(candidate, "  |  ", banner), .02, .5, 9.5, TRUE, "left"), .5, .91, .96, .035),
    tri_at(body, .5, .54, .96, body_height),
    tri_at(tri_text(tri_figure_caption, .01, .5, 9, FALSE, "left"), .5, .105, .96, .18)
  )
}

plot_tri_compact <- function(display, artificial) {
  r <- display$data
  y <- c(10.5, 9.5, 8.5, 6.5, 5.5, 4.5, 2.5, 1.5, .5)
  r$.y <- y
  children <- list(tri_at(tri_interval_panel(r, y, display, c(0, 12)), .395, .53, .31, .85),
                   tri_at(tri_axis(display), .395, .075, .31, .065),
                   tri_text("Potential impact fraction (%)", .395, .005, 9),
                   tri_text("Outcome", .01, .985, 9.5, TRUE, "left"),
                   tri_text("PIF (95% CI) / model N", .565, .985, 9.5, TRUE, "left"),
                   tri_text("Evidence / BMI range", .82, .985, 9.5, TRUE, "left"))
  position <- function(y) .105 + .85 * y / 12
  for (i in seq_len(nrow(r))) children <- c(children, list(
    tri_text(tri_outcome_text[[r$outcome[i]]], .01, position(y[i]), 9.5, just = "left"),
    tri_text(paste0(r$estimate_label[i], "\n", r$model_label[i]), .565, position(y[i]), 9.5, just = "left"),
    tri_text(sub("Outside:", "Out:", r$diagnostic_label[i], fixed = TRUE), .82, position(y[i]), 9, just = "left")))
  for (i in seq_len(3)) {
    group <- r[r$frame == names(triangulation_frames)[i], ]
    children <- c(children, list(tri_text(tri_frame_text(group), .01, position(c(11.5, 7.5, 3.5)[i]), 9.2, TRUE, "left")))
  }
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "A — Compact forest", artificial)
}

plot_tri_triptych <- function(display, artificial) {
  r <- display$data
  children <- list()
  # Each outcome column uses the same scale and frame order.
  for (j in seq_len(3)) {
    x <- (j - .5) / 3
    group <- r[r$outcome == names(triangulation_outcomes)[j], ]
    cells <- list(tri_text(gsub("\n", " ", tri_outcome_text[[names(triangulation_outcomes)[j]]]), .5, .98, 10.5, TRUE))
    for (i in seq_len(3)) {
      rr <- group[i, , drop = FALSE]
      y <- .82 - (i - 1) * .29
      cells <- c(cells, list(
        tri_at(tri_text(tri_frame_text(rr, TRUE), .02, .5, 9, TRUE, "left"), .5, y + .07, .96, .095),
        tri_at(tri_interval_panel(rr, 1, display, c(.5, 1.5)), .5, y, .86, .055),
        tri_text(paste0(rr$estimate_label, "\n", rr$model_label), .5, y - .055, 9.2),
        tri_text(rr$diagnostic_label, .5, y - .125, 9)))
    }
    cells <- c(cells, list(tri_at(tri_axis(display), .5, .045, .86, .06)))
    children <- c(children, list(tri_at(grid::grobTree(children = do.call(grid::gList, cells)), x, .5, .32, 1)))
  }
  children <- c(children, list(tri_text("Potential impact fraction (%) — common scale in every column", .5, .005, 9)))
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "B — Outcome-first triptych", artificial)
}

plot_tri_matrix <- function(display, artificial) {
  r <- display$data
  children <- list()
  for (j in seq_len(3)) children <- c(children, list(tri_text(gsub("\n", " ", tri_outcome_text[[names(triangulation_outcomes)[j]]]), .20 + (j - .5) * .80 / 3, .985, 10, TRUE)))
  for (i in seq_len(3)) {
    y <- .81 - (i - 1) * .29
    group <- r[r$frame == names(triangulation_frames)[i], ]
    label <- tri_frame_text(group, TRUE)
    label <- gsub("; unresolved ", "\nUnresolved ", label, fixed = TRUE)
    label <- gsub("ABG or VBG drawn", "ABG or VBG\ndrawn", label, fixed = TRUE)
    children <- c(children, list(tri_at(tri_text(label, .02, .5, 9, TRUE, "left"), .095, y, .18, .23)))
    for (j in seq_len(3)) {
      rr <- group[j, , drop = FALSE]
      x <- .20 + (j - .5) * .80 / 3
      cell <- grid::grobTree(
        tri_at(tri_interval_panel(rr, 1, display, c(.5, 1.5)), .5, .74, .9, .18),
        tri_at(tri_axis(display), .5, .58, .9, .16),
        tri_text(paste0(rr$estimate_label, "\n", rr$model_label), .5, .35, 9.2),
        tri_text(rr$diagnostic_label, .5, .08, 9))
      children <- c(children, list(tri_at(cell, x, y, .255, .25)))
    }
  }
  children <- c(children, list(tri_text("Potential impact fraction (%) — identical axes in all nine cells", .6, .025, 9)))
  tri_figure_shell(grid::grobTree(children = do.call(grid::gList, children)), "C — 3×3 mini-forest matrix", artificial)
}

tri_figure_candidates <- function(results, artificial = FALSE) {
  # ggplotGrob needs a device for measurements. Avoid an implicit Rplots.pdf
  # when constructing candidates in a clean, noninteractive R session.
  opened_device <- grDevices::dev.cur() == 1L
  if (opened_device) grDevices::pdf(file = NULL)
  on.exit(if (opened_device) grDevices::dev.off(), add = TRUE)
  display <- prepare_tri_display(results)
  list(A = plot_tri_compact(display, artificial), B = plot_tri_triptych(display, artificial), C = plot_tri_matrix(display, artificial))
}

export_tri_candidates <- function(bundle, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  plots <- tri_figure_candidates(bundle$analysis$results, bundle$manifest$mode == "fixture")
  heights <- c(A = 180, B = 180, C = 180)
  devices <- list(svg = grDevices::svg, pdf = grDevices::cairo_pdf,
                  png = function(...) grDevices::png(..., units = "in", res = 300, type = "cairo"),
                  jpg = function(...) grDevices::jpeg(..., units = "in", res = 300, quality = 95, type = "cairo"))
  for (id in names(plots)) {
    base <- file.path(output_dir, paste0("candidate-", id))
    for (ext in names(devices)) ggplot2::ggsave(paste0(base, ".", ext), plot = plots[[id]], device = devices[[ext]], width = 190 / 25.4, height = heights[id] / 25.4, units = "in", bg = "white")
  }
  display <- prepare_tri_display(bundle$analysis$results)
  utils::write.csv(display$data, file.path(output_dir, "figure_display_ledger.csv"), row.names = FALSE, na = "")
  jsonlite::write_json(list(aggregate_results_sha256 = bundle$manifest$files$aggregate_results.csv,
                          bundle_manifest_sha256 = bundle$bundle_manifest_sha256,
                          figure_ids = names(plots), common_limits = display$limits, common_ticks = display$ticks,
                          width_mm = 190, height_mm = as.list(heights), dpi = 300, minimum_data_font_pt = 9,
                          source_sha256 = tri_sha256(file.path(Sys.getenv("TRI_REPO_ROOT"), "R", "triangulation_reporting.R"))),
                      file.path(output_dir, "figure_receipt.json"), auto_unbox = TRUE, pretty = TRUE)
  gallery_pdf <- file.path(dirname(output_dir), "figure-gallery.pdf")
  grDevices::cairo_pdf(gallery_pdf, width = 190 / 25.4, height = 180 / 25.4, onefile = TRUE)
  tryCatch({
    for (id in names(plots)) { grid::grid.newpage(); grid::grid.draw(plots[[id]]) }
  }, finally = grDevices::dev.off())
  cards <- vapply(names(plots), function(id) sprintf('<article><h2>Candidate %s — %s</h2><a href="figures/candidate-%s.png"><img src="figures/candidate-%s.png" alt="Candidate %s: identical nine PIF estimates, intervals and model denominators" /></a><p><a href="figures/candidate-%s.pdf">PDF master</a> · <a href="figures/candidate-%s.svg">SVG master</a> · <a href="figures/candidate-%s.jpg">JPG candidate</a></p></article>', id, c(A = "Compact forest", B = "Outcome-first triptych", C = "3×3 mini-forest matrix")[[id]], id, id, id, id, id, id), character(1))
  banner <- if (bundle$manifest$mode == "fixture") "ARTIFICIAL DATA — DESIGN VALIDATION" else "DRAFT CLINICAL RESULTS — REVIEW REQUIRED"
  html <- paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>BMI-to-40 figure alternatives</title><style>body{font:17px Arial,sans-serif;color:#222;margin:2rem}main{max-width:1500px;margin:auto}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}article{border-top:3px solid #184f64}img{width:100%;height:auto}h1{font-size:28px}h2{font-size:20px}a{color:#184f64}.status{font-weight:bold}code{overflow-wrap:anywhere}@media(max-width:950px){.grid{grid-template-columns:1fr}}@media print{.grid{display:block}article{page-break-before:always}img{max-width:190mm}}</style></head><body><main><h1>BMI-to-40: compare three exhibit alternatives</h1><p class="status">', banner, '</p><p>A is recommended provisionally for magnitude and precision comparisons. B compares frames within each outcome; C exposes the full triangulation grid. Click any thumbnail for its full-size review.</p><p><a href="figure-gallery.pdf">Three-page PDF gallery</a> · <a href="rendered/bmi_hypercapnia_triangulation.html">Analysis report</a> · <a href="figures/figure_display_ledger.csv">Shared display ledger</a></p><div class="grid">', paste(cards, collapse = ""), '</div><p>Same saved aggregate ledger for every candidate. CSV SHA-256: <code>', bundle$manifest$files$aggregate_results.csv, '</code>.</p><p>Each export is 190 ×180 mm at 300 dpi for PNG/JPG; vector masters retain editable plotting source. Unknown denotes unavailable outcome evidence; outside-range diagnostics concern marginal BMI support. Scientific qualification remains separate from layout review.</p></main></body></html>')
  writeLines(html, file.path(dirname(output_dir), "figure-gallery.html"))
  invisible(plots)
}
