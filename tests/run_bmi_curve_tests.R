#!/usr/bin/env Rscript
source("tests/bmi_curve_checks.R")
stopifnot(length(checks)==65)
results<-list()
for(id in names(checks)) {
  err<-tryCatch({checks[[id]]();NULL},error=function(e)e)
  results[[id]]<-data.frame(check_id=id,passed=is.null(err),detail=if(is.null(err))"passed"else conditionMessage(err))
  message(if(is.null(err))"PASS "else"FAIL ",id,if(!is.null(err))paste0(": ",conditionMessage(err))else"")
}
r<-bmi_bind(results);dir.create("artifacts/triangulation/curve-refactor-tests",recursive=TRUE,showWarnings=FALSE)
utils::write.csv(r,"artifacts/triangulation/curve-refactor-tests/acceptance-results.csv",row.names=FALSE)
if(any(!r$passed))stop(sum(!r$passed)," acceptance checks failed; results retained")
message("All 65 acceptance checks passed; artificial data only")
