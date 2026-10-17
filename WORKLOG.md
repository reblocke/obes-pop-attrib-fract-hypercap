# Worklog

## 2026-10-17 — Adopt the reviewed merged upstream mapper pin

Owner approval covers upstream PR28 merge, mapper pin adoption and GitHub
reauthentication. The active mapping configuration now pairs merged upstream
`751d794e0a277f72ced2e2b5b48246858f4dcf9b` with mapper SHA-256
`0e1036b94cce9f7e753c57f5c860997df41adc313ba440c7b13c4897bab5844e`.
Only those two configuration fields changed. The other four module hashes and
all transformation, selection, R analysis and rendering code are unchanged.

Before the change, the actual new installed wheel was rejected by the historical
profile. After the change, the real child gate accepts the reviewed pair and
rejects crossed revisions, forged hashes and an unreviewed revision. All 28
existing retained mapper E2E cases passed on both hosts with noneditable wheels
and no PYTHONPATH. The rebuilt wheel matches the upstream hosted artifact, and
all 122 package modules match the actual merged source.

Commands: `verify_calendar_covariates_e2e.py --require-installed`, its read-only
`--verify` mode, the retained exact-pin qualification driver, and
`python -m unittest discover -s tests -p 'test_preparation*.py'`.
The first preparation check used an unactivated R library and failed on missing
`jsonlite`. Activating the existing qualified Mini R library resolved that setup
issue; all 16 checks passed. Both logs are preserved. No package was installed
into a qualified clinical runtime.

Historical source/configuration/runtime and accepted products remain unchanged.
Public documentation now distinguishes the active profile from historical
reproduction. The private engineering handoff retains commands, source/fixture/
runtime identities and artifact hashes. No clinical job, source extraction,
product regeneration or readiness promotion is part of this update.

Publication and source synchronization are recorded in the delivery handoff;
the existing child repository has no hosted checks configured.

## 2026-05-07 08:31 MDT - Refactor obesity/HRF PAF repository setup

Task completed:

- Created canonical report layout under `reports/`.
- Added `reports/obesity_hrf_paf_analysis.qmd` as the maintained refactored analysis report.
- Added `reports/reconstructed_obesity_hrf_from_pdf.qmd` as the archival reconstruction.
- Case-renamed tracked `AGENTS.MD` to `AGENTS.md` and merged in the obesity-HRF project instructions with retained generic R/Quarto guardrails.
- Moved local restricted dataset from `full_db.rds` to `data/raw/full_db.rds`.
- Added `.gitignore` rules for raw data and local Quarto render outputs.
- Added `README.md`, `Makefile`, `docs/DECISIONS.md`, and `docs/DATA_MANAGEMENT.md`.
- Updated the canonical report so figure captions/alt text use valid Quarto comment-YAML chunk options.
- Added explicit ABG/VBG gas-pair availability, HRF-v1 unclassifiable counts, labelled respiratory-status missingness, and a visible PIF table with observed risk, counterfactual risk, and impact fraction.

Commands run:

- `Rscript -e 'x <- readRDS("data/raw/full_db.rds"); ...'`
- `Rscript -e 'cat("R ", as.character(getRversion()), "\n", sep=""); ...'`
- `quarto --version`
- `make test`
- `make render`

Verification:

- `data/raw/full_db.rds` exists, is ignored by Git, and reads successfully.
- Source dataset has 833,476 rows and 548 columns.
- Required report columns are present: `curr_bmi`, `niv_proc`, `imv_proc`, `highest_paco2`, `abg_ph`, `vbg_co2`, `vbg_ph`, `age_at_encounter`, `sex`, `ethnicity`, `has_j9612`, `has_j9622`, `has_j9692`, `has_j9602`.
- Required R packages checked as installed: `dplyr`, `forcats`, `ggplot2`, `gtsummary`, `haven`, `here`, `modelsummary`, `purrr`, `stringr`, `tibble`, `tidyr`, `testthat`.
- R version checked: 4.5.3.
- Quarto version checked: 1.9.36.
- `make render` succeeds for the HTML report.
- Rendered HTML includes dataset N, BMI missingness, ABG/VBG pair availability, attrition, respiratory-status counts, HRF-v1 unclassifiable counts, baseline table, BMI-category plots, primary/strict model tables, hypercapnia subgroup model, named PIF table, PIF figure, BMI-risk curve, and figure alt text.
- `make test` reports that no `tests/testthat` directory exists yet.

Warnings and next steps:

- A full default `quarto render reports/obesity_hrf_paf_analysis.qmd` attempted both HTML and PDF. HTML completed, but PDF failed because local TeX Live 2025 tried to update from the remote 2026 repository and `tlmgr` refused the cross-release update. Use `make render` for HTML verification until TeX Live is updated; use `make render-pdf` after the local TeX installation is fixed.
- No `renv.lock` exists and no `renv` initialization was run. `make renv-init` is documented as a maintainer-approved manual step.
- Helper-function extraction to `R/` and `testthat` derivation tests remain deferred until after the report is reviewed.

## 2026-05-07 11:53 MDT - Address review findings

Task completed:

- Updated `reports/reconstructed_obesity_hrf_from_pdf.qmd` so the archival report looks for `data/raw/full_db.rds` first and falls back to root `full_db.rds`.
- Added minimal archival compatibility flags: `has_bmi`, `has_abg_pair`, `has_vbg_pair`, `has_any_gas_pair`, and `has_any_gas`.
- Removed the duplicate untracked `AGENTS_obesity_hrf.md` source artifact because its contents were merged into canonical `AGENTS.md`.
- Ignored and removed an empty `.Rhistory` generated during local render verification.

Commands run:

- `make render`
- `make render-archival`
- `make test`
- `git status --short --untracked-files=all --ignored`
- `git ls-files | rg '^AGENTS'`

Verification:

- `make render` succeeds for the canonical HTML report.
- `make render-archival` succeeds for the archival HTML report.
- `make test` reports that no `tests/testthat` directory exists yet.
- `AGENTS_obesity_hrf.md` is absent.
- `git ls-files | rg '^AGENTS'` shows only `AGENTS.md`.
- `data/raw/full_db.rds` remains ignored by Git.
- Rendered HTML and support files under `reports/` remain ignored by Git.

## 2026-05-07 15:43 MDT - Bootstrap manual renv target

Task completed:

- Updated `make renv-init` so the target installs `renv` if it is missing before running `renv::init()` and `renv::snapshot()`.
- Updated README, data-management docs, and agent instructions to clarify that `renv-init` bootstraps `renv` only when explicitly run after maintainer approval.

Commands run:

- `make -n renv-init`
- `make render`
- `make render-archival`
- `make test`
- `find . -maxdepth 2 \( -name 'renv.lock' -o -name 'renv' \) -print`

Verification:

- `make -n renv-init` prints the expected bootstrap command and does not run it.
- `make render` succeeds for the canonical HTML report.
- `make render-archival` succeeds for the archival HTML report.
- `make test` reports that no `tests/testthat` directory exists yet.
- No `renv.lock` or `renv/` directory was created during verification.

## 2026-05-07 - Align PDF output, cutoff, and flag wording

Task completed:

- Made `make render` call the full Quarto render so configured outputs include PDF.
- Added `make render-html` for quick HTML-only local checks.
- Removed `pdf-standard: ua-2` from report YAML so local PDF output does not depend on the unavailable `latex-lab` TeX package update.
- Aligned the archival strict lab definition to pH `<= 7.35`.
- Updated agent validation wording from `has_any_gas` to canonical `has_any_gas_pair`.
- Updated README, data-management docs, and implementation ticket wording to describe PDF output as expected.

Commands run:

- `make render`
- `make render-pdf`
- `make render-html`
- `make render-archival`
- `make test`

Verification:

- `make render` succeeds and creates configured HTML and PDF outputs for the main report.
- `make render-pdf` succeeds and creates `reports/obesity_hrf_paf_analysis.pdf`.
- `make render-html` succeeds when run sequentially.
- `make render-archival` succeeds after aligning the archival strict lab cutoff to pH `<= 7.35`.
- `make test` reports that no `tests/testthat` directory exists yet.

## 2026-05-07 - Ignore Finder metadata and annotate refactor

Task completed:

- Added `.DS_Store` to `.gitignore`.
- Removed tracked `.DS_Store` files from the Git index while leaving local Finder metadata files on disk.
- Added novice-friendly section introductions and helper-function comments to `reports/obesity_hrf_paf_analysis.qmd`.
- Preserved analysis logic, model formulas, scientific cutoffs, and report outputs.

Commands run:

- `git status --short --untracked-files=all`
- `git ls-files '.DS_Store' '*/.DS_Store'`
- `git rm --cached -f --ignore-unmatch .DS_Store Code/.DS_Store obesity_hrf_refactor_pack/.DS_Store`
- `make render`
- `make render-archival`
- `make test`
- `git status --porcelain=v1 --ignored=matching`
- `git diff --check`
- `git diff --cached --check`

Verification:

- `make render` succeeds and creates the configured main report outputs.
- `make render-archival` succeeds for the archival HTML report.
- `make test` reports that no `tests/testthat` directory exists yet.
- `git ls-files '.DS_Store' '*/.DS_Store'` returns no tracked `.DS_Store` files.
- `git diff --check` and `git diff --cached --check` report no whitespace errors.
- `data/raw/full_db.rds`, rendered report outputs, and local `.DS_Store` files remain ignored.

## 2026-10-12 10:39 MDT - Repository and ATS abstract readiness audit

Task completed:

- Reviewed the six QMD versions, retained PDF reports, repository history, analysis decisions, and data-management notes at `e316cc3`.
- Compared source contracts with the related TriNetX preprocessing, hypercapnia, GLP-1 eligibility, bicarbonate, and diagnostic-equity repositories. This was a local source review, not cross-host synchronization or restricted-data qualification.
- Confirmed that the maintained QMD implements model-standardized observed/counterfactual risks and named BMI caps, while the newer September trainee PDF contains additional scenarios and model-refitting bootstrap intervals not integrated into maintained source. Its actual bootstrap setting is 200 replicates, overriding the function's 2,000-replicate default.
- Found an analysis plan and implementation ticket, but no standalone abstract/manuscript outline. Existing analysis figures include BMI-category bars, a PIF dot plot, and a standardized BMI-risk curve; no final abstract exhibit is designated.
- Verified current ATS 2027 instructions: November 4, 2026, 5 p.m. Eastern deadline; 400-word body; at most one table or figure in JPG format; scientific results required at submission.

Findings requiring reconciliation before an abstract result is selected:

- September PDF and canonical QMD differ in arterial/venous source precedence, the pH boundary, and BMI counterfactuals. Retained numerical estimates must remain tied to their own versions.
- The shared TriNetX repository contains `r/reports/90_stata_to_r.qmd`, a candidate DTA-to-RDS conversion route. Its existence does not authenticate this repository's local RDS; exact source snapshot, conversion settings, schema, identifiers, and grain still need confirmation.
- Shared documentation describes `full_db.dta` as an enriched suspicion cohort with repeat encounters. If that lineage is confirmed, generalization beyond the selected source cohort requires separate justification.
- This analysis uses current BMI rather than the shared current/prior/calculated BMI hierarchy. Gas fields, measured versus imputed pH, temporal pairing, and ICD composites also need an explicit crosswalk; study-specific definitions should not be silently overwritten.
- Synthetic checks reproduced HRF-negative classification when hypercapnic acidosis is present but ventilation status is unresolved. A separate synthetic factor-coded ICD example reproduced level-code misinterpretation by `as.numeric() == 1`; actual input susceptibility was not assessed.
- The strict sensitivity selects concordant lab/ICD records, changing the denominator. Attrition should show separate cohort branches and final model exclusions.
- PIF/curve uncertainty, repeat-encounter dependence, BMI functional form, and a small synthetic derivation test suite remain to be reconciled in the canonical source. No environment lockfile or existing test suite was found.

Files changed:

