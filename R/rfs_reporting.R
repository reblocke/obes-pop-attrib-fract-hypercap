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
    captions$caption<-paste0("Analysis population: ",bmi_analysis_label(group),". ",
      if(group!="combined")"Subgroup accounting begins with fixed indexes; source/input nodes in these subgroup views do not repeat upstream selection. "else"Global source and pre-index accounting. ",captions$caption)
    captions$alt_text<-captions$caption
    all_captions[[group]]<-captions
    manifest<-utils::read.csv(file.path(folder,"figure-qc-manifest.csv"),stringsAsFactors=FALSE)
    manifest$figure_id<-paste0(group,"/",manifest$figure_id);manifest$notes<-paste(group,manifest$notes)
    all_manifests[[group]]<-manifest
    atlas_path<-file.path(folder,"atlas-index.csv")
    atlas<-if(identical(readLines(atlas_path,warn=FALSE),'""'))data.frame()else utils::read.csv(atlas_path,stringsAsFactors=FALSE)
    if(nrow(atlas)){plotted<-!is.na(atlas$figure_id);atlas$figure_id[plotted]<-paste0(group,"/",atlas$figure_id[plotted]);atlas$analysis_population_id<-group;all_atlas[[group]]<-atlas}
  }
  a<-bundle$analysis
  partition<-a$cohort_edges[a$cohort_edges$partition_id=="rfs_index",,drop=FALSE]
  secondary<-a$cohort_edges[a$cohort_edges$from=="primary::Q" & a$cohort_edges$to=="primary_bmi_ge30::Q",,drop=FALSE]
  if(nrow(partition)) {
    flow<-list(bmi_edge_plot(a,partition)+ggplot2::labs(title="A  Source-entry partition"),
      bmi_edge_plot(a,secondary)+ggplot2::labs(title="B  Nested BMI-restricted secondary",subtitle="Same primary indexes; no later-encounter substitution"))
    bmi_export(root_draw(function()bmi_draw_grid(flow,1,"Populations at the new all-BMI index",
      "The source-entry partition and the nested BMI subset are separate steps")),file.path(output,"RFS-flow"),height_mm=210)
    caption<-"Fixed common indexes partition into primary non-OBESITY-supported source entry, obesity-only source entry and unresolved RFS. Overlapping OBESITY/non-OBESITY membership remains primary. Counts and units derive from the ledger; BMI ≥30 secondary is nested within primary at the same indexes; all-OBESITY supporting models overlap and are not a fourth partition branch."
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
  component_ids<-character()
  for(group in unlist(bundle$config$component_populations)) {
    child<-bundle;child$analysis<-bmi_group_view(a,group);child$manifest$source_group<-group
    folder<-file.path(output,group)
    caps<-bmi_bind(list(bmi_same_day_figure(child,folder),bmi_icd_acuity_figure(child,folder)))
    caps$figure_id<-paste0(group,"/",caps$figure_id)
    caps$caption<-paste0(bmi_analysis_label(group),". ",caps$caption);caps$alt_text<-caps$caption
    all_captions[[paste0(group,"-components")]]<-caps
    component_ids<-c(component_ids,caps$figure_id)
  }
  for(id in c("RFS-flow","RFS-entry","RFS-evidence",component_ids))if(file.exists(file.path(output,paste0(id,".png")))) {
    all_manifests[[id]]<-data.frame(figure_id=id,panel_id="all",file_path=file.path(output,paste0(id,".png")),export_paths=paste(file.path(output,paste0(id,c(".svg",".pdf",".png",".jpg"))),collapse=";"),source_path="R/rfs_reporting.R",figure_type=if(grepl("(^|/)S2-ICD",id))"ICD probabilities and sampling support"else"source-entry audit",intended_use="private research review",width_px=round(190/25.4*300),dpi_x=300,dpi_y=300,color_mode=if(grepl("(^|/)S[12]-",id))"RGB; grayscale review required"else"grayscale",vector_status="SVG/PDF",qc_status="exported; actual visual review pending")
  }
  utils::write.csv(bmi_bind(all_captions),file.path(output,"captions.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(all_manifests),file.path(output,"figure-qc-manifest.csv"),row.names=FALSE)
  utils::write.csv(bmi_bind(all_atlas),file.path(output,"atlas-index.csv"),row.names=FALSE)
  captions<-bmi_bind(all_captions)
  html<-c("<!doctype html><meta charset='utf-8'><title>RFS figure comparison</title><style>body{font:16px sans-serif;max-width:1100px;margin:auto}img{width:100%}</style><h1>RFS figure alternatives</h1><p>F1-B and F2 retain the previously selected layouts; approval of new results is pending. S1 and S2 are integrated physiological and diagnosis components, with separate primary and BMI ≥30 views. Counts and all alternatives use the same saved aggregates.</p>")
  for(i in seq_len(nrow(captions))) {
    id<-captions$figure_id[i]
    html<-c(html,paste0("<article><h2>",id,"</h2><a href='",id,".png'><img loading='lazy' src='",id,".png' alt='",id,"'></a><p>",captions$caption[i],"</p></article>"))
  }
  writeLines(html,file.path(output,"gallery.html"))
  jsonlite::write_json(list(same_saved_values=TRUE,clinical_reads=0,model_refits=0,visual_inspection="pending",populations=bundle$config$analysis_populations,descriptive_populations=bundle$config$descriptive_populations),file.path(output,"figure-data-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
}

bmi_same_day_figure <- function(bundle,output) {
  a<-bundle$analysis;id<-"same_day_abg/encounter/multinomial_spline"
  r<-a$model_registry[a$model_registry$model_id==id,,drop=FALSE]
  curves<-a$probability_curves[a$probability_curves$model_id==id,,drop=FALSE]
  good<-curves[is.finite(curves$probability),,drop=FALSE]
  label<-c(with_acidemia="With same-day acidemia",without_acidemia="Without documented same-day acidemia")
  colours<-c(with_acidemia="#246477",without_acidemia="#995C28")
  if(nrow(good)) {
    total<-good[good$outcome_id=="any_hypercapnia",];with<-good[good$outcome_id=="with_acidemia",];without<-good[good$outcome_id=="without_acidemia",]
    stopifnot(identical(total$bmi,with$bmi),identical(total$bmi,without$bmi),max(abs(total$probability-with$probability-without$probability))<1e-10)
    stacked<-data.frame(bmi=total$bmi,with=with$probability,total=total$probability,
      total_low=total$conf_low,total_high=total$conf_high,sparse=with$locally_sparse|without$locally_sparse|total$locally_sparse)
    stacked$segment<-cumsum(c(TRUE,head(stacked$sparse,-1)!=tail(stacked$sparse,-1)))
    components<-good[good$outcome_id %in% names(label),]
    components$label<-factor(label[components$outcome_id],levels=label)
    components$segment<-ave(seq_len(nrow(components)),components$outcome_id,FUN=function(ix)cumsum(c(TRUE,head(components$locally_sparse[ix],-1)!=tail(components$locally_sparse[ix],-1))))
    bounds<-range(total$bmi);display_bounds<-c(5*floor(bounds[1]/5),5*ceiling(bounds[2]/5))
    xscale<-function()ggplot2::scale_x_continuous(limits=display_bounds,breaks=seq(display_bounds[1],display_bounds[2],by=10),expand=ggplot2::expansion(mult=c(.01,.01)))
    yscale<-function()ggplot2::scale_y_continuous(limits=c(0,1),breaks=c(0,.25,.5,.75,1),labels=function(x)paste0(100*x,"%"),expand=ggplot2::expansion(mult=c(0,.02)))
    sparse<-stacked[stacked$sparse,,drop=FALSE]
    top<-ggplot2::ggplot(stacked,ggplot2::aes(bmi))+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=0,ymax=with),fill="#8CB8C1")+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=with,ymax=total),fill="#E4BF96")+
      ggplot2::geom_rect(data=sparse,ggplot2::aes(xmin=pmax(bounds[1],bmi-bundle$config$grid_step/2),xmax=pmin(bounds[2],bmi+bundle$config$grid_step/2),ymin=0,ymax=1),fill="white",alpha=.45,inherit.aes=FALSE)+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=total_low,ymax=total_high),fill="grey35",alpha=.20)+
      ggplot2::geom_vline(xintercept=30,linetype="dashed",linewidth=.3,colour="grey40")+
      ggplot2::geom_line(ggplot2::aes(y=total,linetype=sparse,group=segment),linewidth=.65)+
      ggplot2::geom_line(ggplot2::aes(y=with,linetype=sparse,group=segment),colour=colours['with_acidemia'],linewidth=.55)+
      ggplot2::scale_linetype_manual(values=c('FALSE'="solid",'TRUE'="dotted"),guide="none")+xscale()+yscale()+
      ggplot2::labs(title="A  Total hypercapnia, divided into its two components",subtitle="Band thickness = component probability; top boundary = total (95% CI)",x=NULL,y="Modeled probability")+bmi_theme()
    at<-which.min(abs(stacked$bmi-(bounds[1]+.59*diff(bounds))))
    top<-top+ggplot2::annotate("text",x=stacked$bmi[at],y=stacked$with[at]/2,label="With same-day acidemia",size=3.3,colour="#153A45")+
      ggplot2::annotate("label",x=stacked$bmi[at],y=(stacked$with[at]+stacked$total[at])/2,label="Without documented\nsame-day acidemia",size=3.3,lineheight=1.05,colour="#573315",fill="white",alpha=.9,linewidth=0)
    comparison<-ggplot2::ggplot(components,ggplot2::aes(bmi,probability,colour=outcome_id,fill=outcome_id))+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=conf_low,ymax=conf_high),alpha=.17,colour=NA)+
      ggplot2::geom_line(ggplot2::aes(linetype=locally_sparse,group=interaction(outcome_id,segment)),linewidth=.7)+
      ggplot2::scale_colour_manual(values=colours,guide="none")+ggplot2::scale_fill_manual(values=colours,guide="none")+
      ggplot2::scale_linetype_manual(values=c('FALSE'="solid",'TRUE'="dotted"),guide="none")+xscale()+yscale()+
      ggplot2::labs(title="B  Component curves on a common baseline",subtitle="Pointwise 95% intervals; dotted segments mark sparse local evidence",x=NULL,y="Modeled probability")+bmi_theme()
    # Direct labels at an interior BMI stay inside the full-range axis in grayscale.
    for(o in names(label)) {
      z<-components[components$outcome_id==o,];j<-which.min(abs(z$bmi-(bounds[1]+.57*diff(bounds))))
      comparison<-comparison+ggplot2::annotate("text",x=z$bmi[j],y=if(o=="with_acidemia")min(.96,z$conf_high[j]+.045)else max(.03,z$probability[j]-.065),label=if(o=="with_acidemia")label[o]else"Without documented same-day acidemia",colour=colours[o],size=3.2)
    }
    bins<-a$distribution_bins[a$distribution_bins$population_id=="C_same_day_abg"&a$distribution_bins$variable_id=="bmi",]
    # Geometries may straddle the observed endpoints; coordinate clipping does not
    # drop boundary bins or their patients as hard scale limits would.
    freq<-ggplot2::ggplot(bins,ggplot2::aes((lower+upper)/2,n))+
      ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey50")+
      ggplot2::scale_x_continuous(breaks=seq(display_bounds[1],display_bounds[2],by=10),expand=ggplot2::expansion(mult=c(.01,.01)))+
      ggplot2::coord_cartesian(xlim=display_bounds)+
      ggplot2::labs(title="C  Patients in the shared co-observed population",x="BMI (kg/m²)",y="Patients")+bmi_theme()
    utils::write.csv(good,file.path(output,"same-day-component-display.csv"),row.names=FALSE)
    plots<-list(top,comparison,freq)
  }else {
    why<-if(nrow(r))paste(r$status,r$failure_reason,sep=": ")else"No model registered"
    plots<-list(bmi_empty_plot("Stacked components unavailable",why),bmi_empty_plot("Component intervals unavailable",why),bmi_empty_plot("No modeled comparison",why))
  }
  counts<-a$cooccurrence_categories
  fmt<-function(x)ifelse(is.na(x),"unavailable",format(x,big.mark=",",trim=TRUE))
  count<-function(k)fmt(counts$n[match(k,counts$category_id)])
  subtitle<-paste0(bmi_analysis_label(bundle$manifest$source_group),"; model/ref N = ",if(nrow(r))fmt(r$n_model)else"unavailable",
    "; with acidemia: ",count("with_acidemia"),"; without: ",count("without_acidemia"))
  draw<-function() {
    grid::grid.newpage()
    grid::grid.text("BMI and hypercapnia with and without same-day acidemia",x=.02,y=.985,just=c("left","top"),gp=grid::gpar(fontsize=11,fontface="bold"))
    grid::grid.text(if(bundle$manifest$mode=="fixture")"ARTIFICIAL DATA ONLY | not verified same-sample pairing"else"Same recorded-day co-occurrence; not verified same-sample pairing",x=.02,y=.962,just=c("left","top"),gp=grid::gpar(fontsize=9))
    grid::grid.text(subtitle,x=.02,y=.94,just=c("left","top"),gp=grid::gpar(fontsize=9))
    grobs<-lapply(plots,ggplot2::ggplotGrob)
    widths<-do.call(grid::unit.pmax,lapply(grobs,`[[`,"widths"))
    for(i in seq_along(grobs))grobs[[i]]$widths<-widths
    grid::pushViewport(grid::viewport(y=.46,height=.89,layout=grid::grid.layout(3,1,heights=grid::unit(c(2.1,2.1,1),"null"))))
    for(i in 1:3) {grid::pushViewport(grid::viewport(layout.pos.row=i));grid::grid.draw(grobs[[i]]);grid::popViewport()}
    grid::popViewport()
  }
  bmi_export(draw,file.path(output,"S1-same-day-ABG"),height_mm=210)
  caption<-paste("Same recorded-day co-occurrence; not verified same-sample pairing. Fixed-index patients with both arterial analytes share inherited adjustment and their analysis population’s fixed BMI spline.",
    "Any eligible day with PaCO₂ ≥45 mm Hg and pH <7.35 assigns the with-acidemia category; remaining hypercapnic patients have no documented same-day acidemia. Different samples may contribute.",
    "A: band thicknesses give component probabilities; the upper boundary is total hypercapnia. B: components share a baseline. Shading denotes pointwise 95% intervals using full joint covariance. C: shared-population BMI frequencies.",
    "Fading/dotted lines mark local windows below 30 patients or five events/non-events; marginal checks do not establish joint support. These recorded outcomes do not establish simultaneous physiology, acute respiratory failure or compensation. Selection, treatment timing and confounding remain limitations.")
  if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
  data.frame(figure_id="S1-same-day-ABG",caption=caption,alt_text=caption,source_tables="probability_curves;same_day_contrasts;same_day_probability_covariance;cooccurrence_categories;model_registry;distribution_bins")
}

