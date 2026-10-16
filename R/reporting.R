# Aggregate persistence, validation, code-generated figures and complete report tables.
validate_analysis_bundle <- function(a) {
  if(!setequal(names(a),bmi_table_names)||!all(vapply(a,is.data.frame,logical(1))))stop("Unexpected aggregate table contract")
  for(name in names(a)) {
    if(any(grepl("^(patient_id|encounter_id|selected_row|index_date|encounter_date|individual_prediction)$",names(a[[name]]))))stop("Private row-level field in bundle: ",name)
    if(any(vapply(a[[name]],function(v)inherits(v,"Date")||inherits(v,"POSIXt"),logical(1))))stop("Direct dates in aggregate bundle")
  }
  bmi_validate_ledger(a)
  if(nrow(a$model_registry)) {
    if(nrow(a$model_registry)!=21||anyDuplicated(a$model_registry$model_id))stop("Model registry identity/count mismatch")
    for(id in a$model_registry$model_id) {
      r<-a$model_registry[a$model_registry$model_id==id,,drop=FALSE]
      if(r$status %in% c("successful","fitted_with_concerns")) {
        c<-a$coefficients[a$coefficients$model_id==id & a$coefficients$status=="estimated",,drop=FALSE]
        v<-a$coefficient_covariance[a$coefficient_covariance$model_id==id,,drop=FALSE]
        if(nrow(c)!=r$n_parameters||nrow(v)!=nrow(c)^2||!setequal(c$term,v$term1)||!setequal(c$term,v$term2))stop("Coefficient/covariance coverage failure")
      }
    }
  }
  if(nrow(a$policy_contributions)) {
    keys<-c("model_id","reference_id","policy_id","method","r","gradient_multiplier")
    key<-function(d)do.call(paste,c(d[keys],sep="|"))
    ct<-a$policy_contributions;tot<-a$policy_totals;cv<-a$policy_contribution_covariance
    for(ix in split(seq_len(nrow(ct)),key(ct))) {
      k<-key(ct[ix[1],,drop=FALSE]);t<-tot[key(tot)==k & tot$status=="estimated",,drop=FALSE];z<-ct[ix,,drop=FALSE]
      if(nrow(t)!=1||max(abs(c(sum(z$n)-t$n_reference,sum(z$mass)-1,sum(z$A)-t$p_observed,sum(z$G)-t$p_shifted,sum(z$D)-t$absolute_difference)))>1e-9)stop("Policy totals/contributions disagree")
      if(abs(sum(cv$covariance[key(cv)==k])-t$variance_difference)>1e-9)stop("Contribution covariance does not reproduce total variance")
    }
  }
  invisible(TRUE)
}
bmi_estimation_files <- function() c("R/analysis.R","R/input_contract.R","R/cohort_audit.R","R/bmi_models.R","R/standardization.R","config/bmi_hypercapnia_analysis.json","config/variable_dictionary.csv","config/common_index_source_policy.json","config/common_index_bmi_policy.json")
bmi_hash_files <- function(files) as.list(setNames(vapply(file.path(tri_repo_root(),files),tri_sha256,character(1)),files))
bmi_write_bundle <- function(a,path,config,receipt,mode="fixture") {
  validate_analysis_bundle(a)
  if(dir.exists(path)||file.exists(path))stop("Bundle output must be fresh")
  dir.create(path,recursive=TRUE,mode="0700");saveRDS(a,file.path(path,"analysis.rds"))
  for(name in names(a))utils::write.csv(a[[name]],file.path(path,paste0(name,".csv")),row.names=FALSE,na="")
  jsonlite::write_json(config,file.path(path,"analysis_config.json"),auto_unbox=TRUE,pretty=TRUE,digits=NA)
  jsonlite::write_json(receipt,file.path(path,"input_receipt.json"),auto_unbox=TRUE,pretty=TRUE,digits=NA)
  writeLines(capture.output(sessionInfo()),file.path(path,"session-info.txt"))
  files<-list.files(path,full.names=TRUE)
  manifest<-list(schema_version=4L,analysis_id=config$analysis_id,run_id=basename(path),mode=mode,
    created_utc=format(Sys.time(),tz="UTC",usetz=TRUE),estimation_sources=bmi_hash_files(bmi_estimation_files()),
    files=as.list(setNames(vapply(files,tri_sha256,character(1)),basename(files))),
    source_status=if(mode=="fixture")"artificial_only"else receipt$source_status,
    analysis_completed=nrow(a$model_registry)>0,numerically_reviewed=FALSE,scientifically_reviewed=FALSE,
    private_aggregate_warning="Exact rare counts and linked tables remain protected research artifacts",
    aggregate_only=TRUE)
  jsonlite::write_json(manifest,file.path(path,"bundle_manifest.json"),auto_unbox=TRUE,pretty=TRUE,digits=NA)
  Sys.chmod(list.files(path,full.names=TRUE),"0600")
  invisible(path)
}
bmi_read_bundle <- function(path,check_sources=TRUE) {
  mf<-file.path(path,"bundle_manifest.json");if(!file.exists(mf))stop("Missing bundle manifest")
  m<-jsonlite::read_json(mf,simplifyVector=FALSE)
  if(!identical(m$schema_version,4L)||!identical(m$analysis_id,"bmi_hypercapnia_curve_audit_v1"))stop("Superseded analysis; rerun under the current design")
  for(name in names(m$files)) {
    if(basename(name)!=name||!file.exists(file.path(path,name))||!identical(tri_sha256(file.path(path,name)),m$files[[name]]))stop("Bundle hash mismatch: ",name)
  }
  if(check_sources&&!identical(m$estimation_sources,bmi_hash_files(bmi_estimation_files())))stop("Estimation source/hash mismatch; create a new analysis run")
  a<-readRDS(file.path(path,"analysis.rds"));validate_analysis_bundle(a)
  list(analysis=a,manifest=m,path=normalizePath(path),config=jsonlite::read_json(file.path(path,"analysis_config.json"),simplifyVector=FALSE),receipt=jsonlite::read_json(file.path(path,"input_receipt.json"),simplifyVector=FALSE))
}
bmi_theme <- function() ggplot2::theme_bw(base_size=10,base_family="sans")+
  ggplot2::theme(panel.grid.minor=ggplot2::element_blank(),panel.grid.major.x=ggplot2::element_blank(),
    plot.title=ggplot2::element_text(size=10,face="bold"),plot.subtitle=ggplot2::element_text(size=9),
    strip.text=ggplot2::element_text(size=9),axis.text=ggplot2::element_text(size=9,colour="black"),axis.title=ggplot2::element_text(size=9),legend.text=ggplot2::element_text(size=9),
    plot.margin=grid::unit(c(3,3,3,3),"mm"),legend.position="bottom")
