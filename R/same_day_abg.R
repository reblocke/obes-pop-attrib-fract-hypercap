# Recorded-day co-occurrence is supplemental evidence, never an index criterion.
bmi_same_day_fields <- c("same_day_abg_state","same_day_abg_n_days","hypercapnia_coobserved",
  "hypercapnia_acidemia_same_day","same_day_abg_noncoobserved_high","same_day_abg_invalid_records",
  "same_day_abg_undated_records","same_day_abg_excluded_records","same_day_abg_duplicate_records",
  "same_day_abg_usable_pco2","same_day_abg_coobserved_pco2","same_day_abg_usable_ph",
  "same_day_abg_coobserved_ph","same_day_abg_co2_only_days","same_day_abg_ph_only_days",
  "same_day_abg_multiple_result_days")
bmi_metadata_fields <- c(bmi_metadata_fields,bmi_same_day_fields)
bmi_same_day_tables <- c("cooccurrence_status","cooccurrence_reconciliation","cooccurrence_availability",
  "cooccurrence_measurements","same_day_curve_crossings")
bmi_table_names <- c(bmi_table_names,bmi_same_day_tables)

bmi_validate_cooccurrence <- function(d) {
  present <- bmi_same_day_fields %in% names(d)
  if(!any(present))return(invisible(TRUE))
  if(!all(present))stop("Incomplete same-day arterial metadata")
  states <- c("coobserved_day","no_coobserved_day","unresolved","source_unavailable")
  if(anyNA(d$same_day_abg_state)||any(!d$same_day_abg_state %in% states))stop("Invalid co-occurrence state")
  for(v in bmi_same_day_fields[-1]) {
    x <- d[[v]]
    if(!is.numeric(x)||any(!is.na(x)&(!is.finite(x)|x<0|x!=round(x))))stop("Invalid day count/outcome: ",v)
  }
  valid <- d$same_day_abg_state=="coobserved_day"
  unavailable <- d$same_day_abg_state=="source_unavailable"
  outcomes <- c("hypercapnia_coobserved","hypercapnia_acidemia_same_day")
  counts <- setdiff(bmi_same_day_fields[-1],outcomes)
  if(any(!unavailable & rowSums(is.na(d[counts]))>0))stop("Assessed co-occurrence has missing counts")
  if(any(valid & (is.na(d$same_day_abg_n_days)|d$same_day_abg_n_days<1)) ||
      any(!valid & !is.na(d$same_day_abg_n_days) & d$same_day_abg_n_days!=0))stop("Co-observation/count mismatch")
  for(v in outcomes)
    if(any(valid & !d[[v]] %in% c(0,1))||any(!valid & !is.na(d[[v]])))stop("Unknown co-occurrence became an outcome")
  if(any(d$hypercapnia_acidemia_same_day>d$hypercapnia_coobserved,na.rm=TRUE))stop("Same-day outcomes are not nested")
  if(any(valid & (is.na(d$abg_pco2)|d$abg_pco2<=5|d$abg_pco2>=200)))stop("Co-observed day lacks original arterial evidence")
  if(any(d$hypercapnia_coobserved==1 & d$abg_pco2<45,na.rm=TRUE))stop("Same-day positive contradicts original arterial maximum")
  for(analyte in c("pco2","ph")) {
    co <- d[[paste0("same_day_abg_coobserved_",analyte)]]
    usable <- d[[paste0("same_day_abg_usable_",analyte)]]
    if(any(co>usable | co<d$same_day_abg_n_days,na.rm=TRUE))stop("Day/measurement reconciliation failed")
  }
  if(any(d$same_day_abg_multiple_result_days>d$same_day_abg_n_days,na.rm=TRUE))stop("Multiplicity exceeds co-observed days")
  if(any(unavailable & rowSums(!is.na(d[bmi_same_day_fields[-1]]))>0))stop("Unavailable source has fabricated counts")
  invisible(TRUE)
}