- `WORKLOG.md` only; no analysis definitions, code, data, or retained report outputs changed.

Commands and verification:

- `git status --short`, `git log`, `git ls-files`, and bounded `rg`/source inspection.
- Bounded PDF routing for six reports. Canonical and BL PDFs passed native routing; four trainee PDFs required whole-document Poppler text fallback because the first extractor returned sparse pages. Relevant definition, bootstrap, result-table, and figure pages were rendered and visually checked.
- Executed an external temporary R script containing only canonical helper definitions and synthetic fixtures. No restricted input was read and no report was rerendered.
- `git diff --check` and final changed-file review.

Outputs and next steps:

- Repository summary, provisional estimand recommendation, and dated ATS preparation roadmap provided in the review chat. Temporary PDF inspection receipts and synthetic checks remain outside the repository.
- Recover the September QMD, authenticate the source/conversion chain, agree one primary estimand, reconcile and test the canonical code, then rerender with suitable uncertainty and focused sensitivities. Select one figure, draft the structured abstract, and complete author review before submission.
- Recommendations from this audit are proposed, not adopted scientific decisions. Prior renders and retained estimates were inspected, not newly reproduced.

ATS sources:

- https://site.thoracic.org/conference/program/call-for-scientific-abstracts-and-case-reports
- https://site.thoracic.org/conference/program/call-for-scientific-abstracts-and-case-reports/submission-criteria

## 2026-10-12 10:48 MDT - Locate historical Stata impact-fraction analysis

- Followed up on the maintainer's recollection of a Stata analysis. No Stata or Python analysis files were found in this repository's tracked current tree or available Git history.
- Located the separate analysis in `trinetx-hypercapnia-code`: `stata/do/36_subpop_hazard.do`, originally `Hypercapnia subpop hazard.do`. Git history records its introduction at `cdcea13` (2025-11-29), expansion at `96a94e9` (2025-12-10), and promotion into the ordered pipeline at `80e3700` (2026-03-23).
- Its target is the `OBESITY_rfs == 1`, BMI >=40 encounter subset, with BMI reassigned to 40. Outcomes are the legacy diagnosis composite and ABG hypercapnia in the ABG-tested subset. Models adjust for age, sex, race/ethnicity, and location, with linear and restricted-cubic-spline specifications. `margins` and `nlcom` calculate standardized risks and impact fractions with model-based uncertainty.
- A March source snapshot retains the original estimand rationale, including the concern about conditioning on blood-gas testing and the intent to avoid adjusting for obesity-mediated conditions. Historical ABG BMI/age spline figures and a baseline table also exist outside this repository.
- The older repository's current architecture explicitly retains Stata downstream estimators. Its Python Stage 36 specification points to the Stata do-file. Searches of current Python/notebook source and seven archived branch tips found no matching impact-fraction estimator implementation; the Python port concerns preprocessing and workflow/validation support.
- This supplements the earlier inventory: the broader project has a separate, more developed severe-obesity Stata analysis that should be compared with the gas-classifiable R analysis before choosing the abstract estimand. The two are not equivalent implementations of one specification.
- Verification: bounded source inspection, Git history/rename tracing, archived-ref Python/notebook searches, and `git diff --check`. No clinical data were read, analyses executed, packages installed, or source code changed. Only this worklog was updated.

## 2026-10-12 12:10 MDT - Duplicate preserved Stata analysis and compare tracks

Task completed:

- Imported `stata/do/36_subpop_hazard.do` from `trinetx-hypercapnia-code` commit `d5d269168eafc7905c9238a5486fc03a62b55ec3`. Preserved the exact source in `archive/stata/36_subpop_hazard.source.do` and recorded original SHA-256 `6e25200c421be03c7f05e6a93898cd7a7816eff015b0095bf4f5668606cf7482`.
- Adapted initialization, input/output paths, required-column checks, logging, and invocation only. The complete scientific block after `START DATA ANALYSIS` is byte-identical to the source snapshot.
- Added an explicitly invoked Stata entrypoint, copied/pinned unattended runner, prerequisite checks, isolated output/source receipts, and `stata-check`, `stata`, and `stata-test` Make targets.
- Copied six historical aggregate Stata workbooks/TIFFs and a source design note into ignored local evidence storage. Retained a hashed inventory/search receipt; reused R PDF extraction receipts after source-hash verification and visually verified relevant figures/tables.
- Added the methods/findings/exhibit comparison, structured consistency/results audits, portable evidence inventory, import provenance, and command documentation. Updated README, AGENTS, decisions, data management, and the historical-ticket banner.

Verification and commands:

- `STATA_EXE=<licensed executable> make stata-check`: passed on the installed Stata/BE 18 with table1_mc, mkspline2, xblc, and cleanplots. No package installation.
- `make stata-test`: 8 standard-library tests passed, including archive/body/runner hashes, missing executable/input, path handling, output isolation, fresh native-code evidence, failure propagation, and ignore rules.
- `python3 tests/stata_smoke.py --stata <licensed executable>`: synthetic integer-BMI input completed the imported and unchanged original analysis with natural exit and native return code zero. All 12 displayed risk/PIF values matched at printed precision.
- The decimal-BMI variant reproduced the same inherited plotting `r(198)` in both scripts, with 9 preceding displayed risk/PIF values matching. Both receipts retained; no scientific fix.
- Native isolated dependency/schema probes returned `r(499)` for unavailable packages and `r(111)` for a synthetic input missing has_abg; the project CLI propagated status 111. Intentional error 459 and timeout cleanup were also verified.
- Confirmed original TriNetX HEAD/status unchanged; all existing QMD hashes and R render recipes unchanged; prior uncommitted worklog bytes preserved.
- Checked structured audit fields/source hashes, evidence-copy hashes, documentation links, `.gitignore` coverage, and `git diff --check`.

Outputs, errors, and limits:

- New runnable Stata track and documentation are local working-tree changes; nothing committed, pushed, or published.
- Ignored `artifacts/stata/` contains synthetic verification and execution receipts. Ignored `artifacts/evidence/` contains historical aggregate evidence and PDF inspections.
- Header-only source diff and implementation baseline retained locally. Stata's native failure codes are preserved exactly in result.json; shell statuses cap at 255.
- The inherited xblc comparison with float(at_value) fails for the tested double-precision decimal BMI. Integer-BMI execution passed. Plotting varlist/profile concerns are documented, not repaired.
- The three inspected local TriNetX checkouts contained no retained Stage 36 PIF logs in current/legacy subpop-hazard output roots. The available baseline table/curves are not substitutes for those estimates.
- Historical empirical findings have incomplete run/input lineage; September's updated QMD remains unavailable. No clinical input was opened and no clinical model/report was rerun.

Next steps:

- Review the two scientific questions, authenticate source/input/timing, recover missing Stata PIF logs and September QMD, and select an ATS estimand separately. Any scientific correction or fresh clinical reproduction requires its own requested scope.

## 2026-10-12 13:15 MDT - Repair decimal xblc plotting error

- User explicitly requested fixing the xblc error in the runnable Stata copy.
- Reproduced the double-precision decimal-BMI `r(198)` in the unchanged original and pre-fix duplicate. The installed xblc compares observed values with float(at_value); the decimal grid can therefore fail despite values being observed.
- Added `stata/ado/obesity_spline_profile.ado`, using observed spline terms with built-in predictnl for the same fixed-profile log-odds predictions and normal confidence limits. Replaced the four BMI/age xblc plotting calls. No raw predictor rounding, model refit, population change, knot change, or PIF-command change.
- The driver captures/loads the helper per run. Removed the now-obsolete xblc runtime dependency; archived-reference regression tests still require it. No installed ado package changed.
- Preserved the exact source archive and earlier failed receipts. The provenance receipt records the four authorized replacements and helper/current-body hashes. Tests reverse those replacements and demand byte-identical original analysis code.
- Updated import/comparison documentation, decisions, agent instructions, README, audit metadata, and native regression tests. All empirical findings remain historical, without a new clinical render.

Verification:

- `make stata-test`: 9 unit tests pass, including immutable archive, declared correction scope, helper snapshot/loading, and launcher boundaries.
- `STATA_EXE=<licensed executable> make stata-check`: native success on Stata/BE 18; no packages installed.
- Integer-BMI smoke: archived and repaired analyses complete; all 12 displayed risk/PIF values match.
- Decimal-BMI smoke: repaired analysis completes with native status zero; archived original retains r(198). All nine displayed risk/PIF values available before the reference failure match. The repaired analysis completes all four model/PIF sections.
- `tests/stata_profile_test.do`: integer profiles agree with legacy xblc within its float output precision; decimal and nearly adjacent grids retain exact observed values. Original inputs, row order, coefficients, and covariance are unchanged. Profile odds/normal limits agree with independent lincom calculations at declared 1e-10/1e-8 relative tolerances.
- Initial focused regression harness used an unsupported datasignature varlist form; corrected to the built-in _datasignature varlist call and retained the failed test receipt. The corrected test completes successfully.
- Native success/failure/timeout and missing-package cases remain covered in the smoke. Link/hash checks and git diff --check pass.

Limits and next steps:

- No clinical input was opened and no empirical figure/PIF was regenerated. No commit, push, or publication.
- The original TriNetX checkout and all existing R sources remain unchanged.
- The separate s_bmi40 wildcard/profile-interpretation questions remain documented for scientific review; this fix does not resolve them.

## 2026-10-12 - Implement patient-level BMI association triangulation

- Saved the approved implementation specification in `docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md` in this obesity repository. Added a separate `reports/bmi_hypercapnia_triangulation.qmd`, reusable R helpers, an explicit input-manifest template, and dedicated test/fixture/clinical-render commands. Existing report targets remain unchanged.
- Implemented the nine adjusted BMI odds ratios: BMI >=40, ABG-drawn, and either-gas-drawn frames crossed with legacy ICD, ABG >=45, and ABG >=45 or VBG >=50 outcomes. Both gas frames retain all BMI values. Adults' first qualifying 2022 ED/inpatient encounter is selected independently per frame before completeness checks. No PAF/PIF calculation was added.
- Retained the legacy derived BMI and Stata adjustment set (age, sex, combined race/ethnicity, location), with linear BMI/age log-odds terms. Missing outcomes/covariates, uncertain frame membership, conflicting source versions, and ambiguous indexes are counted explicitly. No later-encounter substitution or silent estimator/term change occurs.
- Added exact source identity and reviewed coding checks. The manifest requires specimen-specific maximum valid encounter PCO2, separate draw indicators, reviewed ICD capture, dates, and category coding. Source declarations are acceptance requirements, not proof of clinical validity.
- Added aggregate CSVs, a three-panel forest plot with SVG/PDF masters and 300-dpi PNG/JPG copies, and source/runtime/render receipts in fresh ignored output directories. No patient identifiers or row-level indexes are exported by the report.
- Updated the README and decisions to distinguish this association workflow from both historical impact-fraction analyses. No package installation, clinical input read, clinical execution, commit, push, or submission occurred.

Verification:

- `make triangulation-test`: all eight artificial-data check groups passed, including inclusive thresholds, gas evidence states, first-index selection, contradictory duplicates, missing adjustment values, separation/nonestimability, exact nine-model parity against independent `glm()` fits, denominator reconciliation, and manifest/source validation. `testthat` was unavailable, so the dedicated runner executed the same shared checks with base R assertions; the testthat adapter is supplied but was not executed on this host.
- `make triangulation-fixture`: HTML and five-page PDF rendered successfully under R 4.6.1 and Quarto 1.10.18 with installed dependencies only. Final reviewed fixture run: `artifacts/triangulation/fixture-20261012T232828-89314/`. All values are prominently marked artificial.
- Inspected every PDF page and browser-rendered HTML, plus plot exports, grayscale readability, and an artificial nonestimable-row preview. Corrected a missing CO2 subscript glyph and an awkward page break, then rerendered and reinspected. HTML images loaded and had no horizontal page overflow at the inspected viewport. PNG/JPG output is 2700 by 2100 pixels (9 by 7 inches at 300 dpi).
- Independent source review found no remaining material correctness gaps. All 15 pre-existing analysis/source hashes matched the preserved implementation baseline. Final render-source hashes, local documentation links, Git ignore coverage, and `git diff --check` passed. Prior uncommitted work was retained.

