# Aggregate persistence, validation, code-generated figures and complete report tables.
validate_analysis_bundle <- function(a) {
  if(!setequal(names(a),bmi_table_names)||!all(vapply(a,is.data.frame,logical(1))))stop("Unexpected aggregate table contract")
  for(name in names(a)) {
    if("model_id" %in% names(a[[name]]) && nrow(a[[name]]) &&
       any(grepl("^obesity_only(_current)?::",a[[name]]$model_id)))stop("Obesity-only models are superseded; retain descriptive evidence only")
    if(any(grepl("^(patient_id|encounter_id|selected_row|index_date|encounter_date|individual_prediction)$",names(a[[name]]))))stop("Private row-level field in bundle: ",name)
    if(any(vapply(a[[name]],function(v)inherits(v,"Date")||inherits(v,"POSIXt"),logical(1))))stop("Direct dates in aggregate bundle")
  }
  if(nrow(a$policy_totals) && any(a$policy_totals$method!="observed")) stop("Superseded projection in observed-population bundle")
  if(nrow(a$sensitivity_results)||nrow(a$implied_missing_probabilities)) stop("Superseded missing-outcome scenarios")
  if(nrow(a$probability_curves)) {
    expected<-a$model_registry$training_population_id[match(a$probability_curves$model_id,a$model_registry$model_id)]
    if(anyNA(expected)||any(a$probability_curves$reference_id!=expected))stop("Curve reference differs from model-observed population")
  }
  if(nrow(a$policy_totals)) {
    expected<-a$model_registry$training_population_id[match(a$policy_totals$model_id,a$model_registry$model_id)]
    if(anyNA(expected)||any(a$policy_totals$reference_id!=expected))stop("Scenario reference differs from model-observed population")
  }
  bmi_validate_ledger(a)
  if(nrow(a$model_registry)) {
    if(nrow(a$expected_models) && !setequal(a$model_registry$model_id,a$expected_models$model_id))stop("Configured model registry mismatch")
    if(anyDuplicated(a$model_registry$model_id))stop("Model registry identity/count mismatch")
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
    keys<-c("model_id","reference_id","policy_id","method")
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
bmi_estimation_files <- function() c("R/analysis.R","R/input_contract.R","R/cohort_audit.R","R/bmi_models.R","R/standardization.R","R/rfs_analysis.R","config/bmi_hypercapnia_analysis.json","config/variable_dictionary.csv","config/common_index_source_policy.json","config/common_index_bmi_policy.json")
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
  manifest<-list(schema_version=7L,analysis_id=config$analysis_id,run_id=basename(path),mode=mode,
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
  if(!identical(m$schema_version,7L)||!identical(m$analysis_id,"bmi_hypercapnia_rfs_curve_audit_v2"))stop("Superseded analysis; rerun under the current design")
  for(name in names(m$files)) {
    if(basename(name)!=name||!file.exists(file.path(path,name))||!identical(tri_sha256(file.path(path,name)),m$files[[name]]))stop("Bundle hash mismatch: ",name)
  }
  if(check_sources&&!identical(m$estimation_sources,bmi_hash_files(bmi_estimation_files())))stop("Estimation source/hash mismatch; create a new analysis run")
  a<-readRDS(file.path(path,"analysis.rds"));validate_analysis_bundle(a)
  list(analysis=a,manifest=m,path=normalizePath(path),config=jsonlite::read_json(file.path(path,"analysis_config.json"),simplifyVector=FALSE),receipt=jsonlite::read_json(file.path(path,"input_receipt.json"),simplifyVector=FALSE))
}
bmi_theme <- function() ggplot2::theme_classic(base_size=10,base_family="sans")+
  ggplot2::theme(panel.grid.major.y=ggplot2::element_line(colour="grey91",linewidth=.25),
    plot.title=ggplot2::element_text(size=10.5,face="bold",margin=ggplot2::margin(b=4)),
    plot.subtitle=ggplot2::element_text(size=9.5,lineheight=1.1,margin=ggplot2::margin(b=6)),
    strip.background=ggplot2::element_blank(),strip.text=ggplot2::element_text(size=9.5,face="bold"),
    axis.text=ggplot2::element_text(size=9.5,colour="black"),axis.title=ggplot2::element_text(size=9.5),
    axis.line=ggplot2::element_line(linewidth=.3),axis.ticks=ggplot2::element_line(linewidth=.3),
    legend.text=ggplot2::element_text(size=9.5),legend.title=ggplot2::element_text(size=9.5),
    legend.key.width=grid::unit(6,"mm"),plot.margin=grid::unit(c(3,3,3,3),"mm"),legend.position="bottom")
bmi_outcome_label <- function(o) unname(c(icd="Documented ICD composite",abg="Arterial PCO₂ ≥45 mm Hg",any_gas="Arterial ≥45 or venous ≥50 mm Hg")[o])
bmi_outcome_short <- function(o) unname(c(abg="ABG",any_gas="ABG or VBG",icd="ICD composite")[o])
bmi_count_label <- function(model,reference) {
  fmt<-function(x)ifelse(is.na(x),"unavailable",format(x,big.mark=",",trim=TRUE,scientific=FALSE))
  if(!is.na(model)&&!is.na(reference)&&model==reference)paste0("Model/ref N = ",fmt(model))else paste0("Model N = ",fmt(model),"\nReference N = ",fmt(reference))
}
bmi_empty_plot <- function(title,reason) ggplot2::ggplot()+ggplot2::annotate("text",x=0,y=0,label=paste(strwrap(reason,24),collapse="\n"),size=3.3)+ggplot2::labs(title=paste(strwrap(title,24),collapse="\n"))+ggplot2::theme_void(base_size=10)+ggplot2::theme(plot.margin=grid::unit(rep(4,4),"mm"))
bmi_curve_plot <- function(d,title,observation=FALSE) {
  good<-d[!is.na(d$probability),,drop=FALSE]
  if(!nrow(good)) {
    counts<-if(nrow(d))paste0("Model N=",ifelse(is.na(d$n_model[1]),"unavailable",format(d$n_model[1],big.mark=",")),"\nReference N=",ifelse(is.na(d$n_reference[1]),"pending",format(d$n_reference[1],big.mark=",")))else"Model/reference N unavailable"
    return(bmi_empty_plot(title,if(nrow(d))paste(unique(d$status),collapse="; ")else"Not assessed")+
      ggplot2::labs(title=paste(strwrap(title,20),collapse="\n"),subtitle=counts)+
      ggplot2::theme(plot.title=ggplot2::element_text(size=10.5,face="bold"),plot.subtitle=ggplot2::element_text(size=9)))
  }
  d<-good
  d$display_support<-ifelse(!d$within_training_bmi_range,"extrapolated",ifelse(d$locally_sparse %in% TRUE,"sparse","supported"))
  d$segment<-cumsum(c(TRUE,head(d$display_support,-1)!=tail(d$display_support,-1)))
  ggplot2::ggplot(d,ggplot2::aes(bmi,probability))+
    ggplot2::geom_ribbon(ggplot2::aes(ymin=conf_low,ymax=conf_high),fill="grey82")+
    ggplot2::geom_line(ggplot2::aes(y=conf_low),colour="grey55",linewidth=.2)+
    ggplot2::geom_line(ggplot2::aes(y=conf_high),colour="grey55",linewidth=.2)+
    ggplot2::geom_line(ggplot2::aes(linetype=display_support,group=segment),linewidth=.6)+
    ggplot2::scale_linetype_manual(values=c(supported="solid",extrapolated="dashed",sparse="dotted"),guide="none")+
    ggplot2::scale_y_continuous(labels=function(x)paste0(100*x,"%"),limits=c(0,1),breaks=c(0,.5,1),expand=ggplot2::expansion(mult=c(.02,.03)))+
    ggplot2::labs(title=bmi_wrap(title,28),subtitle=bmi_count_label(d$n_model[1],d$n_reference[1]),
      x="BMI (kg/m²)",y=if(observation)if(all(d$outcome_id=="icd"))"Known capture"else"Usable evidence"else"Hypercapnia probability")+bmi_theme()
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
    ggplot2::scale_fill_manual(values=c("grey20","grey45","grey68","grey88"),labels=c("ABG only","VBG only","Both","Neither"),drop=FALSE)+
    ggplot2::guides(fill=ggplot2::guide_legend(nrow=2,byrow=TRUE))+
    ggplot2::scale_y_continuous(expand=ggplot2::expansion(mult=c(0,.08)))+
    ggplot2::labs(title="BMI distribution",subtitle=paste0("Complete adjustment: N = ",format(a$cohort_nodes$n[match(reference_id,a$cohort_nodes$population_id)],big.mark=","),"; mutually exclusive gas groups"),x="BMI (kg/m²)",y="Patients (%)",fill=NULL)+bmi_theme()
}
bmi_flow_plot <- function(a,detailed=FALSE) {
  ids<-if(detailed)a$cohort_nodes$population_id else c("source_records","encounter_versions","confirmed_eligible_encounters","excluded_encounters","uncertain_encounters","n_frame_patients","Q","n_index_unresolved","C","missing_adjustment","C_icd","C_abg_encounter","C_any_gas_encounter")
  n<-a$cohort_nodes[match(ids,a$cohort_nodes$population_id),,drop=FALSE]
  if(!detailed) {
    n$x<-c(2,2,2,1,3,2,2,3,2,1,2,1,3);n$y<-c(9,8,7,7,7,6,5,5,4,4,3,2,2)
  } else {n$x<-1;n$y<-rev(seq_len(nrow(n)))}
  n$text<-paste(vapply(bmi_population_label(n$population_id),function(z)paste(strwrap(z,24),collapse="\n"),character(1)),
    paste0("N = ",ifelse(is.na(n$n),"unavailable",format(n$n,big.mark=",",trim=TRUE))),gsub("_"," ",n$grain),sep="\n")
  e<-a$cohort_edges[a$cohort_edges$from %in% n$population_id & a$cohort_edges$to %in% n$population_id,,drop=FALSE]
  e$x<-n$x[match(e$from,n$population_id)];e$y<-n$y[match(e$from,n$population_id)]-.40
  e$xend<-n$x[match(e$to,n$population_id)];e$yend<-n$y[match(e$to,n$population_id)]+.40
  if(detailed){e$x<-rep(1.35,nrow(e));e$xend<-rep(1.35,nrow(e));e$y<-n$y[match(e$from,n$population_id)];e$yend<-n$y[match(e$to,n$population_id)]}
  connectors<-if(detailed)ggplot2::geom_curve(data=e,ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),curvature=.32,inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)else
    ggplot2::geom_segment(data=e,ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)
  branch_stems<-NULL
  if(!detailed){
    special<-e$from=="C" & e$to %in% c("C_abg_encounter","C_any_gas_encounter")
    if(any(special)){
      branches<-e[special,];branches$x<-branches$xend;branches$y<-3.5
      connectors<-ggplot2::geom_segment(data=rbind(e[!special,],branches),ggplot2::aes(x=x,y=y,xend=xend,yend=yend,linetype=relation),inherit.aes=FALSE,arrow=grid::arrow(length=grid::unit(1.5,"mm")),colour="grey40",show.legend=FALSE)
      stems<-data.frame(x=c(2,2,2),y=c(3.72,3.5,3.5),xend=c(2,1,3),yend=c(3.5,3.5,3.5))
      branch_stems<-ggplot2::geom_segment(data=stems,ggplot2::aes(x=x,y=y,xend=xend,yend=yend),inherit.aes=FALSE,colour="grey40",linetype="dashed")
    }
  }
  ggplot2::ggplot(n,ggplot2::aes(x,y))+connectors+branch_stems+
    ggplot2::geom_rect(ggplot2::aes(xmin=x-.47,xmax=x+.47,ymin=y-.38,ymax=y+.38),fill="white",colour="grey35",linewidth=.3)+
    ggplot2::geom_text(ggplot2::aes(label=text),size=3.4,lineheight=.95)+
    ggplot2::scale_x_continuous(limits=if(detailed)c(0,2)else c(.35,3.65))+
    ggplot2::scale_y_continuous(expand=ggplot2::expansion(add=.6))+
    ggplot2::labs(title="Observational cohort construction",subtitle="Parallel model branches overlap; counts come from the cohort ledger")+
    ggplot2::theme_void(base_size=10)+ggplot2::theme(plot.title=ggplot2::element_text(face="bold",size=12),plot.subtitle=ggplot2::element_text(size=9))
}
bmi_draw_grid <- function(plots,ncol=3,title="",subtitle="") {
  grid::grid.newpage();grid::grid.text(title,x=.02,y=.98,just=c("left","top"),gp=grid::gpar(fontsize=12,fontface="bold"))
  grid::grid.text(subtitle,x=.02,y=.945,just=c("left","top"),gp=grid::gpar(fontsize=9.5))
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
  recorded<-NULL
  for(ext in formats) {
    file<-paste0(stem,".",ext)
    if(ext=="pdf")grDevices::cairo_pdf(file,width=width_mm/25.4,height=height_mm/25.4,family="sans")
    if(ext=="svg")grDevices::svg(file,width=width_mm/25.4,height=height_mm/25.4,family="sans")
    if(ext=="png")grDevices::png(file,width=width_mm,height=height_mm,units="mm",res=300,type="cairo")
    if(ext=="jpg")grDevices::jpeg(file,width=width_mm,height=height_mm,units="mm",res=300,quality=95,type="cairo")
    warning_messages<-character()
    tryCatch(withCallingHandlers({
      if(is.null(recorded)) {
        grDevices::dev.control(displaylist="enable")
        draw();recorded<-grDevices::recordPlot()
      } else grDevices::replayPlot(recorded)
    },warning=function(w){warning_messages<<-c(warning_messages,conditionMessage(w));invokeRestart("muffleWarning")}),finally=grDevices::dev.off())
    if(length(warning_messages))utils::write.table(data.frame(export=basename(file),warning=warning_messages),paste0(stem,"-warnings.csv"),sep=",",row.names=FALSE,col.names=!file.exists(paste0(stem,"-warnings.csv")),append=file.exists(paste0(stem,"-warnings.csv")),qmethod="double")
  }
}
bmi_export_population_figures <- function(bundle,output) {
  a<-bundle$analysis;config<-bundle$config;dir.create(output,recursive=TRUE,showWarnings=FALSE);manifest<-list();captions<-list();atlas_index<-list()
  add<-function(id,draw,height,caption,kind="scientific figure") {
    if(id %in% c("F1-A","F1-B","F1-C","F2") && !is.null(bundle$manifest$source_group)) {
      source_draw<-draw;group<-bundle$manifest$source_group
      group_label<-c(primary="Non-OBESITY-supported entry",primary_current="Non-OBESITY-supported; current BMI",all_obesity="Any OBESITY source entry (overlapping)")[[group]]
      draw<-local({source_draw<-source_draw;label<-paste(group_label,"| encounter-wide");y<-if(id=="F2").92 else .95
        function(){source_draw();grid::grid.text(label,x=.02,y=y,just=c("left","top"),gp=grid::gpar(fontsize=9.5))}})
    }
    if(bundle$manifest$mode=="fixture") {
      original_draw<-draw
      draw<-local({original_draw<-original_draw;function(){original_draw();grid::grid.text("ARTIFICIAL DATA ONLY",x=.985,y=.995,just=c("right","top"),gp=grid::gpar(fontsize=9,col="grey25"))}})
    }
    stem<-file.path(output,id);formats<-if(grepl("^F[34]|^F0-detail-",id))c("pdf","svg","png")else c("pdf","svg","png","jpg");bmi_export(draw,stem,height_mm=height,formats=formats)
    manifest[[id]]<<-data.frame(figure_id=id,panel_id="all",file_path=paste0(stem,".png"),export_paths=paste(paste0(stem,paste0(".",formats)),collapse=";"),source_path="R/reporting.R",source_paths="R/reporting.R;R/report_views.R;R/standardization.R",figure_type=kind,intended_use="private manuscript/audit review",target_requirements="190 mm; >=9 pt; grayscale; identical saved aggregates",width_px=round(190/25.4*300),height_px=round(height/25.4*300),dpi_x=300,dpi_y=300,color_mode="grayscale-safe",vector_status="SVG/PDF masters",legend_status="caption and alt text saved",qc_status="exported; visual inspection pending",blockers="",notes="No numerical quantity copied manually")
    captions[[id]]<<-data.frame(figure_id=id,caption=caption,alt_text=caption,source_tables=if(grepl("F1",id))"probability_curves;observation_curves;distribution_bins"else if(grepl("F2",id))"policy_totals;policy_contributions"else if(grepl("F3",id))"variable_summary;category_counts;distribution_bins;distribution_curves"else if(grepl("F4",id))"model_registry;coefficients;coefficient_covariance;model_fit_diagnostics;model_residual_bins;model_influence_summary;model_support"else if(grepl("F5",id))"probability_curves;policy_totals;sensitivity_results;timing_audit"else"cohort_nodes;cohort_edges")
  }
  if(nrow(a$model_registry)) {
    outcomes<-c("abg","any_gas","icd");p<-obs<-freq<-list()
    for(o in outcomes) {
      ref<-"C"
      p[[o]]<-bmi_curve_plot(a$probability_curves[a$probability_curves$model_id==paste(o,"encounter/spline",sep="/"),],bmi_outcome_short(o))
      obs[[o]]<-bmi_observation_plot(a,o)
      freq[[o]]<-bmi_frequency_plot(a,ref,"BMI frequency and usable gases",config)
      limits<-range(a$distribution_bins$lower[a$distribution_bins$variable_id=="gas_pattern_bmi"],a$distribution_bins$upper[a$distribution_bins$variable_id=="gas_pattern_bmi"],na.rm=TRUE)
      for(name in c("p","obs","freq")) {obj<-get(name);if(is.data.frame(obj[[o]]$data)&&nrow(obj[[o]]$data))obj[[o]]<-obj[[o]]+ggplot2::coord_cartesian(xlim=limits);assign(name,obj)}
    }
    caption<-paste("F1. BMI–hypercapnia relationships at the first eligible adult 2022 acute-care encounter. ABG denotes PaCO₂ ≥45 mm Hg; ABG or VBG denotes PaCO₂ ≥45 or PvCO₂ ≥50 mm Hg. ICD denotes the five-code composite, including E66.2. Gas curves standardize over outcome-evaluable patients; ICD uses known diagnosis capture. Model/ref N is the common model and reference count. Availability and BMI frequency use all adjustment-complete patients (C); the four frequency groups are mutually exclusive. Adjustment: age, sex, race/ethnicity and region with a fixed natural BMI spline. Shading and fine boundaries show pointwise model-based 95% CIs; dotted segments are locally sparse and dashed segments exceed training BMI support. Open availability points use Wilson intervals when no model is estimable. Known capture is distinct from ICD positivity. ABG/VBG: arterial/venous blood gas. Conditional model uncertainty excludes selection and measurement assumptions; no population transport or causal effect is inferred.")
    add("F1-A",function()bmi_draw_relationship(p,obs,freq[[1]],"A"),190,caption)
    add("F1-B",function()bmi_draw_relationship(p,obs,freq[[1]],"B"),210,caption)
    add("F1-C",function()bmi_draw_relationship(p,obs,freq[[1]],"C"),190,caption)
    zoom<-lapply(p,function(g)g+ggplot2::coord_cartesian(xlim=c(30,60)))
    add("F1-detail",function()bmi_draw_grid(zoom,3,"BMI 30–60: relationship detail","Display zoom only; full ranges and all patients retained in F1"),105,paste(caption,"This labeled detail view limits the displayed BMI axis to 30–60; no observations were removed from estimation."))
    f2<-bands<-list()
    for(o in outcomes) {
      id<-paste(o,"encounter/spline",sep="/")
      totals<-a$policy_totals
      label<-totals[totals$model_id==id & totals$policy_id==config$policies[[1]]$policy_id,,drop=FALSE]
      z<-a$policy_contributions
      z<-z[z$model_id==id & z$method=="observed" & z$policy_id==config$policies[[1]]$policy_id,,drop=FALSE]
      if(!nrow(z) || !nrow(label) || label$status[1]!="estimated") {
        r<-a$model_registry[a$model_registry$model_id==id,,drop=FALSE]
        counts<-if(nrow(r))bmi_count_label(r$n_model[1],if(nrow(label))label$n_reference[1]else NA_real_)else"Model/reference N unavailable"
        reason<-paste0("Scenario unavailable",if(nrow(r))paste0(": ",r$status[1])else"")
        empty<-bmi_empty_plot(bmi_outcome_short(o),reason)+ggplot2::labs(subtitle=counts)
        f2<-c(f2,list(empty,empty));bands[[o]]<-empty
        next
      }
      f2[[length(f2)+1L]]<-bmi_scenario_probability_plot(label,o)
      f2[[length(f2)+1L]]<-ggplot2::ggplot(z,ggplot2::aes((bin_low+bin_high)/2,contribution_per1000))+
        ggplot2::geom_hline(yintercept=0,colour="grey40",linewidth=.3)+
        ggplot2::geom_col(ggplot2::aes(width=.8*(bin_high-bin_low)),fill="grey35")+
        ggplot2::geom_errorbar(ggplot2::aes(ymin=conf_low_per1000,ymax=conf_high_per1000),width=1,linewidth=.4)+
        ggplot2::scale_y_continuous(n.breaks=3)+
        ggplot2::labs(title="Signed BMI-band contribution",subtitle=paste0("Total /1,000: ",bmi_ci(label$difference_per1000,label$difference_low_per1000,label$difference_high_per1000),
          "\nPIF ",bmi_percent_ci(100*label$PIF,100*label$PIF_low,100*label$PIF_high)),x="Original BMI (kg/m²)",y="Change /1,000 patients")+bmi_theme()
      means<-bmi_bind(list(data.frame(bmi=(z$bin_low+z$bin_high)/2,p=z$mean_observed,scenario="Observed"),
                          data.frame(bmi=(z$bin_low+z$bin_high)/2,p=z$mean_shifted,scenario="Shifted")))
      bands[[o]]<-ggplot2::ggplot(means,ggplot2::aes(bmi,p,linetype=scenario,shape=scenario))+
        ggplot2::geom_line(linewidth=.5,na.rm=TRUE)+ggplot2::geom_point(size=1.5,na.rm=TRUE)+
        ggplot2::scale_y_continuous(limits=c(0,1),breaks=c(0,.5,1),labels=function(x)paste0(100*x,"%"))+
        ggplot2::labs(title=bmi_outcome_short(o),subtitle=bmi_count_label(label$n_model,label$n_reference),
          x="Original BMI (kg/m²)",y="Mean probability",linetype=NULL,shape=NULL)+bmi_theme()+
        ggplot2::guides(linetype=ggplot2::guide_legend(ncol=1),shape=ggplot2::guide_legend(ncol=1))
    }
    add("F2",function()bmi_draw_grid(f2,2,config$policies[[1]]$label,
      "Paired predictions; original reference and covariates retained"),195,
      paste0("F2. Paired scenario: ",config$policies[[1]]$label,". ABG: arterial PCO₂ ≥45 mm Hg; ABG or VBG: arterial ≥45 or venous ≥50 mm Hg; ICD: five-code composite including E66.2. Left: observed and shifted standardized probabilities with model-based 95% CIs and printed limits. Left probability axes use different labeled inset scales; compare printed values across outcomes. N identifies the common model/reference population; shifted percentage is a descriptive cohort fraction. Right: signed original-BMI-band contributions per 1,000 reference patients, with 95% CIs. Total-difference/PIF limits are printed; contribution covariance reproduces total variance. Right axes vary by outcome and retain zero and all limits. Gas samples are outcome-evaluable; ICD uses known capture. Adjustment, source-entry membership and covariates are fixed. PIF is the model-standardized potential impact fraction. These conditional scenarios do not estimate a weight-loss treatment effect."))
    add("F2-bands",function()bmi_draw_grid(bands,3,"Paired predictions within original BMI bands",
      "Audit companion to F2; full BMI range and original band membership"),120,
      "F2 bands. Mean observed and shifted predictions within each original BMI band; the displayed N is the model/reference population. These are paired conditional predictions, not fixed-BMI risk curves. Band-specific probability intervals are not persisted in the bundle and are not fabricated here; aggregate probability and signed contribution intervals appear in F2. All band means and contribution covariances remain available in the aggregate tables.","scenario audit")
  }
  add("F0-main",function()print(bmi_flow_plot(a)),205,"F0. Observational cohort flow. Ledger counts identify grain; eligibility and adjustment branches are partitions at their declared grain. Matched outcome samples overlap. Unresolved earlier membership and ties never advance to a later visit.","observational flow")
  # One parent/edge group per diagram: partitions are never mixed with overlapping subsets.
  edge_groups<-split(seq_len(nrow(a$cohort_edges)),paste(a$cohort_edges$from,a$cohort_edges$relation,a$cohort_edges$partition_id))
  for(i in seq_along(edge_groups)) {
    e<-a$cohort_edges[edge_groups[[i]],,drop=FALSE]
    add(paste0("F0-detail-",i),local({e<-e;function()print(bmi_edge_plot(a,e))}),max(90,45+20*nrow(e)),
      paste("Detailed cohort edges:",e$relation[1],". Counts and grain come from cohort_nodes. Subsets overlap; only named partitions sum to their parent."),"observational flow")
  }
  # F3: all registered numeric/category variables at every profiled stage.
  histogram<-a$distribution_bins[a$distribution_bins$variable_id!="gas_pattern_bmi",,drop=FALSE]
  for(v in unique(c(histogram$variable_id,a$category_counts$variable_id))) {
    unit<-a$variable_dictionary$unit[match(v,a$variable_dictionary$variable_id)]
    variable_label<-bmi_variable_label(v,a$variable_dictionary)
    unit<-gsub("kg/m2","kg/m²",unit,fixed=TRUE)
    axis_label<-if(length(unit)&&!is.na(unit)&&nzchar(unit))paste0(variable_label," (",unit,")")else variable_label
    hist<-histogram[histogram$variable_id==v,,drop=FALSE];catdata<-a$category_counts[a$category_counts$variable_id==v & !is.na(a$category_counts$n_reference) & a$category_counts$n_reference>0,,drop=FALSE]
    original<-if(nrow(hist))hist else catdata
    if(!nrow(original))next
    shared<-bmi_unique_plot_profiles(original,setdiff(names(original),c("population_id","pattern")))
    index<-shared$index;index$variable_id<-v;index$kind<-if(nrow(hist))"histogram"else"categories"
    if(nrow(hist))hist<-shared$data else catdata<-shared$data
    reps<-unique(shared$data$population_id);index$figure_id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",ceiling(match(index$representative_id,reps)/4));atlas_index[[length(atlas_index)+1L]]<-index
    ids<-unique(c(hist$population_id,catdata$population_id));chunks<-split(ids,ceiling(seq_along(ids)/4))
    for(j in seq_along(chunks)) {
      stages<-chunks[[j]];id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",j)
      if(nrow(hist)) {
        h<-hist[hist$population_id %in% stages,,drop=FALSE]
        chart<-ggplot2::ggplot(h,ggplot2::aes((lower+upper)/2,100*mass))+ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey40")+
          ggplot2::facet_wrap(~population_id,ncol=2,scales="free_y",labeller=ggplot2::as_labeller(function(x)bmi_wrap(bmi_population_label(x),28)))+ggplot2::labs(title=bmi_wrap(paste(variable_label,"— full-range distributions"),65),subtitle="Named population (%); panel scales vary; exact tables retained",x=axis_label,y="Population (%)")+bmi_theme()
      }else{
        h<-catdata[catdata$population_id %in% stages,,drop=FALSE]
        h$level<-factor(bmi_category_labels(v,h$level,a$variable_dictionary),levels=unique(bmi_category_labels(v,h$level,a$variable_dictionary)))
        chart<-ggplot2::ggplot(h,ggplot2::aes(level,percent_all))+ggplot2::geom_col(fill="grey40")+ggplot2::coord_flip()+
          ggplot2::facet_wrap(~population_id,ncol=2,labeller=ggplot2::as_labeller(function(x)bmi_wrap(bmi_population_label(x),28)))+ggplot2::labs(title=bmi_wrap(paste(variable_label,"— complete category profiles"),65),subtitle="All categories and missing values; exact tables retained",x=NULL,y="Population (%)")+bmi_theme()
      }
      add(id,local({chart<-chart;function()print(chart)}),185,paste("F3. Complete",v,"stage atlas; each facet names its denominator. All categories, tails and missingness are retained in the matching aggregate tables."),"descriptive atlas")
    }
    curves<-a$distribution_curves[a$distribution_curves$variable_id==v,,drop=FALSE]
    if(nrow(curves))for(kind in unique(curves$kind)) {
      kinddata<-curves[curves$kind==kind,,drop=FALSE]
      shared<-bmi_unique_plot_profiles(kinddata,setdiff(names(kinddata),"population_id"));kinddata<-shared$data
      index<-shared$index;index$variable_id<-v;index$kind<-kind;reps<-unique(kinddata$population_id)
      index$figure_id<-paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",kind,"-",ceiling(match(index$representative_id,reps)/4));atlas_index[[length(atlas_index)+1L]]<-index
      curvechunks<-split(reps,ceiling(seq_along(reps)/4))
      for(j in seq_along(curvechunks)) {
        z<-kinddata[kinddata$population_id %in% curvechunks[[j]],,drop=FALSE];if(!nrow(z))next
        chart<-ggplot2::ggplot(z,ggplot2::aes(x,y))
        if(kind=="ecdf") {
          chart<-chart+ggplot2::geom_step(linewidth=.5)+ggplot2::geom_point(size=.6)+ggplot2::scale_y_continuous(limits=c(0,1),breaks=c(0,.5,1))
          if(length(unique(z$x))==1L)chart<-chart+ggplot2::scale_x_continuous(breaks=z$x[1],expand=ggplot2::expansion(add=1))
        }else chart<-chart+ggplot2::geom_line(linewidth=.5)
        chart<-chart+ggplot2::facet_wrap(~population_id,ncol=2,labeller=ggplot2::as_labeller(function(x)bmi_wrap(bmi_population_label(x),28)))+
          ggplot2::labs(title=bmi_wrap(paste(variable_label,if(kind=="ecdf")"— cumulative distribution"else"— density"),65),subtitle=if(kind=="kde")"Gaussian; common bandwidth; scaled to observed population mass"else"Observed-value ECDF; common saved grid",x=axis_label,y=if(kind=="ecdf")"Cumulative proportion"else"Density")+bmi_theme()
        if(kind=="ecdf")chart<-chart+ggplot2::theme(plot.margin=grid::unit(c(3,8,3,3),"mm"))
        add(paste0("F3-",gsub("[^a-zA-Z0-9]","-",v),"-",kind,"-",j),local({chart<-chart;function()print(chart)}),185,paste("F3.",v,kind,"across named stages; full coordinate export and normalization metadata in distribution_curves."),"descriptive atlas")
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
        ggplot2::facet_wrap(~diagnostic,scales="free_x",labeller=ggplot2::as_labeller(c(BMI="BMI bands",fitted_probability="Predicted-probability groups")))+
        ggplot2::scale_y_continuous(labels=function(x)paste0(100*x,"%"))+
        ggplot2::labs(title=paste(strwrap(paste("Model:",gsub("_"," ",id)),55),collapse="\n"),subtitle="Open points: observed means; line: fitted means",x="BMI band (kg/m²) or probability-group number",y="Probability")+bmi_theme()
      residual<-d[grepl("^hist_",d$diagnostic),,drop=FALSE]
      rp<-ggplot2::ggplot(residual,ggplot2::aes((lower+upper)/2,n))+ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey40")+
        ggplot2::facet_wrap(~diagnostic,ncol=1,scales="free",labeller=ggplot2::as_labeller(function(x)gsub("_"," ",sub("^hist_","",x))))+ggplot2::scale_y_continuous(breaks=function(limits){x<-pretty(limits,n=2);x<-x[x>0 & x<=limits[2]];c(0,if(length(x))max(x))})+ggplot2::labs(title="Residual and predicted-probability distributions",x="Value (panel-specific scale)",y="Model patients")+bmi_theme()
      draw<-local({chart<-chart;rp<-rp;counts<-paste0("Training N = ",format(a$model_registry$n_model[i],big.mark=",",trim=TRUE),"; events = ",format(a$model_registry$n_events[i],big.mark=",",trim=TRUE),"; in-sample diagnostics")
        function()bmi_draw_grid(list(chart,rp),1,"Complete model diagnostics",counts)})
    }else draw<-local({reason<-a$model_registry$failure_reason[i];id<-id;function()print(bmi_empty_plot(id,reason))})
    add(paste0("F4-",i),draw,190,paste("F4. Model",id,"apparent fit and full-sample diagnostics. Influence flags do not exclude observations. Failure positions remain visible."),"model diagnostics")
  }
  if(nrow(a$model_registry)) {
    for(o in c("abg","any_gas")) {
      z<-a$probability_curves[a$probability_curves$outcome_id==o & a$probability_curves$family %in% c("primary","timing"),,drop=FALSE]
      plots<-lapply(c("encounter","index_calendar_day"),function(w)bmi_curve_plot(z[z$window==w,,drop=FALSE],paste(bmi_outcome_short(o),if(w=="encounter")"— encounter"else"— index day")))
      if(any(is.finite(z$bmi)))plots<-lapply(plots,function(p)p+ggplot2::coord_cartesian(xlim=range(z$bmi,na.rm=TRUE)))
      add(paste0("F5-timing-",o),local({plots<-plots;function()bmi_draw_grid(plots,1,"Hypercapnia by ascertainment window","Fixed indexes; window-specific outcome-evaluable populations")}),170,"F5. Encounter versus encounter-start-calendar-day curves reuse the same indexes and fixed spline basis, on shared BMI/probability scales. Each curve standardizes over its displayed model/reference population. Bands are pointwise model-based 95% CIs; dotted segments are locally sparse and dashed segments exceed training BMI support. Pending source or failed models remain explicit. Index day is a calendar-date restriction, not elapsed 24 hours.","sensitivity")
    }
    for(pair in c("abg","any_gas")) {
      z<-a$probability_curves[a$probability_curves$model_id %in% paste("matched",pair,c("icd",pair),sep="/"),,drop=FALSE]
      plots<-lapply(c("icd",pair),function(o)bmi_curve_plot(z[z$outcome_id==o,,drop=FALSE],bmi_outcome_short(o)))
      if(any(is.finite(z$bmi)))plots<-lapply(plots,function(p)p+ggplot2::coord_cartesian(xlim=range(z$bmi,na.rm=TRUE)))
      add(paste0("F5-matched-",pair),local({plots<-plots;function()bmi_draw_grid(plots,1,"Hypercapnia definitions in matched patients","Encounter-wide; identical patients within each comparison")}),170,"F5. Matched ICD/gas curves use identical training/reference patients within each pair and shared BMI/probability scales. Arterial and combined pairs can have different membership. Bands are pointwise model-based 95% CIs; dotted segments are locally sparse and dashed segments exceed training BMI support. ICD is the five-code composite including E66.2. Separate bands are not a test of between-model differences.","sensitivity")
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
# Paired standardized means: direct labels stay outside the interval glyphs.
bmi_scenario_probability_plot <- function(total,outcome) {
  d<-data.frame(state=c("Observed","Shifted"),y=c(2,1),
    probability=100*c(total$p_observed,total$p_shifted),
    low=100*c(total$p_observed_low,total$p_shifted_low),
    high=100*c(total$p_observed_high,total$p_shifted_high))
  d$label<-bmi_percent_ci(d$probability,d$low,d$high)
  limits<-range(c(d$low,d$high),finite=TRUE)
  padding<-max(diff(limits)*.18,.001)
  ggplot2::ggplot(d,ggplot2::aes(probability,y))+
    ggplot2::geom_errorbar(ggplot2::aes(xmin=low,xmax=high),orientation="y",width=.12,linewidth=.5)+
    ggplot2::geom_point(ggplot2::aes(shape=state),size=2.1)+
    ggplot2::scale_shape_manual(values=c(Observed=16,Shifted=1),guide="none")+
    ggplot2::geom_text(ggplot2::aes(label=label),x=mean(limits),nudge_y=-.32,size=3.4)+
    ggplot2::scale_y_continuous(limits=c(.35,2.35),breaks=c(1,2),labels=c("Shifted","Observed"))+
    ggplot2::scale_x_continuous(labels=function(x)paste0(format(x,trim=TRUE,digits=4),"%"),breaks=pretty(limits,n=3))+
    ggplot2::coord_cartesian(xlim=c(max(0,limits[1]-padding),min(100,limits[2]+padding)))+
    ggplot2::labs(title=bmi_outcome_short(outcome),subtitle=paste0(bmi_count_label(total$n_model,total$n_reference),
      "\nShifted: ",bmi_number(total$pct_shifted,4),"% of model patients"),
      x="Probability (%) · inset scale",y=NULL)+bmi_theme()+
    ggplot2::theme(panel.grid.major.y=ggplot2::element_blank())
}
bmi_observation_plot <- function(a,outcome) {
  z<-a$observation_curves[a$observation_curves$model_id==paste("observation",outcome,"encounter",sep="/"),,drop=FALSE]
  if(nrow(z)&&any(!is.na(z$probability)))return(bmi_curve_plot(z,paste("Usable",bmi_outcome_short(outcome)),TRUE))
  d<-a$evidence_by_bmi;d<-d[d$population_id=="C"&d$window=="encounter"&d$outcome_id==outcome&d$status=="assessed",,drop=FALSE]
  if(!nrow(d))return(bmi_empty_plot("Evidence availability","Unassessed"))
  if(outcome=="icd" && sum(d$N)>0 && all(d$M==d$N)) {
    n<-sum(d$N)
    label<-paste0(format(n,big.mark=",",trim=TRUE)," / ",format(n,big.mark=",",trim=TRUE),
      "\nC patients have known capture.\nCapture is not ICD positivity.")
    return(ggplot2::ggplot()+ggplot2::annotate("text",x=.5,y=.5,label=label,size=3.4,lineheight=1.1)+
      ggplot2::coord_cartesian(xlim=c(0,1),ylim=c(0,1))+
      ggplot2::labs(title="Diagnosis capture")+ggplot2::theme_void(base_size=10)+
      ggplot2::theme(plot.title=ggplot2::element_text(size=10.5,face="bold"),plot.margin=grid::unit(rep(4,4),"mm")))
  }
  intervals<-t(vapply(seq_len(nrow(d)),function(i)bmi_wilson(d$M[i],d$N[i]),numeric(2)))
  d$low<-pmax(0,intervals[,1]);d$high<-pmin(1,intervals[,2])
  ggplot2::ggplot(d,ggplot2::aes((bin_low+bin_high)/2,observation))+ggplot2::geom_errorbar(ggplot2::aes(ymin=low,ymax=high),width=.7)+ggplot2::geom_point(shape=1,size=1.8)+
    ggplot2::scale_y_continuous(limits=c(0,1),labels=function(x)paste0(100*x,"%"))+
    ggplot2::labs(title="Evidence availability",subtitle=paste0("Model: ",if(nrow(z))z$status[1]else"unavailable","\nRaw M/N on C; Wilson 95% CI"),x="BMI (kg/m²)",y=if(outcome=="icd")"Known diagnosis capture"else"Usable gas evidence")+bmi_theme()
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
bmi_number <- function(x,digits=3) vapply(x,function(z) {
  if(is.na(z))return("unavailable")
  if(z==0)return("0")
  format(z,digits=digits,trim=TRUE,scientific=abs(z)<.001||abs(z)>=1e6)
},character(1))

bmi_latex_escape <- function(text) {
  replacements<-setNames(c("\\textbackslash{}","\\{","\\}","\\$","\\&","\\#","\\%","\\_","\\textasciitilde{}","\\textasciicircum{}"),c("\\","{","}","$","&","#","%","_","~","^"))
  vapply(text,function(x){chars<-strsplit(x,"",fixed=TRUE)[[1]];mapped<-unname(replacements[chars]);paste0(ifelse(is.na(mapped),chars,mapped),collapse="")},character(1))
}
