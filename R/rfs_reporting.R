# Raw outcome availability on the full fixed-index RFS populations, before adjustment.
bmi_rfs_availability <- function(a) {
  rows<-list()
  for(group in c("primary","obesity_only"))for(o in c("abg","any_gas","icd")) {
    subgroups<-if(group=="primary")c("non_obesity_only","overlap","non_obesity_with_unknown_obesity")else"obesity_only"
    z<-a$rfs_outcomes[a$rfs_outcomes$subgroup %in% subgroups & a$rfs_outcomes$outcome_id==o & a$rfs_outcomes$ascertainment_window=="encounter",]
    if(nrow(z)!=length(subgroups))stop("Missing RFS availability rows")
    n<-sum(z$N);m<-sum(z$evaluable);interval<-bmi_wilson(m,n)
    rows[[length(rows)+1L]]<-data.frame(population_id=group,outcome_id=o,N=n,M=m,unknown=sum(z$unknown),
      percent=if(n>0)100*m/n else NA_real_,conf_low=100*interval[1],conf_high=100*interval[2])
  }
  bmi_bind(rows)
}

# The scientific exhibit describes gas observation in primary indexes only.
# Other source-entry groups and diagnosis-capture counts remain audit tables.
bmi_rfs_evidence_plot <- function(availability) {
  d<-availability[availability$population_id=="primary" & availability$outcome_id %in% c("abg","any_gas"),,drop=FALSE]
  d$y<-match(d$outcome_id,c("any_gas","abg"))
  d$label<-paste0(format(d$M,big.mark=",",trim=TRUE)," / ",format(d$N,big.mark=",",trim=TRUE),"\n",
    bmi_percent_ci(d$percent,d$conf_low,d$conf_high))
  # Retain the exact interval endpoints; cap marks and an inset scale improve
  # visibility without artificially widening the intervals of a large cohort.
  endpoints<-c(d$conf_low,d$conf_high)
  limits<-if(any(is.finite(endpoints)))range(endpoints[is.finite(endpoints)])else c(0,100)
  padding<-max(1,diff(limits)*.15)
  ggplot2::ggplot(d,ggplot2::aes(percent,y))+
    ggplot2::geom_segment(ggplot2::aes(x=conf_low,xend=conf_high,yend=y),linewidth=.8,na.rm=TRUE)+
    ggplot2::geom_segment(ggplot2::aes(x=conf_low,xend=conf_low,y=y-.045,yend=y+.045),linewidth=.6,na.rm=TRUE)+
    ggplot2::geom_segment(ggplot2::aes(x=conf_high,xend=conf_high,y=y-.045,yend=y+.045),linewidth=.6,na.rm=TRUE)+
    ggplot2::geom_point(size=1.6,na.rm=TRUE)+
    ggplot2::geom_text(ggplot2::aes(label=label),x=mean(limits),nudge_y=-.27,size=3.4,lineheight=1.1)+
    ggplot2::scale_x_continuous(labels=function(x)paste0(x,"%"))+
    ggplot2::coord_cartesian(xlim=c(max(0,limits[1]-padding),min(100,limits[2]+padding)))+
    ggplot2::scale_y_continuous(limits=c(.35,2.35),breaks=c(1,2),labels=c("ABG or VBG","ABG"))+
    ggplot2::labs(title="Usable blood-gas evidence in the primary population",subtitle="Full fixed-index denominator; proportions with Wilson 95% CIs",
      x="Patients with usable evidence (%) — inset scale",y=NULL)+bmi_theme()+
    ggplot2::theme(panel.grid.major.y=ggplot2::element_blank(),panel.grid.minor=ggplot2::element_blank())
}

