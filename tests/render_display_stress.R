#!/usr/bin/env Rscript
# Artificial layout cases only. No clinical records or model fitting.
args<-commandArgs(TRUE);if(length(args)!=1)stop("Use explicit figure output directory")
source("R/analysis.R")
x<-data.frame(case=c("Negative","Exact zero/no change","Small nonzero","Interval crosses zero","Wide interval","Pending evidence","Long diagnostic label: unsupported reference category"),
  estimate=c(-.2,0,1e-8,.1,.2,NA,NA),low=c(-.4,0,-1e-8,-.2,-1,NA,NA),high=c(-.1,0,2e-8,.3,1.2,NA,NA))
x$case<-factor(x$case,levels=rev(x$case))
x$printed<-ifelse(is.na(x$estimate),"unavailable; no numerical mark",paste0(bmi_number(x$estimate)," (",bmi_number(x$low),", ",bmi_number(x$high),")"))
p<-ggplot2::ggplot(x,ggplot2::aes(estimate,case))+ggplot2::geom_vline(xintercept=0,colour="grey60")+
  ggplot2::geom_errorbar(ggplot2::aes(xmin=low,xmax=high),orientation="y",width=.15,na.rm=TRUE)+ggplot2::geom_point(na.rm=TRUE)+
  ggplot2::scale_y_discrete(labels=function(v)vapply(v,function(z)paste(strwrap(z,24),collapse="\n"),character(1)))+ggplot2::labs(title="ARTIFICIAL display stress cases",subtitle="Signed, zero, tiny, wide and unavailable states",x="Artificial contrast",y=NULL)+bmi_theme()
q<-ggplot2::ggplot(x,ggplot2::aes(0,case,label=printed))+ggplot2::geom_text(hjust=0,size=3.3)+
  ggplot2::xlim(0,1)+ggplot2::labs(title="Exact numerical labels",x=NULL,y=NULL)+ggplot2::theme_void(base_size=10)+ggplot2::theme(axis.text.y=ggplot2::element_blank())
# Separate numeric panel does not extend the quantitative axis.
bmi_export(function()bmi_draw_grid(list(p,q),2,"ARTIFICIAL quality-control stress","Display tests only; no epidemiologic estimates"),file.path(args[1],"QC-stress"),height_mm=160)
utils::write.csv(x,file.path(args[1],"QC-stress.csv"),row.names=FALSE)