Remaining work:

- Bind and review an actual analysis-ready input and its producer/source evidence using `config/triangulation_input.example.json`; its pending fields intentionally prevent use as a qualified manifest. Actual-data execution and scientific qualification remain separate from this implementation.
- Review model behavior and the clinical interpretation on accepted actual results before revising an abstract or selecting an exhibit. Artificial reports establish workflow behavior and layout only. Dependencies are recorded per run but are not locked in an installed project environment.


## 2026-10-13 - Correct primary estimand to the confirmed BMI-to-40 scenario

- The user clarified that the desired primary quantity is a standardized attributable/impact fraction, rather than the previously implemented odds ratio alone. The user then explicitly reversed an interim BMI-minus-one choice and confirmed setting observed BMI above 40 to 40 kg/m², with BMI at or below 40 unchanged.
- Updated the saved implementation plan, decisions, and README with the confirmed counterfactual and scope. The selected indexes, three sampling frames, three outcome definitions, derived BMI, complete-case rules, and legacy Stata adjustment set are unchanged. Original frame membership remains fixed in both prediction scenarios.
- Added `standardize_bmi40()` to the R helper. It averages predicted probabilities on identical observed model cases under observed BMI and `pmin(bmi,40)`, then reports both probabilities, their absolute difference, and `1 - p_counterfactual / p_observed`. Adjusted odds ratios remain supporting outputs.
- Added full-coefficient-covariance delta-method intervals on the log probability-ratio scale, transformed to the fraction scale. Intervals condition on the empirical covariate distribution. Negative fractions are retained. No-change scenarios and invalid standardization are explicit. The report identifies extrapolation beyond each cell's observed BMI range.
- Revised the Quarto report and primary figure to the BMI-to-40 fractions, with a linear percentage axis and zero reference. Captions and interpretation distinguish modeled documented hypercapnia at the index encounter from incident disease, total obesity burden, or demonstrated prevention. Causal interpretation remains dependent on temporal ordering, intervention consistency, confounding control, support, measurement, and selection/missingness assumptions.

Verification:

- `make triangulation-test`: all 11 artificial-data groups passed using the existing base-R fallback because testthat remains unavailable. Added exact BMI-to-40/direct-prediction checks, independent finite-difference verification of delta-method gradients and intervals, fixed denominator/index checks, null/negative/no-change scenarios, invalid predictions, and support counts. No packages installed.
- `make triangulation-fixture`: successful HTML and seven-page PDF render. Final run: `artifacts/triangulation/fixture-20261013T101226-10466/`. Every PDF page and browser HTML inspected; figure SVG/PDF/PNG/JPG reviewed, including grayscale and artificial negative/nonestimable-row checks. Raster dimensions verified as 2700 by 2100 at 300 dpi. No clipping or missing symbols found in the inspected outputs.
- Independent source review found no material computational or cohort-selection gaps. Its caption wording observation was corrected before the final render. Existing fixture OR estimates, intervals, statuses, and denominator fields match the prior run exactly.
- All 15 historical analysis/source hashes remain unchanged. Final render-source hashes, documentation links, generated-file ignore coverage, and `git diff --check` passed. Historical outputs and unrelated uncommitted work retained.

Limits and next steps:

- Only artificial fixtures were analyzed. No clinical data opened, clinical run, installation, commit, push, or submission. The actual input and source mapping still require review before an authorized clinical run.
- The target population for each estimate is its model-evaluable subset; full-frame inference requires additional missing-data assumptions or methods. Model-based intervals do not quantify bias or uncertainty from the empirical covariate distribution, confounding, ascertainment, or selection. Historical R and Stata analyses remain distinct.

## 2026-10-13 11:22 MDT — Freeze triangulation estimates and develop three QC-reviewed exhibits

- Implemented the accepted execution plan with fixed scientific definitions and BMI-to-40 counterfactual. The original estimation helper, canonical/archival R reports and preserved Stata/source files retain their baseline hashes.
- Added `scripts/preflight_triangulation.R` and `make triangulation-preflight`. Inspected the local RDS for schema, key aggregates, candidate field characteristics and selected category dictionaries; no identifier values exported and no clinical models fitted. Exact source and schema identities are retained in ignored receipt `artifacts/triangulation/preflight-20261013T105341-17075/`.
- The RDS is not authenticated for the agreed input contract. Producer/conversion lineage, original patient-key provenance, independent gas-draw evidence, specimen-specific encounter maxima, and ICD-negative/unknown capture remain unresolved. Inspected the candidate producer at c857ee5; verified relevant code and checked LOINC blood-versus-arterial concepts. Saved a field-specific upstream request in `docs/TRIANGULATION_INPUT_HANDOFF.md`; no request was sent and the pending manifest was not falsely completed.
- Added `R/triangulation_reporting.R`. The launcher now calls the estimator once and writes a strict aggregate-only RDS/CSV bundle, audits and hash receipts. Quarto reads that bundle for HTML/PDF. `make triangulation-review RUN=...` reuses saved results in a fresh review directory without clinical input access or model evaluation. Bundle/file tampering and unexpected fields are rejected.
- Created A (compact forest), B (outcome-first triptych), and C (3×3 mini-forest matrix), sharing exact numerical content and common linear axes. Exported SVG/PDF masters and 300-dpi PNG/JPG at 190×180 mm, plus HTML and three-page PDF galleries. Direct labels show PIF/95% CI/N, unknown outcomes and outside-BMI-range counts; frame headers retain unresolved indexes and uncertain membership. A is recommended provisionally for magnitude/precision comparison; C emphasizes the design.
- Used figure-and-medical-illustration-qc creation/unified workflows. Added `docs/TRIANGULATION_FIGURE_BRIEF.md`; updated the saved plan, README, data-management note, Make targets and shared tests. Outputs, receipts, inspection images and QC records remain ignored.

Verification and retained failures:

- `make triangulation-test`: all 14 shared artificial check groups pass through base R; testthat remains unavailable and was not installed. New checks cover exact bundle roundtrip after input removal, loader/estimator tripwires during aggregate consumption, file/manifest hash failures, aggregate-only fields, denominator corruption and negative/wide/zero/nonestimable display states.
- `make triangulation-fixture` completed analysis once and HTML/PDF rendering. `make triangulation-review` completed multiple display-only revisions. Frozen aggregate hashes remain unchanged. Every estimate, confidence endpoint, count and status matches `fixture-20261013T101226-10466` within 1e-12; all seven saved preservation-baseline source hashes still match.
- Initial PDF render failed because the default graphics device could not resolve Arial. Switched Quarto PDF graphics to Cairo; retained the failed render receipt/log. Visual review corrected clipped caption lines, dense labels, a triptych axis collision, a heading-only PDF page, missing negative ticks in a wide-interval stress case and diagnostic-label margins for large counts. An implicit Rplots.pdf from device-free grob construction was moved to ignored recovery and prevented by explicit null-device handling.
- Artificial display-stress previews inject negative/wide/zero/nonestimable states and large counts. They have their own display ledger and receipt, and are explicitly not analysis outputs. A borrowed analysis hash in the initial stress-only receipt was invalidated and retained as recovery evidence.
- Final reviewed source analysis: `artifacts/triangulation/fixture-20261013T110930-22012/`. Final delivery review: `reviews/review-20261013T111507-23589/`. Both report formats succeeded; the final report has nine pages. Gallery has three full-size pages. All 12 final SVG/PDF/PNG/JPG exports, every report page, browser gallery, grayscale views and artificial stress cases inspected.
- PDF read-back matches all nine PIF/CI labels, model Ns and unknown counts in each candidate. Display-ledger fields match the source CSV. Raster metadata verified as 2244×2125 pixels, RGB, PNG DPI 299.9994 (rounding) / JPG 300. Browser views loaded all images and had no page errors or horizontal overflow at 1400 pixels. QC manifest, caption, technical JSON and human review receipt retained under the final review's `qc/`.
- No clipping or missing symbols remain in the inspected artificial outputs. No color-vision simulation was performed; grayscale and redundant text/shape encoding were reviewed. Scientific/coauthor review remains distinct.

Remaining work:

- Obtain the authenticated fields/evidence specified in the upstream handoff, bind the actual manifest, then execute and review clinical estimates. The current deliverables contain artificial numbers only. No clinical run, installation, commit, push or submission occurred.

## 2026-10-13 12:09 MDT — Fix both delegated review findings and prepare merge

- Reproduced the preflight failure with an artificial all-NA numeric gas-draw field and an all-NA factor. Added an explicit all-missing dictionary marker with the missing count, allowing the audit to write its final receipt. Existing observed category counts are unchanged.
- Replaced repeated named-list patient-group searches with positional traversal and one precomputed patient match for uncertain encounters. Index order, first-encounter selection, ties, earlier uncertainty and all denominators remain identical; no scientific definition or estimator changed.
- Added two shared regression groups covering mismatched patient-group positions, later/earlier/undated uncertainty, reversed source order, empty confirmed groups, all-missing numeric/factor preflight fields and empty-input receipt completion.
- Created a recovery snapshot of all 36 reviewed source paths under ignored `artifacts/triangulation/review-fixes-20261013/` before editing. Prepared branch `codex/triangulation-reviewed-fixes` for the reviewed source package and these fixes; restricted inputs and generated evidence remain ignored.

Verification:

- `make triangulation-test`: all 16 artificial check groups pass using the existing base-R fallback; no packages installed.
- `make stata-test`: nine source/launcher tests pass. `STATA_EXE=<licensed executable> make stata-check` succeeds. Decimal-BMI synthetic native smoke succeeds for the repaired workflow, reproduces the archived expected r(198), and matches all nine pre-failure displayed estimates. No clinical input was opened.
- Original-versus-fixed selection objects and the full nine-cell analysis are identical on the artificial fixture. Benchmarks with uncertain-encounter groups also retain exact selection/audit/count parity: 10k patients 2.391s →1.700s; 20k 5.846s →3.606s; 40k 17.714s →8.658s. Timings are illustrative local measurements, not a clinical performance guarantee.
- `make triangulation-fixture`: fresh HTML/PDF report and A/B/C exports succeed in `fixture-20261013T120843-34089`. The aggregate CSV and all PNG/JPG/SVG candidates match the prior QC-reviewed outputs byte-for-byte; all nine PDF pages match as rendered pixels. Figures and scientific results therefore need no content revision for these fixes.
- Source-only staging/privacy checks and whitespace validation are performed before publishing. Clinical source authentication remains unresolved as documented in the upstream handoff.
- The staged whitespace check identifies only inherited trailing whitespace in the immutable Stata archive and matching preserved runnable analysis body. Those bytes are retained for provenance; the remaining staged source/documentation passes the whitespace check.

## 2026-10-13 21:32 MDT — Make BMI >30 minus one primary; retain runnable historical tracks

Implemented the user-approved one-unit shift with observed BMI >30 eligibility, no floor and no reindexing. This supersedes the primary BMI-to-40 scenario, without changing the intentionally distinct frames, inclusive thresholds, five-code ICD composite, legacy BMI or inherited linear adjustment formula.

Files and behavior:

- `R/bmi_hypercapnia_triangulation.R` now provides the ordered fifteen-cell registry: nine encounter primary and six fixed-index calendar-day sensitivities. Conflicting calendar-day summaries remain unknown without creating primary key conflicts. A pending timing module retains six unassessed positions, not measured zeros. Added aggregate timing transitions and BMI/model-shape/support diagnostics.
- `R/triangulation_reporting.R`, the primary QMD and launcher persist version-2 scenario/registry/input/manifest/source identities and strict aggregate-only results. Rendering reads saved aggregates without clinical data or refitting. Inputs/manifests/sources are checked for changes during execution. Version-1 saved runs use hash-verified frozen sources and keep their nine-cell BMI-to-40 definitions.
- The version-2 input contract requires reviewed source qualification gates and hashed lineage/population/field evidence. The pending example is not falsely accepted. Optional calendar-day mapping has separate evidence, availability and exact window requirements.
- Promoted `make render`, `render-html`, `render-pdf` to explicit saved-run review. Dedicated clinical estimation, preflight, fixture and historical commands remain. Updated README, instructions, plan, decisions, audit response, source assessment and archive index.
- Preserved nine exact original source/document files from `1e78e3c` with hashes under `archive/2026-10-13-bmi-to-40/`. Moved the unchanged reconstructed QMD to `archive/r/`. The separately repaired historical R report fixes ventilation/unknown propagation, actual 0/1 factor ICD decoding and parent-specific branch attrition. Its model/scenario definitions remain historical. PDF display repairs hide long code, wrap titles/session output and shorten model headers; HTML keeps inspectable code. Immutable/runnable Stata sources are unchanged.
- Applied figure-and-medical-illustration-qc to three alternatives from one ledger. A is preferred for accurate PIF/CI/N/shift-percentage retrieval; B compares frames within outcomes; C exposes the frame-by-outcome design and paired gas windows. Native SVG/PDF and 300-dpi PNG/JPG exports are 190 x 275 mm with 9.5-point data labels. Detailed missingness/support remains in report tables.

Source assessment:

- Read current upstream main at `787fba64319c0285244e2e17a9e303c739f31a14`; its accepted encounter products supersede the stale local failed-build record. Confirmed original-key publication, compatibility population limits, exact-code raw transport and calendar-date precision. pH pairing/sample-link/elapsed-hour requirements do not apply to this PCO2-only study.
- Bounded local RDS schema/code/gas audit exported no identifiers and fitted no model. Existing source products/receipts were not mounted; the read-only Mini connection failed hostname resolution. The local numeric key encoding and result-derived draw flags still need authenticated downstream mapping. Population coverage, units/windows, BMI/adjustment coverage and ICD absence-versus-unknown require actual existing-source reconciliation. No replacement export or upstream message was requested.
- Detailed receipts remain in `artifacts/triangulation/primary-shift-implementation-20261013/`. The research-data-readiness v1 receipt passes its consistency validator as `not_evaluated`; required private checks are unrun rather than asserted failures of accepted upstream products.

Commands and verification:

- `make triangulation-test`: all 23 shared artificial groups passed using the installed base-R fallback; no dependencies installed. Checks cover exact BMI-30 boundaries/crossing, one-unit removal, independent predictions, full-covariance finite-difference gradients, negative/null/no-change results, unchanged primary coefficients/observed probabilities/indexes/denominators, timing conflicts/fixed indexes, fifteen-cell/pending semantics, hashes, old bundles and rendering tripwires.
- `make historical-test`: original defects reproduced and repaired truth tables/branch accounting passed; all nine unchanged original hashes and the reconstructed-source hash passed. `make stata-test`: nine source/launcher tests passed; no Stata code was changed or clinical Stata execution performed.
- `make triangulation-fixture` generated the artificial fifteen-cell run `fixture-20261014T022835-11646`. Final aggregate-only `make render RUN=...` review is `reviews/review-20261014T032458-15045/`. HTML and ten-page PDF completed; source hashes remained stable, no clinical input opened, no model evaluations during rendering. Every final page is pixel-identical to its inspected predecessor. PDF figure read-back and the display CSV match every saved PIF/CI/model N/shift percentage and all fifteen identities. Twelve final exports have verified dimensions/DPI and retained hashes.
- The pending-module artificial run `fixture-pending-20261013`, reviewed at `review-20261014T031759-14086`, renders nine primary results and six explicit pending rows. Every page of its ten-page PDF and all three figures were inspected. Artificial display-only stress figures separately test negative/cross-zero/wide/tiny/zero/nonestimable/pending/large-count labels; they are not estimation outputs.
- `make render-html RUN=artifacts/triangulation/fixture-20261013T120843-34089` passed using frozen version-1 sources, original labels and no clinical access/refit. Historical artificial full HTML/PDF replay completed in `artifacts/historical-r/20261014T032304-14706/`; all eleven final pages reviewed.
- Browser gallery/report loaded all images, showed no horizontal overflow at 1280 px, and had no errors. All primary candidate SVG/PDF/PNG/JPG formats and grayscale variants were visually reviewed. Formal color-vision simulation was not performed. QC manifest, technical JSON and visual receipt are under the final review `qc/` directory.
- Visual review found and fixed crowded rows/ticks, C axis alignment, large-N wrapping, blank heading-only pages, missing PDF CO2 glyphs and historical code/table/title clipping. Earlier attempts are retained. A readiness-receipt draft failed validation for missing null next-action fields, then passed after correction. A one-off ignore-verification script had a syntax error; corrected rerun passed. No clinical execution failed or was attempted.
- `git diff --check`, current documentation links, original/raw input hashes and generated-file ignore checks passed. All 101 inspected final/evidence artifacts are ignored. No restricted input, clinical result, package installation, upstream mutation, commit, push or submission occurred in this implementation.

Next step: bind and reconcile the existing accepted source and private receipts on its available host, complete the reviewed manifest, then execute the primary clinical analysis. Calendar-day sensitivities may remain explicitly pending if only primary evidence qualifies. Scientific/coauthor interpretation and release review remain separate; the current report numbers are artificial.

## 2026-10-13 22:22 MDT — Correct calendar-day outcome variation and clarify source readiness

- Reproduced the delegated review finding with a new artificial regression before changing the helper: encounter ABG/combined outcomes were constant positive while their calendar-day outcomes varied; the valid sensitivity was rejected as having no variation.
- Changed only the variation guard in `R/bmi_hypercapnia_triangulation.R` to read `outcome_field`. Added `check_outcome_variation_uses_selected_window` in `tests/triangulation_checks.R`, covering both gas outcomes, independent day-specific GLM/standardization parity, event/model counts, unchanged constant-primary rejection and rejection of genuinely constant day outcomes.
- `make triangulation-test`: all 24 artificial groups passed through the existing base-R fallback. No installation or clinical input access. `make triangulation-fixture` completed HTML/PDF and all candidates in `artifacts/triangulation/fixture-20261014T042001-18099/`.
- The fifteen-row default aggregate CSV, shared display ledger and SVG/PNG/JPG exports are byte-identical to the prior fixture/review. All ten fresh PDF report pages are pixel-identical to the previously inspected report. The fix affects the newly reproduced window-specific edge case; it does not change default fixture estimates or the primary model/index specification. Verification is retained in the fresh run's `qc/review-fix-verification.json`.
- Read-only upstream main verification still resolves to `787fba64319c0285244e2e17a9e303c739f31a14`. Rechecked pinned upstream documents and the result-derived legacy draw-flag construction. Updated `docs/TRIANGULATION_SOURCE_ASSESSMENT.md` with resolved/superseded concerns and remaining study-specific input, coverage, gas, BMI/adjustment, ICD and calendar-day evidence gaps.
- No private source reconciliation or clinical estimation ran in this repair. There is no demonstrated need for a replacement export or timestamp acquisition. Only the pending manifest template exists locally. The original readiness receipt retains its identity; ignored `artifacts/triangulation/calendar-day-review-fix-20261013/focused-source-review.json` records the current code identity and unchanged unverified source-binding status without declaring earlier private checks repeated.
- All nine archived original hashes remain unchanged. `git diff --check` passes; generated fix/fixture evidence remains ignored. Changes are uncommitted; no push, external message or submission.

Next action: bind and reconcile the existing accepted source and private receipts for this study, then complete the reviewed version-2 input manifest. Clinical source readiness remains not evaluated; source qualification does not eliminate causal, selection/missingness or linear-model interpretation limits.

## 2026-10-13 — Audit README and save a focused update plan

- Applied readme-builder's repository/research checks to the current local main working tree and read the launcher, Make recipes, manifest/source contracts, primary/historical QMDs and latest artificial receipts.
- Confirmed thirteen README-local links resolve and seventeen distinct documented Make targets exist. Live remote main remains `1e78e3c`; its README still describes the older BMI-to-40 workflow, while current local implementation/README changes remain uncommitted.
- Saved `docs/README_UPDATE_PLAN.md`. The local README is substantively aligned but needs earlier dated status/prerequisites, a minimal artificial start and success/output map, corrected source-gate wording, a concise project map, human-oriented dependency links and portable source-readiness wording. Identified a narrow companion clarification for obsolete canonical/fallback wording in `docs/DATA_MANAGEMENT.md`. Licensing/citation/access metadata remain explicit maintainer decisions rather than invented facts.
- Observed installed R 4.6.1 and Quarto 1.10.18; inspected completed post-fix artificial receipts. No models or existing tests were rerun for this documentation audit. The proposed HTML-only fixture invocation was inspected as supported but remains a smoke check for an implementation turn.
- Plan links/whitespace and `git diff --check` verified; README SHA-256 is unchanged from the start of this audit. Only the plan and this handoff entry were written. No README/code/source/skill edits, installation, clinical input access, commit, push or submission. Next step is the planned scoped documentation update and its bounded validation.

## 2026-10-13 — Execute the README update plan

- Applied readme-builder to the approved scoped documentation revision. Updated README.md, docs/DATA_MANAGEMENT.md and the implementation status in docs/README_UPDATE_PLAN.md; no analysis or source-rule changes.
- README now leads with purpose/current clinical status, places prerequisites before runnable commands, documents the minimal artificial/full versus HTML-only route, actual output files and success receipts, explicit qualified-input and saved-run paths, and a short methods/project map. Historical commands/definitions remain intact; machine-specific access notes are replaced by the dated source assessment. Licence/citation/access gaps remain explicit.
- Corrected data-management historical wording: the unchanged original's fallback is not the current canonical route. Repaired historical rendering uses explicit INPUT; primary estimation/rendering uses explicit INPUT/MANIFEST/RUN.
- Before editing, preserved document copies and R/Python/Quarto/Stata source hashes in ignored artifacts/triangulation/readme-update-20261013/. All captured source/archive hashes remain unchanged after the update.
- Executed the exact documented `Rscript --vanilla scripts/render_triangulation.R fixture html`: success in fixture-20261014T043753-20169, with one artificial estimation, fifteen aggregate cells, completed HTML, all figure formats/PDF gallery and no report PDF. Aggregate results match the previous artificial fixture byte-for-byte. No clinical input read, installation or estimator modification.
- Static checks validate twenty-two local README links, ten data-management links, seventeen Make targets, actual output names and success/status identities. Installed R dependencies are present; R 4.6.1 and Quarto 1.10.18 observed. GFM-to-HTML rendering and `git diff --check` pass. Evidence and smoke outputs remain ignored; no new validation framework introduced.
- Remaining boundaries: clinical input qualification, untested environments, external access/licensing/citation choices and publication of this uncommitted implementation remain separate. No clinical/Stata execution, package installation, commit, push or submission.

## 2026-10-13 23:11 MDT — Verify and prepare the authorized source release

- User authorized committing, pushing and merging the reviewed implementation and README update. Created `codex/primary-bmi-shift` from remote-aligned `1e78e3c`; no open PR existed for this change. Source-only recovery snapshot, patch, Git bundle and test logs are retained in ignored `artifacts/evidence/publish-primary-shift-20261014T050945Z/`.
- Re-ran `make triangulation-test` (all 24 artificial groups passed), `make historical-test` (original defects, corrected behavior and original hashes passed), and `make stata-test` (nine source/launcher tests passed). The Stata test log's deliberately simulated missing-executable/nonzero-run cases are expected test coverage, not clinical execution. No packages installed or clinical data opened.
- Verified all nine archived originals byte-for-byte against the source commit, the unchanged reconstructed R report, and both unchanged Stata sources. Existing post-fix artificial HTML/PDF, figure QC and README smoke evidence remain applicable; no estimation or figure revision was needed for this publication step.
- Staging is restricted to the 44 reviewed source/documentation paths, including historical relocations and source snapshots. Generated artifacts, local manifests and restricted inputs remain ignored. Final staged path/type, archive hash, whitespace and ignore checks precede publication; PR/merge identities and final tree verification are retained in the ignored publication receipt.
- Clinical qualification remains not evaluated. The release does not authenticate the local RDS or its population/field mappings, populate clinical estimates, send an upstream data request, or submit an abstract. Next action is the existing-source binding/reconciliation described in `docs/TRIANGULATION_SOURCE_ASSESSMENT.md` and the version-2 manifest.

