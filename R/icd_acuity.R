# Optional encounter diagnosis decomposition; never an index or PIF criterion.
bmi_icd_flags <- paste0("icd_",c("J9602","J9612","J9622","J9692","E662"))
bmi_icd_fields <- c("icd_capture_state",bmi_icd_flags)
bmi_icd_classes <- c("no_target","chronic_ohs","acute_chronic","acute","unspecified")
bmi_icd_labels <- c(no_target="No target diagnosis documented",chronic_ohs="Chronic coding / OHS",
  acute_chronic="Acute-on-chronic or concurrent coding",acute="Acute coding",unspecified="Unspecified acuity")
bmi_metadata_fields <- c(bmi_metadata_fields,bmi_icd_fields)
bmi_icd_tables <- c("icd_acuity_status","icd_acuity_categories","icd_acuity_patterns","icd_acuity_reconciliation",
  "icd_acuity_contrasts","icd_acuity_probability_covariance","icd_acuity_curve_reconciliation","icd_acuity_observed_bands")
bmi_table_names <- c(bmi_table_names,bmi_icd_tables)

bmi_icd_category <- function(d) {
  x<-rep(NA_character_,nrow(d));ok<-d$icd_capture_state=="complete"
  x[ok]<-"no_target"
  x[ok & d$icd_J9692 %in% 1]<-"unspecified"
  x[ok & (d$icd_J9612 %in% 1 | d$icd_E662 %in% 1)]<-"chronic_ohs"
  x[ok & d$icd_J9602 %in% 1]<-"acute"
  x[ok & (d$icd_J9622 %in% 1 | (d$icd_J9602 %in% 1 & (d$icd_J9612 %in% 1 | d$icd_E662 %in% 1)))]<-"acute_chronic"
  factor(x,levels=bmi_icd_classes)
}
bmi_icd_spec <- function(specified=FALSE) {
  classes<-if(specified)bmi_icd_classes[1:4]else bmi_icd_classes
  pairs<-lapply(combn(2:length(classes),2,simplify=FALSE),rev)
  list(family=if(specified)"icd_acuity_specified"else"icd_acuity",classes=classes,
    category=function(d)factor(bmi_icd_category(d),levels=classes),total="any_target",
    estimator=if(specified)"maximum_likelihood"else"firth_mean_bias_reduced_v1",
    contrast_pairs=pairs,contrast_names=vapply(pairs,function(x)paste0(classes[x[1]],"_minus_",classes[x[2]],"_change"),character(1)),table_prefix="icd_acuity")
}

bmi_validate_icd_acuity <- function(d) {
  present<-bmi_icd_fields %in% names(d)
  if(!any(present))return(invisible(TRUE))
  if(!all(present))stop("Incomplete ICD acuity extension")
  if(anyNA(d$icd_capture_state)||any(!d$icd_capture_state %in% c("complete","incomplete","unavailable")))stop("Invalid ICD capture state")
  for(v in bmi_icd_flags)if(!is.numeric(d[[v]])||any(!is.na(d[[v]]) & !d[[v]] %in% c(0,1)))stop("Invalid ICD code flag: ",v)
  complete<-d$icd_capture_state=="complete"
  if(any(complete & rowSums(is.na(d[bmi_icd_flags]))>0))stop("Complete ICD capture has unknown flags")
  if(any(!complete & rowSums(d[bmi_icd_flags]==0,na.rm=TRUE)>0))stop("Incomplete ICD capture cannot establish absent codes")
  composite<-if("icd_hypercapnia" %in% names(d))d$icd_hypercapnia else d$icd
  if(is.null(composite))stop("Missing original ICD comparator")
  positive<-rowSums(d[bmi_icd_flags]==1,na.rm=TRUE)>0
  if(any(complete & (is.na(composite)|composite!=as.integer(positive))))stop("ICD subtype union disagrees with original composite")
  invisible(TRUE)
}
bmi_icd_load <- function(loaded,manifest_path) {
  entry<-loaded$manifest$source_evidence_files$icd_acuity
  has<-any(bmi_icd_fields %in% names(loaded$data))
  if(is.null(entry)) {if(has)stop("ICD columns require hash-bound evidence");return(loaded)}
  path<-entry$path
  if(!grepl("^(/|[A-Za-z]:)",path))path<-file.path(dirname(manifest_path),path)
  if(!identical(tri_sha256(path),entry$sha256))stop("ICD acuity evidence hash mismatch")
  e<-jsonlite::read_json(path,simplifyVector=FALSE)
  if(!has||!identical(e$schema_version,1L)||!identical(e$policy_id,"icd_acuity_v1")||
     !e$status %in% c("qualified","unavailable")||!isTRUE(e$source_unchanged)||
     !identical(e$input_sha256,loaded$manifest$input_sha256)||
     !identical(e$selection_sha256,loaded$manifest$source_evidence_files$selection$sha256))stop("Invalid ICD acuity identity/evidence")
  lineage<-loaded$manifest$source_evidence_files$lineage$path
  if(!grepl("^(/|[A-Za-z]:)",lineage))lineage<-file.path(dirname(manifest_path),lineage)
  if(!identical(e$canonical_database_sha256,jsonlite::read_json(lineage)$canonical_database_sha256))stop("ICD acuity source lineage mismatch")
  if(e$status=="qualified" && (!isTRUE(e$diagnosis_capture_complete)||!length(e$diagnosis_code_systems)||
      !setequal(unlist(e$target_codes),sub("icd_","",bmi_icd_flags))))stop("Unqualified ICD code/capture policy")
  if(e$status=="unavailable"&&any(loaded$data$icd_capture_state=="complete"))stop("Unavailable ICD evidence contains complete capture")
  bmi_validate_icd_acuity(loaded$data)
  attr(loaded$data,"icd_acuity_evidence")<-e;loaded$icd_acuity_evidence<-e;loaded
}

