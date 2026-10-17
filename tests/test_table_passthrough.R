#!/usr/bin/env Rscript
source("R/analysis.R");source("reports/table_passthrough.R")
x<-data.frame(value=c(-.1,0,1e-8),status=c("negative","no change","small nonzero"))
original<-bmi_report_table;wrapped<-bmi_raw_table_writer(original)
for(format in c("html","latex")) {
 knitr::opts_knit$set(rmarkdown.pandoc.to=format)
 old<-capture.output(original(x,"Complete values"));new<-capture.output(wrapped(x,"Complete values"))
 stripped<-new[!grepl("^```",new)]
 stopifnot(identical(old[nzchar(old)],stripped[nzchar(stripped)]),any(grepl(paste0("```{=",format,"}"),new,fixed=TRUE)))
 empty<-capture.output(wrapped(data.frame(),"No sample"));stopifnot(any(grepl("unavailable",empty)),!any(grepl("^```",empty)))
 message("PASS raw table payload: ",format)
}