bmi_icd_model_figure <- function(bundle,output,specified=FALSE) {
  family<-if(specified)"icd_acuity_specified"else"icd_acuity"
  figure_id<-if(specified)"S2-ICD-specified"else"S2-ICD-acuity"
  a<-bundle$analysis;id<-paste0(family,"/encounter/multinomial_spline")
  r<-a$model_registry[a$model_registry$model_id==id,]
  z<-a$probability_curves[a$probability_curves$model_id==id & a$probability_curves$status=="estimated",]
  labels<-c(chronic_ohs="Chronic coding / OHS",acute_chronic="Acute-on-chronic or\nconcurrent coding",acute="Acute coding",unspecified="Unspecified acuity")
  if(specified)labels<-labels[names(labels)!="unspecified"]
  colours<-c(chronic_ohs="#25475C",acute_chronic="#BD8F54",acute="#796E85",unspecified="#D8D8D8")
  if(nrow(z)) {
    total<-z[z$outcome_id=="any_target",];grid<-total$bmi
    components<-z[z$outcome_id %in% names(labels),]
    components$label<-factor(labels[components$outcome_id],levels=labels)
    upper<-rep(0,length(grid));stack<-list()
    for(o in names(labels)) {
      v<-components[components$outcome_id==o,];stopifnot(identical(v$bmi,grid))
      v$lower<-upper;v$upper<-upper+v$probability;upper<-v$upper;stack[[o]]<-v
    }
    stopifnot(max(abs(upper-total$probability))<1e-9)
    stack<-bmi_bind(stack);bounds<-c(5*floor(min(grid)/5),5*ceiling(max(grid)/5))
    ymax<-min(1,max(.05,ceiling(max(z$conf_high[z$outcome_id!="no_target"])*20)/20))
    xs<-function()ggplot2::scale_x_continuous(limits=bounds,breaks=seq(bounds[1],bounds[2],10),expand=ggplot2::expansion(mult=c(.01,.01)))
    ys<-function()ggplot2::scale_y_continuous(limits=c(0,ymax),labels=function(x)paste0(round(100*x,1),"%"),expand=ggplot2::expansion(mult=c(0,.03)))
    sparse<-sort(unique(components$bmi[components$locally_sparse]))
    # Merge adjacent windows: tiled translucent rectangles create PDF hairline seams.
    intervals<-if(length(sparse))bmi_bind(lapply(split(sparse,cumsum(c(TRUE,diff(sparse)>bundle$config$grid_step*1.01))),function(x)
      data.frame(low=max(min(grid),min(x)-bundle$config$grid_step/2),high=min(max(grid),max(x)+bundle$config$grid_step/2))))else data.frame(low=numeric(),high=numeric())
    top<-ggplot2::ggplot(stack,ggplot2::aes(bmi))+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=lower,ymax=upper,fill=outcome_id),colour="white",linewidth=.15)+
      ggplot2::geom_rect(data=intervals,ggplot2::aes(xmin=low,xmax=high,ymin=0,ymax=ymax),inherit.aes=FALSE,fill="white",alpha=.45)+
      ggplot2::geom_ribbon(data=total,ggplot2::aes(ymin=conf_low,ymax=conf_high),fill="grey20",alpha=.17)+
      ggplot2::geom_line(data=total,ggplot2::aes(y=probability),linewidth=.65)+
      ggplot2::scale_fill_manual(values=colours,breaks=names(labels),labels=labels,name=NULL)+
      ggplot2::guides(fill=ggplot2::guide_legend(nrow=2,byrow=TRUE))+xs()+ys()+bmi_theme()+
      ggplot2::labs(title="A  Documented diagnoses divided by acuity coding",subtitle="Band thickness = component; upper boundary = total with 95% CI",x=NULL,y="Modeled probability")
    components$segment<-ave(seq_len(nrow(components)),components$outcome_id,FUN=function(ix)cumsum(c(TRUE,head(components$locally_sparse[ix],-1)!=tail(components$locally_sparse[ix],-1))))
    comparison<-ggplot2::ggplot(components,ggplot2::aes(bmi,probability))+
      ggplot2::geom_ribbon(ggplot2::aes(ymin=conf_low,ymax=conf_high),fill="grey65",alpha=.35)+
      ggplot2::geom_line(ggplot2::aes(linetype=locally_sparse,group=interaction(outcome_id,segment)),linewidth=.65)+
      ggplot2::scale_linetype_manual(values=c('FALSE'="solid",'TRUE'="dotted"),guide="none")+
      ggplot2::facet_wrap(~label,ncol=2)+xs()+ys()+bmi_theme()+
      ggplot2::theme(panel.spacing.x=grid::unit(6,"mm"))+
      ggplot2::labs(title="B  Component magnitudes on common axes",subtitle="Pointwise 95% intervals; dotted segments indicate local sparsity",x=NULL,y="Modeled probability")
    bins<-a$distribution_bins[a$distribution_bins$population_id==paste0("C_",family)&a$distribution_bins$variable_id=="bmi",]
    freq<-ggplot2::ggplot(bins,ggplot2::aes((lower+upper)/2,n))+
      ggplot2::geom_col(ggplot2::aes(width=upper-lower),fill="grey50")+
      ggplot2::scale_y_continuous(breaks=function(x)pretty(x,n=2))+
      ggplot2::scale_x_continuous(breaks=seq(bounds[1],bounds[2],10),expand=ggplot2::expansion(mult=c(.01,.01)))+
      ggplot2::coord_cartesian(xlim=bounds)+bmi_theme()+ggplot2::labs(title="C  Patients in the shared diagnosis-capture population",x="BMI (kg/m²)",y="Patients")
    plots<-list(top,comparison,freq)
    utils::write.csv(z,file.path(output,paste0(family,"-component-display.csv")),row.names=FALSE)
  }else {
    why<-if(nrow(r))paste(r$status,r$failure_reason,sep=": ")else"No model registered"
    plots<-list(bmi_empty_plot("ICD components unavailable",why),bmi_empty_plot("Component intervals unavailable",why),bmi_empty_plot("No modeled comparison",why))
  }
  counts<-a$icd_acuity_categories
  fmt<-function(x)ifelse(is.na(x),"unavailable",format(x,big.mark=",",trim=TRUE))
  n<-if(nrow(r))fmt(r$n_model)else"unavailable"
  count<-function(k)fmt(counts$n[match(k,counts$category_id)])
  draw<-function() {
    grid::grid.newpage()
    grid::grid.text(if(specified)"Sensitivity: exclude unspecified-only diagnosis category"else"BMI and documented respiratory-failure acuity / OHS",x=.02,y=.99,just=c("left","top"),gp=grid::gpar(fontsize=11,fontface="bold"))
    grid::grid.text(paste0(if(bundle$manifest$mode=="fixture")"ARTIFICIAL DATA ONLY | "else paste0(bmi_analysis_label(bundle$manifest$source_group)," | "),"Encounter-wide; model/reference N = ",n,if(specified)" | Maximum likelihood"else" | Firth bias reduction"),x=.02,y=.969,just=c("left","top"),gp=grid::gpar(fontsize=9))
    grid::grid.text(paste0("Events: chronic/OHS ",count("chronic_ohs"),"; acute/chronic ",count("acute_chronic"),"; acute ",count("acute"),if(specified)paste0("; excluded ",count("unspecified"))else paste0("; unspecified ",count("unspecified"))),x=.02,y=.95,just=c("left","top"),gp=grid::gpar(fontsize=9))
    grid::pushViewport(grid::viewport(y=.465,height=.91,layout=grid::grid.layout(3,1,heights=grid::unit(c(2.5,3.3,1.2),"null"))))
    for(i in 1:3) {grid::pushViewport(grid::viewport(layout.pos.row=i));grid::grid.draw(ggplot2::ggplotGrob(plots[[i]]));grid::popViewport()}
    grid::popViewport()
  }
  bmi_export(draw,file.path(output,figure_id),height_mm=200)
  caption<-paste(if(specified)"Unpenalized four-category sensitivity excluding unspecified-only encounters and standardizing over the remaining patients."else"Mean-bias-reduced five-category multinomial spline; all diagnosis-evaluable patients in the stated population retained.",
    "Encounter-wide coding, no gas requirement; inherited adjustment and the population-specific spline basis. Bands partition the composite; thickness gives component probability. Shading: pointwise 95% intervals from joint information covariance, conditional on the empirical reference and basis. Fading/dots: local sparsity; histogram N equals model/reference N.",
    "Acute-on-chronic includes explicit or concurrent acute/chronic coding. OHS (obesity hypoventilation syndrome) is analytically chronic; this does not establish chronic respiratory failure. Source selection and diagnostic incorporation limit physiological interpretation.")
  if(!nrow(z))caption<-paste("Adjusted ICD-acuity curves and intervals are unavailable:",why,
    "This is a model-status display, not an estimated relationship. The accompanying table reports observed category counts only when source evidence is qualified. Fixed indexes and inherited adjustment are retained; no fallback estimator was used.")
  if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
  data.frame(figure_id=figure_id,caption=caption,alt_text=caption,source_tables="probability_curves;icd_acuity_categories;icd_acuity_probability_covariance;distribution_bins;model_registry")
}


