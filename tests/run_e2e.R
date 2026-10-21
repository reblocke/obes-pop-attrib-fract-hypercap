#!/usr/bin/env Rscript
# Public fixture -> saved aggregates -> real HTML/PDF -> independent evidence.
args <- commandArgs(TRUE)
if (length(args)>1L) stop("Use no arguments for a fresh run, or one saved artificial RUN to resume")
Sys.setenv(BMI_REPO_ROOT=normalizePath("."))
test_files <- c("tests/run_e2e.R","tests/e2e_oracles.R","tests/same_day_e2e.R","tests/fixtures/bmi_curve_fixture.R")
initial_test_hashes <- as.list(setNames(vapply(test_files,function(path)
  digest::digest(file=path,algo="sha256"),character(1)),test_files))
source("R/analysis.R")
source("tests/fixtures/bmi_curve_fixture.R")
source("tests/e2e_oracles.R")
source("tests/same_day_e2e.R")
require_tri_packages(c("jsonlite","digest","ggplot2","knitr","rmarkdown","lpSolve","nnet"))
for (command in c("quarto","pdftotext","pdfinfo"))
  if (!nzchar(Sys.which(command))) stop("Required installed command unavailable: ",command)

out <- file.path("artifacts/triangulation",paste0("e2e-",format(Sys.time(),"%Y%m%dT%H%M%S"),"-",Sys.getpid()))
dir.create(out,recursive=TRUE,mode="0700"); out <- normalizePath(out)
checks <- list()
receipt <- list(status="started",scope="Artificial typed-input analysis/report end to end",
  source_boundary_checks="separate: make source-test; not asserted by this receipt",
  clinical_input_reads=0L,human_visual_review="not performed by automated test",scientific_review="not asserted")
receipt$test_sources <- initial_test_hashes
persist <- function() {
  if (length(checks)) utils::write.csv(do.call(rbind,checks),file.path(out,"checks.csv"),row.names=FALSE)
  jsonlite::write_json(receipt,file.path(out,"receipt.json"),auto_unbox=TRUE,pretty=TRUE)
}
check <- function(name,code) {
  error <- tryCatch({force(code);NULL},error=function(e)e)
  checks[[name]] <<- data.frame(check=name,passed=is.null(error),detail=if(is.null(error))"passed"else conditionMessage(error))
  message(if(is.null(error))"PASS "else"FAIL ",name)
  persist()
  if (!is.null(error)) stop(conditionMessage(error),call.=FALSE)
}
rscript <- file.path(R.home("bin"),"Rscript")
command <- function(script,arguments,log,success=TRUE,pattern=NULL) {
  status <- system2(rscript,c("--vanilla",shQuote(script),vapply(arguments,shQuote,character(1))),stdout=log,stderr=log)
  text <- paste(readLines(log,warn=FALSE),collapse="\n")
  if ((success && status!=0L) || (!success && status==0L)) stop("Unexpected command status; see ",log)
  if (!is.null(pattern) && !grepl(pattern,text)) stop("Expected failure reason missing: ",log)
  text
}

