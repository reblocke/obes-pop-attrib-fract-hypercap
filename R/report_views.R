bmi_analysis_label <- function(group) {
  labels<-c(primary="All valid BMI: primary",primary_bmi_ge30="BMI ≥30: secondary",
    primary_current="Current BMI: sensitivity",all_obesity="All OBESITY routes: overlapping sensitivity",
    combined="All indexed patients: audit",obesity_only="Obesity-only entry: audit",unresolved="Unresolved RFS: audit")
  label<-unname(labels[group]);if(length(label)!=1L||is.na(label))stop("Unknown analysis population")
  label
}
# Aggregate-only presentation. No patient records, model fitting or scientific recoding.
bmi_wrap <- function(x,width=28) vapply(x,function(z)paste(strwrap(z,width),collapse="\n"),character(1))
bmi_variable_label <- function(variable,dictionary) {
  label<-dictionary$display_label[match(variable,dictionary$variable_id)]
  if(!length(label)||is.na(label)||!nzchar(label))label<-gsub("_"," ",variable)
  for(term in c("BMI","ABG","VBG","ICD","RFS"))label<-gsub(paste0("\\b",tolower(term),"\\b"),term,label,ignore.case=TRUE)
  paste0(toupper(substr(label,1,1)),substring(label,2))
}
bmi_population_label <- function(x) {
  labels<-c(source_records="Original candidate records",encounter_versions="Distinct candidate encounters",source_patients="Patients in original population",
    confirmed_eligible_encounters="Confirmed eligible encounters",excluded_encounters="Excluded encounters",uncertain_encounters="Eligibility uncertain",
    n_frame_patients="Patients with confirmed eligibility",n_index_unresolved="First index unresolved",n_membership_uncertain="Patient eligibility uncertain",
    n_no_eligible_or_uncertain="No eligible or uncertain encounter",Q="Resolved first indexes (Q)",C="Complete adjustment (C)",C40="BMI ≥40 within C",
    C_icd="Known diagnosis capture",missing_adjustment="Incomplete adjustment",M_abg="Matched ICD / ABG",M_any_gas="Matched ICD / combined gas",
    C_abg_encounter="ABG outcome observed",C_any_gas_encounter="Combined outcome observed",
    "combined::Q"="All resolved common indexes", "primary::Q"="Non-OBESITY-supported entry", "primary_bmi_ge30::Q"="BMI ≥30 at the same index",
    "obesity_only::Q"="Obesity-only entry: descriptive audit", "unresolved::Q"="RFS membership unresolved")
  out<-unname(labels[x]);bad<-is.na(out);out[bad]<-gsub("_"," ",x[bad],fixed=TRUE);out
}
bmi_category_labels <- function(v,x,dictionary) {
  entry<-dictionary$value_labels[match(v,dictionary$variable_id)]
  if(!length(entry)||is.na(entry))return(x)
  parts<-trimws(strsplit(entry,"|",fixed=TRUE)[[1]]);parts<-parts[grepl(" = ",parts,fixed=TRUE)]
  if(!length(parts))return(x)
  keys<-sub(" = .*","",parts);values<-sub("^[^=]* = ","",parts);values<-sub(";.*","",values)
  found<-match(x,keys);out<-x;out[!is.na(found)]<-paste0(x[!is.na(found)],": ",values[found[!is.na(found)]])
  bmi_wrap(out,24)
}
bmi_draw_panels <- function(plots,cells,heights,title) {
  grid::grid.newpage();grid::grid.text(title,x=.02,y=.99,just=c("left","top"),gp=grid::gpar(fontsize=12,fontface="bold"))
  grid::pushViewport(grid::viewport(y=.47,height=.84,layout=grid::grid.layout(length(heights),max(cells[,4]),heights=grid::unit(heights,"null"))))
  grobs<-lapply(plots,ggplot2::ggplotGrob)
  for(row in unique(cells[,1])) {
    ix<-which(cells[,1]==row);if(length(ix)<2)next
    tops<-bottoms<-list()
    for(j in ix){g<-grobs[[j]];pan<-g$layout[grepl("^panel",g$layout$name),];tops[[as.character(j)]]<-sum(g$heights[seq_len(min(pan$t)-1)]);bottoms[[as.character(j)]]<-sum(g$heights[seq(max(pan$b)+1,length(g$heights))])}
    top<-do.call(grid::unit.pmax,tops);bottom<-do.call(grid::unit.pmax,bottoms)
    for(j in ix){g<-grobs[[j]];g<-gtable::gtable_add_rows(g,top-tops[[as.character(j)]],pos=0);g<-gtable::gtable_add_rows(g,bottom-bottoms[[as.character(j)]],pos=-1);grobs[[j]]<-g}
  }
  for(i in seq_along(plots)) {
    grid::pushViewport(grid::viewport(layout.pos.row=cells[i,1]:cells[i,2],layout.pos.col=cells[i,3]:cells[i,4]))
    g<-grobs[[i]];pan<-g$layout[grepl("^panel",g$layout$name),];pr<-unique(unlist(Map(seq,pan$t,pan$b)))
    available<-grid::convertHeight(grid::unit(1,"npc"),"mm",valueOnly=TRUE)-grid::convertHeight(sum(g$heights[-pr]),"mm",valueOnly=TRUE)
    if(available<10)stop("Quantitative panel collapsed below 10 mm; revise figure layout")
    grid::grid.draw(g);grid::popViewport()
  };grid::popViewport()
}
bmi_draw_relationship <- function(p,obs,freq,variant) {
  for(i in seq_along(p)) {
    p[[i]]<-p[[i]]+ggplot2::labs(title=paste(LETTERS[i],bmi_outcome_short(names(p)[i])),x=NULL)
    obs[[i]]<-obs[[i]]+ggplot2::labs(title=paste(LETTERS[i+3],if(names(obs)[i]=="icd")"Diagnosis capture"else paste("Usable",bmi_outcome_short(names(obs)[i]))),x=NULL)
    if(variant!="B" && i>1) {
      p[[i]]<-p[[i]]+ggplot2::labs(y=NULL)
      obs[[i]]<-obs[[i]]+ggplot2::labs(y=NULL)
    }
  }
  freq<-freq+ggplot2::labs(title="G  BMI distribution",y="Patients (%)")+ggplot2::guides(fill=ggplot2::guide_legend(nrow=1))+ggplot2::theme(legend.key.height=grid::unit(3,"mm"),legend.margin=ggplot2::margin(0,0,0,0),plot.margin=grid::unit(c(1,3,1,3),"mm"))
  if(variant=="A") {
    cells<-rbind(cbind(1,1,1:3,1:3),cbind(2,2,1:3,1:3),c(3,3,1,3))
    plots<-c(p,obs,list(freq));h<-c(1.1,1,1.05)
  } else if(variant=="B") {
    plots<-unlist(lapply(names(p),function(o)list(p[[o]],obs[[o]])),recursive=FALSE)
    cells<-rbind(cbind(rep(1:3,each=2),rep(1:3,each=2),rep(1:2,3),rep(1:2,3)),c(4,4,1,2))
    plots<-c(plots,list(freq));h<-c(1,1,1,1.1)
  } else {
    # Group the two gas definitions above the diagnosis comparator; quantities stay separate.
    order<-c("abg","any_gas","icd");plots<-c(p[order],list(freq),obs[order])
    cells<-rbind(cbind(1,1,1:3,1:3),c(2,2,1,3),cbind(3,3,1:3,1:3));h<-c(1.1,1.05,1)
  }
  bmi_draw_panels(plots,cells,h,"BMI and documented hypercapnia")
  grid::grid.text("Shading: 95% CI   |   Dotted: locally sparse   |   Dashed: outside training BMI range",
    x=.5,y=.012,gp=grid::gpar(fontsize=9.5))
}
bmi_edge_plot <- function(a,e) {
  ids<-c(e$from[1],e$to);n<-a$cohort_nodes[match(ids,a$cohort_nodes$population_id),,drop=FALSE]
  n$x<-c(0,rep(2,nrow(e)));n$y<-c((nrow(e)+1)/2,rev(seq_len(nrow(e))))
  n$text<-paste(bmi_wrap(bmi_population_label(n$population_id),27),paste0("N = ",ifelse(is.na(n$n),"unavailable",format(n$n,big.mark=",",trim=TRUE))),gsub("_"," ",n$grain),sep="\n")
  segments<-rbind(data.frame(x=.65,y=n$y[1],xe=1,ye=n$y[1]),data.frame(x=1,y=n$y[1],xe=1,ye=n$y[-1]))
  arrows<-data.frame(x=1,y=n$y[-1],xe=1.35,ye=n$y[-1])
  ggplot2::ggplot(n,ggplot2::aes(x,y))+
    ggplot2::geom_segment(data=segments,ggplot2::aes(x=x,y=y,xend=xe,yend=ye),inherit.aes=FALSE,colour="grey35")+
    ggplot2::geom_segment(data=arrows,ggplot2::aes(x=x,y=y,xend=xe,yend=ye),inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(2,"mm")))+
    ggplot2::geom_rect(ggplot2::aes(xmin=x-.65,xmax=x+.65,ymin=y-.43,ymax=y+.43),fill="white",colour="grey35")+
    ggplot2::geom_text(ggplot2::aes(label=text),size=3.4,lineheight=.95)+
    ggplot2::scale_x_continuous(limits=c(-.8,2.8))+ggplot2::scale_y_continuous(limits=c(.45,nrow(e)+.55))+
    ggplot2::labs(title=if(e$partition_id[1]=="rfs_index")"Source-entry partition at the fixed index"else paste("Cohort accounting:",e$relation[1]),subtitle=if(e$partition_id[1]=="rfs_index")"Mutually exclusive patient groups; overlap remains in primary"else if(e$relation[1]=="partition")paste("Partition:",gsub("_"," ",e$partition_id[1]))else"Children are not an exclusive partition")+
    ggplot2::theme_void(base_size=11)+ggplot2::theme(plot.margin=grid::unit(rep(4,4),"mm"),plot.title=ggplot2::element_text(face="bold"))
}
bmi_page <- function() if(knitr::is_latex_output())cat("\n\\clearpage\n\n")
bmi_figure <- function(id,review,captions) {
  ext<-if(knitr::is_latex_output())"pdf"else"svg";path<-file.path(review,"figures",paste0(id,".",ext))
  if(!file.exists(path))stop("Required figure missing: ",id)
  row<-captions[captions$figure_id==id,,drop=FALSE];if(nrow(row)!=1)stop("Figure caption identity missing: ",id)
  # A dedicated figure page keeps the complete caption with its vector image.
  if(knitr::is_latex_output()) {
    cat("\n\\clearpage\n\\begin{figure}[p]\n\\centering\n\\includegraphics[width=\\linewidth,height=.80\\textheight,keepaspectratio]{\\detokenize{",path,"}}\n\\caption{",gsub("PCO₂","PCO$_2$",bmi_latex_escape(row$caption),fixed=TRUE),"}\n\\end{figure}\n\\clearpage\n",sep="")
  } else {
    cat("\n<figure id=\"",id,"\"><img src=\"",path,"\" alt=\"",gsub('"',"&quot;",row$alt_text,fixed=TRUE),"\" style=\"width:100%;height:auto\"><figcaption>",row$caption,"</figcaption></figure>\n\n",sep="")
  }
}
bmi_coverage <- function(d,caption,represented_rows=nrow(d),representation="printed") {
  review<-Sys.getenv("BMI_REVIEW_DIR");report<-Sys.getenv("BMI_REPORT_ID")
  if(nzchar(review)&&nzchar(report)) {
    path<-file.path(review,paste0(report,"-table-coverage.csv"))
    utils::write.table(data.frame(report=report,format=if(knitr::is_latex_output())"pdf"else"html",caption=caption,rows=represented_rows,columns=ncol(d),displayed_rows=nrow(d),representation=representation),path,sep=",",row.names=FALSE,col.names=!file.exists(path),append=file.exists(path),qmethod="double")
  }
}
bmi_break_table_tokens <- function(text) {
  punctuation<-gregexpr("[/|,:;]",text,perl=TRUE)
  regmatches(text,punctuation)<-lapply(regmatches(text,punctuation),function(x)paste0(x,"\\allowbreak{}"))
  # Optional breaks preserve every character of long hashes without crossing cells.
  matches<-gregexpr("[A-Za-z0-9]{24,}",text,perl=TRUE)
  regmatches(text,matches)<-lapply(regmatches(text,matches),function(tokens)vapply(tokens,function(token) {
    starts<-seq(1,nchar(token),by=10)
    paste(substring(token,starts,pmin(starts+9,nchar(token))),collapse="\\allowbreak{}")
  },character(1)))
  text
}
bmi_report_table <- function(d,caption,keys=character(),record=TRUE) {
  if(!ncol(d)||!nrow(d)){cat("\n*",caption,": unavailable or not applicable; no numerical value implied.*\n\n",sep="");return(invisible(NULL))}
  if(record)bmi_coverage(d,caption)
  keys<-intersect(keys,names(d))
  if(nrow(d)==1&&ncol(d)>8){d<-data.frame(Field=names(d),Value=vapply(d,function(x)if(is.numeric(x))bmi_number(x,7)else as.character(x),character(1)));keys<-"Field"}
  constants<-if(nrow(d)>1&&ncol(d)>8&&!grepl("covariance|correlation",caption,ignore.case=TRUE))setdiff(names(d)[vapply(d,function(x)length(unique(x))==1,logical(1))],keys)else character()
  if(length(constants)) {
    cat("\n",paste(paste(gsub("_"," ",constants),vapply(d[constants],function(x)if(is.na(x[1]))"unavailable"else as.character(x[1]),character(1)),sep=": "),collapse="; "),".\n\n",sep="")
    d<-d[setdiff(names(d),constants)]
  }
  rest<-setdiff(names(d),keys);chunks<-split(rest,ceiling(seq_along(rest)/max(1,8-length(keys))))
  if(!length(chunks))chunks<-list(character())
  for(i in seq_along(chunks)) {
    x<-d[unique(c(keys,chunks[[i]]))]
    for(v in names(x))x[[v]]<-if(is.numeric(x[[v]]))bmi_number(x[[v]],7)else ifelse(is.na(x[[v]]),"unavailable",gsub("_"," ",as.character(x[[v]]),fixed=TRUE))
    names(x)<-gsub("_"," ",names(x),fixed=TRUE)
    label<-paste0(caption,if(length(chunks)>1)paste0(" — panel ",i,"/",length(chunks))else"")
    if(knitr::is_latex_output()) {
      out<-knitr::kable(x,format="latex",booktabs=TRUE,longtable=TRUE,caption=bmi_latex_escape(label),label=NA,row.names=FALSE,linesep="",escape=TRUE)
      out<-bmi_break_table_tokens(out)
      widths<-rep((18.4-.45*ncol(x))/ncol(x),ncol(x));if(length(keys)&&ncol(x)>3){widths[seq_along(keys)]<-3.2;widths[-seq_along(keys)]<-(18.4-.45*ncol(x)-3.2*length(keys))/(ncol(x)-length(keys))}
      spec<-paste0(">{\\raggedright\\arraybackslash}p{",format(widths,digits=3),"cm}",collapse="")
      out<-sub("\\\\begin\\{longtable\\}(\\[[^]]*\\])?\\{[lrc]+\\}",paste0("\\\\begin{longtable}{",gsub("\\","\\\\",spec,fixed=TRUE),"}"),out)
      header<-strsplit(strsplit(out,"\\toprule\n",fixed=TRUE)[[1]][2],"\\midrule",fixed=TRUE)[[1]][1]
      parts<-strsplit(out,"\\midrule\n",fixed=TRUE)[[1]]
      out<-paste0(parts[1],"\\midrule\n\\endfirsthead\n\\toprule\n",header,"\\midrule\n\\endhead\n\\relax ",paste(parts[-1],collapse="\\midrule\n"))
      cat("\n\\begingroup\\fontsize{9}{10.8}\\selectfont\n",out,"\n\\endgroup\n\n",sep="")
    }else cat(knitr::kable(x,format="html",caption=label,row.names=FALSE,table.attr='class="table bmi-audit-table"'),"\n\n")
  };invisible(NULL)
}
bmi_profile_report <- function(d,caption) {
  if(!nrow(d))return(bmi_report_table(d,caption))
  # Equality covers every value and denominator, excluding only the stage identifier.
  for(v in unique(d$variable_id)) {
    z<-d[d$variable_id==v,,drop=FALSE];shared<-bmi_unique_plot_profiles(z,setdiff(names(z),"population_id"))
    cat("\n### ",gsub("_"," ",v),"\n\n",sep="")
    bmi_coverage(shared$data,caption,nrow(z),"full values with explicit identical-summary aliases")
    bmi_report_table(shared$index,"Identical summary mapping (not a claim of identical membership)",keys="population_id")
    bmi_grouped_report(shared$data,caption,groups="variable_id",record=FALSE)
    review<-Sys.getenv("BMI_REVIEW_DIR");if(nzchar(review)) {
      dir.create(file.path(review,"coverage"),showWarnings=FALSE)
      stem<-file.path(review,"coverage",paste0(caption,"-",gsub("[^A-Za-z0-9]","-",v)))
      utils::write.csv(shared$index,paste0(stem,"-aliases.csv"),row.names=FALSE)
      utils::write.csv(shared$data,paste0(stem,"-displayed.csv"),row.names=FALSE)
    }
  }
}
bmi_grouped_report <- function(d,caption,groups,record=TRUE) {
  if(!nrow(d))return(bmi_report_table(d,caption,record=record))
  groups<-intersect(groups,names(d));key<-do.call(paste,c(d[groups],sep=" | "))
  for(ix in split(seq_len(nrow(d)),factor(key,levels=unique(key)))) {
    cat("\n**",paste(paste(groups,as.character(d[ix[1],groups]),sep="="),collapse=";  \n"),"**\n\n",sep="")
    if(record)bmi_coverage(d[ix,,drop=FALSE],caption)
    x<-d[ix,setdiff(names(d),groups),drop=FALSE]
    absent<-names(x)[vapply(x,function(v)all(is.na(v)),logical(1))]
    if(length(absent))cat("Unavailable throughout this group: ",paste(absent,collapse=", "),".\n\n",sep="")
    x<-x[setdiff(names(x),absent)]
    bmi_report_table(x,caption,keys=intersect(c("population_id","bin_low","level"),names(x))[1],record=FALSE)
  }
}
bmi_primary_ids <- function()paste(c("abg","any_gas","icd"),"encounter/spline",sep="/")
bmi_pif_view <- function(a,ids) {
  z<-a$policy_totals[a$policy_totals$model_id %in% ids,,drop=FALSE]
  if(!nrow(z))return(z)
  for(v in c("pct_shifted","p_observed","p_observed_low","p_observed_high","p_shifted","p_shifted_low","p_shifted_high","difference_per1000","difference_low_per1000","difference_high_per1000","PIF","PIF_low","PIF_high"))if(!v %in% names(z))z[[v]]<-NA_real_
  r<-a$model_registry[match(z$model_id,a$model_registry$model_id),,drop=FALSE]
  for(v in c("n_shifted","mean_decrement","maximum_decrement"))if(!v %in% names(z))z[[v]]<-NA_real_
  data.frame(Model=ifelse(z$status=="estimated",z$model_id,paste(z$model_id,z$status,z$reason,sep="; ")),Reference=z$reference_id,`Model N`=z$n_model,`Reference N`=z$n_reference,Events=r$n_events,`Patients shifted`=z$n_shifted,`Mean decrement`=z$mean_decrement,`Maximum decrement`=z$maximum_decrement,
    `Eligible (%)`=bmi_number(z$pct_shifted,4),`Observed probability % (95% CI)`=bmi_ci(100*z$p_observed,100*z$p_observed_low,100*z$p_observed_high),
    `Shifted probability % (95% CI)`=bmi_ci(100*z$p_shifted,100*z$p_shifted_low,100*z$p_shifted_high),`Difference per 1000 (95% CI)`=bmi_ci(z$difference_per1000,z$difference_low_per1000,z$difference_high_per1000),
    `PIF % (95% CI)`=bmi_ci(100*z$PIF,100*z$PIF_low,100*z$PIF_high),check.names=FALSE)
}
bmi_ci <- function(x,l,h)paste0(bmi_number(x,4)," (",bmi_number(l,4),", ",bmi_number(h,4),")")
bmi_percent_ci <- function(x,l,h)ifelse(is.na(x),"unavailable",paste0(bmi_number(x,4),"% (95% CI ",bmi_number(l,4),"–",bmi_number(h,4),"%)"))
bmi_coefficient_view <- function(a,id) {
  d<-a$coefficients[a$coefficients$model_id==id,,drop=FALSE]
  if(!nrow(d))return(d)
  data.frame(Term=d$term,Estimate=d$estimate,SE=d$std_error,`95% CI`=ifelse(d$status=="estimated",bmi_ci(d$estimate,d$conf_low,d$conf_high),"Reference; not estimated"),`P value`=d$p_value,Interpretation=d$clinical_or_interpretation,check.names=FALSE)
}
bmi_scientific_results <- function(a,section) {
  fmt<-function(x)format(x,big.mark=",",trim=TRUE,scientific=FALSE)
  count<-function(id){v<-a$cohort_nodes$n[match(id,a$cohort_nodes$population_id)];if(!length(v)||is.na(v))"unavailable"else fmt(v)}
  if(section=="cohort")cat("The original candidate ledger contained **",count("source_records")," records**, with **",count("Q")," resolved first eligible patient indexes** and **",count("C")," patients complete for adjustment**. First-index resolution remained uncertain for ",count("n_index_unresolved")," patients; no later encounter replaced these unresolved indexes. These are different counting units and are not interchangeable denominators.\n\n",sep="")
  if(section=="outcomes")for(id in bmi_primary_ids()) {
    r<-a$model_registry[a$model_registry$model_id==id,,drop=FALSE];if(!nrow(r))next
    interval<-if(is.na(r$n_model)||is.na(r$n_events)||r$n_model<=0)c(NA_real_,NA_real_)else bmi_wilson(r$n_events,r$n_model)
    cat(bmi_outcome_label(r$outcome_id),": ",fmt(r$n_events)," documented-positive outcomes among ",fmt(r$n_model)," model patients; observed positivity ",
      bmi_percent_ci(100*r$n_events/r$n_model,100*interval[1],100*interval[2])," (Wilson interval). Model status: ",r$status,". ",r$failure_reason,"\n\n",sep="")
  }
  if(section=="curves")for(id in bmi_primary_ids()) {
    z<-a$fixed_bmi_contrasts[a$fixed_bmi_contrasts$model_id==id,,drop=FALSE];if(!nrow(z))next
    if(z$status!="estimated"){cat(id,": contrast unavailable — ",z$reason,".\n\n",sep="");next}
    cat(bmi_outcome_label(a$model_registry$outcome_id[match(id,a$model_registry$model_id)]),": standardized probability at BMI 40 was ",bmi_number(100*z$probability_low_bmi,4),"% and at BMI 45 was ",bmi_number(100*z$probability_high_bmi,4),"%. The difference was ",bmi_ci(z$difference_per1000/10,z$conf_low_per1000/10,z$conf_high_per1000/10)," percentage points (95% CI), within ",z$reference_id,". This is a fixed-BMI contrast, not the one-unit distribution-shift PIF.\n\n",sep="")
  }
  if(section=="conclusion") {
    z<-a$fixed_bmi_contrasts[a$fixed_bmi_contrasts$model_id %in% bmi_primary_ids(),,drop=FALSE]
    direction<-"We estimated BMI–hypercapnia probability relationships within the fixed-index, non-OBESITY-supported source-entry population. Outcome-specific contrasts and their uncertainty are reported separately; they do not constitute a between-group test."
    cat("> **Example conclusion, pending investigator review:** ",direction," Gas-based estimates describe patients with usable blood-gas evidence in this selected acute-care cohort; diagnosis-based estimates describe patients with known diagnosis capture. The primary association remains subject to outcome-dependent entry and selective gas measurement. Secondary one-unit BMI-shift contrasts are descriptive model scenarios and do not establish effects of weight loss or cases prevented.\n\n",sep="")
  }
}

