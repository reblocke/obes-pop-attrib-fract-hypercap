# Optional testthat interface to the same independent artificial acceptance checks.
root <- normalizePath(getwd(), mustWork = TRUE)
while (!file.exists(file.path(root, "R", "analysis.R"))) {
  parent <- dirname(root)
  if (identical(parent, root)) stop("Cannot find repository root")
  root <- parent
}
withr::local_envvar(BMI_REPO_ROOT = root)
source(file.path(root, "tests", "bmi_curve_checks.R"), local = TRUE)
for (id in names(checks)) testthat::test_that(paste("Curve/audit acceptance", id), {
  testthat::expect_error(checks[[id]](), NA)
})
