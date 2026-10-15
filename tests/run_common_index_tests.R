#!/usr/bin/env Rscript
# Artificial-only test entrypoint; never reads clinical inputs.
for (file in c("bmi_hypercapnia_triangulation.R", "triangulation_reporting.R", "common_index_hypercapnia.R", "common_index_reporting.R")) source(file.path("R", file))
source("tests/fixtures/triangulation_fixture.R")
source("tests/common_index_checks.R")
failures <- character()
for (name in names(common_checks)) {
  error <- tryCatch({common_checks[[name]]();NULL},error=function(e)e)
  if (is.null(error)) message("PASS: ",name) else {
    message("FAIL: ",name," — ",conditionMessage(error));failures<-c(failures,name)
  }
}
if (length(failures)) stop(length(failures)," common-index groups failed")
message("All ",length(common_checks)," common-index artificial check groups passed.")
