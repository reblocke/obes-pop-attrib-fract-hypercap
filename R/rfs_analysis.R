# Historical source membership is metadata on a previously selected clinical index.
bmi_rfs_fields <- paste0(c("OBESITY","ABG","VBG","RESPFAIL","VENTSUPPORT","PREDISPOSITION"),"_rfs")
bmi_metadata_fields <- c(bmi_rfs_fields,"bmi_method","reported_bmi","reported_date","height_date","weight_date",
  "height_inches","weight_pounds","bmi_reason","raw_race","raw_ethnicity","obesity_trigger")
bmi_rfs_tables <- c("rfs_summary","rfs_outcomes","rfs_combinations","rfs_by_bmi","bmi_provenance","demographic_crosswalk","prior_run_reconciliation","rfs_semantics","expected_models")
bmi_table_names <- c(bmi_table_names,bmi_rfs_tables)

bmi_validate_metadata <- function(d) {
  for (name in intersect(bmi_rfs_fields,names(d))) {
    x<-d[[name]]
    if(!is.numeric(x)||is.factor(x)||any(!is.na(x)&!x %in% c(0,1)))stop("RFS flags require authenticated 0/1/NA: ",name)
  }
  for(name in intersect(c("reported_date","height_date","weight_date"),names(d)))
    if(!inherits(d[[name]],"Date"))stop("Metadata date must be Date: ",name)
  invisible(TRUE)
}
bmi_classify_rfs <- function(d) {
  for(name in setdiff(bmi_rfs_fields,names(d)))d[[name]]<-rep(NA_real_,nrow(d))
  bmi_validate_metadata(d)
  n<-as.matrix(d[bmi_rfs_fields[-1]])
  positive<-rowSums(n==1,na.rm=TRUE)>0
  zero<-rowSums(n==0,na.rm=TRUE)==5
  o<-d$OBESITY_rfs
  d$rfs_group<-ifelse(positive,"primary",ifelse(o %in% 1 & zero,"obesity_only","unresolved"))
  d$rfs_subgroup<-ifelse(positive,ifelse(is.na(o),"non_obesity_with_unknown_obesity",ifelse(o==1,"overlap","non_obesity_only")),
    ifelse(o %in% 1 & zero,"obesity_only",ifelse(o %in% 0 & zero,"all_zero_discrepancy","rfs_unresolved")))
  # Current-measurement sensitivity uses the selected source, never an alternative BMI.
  d$current_bmi_verified<-rep(NA,nrow(d))
  if("bmi_method" %in% names(d)) {
    reported<-d$bmi_method %in% "current"
    calculated<-grepl("^calculated",d$bmi_method)&!is.na(d$bmi_method)
    if("reported_date" %in% names(d))d$current_bmi_verified[reported]<-d$reported_date[reported]>=d$encounter_date[reported]
    if(all(c("height_date","weight_date") %in% names(d)))d$current_bmi_verified[calculated]<-
      d$height_date[calculated]>=d$encounter_date[calculated]&d$weight_date[calculated]>=d$encounter_date[calculated]
    d$current_bmi_verified[d$bmi_method %in% "prior"]<-FALSE
  }
  for(pair in list(c("reported_date","bmi_lag_days"),c("height_date","height_lag_days"),c("weight_date","weight_lag_days")))
    d[[pair[2]]]<-if(pair[1] %in% names(d))as.numeric(d$encounter_date-d[[pair[1]]])else rep(NA_real_,nrow(d))
  d$component_gap_days<-if(all(c("height_date","weight_date") %in% names(d)))abs(as.numeric(d$height_date-d$weight_date))else rep(NA_real_,nrow(d))
  d
}
bmi_namespace <- function(a,group,remove=FALSE) {
  fields<-c("population_id","reference_id","reference_population_id","training_population_id","denominator_id","from","to","model_id","partition_id")
  for(name in names(a)) {
    d<-a[[name]]
    for(v in intersect(fields,names(d))) {
      if(remove)d[[v]]<-sub(paste0("^",group,"::"),"",d[[v]])
      else {ix<-!is.na(d[[v]])&nzchar(d[[v]]);d[[v]][ix]<-paste0(group,"::",d[[v]][ix])}
    }
    if(name=="coverage_index" && nrow(d)) {
      ix<-d$kind %in% c("population","model")
      d$item_id[ix]<-if(remove)sub(paste0("^",group,"::"),"",d$item_id[ix])else paste0(group,"::",d$item_id[ix])
    }
    if(nrow(d))d$analysis_population_id<-group
    if("window" %in% names(d))d$ascertainment_window<-d$window
    if("reference_id" %in% names(d))d$reference_population_id<-d$reference_id
    a[[name]]<-d
  }
  a
}
bmi_group_view <- function(a,group) {
  result<-lapply(a,function(d) {
    if("analysis_population_id" %in% names(d)) d<-d[d$analysis_population_id %in% group,,drop=FALSE]
    d
  })
  result<-bmi_namespace(result,group,TRUE)
  result$variable_dictionary<-a$variable_dictionary
  result$policy_registry<-a$policy_registry
  result
}
bmi_rfs_audits <- function(ctx,config) {
  q<-bmi_classify_rfs(ctx$members$Q); rows<-outcomes<-combinations<-bins<-provenance<-list()
  for(group in c("primary","obesity_only","unresolved")) {
    d<-q[q$rfs_group==group,,drop=FALSE];complete<-stats::complete.cases(d[triangulation_adjustment])
    rows[[group]]<-data.frame(population_id=group,n=nrow(d),complete=sum(complete),incomplete=sum(!complete),denominator=nrow(q),status="assessed")
  }
  for(sub in c("non_obesity_only","overlap","non_obesity_with_unknown_obesity","obesity_only","rfs_unresolved","all_zero_discrepancy")) {
    d<-q[q$rfs_subgroup==sub,,drop=FALSE]
    for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","any_gas","icd")else c("abg","any_gas")) {
      y<-d[[if(w=="encounter")o else paste0(o,"_index_calendar_day")]];pending<-w!="encounter"&&ctx$day_status=="pending"
      outcomes[[length(outcomes)+1L]]<-data.frame(subgroup=sub,outcome_id=o,ascertainment_window=w,N=nrow(d),evaluable=if(pending)NA_integer_ else sum(!is.na(y)),positive=if(pending)NA_integer_ else sum(y==1,na.rm=TRUE),unknown=if(pending)NA_integer_ else sum(is.na(y)),abg_exactly45=if(pending)NA_integer_ else sum(d[[if(w=="encounter")"abg_pco2"else"abg_pco2_index_day"]]==45,na.rm=TRUE),vbg_exactly50=if(pending)NA_integer_ else sum(d[[if(w=="encounter")"vbg_pco2"else"vbg_pco2_index_day"]]==50,na.rm=TRUE),status=if(pending)"pending_source"else if(!any(y==1,na.rm=TRUE))"zero_events; evaluate source incorporation"else"assessed; source membership not clinical absence")
    }
  }
  pattern<-apply(q[bmi_rfs_fields],1,function(z)paste(ifelse(is.na(z),"?",z),collapse=""))
  for(p in unique(pattern)) {
    z<-q[pattern==p,,drop=FALSE]
    for(o in c("abg","any_gas","icd"))combinations[[length(combinations)+1L]]<-data.frame(pattern=p,flag_order=paste(bmi_rfs_fields,collapse="|"),outcome_id=o,n=nrow(z),evaluable=sum(!is.na(z[[o]])),positive=sum(z[[o]]==1,na.rm=TRUE))
  }
  for(width in unique(c(config$bmi_bin_width,config$diagnostic_bin_width)))for(b in sort(unique(width*floor(q$bmi/width)))) {
    if(width==config$diagnostic_bin_width && (b<config$diagnostic_bmi_range[[1]]||b>=config$diagnostic_bmi_range[[2]]))next
    for(sub in unique(q$rfs_subgroup))for(setting in unique(q$encounter_type)) {
      z<-q[q$rfs_subgroup==sub&q$encounter_type==setting&floor(q$bmi/width)*width==b,,drop=FALSE]
      bins[[length(bins)+1L]]<-data.frame(subgroup=sub,setting=setting,bin_low=b,bin_high=b+width,n=nrow(z),denominator=nrow(q),abg_evaluable=sum(!is.na(z$abg)),gas_evaluable=sum(!is.na(z$any_gas)),abg_positive=sum(z$abg==1,na.rm=TRUE),gas_positive=sum(z$any_gas==1,na.rm=TRUE),icd_positive=sum(z$icd==1,na.rm=TRUE))
    }
  }
  for(stage in names(ctx$members)) {
    if(!stage %in% c("encounter_versions","Q","C","C_abg_encounter","C_any_gas_encounter","C_icd"))next
    d<-bmi_classify_rfs(ctx$members[[stage]])
    method<-if("bmi_method" %in% names(d))ifelse(is.na(d$bmi_method),"[MISSING]",d$bmi_method)else rep("[UNAVAILABLE]",nrow(d))
    state<-ifelse(is.na(d$any_gas),"unavailable",ifelse(d$any_gas==1,"positive","negative"))
    band<-ifelse(is.na(d$bmi),"unknown",ifelse(d$bmi<40,"below40",ifelse(d$bmi<50,"40to50","50plus")))
    grouping<-paste(d$rfs_subgroup,method,band,state,sep="|")
    for(ix in split(seq_len(nrow(d)),grouping)) {
      z<-d[ix,,drop=FALSE]
      for(lag in c("bmi_lag_days","height_lag_days","weight_lag_days","component_gap_days")) {
        x<-z[[lag]];ok<-x[!is.na(x)]
        provenance[[length(provenance)+1L]]<-data.frame(stage=stage,subgroup=z$rfs_subgroup[1],method=method[ix[1]],bmi_band=band[ix[1]],gas_state=state[ix[1]],metric=lag,n=nrow(z),known=sum(!is.na(x)),unknown=sum(is.na(x)),median=if(length(ok))median(ok)else NA_real_,maximum=if(length(ok))max(ok)else NA_real_,status=if(length(ok))"assessed"else"unavailable_or_unknown")
      }
    }
  }
  demo<-if(all(c("raw_race","raw_ethnicity")%in%names(q))) {
    z<-q[c("raw_race","raw_ethnicity","race_ethnicity")];z[]<-lapply(z,function(x)ifelse(is.na(x),"[MISSING]",as.character(x)))
    as.data.frame(table(z),responseName="n",stringsAsFactors=FALSE)
  }else data.frame(status="unavailable; raw demographics not authenticated")
  list(rfs_summary=bmi_bind(rows),rfs_outcomes=bmi_bind(outcomes),rfs_combinations=bmi_bind(combinations),rfs_by_bmi=bmi_bind(bins),bmi_provenance=bmi_bind(provenance),demographic_crosswalk=demo)
}

