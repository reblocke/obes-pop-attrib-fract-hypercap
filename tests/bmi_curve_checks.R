#!/usr/bin/env Rscript
# Independent artificial expectations. No clinical input is opened.
test_root<-normalizePath(Sys.getenv("BMI_REPO_ROOT",unset=getwd()),mustWork=TRUE)
source(file.path(test_root,"R/analysis.R"),local=TRUE);source(file.path(test_root,"tests/fixtures/bmi_curve_fixture.R"),local=TRUE)
config<-bmi_config(file.path(test_root,"config/bmi_hypercapnia_analysis.json"));config$mnar_enabled<-FALSE
raw<-make_bmi_curve_fixture(900)
ctx<-construct_cohort_and_memberships(raw);basis<-resolve_bmi_basis(ctx$members$C,config)
a<-bmi_run_population_analysis(raw,config);models<-fit_registered_models(ctx,basis,config)
m<-models[["any_gas/encounter/spline"]];ref<-ctx$members$C
expect_error<-function(expr,pattern=NULL){e<-tryCatch({force(expr);NULL},error=function(e)e);if(is.null(e)||(!is.null(pattern)&&!grepl(pattern,conditionMessage(e))))stop("Expected error: ",pattern)}
near<-function(x,y,tol=1e-9)stopifnot(isTRUE(all.equal(as.numeric(x),as.numeric(y),tolerance=tol)))
checks<-list();add<-function(id,fun)checks[[id]]<<-fun
small<-function(){d<-make_bmi_curve_fixture(3,with_index_day=FALSE,adverse=FALSE);d$bmi<-40;d$bmi_evidence_state<-"valid";d$sex<-"0";d}
policy<-config$policies[[1]]
# A. Source and eligibility (9)
add("A01",function(){p<-common_source_policy();stopifnot(p$unit_factors_to_mmhg$kpa==7.50062,!"11557-6" %in% unlist(p$arterial_codes),!"32771-8" %in% unlist(p$arterial_codes));d<-small();d$has_abg[1]<-3;expect_error(validate_triangulation_input(d),"0/1/NA")})
add("A02",function(){d<-small();d$patient_id<-as.numeric(rep(1:3,each=2));expect_error(validate_triangulation_input(d),"character keys");mf<-jsonlite::read_json(file.path(test_root,"config/triangulation_input.example.json"));stopifnot(mf$semantics$keys=="original_patient_and_encounter");expect_error(bmi_load_input("absent.rds","absent.json"))})
add("A03",function(){p<-bmi_partial_audit("Uncovered original-list candidate mapping",config);stopifnot(p$source_audit$status=="blocked",all(is.na(p$cohort_nodes$n)),nrow(p$model_registry)==0)})
add("A04",function(){p<-bmi_partial_audit("Checked one partition; total unknown",config);stopifnot(all(is.na(p$population_registry$n)),all(p$population_registry$status=="source_unqualified"))})
add("A05",function(){d<-small();d<-rbind(d,d[1,]);v<-validate_triangulation_input(d);stopifnot(attr(v,"exact_duplicates_removed")==1);d[nrow(d),"bmi"]<-41;v<-validate_triangulation_input(d);stopifnot(sum(v$.key_conflict)==2);d[nrow(d),"bmi"]<-20;x<-construct_cohort_and_memberships(d);stopifnot(x$selection$counts$n_earlier_uncertainty>=1,!d$patient_id[1] %in% x$members$Q$patient_id)})
add("A06",function(){d<-small();d$encounter_date<-as.Date(c("2022-01-01","2023-01-01","2022-01-01","2022-02-01","2022-03-01","2022-04-01"));d$age_at_encounter<-c(18,18,17,18,40,40);e<-bmi_eligibility(d)$state;stopifnot(identical(e[1:4],c(TRUE,FALSE,FALSE,TRUE)))})
add("A07",function(){d<-small();d$bmi<-c(29.999,30,39.999,40,30,40);e<-bmi_eligibility(d)$state;stopifnot(!e[1],all(e[-1]),sum(d$bmi>=40)==2)})
add("A08",function(){d<-small();d$bmi[1]<-NA;d$bmi_evidence_state[1]<-"unresolved";d$age_at_encounter[2]<-NA;d$encounter_type[3]<-NA;stopifnot(all(is.na(bmi_eligibility(d)$state[1:3])));d$bmi_evidence_state[1]<-"missing";stopifnot(identical(bmi_eligibility(d)$state[1],FALSE))})
add("A09",function(){d<-small();d$encounter_type[1]<-"OTHER";d$bmi[1]<-NA;d$bmi_evidence_state[1]<-"unresolved";stopifnot(identical(bmi_eligibility(d)$state[1],FALSE))})
# B. Index and ledger (9)
add("B01",function(){d<-small();d$sex[1]<-NA;d$abg_pco2[1]<-NA;d$has_abg[1]<-0;x<-construct_cohort_and_memberships(d);stopifnot(d$encounter_id[1] %in% x$members$Q$encounter_id,!d$patient_id[1] %in% x$members$C$patient_id)})
add("B02",function(){d<-small();d$bmi[1]<-NA;d$bmi_evidence_state[1]<-"unresolved";x<-construct_cohort_and_memberships(d);stopifnot(x$selection$counts$n_earlier_uncertainty==1,!d$patient_id[1] %in% x$members$Q$patient_id)})
add("B03",function(){d<-small();d$encounter_date[2]<-d$encounter_date[1];x<-construct_cohort_and_memberships(d);stopifnot(x$selection$counts$n_earliest_ties==1);near(x$selection$counts$n_index_resolved,construct_cohort_and_memberships(d[nrow(d):1,])$selection$counts$n_index_resolved)})
add("B04",function(){d<-raw;d$icd_hypercapnia<-1-d$icd_hypercapnia;for(v in triangulation_index_day_columns)d[[v]]<-NULL;near(match(ctx$members$Q$encounter_id,d$encounter_id),match(construct_cohort_and_memberships(d)$members$Q$encounter_id,d$encounter_id))})
add("B05",function(){stopifnot(length(unique(ctx$members$Q$patient_id))==nrow(ctx$members$Q),length(unique(tri_encounter_key(ctx$members$Q)))==nrow(ctx$members$Q))})
add("B06",function(){bmi_validate_ledger(a);stopifnot(a$cohort_nodes$n_records[a$cohort_nodes$population_id=="source_records"]==nrow(raw));bad<-a;bad$cohort_nodes$n[bad$cohort_nodes$population_id=="excluded_encounters"]<-999;expect_error(bmi_validate_ledger(bad),"reconciliation")})
add("B07",function(){x<-bmi_ledger(ctx);near(sum(x$exclusion_reasons$n[x$exclusion_reasons$accounting=="first_failure"]),nrow(ctx$members$excluded_encounters));stopifnot(all(x$exclusion_overlaps$n_false>=0))})
add("B08",function(){stopifnot(all(a$cohort_edges$relation %in% c("partition","deduplication","subset","unit_conversion")),all(nzchar(a$cohort_edges$denominator_id)));txt<-deparse(body(bmi_flow_plot));stopifnot(any(grepl("n\\$n",txt)))})
add("B09",function(){d<-make_bmi_curve_fixture(20);cp<-bmi_make_companion(d);q<-construct_cohort_and_memberships(d)$members$Q;j<-bmi_merge_companion(bmi_run_analysis(q,config,audit_only=TRUE),cp,q);invisible(bmi_validate_ledger(j));bad<-q;bad$bmi[1]<-bad$bmi[1]+.1;expect_error(bmi_merge_companion(j,cp,bad),"field identity");stopifnot(all(ctx$members$C40$patient_id %in% ref$patient_id),all(ctx$members$M_abg$patient_id %in% ctx$members$M_any_gas$patient_id));for(pair in c("abg","any_gas"))stopifnot(identical(models[[paste("matched",pair,"icd",sep="/")]]$data$patient_id,models[[paste("matched",pair,pair,sep="/")]]$data$patient_id))})
# C. Evidence and descriptive output (11)
add("C01",function(){d<-small();d$has_abg<-d$has_vbg<-1;d$abg_pco2<-c(44.99,45,45.01,44,44,44);d$vbg_pco2<-c(49.99,49.99,50,50,49,49);x<-derive_triangulation_variables(validate_triangulation_input(d));stopifnot(identical(x$abg[1:3],c(0L,1L,1L)),all(x$any_gas[c(2,3,4)]==1));p<-common_source_policy();stopifnot(p$arterial_validity$lower_exclusive==5,p$arterial_validity$upper_exclusive==200,p$venous_validity$lower_exclusive==10,p$venous_validity$upper_exclusive==250)})
add("C02",function(){d<-small();d$has_abg<-1;d$has_vbg<-0;d$abg_pco2<-d$vbg_pco2<-NA_real_;x<-construct_cohort_and_memberships(d);stopifnot(all(is.na(x$members$Q$any_gas)))})
add("C03",function(){d<-small();d$has_abg<-1;d$abg_pco2<-44;d$vbg_pco2<-NA_real_;d$has_vbg<-0;x<-construct_cohort_and_memberships(d);stopifnot(all(x$members$Q$any_gas==0),all(is.na(x$members$Q$vbg_pco2)))})
add("C04",function(){d<-make_bmi_curve_fixture(5,adverse=FALSE);i<-which(!is.na(d$abg_pco2_index_day))[1];d$abg_pco2_index_day[i]<-d$abg_pco2[i]+1;expect_error(validate_triangulation_input(d),"exceeds")})
add("C05",function(){p<-a$observation_patterns;p<-p[p$status=="assessed",];for(ix in split(seq_len(nrow(p)),paste(p$population_id,p$window)))near(sum(p$n[ix]),p$n_reference[ix[1]])})
add("C06",function(){near(bmi_wilson(0,10),c(0,.277532799862889));near(bmi_wilson(5,10),c(.236593090512564,.763406909487436));stopifnot(all(is.na(bmi_wilson(0,0))));e<-a$evidence_by_bmi;e<-e[e$status=="assessed"&e$M>0,];near(e$observation*e$positivity,e$documented)})
add("C07",function(){d<-small();d$icd_hypercapnia<-c(0,1,NA,1,1,1);v<-derive_triangulation_variables(validate_triangulation_input(d));stopifnot(v$icd[1]==0,v$icd[2]==1,is.na(v$icd[3]));stopifnot(nrow(ctx$members$C_icd)<nrow(ref))})
add("C08",function(){dict<-a$variable_dictionary;stopifnot(all(names(ctx$data) %in% dict$variable_id),all(names(ctx$data) %in% a$variable_summary$variable_id));bad<-ctx$data;bad$unregistered<-1;expect_error(bmi_dictionary(bad,config),"Unregistered")})
add("C09",function(){c<-a$category_counts;for(ix in split(seq_len(nrow(c)),paste(c$population_id,c$variable_id)))near(sum(c$n[ix]),c$n_reference[ix[1]]);h<-a$distribution_bins;h<-h[h$variable_id!="gas_pattern_bmi",];for(ix in split(seq_len(nrow(h)),paste(h$population_id,h$variable_id)))near(sum(h$n[ix]),h$n_observed[ix[1]])})
add("C10",function(){stopifnot((1+90)/(2+100)!=mean(c(1/2,90/100)));h<-a$distribution_bins[a$distribution_bins$variable_id=="gas_pattern_bmi",];for(ix in split(seq_len(nrow(h)),h$population_id))near(sum(h$mass[ix]),1)})
add("C11",function(){d<-ctx$data[1:4,];d$bmi<-40;p<-bmi_profile(d,"constant",a$variable_dictionary,config,d);stopifnot(!any(p$distribution_curves$variable_id=="bmi"&p$distribution_curves$kind=="kde"))})
# D. Models (11)
add("D01",function(){x<-bmi_add_basis(ref,basis);z<-ref;z$bmi<-z$bmi-1;z<-bmi_add_basis(z,basis);b<-splines::ns(z$bmi,knots=basis$knots[2:3],Boundary.knots=basis$knots[c(1,4)]);near(as.matrix(z[paste0("bmi_ns",1:3)]),b);stopifnot(length(unique(a$model_registry$basis_id))==1)})
add("D02",function(){train<-m$data;train$s1<-splines::ns(train$bmi,knots=basis$knots[2:3],Boundary.knots=basis$knots[c(1,4)])[,1];d<-train;d$bmi<-43;x<-bmi_matrix(m,d);near(plogis(drop(x%*%coef(m$fit))),predict(m$fit,bmi_add_basis(d,basis),type="response"))})
add("D03",function(){for(w in c("encounter","index_calendar_day"))for(o in if(w=="encounter")c("abg","any_gas","icd")else c("abg","any_gas"))stopifnot(identical(models[[paste(o,w,"spline",sep="/")]]$data$patient_id,models[[paste(o,w,"linear",sep="/")]]$data$patient_id))})
add("D04",function(){for(mm in models)if(!is.null(mm$fit))near(nobs(mm$fit),mm$row$n_model);s<-m$row;d<-m$data;d$age_at_encounter[1]<-NA;expect_error(fit_bmi_model(s,d,basis,config),"hidden missing")})
add("D05",function(){s<-m$row;d<-m$data;d[[s$field]]<-0;stopifnot(fit_bmi_model(s,d,basis,config)$row$status=="constant_outcome");b<-basis;b$status<-"duplicated_or_unavailable_knots";stopifnot(fit_bmi_model(s,m$data,b,config)$row$status=="rank_deficiency");d<-m$data;d[[s$field]]<-as.integer(d$bmi>40);stopifnot(fit_bmi_model(s,d,basis,config)$row$status=="separation");cfg<-config;cfg$maxit<-1;stopifnot(fit_bmi_model(m$row,m$data,basis,cfg)$row$status=="convergence_failure");r<-bmi_model_registry("pending");s<-r[r$source_status=="pending",][1,];stopifnot(fit_bmi_model(s,d,basis,config)$row$status=="pending_source")})
add("D06",function(){c<-m$coefficients;stopifnot(all(c("(Intercept)","bmi_ns1","bmi_ns2","bmi_ns3","age_at_encounter") %in% c$term),nrow(c[c$status=="estimated",])==length(coef(m$fit)))})
add("D07",function(){c<-a$coefficients;r<-c[c$status=="reference_not_estimated",];stopifnot(nrow(r)>0,all(is.na(r$estimate)),all(is.na(r$std_error)))})
add("D08",function(){validate_analysis_bundle(a);bad<-a;bad$coefficient_covariance<-bad$coefficient_covariance[-1,];expect_error(validate_analysis_bundle(bad),"covariance")})
add("D09",function(){stopifnot(all(a$model_registry$model_id %in% a$coverage_index$item_id),all(a$model_registry$model_id %in% a$model_fit_diagnostics$model_id));stopifnot(all(paste0("model:",a$model_registry$model_id) %in% a$population_registry$population_id))})
add("D10",function(){stopifnot(all(grepl("model-based",a$model_registry$covariance_method)),all(grepl("apparent",a$model_fit_diagnostics$note[a$model_fit_diagnostics$metric!="unavailable"])))})
add("D11",function(){d<-ref;d$sex[1]<-"UNSEEN";expect_error(bmi_mean_prediction(m,d,config),"Unseen reference category");z<-standardize_policy_and_contributions(m,d,"test",policy,config);stopifnot(z$policy_totals$status=="prediction_unavailable",z$policy_totals$n_reference==nrow(d))})
# E. Curves and paired decomposition (14)
add("E01",function(){d<-ref;d$bmi<-45;expected<-mean(predict(m$fit,bmi_add_basis(d,basis),type="response"));near(bmi_mean_prediction(m,ref,config,bmi=45)$probability,expected)})
add("E02",function(){# Explicit correlated-covariate counterexample: product marginals break the joint distribution.
 b<-c(30,30,50,50);age<-c(20,20,80,80);joint<-mean(plogis(-7+.08*b+.05*age));marginal<-mean(vapply(b,function(x)mean(plogis(-7+.08*x+.05*age)),numeric(1)));stopifnot(abs(joint-marginal)>.02)})
