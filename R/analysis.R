# Current workflow bootstrap. Sourcing never reads clinical data or fits models.
bmi_source <- function(root = Sys.getenv("BMI_REPO_ROOT", unset = getwd())) {
  for (name in c("input_contract", "cohort_audit", "bmi_models", "standardization", "reporting", "report_views", "rfs_analysis", "rfs_reporting", "same_day_abg", "same_day_multinomial", "icd_acuity")) {
    sys.source(file.path(root, "R", paste0(name, ".R")), envir = parent.frame())
  }
  invisible(NULL)
}
bmi_source()
