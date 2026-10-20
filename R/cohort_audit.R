bmi_table_names <- c("cohort_nodes","cohort_edges","exclusion_reasons","exclusion_overlaps","variable_summary","category_counts","distribution_bins","distribution_curves","missingness_patterns","comissingness","evidence_by_bmi","observation_patterns","timing_audit","variable_dictionary","source_audit","population_registry","stage_summary","policy_registry","model_registry","model_sample_audit","coefficients","coefficient_covariance","factor_references","model_fit_diagnostics","model_residual_bins","model_influence_summary","model_support","bmi_basis","prediction_support","probability_curves","observation_curves","fixed_bmi_contrasts","policy_totals","policy_contributions","policy_contribution_covariance","sensitivity_results","implied_missing_probabilities","linear_spline_comparison","coverage_index","numerical_reconciliation")
bmi_validate_ledger <- function(a) {
  tests<-list();add<-function(id,ok,note="")tests[[length(tests)+1L]]<<-data.frame(check_id=id,passed=if(length(ok)==1L && is.na(ok))NA else isTRUE(ok),status=if(length(ok)==1L && is.na(ok))"not_assessed"else if(isTRUE(ok))"passed"else"failed",note=note)
  nodes<-a$cohort_nodes;edges<-a$cohort_edges
  if(anyDuplicated(nodes$population_id))stop("Duplicate cohort node")
  add("edge_identifiers",all(edges$from %in% nodes$population_id & edges$to %in% nodes$population_id & edges$denominator_id %in% nodes$population_id))
  for(id in unique(edges$partition_id[nzchar(edges$partition_id)])) {
    e<-edges[edges$partition_id==id,,drop=FALSE];from<-nodes$n[match(e$from[1],nodes$population_id)];to<-nodes$n[match(e$to,nodes$population_id)]
    add(paste0("partition:",id),if(is.na(from)||anyNA(to))NA else sum(to)==from,"Checked at declared grain; unknown totals not asserted")
  }
  for(id in intersect(c("Q","C","C40","C_icd","M_abg","M_any_gas"),nodes$population_id)) {
    node<-nodes[nodes$population_id==id,,drop=FALSE];add(paste0("unique_patient:",id),if(is.na(node$n_records))NA else node$n_records==node$n_patients)
  }
  e<-a$evidence_by_bmi
  if(nrow(e))for(i in which(e$status=="assessed"))add(paste0("evidence:",i),e$H[i]<=e$M[i]&&e$M[i]<=e$N[i]&&
    (e$M[i]==0||abs(e$observation[i]*e$positivity[i]-e$documented[i])<1e-12))
  r<-bmi_bind(tests)
  if(any(r$passed %in% FALSE))stop("Cohort/evidence reconciliation failure: ",paste(r$check_id[r$passed %in% FALSE],collapse=", "))
  r
}