bmi_integrate_icd_acuity <- function(a,ctx,raw,config,audit_only=FALSE,source_status="artificial",population="primary") {
  if(!identical(config$icd_acuity_estimator,"firth_mean_bias_reduced_v1") ||
     !isTRUE(config$icd_acuity_specified_sensitivity))stop("Unsupported ICD estimator/registry configuration")
  c<-ctx$members$C
  present<-all(bmi_icd_fields %in% names(c));e<-attr(raw,"icd_acuity_evidence")
  qualified<-isTRUE(config$icd_acuity_enabled)&&present&&(source_status %in% c("artificial","artificial_only")||identical(e$status,"qualified"))
  reason<-if(qualified)"Complete encounter diagnosis capture; inherited five-code composite"else"No qualified code-level diagnosis enrichment supplied (or module disabled)"
  if(!present) {c$icd_capture_state<-rep("unavailable",nrow(c));for(v in bmi_icd_flags)c[[v]]<-rep(NA_real_,nrow(c))}
  bmi_validate_icd_acuity(c)
  p<-c[if(qualified)c$icd_capture_state=="complete"else rep(FALSE,nrow(c)),,drop=FALSE]
  t<-setNames(rep(list(data.frame()),length(bmi_table_names)),bmi_table_names)
  status<-if(qualified)"qualified"else"unavailable"
  t$icd_acuity_status<-data.frame(module="icd_acuity_v1",status=status,reason=reason,n_primary_complete=nrow(c),n_complete_capture=if(qualified)nrow(p)else NA_integer_)
  counts<-if(qualified)as.integer(table(bmi_icd_category(p)))else rep(NA_integer_,5)
  t$icd_acuity_categories<-data.frame(category_id=bmi_icd_classes,label=unname(bmi_icd_labels),n=counts,N=if(qualified)nrow(p)else NA_integer_,status=status)
  ci<-t(vapply(counts,function(n)if(is.na(n)||!nrow(p))c(NA_real_,NA_real_)else bmi_wilson(n,nrow(p)),numeric(2)))
  t$icd_acuity_categories$proportion<-if(nrow(p))counts/nrow(p)else NA_real_
  t$icd_acuity_categories$conf_low<-ci[,1];t$icd_acuity_categories$conf_high<-ci[,2]
  t$icd_acuity_reconciliation<-data.frame(metric=c("complete_capture","incomplete_capture","unavailable_capture","original_composite_positive","classified_positive"),
    n=if(qualified)c(nrow(p),sum(c$icd_capture_state=="incomplete"),sum(c$icd_capture_state=="unavailable"),sum(p$icd==1),sum(counts[-1]))else rep(NA_integer_,5),status=status)
  node<-bmi_node("C_icd_acuity",p,status=if(qualified)"assessed"else"unavailable",label="Complete diagnosis capture for ICD acuity")
  if(!qualified)node[c("n_records","n_encounters","n_patients","n")]<-NA_real_
  t$cohort_nodes<-t$population_registry<-node
  if(qualified) {
    profiles<-bmi_profile(p,"C_icd_acuity",a$variable_dictionary,config,c)
    for(name in names(profiles))t[[name]]<-profiles[[name]]
    p$pattern<-apply(p[bmi_icd_flags],1,paste0,collapse="")
    p$band<-config$bmi_bin_width*floor(p$bmi/config$bmi_bin_width)
    pattern_rows<-lapply(split(seq_len(nrow(p)),paste(p$pattern,p$band,p$rfs_subgroup,sep="|")),function(ix) {
      z<-p[ix,,drop=FALSE]
      data.frame(pattern=z$pattern[1],bin_low=z$band[1],bin_high=z$band[1]+config$bmi_bin_width,rfs_subgroup=z$rfs_subgroup[1],n=nrow(z),
        category_id=as.character(bmi_icd_category(z)[1]),explicit_acute_chronic=z$icd_J9622[1]==1,
        concurrent_acute_chronic=z$icd_J9602[1]==1&&(z$icd_J9612[1]==1||z$icd_E662[1]==1),
        chronic_provenance=if(z$icd_J9612[1]==1&&z$icd_E662[1]==1)"J9612_and_E662"else if(z$icd_J9612[1]==1)"J9612_only"else if(z$icd_E662[1]==1)"E662_only"else"neither")
    })
    t$icd_acuity_patterns<-bmi_bind(pattern_rows)
    t$icd_acuity_observed_bands<-bmi_bind(lapply(sort(unique(p$band)),function(lo) {
      d<-p[p$band==lo,,drop=FALSE];n<-as.integer(table(bmi_icd_category(d)))
      ci<-t(vapply(n,function(v)bmi_wilson(v,nrow(d)),numeric(2)))
      data.frame(category_id=bmi_icd_classes,bin_low=lo,bin_high=lo+config$bmi_bin_width,
        n=n,N=nrow(d),proportion=n/nrow(d),conf_low=ci[,1],conf_high=ci[,2],
        sparse=nrow(d)<config$sparse_n | pmin(n,nrow(d)-n)<config$sparse_events,
        status="observed",denominator="Primary covariate-complete known diagnosis capture")
    }))
  }
  p$pattern<-p$band<-NULL
  if(!audit_only) {
    b<-a$bmi_basis[a$bmi_basis$analysis_population_id==population,]
    if(nrow(b)!=4)stop("Missing primary basis for ICD acuity")
    basis<-list(knots=b$knot,basis_id=b$basis_id[1],status=b$status[1],quantile_type=b$quantile_type[1])
    for(specified in c(FALSE,TRUE)) {
      spec<-bmi_icd_spec(specified)
      sample<-if(specified)p[bmi_icd_category(p)!="unspecified",,drop=FALSE]else p
      if(specified) {
        node<-bmi_node("C_icd_acuity_specified",sample,status=if(qualified)"assessed"else"unavailable",label="Diagnosis capture excluding unspecified-only category")
        if(!qualified)node[c("n_records","n_encounters","n_patients","n")]<-NA_real_
        t$cohort_nodes<-bmi_bind(list(t$cohort_nodes,node));t$population_registry<-bmi_bind(list(t$population_registry,node))
        if(qualified) {
          profiles<-bmi_profile(sample,"C_icd_acuity_specified",a$variable_dictionary,config,p)
          for(name in names(profiles))t[[name]]<-bmi_bind(list(t[[name]],profiles[[name]]))
        }
      }
      m<-bmi_multinomial_fit(sample,basis,config,qualified,reason,spec)
      t$model_registry<-bmi_bind(list(t$model_registry,m$row))
      for(name in c("coefficients","covariance","references")) {
        target<-c(coefficients="coefficients",covariance="coefficient_covariance",references="factor_references")[[name]]
        t[[target]]<-bmi_bind(list(t[[target]],m[[name]]))
      }
      for(name in c("model_fit_diagnostics","model_residual_bins","model_influence_summary","model_support"))t[[name]]<-bmi_bind(list(t[[name]],m[[name]]))
      predicted<-bmi_multinomial_predictions(m,config)
      for(name in names(predicted))t[[name]]<-bmi_bind(list(t[[name]],predicted[[name]]))
    }
    t$model_sample_audit<-t$model_registry;t$expected_models<-t$model_registry["model_id"]
    t$coverage_index<-data.frame(kind="model",item_id=t$model_registry$model_id,table="model_registry",status=t$model_registry$status)
  }
  t$coverage_index<-bmi_bind(list(t$coverage_index,data.frame(kind="population",item_id=t$population_registry$population_id,table="population_registry",status=status)))
  t<-bmi_namespace(t,population)
  for(name in names(t)) {
    z<-t[[name]]
    if("model_id" %in% names(z)&&nrow(z)) {
      ix<-match(z$model_id,t$model_registry$model_id)
      if(!"population_id" %in% names(z))z$population_id<-population
      if(!"outcome_id" %in% names(z))z$outcome_id<-t$model_registry$outcome_id[ix]
      if(!"ascertainment_window" %in% names(z))z$ascertainment_window<-"encounter"
      if(!"model_form" %in% names(z))z$model_form<-"multinomial_spline"
    }
    a[[name]]<-bmi_bind(list(a[[name]],z))
  }
  a
}