# Population-aware views; all numerical figures read saved aggregates only.
bmi_export_figures <- function(bundle,output) {
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  all_captions<-all_manifests<-all_atlas<-list()
  root_draw<-function(draw)function(){draw();if(bundle$manifest$mode=="fixture")grid::grid.text("ARTIFICIAL DATA ONLY",x=.985,y=.995,just=c("right","top"),gp=grid::gpar(fontsize=9,col="grey25"))}
  for(group in c("combined","unresolved",unlist(bundle$config$descriptive_populations),unlist(bundle$config$analysis_populations))) {
    view<-bmi_group_view(bundle$analysis,group)
    if(!nrow(view$cohort_nodes))next
    child<-bundle;child$analysis<-view;child$manifest$source_group<-group
    folder<-file.path(output,group)
    bmi_export_population_figures(child,folder)
    gallery_path<-file.path(folder,"gallery.html")
    writeLines(gsub("../../../","../../../../",readLines(gallery_path,warn=FALSE),fixed=TRUE),gallery_path)
    captions<-utils::read.csv(file.path(folder,"captions.csv"),stringsAsFactors=FALSE)
    captions$figure_id<-paste0(group,"/",captions$figure_id)
    captions$caption<-paste0("Source-entry population: ",group,". ",
      if(group!="combined")"Subgroup accounting begins with fixed indexes; source/input nodes in these subgroup views do not repeat upstream selection. "else"Global source and pre-index accounting. ",captions$caption)
    captions$alt_text<-captions$caption
    all_captions[[group]]<-captions
    manifest<-utils::read.csv(file.path(folder,"figure-qc-manifest.csv"),stringsAsFactors=FALSE)
    manifest$figure_id<-paste0(group,"/",manifest$figure_id);manifest$notes<-paste(group,manifest$notes)
    all_manifests[[group]]<-manifest
    atlas_path<-file.path(folder,"atlas-index.csv")
    atlas<-if(identical(readLines(atlas_path,warn=FALSE),'""'))data.frame()else utils::read.csv(atlas_path,stringsAsFactors=FALSE)
    if(nrow(atlas)){atlas$figure_id<-paste0(group,"/",atlas$figure_id);atlas$analysis_population_id<-group;all_atlas[[group]]<-atlas}
  }
  a<-bundle$analysis
  partition<-a$cohort_edges[a$cohort_edges$partition_id=="rfs_index",,drop=FALSE]
  if(nrow(partition)) {
    bmi_export(root_draw(function()print(bmi_edge_plot(a,partition))),file.path(output,"RFS-flow"),height_mm=150)
    caption<-"Fixed common indexes partition into primary non-OBESITY-supported source entry, obesity-only source entry and unresolved RFS. Overlapping OBESITY/non-OBESITY membership remains primary. Counts and units derive from the ledger; all-OBESITY supporting models overlap and are not a fourth partition branch."
    if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
    all_captions[["flow"]]<-data.frame(figure_id="RFS-flow",caption=caption,alt_text=caption,source_tables="cohort_nodes;cohort_edges")
  }
  z<-a$rfs_by_bmi
  if(nrow(z)) {
    z<-z[abs(z$bin_high-z$bin_low-bundle$config$bmi_bin_width)<1e-8,,drop=FALSE]
    z<-stats::aggregate(n~subgroup+bin_low+bin_high,z,sum)
    z$subgroup<-factor(z$subgroup,levels=c("non_obesity_only","overlap","non_obesity_with_unknown_obesity","obesity_only","rfs_unresolved","all_zero_discrepancy"))
    plot<-ggplot2::ggplot(z,ggplot2::aes((bin_low+bin_high)/2,n))+
      ggplot2::geom_col(ggplot2::aes(width=bin_high-bin_low),fill="grey35")+
      ggplot2::facet_wrap(~subgroup,ncol=1,labeller=ggplot2::as_labeller(function(x)bmi_wrap(gsub("_"," ",x),55)))+
      ggplot2::labs(title="Historical source-entry membership across BMI",subtitle="Fixed common indexes; patient counts",x="BMI (kg/m²)",y="Indexed patients")+bmi_theme()
    stem<-file.path(output,"RFS-entry");bmi_export(root_draw(function()print(plot)),stem,height_mm=190)
    caption<-"Historical source-entry subgroup counts by BMI, pooling the two acute settings on fixed indexes. Overlap remains in primary; obesity-only is a descriptive selection audit without adjusted outcome models. Membership records source-file representation, not exhaustive clinical criteria. Unresolved and all-zero discrepancies are retained. All groups partition the common indexed population. No association or causal bias correction follows from this partition."
    if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
    all_captions[["entry"]]<-data.frame(figure_id="RFS-entry",caption=caption,alt_text=caption,source_tables="rfs_by_bmi")
  }
  if(nrow(a$rfs_outcomes)) {
    availability<-bmi_rfs_availability(a)
    availability$displayed<-availability$population_id=="primary" & availability$outcome_id %in% c("abg","any_gas")
    utils::write.csv(availability,file.path(output,"rfs-evidence-display.csv"),row.names=FALSE)
    plot<-bmi_rfs_evidence_plot(availability)
    bmi_export(root_draw(function()print(plot)),file.path(output,"RFS-evidence"),height_mm=85)
    caption<-"Encounter-wide usable gas evidence among all primary fixed indexes, before adjustment completeness. Labels give evaluable/full N, percentage and 95% Wilson CI; capped intervals use their exact endpoints on a labeled inset scale. ABG: arterial blood gas; VBG: venous blood gas. The combined row accepts either usable specimen; the two rows overlap and are not summed. These percentages describe evidence availability, not hypercapnia positivity. Primary includes non-OBESITY pathways and their OBESITY overlaps. Complete diagnosis capture, when present, is a source fact rather than ICD positivity and is reported separately. Obesity-only counts and residual-gas discrepancies are confined to the cohort flow and audit; they do not define a scientific comparator or weighting analysis."
    if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
    all_captions[["evidence"]]<-data.frame(figure_id="RFS-evidence",caption=caption,alt_text=caption,source_tables="rfs_outcomes;rfs_summary")
  }
  for(id in c("RFS-flow","RFS-entry","RFS-evidence"))if(file.exists(file.path(output,paste0(id,".png")))) {
    all_manifests[[id]]<-data.frame(figure_id=id,panel_id="all",file_path=file.path(output,paste0(id,".png")),export_paths=paste(file.path(output,paste0(id,c(".svg",".pdf",".png",".jpg"))),collapse=";"),source_path="R/rfs_reporting.R",figure_type="source-entry audit",intended_use="private research review",width_px=round(190/25.4*300),dpi_x=300,dpi_y=300,color_mode="grayscale",vector_status="SVG/PDF",qc_status="exported; actual visual review pending")
  }
  utils::write.csv(bmi_bind(all_captions),file.path(output,"captions.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(all_manifests),file.path(output,"figure-qc-manifest.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(all_atlas),file.path(output,"atlas-index.csv"),row.names=FALSE)
  captions<-bmi_bind(all_captions)
  html<-c("<!doctype html><meta charset='utf-8'><title>RFS figure comparison</title><style>body{font:16px sans-serif;max-width:1100px;margin:auto}img{width:100%}</style><h1>RFS figure alternatives</h1><p>F1-A remains provisional preferred. Counts and all alternatives use the same saved aggregates.</p>")
  for(i in seq_len(nrow(captions))) {
    id<-captions$figure_id[i]
    html<-c(html,paste0("<article><h2>",id,"</h2><a href='",id,".png'><img loading='lazy' src='",id,".png' alt='",id,"'></a><p>",captions$caption[i],"</p></article>"))
  }
  writeLines(html,file.path(output,"gallery.html"))
  jsonlite::write_json(list(same_saved_values=TRUE,clinical_reads=0,model_refits=0,visual_inspection="pending",populations=bundle$config$analysis_populations,descriptive_populations=bundle$config$descriptive_populations),file.path(output,"figure-data-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
}
