# Same-sample arterial evidence is a secondary module, never an index criterion.
bmi_paired_fields <- c("paired_abg_state","paired_abg_n_pairs","hypercapnia_paired","hypercapnia_acidemic",
  "paired_abg_unpaired_high","paired_abg_conflicts","paired_abg_invalid","paired_abg_usable_pco2","paired_abg_paired_pco2")
bmi_metadata_fields <- c(bmi_metadata_fields,bmi_paired_fields)
bmi_paired_tables <- c("pairing_status","pairing_reconciliation","pairing_availability","pairing_measurements","paired_curve_crossings")
bmi_table_names <- c(bmi_table_names,bmi_paired_tables)

bmi_validate_pairing <- function(d) {
  present<-bmi_paired_fields %in% names(d)
  if(!any(present))return(invisible(TRUE))
  if(!all(present))stop("Incomplete paired-ABG metadata")
  states<-c("valid_pair","no_valid_pair","unresolved","source_unavailable")
  if(anyNA(d$paired_abg_state)||any(!d$paired_abg_state %in% states))stop("Invalid pairing state")
  for(v in bmi_paired_fields[-1]) {
    x<-d[[v]]
    if(!is.numeric(x)||any(!is.na(x)&(!is.finite(x)|x<0|x!=round(x))))stop("Invalid pairing count/outcome: ",v)
  }
  valid<-d$paired_abg_state=="valid_pair";unavailable<-d$paired_abg_state=="source_unavailable"
  if(any(!unavailable & rowSums(is.na(d[setdiff(bmi_paired_fields[-1],c("hypercapnia_paired","hypercapnia_acidemic"))]))>0))stop("Assessed pairing has missing audit counts")
  if(any(valid & (is.na(d$paired_abg_n_pairs)|d$paired_abg_n_pairs<1)) ||
      any(!valid & !is.na(d$paired_abg_n_pairs) & d$paired_abg_n_pairs!=0))stop("Pair availability/count mismatch")
  for(v in c("hypercapnia_paired","hypercapnia_acidemic"))
    if(any(valid & !d[[v]] %in% c(0,1))||any(!valid & !is.na(d[[v]])))stop("Unknown pairing became an outcome")
  if(any(d$hypercapnia_acidemic>d$hypercapnia_paired,na.rm=TRUE))stop("Paired outcomes are not nested")
  if(any(valid & (is.na(d$abg_pco2)|d$abg_pco2<=5|d$abg_pco2>=200)))stop("Pair lacks original valid arterial evidence")
  if(any(d$hypercapnia_paired==1 & d$abg_pco2<45,na.rm=TRUE))stop("Paired positive contradicts original arterial maximum")
  if(any(d$paired_abg_paired_pco2>d$paired_abg_usable_pco2,na.rm=TRUE) ||
      any(d$paired_abg_paired_pco2!=d$paired_abg_n_pairs,na.rm=TRUE))stop("Paired measurement reconciliation failed")
  if(any(unavailable & rowSums(!is.na(d[bmi_paired_fields[-1]]))>0))stop("Unavailable pairing has fabricated counts")
  invisible(TRUE)
}