bmi_validate_icd_population <- function(a) {
  z<-a$icd_acuity_categories
  if(nrow(z)&&all(z$status=="qualified")) {
    if(anyNA(z$n)||sum(z$n)!=z$N[1]||any(z$N!=z$N[1])||!identical(z$category_id,bmi_icd_classes))stop("ICD category partition mismatch")
    rec<-a$icd_acuity_reconciliation
    if(rec$n[rec$metric=="original_composite_positive"]!=sum(z$n[-1])||sum(a$icd_acuity_patterns$n)!=z$N[1])stop("ICD composite/pattern reconciliation mismatch")
  }
  joint<-a$model_registry[a$model_registry$family %in% c("icd_acuity","icd_acuity_specified"),,drop=FALSE]
  if(!nrow(joint))return(invisible(TRUE))
  if(nrow(joint)!=2L||any(joint$model_form!="multinomial_spline")||any(a$policy_totals$model_id %in% joint$model_id))stop("Invalid ICD supplemental registry")
  if(!setequal(joint$family,c("icd_acuity","icd_acuity_specified"))||
     !identical(joint$estimator,c("firth_mean_bias_reduced_v1","maximum_likelihood")))stop("ICD estimator identity mismatch")
  if(nrow(z)&&all(z$status=="qualified")) {
    if(joint$n_model[1]!=z$N[1]||joint$n_model[2]!=z$N[1]-z$n[z$category_id=="unspecified"])stop("ICD sensitivity denominator mismatch")
    band<-a$icd_acuity_observed_bands
    if(sum(band$n)!=z$N[1])stop("ICD BMI-band counts do not reconcile")
    for(category in bmi_icd_classes)if(sum(band$n[band$category_id==category])!=z$n[z$category_id==category])stop("ICD band category mismatch")
  }
  for(i in seq_len(nrow(joint))) {
    classes<-bmi_icd_spec(joint$family[i]=="icd_acuity_specified")$classes
    curves<-a$probability_curves[a$probability_curves$model_id==joint$model_id[i] & a$probability_curves$status=="estimated",]
    expected<-c(classes,"any_target")
    for(ix in split(seq_len(nrow(curves)),curves$bmi)) {
      z<-curves[ix,];pp<-setNames(z$probability,z$outcome_id)
      if(nrow(z)!=length(expected)||anyDuplicated(z$outcome_id)||!setequal(z$outcome_id,expected)||any(!is.finite(pp)|pp<0|pp>1)||
         abs(sum(pp[classes])-1)>1e-9||abs(sum(pp[classes[-1]])-pp['any_target'])>1e-9)stop("ICD curve partition mismatch")
      cv<-a$icd_acuity_probability_covariance;cv<-cv[cv$model_id==joint$model_id[i]&cv$bmi==z$bmi[1],]
      if(nrow(cv)!=length(expected)^2||anyDuplicated(paste(cv$outcome1,cv$outcome2))||any(!is.finite(cv$covariance)))stop("Missing ICD joint covariance")
      component<-cv$outcome1 %in% classes[-1]&cv$outcome2 %in% classes[-1]
      total<-cv$outcome1=='any_target'&cv$outcome2=='any_target'
      if(sum(total)!=1L||abs(sum(cv$covariance[component])-cv$covariance[total])>1e-9)stop("ICD total covariance mismatch")
    }
  }
  invisible(TRUE)
}

bmi_validate_icd_bundle <- function(a) {
  for(population in unique(a$model_registry$analysis_population_id[a$model_registry$family %in% c("icd_acuity","icd_acuity_specified")]))
    bmi_validate_icd_population(bmi_group_view(a,population))
  invisible(TRUE)
}