bmi_cooccurrence_load <- function(loaded,manifest_path) {
  entry<-loaded$manifest$source_evidence_files$same_day_abg
  has<-any(bmi_same_day_fields %in% names(loaded$data))
  if(is.null(entry)) {
    if(has)stop("Co-occurrence columns require hash-bound enrichment evidence")
    return(loaded)
  }
  path<-entry$path
  if(!grepl("^(/|[A-Za-z]:)",path))path<-file.path(dirname(manifest_path),path)
  if(!identical(tri_sha256(path),entry$sha256))stop("Co-occurrence evidence hash mismatch")
  evidence<-jsonlite::read_json(path,simplifyVector=FALSE)
  extension<-loaded$manifest$same_day_abg_extension
  if(!identical(extension$schema_version,1L)||!identical(extension$policy_id,evidence$policy_id)||
      !identical(extension$base_input_sha256,evidence$base_input_sha256)||
      !identical(extension$base_manifest_sha256,evidence$base_manifest_sha256))stop("Co-occurrence extension/base identity mismatch")
  if(!identical(evidence$schema_version,1L)||!identical(evidence$policy_id,"same_day_arterial_cooccurrence_v1")||
      !evidence$status %in% c("qualified","unavailable")||!isTRUE(evidence$source_unchanged)||
      !grepl("^[a-f0-9]{64}$",evidence$base_input_sha256)||!has)stop("Invalid co-occurrence enrichment evidence")
  if(evidence$status=="qualified" && (is.null(evidence$policy)||
      !identical(evidence$policy$date_semantics,"recorded_result_calendar_date")))stop("Missing qualified recorded-date semantics")
  lineage<-loaded$manifest$source_evidence_files$lineage$path
  if(!grepl("^(/|[A-Za-z]:)",lineage))lineage<-file.path(dirname(manifest_path),lineage)
  lineage<-jsonlite::read_json(lineage,simplifyVector=FALSE)
  if(!identical(evidence$canonical_database_sha256,lineage$canonical_database_sha256))stop("Co-occurrence source lineage mismatch")
  if(evidence$status=="qualified")for(item in evidence$policy$evidence_files)
    if(!identical(tri_sha256(item$path),item$sha256))stop("Co-occurrence policy source evidence hash mismatch")
  if(evidence$status=="unavailable"&&any(loaded$data$same_day_abg_state!="source_unavailable"))stop("Unavailable module contains assessed outcomes")
  bmi_validate_cooccurrence(loaded$data)
  loaded$cooccurrence_evidence<-evidence
  attr(loaded$data,"cooccurrence_evidence")<-evidence
  loaded
}

