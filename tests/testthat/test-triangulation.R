# Works both with the dedicated runner and testthat::test_dir("tests/testthat").
triangulation_root <- normalizePath(getwd(), mustWork = TRUE)
while (!file.exists(file.path(triangulation_root, "R", "bmi_hypercapnia_triangulation.R"))) {
  parent <- dirname(triangulation_root)
  if (identical(parent, triangulation_root)) stop("Cannot locate the triangulation repository root")
  triangulation_root <- parent
}
source(file.path(triangulation_root, "R", "bmi_hypercapnia_triangulation.R"), local = TRUE)
source(file.path(triangulation_root, "R", "triangulation_reporting.R"), local = TRUE)
source(file.path(triangulation_root, "tests", "fixtures", "triangulation_fixture.R"), local = TRUE)
source(file.path(triangulation_root, "tests", "triangulation_checks.R"), local = TRUE)
for (check_name in names(triangulation_checks)) {
  testthat::test_that(check_name, {
    testthat::expect_error(triangulation_checks[[check_name]](), NA)
  })
}
