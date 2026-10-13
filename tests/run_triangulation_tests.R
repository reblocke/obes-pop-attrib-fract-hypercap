#!/usr/bin/env Rscript
# This runner reads artificial fixtures only; it never opens clinical input.
script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1L) stop("Run with Rscript tests/run_triangulation_tests.R")
script_path <- normalizePath(gsub("~+~", " ", sub("^--file=", "", script_argument), fixed = TRUE), mustWork = TRUE)
root <- dirname(dirname(script_path))
if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_file(file.path(root, "tests", "testthat", "test-triangulation.R"),
                      stop_on_failure = TRUE)
} else {
  message("testthat is unavailable; running the exact same shared base-R checks. No installation attempted.")
  source(file.path(root, "R", "bmi_hypercapnia_triangulation.R"))
  source(file.path(root, "R", "triangulation_reporting.R"))
  source(file.path(root, "tests", "fixtures", "triangulation_fixture.R"))
  source(file.path(root, "tests", "triangulation_checks.R"))
  failures <- character()
  for (check_name in names(triangulation_checks)) {
    error <- tryCatch({ triangulation_checks[[check_name]](); NULL }, error = function(e) e)
    if (is.null(error)) {
      message("PASS: ", check_name)
    } else {
      message("FAIL: ", check_name, " - ", conditionMessage(error))
      failures <- c(failures, check_name)
    }
  }
  if (length(failures)) stop(length(failures), " triangulation check group(s) failed", call. = FALSE)
  message("All ", length(triangulation_checks), " artificial-data check groups passed.")
}