bmi_outcome_label <- function(o) unname(c(icd="Documented ICD composite",abg="Arterial PCO2 >=45 mm Hg",any_gas="Arterial >=45 or venous >=50 mm Hg")[o])
bmi_empty_plot <- function(title,reason) ggplot2::ggplot()+ggplot2::annotate("text",x=0,y=0,label=paste(strwrap(reason,24),collapse="\n"),size=3.3)+ggplot2::labs(title=paste(strwrap(title,24),collapse="\n"))+ggplot2::theme_void(base_size=10)+ggplot2::theme(plot.margin=grid::unit(rep(4,4),"mm"))
bmi_curve_plot <- function(d,title,observation=FALSE) {
  good<-d[!is.na(d$probability),,drop=FALSE]
  if(!nrow(good))return(bmi_empty_plot(title,if(nrow(d))paste(unique(d$status),collapse="; ")else"Not assessed"))
  d<-good;d$segment<-cumsum(c(TRUE,head(d$supported,-1)!=tail(d$supported,-1)))
  ggplot2::ggplot(d,ggplot2::aes(bmi,probability))+
    ggplot2::geom_ribbon(ggplot2::aes(ymin=conf_low,ymax=conf_high),fill="grey80")+
    ggplot2::geom_line(ggplot2::aes(linetype=supported,group=segment),linewidth=.6)+
    ggplot2::scale_linetype_manual(values=c(`TRUE`="solid",`FALSE`="dashed"),guide="none")+
    ggplot2::scale_y_continuous(labels=function(x)paste0(format(100*x,trim=TRUE,digits=3),"%"),limits=c(0,1))+
    ggplot2::labs(title=paste(strwrap(title,20),collapse="\n"),subtitle=paste0("Model N=",format(d$n_model[1],big.mark=","),"\nReference ",d$reference_id[1]," N=",format(d$n_reference[1],big.mark=",")),
      x="BMI (kg/m2)",y=if(observation)"Usable/known evidence"else"Modeled probability")+bmi_theme()
}
bmi_frequency_plot <- function(a,reference_id,title,config) {
  # The four gas patterns are mutually exclusive, unlike ABG and combined samples.
  ev<-a$evidence_by_bmi;ev<-ev[ev$population_id==reference_id & ev$window=="encounter",,drop=FALSE]
  if(!nrow(ev))return(bmi_empty_plot(title,"No reference distribution"))
  abg<-ev[ev$outcome_id=="abg",];vbg<-ev[ev$outcome_id=="vbg",];any<-ev[ev$outcome_id=="any_gas",]
  # Pattern-specific bin counts are persisted separately by the analysis, never recovered from overlapping marginals.
  z<-a$distribution_bins[a$distribution_bins$variable_id=="gas_pattern_bmi" & a$distribution_bins$population_id==reference_id,,drop=FALSE]
  if(!nrow(z))return(bmi_empty_plot(title,"Pattern-specific BMI bins unavailable"))
  z$pattern<-factor(z$pattern,levels=c("abg_only","vbg_only","both","neither"))
  ggplot2::ggplot(z,ggplot2::aes(lower+config$bmi_bin_width/2,100*mass,fill=pattern))+
    ggplot2::geom_col(width=config$bmi_bin_width,colour="white",linewidth=.15)+
    ggplot2::scale_fill_manual(values=c("grey20","grey45","grey70","grey93"),labels=c("ABG only","VBG only","Both","Neither"),drop=FALSE)+
    ggplot2::guides(fill=ggplot2::guide_legend(nrow=2,byrow=TRUE))+
    ggplot2::labs(title="BMI frequency",subtitle=paste("Reference",reference_id,"\nDisjoint usable-gas patterns"),x="BMI (kg/m2)",y="Reference patients (%)",fill=NULL)+bmi_theme()
}
bmi_flow_plot <- function(a,detailed=FALSE) {
  ids<-if(detailed)a$cohort_nodes$population_id else c("source_records","encounter_versions","confirmed_eligible_encounters","excluded_encounters","uncertain_encounters","n_frame_patients","Q","n_index_unresolved","C","missing_adjustment","C_icd","M_abg","M_any_gas")
  n<-a$cohort_nodes[match(ids,a$cohort_nodes$population_id),,drop=FALSE]
  if(!detailed) {
    n$x<-c(2,2,2,1,3,2,2,3,2,1,2,1,3);n$y<-c(9,8,7,7,7,6,5,5,4,4,3,2,2)
  } else {n$x<-1;n$y<-rev(seq_len(nrow(n)))}
  n$text<-paste(vapply(n$label,function(z)paste(strwrap(gsub("_"," ",z),24),collapse="\n"),character(1)),
    paste0("N=",ifelse(is.na(n$n),"unavailable",format(n$n,big.mark=",",trim=TRUE))),n$grain,sep="\n")
  e<-a$cohort_edges[a$cohort_edges$from %in% n$population_id & a$cohort_edges$to %in% n$population_id,,drop=FALSE]
  e$x<-n$x[match(e$from,n$population_id)];e$y<-n$y[match(e$from,n$population_id)]-.28
  e$xend<-n$x[match(e$to,n$population_id)];e$yend<-n$y[match(e$to,n$population_id)]+.28
  if(detailed){e$x<-rep(1.35,nrow(e));e$xend<-rep(1.35,nrow(e));e$y<-n$y[match(e$from,n$population_id)];e$yend<-n$y[match(e$to,n$population_id)]}
  connectors<-if(detailed)ggplot2::geom_curve(data=e,ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),curvature=.32,inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)else
    ggplot2::geom_segment(data=e,ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)
  branch_stems<-NULL
  if(!detailed){
    special<-e$from=="C" & e$to %in% c("M_abg","M_any_gas")
    if(any(special)){
      branches<-e[special,];branches$x<-branches$xend;branches$y<-3.5
      connectors<-ggplot2::geom_segment(data=rbind(e[!special,],branches),ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)
      stems<-data.frame(x=c(2,2,2),y=c(3.72,3.5,3.5),xend=c(2,1,3),yend=c(3.5,3.5,3.5))
      branch_stems<-ggplot2::geom_segment(data=stems,ggplot2::aes(x=x,y=y,xend=xend,yend=yend),inherit.aes=FALSE,colour="grey40",linetype="dashed")
    }
  }
  ggplot2::ggplot(n,ggplot2::aes(x,y))+connectors+branch_stems+
    ggplot2::geom_label(ggplot2::aes(label=text),size=3.2,lineheight=.95,label.padding=grid::unit(2,"mm"),linewidth=.3)+
    ggplot2::scale_x_continuous(limits=if(detailed)c(0,2)else c(.35,3.65))+
    ggplot2::scale_y_continuous(expand=ggplot2::expansion(add=.6))+
    ggplot2::labs(title="Observational cohort construction",subtitle="Parallel model branches overlap; counts come from the cohort ledger")+
    ggplot2::theme_void(base_size=10)+ggplot2::theme(plot.title=ggplot2::element_text(face="bold",size=12),plot.subtitle=ggplot2::element_text(size=9))
}
bmi_draw_grid <- function(plots,ncol=3,title="",subtitle="") {
  grid::grid.newpage();grid::grid.text(title,x=.02,y=.98,just=c("left","top"),gp=grid::gpar(fontsize=12,fontface="bold"))
  grid::grid.text(subtitle,x=.02,y=.945,just=c("left","top"),gp=grid::gpar(fontsize=9))
  nr<-ceiling(length(plots)/ncol)
  grid::pushViewport(grid::viewport(y=.45,height=.86,layout=grid::grid.layout(nr,ncol)))
  grobs<-lapply(plots,ggplot2::ggplotGrob)
  counts<-vapply(grobs,function(g)length(g$widths),integer(1));common<-which(counts==max(counts))
  if(length(common)>1){widths<-do.call(grid::unit.pmax,lapply(grobs[common],`[[`,"widths"));for(i in common)grobs[[i]]$widths<-widths}
  # Align panel top/bottom as well as widths; legends and subtitles cannot shift data rows.
  for(row in seq_len(nr)) {
    ix<-which(ceiling(seq_along(grobs)/ncol)==row)
    if(length(ix)<2)next
    top<-bottom<-list()
    for(j in ix){g<-grobs[[j]];panel<-g$layout[grepl("^panel",g$layout$name),,drop=FALSE];top[[as.character(j)]]<-sum(g$heights[seq_len(min(panel$t)-1)]);bottom[[as.character(j)]]<-sum(g$heights[seq(max(panel$b)+1,length(g$heights))])}
    maxtop<-do.call(grid::unit.pmax,top);maxbottom<-do.call(grid::unit.pmax,bottom)
    for(j in ix){g<-grobs[[j]];g<-gtable::gtable_add_rows(g,maxtop-top[[as.character(j)]],pos=0);g<-gtable::gtable_add_rows(g,maxbottom-bottom[[as.character(j)]],pos=-1);grobs[[j]]<-g}
  }
  for(i in seq_along(grobs)){grid::pushViewport(grid::viewport(layout.pos.row=ceiling(i/ncol),layout.pos.col=(i-1)%%ncol+1));grid::grid.draw(grobs[[i]]);grid::popViewport()}
  grid::popViewport()
}
bmi_export <- function(draw,stem,width_mm=190,height_mm=210,formats=c("pdf","svg","png","jpg")) {
  dir.create(dirname(stem),recursive=TRUE,showWarnings=FALSE)
  for(ext in formats) {
    file<-paste0(stem,".",ext)
    if(ext=="pdf")grDevices::cairo_pdf(file,width=width_mm/25.4,height=height_mm/25.4,family="sans")
    if(ext=="svg")grDevices::svg(file,width=width_mm/25.4,height=height_mm/25.4,family="sans")
    if(ext=="png")grDevices::png(file,width=width_mm,height=height_mm,units="mm",res=300,type="cairo")
    if(ext=="jpg")grDevices::jpeg(file,width=width_mm,height=height_mm,units="mm",res=300,quality=95,type="cairo")
    warning_messages<-character()
    tryCatch(withCallingHandlers(draw(),warning=function(w){warning_messages<<-c(warning_messages,conditionMessage(w));invokeRestart("muffleWarning")}),finally=grDevices::dev.off())
    if(length(warning_messages))utils::write.table(data.frame(export=basename(file),warning=warning_messages),paste0(stem,"-warnings.csv"),sep=",",row.names=FALSE,col.names=!file.exists(paste0(stem,"-warnings.csv")),append=file.exists(paste0(stem,"-warnings.csv")),qmethod="double")
  }
}
bmi_export_figures <- function(bundle,output) {
  a<-bundle$analysis;config<-bundle$config;dir.create(output,recursive=TRUE,showWarnings=FALSE);manifest<-list();captions<-list();atlas_index<-list()
  add<-function(id,draw,height,caption,kind="scientific figure") {
    if(bundle$manifest$mode=="fixture") {
      original_draw<-draw
      draw<-local({original_draw<-original_draw;function(){original_draw();grid::grid.text("ARTIFICIAL DATA ONLY",x=.985,y=.995,just=c("right","top"),gp=grid::gpar(fontsize=9,col="grey25"))}})
    }
    stem<-file.path(output,id);formats<-if(grepl("^F[0345]",id))c("pdf","svg","png")else c("pdf","svg","png","jpg");bmi_export(draw,stem,height_mm=height,formats=formats)
    manifest[[id]]<<-data.frame(figure_id=id,panel_id="all",file_path=paste0(stem,".png"),export_paths=paste(paste0(stem,paste0(".",formats)),collapse=";"),source_path="R/reporting.R",source_paths="R/reporting.R;R/standardization.R",figure_type=kind,intended_use="private manuscript/audit review",target_requirements="190 mm; >=9 pt; grayscale; identical saved aggregates",width_px=round(190/25.4*300),height_px=round(height/25.4*300),dpi_x=300,dpi_y=300,color_mode="grayscale-safe",vector_status="SVG/PDF masters",legend_status="caption and alt text saved",qc_status="exported; visual inspection pending",blockers="",notes="No numerical quantity copied manually")
    captions[[id]]<<-data.frame(figure_id=id,caption=caption,alt_text=caption,source_tables=if(grepl("F1",id))"probability_curves;observation_curves;distribution_bins"else if(grepl("F2",id))"policy_totals;policy_contributions"else if(grepl("F3",id))"variable_summary;category_counts;distribution_bins;distribution_curves"else if(grepl("F4",id))"model_registry;coefficients;coefficient_covariance;model_fit_diagnostics;model_residual_bins;model_influence_summary;model_support"else if(grepl("F5",id))"probability_curves;policy_totals;sensitivity_results;timing_audit"else"cohort_nodes;cohort_edges")
  }
  if(nrow(a$model_registry)) {
    outcomes<-c("icd","abg","any_gas");p<-obs<-freq<-list()
    for(o in outcomes) {
      ref<-if(o=="icd")"C_icd"else"C"
      p[[o]]<-bmi_curve_plot(a$probability_curves[a$probability_curves$model_id==paste(o,"encounter/spline",sep="/"),],bmi_outcome_label(o))
      obs[[o]]<-bmi_observation_plot(a,o)
      freq[[o]]<-bmi_frequency_plot(a,ref,"BMI frequency and usable gases",config)
      limits<-range(a$distribution_bins$lower[a$distribution_bins$variable_id=="gas_pattern_bmi"],a$distribution_bins$upper[a$distribution_bins$variable_id=="gas_pattern_bmi"],na.rm=TRUE)
      for(name in c("p","obs","freq")) {obj<-get(name);if(is.data.frame(obj[[o]]$data)&&nrow(obj[[o]]$data))obj[[o]]<-obj[[o]]+ggplot2::coord_cartesian(xlim=limits);assign(name,obj)}
    }
    caption<-paste("F1. BMI relationship, usable-evidence observation and original-BMI frequencies in the original selected encounter cohort. First qualifying adult 2022 ED/inpatient BMI >=30 encounter, before gas/completeness selection. BMI is body mass index (kg/m2); ABG and VBG are arterial and venous blood gases; PCO2 is in mm Hg. C is the covariate-complete reference and C_icd has established diagnosis capture. Outcome models adjust for age, sex, race/ethnicity and region with a fixed natural BMI spline. Gas curves reference C; ICD references C_icd (known capture). Observation models reference C. Bands are pointwise conditional model-based 95% intervals; line type identifies outcome extrapolation beyond training BMI support. When an observation model is unavailable, open points show raw M/N with Wilson 95% intervals and its failure is named. Four frequency components are disjoint. Combined negatives concern available specimens. ICD includes E66.2. No incidence or causal-prevention interpretation.")
    add("F1-A",function()bmi_draw_grid(c(p,obs,freq),3,"BMI and documented hypercapnia probability","Outcome relationship, observation and population support"),255,caption)
    add("F1-B",function()bmi_draw_grid(unlist(lapply(outcomes,function(o)list(p[[o]],obs[[o]],freq[[o]])),recursive=FALSE),3,"BMI and documented hypercapnia probability","Read each outcome across: probability | observation | BMI frequency"),255,caption)
    cplots<-list()
    for(o in outcomes){cplots[[length(cplots)+1L]]<-bmi_relationship_observation_plot(a,o,config);cplots[[length(cplots)+1L]]<-freq[[o]]}
    add("F1-C",function()bmi_draw_grid(cplots,2,"BMI relationship and evidence availability","Within each outcome: paired probability quantities | BMI frequency"),255,paste(caption,"Candidate C: outcome and availability share a 0–1 probability scale. Solid outcome segments are supported and dotted segments extrapolate; availability uses long dashes with its interval bounds. Raw availability has open points/Wilson bars when its model is unavailable. These are different quantities, with their named references; their separation is not an effect estimate."))
    f2<-list()
    for(o in outcomes) {
      z<-a$policy_contributions;z<-z[z$model_id==paste(o,"encounter/spline",sep="/") & z$reference_id==if(o=="icd")"C_icd"else"C",,drop=FALSE]
      z<-z[z$method==if(o=="icd")"observed"else"mar",,drop=FALSE];z<-z[z$policy_id=="bmi_gt30_minus1_v1",,drop=FALSE]
      if(!nrow(z)){f2[[length(f2)+1L]]<-bmi_empty_plot(bmi_outcome_label(o),"Scenario unavailable");next}
      label<-a$policy_totals;label<-label[label$model_id==z$model_id[1]&label$reference_id==z$reference_id[1]&label$method==z$method[1]&label$policy_id==z$policy_id[1],]
      top<-bmi_bind(list(data.frame(bmi=z$bin_low+2.5,p=z$mean_observed,scenario="Observed BMI"),data.frame(bmi=z$bin_low+2.5,p=z$mean_shifted,scenario="Shifted BMI")))
      f2[[length(f2)+1L]]<-ggplot2::ggplot(top,ggplot2::aes(bmi,p,linetype=scenario,shape=scenario))+ggplot2::geom_line(linewidth=.5,na.rm=TRUE)+ggplot2::geom_point(size=1.7,na.rm=TRUE)+
        ggplot2::labs(title=bmi_outcome_label(o),subtitle=paste0("Model/reference N ",label$n_model,"/",label$n_reference,"; shifted ",sprintf("%.1f%%",label$pct_shifted),"\np0=",bmi_number(label$p_observed,4),"; pg=",bmi_number(label$p_shifted,4)),x="Original BMI (kg/m2)",y="Mean probability",linetype=NULL,shape=NULL)+bmi_theme()
      f2[[length(f2)+1L]]<-ggplot2::ggplot(z,ggplot2::aes(bin_low+2.5,contribution_per1000))+ggplot2::geom_hline(yintercept=0,colour="grey45")+ggplot2::geom_col(width=4,fill="grey35")+ggplot2::geom_errorbar(ggplot2::aes(ymin=conf_low_per1000,ymax=conf_high_per1000),width=1)+
        ggplot2::labs(title=paste0("Total change ",bmi_number(label$difference_per1000,3)," /1,000"),subtitle=paste0("PIF ",paste0(bmi_number(100*label$PIF,3),"%")," (",bmi_number(100*label$PIF_low,3),", ",bmi_number(100*label$PIF_high,3),")"),x="Original BMI (kg/m2)",y="Contribution /1,000 reference")+bmi_theme()
    }
    add("F2",function()bmi_draw_grid(f2,2,"One-unit BMI reduction above 30","Paired predictions and signed original-BMI contributions"),245,
      "F2. Secondary one-unit BMI scenario in the original selected encounter cohort. BMI is body mass index (kg/m2); p0 and pg are average predictions under observed and shifted BMI. PIF is the model-standardized potential impact fraction. Adjustment includes age, sex, race/ethnicity and region with a fixed natural BMI spline. Original covariates, indexes and reference membership are fixed. Gas C summaries are conditional MAR projections; ICD uses known capture. Original-band contributions sum exactly to the absolute change; their full covariance reproduces total variance. Each outcome uses its displayed vertical scale; compare printed values across outcomes. Negative contributions remain negative. Bands reflect conditional model uncertainty and omit missingness/model/source assumptions.")
  }
  add("F0-main",function()print(bmi_flow_plot(a)),230,"F0. Observational cohort flow. Ledger counts identify grain; eligibility and adjustment branches are partitions at their declared grain. Matched outcome samples overlap. Unresolved earlier membership and ties never advance to a later visit.","observational flow")
  # Detailed flow uses readable pages and a complete tabular equivalent in the audit.
  chunks<-split(seq_len(nrow(a$cohort_nodes)),ceiling(seq_len(nrow(a$cohort_nodes))/9))
  for(i in seq_along(chunks)) {
    part<-a;part$cohort_nodes<-a$cohort_nodes[chunks[[i]],,drop=FALSE]
    add(paste0("F0-detail-",i),local({part<-part;function()print(bmi_flow_plot(part,TRUE))}),260,"Detailed ledger nodes and within-page edges; cross-page relationships appear in the full cohort_edges table.","observational flow")
  }
  # F3: all registered numeric/category variables at every profiled stage.
  histogram<-a$distribution_bins[a$distribution_bins$variable_id!="gas_pattern_bmi",,drop=FALSE]
  for(v in unique(c(histogram$variable_id,a$category_counts$variable_id))) {
    unit<-a$variable_dictionary$unit[match(v,a$variable_dictionary$variable_id)]
    axis_label<-if(length(unit)&&!is.na(unit)&&nzchar(unit))paste0(v," (",unit,")")else v
    hist<-histogram[histogram$variable_id==v,,drop=FALSE];catdata<-a$category_counts[a$category_counts$variable_id==v & !is.na(a$category_counts$n_reference) & a$category_counts$n_reference>0,,drop=FALSE]
    original<-if(nrow(hist))hist else catdata
    if(!nrow(original))next
    shared<-bmi_unique_plot_profiles(original,setdiff(names(original),c("population_id","pattern")))
    index<-shared$index;index$variable_id<-v;index$kind<-if(nrow(hist))"histogram"else"categories"
    if(nrow(hist))hist<-shared$data else catdata<-shared$data
    reps<-unique(shared$data$population_id);index$figure_id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",ceiling(match(index$representative_id,reps)/6));atlas_index[[length(atlas_index)+1L]]<-index
    ids<-unique(c(hist$population_id,catdata$population_id));chunks<-split(ids,ceiling(seq_along(ids)/6))
    for(j in seq_along(chunks)) {
      stages<-chunks[[j]];id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",j)
      if(nrow(hist)) {
        h<-hist[hist$population_id %in% stages,,drop=FALSE]
        chart<-ggplot2::ggplot(h,ggplot2::aes((lower+upper)/2,100*mass))+ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey40")+
          ggplot2::facet_wrap(~population_id,ncol=2,scales="free_y",labeller=ggplot2::label_wrap_gen(30))+ggplot2::labs(title=paste("Full-range",v,"distributions"),subtitle="Named population (%); identical plot profiles shared in atlas index",x=axis_label,y="Population (%)")+bmi_theme()
      }else{
        h<-catdata[catdata$population_id %in% stages,,drop=FALSE]
        chart<-ggplot2::ggplot(h,ggplot2::aes(level,percent_all))+ggplot2::geom_col(fill="grey40")+ggplot2::coord_flip()+
          ggplot2::facet_wrap(~population_id,ncol=2,labeller=ggplot2::label_wrap_gen(30))+ggplot2::labs(title=paste(v,"complete category profiles"),subtitle="All levels/missingness; identical plot profiles shared in atlas index",x=NULL,y="Population (%)")+bmi_theme()
      }
      add(id,local({chart<-chart;function()print(chart)}),250,paste("F3. Complete",v,"stage atlas; each facet names its denominator. All categories, tails and missingness are retained in the matching aggregate tables."),"descriptive atlas")
    }
    curves<-a$distribution_curves[a$distribution_curves$variable_id==v,,drop=FALSE]
    if(nrow(curves))for(kind in unique(curves$kind)) {
      kinddata<-curves[curves$kind==kind,,drop=FALSE]
      shared<-bmi_unique_plot_profiles(kinddata,setdiff(names(kinddata),"population_id"));kinddata<-shared$data
      index<-shared$index;index$variable_id<-v;index$kind<-kind;reps<-unique(kinddata$population_id)
      index$figure_id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",kind,"-",ceiling(match(index$representative_id,reps)/6));atlas_index[[length(atlas_index)+1L]]<-index
      curvechunks<-split(reps,ceiling(seq_along(reps)/6))
      for(j in seq_along(curvechunks)) {
        z<-kinddata[kinddata$population_id %in% curvechunks[[j]],,drop=FALSE];if(!nrow(z))next
        chart<-ggplot2::ggplot(z,ggplot2::aes(x,y))+ggplot2::geom_line(linewidth=.5)+ggplot2::facet_wrap(~population_id,ncol=2,labeller=ggplot2::label_wrap_gen(30))+
          ggplot2::labs(title=paste(v,kind),subtitle=if(kind=="kde")"Gaussian; shared source bandwidth; weighted by observed population mass"else"Observed-value ECDF on persisted common grid",x=axis_label,y=kind)+bmi_theme()
        add(paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",kind,"-",j),local({chart<-chart;function()print(chart)}),250,paste("F3.",v,kind,"across named stages; full coordinate export and normalization metadata in distribution_curves."),"descriptive atlas")
      }
    }
  }
  # F4: model-specific observed/fitted and residual distributions, including failed positions.
  if(nrow(a$model_registry))for(i in seq_len(nrow(a$model_registry))) {
    id<-a$model_registry$model_id[i];d<-a$model_residual_bins
    if(nrow(d))d<-d[d$model_id==id,,drop=FALSE]
    if(nrow(d)) {
      z<-d[d$diagnostic %in% c("BMI","fitted_probability"),,drop=FALSE]
      z$position<-suppressWarnings(as.numeric(z$group))
      chart<-ggplot2::ggplot(z,ggplot2::aes(position,observed))+ggplot2::geom_point(shape=1,size=2)+ggplot2::geom_line(ggplot2::aes(y=fitted),linewidth=.6)+
        ggplot2::facet_wrap(~diagnostic,scales="free_x")+ggplot2::labs(title=paste(strwrap(paste("Model audit:",id),55),collapse="\n"),subtitle="Open points: observed; line: fitted. Apparent training-sample summaries.",x="BMI band (kg/m2) or fitted-probability group",y="Probability")+bmi_theme()
      residual<-d[grepl("^hist_",d$diagnostic),,drop=FALSE]
      rp<-ggplot2::ggplot(residual,ggplot2::aes((lower+upper)/2,n))+ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey40")+
        ggplot2::facet_wrap(~diagnostic,ncol=1,scales="free")+ggplot2::labs(title="Residual and fitted-probability distributions",x="Persisted bin",y="Model cases")+bmi_theme()
      draw<-local({chart<-chart;rp<-rp;function()bmi_draw_grid(list(chart,rp),1,"Complete model diagnostics","Coefficients, covariance and sample accounting appear in the audit tables")})
    }else draw<-local({reason<-a$model_registry$failure_reason[i];id<-id;function()print(bmi_empty_plot(id,reason))})
    add(paste0("F4-",i),draw,240,paste("F4. Model",id,"apparent fit and full-sample diagnostics. Influence flags do not exclude observations. Failure positions remain visible."),"model diagnostics")
  }
  if(nrow(a$model_registry)) {
    for(o in c("abg","any_gas")) {
      z<-a$probability_curves[a$probability_curves$outcome_id==o & a$probability_curves$family %in% c("primary","timing"),,drop=FALSE]
      plots<-lapply(c("encounter","index_calendar_day"),function(w)bmi_curve_plot(z[z$window==w,,drop=FALSE],paste(o,w)))
      add(paste0("F5-timing-",o),local({plots<-plots;function()bmi_draw_grid(plots,1,"Fixed-index timing comparison","Identical selected indexes; window-specific observed training samples")}),220,"F5. Encounter versus start-calendar-day curves reuse the same original indexes and fixed spline basis. Pending source or failed models are displayed explicitly.","sensitivity")
    }
    for(pair in c("abg","any_gas")) {
      z<-a$probability_curves[a$probability_curves$model_id %in% paste("matched",pair,c("icd",pair),sep="/"),,drop=FALSE]
      plots<-lapply(c("icd",pair),function(o)bmi_curve_plot(z[z$outcome_id==o,,drop=FALSE],bmi_outcome_label(o)))
      add(paste0("F5-matched-",pair),local({plots<-plots;function()bmi_draw_grid(plots,1,"Matched definition comparison","Identical patients within each pair; no independent-model difference test")}),220,"F5. Matched ICD/gas curves use identical training and reference patients within the indicated pair. Arterial and combined pairs may have different membership.","sensitivity")
    }
    s<-a$sensitivity_results
    if(nrow(s)) {
      z<-s[s$status=="estimated" & s$window=="encounter",,drop=FALSE]
      if(nrow(z)) {
        z$gradient<-factor(z$gradient_multiplier)
        chart<-ggplot2::ggplot(z,ggplot2::aes(r,100*PIF,linetype=gradient,shape=gradient))+ggplot2::geom_hline(yintercept=0,colour="grey60")+ggplot2::geom_line()+ggplot2::geom_point()+ggplot2::scale_x_log10(breaks=c(.25,.5,1,2,4))+
          ggplot2::facet_wrap(~outcome_id,ncol=1)+ggplot2::labs(title="Fixed-observation-stratum sensitivity",subtitle="Assumed missing/observed odds at BMI 40 and gradient multipliers",x="Assumed odds ratio at BMI 40",y="Model-standardized PIF (%)",linetype="Gradient",shape="Gradient")+bmi_theme()
        add("F5-MNAR",local({chart<-chart;function()print(chart)}),210,"F5. MNAR assumption scenarios keep factual observation membership fixed and evaluate offsets at shifted BMI. The r=1, gradient=1 anchor reproduces MAR; scenario variation is not a sampling interval.","sensitivity")
      }
    }
  }

  utils::write.csv(bmi_bind(atlas_index),file.path(output,"atlas-index.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(manifest),file.path(output,"figure-qc-manifest.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(captions),file.path(output,"captions.csv"),row.names=FALSE)
  gallery<-c("<!doctype html><meta charset='utf-8'><title>Figure comparison</title><style>body{font:16px sans-serif;max-width:1200px;margin:auto}img{width:100%;height:auto}article{margin:2em 0}</style><h1>Figure alternatives</h1>",if(bundle$manifest$mode=="fixture")"<p>ARTIFICIAL DATA ONLY</p>")
  for(id in names(manifest))gallery<-c(gallery,paste0("<article><h2>",id,"</h2><a href='",id,".png'><img src='",id,".png' alt='",id," full-size review'></a><p>",captions[[id]]$caption,"</p><p>Aggregate sources: ",paste(vapply(strsplit(captions[[id]]$source_tables,";",fixed=TRUE)[[1]],function(t)paste0("<a href=\"../../../",t,".csv\">",t,"</a>"),character(1)),collapse=", "),"</p></article>"))
  writeLines(gallery,file.path(output,"gallery.html"))
  jsonlite::write_json(list(bundle_sha256=tri_sha256(file.path(bundle$path,"analysis.rds")),source_tables=lapply(a[c("probability_curves","observation_curves","policy_totals","policy_contributions")],function(d)digest::digest(d,algo="sha256")),
    candidates=c("F1-A","F1-B","F1-C"),same_saved_values=TRUE,visual_inspection="pending"),file.path(output,"figure-data-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
  invisible(bmi_bind(manifest))
}
bmi_report_table <- function(d,caption,keys=character()) {
  if(!ncol(d)){cat("\n*",caption,": unavailable/not applicable in this run.*\n\n",sep="");return(invisible(NULL))}
  if(!nrow(d)){cat("\n*",caption,": no rows (empty population or unavailable module).*\n\n",sep="");return(invisible(NULL))}
  review<-Sys.getenv("BMI_REVIEW_DIR");report<-Sys.getenv("BMI_REPORT_ID")
  if(nzchar(review)&&nzchar(report)) {
    path<-file.path(review,paste0(report,"-table-coverage.csv"))
    utils::write.table(data.frame(report=report,format=if(knitr::is_latex_output())"pdf"else"html",caption=caption,rows=nrow(d),columns=ncol(d)),path,sep=",",row.names=FALSE,col.names=!file.exists(path),append=file.exists(path),qmethod="double")
  }
  # Every row is printed. Wide tables split columns with repeated keys, never head().
  keys<-intersect(keys,names(d));other<-setdiff(names(d),keys);chunks<-split(other,ceiling(seq_along(other)/max(1,5-length(keys))))
  if(!length(chunks))chunks<-list(character())
  for(i in seq_along(chunks)) {
    x<-d[unique(c(keys,chunks[[i]]))]
    for(v in names(x)) {
      if(is.numeric(x[[v]]))x[[v]]<-bmi_number(x[[v]],digits=7)else{
        x[[v]]<-ifelse(is.na(x[[v]]),"unavailable",as.character(x[[v]]));x[[v]]<-gsub("([_/])","\\1 ",x[[v]]);x[[v]]<-gsub("([^[:space:]]{14})","\\1 ",x[[v]],perl=TRUE)
      }
    }
    names(x)<-gsub("([_/])","\\1 ",names(x))
    label<-paste0(caption,if(length(chunks)>1)paste0(" — columns ",i,"/",length(chunks))else"")
    if(knitr::is_latex_output()) {
      out<-knitr::kable(x,format="latex",booktabs=TRUE,longtable=TRUE,caption=bmi_latex_escape(label),label=NA,row.names=FALSE,linesep="",escape=TRUE)
      # Paragraph columns wrap long labels instead of extending beyond the PDF page.
      spec<-paste(rep(paste0(">{\\raggedright\\arraybackslash}p{",format(18.4/ncol(x)-.45,digits=3),"cm}"),ncol(x)),collapse="")
      out<-sub("\\\\begin\\{longtable\\}\\[[^]]*\\]\\{[^}]*\\}",paste0("\\\\begin{longtable}{",gsub("\\","\\\\",spec,fixed=TRUE),"}"),out)
      out<-sub("\\\\begin\\{longtable\\}\\{[lrc]+\\}",paste0("\\\\begin{longtable}{",gsub("\\","\\\\",spec,fixed=TRUE),"}"),out)
      # booktabs otherwise interprets a first row such as (Intercept) as a trim option.
      # Repeat the actual column header on continuation pages of the full audit.
      header<-strsplit(strsplit(out,"\\toprule\n",fixed=TRUE)[[1]][2],"\\midrule",fixed=TRUE)[[1]][1]
      parts<-strsplit(out,"\\midrule\n",fixed=TRUE)[[1]]
      out<-paste0(parts[1],"\\midrule\n\\endfirsthead\n\\toprule\n",header,"\\midrule\n\\endhead\n",paste(parts[-1],collapse="\\midrule\n"))
      out<-gsub("\\endhead\n(","\\endhead\n\\relax (",out,fixed=TRUE)
      cat("\n",out,"\n\n",sep="")
    }else cat(knitr::kable(x,format="html",caption=label,row.names=FALSE,table.attr='class="table bmi-audit-table"'),"\n\n")
  }
  invisible(NULL)
}
bmi_report_figure <- function(path,caption,width="100%") {
  if(file.exists(path)){cat("\n");print(knitr::include_graphics(path));cat("\n\n",caption,"\n\n",sep="")}
}
bmi_observation_plot <- function(a,outcome) {
  z<-a$observation_curves[a$observation_curves$model_id==paste("observation",outcome,"encounter",sep="/"),,drop=FALSE]
  if(nrow(z)&&any(!is.na(z$probability)))return(bmi_curve_plot(z,"Evidence availability",TRUE))
  d<-a$evidence_by_bmi;d<-d[d$population_id=="C"&d$window=="encounter"&d$outcome_id==outcome&d$status=="assessed",,drop=FALSE]
  if(!nrow(d))return(bmi_empty_plot("Evidence availability","Unassessed"))
  intervals<-t(vapply(seq_len(nrow(d)),function(i)bmi_wilson(d$M[i],d$N[i]),numeric(2)))
  d$low<-pmax(0,intervals[,1]);d$high<-pmin(1,intervals[,2])
  ggplot2::ggplot(d,ggplot2::aes((bin_low+bin_high)/2,observation))+ggplot2::geom_errorbar(ggplot2::aes(ymin=low,ymax=high),width=.7)+ggplot2::geom_point(shape=1,size=1.8)+
    ggplot2::scale_y_continuous(limits=c(0,1),labels=function(x)paste0(100*x,"%"))+
    ggplot2::labs(title="Evidence availability",subtitle=paste0("Model: ",if(nrow(z))z$status[1]else"unavailable","\nRaw M/N on C; Wilson 95% CI"),x="BMI (kg/m2)",y="Usable/known evidence")+bmi_theme()
}
# View-only sharing of identical plots; complete stage tables remain unchanged.
bmi_unique_plot_profiles <- function(d,fields) {
  ids<-unique(d$population_id);signatures<-vapply(ids,function(id){z<-d[d$population_id==id,fields,drop=FALSE];rownames(z)<-NULL;digest::digest(z,algo="sha256")},character(1))
  rep<-ids[match(signatures,signatures)]
  list(data=d[d$population_id %in% unique(rep),,drop=FALSE],index=data.frame(population_id=ids,representative_id=rep))
}
bmi_covariance_report <- function(d,caption,first,second,value) {
  if(!nrow(d))return(bmi_report_table(d,caption))
  rows<-unique(d[[first]]);cols<-unique(d[[second]])
  mat<-matrix(NA_real_,length(rows),length(cols),dimnames=list(rows,cols))
  mat[cbind(match(d[[first]],rows),match(d[[second]],cols))]<-d[[value]]
  x<-data.frame(term=rows,mat,check.names=FALSE)
  bmi_report_table(x,caption,keys="term")
}
bmi_grouped_report <- function(d,caption,groups) {
  if(!nrow(d))return(bmi_report_table(d,caption))
  groups<-intersect(groups,names(d));key<-do.call(paste,c(d[groups],sep=" | "))
  for(ix in split(seq_len(nrow(d)),factor(key,levels=unique(key)))) {
    cat("\n**",paste(paste(groups,as.character(d[ix[1],groups]),sep="="),collapse="; "),"**\n\n",sep="")
    x<-d[ix,setdiff(names(d),groups),drop=FALSE]
    # Fields entirely not-applicable are identified explicitly, not shown as estimated zeros.
    absent<-names(x)[vapply(x,function(v)all(is.na(v)),logical(1))]
    if(length(absent))cat("Not applicable/unavailable throughout this group: ",paste(absent,collapse=", "),".\n\n",sep="")
    x<-x[setdiff(names(x),absent)]
    bmi_report_table(x,caption,keys=intersect(c("population_id","bin_low","level"),names(x))[1])
  }
}

bmi_number <- function(x,digits=3) vapply(x,function(z) {
  if(is.na(z))return("unavailable")
  if(z==0)return("0")
  format(z,digits=digits,trim=TRUE,scientific=abs(z)<.001||abs(z)>=1e6)
},character(1))

bmi_latex_escape <- function(text) {
  replacements<-setNames(c("\\textbackslash{}","\\{","\\}","\\$","\\&","\\#","\\%","\\_","\\textasciitilde{}","\\textasciicircum{}"),c("\\","{","}","$","&","#","%","_","~","^"))
  vapply(text,function(x){chars<-strsplit(x,"",fixed=TRUE)[[1]];mapped<-unname(replacements[chars]);paste0(ifelse(is.na(mapped),chars,mapped),collapse="")},character(1))
}

bmi_relationship_observation_plot <- function(a,outcome,config) {
  d<-a$probability_curves[a$probability_curves$model_id==paste(outcome,"encounter/spline",sep="/"),,drop=FALSE]
  if(!nrow(d)||all(is.na(d$probability)))return(bmi_empty_plot(bmi_outcome_label(outcome),if(nrow(d))d$status[1]else"Unavailable"))
  d$segment<-cumsum(c(TRUE,head(d$supported,-1)!=tail(d$supported,-1)))
  d$quantity<-ifelse(d$supported,"Outcome fit","Outcome extrapolation")
  obs<-a$observation_curves[a$observation_curves$model_id==paste("observation",outcome,"encounter",sep="/"),,drop=FALSE]
  raw<-!nrow(obs)||all(is.na(obs$probability))
  if(raw){z<-a$evidence_by_bmi;z<-z[z$population_id=="C"&z$window=="encounter"&z$outcome_id==outcome&z$status=="assessed",,drop=FALSE]
    if(nrow(z)){ci<-t(vapply(seq_len(nrow(z)),function(i)bmi_wilson(z$M[i],z$N[i]),numeric(2)));obs<-data.frame(bmi=(z$bin_low+z$bin_high)/2,probability=z$observation,conf_low=pmax(0,ci[,1]),conf_high=pmin(1,ci[,2]),quantity="Evidence availability");nobs<-sum(z$N)}else obs<-data.frame()
  }else{obs$quantity<-"Evidence availability";nobs<-obs$n_reference[1]}
  plot<-ggplot2::ggplot(d,ggplot2::aes(bmi,probability))+
    ggplot2::geom_ribbon(ggplot2::aes(ymin=conf_low,ymax=conf_high),fill="grey82")+
    ggplot2::geom_line(ggplot2::aes(linetype=quantity,group=segment),linewidth=.65)
  if(nrow(obs)){
    plot<-plot+ggplot2::geom_line(data=obs,ggplot2::aes(linetype=quantity),linewidth=.55)
    if(raw)plot<-plot+ggplot2::geom_errorbar(data=obs,ggplot2::aes(ymin=conf_low,ymax=conf_high),width=.7,colour="grey45")+ggplot2::geom_point(data=obs,shape=1,size=1.5)
    else plot<-plot+ggplot2::geom_line(data=obs,ggplot2::aes(y=conf_low),linetype="longdash",colour="grey60",linewidth=.25)+ggplot2::geom_line(data=obs,ggplot2::aes(y=conf_high),linetype="longdash",colour="grey60",linewidth=.25)
  }
  limits<-range(a$distribution_bins$lower[a$distribution_bins$variable_id=="gas_pattern_bmi"],a$distribution_bins$upper[a$distribution_bins$variable_id=="gas_pattern_bmi"],na.rm=TRUE)
  plot+ggplot2::scale_linetype_manual(values=c("Outcome fit"="solid","Outcome extrapolation"="dotted","Evidence availability"="longdash"),breaks=c("Outcome fit","Outcome extrapolation","Evidence availability"))+
    ggplot2::scale_y_continuous(labels=function(x)paste0(100*x,"%"))+
    ggplot2::coord_cartesian(xlim=limits,ylim=c(0,1))+
    ggplot2::labs(title=paste(strwrap(bmi_outcome_label(outcome),28),collapse="\n"),subtitle=paste0("Outcome fit N=",d$n_model[1],"; ref ",d$reference_id[1]," N=",d$n_reference[1],"\nAvailability: ",if(raw)"raw"else"modeled"," C; N=",if(nrow(obs))nobs else"unavailable"),x="BMI (kg/m2)",y="Probability",linetype=NULL)+
    ggplot2::guides(linetype=ggplot2::guide_legend(nrow=2,byrow=TRUE))+bmi_theme()
}