bmi_append_same_day <- function(a,ctx,raw,config,audit_only=FALSE) {
  c<-ctx$members$C; c<-c[c$rfs_group=="primary",,drop=FALSE]
  present<-all(bmi_same_day_fields %in% names(c))
  enabled<-isTRUE(config$same_day_abg_enabled)
  evidence<-attr(raw,"cooccurrence_evidence")
  qualified<-enabled&&present&&(!all(raw$same_day_abg_state=="source_unavailable")||identical(evidence$status,"qualified"))
  status<-if(!enabled)"disabled"else if(qualified)"qualified"else"unavailable"
  reason<-if(!enabled)"Module disabled by configuration"else if(!qualified) {
    if(!is.null(evidence$reason))evidence$reason else "No authenticated recorded-day arterial co-occurrence evidence supplied"
  }else "Recorded-day evidence assessed; zeros refer only to co-observed days"
  if(!present) {
    c$same_day_abg_state<-rep("source_unavailable",nrow(c))
    for(v in bmi_same_day_fields[-1])c[[v]]<-rep(NA_real_,nrow(c))
  }
  bmi_validate_cooccurrence(c)
  p<-c[if(qualified)c$same_day_abg_state=="coobserved_day"else rep(FALSE,nrow(c)),,drop=FALSE]
  abg<-c[!is.na(c$abg),,drop=FALSE]
  t<-setNames(rep(list(data.frame()),length(bmi_table_names)),bmi_table_names)
  t$cooccurrence_status<-data.frame(module="same_day_arterial_cooccurrence_v1",status=status,reason=reason,n_primary_complete=nrow(c),n_coobserved=if(qualified)nrow(p)else NA_integer_)
  node<-bmi_node("C_same_day_abg",p,status=if(qualified)"assessed"else status,label="Same recorded-day arterial PCO2 and pH")
  if(!qualified)node[c("n_records","n_encounters","n_patients","n")]<-NA_real_
  unpaired<-abg[!abg$same_day_abg_state %in% "coobserved_day",,drop=FALSE]
  other<-bmi_node("no_coobserved_abg",unpaired,status=if(qualified)"assessed"else status)
  if(!qualified)other[c("n_records","n_encounters","n_patients","n")]<-NA_real_
  t$cohort_nodes<-t$population_registry<-bmi_bind(list(node,other))
  t$cohort_edges<-data.frame(from="C_abg_encounter",to=c("C_same_day_abg","no_coobserved_abg"),relation="partition",partition_id="same_day_evidence",denominator_id="C_abg_encounter")
  t$cooccurrence_reconciliation<-data.frame(stage=c("Original arterial-evaluable","Co-observed patients: original arterial outcome","Same patients: hypercapnia on co-observed days","Same patients: same-day hypercapnia and acidemia"),
    n=c(nrow(abg),rep(if(qualified)nrow(p)else NA_integer_,3)),
    events=c(sum(abg$abg==1),if(qualified)c(sum(p$abg==1),sum(p$hypercapnia_coobserved==1),sum(p$hypercapnia_acidemia_same_day==1))else rep(NA_integer_,3)),
    status=c("assessed",rep(status,3)))
  rec<-t$cooccurrence_reconciliation
  ci<-t(vapply(seq_len(nrow(rec)),function(i) {
    if(is.na(rec$n[i])||rec$n[i]==0)return(c(NA_real_,NA_real_))
    bmi_wilson(rec$events[i],rec$n[i])
  },numeric(2)))
  t$cooccurrence_reconciliation$proportion<-ifelse(rec$n>0,rec$events/rec$n,NA_real_)
  t$cooccurrence_reconciliation$conf_low<-ci[,1]
  t$cooccurrence_reconciliation$conf_high<-ci[,2]
  availability<-list()
  for(v in c("bmi","age_at_encounter","sex","race_ethnicity","location","encounter_type")) {
    grp<-if(v=="bmi")as.character(config$bmi_bin_width*floor(c$bmi/config$bmi_bin_width))else if(v=="age_at_encounter")as.character(10*floor(c[[v]]/10))else as.character(c[[v]])
    grp[is.na(grp)]<-"Missing"
    for(g in unique(grp)) {
      ix<-which(grp==g);n<-length(ix);m<-if(qualified)sum(c$same_day_abg_state[ix]=="coobserved_day")else NA_integer_
      ci<-if(qualified)bmi_wilson(m,n)else c(NA_real_,NA_real_)
      availability[[length(availability)+1L]]<-data.frame(variable_id=v,level=g,N=n,coobserved=m,
        no_coobserved_day=if(qualified)sum(c$same_day_abg_state[ix]=="no_coobserved_day")else NA_integer_,
        unresolved=if(qualified)sum(c$same_day_abg_state[ix]=="unresolved")else NA_integer_,
        source_unavailable=if(qualified)sum(c$same_day_abg_state[ix]=="source_unavailable")else n,
        proportion=if(qualified)m/n else NA_real_,conf_low=ci[1],conf_high=ci[2],status=status)
    }
  }
  t$cooccurrence_availability<-bmi_bind(availability)
  if(!is.null(evidence$aggregate_counts))t$cooccurrence_measurements<-data.frame(metric=names(evidence$aggregate_counts),value=NA_real_,n=as.numeric(unlist(evidence$aggregate_counts)),scope="source records across original study input indexes")
  if(qualified) {
    counts<-table(p$same_day_abg_n_days)
    t$cooccurrence_measurements<-bmi_bind(list(t$cooccurrence_measurements,
      data.frame(metric="coobserved_days_per_patient",value=as.numeric(names(counts)),n=as.numeric(counts),scope="co-observed population")))
    for(group in c("primary_complete","coobserved_population")) {
      rows<-if(group=="primary_complete")c[c$same_day_abg_state!="source_unavailable",,drop=FALSE] else p
      fields<-setdiff(bmi_same_day_fields,c("same_day_abg_state","hypercapnia_coobserved","hypercapnia_acidemia_same_day"))
      t$cooccurrence_measurements<-bmi_bind(list(t$cooccurrence_measurements,
        data.frame(metric=fields,value=NA_real_,n=vapply(rows[fields],function(x)sum(x,na.rm=TRUE),numeric(1)),scope=paste0("assessed_",group),n_encounters=nrow(rows))))
    }
    members<-list(C_same_day_abg=p,no_coobserved_abg=unpaired)
    profiles<-lapply(names(members),function(id)bmi_profile(members[[id]],id,a$variable_dictionary,config,c))
    for(name in names(profiles[[1]]))t[[name]]<-bmi_bind(lapply(profiles,`[[`,name))
  }
  if(!audit_only) {
    saved_basis<-a$bmi_basis[a$bmi_basis$analysis_population_id=="primary",,drop=FALSE]
    if(nrow(saved_basis)!=4L)stop("Missing primary numeric basis for co-occurrence supplement")
    basis<-list(knots=saved_basis$knot,basis_id=saved_basis$basis_id[1],status=saved_basis$status[1],quantile_type=saved_basis$quantile_type[1])
    models<-list();curves<-list()
    for(i in 1:2) {
      outcome<-c("hypercapnia","hypercapnia_acidemia_cooccurrence")[i]
      id<-paste("same_day_abg","encounter",outcome,"spline",sep="/")
      spec<-data.frame(model_id=id,family="same_day_abg",outcome_id=c("hypercapnia_coobserved","hypercapnia_acidemia_same_day")[i],window="encounter",
        training_population_id="C_same_day_abg",field=c("hypercapnia_coobserved","hypercapnia_acidemia_same_day")[i],model_form="spline",source_status=if(qualified)"qualified"else"pending",source_reason=reason)
      m<-fit_bmi_model(spec,p,basis,config,nrow(p));models[[id]]<-m
      t$model_registry<-bmi_bind(list(t$model_registry,m$row))
      for(name in c("coefficients","covariance","references")) {
        dest<-c(coefficients="coefficients",covariance="coefficient_covariance",references="factor_references")[[name]]
        t[[dest]]<-bmi_bind(list(t[[dest]],m[[name]]))
      }
      diagnostics<-bmi_model_diagnostics(m,config)
      for(name in names(diagnostics))t[[name]]<-bmi_bind(list(t[[name]],diagnostics[[name]]))
      curves[[id]]<-standardize_probability_curves(m,p,"C_same_day_abg",config)
      t$fixed_bmi_contrasts<-bmi_bind(list(t$fixed_bmi_contrasts,bmi_fixed_contrast(m,p,"C_same_day_abg",config)))
      if(!is.null(m$fit)) {
        support<-bmi_support(m,p,curves[[id]]$bmi);support$reference_id<-"C_same_day_abg";support$policy_id<-"none; relationship";support$method<-"fixed_BMI_curve"
        t$prediction_support<-bmi_bind(list(t$prediction_support,support))
      }
    }
    stopifnot(identical(tri_encounter_key(models[[1]]$data),tri_encounter_key(models[[2]]$data)))
    t$model_sample_audit<-t$model_registry;t$expected_models<-t$model_registry["model_id"]
    t$probability_curves<-bmi_bind(curves)
    x<-curves[[1]];y<-curves[[2]]
    good<-is.finite(x$probability)&is.finite(y$probability)&x$within_training_bmi_range&y$within_training_bmi_range
    crossing<-which(good & y$probability>x$probability+1e-12)
    t$same_day_curve_crossings<-if(length(crossing))data.frame(bmi=x$bmi[crossing],excess_probability=y$probability[crossing]-x$probability[crossing],
      locally_sparse=x$locally_sparse[crossing]|y$locally_sparse[crossing],status="crossing_requires_scientific_review")else data.frame(bmi=NA_real_,excess_probability=NA_real_,locally_sparse=NA,status=if(any(good))"no_crossing_on_saved_supported_grid"else"not_assessed")
    t$coverage_index<-data.frame(kind="model",item_id=t$model_registry$model_id,table="model_registry",status=t$model_registry$status)
  }
  t$coverage_index<-bmi_bind(list(t$coverage_index,data.frame(kind="population",item_id=c("C_same_day_abg","no_coobserved_abg"),table="population_registry",status=status)))
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
