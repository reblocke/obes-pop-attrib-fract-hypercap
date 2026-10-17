#!/usr/bin/env Rscript
source("tests/bmi_curve_checks.R")
# Default clean-clone path tests computation only. Integration/visual receipts are separate.
if(Sys.getenv("BMI_TEST_INTEGRATION")!="1")checks<-checks[!names(checks) %in% c("F01","F02","F03","F05","F06","G07","G08")]

results<-list()
for(id in names(checks)) {
  err<-tryCatch({checks[[id]]();NULL},error=function(e)e)
  results[[id]]<-data.frame(check_id=id,passed=is.null(err),detail=if(is.null(err))"passed"else conditionMessage(err))
  message(if(is.null(err))"PASS "else"FAIL ",id,if(!is.null(err))paste0(": ",conditionMessage(err))else"")
}
r<-bmi_bind(results);out<-file.path("artifacts/triangulation",paste0("kernel-tests-",format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid()));dir.create(out,recursive=TRUE,showWarnings=FALSE)
utils::write.csv(r,file.path(out,"acceptance-results.csv"),row.names=FALSE)
if(any(!r$passed))stop(sum(!r$passed)," acceptance checks failed; results retained")
message("Computation checks passed; artificial only. Integration and human review are separate")