# Human-facing full contrast table; raw probabilities/covariance remain exported.
bmi_same_day_contrast_view <- function(d,labels=NULL) {
  if(!nrow(d))return(d)
  if(is.null(labels))labels<-c(no_hypercapnia="No documented hypercapnia",without_acidemia="Hypercapnia without documented same-day acidemia",
    with_acidemia="Hypercapnia with same-day acidemia",any_hypercapnia="Any hypercapnia",
    with_minus_without_change="With minus without: difference in changes")
  interval<-function(x,lo,hi,mult=1)ifelse(is.finite(x),sprintf("%.2f (%.2f to %.2f)",mult*x,mult*lo,mult*hi),"Not estimated")
  for(name in c("probability_low_bmi","probability_low_bmi_low","probability_low_bmi_high","probability_high_bmi","probability_high_bmi_low","probability_high_bmi_high","difference_per1000","conf_low_per1000","conf_high_per1000","prevalence_ratio","ratio_low","ratio_high","locally_sparse"))if(!name %in% names(d))d[[name]]<-NA
  data.frame(`BMI interval`=paste(d$bmi_low,d$bmi_high,sep=" to "),Outcome=unname(labels[d$outcome_id]),
    `Lower BMI probability % (95% CI)`=interval(d$probability_low_bmi,d$probability_low_bmi_low,d$probability_low_bmi_high,100),
    `Higher BMI probability % (95% CI)`=interval(d$probability_high_bmi,d$probability_high_bmi_low,d$probability_high_bmi_high,100),
    `Change pp (95% CI)`=interval(d$difference_per1000,d$conf_low_per1000,d$conf_high_per1000,.1),
    `Probability ratio (95% CI)`=interval(d$prevalence_ratio,d$ratio_low,d$ratio_high),
    Status=ifelse(d$status!="estimated",d$status,ifelse(d$locally_sparse,"Estimated; sparse endpoint","Estimated")),check.names=FALSE)
}