bmi_pairing_load <- function(loaded,manifest_path) {
  entry<-loaded$manifest$source_evidence_files$paired_abg
  has<-any(bmi_paired_fields %in% names(loaded$data))
  if(is.null(entry)) {
    if(has)stop("Pairing columns require hash-bound enrichment evidence")
    return(loaded)
  }
  path<-entry$path
  if(!grepl("^(/|[A-Za-z]:)",path))path<-file.path(dirname(manifest_path),path)
  if(!identical(tri_sha256(path),entry$sha256))stop("Pairing evidence hash mismatch")
  evidence<-jsonlite::read_json(path,simplifyVector=FALSE)
  extension<-loaded$manifest$paired_abg_extension
  if(!identical(extension$schema_version,1L)||!identical(extension$policy_id,evidence$policy_id)||
      !identical(extension$base_input_sha256,evidence$base_input_sha256)||
      !identical(extension$base_manifest_sha256,evidence$base_manifest_sha256))stop("Pairing extension/base identity mismatch")
  if(!identical(evidence$schema_version,1L)||!identical(evidence$policy_id,"paired_abg_acidemia_v1")||
      !evidence$status %in% c("qualified","unavailable")||!isTRUE(evidence$source_unchanged)||
      !grepl("^[a-f0-9]{64}$",evidence$base_input_sha256)||!has)stop("Invalid pairing enrichment evidence")
  if(evidence$status=="qualified" && (is.null(evidence$policy)||
      !identical(evidence$policy$link_semantics,"one_arterial_collection")))stop("Missing qualified sample linkage")
  lineage<-loaded$manifest$source_evidence_files$lineage$path
  if(!grepl("^(/|[A-Za-z]:)",lineage))lineage<-file.path(dirname(manifest_path),lineage)
  lineage<-jsonlite::read_json(lineage,simplifyVector=FALSE)
  if(!identical(evidence$canonical_database_sha256,lineage$canonical_database_sha256))stop("Pairing source lineage mismatch")
  if(evidence$status=="qualified")for(item in evidence$policy$evidence_files)
    if(!identical(tri_sha256(item$path),item$sha256))stop("Pairing policy source evidence hash mismatch")
  if(evidence$status=="unavailable"&&any(loaded$data$paired_abg_state!="source_unavailable"))stop("Unavailable module contains assessed outcomes")
  bmi_validate_pairing(loaded$data)
  loaded$pairing_evidence<-evidence
  attr(loaded$data,"pairing_evidence")<-evidence
  loaded
}