add("E03",function(){before<-ref;z<-standardize_policy_and_contributions(m,ref,"C",policy,config);stopifnot(identical(ref,before),z$policy_totals$n_reference==nrow(ref))})
add("E04",function(){near(bmi_policy_transform(c(29.9,30,30.2,40),policy),c(29.9,30,29.2,39));d<-c(30.00001,35,50);near(d-bmi_policy_transform(d,policy),rep(1,3))})
add("E05",function(){p<-policy;p$transformation<-"identity";z<-standardize_policy_and_contributions(m,ref,"identity",p,config)$policy_totals;stopifnot(z$absolute_difference==0,z$PIF==0,z$difference_low_per1000==0,z$difference_high_per1000==0,z$PIF_low==0,z$PIF_high==0)})
add("E06",function(){mm<-m;beta<-coef(mm$fit);beta[]<-0;beta[1]<--1;mm$fit$coefficients<-beta;z<-standardize_policy_and_contributions(mm,ref,"null",policy,config);near(z$policy_totals$PIF,0);beta['bmi_ns1']<--2;mm$fit$coefficients<-beta;v<-bmi_pair_quantities(list(probability=.1,gradient=rep(0,length(beta))),list(probability=.2,gradient=rep(0,length(beta))),vcov(m$fit));stopifnot(v$PIF<0,v$PIF_low<0)})
add("E07",function(){z<-standardize_policy_and_contributions(m,ref,"C",policy,config);t<-z$policy_totals;c<-z$policy_contributions;near(sum(c$A),t$p_observed);near(sum(c$G),t$p_shifted);near(sum(c$D),t$absolute_difference);near(sum(c$D)/sum(c$A),t$PIF)})
add("E08",function(){z<-standardize_policy_and_contributions(m,ref,"C",policy,config);cfg<-config;cfg$bmi_bin_width<-10;y<-standardize_policy_and_contributions(m,ref,"C",policy,cfg);near(z$policy_totals$PIF,y$policy_totals$PIF)})
add("E09",function(){d<-ref[ref$bmi<35|ref$bmi>=50,];z<-standardize_policy_and_contributions(m,d,"gaps",policy,config)$policy_contributions;e<-z[z$n==0,];stopifnot(nrow(e)>0,all(e$mass==0),all(e$D==0),all(is.na(e$mean_observed)))})
add("E10",function(){beta<-coef(m$fit);pred<-bmi_mean_prediction(m,ref,config);eps<-1e-6;num<-vapply(seq_along(beta),function(j){step<-rep(0,length(beta));step[j]<-eps;(bmi_mean_prediction(m,ref,config,coefficients=beta+step)$probability-bmi_mean_prediction(m,ref,config,coefficients=beta-step)$probability)/(2*eps)},numeric(1));near(pred$gradient,num,1e-7)
  shifted<-bmi_policy_transform(ref$bmi,policy);p0<-pred;p1<-bmi_mean_prediction(m,ref,config,bmi=shifted);fun<-function(b){q0<-bmi_mean_prediction(m,ref,config,coefficients=b);q1<-bmi_mean_prediction(m,ref,config,bmi=shifted,coefficients=b);c(q0$probability-q1$probability,1-q1$probability/q0$probability)}
  numerical<-sapply(seq_along(beta),function(j){step<-rep(0,length(beta));step[j]<-eps;(fun(beta+step)-fun(beta-step))/(2*eps)})
  analytic<-rbind(p0$gradient-p1$gradient,p1$probability/p0$probability^2*p0$gradient-p1$gradient/p0$probability);near(numerical,analytic,1e-7)
})
add("E11",function(){z<-standardize_policy_and_contributions(m,ref,"C",policy,config);near(sum(z$policy_contribution_covariance$covariance),z$policy_totals$variance_difference);stopifnot(any(z$policy_contribution_covariance$bin1!=z$policy_contribution_covariance$bin2 & abs(z$policy_contribution_covariance$covariance)>0))})
add("E12",function(){d<-ref;d$bmi<-30.2;z<-standardize_policy_and_contributions(m,d,"outside",policy,config);stopifnot(z$prediction_support$n_transformed_outside==nrow(d),all(z$policy_contributions$bin_low==30),z$policy_totals$n_reference==nrow(d))})
add("E13",function(){stopifnot(all(a$policy_totals$method=="observed"),nrow(a$sensitivity_results)==0,nrow(a$implied_missing_probabilities)==0);expect_error(standardize_policy_and_contributions(m,ref,"C",policy,config,"mar"),"historical only")})
add("E14",function(){before<-serialize(models,NULL);cfg<-config;cfg$policies[[1]]$threshold<-40;standardize_policy_and_contributions(m,ref,"C",cfg$policies[[1]],cfg);stopifnot(identical(before,serialize(models,NULL)),identical(ctx$members$Q$encounter_id,construct_cohort_and_memberships(raw)$members$Q$encounter_id))})
# F. Full render assertions run against a real fresh fixture review; no success from source inspection alone.
review<-Sys.getenv("BMI_TEST_REVIEW");review_ok<-nzchar(review)&&file.exists(file.path(review,"render-receipt.json"))
render_receipt<-if(review_ok)jsonlite::read_json(file.path(review,"render-receipt.json"),simplifyVector=TRUE)else NULL
add("F01",function(){if(!review_ok)stop("Set BMI_TEST_REVIEW to the actual completed artificial HTML/PDF review");stopifnot(render_receipt$status=="completed",all(file.exists(file.path(review,c("bmi_hypercapnia.html","bmi_hypercapnia.pdf","bmi_hypercapnia_audit.html","bmi_hypercapnia_audit.pdf")))));for(name in c("bmi_hypercapnia","bmi_hypercapnia_audit")){html<-readLines(file.path(review,paste0(name,".html")),warn=FALSE);stopifnot(!any(grepl("usepackage{longtable",html,fixed=TRUE)),any(grepl("bmi-audit-table",html,fixed=TRUE)))}})
add("F02",function(){if(!review_ok)stop("Actual render required");stopifnot(render_receipt$clinical_input_reads==0,render_receipt$model_refits==0,render_receipt$bundle_unchanged);bad<-function(...)stop("tripwire");load_bak<-bmi_load_input;fit_bak<-fit_bmi_model;assign("bmi_load_input",bad,.GlobalEnv);assign("fit_bmi_model",bad,.GlobalEnv);on.exit({assign("bmi_load_input",load_bak,.GlobalEnv);assign("fit_bmi_model",fit_bak,.GlobalEnv)});stopifnot(nrow(bmi_read_bundle(dirname(dirname(review)))$analysis$coefficients)>0)})
add("F03",function(){if(!review_ok)stop("Actual render required");x<-utils::read.csv(file.path(review,"audit-table-coverage.csv"));actual<-bmi_read_bundle(dirname(dirname(review)))$analysis;for(format in c("html","pdf")){z<-x[x$format==format,];near(sum(z$rows[z$caption=="coefficients"]),nrow(actual$coefficients));near(sum(z$rows[z$caption=="category_counts"]),nrow(actual$category_counts));near(sum(z$rows[z$caption=="variable_summary"]),nrow(actual$variable_summary));cv<-z[z$caption=="Complete coefficient covariance",];near(sum(cv$rows*(cv$columns-1)),nrow(actual$coefficient_covariance))};pdf<-system2("pdftotext",c(shQuote(file.path(review,"bmi_hypercapnia_audit.pdf")),"-"),stdout=TRUE);stopifnot(any(grepl("Every planned regression",pdf)),any(grepl("Export and review",pdf)))})
add("F04",function(){pending<-bmi_run_population_analysis(make_bmi_curve_fixture(60,with_index_day=FALSE),config);ix<-grepl("index_calendar_day",pending$cohort_nodes$population_id);stopifnot(all(is.na(pending$cohort_nodes$n[ix])),all(is.na(pending$evidence_by_bmi$N[pending$evidence_by_bmi$window=="index_calendar_day"])));p<-bmi_partial_audit("pending",config);stopifnot(all(is.na(p$population_registry$n)));r<-a$model_registry;stopifnot(all(r$status %in% c("pending_source","no_evaluable_sample","constant_outcome","rank_deficiency","separation","convergence_failure","diagnostic_failure","fitted_with_concerns","successful")))})
add("F05",function(){stopifnot(bmi_number(1e-9)!="0",bmi_number(-1e-9)!="0",bmi_number(0)=="0",identical(bmi_number(c(.01306620804615372,-8.542072e-14),digits=7),c("0.01306621","-8.542072e-14")));if(!review_ok)stop("Actual exports required");stopifnot(all(file.exists(file.path(review,"figures",paste0(rep(c("primary","obesity_only"),each=4),"/",rep(c("F1-A","F1-B","F1-C","F2"),2),".png")))));r<-jsonlite::read_json(file.path(review,"figures","figure-data-receipt.json"));stopifnot(isTRUE(r$same_saved_values))})
add("F06",function(){if(!review_ok)stop("Actual visual review required");r<-jsonlite::read_json(file.path(review,"visual-review-receipt.json"));stopifnot(isTRUE(r$native_size_inspected),isTRUE(r$grayscale_inspected),isTRUE(r$report_pages_inspected),r$open_blockers==0)})
add("F07",function(){stopifnot(all(a$model_registry$model_id %in% a$coverage_index$item_id),all(unique(a$variable_summary$variable_id) %in% a$coverage_index$item_id));validate_analysis_bundle(a)})
add("F08",function(){validate_analysis_bundle(a);bad<-a;bad$variable_summary$patient_id<-"ARTIFICIAL-ID";expect_error(validate_analysis_bundle(bad),"row-level");stopifnot(!any(vapply(a,function(d)any(vapply(d,function(v)inherits(v,"Date"),logical(1))),logical(1))))})
add("F09",function(){path<-tempfile();dir.create(path);jsonlite::write_json(list(schema_version=3,analysis_id="old"),file.path(path,"bundle_manifest.json"));expect_error(bmi_read_bundle(path),"Superseded");unlink(path,recursive=TRUE)})
add("F10",function(){mk<-readLines(file.path(test_root,"Makefile"));stopifnot(any(grepl("render_bmi_hypercapnia.R",mk)),!any(grepl("run_frame_triangulation|render_triangulation.R",mk)));stopifnot(!any(grepl("source\\(.*(common_index_hypercapnia|triangulation_reporting)",readLines(file.path(test_root,"R/analysis.R")))))})
add("F11",function(){
 path<-tempfile();bmi_write_bundle(a,path,config,list(source_status="ARTIFICIAL"));bmi_read_bundle(path)
 copy<-tempfile();dir.create(copy);old_root<-Sys.getenv("BMI_REPO_ROOT",unset=NA_character_)
 on.exit({if(is.na(old_root))Sys.unsetenv("BMI_REPO_ROOT")else Sys.setenv(BMI_REPO_ROOT=old_root);unlink(c(path,copy),recursive=TRUE)})
 for(f in bmi_estimation_files()){dir.create(dirname(file.path(copy,f)),recursive=TRUE,showWarnings=FALSE);stopifnot(file.copy(file.path(test_root,f),file.path(copy,f)))}
 Sys.setenv(BMI_REPO_ROOT=copy);bmi_read_bundle(path)
 # Plot-only revisions remain compatible, but cohort/source revisions must fail.
 writeLines("# artificial plot-only revision",file.path(copy,"R/reporting.R"));bmi_read_bundle(path)
 cat("\n# artificial source/cohort revision\n",file=file.path(copy,"R/cohort_audit.R"),append=TRUE)
 expect_error(bmi_read_bundle(path),"Estimation source/hash mismatch")
 if(is.na(old_root))Sys.unsetenv("BMI_REPO_ROOT")else Sys.setenv(BMI_REPO_ROOT=old_root)
 cat("\n",file=file.path(path,"coefficients.csv"),append=TRUE);expect_error(bmi_read_bundle(path),"hash mismatch")
})