# One global selection; each kernel receives exactly one fixed encounter per patient.
bmi_run_analysis <- function(raw,config,source_status="artificial",audit_only=FALSE,companion=NULL) {
  if(!all(bmi_rfs_fields %in% names(raw)))stop("Missing authenticated historical RFS fields")
  ctx<-construct_cohort_and_memberships(raw)
  q<-bmi_classify_rfs(ctx$members$Q)
  combined<-bmi_run_population_analysis(raw,config,source_status,audit_only=TRUE,companion=companion)
  combined<-bmi_namespace(combined,"combined")
  audits<-bmi_rfs_audits(ctx,config)
  results<-list(combined);expected<-list()
  parent_basis<-list()
  for(group in unlist(config$analysis_populations)) {
    parent<-sub("_current$","",group)
    d<-q[if(group=="all_obesity")q$OBESITY_rfs %in% 1 else q$rfs_group==parent,,drop=FALSE]
    if(grepl("_current$",group))d<-d[d$current_bmi_verified %in% TRUE,,drop=FALSE]
    if(ctx$day_status=="pending")d[triangulation_index_day_columns]<-NULL
    cfg<-config;cfg$fit_role<-if(group %in% unlist(config$full_model_populations))"full"else"supporting"
    c<-d[stats::complete.cases(d[triangulation_adjustment]),,drop=FALSE]
    basis<-if(grepl("_current$",group))parent_basis[[parent]]else resolve_bmi_basis(c,cfg)
    parent_basis[[group]]<-basis;cfg$basis_override<-basis
    a<-bmi_run_population_analysis(d,cfg,source_status,audit_only=audit_only)
    a<-bmi_namespace(a,group)
    if(grepl("_current$",group) && nrow(a$bmi_basis)) {
      a$bmi_basis$reference_id<-paste0(parent,"::C")
      a$bmi_basis$reference_population_id<-a$bmi_basis$reference_id
    }
    results[[group]]<-a
    registry<-bmi_model_registry(ctx$day_status,cfg$fit_role)
    expected[[group]]<-data.frame(model_id=paste0(group,"::",registry$model_id),analysis_population_id=group)
  }
  unresolved<-q[q$rfs_group=="unresolved",,drop=FALSE]
  if(ctx$day_status=="pending")unresolved[triangulation_index_day_columns]<-NULL
  results[["unresolved"]]<-bmi_namespace(bmi_run_population_analysis(unresolved,config,source_status,audit_only=TRUE),"unresolved")
  result<-setNames(lapply(bmi_table_names,function(name)bmi_bind(lapply(results,`[[`,name))),bmi_table_names)
  result$variable_dictionary<-combined$variable_dictionary
  result$policy_registry<-combined$policy_registry
  for(name in names(audits))result[[name]]<-audits[[name]]
  result$expected_models<-if(audit_only)data.frame()else bmi_bind(expected)
  for(name in names(result))if("model_id" %in% names(result[[name]]) && nrow(result[[name]])) {
    z<-result[[name]];r<-result$model_registry;ix<-match(z$model_id,r$model_id)
    if(!"population_id" %in% names(z))z$population_id<-z$analysis_population_id
    if(!"outcome_id" %in% names(z))z$outcome_id<-r$outcome_id[ix]
    if(!"ascertainment_window" %in% names(z))z$ascertainment_window<-r$window[ix]
    if(!"model_form" %in% names(z))z$model_form<-r$model_form[ix]
    if(name=="policy_totals")z$n_events<-r$n_events[ix]
    result[[name]]<-z
  }
  if(!is.null(companion$rfs_provenance))result$bmi_provenance<-bmi_bind(list(result$bmi_provenance[result$bmi_provenance$stage!="encounter_versions",],companion$rfs_provenance))
  result$prior_run_reconciliation<-data.frame(requirement=c("prior_run_keys_and_fields","alternative_index_after_pathway_removal","cross_project_decomposition"),status="not_assessed",note="Requires private authenticated candidate/input comparisons; no equality inferred from totals")
  result$rfs_semantics<-data.frame(requirement="historical_source_membership_v1",status=if(source_status=="artificial")"artificial_fixture"else"See hash-bound RFS evidence",note="Historical extraction membership; zeros do not establish clinical absence. Trigger unavailable unless authenticated directly.")
  # The index partition is disjoint; all-OBESITY and current-measurement groups overlap.
  edges<-lapply(c("primary","obesity_only"),function(g)data.frame(from="combined::Q",to=paste0(g,"::Q"),relation="partition",partition_id="rfs_index",denominator_id="combined::Q"))
  edges[[3]]<-data.frame(from="combined::Q",to="unresolved::Q",relation="partition",partition_id="rfs_index",denominator_id="combined::Q")
  result$cohort_edges<-bmi_bind(c(list(result$cohort_edges),edges));result$population_registry<-result$population_registry
  result$coverage_index<-bmi_bind(list(result$coverage_index,data.frame(kind="population",item_id="unresolved::Q",table="rfs_summary",status="assessed")))
  result$numerical_reconciliation<-bmi_validate_ledger(result)
  result
}