bmi_icd_observed_figure <- function(bundle,output) {
  a<-bundle$analysis;z<-a$icd_acuity_observed_bands
  caption<-paste("Observed encounter-wide diagnosis proportions within five-unit BMI bands of the covariate-complete analysis population with known capture; no gas requirement.",
    "These are unadjusted descriptions, not fitted curves. Error bars are Wilson 95% intervals; hollow points mark sparse patient/event/non-event counts. The histogram shows each band denominator, shared by every category. Empty bands have no estimate.",
    "OHS is grouped with chronic coding analytically; codes do not establish physiology. Overall percentages and their Wilson intervals are printed in each panel; no-target coding is the complement of the four displayed categories.")
  if(nrow(z)) {
    labels<-bmi_icd_labels[-1];counts<-a$icd_acuity_categories
    subtitles<-vapply(names(labels),function(k) {
      v<-counts[counts$category_id==k,]
      paste0(labels[k],"\n",bmi_percent_ci(100*v$proportion,100*v$conf_low,100*v$conf_high))
    },character(1))
    d<-z[z$category_id %in% names(labels),];d$label<-factor(subtitles[d$category_id],levels=subtitles)
    bounds<-range(c(z$bin_low,z$bin_high));xs<-function()ggplot2::scale_x_continuous(breaks=seq(bounds[1],bounds[2],10),limits=bounds,expand=ggplot2::expansion(mult=c(.01,.01)))
    p<-ggplot2::ggplot(d,ggplot2::aes((bin_low+bin_high)/2,proportion))+
      ggplot2::geom_errorbar(ggplot2::aes(ymin=conf_low,ymax=conf_high),width=1,linewidth=.35)+
      ggplot2::geom_point(ggplot2::aes(shape=sparse),size=1.5)+
      ggplot2::scale_shape_manual(values=c('FALSE'=16,'TRUE'=1),guide="none")+
      ggplot2::scale_y_continuous(labels=function(x)paste0(round(100*x,1),"%"))+
      ggplot2::coord_cartesian(ylim=c(0,max(d$conf_high)*1.02))+
      ggplot2::facet_wrap(~label,ncol=2)+xs()+bmi_theme()+
      ggplot2::theme(panel.spacing.x=grid::unit(6,"mm"))+
      ggplot2::labs(title="Observed diagnosis proportions across BMI",subtitle="Raw proportions and Wilson 95% intervals; hollow points = sparse bands",x=NULL,y="Within-band proportion")
    bins<-z[z$category_id=="no_target",]
    freq<-ggplot2::ggplot(bins,ggplot2::aes((bin_low+bin_high)/2,N))+
      ggplot2::geom_col(ggplot2::aes(width=bin_high-bin_low),fill="grey50")+xs()+bmi_theme()+
      ggplot2::labs(x="Original BMI band (kg/m²)",y="Patients",title=paste0("Known-capture analysis population: N = ",format(sum(bins$N),big.mark=",",trim=TRUE)))
    draw<-function() {
      grid::grid.newpage();grid::pushViewport(grid::viewport(layout=grid::grid.layout(2,1,heights=grid::unit(c(4,1),"null"))))
      for(i in 1:2) {grid::pushViewport(grid::viewport(layout.pos.row=i));grid::grid.draw(ggplot2::ggplotGrob(list(p,freq)[[i]]));grid::popViewport()}
      grid::popViewport()
      if(bundle$manifest$mode=="fixture")grid::grid.text("ARTIFICIAL DATA ONLY",x=.98,y=.995,just=c("right","top"),gp=grid::gpar(fontsize=9))
    }
  }else draw<-function()print(bmi_empty_plot("Observed ICD proportions unavailable","No qualified code-level source evidence"))
  bmi_export(draw,file.path(output,"S2-ICD-observed"),height_mm=190)
  utils::write.csv(z,file.path(output,"icd-observed-display.csv"),row.names=FALSE)
  if(bundle$manifest$mode=="fixture")caption<-paste("ARTIFICIAL DATA ONLY.",caption)
  data.frame(figure_id="S2-ICD-observed",caption=caption,alt_text=caption,source_tables="icd_acuity_observed_bands;icd_acuity_categories")
}

bmi_icd_acuity_figure <- function(bundle,output) bmi_bind(list(
  bmi_icd_model_figure(bundle,output),bmi_icd_model_figure(bundle,output,TRUE),
  bmi_icd_observed_figure(bundle,output)))