# G. Observed-reference refresh and auditable presentation.
add("G01",function(){
 for(id in names(models)) {
  mm<-models[[id]];curves<-if(mm$row$family=="observation")a$observation_curves else a$probability_curves
  z<-curves[curves$model_id==id,,drop=FALSE];expected<-if(mm$row$family=="observation")"C"else mm$row$training_population_id
  stopifnot(all(z$reference_id==expected));if(is.null(mm$fit))next
  d<-ctx$members[[expected]];d$bmi<-z$bmi[1];pred<-predict(mm$fit,if(mm$row$model_form=="spline")bmi_add_basis(d,basis)else d,type="response")
  near(z$probability[1],mean(pred));near(z$n_reference[1],nrow(d))
 }
})
add("G02",function(){stopifnot(nrow(ctx$members$M_any_gas)<nrow(ctx$members$C_any_gas_encounter));z<-a$policy_totals[a$policy_totals$model_id=="any_gas/encounter/spline",];near(z$n_reference,nrow(m$data));stopifnot(z$reference_id=="C_any_gas_encounter")})
add("G03",function(){for(id in names(models)){mm<-models[[id]];if(is.null(mm$fit))next;c<-a$coefficients[a$coefficients$model_id==id & a$coefficients$status=="estimated",];near(c$estimate,coef(mm$fit));near(a$model_registry$n_model[a$model_registry$model_id==id],nrow(mm$data))}})
add("G04",function(){bad<-a;bad$probability_curves$reference_id[1]<-"C";expect_error(validate_analysis_bundle(bad),"reference");path<-tempfile();dir.create(path);jsonlite::write_json(list(schema_version=4L,analysis_id="bmi_hypercapnia_curve_audit_v1"),file.path(path,"bundle_manifest.json"));expect_error(bmi_read_bundle(path),"Superseded");unlink(path,recursive=TRUE)})
add("G05",function(){token<-paste0("model:abg/encounter;EMER|IMP,J96.02/",paste(rep("abcdef0123",7),collapse=""));stopifnot(identical(gsub("\\allowbreak{}","",bmi_break_table_tokens(token),fixed=TRUE),token));expect_error(bmi_figure("absent",tempdir(),data.frame()),"Required figure missing");stopifnot(grepl("White with non-Hispanic or unknown ethnicity",gsub("\n"," ",bmi_category_labels("race_ethnicity","0",a$variable_dictionary))))})
add("G06",function(){d<-a$category_counts;z<-bmi_unique_plot_profiles(d[d$variable_id=="sex",],setdiff(names(d),"population_id"));for(i in seq_len(nrow(z$index))){old<-d[d$variable_id=="sex"&d$population_id==z$index$population_id[i],];new<-z$data[z$data$population_id==z$index$representative_id[i],];old$population_id<-new$population_id;rownames(old)<-rownames(new)<-NULL;stopifnot(identical(old,new))}})
add("G07",function(){if(!review_ok)stop("Actual render required");actual<-bmi_read_bundle(dirname(dirname(review)))$analysis
 for(table in c("variable_summary","category_counts"))for(v in unique(actual[[table]]$variable_id)) {
  stem<-file.path(review,"coverage",paste0(table,"-",gsub("[^A-Za-z0-9]","-",v)))
  alias<-utils::read.csv(paste0(stem,"-aliases.csv"),stringsAsFactors=FALSE);shown<-utils::read.csv(paste0(stem,"-displayed.csv"),stringsAsFactors=FALSE,check.names=FALSE)
  orig<-actual[[table]][actual[[table]]$variable_id==v,];stopifnot(setequal(alias$population_id,unique(orig$population_id)))
  for(i in seq_len(nrow(alias))){x<-orig[orig$population_id==alias$population_id[i],];y<-shown[shown$population_id==alias$representative_id[i],];stopifnot(nrow(x)==nrow(y));for(col in setdiff(names(x),"population_id"))if(is.numeric(x[[col]]))near(x[[col]],y[[col]])else stopifnot(identical(as.character(x[[col]]),as.character(y[[col]])))}
 }
})
add("G08",function(){if(!review_ok)stop("Actual render required");r<-jsonlite::read_json(file.path(review,"figures","figure-data-receipt.json"));stopifnot(isTRUE(r$same_saved_values));for(group in c("primary","obesity_only"))for(id in c("F1-A","F1-B","F1-C","F1-detail","F2"))for(ext in c("svg","pdf","png","jpg"))stopifnot(file.exists(file.path(review,"figures",group,paste0(id,".",ext))))})

add("E15",function(){z<-ref;z$bmi<-39.99;p<-standardize_probability_curves(m,z,"narrow",config);stopifnot(nrow(p)==1,p$bmi==39.99,p$status=="estimated")})
