# Population-aware views; all numerical figures read saved aggregates only.
bmi_export_figures <- function(bundle,output) {
  dir.create(output,recursive=TRUE,showWarnings=FALSE)
  all_captions<-all_manifests<-all_atlas<-list()
  for(group in c("combined","unresolved",unlist(bundle$config$analysis_populations))) {
    view<-bmi_group_view(bundle$analysis,group)
    if(!nrow(view$cohort_nodes))next
    child<-bundle;child$analysis<-view
    folder<-file.path(output,group)
    bmi_export_population_figures(child,folder)
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
    bmi_export(function()print(bmi_edge_plot(a,partition)),file.path(output,"RFS-flow"),height_mm=150)
    caption<-"Fixed common indexes partition into primary non-OBESITY-supported source entry, obesity-only source entry and unresolved RFS. Overlapping OBESITY/non-OBESITY membership remains primary. Counts and units derive from the ledger; all-OBESITY supporting models overlap and are not a fourth partition branch."
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
      ggplot2::labs(title="Historical source-entry membership across BMI",subtitle="Fixed common indexes; counts, not equal-area densities",x="BMI (kg/m2)",y="Indexed patients",fill="Source-entry subgroup")+bmi_theme()+
      ggplot2::theme(legend.text=ggplot2::element_text(size=9))
    stem<-file.path(output,"RFS-entry");bmi_export(function()print(plot),stem,height_mm=190)
    caption<-"Historical source-entry subgroup counts by BMI, pooling the two acute settings on fixed indexes. Overlap remains in primary; obesity-only is a separate selection sensitivity. Membership records source-file representation, not exhaustive clinical criteria. Unresolved and all-zero discrepancies are retained. All groups partition the common indexed population. No association or causal bias correction follows from this partition."
    all_captions[["entry"]]<-data.frame(figure_id="RFS-entry",caption=caption,alt_text=caption,source_tables="rfs_by_bmi")
  }
  for(id in c("RFS-flow","RFS-entry"))if(file.exists(file.path(output,paste0(id,".png")))) {
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
  jsonlite::write_json(list(same_saved_values=TRUE,clinical_reads=0,model_refits=0,visual_inspection="pending",populations=bundle$config$analysis_populations),file.path(output,"figure-data-receipt.json"),auto_unbox=TRUE,pretty=TRUE)
}
