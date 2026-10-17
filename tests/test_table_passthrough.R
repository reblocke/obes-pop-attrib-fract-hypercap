#!/usr/bin/env Rscript
source("R/analysis.R");source("reports/table_passthrough.R")
x<-data.frame(value=c(-.1,0,1e-8),status=c("negative","no change","small nonzero"),criterion="PREDISPOSITION")
original<-bmi_report_table;wrapped<-bmi_raw_table_writer(original)
for(format in c("html","latex")) {
 knitr::opts_knit$set(rmarkdown.pandoc.to=format)
 old<-capture.output(original(x,"Complete values"));new<-capture.output(wrapped(x,"Complete values"))
 stripped<-new[!grepl("^```",new)]
 unbreak<-function(z)gsub("\\allowbreak{}","",z,fixed=TRUE)
 stopifnot(identical(unbreak(old[nzchar(old)]),unbreak(stripped[nzchar(stripped)])),any(grepl(paste0("```{=",format,"}"),new,fixed=TRUE)))
 if(format=="latex")stopifnot(any(grepl("PREDISP\\allowbreak{}OSITION",new,fixed=TRUE)))
 empty<-capture.output(wrapped(data.frame(),"No sample"));stopifnot(any(grepl("unavailable",empty)),!any(grepl("^```",empty)))
 message("PASS raw table payload: ",format)
}
commands<-"\\arraybackslash \\endfirsthead & -1.234567e-08 PREDISPOSITION"
stopifnot(identical(unbreak(bmi_softwrap_table_line(commands)),commands))
