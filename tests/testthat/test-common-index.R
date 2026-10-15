# Same artificial checks as the standalone runner, in a testthat-local environment.
common_root <- normalizePath(getwd(), mustWork = TRUE)
while (!file.exists(file.path(common_root, "R", "common_index_hypercapnia.R"))) {
  parent <- dirname(common_root)
  if (identical(parent, common_root)) stop("Cannot locate the common-index repository")
  common_root <- parent
}
for (file in c("bmi_hypercapnia_triangulation.R", "triangulation_reporting.R", "common_index_hypercapnia.R", "common_index_reporting.R")) source(file.path(common_root, "R", file), local = TRUE)
source(file.path(common_root, "tests", "fixtures", "triangulation_fixture.R"), local = TRUE)
source(file.path(common_root, "tests", "common_index_checks.R"), local = TRUE)
for (name in names(common_checks)) testthat::test_that(name, {
  testthat::expect_error(common_checks[[name]](), NA)
})
