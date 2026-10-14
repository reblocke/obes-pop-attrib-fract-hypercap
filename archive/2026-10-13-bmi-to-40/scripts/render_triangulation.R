#!/usr/bin/env Rscript
# Estimate once, then render only from a validated aggregate bundle.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[1] %in% c("fixture", "clinical", "review")) stop("Usage: Rscript scripts/render_triangulation.R fixture | clinical INPUT MANIFEST | review RUN")
mode <- args[1]
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "reports", "bmi_hypercapnia_triangulation.qmd"))) stop("Run from the repository root.")
if (mode == "clinical" && length(args) != 3L) stop("Clinical mode requires explicit INPUT and MANIFEST.")
if (mode == "fixture" && length(args) != 1L) stop("Fixture mode takes no input paths.")
if (mode == "review" && length(args) != 2L) stop("Review mode requires an explicit saved RUN directory.")
source(file.path(root, "R", "bmi_hypercapnia_triangulation.R"))
source(file.path(root, "R", "triangulation_reporting.R"))
require_tri_packages(c("ggplot2", "jsonlite", "digest", "knitr", "rmarkdown"))
if (!nzchar(Sys.which("quarto"))) stop("Quarto is unavailable; no installation attempted.")
source_files <- c("R/bmi_hypercapnia_triangulation.R", "R/triangulation_reporting.R", "reports/bmi_hypercapnia_triangulation.qmd", "scripts/render_triangulation.R", "tests/fixtures/triangulation_fixture.R")
source_hashes <- as.list(setNames(vapply(file.path(root, source_files), tri_sha256, character(1)), source_files))
run_root <- file.path(root, "artifacts", "triangulation")
dir.create(run_root, recursive = TRUE, showWarnings = FALSE)
if (mode == "review") {
  run_dir <- normalizePath(args[2], mustWork = TRUE)
  bundle <- read_tri_bundle(run_dir)
  output <- file.path(run_dir, "reviews", tri_run_id("review"))
  if (!dir.create(output, recursive = TRUE)) stop("Fresh review directory could not be created.")
} else {
  output <- run_dir <- file.path(run_root, tri_run_id(mode))
  if (!dir.create(output)) stop("Fresh run directory could not be created.")
  analysis_status <- list(status = "analysis_started", mode = mode, source_sha256 = source_hashes)
  jsonlite::write_json(analysis_status, file.path(run_dir, "analysis_status.json"), auto_unbox = TRUE, pretty = TRUE)
  # Only this branch can read clinical inputs or call the estimator.
  attempt <- tryCatch({
    input_receipt <- list(mode = mode, clinical_results_qualified = FALSE)
    if (mode == "fixture") {
      source(file.path(root, "tests", "fixtures", "triangulation_fixture.R"))
      data <- make_triangulation_fixture()
      input_receipt$source_identity <- "ARTIFICIAL FIXTURE; seed 20261012; no clinical input"
    } else {
      loaded <- load_triangulation_input(normalizePath(args[2], mustWork = TRUE), normalizePath(args[3], mustWork = TRUE))
      data <- loaded$data
      input_receipt$source_identity <- loaded$manifest$source_identity
      input_receipt$input_sha256 <- loaded$input_sha256
      input_receipt$manifest_sha256 <- tri_sha256(args[3])
      input_receipt$reviewed_manifest <- loaded$manifest
    }
    analysis <- run_triangulation(data)
    write_tri_bundle(analysis, run_dir, input_receipt, source_hashes, mode, basename(run_dir))
    NULL
  }, error = function(e) e)
  analysis_status$status <- if (is.null(attempt)) "analysis_completed" else "analysis_failed"
  if (!is.null(attempt)) analysis_status$error <- conditionMessage(attempt)
  jsonlite::write_json(analysis_status, file.path(run_dir, "analysis_status.json"), auto_unbox = TRUE, pretty = TRUE)
  if (!is.null(attempt)) stop("Analysis failed; receipt retained in ", run_dir, ": ", conditionMessage(attempt))
  rm(data, analysis)
  bundle <- read_tri_bundle(run_dir)
}
Sys.setenv(TRI_REPO_ROOT = root, TRI_RUN_DIR = run_dir, TRI_OUTPUT_DIR = output)
receipt <- list(run_id = bundle$manifest$run_id, mode = bundle$manifest$mode, status = "render_started",
                started_at = format(Sys.time(), tz = "UTC", usetz = TRUE), render_source_sha256 = source_hashes,
                bundle_manifest_sha256 = bundle$bundle_manifest_sha256, clinical_results_qualified = FALSE,
                clinical_input_opened_by_render = FALSE, analysis_evaluations_by_render = 0L)
jsonlite::write_json(receipt, file.path(output, "render_status.json"), auto_unbox = TRUE, pretty = TRUE)
plots <- export_tri_candidates(bundle, file.path(output, "figures"))
log_path <- file.path(output, "quarto-render.log")
rendered <- file.path(output, "rendered")
status <- system2("quarto", c("render", shQuote(file.path(root, "reports", "bmi_hypercapnia_triangulation.qmd")), "--to", "all", "--output-dir", shQuote(rendered)), stdout = log_path, stderr = log_path)
receipt$status <- if (identical(status, 0L)) "render_completed" else "render_failed"
receipt$exit_status <- status
receipt$completed_at <- format(Sys.time(), tz = "UTC", usetz = TRUE)
receipt$expected_outputs_present <- all(file.exists(file.path(rendered, paste0("bmi_hypercapnia_triangulation.", c("html", "pdf")))))
if (status == 0L && !receipt$expected_outputs_present) { status <- 1L; receipt$status <- "render_incomplete"; receipt$exit_status <- status }
jsonlite::write_json(receipt, file.path(output, "render_status.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Run directory:", run_dir, "\nReview directory:", output, "\nStatus:", receipt$status, "\nLog:", log_path, "\n")
quit(status = status)