## 2026-10-14 — Implement the common-index BMI ≥30 study

Implemented the approved common first-index study locally. Preserved sixteen exact source/document files from merged `d8909df` under `archive/2026-10-14-frame-specific/` before editing. The previous frame-specific fifteen-cell, BMI-to-40, repaired historical R and Stata tracks remain separately runnable with their original definitions and source hashes.

Changes:

- Added `R/common_index_hypercapnia.R` and `R/common_index_reporting.R`. Select the first adult 2022 acute-care BMI ≥30 index before gas/completeness; retain unresolved chronology and incomplete covariates in accounting. Use one complete reference, separate arterial/combined available-evidence outcomes, the unchanged one-unit shift above 30 and inherited linear adjustment.
- Fit eight unique model positions once. Reuse the fitted primary models for the fixed-index BMI ≥40 reference sensitivity, calendar-day projections and prespecified MAR/MNAR scenarios. Matched ICD/ABG and ICD/combined comparisons use identical complete rows within each separate pair; neither requires both specimens. No missing-ICD projection or extra covariates added.
- Persist a version-3, aggregate-only 140-position registry/results bundle, model/observation/covariate/BMI/timing audits, scenario/registry identities and source/input hashes. No IDs, selected encounters, model objects or individual predictions enter the bundle. Require expanded-study population binding in version-3 manifests; old manifests do not autoqualify it.
- Updated primary QMD, launcher/preflight/Make routes, README, project instructions, decisions, plan, handoff, figure brief and source assessment. Added hash-verified `scripts/run_frame_triangulation.py` for frozen version-2 execution and saved version-1/2 review. Historical audit/comparison documents now point to dated current authority without deleting history.
- Applied figure-and-medical-illustration-qc to A (preferred paired absolute/PIF forest-table), B (outcome-first observed/MAR panels) and C (explicit MNAR assumption maps). All use saved aggregates only, direct numerical labels, 190-mm nominal widths, ≥9-point text, grayscale-safe display and SVG/PDF/300-dpi PNG/JPG exports. A/B share four cells; C shows thirty assumption positions, not confidence intervals.

Verification and artifacts:

- `make triangulation-test`: 24 shared artificial groups and 14 new common-index groups passed. Independent GLM/prediction parity, finite-difference gradients/full covariance, BMI boundaries, MAR/MNAR identity, negative/no-change/unsupported cases, fixed indexes/models, matched pairs, pending timing, unseen categories, hash failures and aggregate-only render tripwires passed. Installed testthat is unavailable; shared checks ran via base R and the testthat bridge was parsed/local-environment checked without installation.
- `make historical-test` passed; `make stata-test` passed all nine source/launcher tests (mocked failure cases are intentional). Frozen version-2 artificial checks passed all 24 groups. Old saved version-1 and version-2 HTML review completed without source changes, clinical access or refitting.
- Final artificial run: `artifacts/triangulation/fixture-20261014T191709-47425/`. Final aggregate-only review: `reviews/review-20261014T194108-48834/`; HTML and eight-page PDF completed with zero analysis evaluations and no clinical input opened by rendering. Candidate display ledger equals the saved 140 positions; PDF labels/CI endpoints/Ns and all sixty printed MNAR values reconcile. All twelve exports have checked dimensions/DPI/modes. QC manifest, technical checks, page comparison and human receipt are in this review's `qc/`.
- All eight report pages and candidate formats/grayscale previews were inspected. Closing B/C SVG/raster exports and report pages 1, 2, 4–8 are unchanged from the inspected final layout; re-inspected changed A/page 3. Local gallery/browser showed loaded images and no horizontal overflow. Formal color-vision simulation was not performed.
- Pending-day fixture `fixture-pending-common-20261014T191340-47069`, review `review-20261014T191721-47424`, completed with eight inspected pages; primary estimates match and sixty-eight projection positions remain explicitly source-pending. Separate display-only stress artifacts test large N, wide/cross-zero/negative/tiny/no-change and nonestimable states; these modified values are not fitted results.
- Early PDF equation delimiters, font measurement, crowded ticks/null-line overlap and a test-harness restoration issue were repaired. QC metadata was corrected for actual opaque indexed PNGs and Cairo integer-point PDF sizing. Failed attempts/logs remain in ignored storage; no clinical execution failed or was attempted.
- Static documentation checks validated local links and documented Make targets. Snapshot hashes match their source commits; Stata and older originals are unchanged. Generated output remains ignored; final whitespace/path/privacy checks recorded in `artifacts/triangulation/common-index-implementation-20261014/`.

Source status and next step:

The local RDS hash remains unchanged (exact identity retained in private evidence). Current upstream main was rechecked at `787fba64319c0285244e2e17a9e303c739f31a14`; existing engineering acceptance is reused, not declared failed. No accepted-product/private-receipt binding is locally available for expanded BMI ≥30 coverage. The new readiness assessment validates as **not_evaluated**, with private reconciliation checks unrun and field-specific next actions. No replacement export, timestamp/pH acquisition, upstream message or clinical suitability claim is made.

Next: bind existing accepted products/receipts and authenticate intended population, chronology, BMI/covariates, gas code/unit/window/testing evidence and ICD negative/unknown rules. Then run qualified estimation; optional day evidence may remain pending. This implementation made no clinical fits, installs, commit, push, PR, merge or submission. Changes remain local and uncommitted.

## 2026-10-15 12:09 MDT — Prepare the common-index source-policy release

User approved ordinary unadjusted PCO₂, strict arterial 5–200 and venous 10–250 mm Hg validity intervals, specimen authentication, captured-absence ICD negatives without another-diagnosis requirement, Mini execution and code-first merge. The owner will resume clinical work on the home network; the Mini hostname remains unresolved here.

- Working branch: `codex/qualify-common-index`, based on `d8909df`. The release includes the previously local common-index implementation, its frozen frame-specific archive and the new source-policy preparation work. Starting patch and 109 source-file hashes are in ignored `artifacts/triangulation/source-release-20261015/`.
- Added a pinned source policy, private preparation template/command and typed R writer. They use existing accepted readers and exact-code transport, require original keys and bidirectional captured/legacy scope reconciliation, retain uncertain chronology/completeness, preserve the legacy BMI/adjustment values, and reject unreviewed mappings or incomplete queries. Output is owner-only and inside Git must be ignored. Preparation writes typed input, aggregate population/field evidence, receipt and a deliberately pending clinical manifest. No acceptance gate is set automatically.
- New clinical manifests require `unadjusted_pco2_v1` plus exact hashed JSON policy evidence; new runs record actual commit/tree and require a clean checkout. Adjusted-gas availability/validity/capture audits can be persisted as allowlisted aggregates. Existing saved bundles retain their source-policy labels. Added the home-network handoff and updated README, AGENTS, plan, decisions and source-assessment documents.
- `make triangulation-test`: 24 shared and 14 common-index groups passed. Preparation checks include specimen ambiguity, adjusted values, unit conversion, validity boundaries, ICD capture, original-key/coverage failures, hashes, output privacy and typed R roundtrip. Default Python lacks pandas and skips the orchestration case; all twelve checks passed with existing bundled pandas/R, using explicit synthetic reader stand-ins. That test does not establish an installed upstream/private source read. DuckDB/PyArrow/upstream reader execution is unavailable locally and remains a Mini verification step. No dependency was installed.
- `make historical-test` passed; `make stata-test` passed nine source/launcher cases, including intentional mocked failure outputs. Original Stata and older source archives remain unchanged. The common-loader test initially failed because its artificial JSON writer rounded the fixed unit factor; full-precision fixture serialization repaired it. New clinical validity/policy/hash guards and existing archive checks passed.
- Full artificial fixture `fixture-20261015T180342-95921` completed HTML/PDF. Saved-aggregate-only final review is `reviews/review-20261015T180456-96288/`, with zero model evaluations and no clinical input opened by rendering. All ten aggregate CSVs are byte-identical to the prior reviewed fixture; A/B/C PNGs are pixel-identical. Numerical read-back checks cover all 140 identities, primary CI endpoints/Ns and sixty MNAR display values. All twelve exports passed dimensions/DPI/mode checks; all eight report pages were inspected. Candidate A remains preferred. QC receipts are retained under that review's `qc/`.
- The fresh research-data-readiness receipt validates as `not_evaluated`, preserving unrun private gates. The historical comparator's unchanged hash was reverified without printing identifiers. No private source reconciliation, clinical estimation, human scientific acceptance or abstract submission occurred. Exact release/PR/merge identities and final staged-path/privacy checks will be appended after publication.

Next: finish source review and code publication; at home follow `docs/CLINICAL_RUN_HANDOFF.md` to synchronize the Mini, bind actual accepted products/receipts, prepare/review the input, execute once, then inspect and close out the clinical bundle. Do not replace unknowns or narrow the population to pass a gate.

Release checks: saved version-1/2/3 HTML rerenders passed; 43 local documentation links and 19 README Make targets resolve. Final source review covered staged, unstaged and untracked paths, including specimen vocabulary/setting/system and reverse-coverage guards, private-output handling, hashes and shared reader signatures. All twelve preparation checks passed in the existing pandas/R runtime with synthetic reader stand-ins; the actual upstream/private runtime remains deferred. All 49 staged paths are source/docs/tests; restricted inputs, local configuration and generated outputs remain ignored. Release evidence is owner-only in the existing ignored packet. No clinical findings or source acceptance are asserted.

