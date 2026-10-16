#!/usr/bin/env Rscript
# Estimate once, then render only from a validated aggregate bundle.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[1] %in% c("fixture", "clinical", "review")) stop("Usage: fixture [FORMAT] | clinical INPUT MANIFEST [FORMAT] | review RUN [FORMAT]; FORMAT=all/html/pdf")
mode <- args[1]
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "reports", "bmi_hypercapnia_triangulation.qmd"))) stop("Run from the repository root.")
required_args <- c(fixture = 1L, clinical = 3L, review = 2L)[[mode]]
if (!length(args) %in% c(required_args, required_args + 1L)) stop("Explicit mode arguments are missing or unexpected.")
output_format <- if (length(args) > required_args) args[length(args)] else "all"
if (!output_format %in% c("all", "html", "pdf")) stop("FORMAT must be all, html or pdf.")
if (!requireNamespace("digest", quietly = TRUE)) stop("Missing digest; no installation attempted.")
source_files <- c("R/common_index_hypercapnia.R", "R/common_index_reporting.R", "R/bmi_hypercapnia_triangulation.R", "R/triangulation_reporting.R", "reports/bmi_hypercapnia_triangulation.qmd", "scripts/render_triangulation.R", "tests/fixtures/triangulation_fixture.R", "config/common_index_source_policy.json", "config/common_index_bmi_policy.json")
source_paths <- setNames(file.path(root, source_files), source_files)
source_hashes <- as.list(vapply(source_paths, function(path) digest::digest(file = path, algo = "sha256"), character(1)))
source(file.path(root, "R", "bmi_hypercapnia_triangulation.R"))
source(file.path(root, "R", "triangulation_reporting.R"))
source(file.path(root, "R", "common_index_hypercapnia.R"))
source(file.path(root, "R", "common_index_reporting.R"))
Sys.setenv(TRI_REPO_ROOT = root)
require_tri_packages(c("ggplot2", "jsonlite", "digest", "knitr", "rmarkdown"))
if (!nzchar(Sys.which("quarto"))) stop("Quarto is unavailable; no installation attempted.")
code_identity <- list(commit = NA_character_, tree = NA_character_, working_tree_clean = FALSE)
if (nzchar(Sys.which("git"))) {
  git_value <- function(args) {
    value <- system2("git", args, stdout = TRUE, stderr = FALSE)
    if (!is.null(attr(value, "status"))) stop("Cannot resolve Git code identity.")
    value
  }
  code_identity <- list(commit = git_value(c("rev-parse", "HEAD")), tree = git_value(c("rev-parse", "HEAD^{tree}")),
    working_tree_clean = !length(git_value(c("status", "--porcelain", "--untracked-files=all"))))
}
if (mode == "clinical" && !isTRUE(code_identity$working_tree_clean)) stop("Clinical estimation requires the clean merged checkout; private inputs and configuration must remain ignored.")
run_root <- file.path(root, "artifacts", "triangulation")
dir.create(run_root, recursive = TRUE, showWarnings = FALSE)
if (mode == "review") {
  run_dir <- normalizePath(args[2], mustWork = TRUE)
  manifest <- jsonlite::read_json(file.path(run_dir, "bundle_manifest.json"), simplifyVector = TRUE)
  if (manifest$schema_version %in% c(1L, 2L)) {
    status <- system2("python3", c(shQuote(file.path(root, "scripts", "run_frame_triangulation.py")), "review", shQuote(run_dir), output_format))
    quit(status = status)
  }
  bundle <- read_common_bundle(run_dir)
  output <- file.path(run_dir, "reviews", tri_run_id("review"))
  if (!dir.create(output, recursive = TRUE)) stop("Fresh review directory could not be created.")
} else {
  output <- run_dir <- file.path(run_root, tri_run_id(mode))
  if (!dir.create(output)) stop("Fresh run directory could not be created.")
  analysis_status <- list(status = "analysis_started", mode = mode, source_sha256 = source_hashes)
  jsonlite::write_json(analysis_status, file.path(run_dir, "analysis_status.json"), auto_unbox = TRUE, pretty = TRUE)
  # Only this branch can read clinical inputs or call the estimator.
  attempt <- tryCatch({
    input_receipt <- list(mode = mode, clinical_results_qualified = FALSE, code_identity = code_identity)
    if (mode == "fixture") {
      source(file.path(root, "tests", "fixtures", "triangulation_fixture.R"))
      data <- make_triangulation_fixture()
      input_receipt$source_identity <- "ARTIFICIAL FIXTURE; seed 20261012; calendar-day fixture added 20261013; no clinical input"
    } else {
      loaded <- load_common_input(normalizePath(args[2], mustWork = TRUE), normalizePath(args[3], mustWork = TRUE))
      data <- loaded$data
      input_receipt$source_identity <- loaded$manifest$source_identity
      input_receipt$input_sha256 <- loaded$input_sha256
      input_receipt$manifest_sha256 <- loaded$manifest_sha256
      input_receipt$reviewed_manifest <- loaded$manifest
      input_receipt$source_policy_id <- loaded$manifest$source_policy_id
      input_receipt$source_audit <- loaded$source_audit
    }
    analysis <- run_common_index(data)
    if (!identical(source_hashes, as.list(vapply(source_paths, tri_sha256, character(1))))) stop("Analysis sources changed during estimation.")
    if (mode == "clinical" && (!identical(loaded$input_sha256, tri_sha256(args[2])) ||
        !identical(loaded$manifest_sha256, tri_sha256(args[3])))) stop("Clinical input or manifest changed during estimation.")
    write_common_bundle(analysis, run_dir, input_receipt, source_hashes, mode, basename(run_dir))
    NULL
  }, error = function(e) e)
  analysis_status$status <- if (is.null(attempt)) "analysis_completed" else "analysis_failed"
  if (!is.null(attempt)) analysis_status$error <- conditionMessage(attempt)
  jsonlite::write_json(analysis_status, file.path(run_dir, "analysis_status.json"), auto_unbox = TRUE, pretty = TRUE)
  if (!is.null(attempt)) stop("Analysis failed; receipt retained in ", run_dir, ": ", conditionMessage(attempt))
  rm(data, analysis)
  bundle <- read_common_bundle(run_dir)
}
report_root <- root
Sys.setenv(TRI_RUN_DIR = run_dir, TRI_OUTPUT_DIR = output)
receipt <- list(run_id = bundle$manifest$run_id, mode = bundle$manifest$mode, status = "render_started",
                started_at = format(Sys.time(), tz = "UTC", usetz = TRUE), render_source_sha256 = source_hashes,
                bundle_manifest_sha256 = bundle$bundle_manifest_sha256, clinical_results_qualified = FALSE,
                bundle_schema_version = bundle$manifest$schema_version, study_design = common_design_id, format = output_format,
                clinical_input_opened_by_render = FALSE, analysis_evaluations_by_render = 0L)