# Cohort membership remains private; only these summaries enter saved bundles.
bmi_bind <- function(x) {
  x <- Filter(function(y) is.data.frame(y) && ncol(y) > 0L, x)
  if (!length(x)) return(data.frame())
  fields <- unique(unlist(lapply(x, names)))
  x <- lapply(x, function(y) { for (v in setdiff(fields, names(y))) y[[v]] <- rep(NA, nrow(y)); y[fields] })
  rownames_result <- do.call(rbind, x); rownames(rownames_result) <- NULL; rownames_result
}
bmi_config <- function(path = "config/bmi_hypercapnia_analysis.json") {
  x <- jsonlite::read_json(path, simplifyVector = FALSE)
  if (!identical(x$analysis_id, "bmi_hypercapnia_rfs_curve_audit_v4") || x$bundle_schema != 9 ||
      x$population_scope_id != "original_selected_encounters_v1" || x$source_policy_id != "unadjusted_pco2_v1" ||
      x$bmi_policy_id != "available_encounter_or_prior_bmi_v1") stop("Unreviewed analysis/source/population policy")
  if (!identical(x$standardization_policy,"outcome_observed_v1") || !identical(x$mnar_enabled,FALSE)) stop("Full-cohort MAR/MNAR projections are superseded")
  if (!identical(unlist(x$analysis_populations,use.names=FALSE),c("primary","primary_current","all_obesity")) ||
      !identical(unlist(x$full_model_populations,use.names=FALSE),"primary") ||
      !identical(unlist(x$descriptive_populations,use.names=FALSE),"obesity_only")) stop("Unreviewed population roles; obesity-only is descriptive")
  if (any(vapply(x$policies,function(p)!identical(p$target,"model_observed"),logical(1)))) stop("Policies must retain the model-observed population")
  for (name in c("quantile_type", "grid_step", "bmi_bin_width", "chunk_size", "ecdf_grid_size", "kde_min_n", "kde_min_distinct", "sparse_n", "sparse_events")) {
    if (length(x[[name]]) != 1 || !is.numeric(x[[name]]) || !is.finite(x[[name]]) || x[[name]] <= 0) stop("Invalid config: ", name)
  }
  if (x$quantile_type != 7 || !identical(as.numeric(unlist(x$knot_probabilities)), c(.05,.35,.65,.95))) stop("Unreviewed spline specification")
  if (length(x$policies) < 1 || anyDuplicated(vapply(x$policies, `[[`, "", "policy_id"))) stop("Invalid policy registry")
  for (p in x$policies) if (!all(c("policy_id","enabled","threshold","transformation","target","label") %in% names(p)) ||
      !p$transformation %in% c("minus_one","cap","identity") || !is.numeric(p$threshold) || !is.finite(p$threshold)) stop("Incomplete explicit policy")
  x
}
bmi_eligibility <- function(d) {
  criteria <- data.frame(calendar = d$encounter_date >= as.Date("2022-01-01") & d$encounter_date < as.Date("2023-01-01"),
    setting = ifelse(is.na(d$encounter_type), NA, d$encounter_type %in% c("EMER","IMP")),
    adult = d$age_at_encounter >= 18, bmi = d$bmi >= 30)
  if ("bmi_evidence_state" %in% names(d)) criteria$bmi[d$bmi_evidence_state == "missing"] <- FALSE
  list(criteria = criteria, state = Reduce(`&`, criteria))
}
construct_cohort_and_memberships <- function(raw) {
  d <- bmi_classify_rfs(derive_triangulation_variables(validate_triangulation_input(raw)))
  e <- bmi_eligibility(d); d$common_obesity <- e$criteria$bmi
  # Resolve conflicting encounter versions before calling any row confirmed.
  for(ix in split(which(d$.key_conflict),tri_encounter_key(d)[d$.key_conflict])) {
    z<-e$state[ix];e$state[ix]<-if(all(z %in% TRUE))TRUE else if(all(z %in% FALSE))FALSE else NA
  }
  for(v in names(e$criteria))d[[paste0("eligibility_",v)]]<-e$criteria[[v]]
  d$eligibility_state<-e$state
  selected <- select_frame_indexes(d, "common_obesity")
  q <- selected$indexes; c <- q[stats::complete.cases(q[triangulation_adjustment]), , drop=FALSE]
  members <- list(source_records=raw, encounter_versions=d,
    confirmed_eligible_encounters=d[e$state %in% TRUE,,drop=FALSE],
    excluded_encounters=d[e$state %in% FALSE,,drop=FALSE],
    uncertain_encounters=d[is.na(e$state),,drop=FALSE],
    unresolved_candidate_encounters=d[d$patient_id %in% selected$audit$patient_id[selected$audit$status != "resolved"],,drop=FALSE],
    Q=q, missing_adjustment=q[!stats::complete.cases(q[triangulation_adjustment]),,drop=FALSE], C=c,
    C40=c[c$bmi >=40,,drop=FALSE], C_icd=c[!is.na(c$icd),,drop=FALSE],
    M_abg=c[!is.na(c$icd)&!is.na(c$abg),,drop=FALSE], M_any_gas=c[!is.na(c$icd)&!is.na(c$any_gas),,drop=FALSE])
  for (w in c("encounter","index_calendar_day")) for (o in c("abg","any_gas")) {
    field <- if (w == "encounter") o else paste0(o,"_index_calendar_day")
    members[[paste("C",o,w,sep="_")]] <- c[!is.na(c[[field]]),,drop=FALSE]
    members[[paste("unknown",o,w,sep="_")]] <- c[is.na(c[[field]]),,drop=FALSE]
  }
  for (v in triangulation_adjustment) members[[paste0("missing_",v)]] <- q[is.na(q[[v]]),,drop=FALSE]
  list(data=d, members=members, selection=selected, eligibility=e,
    day_status=attr(d,"index_day_source_status"), duplicates=attr(d,"exact_duplicates_removed"))
}
bmi_node <- function(id, d, grain="patient", status="assessed", label=id) data.frame(
  population_id=id, label=label, grain=grain, n_records=nrow(d),
  n_encounters=nrow(unique(d[c("patient_id","encounter_id")])), n_patients=length(unique(d$patient_id)),
  n=if(grain=="patient") length(unique(d$patient_id)) else nrow(d), status=status)