tryCatch({
  if (!length(args)) {
    message("Running public fixture and both complete reports; log: ",file.path(out,"run.log"))
    log <- command("scripts/run_bmi_hypercapnia.R","fixture",file.path(out,"run.log"))
    lines <- strsplit(log,"\n",fixed=TRUE)[[1]]
    run <- sub("^Saved run: *","",tail(grep("^Saved run:",lines,value=TRUE),1))
    if (!nzchar(run)) stop("Fixture launcher did not identify its saved run")
  } else run <- args[1]
  run <- normalizePath(trimws(run),mustWork=TRUE)
  bundle <- bmi_read_bundle(run)
  stopifnot(bundle$manifest$mode=="fixture",bundle$manifest$source_status=="artificial_only")
  receipt$run <- run
  receipt$bundle_manifest_sha256 <- tri_sha256(file.path(run,"bundle_manifest.json"))
  receipt$estimation_sources <- bundle$manifest$estimation_sources

  check("independent cohort, regressions, curves and paired uncertainty", {
    numerical <- e2e_saved_values(bundle,make_bmi_curve_fixture())
    utils::write.csv(numerical,file.path(out,"independent-model-checks.csv"),row.names=FALSE)
  })
  check("same-day ABG independent models",{
    paired<-e2e_same_day(bundle,make_bmi_curve_fixture())
    utils::write.csv(paired,file.path(out,"same-day-independent-model-checks.csv"),row.names=FALSE)
  })
  check("adverse eligibility, RFS, policy and failure states",e2e_adverse_cases())
  check("persisted aggregate privacy and coverage", {
    a <- bundle$analysis
    for (table in a) {
      stopifnot(is.data.frame(table),!any(vapply(table,function(x)inherits(x,c("Date","POSIXt","glm","lm")),logical(1))))
      text <- unlist(lapply(table,as.character),use.names=FALSE)
      stopifnot(!any(grepl("ARTIFICIAL-[PE][0-9]",text)),
        !any(names(table) %in% c("patient_id","encounter_id","encounter_date","individual_prediction","selected_row")))
    }
    stopifnot(all(a$model_registry$model_id %in% a$coverage_index$item_id),
      all(a$cohort_nodes$population_id %in% a$coverage_index$item_id),
      all(a$variable_dictionary$variable_id %in% a$coverage_index$item_id),
      !any(a$numerical_reconciliation$passed %in% FALSE))
  })

  # A copied aggregate bundle is sufficient; no fixture/raw input is persisted.
  aggregate_only <- file.path(out,"aggregate-only")
  dir.create(aggregate_only)
  stopifnot(all(file.copy(file.path(run,c(names(bundle$manifest$files),"bundle_manifest.json")),aggregate_only)))
  source_files <- c("R/reporting.R","R/report_views.R","R/rfs_reporting.R","scripts/render_bmi_hypercapnia.R",
    "reports/bmi_hypercapnia.qmd","reports/bmi_hypercapnia_audit.qmd","reports/bmi_report.css","reports/table_passthrough.R")
  reviews <- list.dirs(file.path(run,"reviews"),recursive=FALSE,full.names=TRUE)
  usable <- Filter(function(path) {
    file <- file.path(path,"render-receipt.json")
    if (!file.exists(file)) return(FALSE)
    r <- jsonlite::read_json(file,simplifyVector=FALSE)
    identical(r$status,"completed") && identical(r$render_sources,bmi_hash_files(source_files)) &&
      identical(r$bundle_manifest_sha256,receipt$bundle_manifest_sha256) &&
      all(file.exists(file.path(path,c("bmi_hypercapnia.html","bmi_hypercapnia.pdf","bmi_hypercapnia_audit.html","bmi_hypercapnia_audit.pdf"))))
  },reviews)
  if (!length(usable)) {
    log <- command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"all"),file.path(out,"render.log"))
    lines <- strsplit(log,"\n",fixed=TRUE)[[1]]
    review <- trimws(sub("^Review: *","",tail(grep("^Review:",lines,value=TRUE),1)))
  } else review <- tail(sort(usable),1)
  receipt$review <- normalizePath(review,mustWork=TRUE)
  check("aggregate-only report and complete table exports",{
    r <- jsonlite::read_json(file.path(review,"render-receipt.json"),simplifyVector=TRUE)
    stopifnot(r$status=="completed",r$clinical_input_reads==0,r$model_refits==0,r$bundle_unchanged,r$sources_unchanged)
    a <- bundle$analysis
    coverage <- utils::read.csv(file.path(review,"audit-table-coverage.csv"),stringsAsFactors=FALSE)
    renamed <- c(source_audit="Source status and interpretation limits",coverage_index="Coverage index",
      variable_dictionary="Complete variable dictionary",bmi_basis="Fixed spline basis",
      linear_spline_comparison="Same-sample linear-versus-spline comparisons")
    # Coordinates are completely exported and represented by the required
    # figures; stage/model-sample summaries are exact aliases, not extra prints.
    special <- c(names(renamed),"distribution_bins","distribution_curves","probability_curves","observation_curves",
      "stage_summary","model_sample_audit","sensitivity_results","implied_missing_probabilities",
      "coefficient_covariance","policy_contribution_covariance","model_residual_bins")
    for (format in c("html","pdf")) {
      rows <- coverage[coverage$format==format,]
      for (table in setdiff(names(a),special))
        e2e_near(sum(rows$rows[rows$caption==table]),nrow(a[[table]]))
      for (table in names(renamed))e2e_near(sum(rows$rows[rows$caption==renamed[[table]]]),nrow(a[[table]]))
      for (caption in c("Complete coefficient covariance","Complete coefficient correlation")) {
        covariance <- rows[rows$caption==caption,]
        e2e_near(sum(covariance$rows*(covariance$columns-1)),nrow(a$coefficient_covariance))
      }
      covariance <- rows[rows$caption=="Complete original-band contribution covariance",]
      e2e_near(sum(covariance$rows*(covariance$columns-1)),nrow(a$policy_contribution_covariance))
      residuals <- a$model_residual_bins[!grepl("^(hist_|ecdf_)",a$model_residual_bins$diagnostic),]
      e2e_near(sum(rows$rows[rows$caption=="model_residual_bins"]),nrow(residuals))
    }
    for (name in c("bmi_hypercapnia","bmi_hypercapnia_audit")) {
      html <- paste(readLines(file.path(review,paste0(name,".html")),warn=FALSE),collapse="\n")
      stopifnot(!grepl("usepackage{longtable",html,fixed=TRUE),grepl("bmi-audit-table",html,fixed=TRUE))
      pdf <- system2("pdftotext",c(shQuote(file.path(review,paste0(name,".pdf"))),"-"),stdout=TRUE)
      stopifnot(is.null(attr(pdf,"status")),length(pdf)>0,!any(grepl("\uFFFD",pdf,fixed=TRUE)))
    }
  })
  check("complete S1 caption in assembled PDFs",{
    captions <- utils::read.csv(file.path(review,"figures/captions.csv"),stringsAsFactors=FALSE)
    normalize <- function(x)gsub("[^[:alnum:]]","",tolower(gsub("₂","2",paste(x,collapse=" "),fixed=TRUE)))
    expected <- normalize(captions$caption[captions$figure_id=="S1-same-day-ABG"])
    stopifnot(nzchar(expected))
    for(name in c("bmi_hypercapnia","bmi_hypercapnia_audit")) {
      text <- system2("pdftotext",c(shQuote(file.path(review,paste0(name,".pdf"))),"-"),stdout=TRUE)
      if(!grepl(expected,normalize(text),fixed=TRUE))stop("S1 caption clipped or missing in ",name)
    }
  })
  check("every declared figure and required alternatives",{
    captions <- utils::read.csv(file.path(review,"figures/captions.csv"),stringsAsFactors=FALSE)
    stopifnot(nrow(captions)>0,!anyDuplicated(captions$figure_id))
    for (id in captions$figure_id) for (ext in c("svg","pdf","png")) {
      path <- file.path(review,"figures",paste0(id,".",ext))
      stopifnot(file.exists(path),file.info(path)$size>0)
    }
    required <- c("RFS-flow","RFS-evidence","S1-same-day-ABG",paste0("primary/",c("F1-A","F1-B","F1-C","F2","F2-bands")))
    stopifnot(all(required %in% captions$figure_id),all(file.exists(file.path(review,"figures",paste0(required,".jpg")))))
    display <- utils::read.csv(file.path(review,"figures/rfs-evidence-display.csv"))
    displayed <- display[display$displayed,]
    stopifnot(nrow(displayed)==2,all(displayed$population_id=="primary"),setequal(displayed$outcome_id,c("abg","any_gas")))
    q <- e2e_indexes(make_bmi_curve_fixture()); q <- q[q$group=="primary",]
    for (i in seq_len(nrow(displayed))) {
      e2e_near(displayed$N[i],nrow(q));e2e_near(displayed$M[i],sum(!is.na(q[[paste0(displayed$outcome_id[i],"_encounter")]])))
    }
  })
  check("printed figure probabilities and confidence limits",{
    normalize_text <- function(text) gsub("[[:space:]]+","",gsub("\u2212","-",paste(text,collapse=""),fixed=TRUE))
    number <- function(x) format(signif(x,4),trim=TRUE,scientific=abs(x)>0 & (abs(x)<.001 | abs(x)>=1e6))
    ci_label <- function(p,lo,hi) paste0(number(p),"% (95% CI ",number(lo),"–",number(hi),"%)")
    labels <- list()
    expect_label <- function(id,label) {
      file <- file.path(review,"figures",paste0(id,".pdf"))
      text <- normalize_text(system2("pdftotext",c(shQuote(file),"-"),stdout=TRUE))
      if (!grepl(normalize_text(label),text,fixed=TRUE)) stop("Missing numerical label in ",id,": ",label)
      labels[[length(labels)+1L]] <<- data.frame(figure_id=id,label=label,status="present in exported PDF")
    }
    q <- e2e_indexes(make_bmi_curve_fixture());q <- q[q$group=="primary",]
    for (outcome in c("abg","any_gas")) {
      n <- nrow(q);m <- sum(!is.na(q[[paste0(outcome,"_encounter")]]));p <- m/n;z <- qnorm(.975)
      centre <- (p+z^2/(2*n))/(1+z^2/n)
      half <- z*sqrt(p*(1-p)/n+z^2/(4*n^2))/(1+z^2/n)
      expect_label("RFS-evidence",ci_label(100*p,100*(centre-half),100*(centre+half)))
    }
    totals <- bundle$analysis$policy_totals
    totals <- totals[totals$status=="estimated" & grepl("/(encounter/spline)$",totals$model_id),]
    for (group in unique(totals$analysis_population_id))
      expect_label(paste0(group,"/F2"),bundle$config$policies[[1]]$label)
    for (i in seq_len(nrow(totals))) {
      t <- totals[i,];id <- paste0(t$analysis_population_id,"/F2")
      expect_label(id,ci_label(100*t$p_observed,100*t$p_observed_low,100*t$p_observed_high))
      expect_label(id,ci_label(100*t$p_shifted,100*t$p_shifted_low,100*t$p_shifted_high))
      expect_label(id,ci_label(100*t$PIF,100*t$PIF_low,100*t$PIF_high))
    }
    utils::write.csv(do.call(rbind,labels),file.path(out,"printed-figure-labels.csv"),row.names=FALSE)
  })
  check("public rejection of stale source, old schema and corrupt bundle",{
    manifest_path <- file.path(aggregate_only,"bundle_manifest.json")
    original <- jsonlite::read_json(manifest_path,simplifyVector=FALSE)
    write <- function(x) jsonlite::write_json(x,manifest_path,auto_unbox=TRUE,pretty=TRUE,digits=NA)
    bad <- original;bad$estimation_sources[[1]] <- strrep("0",64);write(bad)
    command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"html"),file.path(out,"reject-source.log"),FALSE,"source/hash mismatch")
    bad <- original;bad$schema_version <- 6L;write(bad)
    command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"html"),file.path(out,"reject-schema.log"),FALSE,"Superseded analysis")
    write(original)
    cat("\nARTIFICIAL corruption\n",file=file.path(aggregate_only,"model_registry.csv"),append=TRUE)
    command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"html"),file.path(out,"reject-bundle.log"),FALSE,"Bundle hash mismatch")
    stopifnot(file.copy(file.path(run,"model_registry.csv"),aggregate_only,overwrite=TRUE))
    # Verify the original and restored copy still load; never mutate the source run.
    bmi_read_bundle(aggregate_only);bmi_read_bundle(run)
  })
  check("public rejection of unrelated or stale reused figures",{
    reuse <- file.path(out,"invalid-figure-reuse");dir.create(reuse)
    previous <- jsonlite::read_json(file.path(review,"render-receipt.json"),simplifyVector=FALSE)
    path <- file.path(reuse,"render-receipt.json")
    old <- Sys.getenv("BMI_FIGURES_FROM",unset=NA_character_)
    Sys.setenv(BMI_FIGURES_FROM=reuse)
    tryCatch({
      bad <- previous;bad$bundle_manifest_sha256 <- strrep("0",64)
      jsonlite::write_json(bad,path,auto_unbox=TRUE,pretty=TRUE)
      command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"html"),file.path(out,"reject-figure-bundle.log"),FALSE,"different aggregate bundle")
      bad <- previous;bad$render_sources[["R/reporting.R"]] <- strrep("0",64)
      jsonlite::write_json(bad,path,auto_unbox=TRUE,pretty=TRUE)
      command("scripts/render_bmi_hypercapnia.R",c(aggregate_only,"html"),file.path(out,"reject-figure-source.log"),FALSE,"Figure-source hash mismatch")
    },finally={if(is.na(old))Sys.unsetenv("BMI_FIGURES_FROM")else Sys.setenv(BMI_FIGURES_FROM=old)})
  })
  check("run and verification source identities stable",{
    stopifnot(identical(receipt$bundle_manifest_sha256,tri_sha256(file.path(run,"bundle_manifest.json"))),
      identical(receipt$test_sources,bmi_hash_files(names(receipt$test_sources))))
  })
  files <- unique(c(file.path(run,c("bundle_manifest.json",names(bundle$manifest$files))),
    list.files(review,recursive=TRUE,full.names=TRUE),list.files(out,full.names=TRUE)))
  files <- files[file.exists(files)&!file.info(files)$isdir]
  # The final receipt binds this immutable index; it must not hash itself or an
  # earlier version of the still-open receipt.
  files <- setdiff(files,file.path(out,c("receipt.json","artifact-hashes.csv")))
  hashes <- data.frame(path=files,sha256=vapply(files,tri_sha256,character(1)),bytes=file.info(files)$size)
  utils::write.csv(hashes,file.path(out,"artifact-hashes.csv"),row.names=FALSE)
  receipt$status <- "passed";receipt$artifact_index_sha256 <- tri_sha256(file.path(out,"artifact-hashes.csv"))
  receipt$repeat_command <- "Rscript --vanilla tests/run_e2e.R"
  receipt$finished_utc <- format(Sys.time(),tz="UTC",usetz=TRUE)
  persist()
},error=function(e) {
  receipt$status <<- "failed";receipt$failure <<- conditionMessage(e);persist()
  stop("E2E failed; retained evidence: ",out,"\n",conditionMessage(e),call.=FALSE)
})
message("Analysis/report E2E passed: ",file.path(out,"receipt.json"),"\nSource qualification and human review are separate.")
