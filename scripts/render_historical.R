#!/usr/bin/env Rscript
# Explicit historical input only; outputs never replace original sources.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% c(1L, 2L)) stop("Usage: Rscript scripts/render_historical.R INPUT [all|html|pdf]")
output_format <- if (length(args) == 2L) args[2] else "all"
if (!output_format %in% c("all", "html", "pdf")) stop("Invalid historical format.")
root <- normalizePath(".", mustWork = TRUE)
input <- normalizePath(args[1], mustWork = TRUE)
source("R/bmi_hypercapnia_triangulation.R")
require_tri_packages(c("digest", "jsonlite"))
report <- "archive/r/obesity_hrf_paf_analysis.qmd"
output <- file.path(root, "artifacts", "historical-r", paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "-", Sys.getpid()))
dir.create(output, recursive = TRUE)
receipt <- list(track = "historical_repaired_R", input_sha256 = digest::digest(file = input, algo = "sha256"),
  report_sha256 = digest::digest(file = report, algo = "sha256"), clinical_results_qualified = FALSE,
  helper_sha256 = digest::digest(file = "R/historical_hrf_helpers.R", algo = "sha256"), status = "render_started", format = output_format)
jsonlite::write_json(receipt, file.path(output, "receipt.json"), auto_unbox = TRUE, pretty = TRUE)
Sys.setenv(HISTORICAL_REPO_ROOT = root, HISTORICAL_DATA_PATH = input)
status <- system2("quarto", c("render", shQuote(report), "--to", output_format, "--output-dir", shQuote(output)),
  stdout = file.path(output, "render.log"), stderr = file.path(output, "render.log"))
receipt$status <- if (status == 0L) "render_completed" else "render_failed"
receipt$exit_status <- status
receipt$input_unchanged <- identical(receipt$input_sha256, digest::digest(file = input, algo = "sha256"))
formats <- if (output_format == "all") c("html", "pdf") else output_format
receipt$expected_outputs_present <- all(file.exists(file.path(output, paste0("obesity_hrf_paf_analysis.", formats))))
if (!receipt$input_unchanged || !receipt$expected_outputs_present) { status <- 1L; receipt$status <- "render_incomplete_or_input_changed" }
jsonlite::write_json(receipt, file.path(output, "receipt.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Historical output:", output, "\nStatus:", receipt$status, "\n")
quit(status = status)