bmi_ledger <- function(ctx) {
  nodes <- bmi_bind(lapply(names(ctx$members), function(id) bmi_node(id,ctx$members[[id]],
    if(id=="source_records")"record"else if (id %in% c("encounter_versions","confirmed_eligible_encounters","excluded_encounters","uncertain_encounters","unresolved_candidate_encounters")) "encounter_version" else "patient")))
  counts <- ctx$selection$counts
  for (name in c("n_frame_patients","n_index_unresolved","n_membership_uncertain","n_earliest_ties","n_earlier_uncertainty","n_conflicting_indexes")) {
    nodes <- bmi_bind(list(nodes, data.frame(population_id=name,label=name,grain="patient",n_records=NA,n_encounters=NA,n_patients=counts[[name]],n=counts[[name]],status="assessed")))
  }
  nsource<-length(unique(ctx$data$patient_id))
  nodes<-bmi_bind(list(nodes,data.frame(population_id=c("source_patients","n_no_eligible_or_uncertain"),label=c("Patients in original candidate scope","Patients without eligible or uncertain encounters"),grain="patient",n_records=NA_real_,n_encounters=NA_real_,n_patients=c(nsource,nsource-counts$n_frame_patients-counts$n_membership_uncertain),n=c(nsource,nsource-counts$n_frame_patients-counts$n_membership_uncertain),status="assessed")))
  labels<-c(source_records="Typed original candidate records",encounter_versions="Distinct candidate encounter versions",n_frame_patients="Patients with confirmed eligibility",Q="Resolved first indexes (Q)",C="Complete adjustment (C)",C_icd="Known diagnosis capture (C_icd)",n_index_unresolved="Unresolved earliest index")
  for(id in names(labels))nodes$label[nodes$population_id==id]<-labels[[id]]
  edges <- data.frame(from=c("source_records",rep("encounter_versions",3),"confirmed_eligible_encounters","n_frame_patients","n_frame_patients","Q","Q","C","C","C","C"),
    to=c("encounter_versions","confirmed_eligible_encounters","excluded_encounters","uncertain_encounters","n_frame_patients","Q","n_index_unresolved","C","missing_adjustment","C40","C_icd","M_abg","M_any_gas"),
    relation=c("deduplication",rep("partition",3),"unit_conversion","partition","partition","partition","partition",rep("subset",4)),
    partition_id=c("",rep("eligibility",3),"",rep("index",2),rep("adjustment",2),rep("",4)),
    denominator_id=c("source_records",rep("encounter_versions",3),"confirmed_eligible_encounters",rep("n_frame_patients",2),rep("Q",2),rep("C",4)))
  edges<-bmi_bind(list(edges,data.frame(from=c("encounter_versions",rep("source_patients",3)),to=c("source_patients","n_frame_patients","n_membership_uncertain","n_no_eligible_or_uncertain"),relation=c("unit_conversion",rep("partition",3)),partition_id=c("",rep("patient_membership",3)),denominator_id=c("encounter_versions",rep("source_patients",3)))))
  for(w in c("encounter","index_calendar_day")) for(o in c("abg","any_gas")) for(prefix in c("C","unknown")) {
    id<-paste(prefix,o,w,sep="_")
    edges<-bmi_bind(list(edges,data.frame(from="C",to=id,relation="partition",partition_id=paste(o,w),denominator_id="C")))
  }
  reason <- rep(NA_character_, nrow(ctx$data))
  for(v in names(ctx$eligibility$criteria)) reason[is.na(reason)&ctx$eligibility$criteria[[v]] %in% FALSE] <- v
  reason[!ctx$eligibility$state %in% FALSE]<-NA_character_
  exclusions <- as.data.frame(table(factor(reason,levels=names(ctx$eligibility$criteria))),stringsAsFactors=FALSE)
  names(exclusions)<-c("reason","n"); exclusions$denominator_id<-"encounter_versions";exclusions$accounting<-"first_failure"
  overlap <- bmi_bind(lapply(names(ctx$eligibility$criteria),function(v) data.frame(reason=v,
    n_false=sum(ctx$eligibility$criteria[[v]] %in% FALSE),n_unknown=sum(is.na(ctx$eligibility$criteria[[v]])),denominator_id="encounter_versions")))
  miss <- rep("complete",nrow(ctx$members$Q))
  for(v in triangulation_adjustment) miss[miss=="complete"&is.na(ctx$members$Q[[v]])] <-v
  sequential<-as.data.frame(table(factor(miss,levels=c("complete",triangulation_adjustment))),stringsAsFactors=FALSE);names(sequential)<-c("reason","n");sequential$denominator_id<-rep("Q",nrow(sequential));sequential$accounting<-rep("first_missing_adjustment",nrow(sequential))
  list(cohort_nodes=nodes,cohort_edges=edges,exclusion_reasons=bmi_bind(list(exclusions,sequential)),exclusion_overlaps=overlap)
}
bmi_dictionary <- function(d, config) {
  dictionary<-utils::read.csv(file.path(tri_repo_root(),"config","variable_dictionary.csv"),stringsAsFactors=FALSE,check.names=FALSE)
  absent<-setdiff(names(d),dictionary$variable_id)
  if(length(absent)) stop("Unregistered variables: ",paste(absent,collapse=", "))
  dictionary
}
bmi_profile <- function(d, population_id, dictionary, config, breaks_reference=d) {
  tables<-list(variable_summary=list(),category_counts=list(),distribution_bins=list(),distribution_curves=list(),missingness_patterns=list(),comissingness=list())
  for(v in names(d)) {
    entry<-dictionary[match(v,dictionary$variable_id),,drop=FALSE]; x<-d[[v]]; n<-length(x); obs<-!is.na(x)
    base<-data.frame(population_id=population_id,variable_id=v,n=n,n_observed=sum(obs),n_missing=sum(!obs),n_distinct=length(unique(x[obs])),status=if(n)"assessed" else "empty_population")
    if(entry$role=="identifier") { tables$variable_summary[[v]]<-base;next }
    if(inherits(x,"Date")) { tables$variable_summary[[v]]<-transform(base,status="date_values_protected; cardinality/missingness only");next }
    if(is.numeric(x) && entry$type=="continuous") {
      z<-x[obs]; ref<-breaks_reference[[v]];ref<-ref[is.finite(ref)]
      qs<-if(length(z)) stats::quantile(z,c(0,.01,.05,.25,.5,.75,.95,.99,1),type=config$quantile_type,names=FALSE) else rep(NA_real_,9)
      names(qs)<-c("minimum","q01","q05","q25","median","q75","q95","q99","maximum")
      tables$variable_summary[[v]]<-cbind(base,mean=if(length(z))mean(z)else NA_real_,sd=if(length(z)>1)stats::sd(z)else NA_real_,as.data.frame(as.list(qs)),n_invalid=sum(!is.finite(x)&!is.na(x)))
      if(length(ref)&&length(z)) {
        width<-if(v=="bmi")config$bmi_bin_width else if(grepl("pco2",v))5 else if(v=="age_at_encounter")5 else max(diff(range(ref))/20,1)
        br<-seq(floor(min(ref)/width)*width,ceiling(max(ref)/width)*width+width,by=width)
        h<-hist(z,breaks=br,plot=FALSE,right=FALSE)
        tables$distribution_bins[[v]]<-data.frame(population_id=population_id,variable_id=v,lower=head(h$breaks,-1),upper=tail(h$breaks,-1),n=h$counts,n_reference=n,n_observed=length(z),mass=h$counts/max(n,1),normalization="fraction_of_population; missing separate")
        grid<-seq(min(ref),max(ref),length.out=config$ecdf_grid_size)
        tables$distribution_curves[[paste(v,"ecdf")]]<-data.frame(population_id=population_id,variable_id=v,kind="ecdf",x=grid,y=stats::ecdf(z)(grid),normalization="observed_values",bandwidth=NA_real_)
        if(v %in% c("bmi","age_at_encounter") && length(z)>=config$kde_min_n && length(unique(z))>=config$kde_min_distinct && length(unique(ref))>1) {
          bw<-stats::bw.nrd0(ref); den<-stats::density(z,bw=bw,n=128,from=min(ref)-3*bw,to=max(ref)+3*bw)
          tables$distribution_curves[[paste(v,"kde")]]<-data.frame(population_id=population_id,variable_id=v,kind="kde",x=den$x,y=den$y*length(z)/max(n,1),normalization="population_mass; Gaussian; shared source bandwidth",bandwidth=bw)
        }
      }
    } else {
      tables$variable_summary[[v]]<-base
      declared<-strsplit(entry$allowed_levels,"|",fixed=TRUE)[[1]];declared<-declared[nzchar(declared)]
      values<-sort(unique(c(declared,as.character(x[obs]),"[MISSING]")))
      levels_count<-vapply(values,function(y) if(y=="[MISSING]")sum(!obs)else sum(as.character(x[obs])==y),numeric(1))
      tables$category_counts[[v]]<-data.frame(population_id=population_id,variable_id=v,level=values,n=levels_count,
        n_reference=n,percent_all=if(n)100*levels_count/n else NA_real_,percent_nonmissing=ifelse(values=="[MISSING]"|sum(obs)==0,NA_real_,100*levels_count/max(sum(obs),1)))
    }
  }
  vars<-intersect(triangulation_adjustment,names(d))
  if(nrow(d)&&length(vars)) {
    m<-is.na(d[vars]); pattern<-apply(m,1,function(row) {v<-vars[row];if(length(v))paste(v,collapse="+")else "complete"})
    tab<-table(pattern); tables$missingness_patterns[[1]]<-data.frame(population_id=population_id,pattern=names(tab),n=as.numeric(tab),denominator=nrow(d))
    pairs<-expand.grid(variable1=vars,variable2=vars,stringsAsFactors=FALSE)
    pairs$n_both_missing<-vapply(seq_len(nrow(pairs)),function(i)sum(m[,pairs$variable1[i]]&m[,pairs$variable2[i]]),numeric(1));pairs$population_id<-population_id
    tables$comissingness[[1]]<-pairs
  }
  lapply(tables,bmi_bind)
}
profile_stage_variables <- function(members, dictionary, config) {
  profiles<-lapply(names(members),function(id)bmi_profile(members[[id]],id,dictionary,config,members$encounter_versions))
  names(profiles)<-names(members)
  setNames(lapply(names(profiles[[1]]),function(table)bmi_bind(lapply(profiles,`[[`,table))),names(profiles[[1]]))
}
bmi_wilson <- function(h,n) {
  if(!n)return(c(NA_real_,NA_real_)); z<-stats::qnorm(.975); p<-h/n
  (p+z*z/(2*n)+c(-1,1)*z*sqrt(p*(1-p)/n+z*z/(4*n*n)))/(1+z*z/n)
}
derive_evidence_states <- function(ctx,config) {
  rows<-patterns<-timing<-list()
  for(id in c("Q","C","C40","C_icd","M_abg","M_any_gas")) for(w in c("encounter","index_calendar_day")) {
    d<-ctx$members[[id]];pending<-w!="encounter"&&ctx$day_status=="pending"
    a<-!is.na(d[[if(w=="encounter")"abg_pco2" else "abg_pco2_index_day"]]);v<-!is.na(d[[if(w=="encounter")"vbg_pco2"else"vbg_pco2_index_day"]])
    pat<-ifelse(a&v,"both",ifelse(a,"abg_only",ifelse(v,"vbg_only","neither")))
    for(p in c("abg_only","vbg_only","both","neither")) patterns[[length(patterns)+1L]]<-data.frame(population_id=id,window=w,pattern=p,n=if(pending)NA_integer_ else sum(pat==p),n_reference=if(pending)NA_integer_ else nrow(d),status=if(pending)"pending_source"else"assessed")
    bins<-sort(unique(config$bmi_bin_width*floor(d$bmi/config$bmi_bin_width)))
    for(o in if(w=="encounter")c("abg","vbg","any_gas","icd") else c("abg","vbg","any_gas")) for(b in bins) {
      ix<-which(config$bmi_bin_width*floor(d$bmi/config$bmi_bin_width)==b);z<-d[ix,,drop=FALSE]
      y<-if(o=="vbg")ifelse(is.na(z[[if(w=="encounter")"vbg_pco2"else"vbg_pco2_index_day"]]),NA_integer_,as.integer(z[[if(w=="encounter")"vbg_pco2"else"vbg_pco2_index_day"]]>=50))else z[[if(w=="encounter")o else paste0(o,"_index_calendar_day")]]
      n<-length(ix);m<-sum(!is.na(y));h<-sum(y==1,na.rm=TRUE);ci<-bmi_wilson(h,m)
      rows[[length(rows)+1L]]<-data.frame(population_id=id,outcome_id=o,window=w,bin_low=b,bin_high=b+config$bmi_bin_width,N=if(pending)NA else n,M=if(pending)NA else m,H=if(pending)NA else h,
        observation=if(pending)NA_real_ else m/n,positivity=if(pending||!m)NA_real_ else h/m,documented=if(pending)NA_real_ else h/n,
        positive_low=if(pending)NA_real_ else ci[1],positive_high=if(pending)NA_real_ else ci[2],status=if(pending)"pending_source"else"assessed")
    }
  }
  for(o in c("abg","any_gas")) {
    d<-ctx$members$Q;state<-function(x)factor(ifelse(is.na(x),"unknown",ifelse(x==1,"positive","available_negative")),levels=c("available_negative","positive","unknown"))
    t<-as.data.frame(table(primary=state(d[[o]]),day=state(d[[paste0(o,"_index_calendar_day")]])),stringsAsFactors=FALSE);names(t)[3]<-"n";t$outcome_id<-o
    if(ctx$day_status=="pending")t<-data.frame(primary="unassessed",day="pending_source",n=NA_integer_,outcome_id=o)
    timing[[o]]<-t
  }
  list(evidence_by_bmi=bmi_bind(rows),observation_patterns=bmi_bind(patterns),timing_audit=bmi_bind(timing))
}
bmi_pattern_bins <- function(ctx,config) {
  rows<-list()
  for(id in c("Q","C","C_icd","C40","M_abg","M_any_gas")) {
    d<-ctx$members[[id]];a<-!is.na(d$abg_pco2);v<-!is.na(d$vbg_pco2)
    pattern<-ifelse(a&v,"both",ifelse(a,"abg_only",ifelse(v,"vbg_only","neither")))
    bin<-config$bmi_bin_width*floor(d$bmi/config$bmi_bin_width)
    for(b in sort(unique(bin)))for(p in c("abg_only","vbg_only","both","neither")) {
      n<-sum(bin==b&pattern==p)
      rows[[length(rows)+1L]]<-data.frame(population_id=id,variable_id="gas_pattern_bmi",lower=b,upper=b+config$bmi_bin_width,n=n,n_reference=nrow(d),n_observed=nrow(d),mass=n/max(nrow(d),1),normalization="fraction_of_named_reference",pattern=p)
    }
  }
  bmi_bind(rows)
}