bmi_append_paired <- function(a,ctx,raw,config,audit_only=FALSE) {
  c<-ctx$members$C; c<-c[c$rfs_group=="primary",,drop=FALSE]
  present<-all(bmi_paired_fields %in% names(c))
  enabled<-isTRUE(config$paired_abg_enabled)
  evidence<-attr(raw,"pairing_evidence")
  qualified<-enabled&&present&&(!all(raw$paired_abg_state=="source_unavailable")||identical(evidence$status,"qualified"))
  status<-if(!enabled)"disabled"else if(qualified)"qualified"else"unavailable"
  reason<-if(!enabled)"Module disabled by configuration"else if(!qualified) {
    if(!is.null(evidence$reason))evidence$reason else "No authenticated same-sample arterial PCO2/pH evidence supplied"
  }else "Same-sample evidence assessed; zeros refer only to evaluable paired samples"
  if(!present) {
    c$paired_abg_state<-rep("source_unavailable",nrow(c))
    for(v in bmi_paired_fields[-1])c[[v]]<-rep(NA_real_,nrow(c))
  }
  bmi_validate_pairing(c)
  p<-c[if(qualified)c$paired_abg_state=="valid_pair"else rep(FALSE,nrow(c)),,drop=FALSE]
  abg<-c[!is.na(c$abg),,drop=FALSE]
  t<-setNames(rep(list(data.frame()),length(bmi_table_names)),bmi_table_names)
  t$pairing_status<-data.frame(module="paired_abg_acidemia_v1",status=status,reason=reason,n_primary_complete=nrow(c),n_paired=if(qualified)nrow(p)else NA_integer_)
  node<-bmi_node("C_paired_abg",p,status=if(qualified)"assessed"else status,label="Same-sample arterial PCO2 and pH")
  if(!qualified)node[c("n_records","n_encounters","n_patients","n")]<-NA_real_
  unpaired<-abg[!abg$paired_abg_state %in% "valid_pair",,drop=FALSE]
  other<-bmi_node("unpaired_abg",unpaired,status=if(qualified)"assessed"else status)
  if(!qualified)other[c("n_records","n_encounters","n_patients","n")]<-NA_real_
  t$cohort_nodes<-t$population_registry<-bmi_bind(list(node,other))
  t$cohort_edges<-data.frame(from="C_abg_encounter",to=c("C_paired_abg","unpaired_abg"),relation="partition",partition_id="paired_evidence",denominator_id="C_abg_encounter")
  t$pairing_reconciliation<-data.frame(stage=c("Original arterial-evaluable","Paired patients: original arterial outcome","Same patients: paired hypercapnia","Same pairs: hypercapnia with acidemia"),
    n=c(nrow(abg),rep(if(qualified)nrow(p)else NA_integer_,3)),
    events=c(sum(abg$abg==1),if(qualified)c(sum(p$abg==1),sum(p$hypercapnia_paired==1),sum(p$hypercapnia_acidemic==1))else rep(NA_integer_,3)),
    status=c("assessed",rep(status,3)))
  availability<-list()
  for(v in c("bmi","age_at_encounter","sex","race_ethnicity","location","encounter_type")) {
    grp<-if(v=="bmi")as.character(config$bmi_bin_width*floor(c$bmi/config$bmi_bin_width))else if(v=="age_at_encounter")as.character(10*floor(c[[v]]/10))else as.character(c[[v]])
    grp[is.na(grp)]<-"Missing"
    for(g in unique(grp)) {
      ix<-which(grp==g);n<-length(ix);m<-if(qualified)sum(c$paired_abg_state[ix]=="valid_pair")else NA_integer_
      ci<-if(qualified)bmi_wilson(m,n)else c(NA_real_,NA_real_)
      availability[[length(availability)+1L]]<-data.frame(variable_id=v,level=g,N=n,paired=m,
        no_valid_pair=if(qualified)sum(c$paired_abg_state[ix]=="no_valid_pair")else NA_integer_,
        unresolved=if(qualified)sum(c$paired_abg_state[ix]=="unresolved")else NA_integer_,
        source_unavailable=if(qualified)sum(c$paired_abg_state[ix]=="source_unavailable")else n,
        proportion=if(qualified)m/n else NA_real_,conf_low=ci[1],conf_high=ci[2],status=status)
    }
  }
  t$pairing_availability<-bmi_bind(availability)
  if(!is.null(evidence$aggregate_counts))t$pairing_measurements<-data.frame(metric=names(evidence$aggregate_counts),value=NA_real_,n=as.numeric(unlist(evidence$aggregate_counts)),scope="source records across original study input indexes")
  if(qualified) {
    counts<-table(p$paired_abg_n_pairs)
    t$pairing_measurements<-bmi_bind(list(t$pairing_measurements,data.frame(metric="valid_pairs_per_patient",value=as.numeric(names(counts)),n=as.numeric(counts),scope="paired population"),
      data.frame(metric=c("usable_arterial_measurements","paired_arterial_measurements","unpaired_hypercapnic_measurements","conflicting_specimen_groups","invalid_analyte_records"),
        value=NA_real_,n=vapply(p[c("paired_abg_usable_pco2","paired_abg_paired_pco2","paired_abg_unpaired_high","paired_abg_conflicts","paired_abg_invalid")],sum,numeric(1)),scope="paired population")))
    members<-list(C_paired_abg=p,unpaired_abg=unpaired)
    profiles<-lapply(names(members),function(id)bmi_profile(members[[id]],id,a$variable_dictionary,config,c))
    for(name in names(profiles[[1]]))t[[name]]<-bmi_bind(lapply(profiles,`[[`,name))
  }
  if(!audit_only) {
    saved_basis<-a$bmi_basis[a$bmi_basis$analysis_population_id=="primary",,drop=FALSE]
    if(nrow(saved_basis)!=4L)stop("Missing primary numeric basis for paired supplement")
    basis<-list(knots=saved_basis$knot,basis_id=saved_basis$basis_id[1],status=saved_basis$status[1],quantile_type=saved_basis$quantile_type[1])
    models<-list();curves<-list()
    for(i in 1:2) {
      outcome<-c("hypercapnia","acidemic_hypercapnia")[i]
      id<-paste("paired_abg","encounter",outcome,"spline",sep="/")
      spec<-data.frame(model_id=id,family="paired_abg",outcome_id=c("hypercapnia_paired","hypercapnia_acidemic")[i],window="encounter",
        training_population_id="C_paired_abg",field=c("hypercapnia_paired","hypercapnia_acidemic")[i],model_form="spline",source_status=if(qualified)"qualified"else"pending",source_reason=reason)
      m<-fit_bmi_model(spec,p,basis,config,nrow(p));models[[id]]<-m
      t$model_registry<-bmi_bind(list(t$model_registry,m$row))
      for(name in c("coefficients","covariance","references")) {
        dest<-c(coefficients="coefficients",covariance="coefficient_covariance",references="factor_references")[[name]]
        t[[dest]]<-bmi_bind(list(t[[dest]],m[[name]]))
      }
      diagnostics<-bmi_model_diagnostics(m,config)
      for(name in names(diagnostics))t[[name]]<-bmi_bind(list(t[[name]],diagnostics[[name]]))
      curves[[id]]<-standardize_probability_curves(m,p,"C_paired_abg",config)
      t$fixed_bmi_contrasts<-bmi_bind(list(t$fixed_bmi_contrasts,bmi_fixed_contrast(m,p,"C_paired_abg",config)))
      if(!is.null(m$fit)) {
        support<-bmi_support(m,p,curves[[id]]$bmi);support$reference_id<-"C_paired_abg";support$policy_id<-"none; relationship";support$method<-"fixed_BMI_curve"
        t$prediction_support<-bmi_bind(list(t$prediction_support,support))
      }
    }
    stopifnot(identical(tri_encounter_key(models[[1]]$data),tri_encounter_key(models[[2]]$data)))
    t$model_sample_audit<-t$model_registry;t$expected_models<-t$model_registry["model_id"]
    t$probability_curves<-bmi_bind(curves)
    x<-curves[[1]];y<-curves[[2]]
    good<-is.finite(x$probability)&is.finite(y$probability)&x$within_training_bmi_range&y$within_training_bmi_range
    crossing<-which(good & y$probability>x$probability+1e-12)
    t$paired_curve_crossings<-if(length(crossing))data.frame(bmi=x$bmi[crossing],excess_probability=y$probability[crossing]-x$probability[crossing],
      locally_sparse=x$locally_sparse[crossing]|y$locally_sparse[crossing],status="crossing_requires_scientific_review")else data.frame(bmi=NA_real_,excess_probability=NA_real_,locally_sparse=NA,status=if(any(good))"no_crossing_on_saved_supported_grid"else"not_assessed")
    t$coverage_index<-data.frame(kind="model",item_id=t$model_registry$model_id,table="model_registry",status=t$model_registry$status)
  }
  t$coverage_index<-bmi_bind(list(t$coverage_index,data.frame(kind="population",item_id=c("C_paired_abg","unpaired_abg"),table="population_registry",status=status)))
  t<-bmi_namespace(t,"primary")
  for(name in names(t)) {
    z<-t[[name]]
    if("model_id" %in% names(z)&&nrow(z)) {
      r<-t$model_registry;ix<-match(z$model_id,r$model_id)
      if(!"population_id" %in% names(z))z$population_id<-"primary"
      if(!"outcome_id" %in% names(z))z$outcome_id<-r$outcome_id[ix]
      if(!"ascertainment_window" %in% names(z))z$ascertainment_window<-r$window[ix]
      if(!"model_form" %in% names(z))z$model_form<-r$model_form[ix]
    }
    a[[name]]<-bmi_bind(list(a[[name]],z))
  }
  a
}