jsonlite::write_json(receipt, file.path(output, "render_status.json"), auto_unbox = TRUE, pretty = TRUE)
plots <- export_common_candidates(bundle, file.path(output, "figures"))
Sys.setenv(TRI_REPO_ROOT = report_root)
log_path <- file.path(output, "quarto-render.log")
rendered <- file.path(output, "rendered")
status <- system2("quarto", c("render", shQuote(file.path(report_root, "reports", "bmi_hypercapnia_triangulation.qmd")), "--to", output_format, "--output-dir", shQuote(rendered)), stdout = log_path, stderr = log_path)
receipt$status <- if (identical(status, 0L)) "render_completed" else "render_failed"
receipt$exit_status <- status
receipt$completed_at <- format(Sys.time(), tz = "UTC", usetz = TRUE)
formats <- if (output_format == "all") c("html", "pdf") else output_format
receipt$expected_outputs_present <- all(file.exists(file.path(rendered, paste0("bmi_hypercapnia_triangulation.", formats))))
if (status == 0L && !receipt$expected_outputs_present) { status <- 1L; receipt$status <- "render_incomplete"; receipt$exit_status <- status }
receipt$render_sources_unchanged <- identical(source_hashes, as.list(vapply(source_paths, tri_sha256, character(1))))
if (!receipt$render_sources_unchanged) { status <- 1L; receipt$status <- "render_sources_changed"; receipt$exit_status <- status }
jsonlite::write_json(receipt, file.path(output, "render_status.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Run directory:", run_dir, "\nReview directory:", output, "\nStatus:", receipt$status, "\nLog:", log_path, "\n")
quit(status = status)