# Source binding and pre-index audit construction are estimation authority.
bmi_merge_companion <- function(tables,companion,raw) {
  if(!identical(companion$population_scope_id,"original_selected_encounters_v1")||!identical(companion$bmi_policy_id,"available_encounter_or_prior_bmi_v1"))stop("Cohort companion scope/policy mismatch")
  key_hash<-function(d)digest::digest(sort(tri_encounter_key(d)),algo="sha256")
  if(!identical(companion$selected_key_sha256,key_hash(raw)))stop("Cohort companion selected-key mismatch")
  if(!identical(companion$selection_sha256,bmi_selection_hash(raw)))stop("Cohort companion selected field identity mismatch")
  # Candidate profiles replace pre-index placeholders; actual gas data remain index-only.
  stageids<-setdiff(companion$tables$cohort_nodes$population_id,c("Q","C","C40","C_icd","M_abg","M_any_gas","missing_adjustment",paste0("missing_",triangulation_adjustment)))
  stageids<-stageids[!grepl("^(C_|unknown_)",stageids)]
  for(name in intersect(names(companion$tables),names(tables))) {
    incoming<-companion$tables[[name]]
    if("population_id" %in% names(incoming)) {
      incoming<-incoming[incoming$population_id %in% stageids,,drop=FALSE]
      tables[[name]]<-bmi_bind(list(tables[[name]][!tables[[name]]$population_id %in% stageids,,drop=FALSE],incoming))
    }else if(name %in% c("exclusion_reasons","exclusion_overlaps"))tables[[name]]<-incoming
  }
  tables
}
bmi_selection_hash <- function(d) {
  d<-d[order(tri_encounter_key(d)),c("patient_id","encounter_id","encounter_date","bmi","age_at_encounter","sex","race_ethnicity","location"),drop=FALSE]
  rownames(d)<-NULL;digest::digest(d,algo="sha256")
}
bmi_make_companion <- function(raw) {
  config<-bmi_config();ctx<-construct_cohort_and_memberships(raw);dictionary<-bmi_dictionary(ctx$data,config)
  q<-ctx$members$Q
  rfs_provenance<-bmi_rfs_audits(ctx,config)$bmi_provenance
  allowed<-c(bmi_metadata_fields, paste0("eligibility_",c("calendar","setting","adult","bmi","state")),"patient_id","encounter_id","encounter_date","age_at_encounter","encounter_type","bmi","sex","race_ethnicity","location","bmi_evidence_state",".key_conflict",".index_day_conflict","in_scope","common_obesity","severe_obesity")
  profiles<-profile_stage_variables(lapply(ctx$members,function(d)d[intersect(allowed,names(d))]),dictionary,config)
  unavailable<-setdiff(names(ctx$data),allowed)
  for(id in names(ctx$members))for(v in unavailable)profiles$variable_summary<-bmi_bind(list(profiles$variable_summary,data.frame(population_id=id,variable_id=v,n=nrow(ctx$members[[id]]),n_observed=NA_real_,n_missing=NA_real_,n_distinct=NA_real_,status="source evidence not extracted at pre-index; unassessed")))
  list(schema_version=1L,population_scope_id="original_selected_encounters_v1",bmi_policy_id="available_encounter_or_prior_bmi_v1",
    selected_key_sha256=digest::digest(sort(tri_encounter_key(q)),algo="sha256"),selection_sha256=bmi_selection_hash(q),
    tables=c(bmi_ledger(ctx),profiles),clinical_models_fitted=0L,
    rfs_provenance=rfs_provenance[rfs_provenance$stage=="encounter_versions",],
    capabilities="Candidate covariates and selection; pre-index gases/diagnoses not extracted. No source acceptance or human review asserted.")
}
bmi_load_input <- function(input,manifest,audit_only=FALSE) {
  loaded<-load_common_input(input,manifest)
  if(!identical(loaded$manifest$schema_version,4L))stop("RFS analysis requires metadata-qualified input schema 4")
  if(!identical(loaded$manifest$population_scope_id,"original_selected_encounters_v1")||!identical(loaded$manifest$bmi_policy_id,"available_encounter_or_prior_bmi_v1"))stop("Current input must bind original population and available-BMI policy")
  entry<-loaded$manifest$source_evidence_files$rfs
  path<-entry$path;if(!grepl("^(/|[A-Za-z]:)",path))path<-file.path(dirname(manifest),path)
  evidence<-jsonlite::read_json(path,simplifyVector=FALSE)
  if(!identical(evidence$policy_id,"historical_source_membership_v1") ||
     !identical(evidence$membership_semantics,"selected_source_file_membership") ||
     !setequal(names(evidence$families),bmi_rfs_fields))stop("Unqualified RFS semantics")
  for(item in evidence$evidence_files)if(!identical(tri_sha256(item$path),item$sha256))stop("RFS producing evidence changed")
  if(!length(evidence$evidence_files))stop("Missing RFS producing evidence")
  loaded$rfs_evidence<-evidence
  loaded$companion<-NULL
  if(isTRUE(loaded$manifest$index_preselected)) {
    entry<-loaded$manifest$source_evidence_files$cohort_audit
    if(is.null(entry))stop("Preselected input lacks the new hash-bound pre-index cohort-audit companion; reuse candidate mapping to prepare it")
    path<-entry$path;if(!grepl("^(/|[A-Za-z]:)",path))path<-file.path(dirname(manifest),path)
    if(!identical(tri_sha256(path),entry$sha256))stop("Cohort-audit companion hash mismatch")
    loaded$companion<-readRDS(path)
    if(!identical(loaded$companion$schema_version,1L)||loaded$companion$clinical_models_fitted!=0)stop("Invalid cohort-audit companion")
    # Independent identity and count validation also occurs when merging the ledger.
  }
  bmi_cooccurrence_load(loaded,manifest)
}
bmi_partial_audit <- function(reason,config) {
  a<-setNames(rep(list(data.frame()),length(bmi_table_names)),bmi_table_names)
  ids<-c("source_records","encounter_versions","confirmed_eligible_encounters","excluded_encounters","uncertain_encounters","n_frame_patients","Q","n_index_unresolved","C","missing_adjustment","C_icd","M_abg","M_any_gas","C40")
  a$cohort_nodes<-data.frame(population_id=ids,label=ids,grain="unassessed",n_records=NA_real_,n_encounters=NA_real_,n_patients=NA_real_,n=NA_real_,status="source_unqualified")
  a$cohort_edges<-data.frame(from=character(),to=character(),relation=character(),partition_id=character(),denominator_id=character())
  a$source_audit<-data.frame(requirement="clinical source qualification",status="blocked",note=reason)
  a$population_registry<-a$cohort_nodes;a$variable_dictionary<-utils::read.csv("config/variable_dictionary.csv",stringsAsFactors=FALSE)
  a$coverage_index<-data.frame(kind="variable",item_id=a$variable_dictionary$variable_id,table="variable_dictionary",status="unavailable; source qualification incomplete")
  a$numerical_reconciliation<-bmi_validate_ledger(a)
  a
}