Publication checkpoint: source commit `2198a44` was pushed and [PR #5](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/pull/5) created/attached. GitHub reports clean mergeability and no configured status checks; local verification above supplies the engineering evidence. This documentation-only checkpoint adds the release link and Mini continuation. The final head/merge/tree reconciliation is retained in the ignored release receipt after squash merge. Clinical qualification remains not evaluated and Mini synchronization remains deferred to the owner's home-network continuation.

## 2026-10-15 18:01 MDT — Mini source qualification and adapter integration fixes

- Restored SSH using the saved Mini account. Transferred the merged `2659ad8` release through a Git bundle because Mini GitHub authentication is unavailable; no credentials were copied. Verified a clean Mini checkout, matching primary source bytes and unchanged original local RDS. An untouched historical QMD differs only in CRLF/LF representation. Preserved the unrelated dirty upstream checkout and exported/hash-verified its four reader modules from the pinned revision.
- Authenticated the existing owner-held trusted acceptance configuration, receipt, FULL_DATA reader and dictionary. Original product keys are strings and unique. The real FULL_DATA layout uses Stata dates/codes and separate race/ethnicity. Added explicit `accepted_stata_full_data_v1` decoding while retaining typed-input compatibility. Actual retained-reference combined categories match at every matched key; BMI/age values and missingness remain unchanged. No default category is substituted for missing raw race/ethnicity.
- Full-history consensus hit internal scratch/RAM limits; accumulating unrelated historical candidates also exceeded bounded external scratch. Failed/interrupted attempts remain private. The focused fix streams all raw rows in disjoint patient-hash partitions, performs unchanged scope selection after consensus, checks coverage in SQL before Python materialization and releases unrelated histories each partition. Reviewed named-unknown setting codes remain uncertain and are written as missing. No index, BMI intervention, covariate, model, outcome or missing-outcome assumption changed.
- A completed bounded fixed-partition check demonstrates potential adult 2022 EMER/IMP keys without approved legacy mappings. The adult birth-year proxy does not establish exact age; neither final BMI eligibility nor a full-population omission count was inferred. This is a failed primary mapping gate, not blanket rejection of existing raw source or a replacement-export request. Added `docs/COMMON_INDEX_SOURCE_GAP_HANDOFF.md` and updated README, saved plan, decisions, source assessment and home-network commands.
- Verification: `make triangulation-test` passed 24 shared and 14 common-index groups. The final preparation suite has 13 local passes plus one upstream SQL case that passes on the Mini against the pinned API; it checks consensus/scope parity, conflicts, unknowns and early coverage failure. Historical R checks and all nine Stata source/launcher cases passed. `git diff --check` and JSON validation pass. Exact source hashes, test evidence and restricted aggregate source receipts are in ignored owner-only continuation storage.
- Mini framework R lacks `haven`, `ggplot2`, `knitr` and `rmarkdown`. Package installation was requested, not performed. No clinical input/acceptance manifest or clinical results bundle was issued, no clinical model ran and no clinical figure/report was rendered. Current full-database hashing and gas/specimen/unit/ICD/window qualification remain unrun after the primary mapping stop. The fresh readiness receipt validates as **blocked**, separately retaining pending scientific review.

Next: review/publish these source fixes and synchronize the clean Mini checkout. Obtain a separately named approved legacy-field mapping from existing captured records, restore an authorized complete R runtime, then finish all primary source gates before one clinical estimation run. Keep scientific/coauthor review and submission separate. Exact PR/merge/synchronization identities will be retained in the ignored publication receipt.

## 2026-10-15 19:20 MDT — Authorized isolated Mini R dependency setup

- The owner authorized installation in an isolated project library. Used the Mini's existing framework R 4.6.1 and compatible CRAN macOS arm64 binaries to install `haven` 2.5.5, `ggplot2` 4.0.3, `knitr` 1.52, `rmarkdown` 2.32 and required dependencies under ignored `artifacts/triangulation/runtime/r-4.6-aarch64/library/`. No renv bootstrap, compiler installation or system-library update was performed.
- Added an ignored Mini-only `artifacts/triangulation/runtime/activate.sh` that selects the framework runtime, isolated library and Quarto R executable for the invoking shell. Installation scripts/logs, binary-index snapshot, package inventory, session information and receipts are retained in the runtime setup directory. All seven required R packages load, with the four requested packages resolved from the isolated library.
- Before/after file hashes match for the inspected framework, Homebrew and user R libraries. Installation exited zero. Against merged source `8735505`, `Rscript --vanilla tests/run_triangulation_tests.R` passed all 24 shared groups and `make common-index-test` passed all 14 common-index groups; both use artificial data only. The Mini's tracked checkout remains unchanged.
- Updated README, clinical/source-gap handoffs, saved implementation plan and source assessment to mark R dependency setup resolved and document activation. Prior dated failure records remain as history. No clinical input was opened, no clinical model ran, and a full Mini report render was not attempted.

Next: complete the separately named broader-candidate legacy-field mapping and remaining source qualification, then use the documented activation before preparation/preflight and the single clinical run. The installation does not satisfy any clinical source or scientific-review gate.

## 2026-10-15 21:33 MDT — Clarify available-BMI cohort and legacy masking rationale

- The owner clarified that BMI must come from the encounter or earlier, with observed height/weight calculation permitted and no statistical BMI imputation. Retained BMI ≥30 study eligibility and the above-30 one-unit shift. Genuine missing BMI after completed mapping is a counted limitation, not a reason to reject the whole source or request a replacement export.
- Read the original Stata BMI block at `5ada7194d40f6006e5563c3592727861336ce2c8` and the accepted Python legacy cleaner at `787fba64319c0285244e2e17a9e303c739f31a14` on the Mini. Stata explicitly attributes its recorded-BMI ≥50.1 exclusion to TriNetX truncation; Python preserves the cutoff and current/prior/calculated hierarchy. Calculated BMI is not capped at 50.1. This was source inspection, not a new patient-level parity comparison. Also distinguished the earlier normalized-vitals BMI range from the raw evidence transport.
- Read the canonical sidecar's metadata fields and source readers without querying clinical rows. TriNetX's indexed de-identification summary describes physical-characteristic tail truncation, but direct PDF retrieval returned 404 and the general description does not authenticate this snapshot's exact masking encoding. No raw-vital distribution audit was run. The proposed ~120 ceiling remains conditional on genuine noncensored measurements; no historical cutoff or source product was changed.
- Inspected common-index selection: `NA` BMI currently becomes uncertain membership and can block a later observed BMI ≥30 index. Recorded the required distinction between completed mapping with true BMI absence and incomplete source evidence/chronology. The former is nonqualification for an available-BMI cohort; the latter can still prevent index resolution. No runtime behavior was silently changed.
- Updated `docs/DECISIONS.md`, the saved implementation plan, source-gap and clinical handoffs, source assessment and README. The plan now specifies current/prior/calculated provenance and timing, missingness reasons, explicit new policy binding, preserved historical outputs, and focused mapping/index verification. Earlier isolated-R setup edits remain intact.
- Verification: documentation diff and local-link/anchor checks; no estimation or analysis test rerun was necessary for this documentation-only clarification. No source/analysis code, clinical input or archived output was edited; no clinical model, commit, push, merge or source acceptance occurred.

Next: implement the broader source mapping and known-missing-versus-unresolved index distinction under the clarified rule, retaining conditional high-BMI handling and the remaining gas/ICD qualification. Complete mapped keys with genuinely absent BMI may proceed as documented missingness.

## 2026-10-15 — Broader source mapping execution checkpoint

- Owner authorized upstream implementation on the Mini, downstream consumption and renewed source qualification. Preserved the unrelated dirty upstream checkout and created `codex/broader-bmi-mapping` from `787fba6` in a separate checkout. Local upstream commits `45eb5ee` and `c588020` add the original-key calendar covariate product, provenance/state fields and hash-bound reader. No historical product or raw input was modified. The downstream branch is `codex/available-bmi-mapping`.
- The independent source-to-product oracle was written before implementation and retained a failing import run. Further fractional/boundary cases exposed missing inherited float16/CSV numeric transport; the corrected mapper preserves that transport, Stata float32 BMI storage and the earlier strict normalized-vital screens. The corrected source-to-product test and Ruff pass. All five existing upstream E2E workflows passed; their retained manifest was independently verified. This is engineering evidence, not clinical source acceptance.
- Read-only private audits authenticated the accepted receipt/sidecar, reviewed actual vital/gas units and demographic vocabulary, inventoried captured domains and checked target diagnosis systems. A full canonical database hash completed in about 15 minutes with stable file identity. Private receipts retain exact queries, hashes, aggregate findings and failed diagnostic queries. No source-value reinterpretation or BMI imputation was introduced.
- The initial diagnostic mapper completed source/candidate/vital staging, then was stopped before qualification to apply the numeric correction. Its partial covariates remain unqualified. Completed raw staging was sealed by source identity, file hashes, row counts, original-key uniqueness and patient partition checks. The corrected producer reuses only that verified staging in a fresh output directory. Private outputs and spill remain external to both repositories.
- Added `scripts/map_common_index_covariates.py` and `make triangulation-map`; the schema-2 preparation route consumes the separate upstream product. Source size requires bounded whole-patient selection before gas extraction. `scripts/select_common_index_mapping.R` uses the same R selection helper and retains aggregate source scope/index counts; the estimation input contains resolved indexes plus bound census evidence. This is an execution change, not later-index substitution or gas-based selection.
- New `bmi_evidence_state` values distinguish valid, completed-missing and unresolved evidence. New runs persist `available_encounter_or_prior_bmi_v1`; older version-3 bundles preserve their original policy. Tests verify later valid indexes after confirmed BMI absence, continued blocking by unresolved evidence, bundle identity and batched selection parity. The 24 shared and 17 common-index artificial groups pass locally. All 15 preparation cases pass in the Mini's existing Python/framework-R environment.
- Qualification remains in progress. No clinical model, abstract result, figure update, source acceptance or human scientific approval is asserted at this checkpoint. The remaining work is corrected-product reconciliation, typed preparation, independent gas/ICD/timing checks and source preflight. Exact runtime commands and artifacts remain in the private qualification packet; final status will be appended after those checks.

## 2026-10-16 07:02 UTC — Broader mapping and actual source qualification completed

- Completed the separately named upstream mapping on the Mini at local commit `72c91a2` (`codex/broader-bmi-mapping`), preserving the unrelated dirty upstream checkout, accepted historical products and original RDS. A verified Git bundle of the three implementation commits is retained in ignored local evidence. The consumer branch is `codex/available-bmi-mapping` on both hosts; its new changes are not yet committed/published/merged.
- The historical overlap audit exposed an intermediate float32-before-rounding defect in the new draft mapper, not a defect in the accepted Stata/Python producer. A failing fractional case and the corrected E2E are retained. Final mapping preserves float16/CSV transport, float32 source/intermediate storage, Stata rounding and final float32 BMI. Identical selected components reproduce historical BMI; demographic codes agree, and age/date differences are explained by the declared encounter-start versus historical qualifying-event anchor. Earlier mapping/preparation attempts remain explicitly diagnostic and unqualified.
- Fresh preparation from the corrected product completed. Independent original-key/index/census, BMI-state/arithmetic/timing, prepared-field, ordinary gas/testing, ICD and calendar-day checks have zero disagreements. The native raw-source qualifier and its exact source snapshot are retained; the prepared-field extension was checked separately without repeating unchanged raw scans. All nineteen CSV/RDS fields agree exactly. No clinical model was fitted.
- Issued a separately named automated-reviewed version-3 manifest after the actual source comparisons. The original pending manifest is unchanged. The source-freeze readiness determination is `ready_with_limitations` for the existing conservative definitions; automated and human review states remain distinct. The first receipt had empty optional-action strings rejected by the structure validator; a separate corrected receipt uses nulls and passes `--require-ready`. No source result changed during that metadata repair.
- Mini `make triangulation-preflight INPUT=... MANIFEST=...` completed in `artifacts/triangulation/preflight-20261016T065817-5083/` with `reviewed_primary_input_identity_and_mapping_passed`, zero models and a qualified calendar-day module. Its generated directory was made owner-only. Exact restricted paths, hashes, counts, source inventories, timing distributions and acceptance evidence remain in the existing external private packet.
- Actual source limitations remain visible: unknown earlier settings and same-day earliest encounters cause substantial unresolved-index attrition; some prior BMI/weight evidence is old, while current-encounter measurements can occur after admission. Recorded these choices and proposed a prespecified recency sensitivity without changing the approved primary rule. No recorded BMI above 50.1 was found; the conditional high-BMI ceiling was not activated. Missing BMI remains missing without statistical imputation.
- Verification: 24 shared and 17 common-index artificial groups pass, including fitted-result/denominator parity after bounded preparation. All 15 preparation cases and 3 qualification cases pass in the Mini's existing environment; tests detect wrong indexes/values/testing/ICD, invalid prior dates and configuration rebinding. Historical R and all nine Stata source/launcher checks pass. The new upstream source-to-product E2E, Ruff and all five existing retained E2E workflows pass; the final E2E evidence was independently verified.
- An older version-3 saved artificial bundle rerenders as HTML with zero analysis evaluations and no clinical input read. Its original BMI/missingness wording remains intact. Source archives retain their verified hashes. Updated README, project instructions, plan/decision/source handoffs, report provenance wording and private-config ignore rule; final link/privacy/diff/source-sync checks follow below.

Next: resolve or explicitly retain the documented scientific choices, review/publish both implementation branches, synchronize clean merged code and rerun identity preflight before the first clinical fit. Source changes require a fresh dependent qualification; presentation changes consume saved aggregates. Clinical results, clinical exhibits, numerical/coauthor scientific review and abstract submission remain unrun. No clinical source artifact is committed or released.

Final verification: 57 local documentation links/anchors resolve; all 26 changed public files match between the local and Mini consumer checkouts. Generated evidence and the new local mapping configuration are ignored. No historical R/Stata source path changed, and the original RDS digest matches the earlier final-verification snapshot. The upstream documentation closeout is `45d3fc0`; its producer code remains the qualified `72c91a2` bytes. Both Git bundles are retained, with the final bundle independently verified. No push/PR/merge or clinical estimation occurred in this implementation phase.

## 2026-10-16 — original selected encounter-list correction (in progress)

Owner confirmed that original selected encounter membership governs the study;
the broader raw-source universe and resulting outside-list UNKNOWN attrition are
superseded. Reserved a private Mini writer lease and starting source hashes.
Observed a separate GLP-1 qualification process using its own private directory;
kept that process and shared upstream code/source read-only. Guarded synchronization
rejects unexpected target-file edits; use one worker and separate fresh outputs.

Added `scripts/original_encounter_population.py`, original-membership regression
checks, mapping/preparation guards and independent qualification checks. The new
mapping authenticates FULL_DATA, verifies original first flags, stages all raw
records only at original acute keys, and preserves the agreed current/prior/
calculated BMI policy. Original flags are not a prefilter before BMI eligibility.
New manifests bind `original_selected_encounters_v1`; superseded broader mappings
cannot acquire that label. Old saved bundles retain their specifications.

Four artificial original-membership checks passed after the red import check;
additional independent wrong-key and population-persistence checks are added.
The first private original-list mapping is running; completion, qualification,
preflight and remaining issues will be recorded below. No clinical model started.

Original-list mapping completed with native exit zero. Original first flags
reproduce under frozen ordering, every original acute key has captured setting
support, and the completed vital cache covers every original candidate patient.
All shared-key BMI/covariate/date/state comparisons against the earlier mapping
have zero differences; cohort membership alone is narrowed. Within-list raw date
and setting conflicts remain in the private audit. Fixed-index selection is
complete; gas extraction is running and independent qualification is queued
strictly after successful preparation.

Verification now passes: 24 shared and 18 common-index groups (also on Mini),
15 preparation cases, 5 original-membership cases, 3 qualification cases,
historical R and 9 Stata source/launcher cases. The initial common-manifest
fixture failed because it lacked the newly required original population binding;
updated the artificial fixture and added a rejection for its removal. Old saved
bundles still render with their recorded labels; a new artificial scoped bundle
renders with original-cohort Methods/captions. Quarto initially lacked access to
its existing cache under the sandbox; the authorized rerender succeeded. All
three changed artificial captions/exports were inspected with figure QC, with
no clipping or symbol/readability issue observed. This is not clinical evidence.

Preparation completed naturally with exit zero. All nineteen CSV/RDS fields
agree exactly, including original string keys, dates and float precision. The
independent qualifier passed its first twenty-one membership/index/field/BMI/
original-flag/raw-start checks without discrepancies, then advanced to raw gas,
testing, ICD and calendar-day checks. Source-setting uncertainty causes no
index blocks in this corrected universe. Historical/new first-index differences
are fully accounted for by ambulatory membership, BMI below threshold, completed
BMI absence or qualifying-date versus start-date ordering; no unexplained case.
The exact counts and reconciliation are private. No clinical model was fitted.

Corrected original-scope qualification completed with native exit zero: all thirty
independent source checks have zero disagreements. Issued a fresh automated source
review and version-3 reviewed manifest after checking exact input/config/mapping/
preparation/selection/code hashes and the typed roundtrip. The readiness receipt
validates as `ready_with_limitations` for the approved selected-cohort source use;
human source/scientific approval is explicitly not invented. Mini identity-bound
preflight `artifacts/triangulation/preflight-20261016T173924-11359/` reports
`reviewed_primary_input_identity_and_mapping_passed`, zero models. The original
pending manifest, older broader products and their receipts remain unchanged.

Plan, decisions, source assessment, README, project instructions and handoffs now
identify original selected membership as authoritative. No new source-export or
membership choice is required under current rules. Within-list chronology/BMI
uncertainty and earliest-date ties remain explicit; a recency cap, old-first-flag
prefilter or alternate tie/date rule would be a new scientific decision. Final
cross-host synchronization, source/ignore checks and writer-lease closeout follow.
No clinical estimates, commit, push or merge were performed in this phase.

Final closeout: all 98 local documentation link targets resolve; Python sources
compile and `git diff --check` passes. The corrected source review and preflight
bind the same exact input, and the recorded executable source hashes still match.
The shared upstream worktree is clean at its unchanged documentation-closeout
revision. All public changes are synchronized between this checkout and the Mini
under per-file guards with no unexpected target edits. Generated reviews and
configuration are ignored; clinical products remain external/private. The study's
writer lease is closed only after all native jobs report success. Clinical models,
human scientific review and code release remain unrun/uncommitted as applicable.

## 2026-10-16 12:10 MDT — BMI availability cross-analysis audit

Investigated whether the selected patient count incorrectly implied low BMI
availability. Performed read-only, aggregate-only Mini comparisons of original
acute keys, the new mapping, accepted FULL_DATA/AFTER_EXCLUSION products and
retained historical Stata comparators. Inspected bicarbonate, hypercapnia
case-definition and equity source filters; did not execute those studies' models.
Reconciled available BMI, BMI≥30 eligibility, distinct patients, first-index
uncertainty, prior/calculated contributions and historical BMI/date differences.
The historical comparator matches accepted AFTER_EXCLUSION keys and BMI exactly;
this does not authenticate every field or the publication/current Air snapshot.

The ignored review and aggregate receipts are under
`artifacts/triangulation/bmi-coverage-review-20261016/`. Arithmetic, same-key
comparisons and source-identity checks pass. An initial audit query used an
unsupported DuckDB prepared CREATE VIEW and was corrected to quote the fixed
paths. An equity audit initially mislabeled the temporary first-only descriptive
subset; the retained version-2 receipt respects preserve/restore and supersedes
those labels. Detailed receipts remain private. No source data, scientific rules,
analysis code, clinical estimates or other-repository files changed. Ambiguous
reported BMI with usable height/weight remains an explicit potential policy
choice; no alternative fallback or index rerun was adopted.

## 2026-10-16 — Curve-first scientific report and complete audit refactor

Implemented the ticket anchored to 8735505, preserving the pending original-list
source corrections. Confirmed original selected encounter scope and known-capture
ICD reference. Replaced default historical/PIF-grid dispatch with separate source
preparation/preflight, cohort audit, analysis and aggregate-only rendering.

New modules cover input validation/selection, membership ledger and variable
atlas, 21 planned spline/linear/observation/matched fits with complete audits,
paired curves/scenarios and full contribution covariance, and version-4 bundles.
Scientific/audit Quarto reports, F0–F5 and three F1 alternatives are generated.
Superseded authority snapshots and the original ticket are retained with hashes.

Commands so far: repeated artificial numerical/adverse acceptance runs; Python
preparation/original-population/source-qualification tests locally and in an
isolated Mini snapshot; `make fixture`; saved-run `make render`. Initial numerical
checks pass; render/visual acceptance remains explicitly pending until actual
inspection. The source adapter suite passes on the Mini including the added
Float32-to-CSV preservation case. Optional testthat is absent locally; the same
checks run through the standalone runner without installation.

Safe repair loops retained failed/superseded views: PDF absolute image paths,
long panel labels, long unbroken identifiers and TeX captions were repaired.
Pending timing memberships are unassessed instead of zero. Identical atlas plots
share an indexed representative; complete stage tables remain. Covariances print
as complete matrices. Presentation changes rerender the saved final artificial
bundle without refitting. Every standalone fixture figure is marked artificial.

Mini work used fresh external private code/scratch, after checking active jobs;
the existing working checkout and accepted products were not edited. Existing
original-list source checks, independent selected-field comparisons, the new
cohort companion, its ledger and fresh preflight pass with zero clinical models.
All 12 current qualification-function hashes match the tested Mini functions.
Private receipts: `artifacts/triangulation/curve-refactor-source-review/`.

No commit, push, merge, upstream write, package installation or submission was
performed. Next: finish actual HTML/PDF/native-size/grayscale inspection, rerun
all 65 acceptance checks against that completed review, and record final receipts.
Clinical fitting still requires the reviewed clean merged Mini checkout.

### 2026-10-16 15:22 MDT — Final curve/audit verification and handoff

Software implementation and artificial verification complete. Final source/cohort
helper move binds source acceptance, companion selection and reconciliation to the
estimation hashes. An unchanged tree renders; plot-only revisions remain compatible;
cohort-source and aggregate tampering fail. Eight scientific/cohort aggregate tables
remain exactly equal across the module move. The final Mini comparison includes
13 qualification-function identities and all estimation-file hashes, superseding
the intermediate 12-function note above.

Commands completed:

- `make fixture` saved `artifacts/triangulation/curve-fixture-20261016T144730-79118`.
- `make render RUN="artifacts/triangulation/curve-fixture-20261016T144730-79118"`
  completed both complete HTML/PDF reports. Presentation-only repairs reused the
  same saved run, never clinical input or model fitting.
- `Rscript --vanilla artifacts/triangulation/curve-refactor-baseline/final-scientific-glyph-render.R`
  repaired one scientific PDF subscript label in a fresh review, reusing the
  unchanged audit/figures with output/source hashes checked.
- `make test BMI_TEST_REVIEW="artifacts/triangulation/curve-fixture-20261016T144730-79118/reviews/20261016T151707-glyph-81498"`
  passed all 65 R acceptance checks. The expected absent-manifest negative test
  emits a missing-file warning. Local Python checks pass with 12 optional cases
  skipped; the Mini runs all 16 preparation, five original-population and three
  source-qualification cases without skips (24 pass).
- Figure skill `figure_manifest_lint.py`, `table_manifest_lint.py` and
  `inspect_image_files.py` return zero against the curated final manifests.
  Poppler page raster/bounds checks and actual browser/visual inspection complete.
- `git diff --check`, R parse checks, Python compile checks, current authority
  file-link checks and all six archive hash checks pass. Historical Stata/raw
  tracked paths have no diff. Generated/private evidence remains ignored.

Final review is
`artifacts/triangulation/curve-fixture-20261016T144730-79118/reviews/20261016T151707-glyph-81498/`.
It includes scientific and exhaustive audit HTML/PDF, `figures/gallery.html`,
F0–F5, F1-A/B/C, SVG/PDF masters, 300-dpi PNG reviews, primary JPG alternatives,
complete captions, manifests and `visual-review-receipt.json`. Aggregate ledger,
complete coefficient/covariance/correlation and reconciliation CSV/RDS tables are
at the run root. The scientific PDF has nine pages; the complete audit has 1,094.

Actual review: all 230 scientific PNGs at approximately 190 mm/100 dpi in grayscale;
79 revised plots rechecked in 20 sheets; final PNGs identical to inspected outputs.
Every report page received layout overview and automated text geometry checks
(zero bounds/collision flags), with representative audit tables inspected at native
raster size. This does not claim manual reading of every cell. Full row and
covariance coverage is tested. All 1,372 audit HTML tables and 229 images are
present, with no broken images/overflowing cells. Scientific HTML has all three
images and no overflow. F1-A is preferred for aligned cross-outcome comparison;
B/C remain available. Some long captions continue on the next PDF page and the
full audit has a slow cold browser load; these are nonblocking presentation limits.

Repair history is retained: long labels, image paths, table widths/continuation
headers, booktabs intercept parsing, LaTeX header leakage, excessive decimal
columns, and one unavailable subscript glyph. Curated manifests and actual
inspection supersede broad prototype heuristics that mislabeled duplicate
PNG/PDF assets and numbered figure variants. Failed/superseded reviews are not
deleted. Final receipts distinguish successful software verification from clinical
qualification or investigator review.

Mini source work used an isolated external private snapshot after active-job
checks. Clinical data were opened for source/companion and model-free preflight
only. Automated original-list source/field/ledger qualification passes. Zero
clinical models fitted; no human approval, MAR validity or causal interpretation
is asserted. Private source receipts remain under
`artifacts/triangulation/curve-refactor-source-review/`.

Changes remain uncommitted. No push/merge, other-repository modification, package
installation, clinical submission or publication occurred. Next: review/merge the
implementation, synchronize a clean matching Mini checkout, then execute one
clinical run, reconcile its numerical outputs and repeat figure/report QC before
investigator scientific review. No observed discrepancy requires a new scientific
choice or replacement source export.

## 2026-10-16 — Authorized release and clinical execution

The investigator authorized review/repair, release, clean Mini synchronization,
source acceptance and clinical estimation in the current conversation. Source
acceptance is based on the existing identity-bound original-list/companion
checks; clinical-results scientific review remains subsequent. Existing work was
preserved in ignored `artifacts/triangulation/clinical-release-20261016/` before
any release edits.

Read-only review covered current cohort/source binding, model registration and
failure handling, prediction/decomposition, aggregate persistence, launchers,
preparation/qualification changes and the pending file inventory. No substantive
scientific defect was identified. Obsolete handoff Make target names were corrected.
Added aggregate-only phase/model messages to make the long run observable; all
eight coefficient/covariance/curve/contribution/cohort tables remain exactly
unchanged on the full artificial fixture after that addition. No covariate,
index, outcome, estimator or scenario rule changed. No CI workflow is configured;
local and Mini receipts will supply the release's actual check evidence.

Mini inspection found no active competing R/source-analysis job. Its original
consumer checkout remains dirty and will be preserved; its upstream checkout has
separate work and remains read-only. The internal disk is nearly full, so the
candidate smoke and clinical run use a separate clean external-drive checkout
and external temporary storage. Existing Quarto and XeLaTeX are installed but
were absent from the noninteractive SSH PATH. No installation is needed so far.

Next checkpoint: commit the reviewed candidate, run fresh artificial end-to-end
and adapter checks on the Mini, then push/PR/merge and synchronize the exact
merged revision before clinical preflight or estimation.

## 2026-10-16 22:20 UTC — Clinical estimation completed from merged release

PR #7 merged as `f18d383b2b6858f6e39307bda4fd84e0c5631850`; its tree
`4b12e22c978266aab2ad2e398d0fe6977e398cf1` exactly matches tested candidate
`ee00e20`. The clean external-drive Mini worktree matched origin/main for the
clinical launch. The original consumer checkout's tracked diff and untracked
inventory remain unchanged; upstream work and accepted products were not edited.
No package or system-library installation occurred during this release.

Fresh Mini `make fixture` completed scientific/audit HTML and PDF. All 65
artificial acceptance checks and all 24 source-adapter tests passed without skips.
The 230 artificial figure pixels match the previously inspected local exports;
eight scientific/cohort tables agree at tolerance 1e-10. The Mini's artificial
audit has 1,239 pages; different local TeX/Quarto pagination is documented. The
first environment smoke failed because R rejects spaces in TMPDIR; a private
space-free symlink to external-drive scratch resolved it without changing code.

The owner explicitly accepted the checked original-list source and pre-index
companion and authorized clinical execution. A fresh private reviewed manifest
preserves the earlier automated manifest and all source products. Twelve
input/evidence hashes also match after execution. Source acceptance is separate
from assumptions about observation, causal interpretation or future investigator
review of the results.

Actual commands were `make preflight INPUT=... MANIFEST=...`, followed by one
`make analyze INPUT=... MANIFEST=...`, and `make render RUN=...`. Exact protected
paths, runtime activation, commands, natural completion markers and logs are in
ignored `artifacts/triangulation/clinical-release-20261016/`. Preflight run:
`curve-preflight-20261016T155811-16922`. Clinical run:
`curve-analyze-20261016T160703-17017`. Estimation took 528.71 seconds. All 21
registered positions are retained: 20 fits succeeded, while ICD capture
availability is constant and is explicitly not fitted. No replacement estimator
or scientific-rule change was used.

The clinical bundle passes 48 additional aggregate numerical checks, including
model/event/denominator accounting, coefficient/covariance coverage, paired
probabilities/PIF, signed contribution and full-covariance reconciliation,
fixed-index timing and MAR/MNAR anchors. Both HTML/PDF formats reproduce all
coefficient, category and variable-profile rows and complete covariance cells.
Rendering records zero clinical input reads and zero model refits; the saved
bundle and estimator sources remain unchanged.

Clinical review `reviews/20261016T160718-17170/` contains both HTML/PDF reports,
40 aggregate tables, 153 scientific/audit figure exports, the three F1
alternatives, SVG/PDF masters, 300-dpi PNG/JPG and gallery/captions. Figure QC
inspected all 153 grayscale exports in native-review-width sheets and F1/F2/main
flow individually. Every PDF master passed native text bounds/size checks. All
nine scientific and 1,224 audit pages received layout-overview inspection;
all-page native text bounds and replacement-character checks pass. Representative
complete source/profile/coefficient/covariance tables were inspected at native
raster size. This does not assert manual reading of every table cell. Static
HTML inventory finds 1,446 audit tables and 152 embedded audit images; no image
resource is missing. Clinical browser interaction was not repeated.

F1-A remains preferred. Nonblocking presentation follow-ups are the large/slow
complete audit, long captions continuing on the next PDF page, and connecting
arcs crossing some detailed-flow label boxes; the main flow and complete edge
table remain clear. Actual receipts distinguish source accepted, estimation
complete, automated numerical reconciliation passed, export QC complete, and
investigator numerical/scientific interpretation pending. Frozen run-manifest
review flags describe their initial execution-time state; the separate review
receipt records subsequent checks without modifying the bundle.

Updated README, implementation plan, decision log, source assessment and clinical
handoff to remove the active pre-run status. Clinical effect estimates and exact
aggregates remain private and ignored by Git. Next: investigator/coauthor review
of interpretation, sparse upper-BMI support, apparent fit and gas-observation
MAR/MNAR assumptions (including sign-changing sensitivity scenarios) before
abstract claims. No new source export or operational decision is required by the
observed checks. No abstract was submitted or clinical result published.

## 2026-10-16 — Observed-population scientific/audit refresh (in progress)

User approved an expanded mini-paper, full audit, observed-data timing/matched/
functional-form checks, and review/commit/push/merge followed by a fresh clinical
run on the Mini. Full-cohort gas MAR/MNAR projections are superseded; IPW is deferred.

Pre-edit assessment confirmed crossed detailed-flow connectors, detached figure
captions, repeated frequency panels and fragmented result tables. The previous
clinical audit has 1,224 pages. Its original artifacts and QC receipt are preserved;
those earlier presentation limitations are not treated as acceptable for this release.

Branch: `codex/observed-bmi-paper-audit`, based on `1626a6d`. Baseline artificial
A–E checks passed; the refreshed 900-patient fixture reproduces all baseline model
coefficients and covariance entries exactly. The new bundle is version 5 and
binds outcome-observed standardization. Rendering remains aggregate-only.

Mini check: reachable; a separate GLP-1 preparation process is active in its own
external workspace. No writes to that workspace or accepted products are planned.
Clinical execution will use a separate clean merged checkout and a fresh run.
Existing installed R/Quarto dependencies are available locally; no installation.

Verification in progress: expanded acceptance checks, full artificial HTML/PDF
renders, complete table coverage/alias reconstruction, native figure and PDF
inspection, release review, then clinical source/hash verification and rerun.

The final 1,200-patient fixture estimated and passed 86 aggregate numerical checks.
Native/overview inspection found long basis hashes overlapping scientific table
columns; the initial render was stopped and retained as a failed presentation
attempt. Optional LaTeX token breaks repair this without truncating identifiers.
A new render reads the same saved bundle. All 24 adapter tests passed on the Mini
using its existing activated R/Python runtime; the first invocation lacked Rscript
on SSH PATH and was corrected without installing anything.

The complete artificial audit rendered to 769 pages. A new text-box collision
scan exposed punctuation-delimited model IDs crossing cells, a candidate-C title
outside the figure boundary and dense residual-count ticks. Repairs add optional
breaks at identifier separators, wrap titles and use two residual-count ticks;
no values, scales or complete table rows are removed.

The focused audit proof cleared every table out-of-bounds/symbol/text-collision
finding. The only remaining flags were the unchanged old F4 plots in that proof;
the source repair now uses two count ticks. The final release render regenerates
all figures/reports from the unchanged 1,200-patient aggregate bundle.

Release verification completed: all 73 artificial acceptance checks passed against
review `20261016T223223-29309`; all 86 aggregate numerical checks passed; all 24
source-adapter tests passed on the Mini. Both HTML/PDF reports render from saved
aggregates (32 scientific and 815 audit pages, 303 figure sets). Automated bounds,
replacement-symbol and text-collision scans found no issues. Visual review covers
all figure/page overviews plus native main/dense examples; all changed final audit
pages were rechecked against the fully scanned proof. It is not an independent
manual verification of every numerical cell. F1-A remains preferred; alternatives
are retained. Private receipts and earlier failure logs remain ignored.

Read-only candidate review covered staged/unstaged/new source files relative to
1626a6d; no further actionable defect remained. Clinical refresh is still pending
merge and the clean matching Mini checkout. Accepted input/manifest hashes were
reverified unchanged; no competing analysis was active. The Mini cannot authenticate
to GitHub directly, so the merged revision will be transferred as a Git bundle.


### Observed-population clinical refresh completed — 2026-10-16

Implementation PR #9 squash-merged as ca24564b9963266d6ff54652d0680a4056a51869
(tree 394dec1fb18a5b4fd39d423dc508408f33a041e5). No GitHub checks were configured;
recorded local/Mini tests preceded merge. The Mini could not authenticate directly
to GitHub, so a Git bundle supplied the merged commit to a new clean isolated
checkout at `/Volumes/RESEARCH FAST/bmi-observed-paper-release-20261016/checkout`.
HEAD and origin/main matched; unrelated dirty research checkouts were untouched.

Using the unchanged qualified input and clinical-reviewed manifest, `make preflight`
completed as `curve-preflight-20261016T224526-24328`, then `make analyze` completed
once as `curve-analyze-20261016T225112-24371`. All 21 model positions remain explicit;
20 fitted and one constant ICD capture-availability position is unestimable.
`Rscript scripts/review_bmi_run.R NEW_RUN OLD_RUN` passed 103 automated numerical
checks. Eleven bound evidence file hashes, the input hash and manifest hash remain
unchanged. The existing owner source acceptance was reused; no new human review
was invented. The execution lease is marked completed.

Aggregate-only copies are under ignored
`artifacts/triangulation/clinical-observed-release-20261016/`. `make render RUN=...`
created review `20261016T225140-32053` locally, without clinical input reads or
refitting. Both HTML/PDF reports completed: 32 scientific and 808 audit pages,
215 figure sets. `scripts/check_report_exports.py` found no out-of-bounds text,
replacement symbols, text collisions or export-format defects. All page/figure
overviews were visually scanned; main figures and dense report examples were
inspected at full size. Complete machine-readable table coverage remains checked.
The exact scope and hashes are in `visual-review-receipt.json`, `QC_REVIEW.md` and
the figure QC manifest. Dense audit numeric columns remain closely spaced, with
full CSVs available for exact retrieval. F1-A remains preferred; B/C are retained.

Source accepted, execution complete, automated numerical review passed and scoped
visual review complete are distinct states. Investigator numerical/scientific
review and abstract submission remain pending. Historical products are unchanged;
all clinical artifacts, numerical results and review images remain ignored.

All 73 acceptance checks passed again with the actual clinical report review for
render/coverage assertions; model tests still use artificial data. The private
`clinical-release-review-receipt.json` binds code, input, manifest, companion,
bundle, numerical and visual evidence. The final documentation update changes no
analysis/render source and requires no refit.
