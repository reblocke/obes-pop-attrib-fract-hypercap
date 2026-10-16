# BMI and hypercapnia: common-index evidence comparisons

This R/Quarto workflow estimates **model-standardized probability differences and potential impact fractions** under a one-unit BMI reduction among patients with observed BMI >30. BMI =30 stays unchanged; there is no floor. It is intended for clinical collaborators running or reviewing the analysis.

The primary population is adults within the original selected encounter list, with a first qualifying **BMI ≥30** ED/inpatient encounter in 2022, selected before gas availability. Separate arterial and combined-gas models supply observed-evidence benchmarks and assumption-dependent projections to one common covariate-complete reference. A BMI ≥40 sensitivity restricts those same index encounters and reuses the primary models. The previous independently indexed frame analysis is preserved as supporting work.

**Status (2026-10-16):** the owner confirmed that candidate encounters must come from the authenticated **original FULL_DATA selected encounter list**. The broader-history mapping and its qualification are superseded for this use. The correction and fresh independent source qualification pass on the Mini: all original first flags reproduce, exact original-key coverage passes, and all 30 source checks have zero disagreements. Clinical models remain unrun. BMI uses current/prior measurements or observed height/weight calculation, without statistical imputation. See the [decision](docs/DECISIONS.md#original-encounter-list-correction--confirmed-2026-10-16) and [plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md#original-encounter-list-correction--2026-10-16).

The [BMI policy](docs/DECISIONS.md#bmi-availability-and-missingness--clarified-2026-10-15) uses valid BMI from the encounter or earlier, preferring recorded values before calculation from observed height/weight. No statistical BMI imputation is performed. Completed-missing BMI is counted and does not qualify that encounter; unresolved source evidence remains distinct. New inputs/bundles bind `available_encounter_or_prior_bmi_v1`; existing saved runs keep their original policy.

## Prerequisites

Run commands from the repository root with Make, R ≥4.3 and Quarto. Installations are not automatic. Required installed R packages: `lpSolve`, `jsonlite`, `digest`, `haven`, `ggplot2`, `knitr`, `rmarkdown`. The previous shared checks support testthat or base R; the new artificial runner uses base R. Python 3 supports frozen-frame and Stata launchers.

PDF reports require XeLaTeX and Arial. Automatic LaTeX package installation is disabled in the new QMD. HTML-only execution skips LaTeX report compilation but still exports R-generated PDF figure masters/gallery. There is no committed renv lockfile; versions are recorded per run. Environment bootstrapping remains separately approved.

Clinical preparation additionally requires the existing Python environment containing pandas, PyArrow, DuckDB and pinned upstream modules. The [original-list mapping template](config/common_index_mapping.example.json) binds five module hashes at upstream `72c91a21d4ff65aadca970cf60a168971a8c4a6e` (local upstream implementation branch). Use that reviewed checkout on `PYTHONPATH` or its matching installed package. A stale import is rejected. The [historical preparation template](config/common_index_preparation.example.json) retains its original four-module pin. No dependency installation is attempted.

## Start with artificial data

```bash
make triangulation-test
make triangulation-fixture
# HTML report only, with all figure formats:
Rscript --vanilla scripts/render_triangulation.R fixture html
```

These commands never open clinical input. Estimation runs once and produces a fresh ignored directory under `artifacts/triangulation/`. The launcher prints that directory and its completion status. Open `rendered/bmi_hypercapnia_triangulation.html` and `figure-gallery.html` inside it; the full fixture also creates a report PDF. Every artificial report/exhibit is labeled.

| Saved output | Purpose |
| --- | --- |
| `aggregate_bundle.rds`, `aggregate_results.csv`, `specification_registry.csv`, `bundle_manifest.json` | Full-precision version-3 design, outcomes, references, methods, scenario parameters and identities |
| `population_counts.csv`, `scope_counts.csv`, `model_diagnostics.csv` | Selection/completeness, model versus reference denominators and model failures |
| `observation_patterns.csv`, `observation_by_bmi.csv`, `covariate_coverage.csv` | Usable specimen patterns, availability/positivity by BMI and inherited covariates |
| `model_shape_by_bmi.csv`, `timing_audit.csv` | Descriptive model-shape and fixed-index timing diagnostics |
| `analysis_status.json`, `analysis_receipt.json`, `input_receipt.json`, `session_info.txt` | Completion, one-estimation receipt, source declarations and environment |
| `rendered/`, `figures/`, `figure-gallery.html`, `figure-gallery.pdf` | Reports, editable-source-linked SVG/PDF/PNG/JPG candidates and galleries |
| `render_status.json`, `quarto-render.log` | Completion/failure, expected outputs, no-refit/no-clinical-read and source-stability records |

Success means zero exit status, `analysis_completed`, then `render_completed` with expected outputs and unchanged sources. Source-pending/nonestimable positions remain visible; they are not zero estimates. Matching hashes and artificial success do not establish clinical acceptance. Fresh failure receipts are retained.

## Methods and interpretation

The unchanged inherited model uses linear BMI and age plus sex, race/ethnicity and geographic region. Index selection precedes completeness. Missing covariates stay in cohort accounting; the common projection reference has complete inherited adjustment values. No imputation or added clinical predictors is used.

| Criterion | Usable evidence | Primary window |
| --- | --- | --- |
| Arterial | PaCO₂ ≥45 mm Hg | Selected encounter maximum |
| Combined | PaCO₂ ≥45 or PvCO₂ ≥50 mm Hg | Available arterial or venous maxima |

No usable gas remains unknown. An available combined negative does not prove that an unmeasured specimen is normal. Fixed-index calendar-day sensitivities use the same thresholds and collection date equal to encounter-start date, not elapsed 24 hours or a standardized measurement schedule.

New clinical runs require [unadjusted_pco2_v1](config/common_index_source_policy.json): ordinary values, authenticated specimen, strict 5–200 mm Hg arterial and 10–250 mm Hg venous validity intervals, and explicit reviewed units. Unspecified-blood codes require specimen evidence. Temperature-adjusted measurements remain outside primary outcomes and appear in source-preparation availability audits. Outcome thresholds ≥45/≥50 remain inclusive. Historical bundles retain their recorded policy.

Observed benchmarks average over measured cases. MAR projects each gas outcome model to the same full reference under conditional MAR. MNAR scenarios vary missing/observed odds at BMI 40 (0.25/0.5/1/2/4) and the relative odds gradient per five BMI units (0.5/1/2). These are exploratory assumptions, not estimates or clinically validated bounds. Observation status remains fixed when BMI changes; the r=g=1 scenario reproduces MAR.

Report paired probabilities, absolute difference per 1,000 and PIF `1 - p_shifted/p_observed`, with pointwise full-covariance delta intervals conditional on the empirical reference and fixed assumptions. Model N and reference N differ. Retain negative contrasts, small nonzero values and support diagnostics. These do not establish physiologic prevalence, incidence reduction, within-person weight-loss effects or causal prevention.

Matched ICD comparisons use the five-code composite J96.02/J96.12/J96.22/J96.92/E66.2. Each ICD/arterial pair requires ABG; each ICD/combined pair accepts either gas. Both models within a pair use identical rows with known coding capture; the pairs may differ. No missing-ICD projection is performed.

ICD negative denotes no target code in a complete, available captured encounter diagnosis extract; another diagnosis is not required. Unavailable/incomplete capture stays unknown. This is a documented-code outcome.

The registry contains 140 display/analysis positions but only eight unique outcome-model positions. Severe-subset and MNAR projections reuse models; cells and overlapping patients are not independent replications. No pooling or joint specification-curve inference is performed.

## Qualified clinical input

Clinical inputs are restricted and not distributed here. On the Mini, use a private copy of the [original-list mapping configuration](config/common_index_mapping.example.json), filled with actual source/evidence identities. Keep mapping products, spill and clinical audits in external private storage. Activate the existing R environment as described in [the handoff](docs/CLINICAL_RUN_HANDOFF.md).

```bash
make triangulation-map \
  PREP_PYTHON="/existing/upstream-environment/bin/python" \
  SOURCE_CONFIG="config/common_index_mapping.local.json" \
  OUTPUT="/private/external/new-mapping"
```

Bind the completed product's `product/manifest.json` and digest in the private configuration, then prepare a fresh typed input:

```bash
make triangulation-prepare \
  PREP_PYTHON="/existing/upstream-environment/bin/python" \
  SOURCE_CONFIG="config/common_index_mapping.local.json" \
  OUTPUT="/private/external/new-prepared-input"
```

Preparation verifies the source and upstream product, processes whole patients in bounded batches using the same R index selector, then extracts gases/diagnoses at the fixed resolved indexes. It writes `study-input.rds`, cohort/index evidence, a preparation receipt and a **pending** manifest. Source-candidate counts and typed-input row counts differ explicitly: unresolved indexes and exclusions remain in the bound cohort census. Models are not fitted.

Run independent source checks before finalizing the manifest:

```bash
make triangulation-qualify \
  PREP_PYTHON="/existing/upstream-environment/bin/python" \
  SOURCE_CONFIG="config/common_index_mapping.local.json" \
  PREPARED="/private/external/new-prepared-input" \
  OUTPUT="/private/external/new-source-checks"
```

`qualification.json` reports independent index/census, prepared-field equality, BMI arithmetic, testing flags, gas, diagnosis and calendar-day disagreements. Success is `automated_checks_passed` with zero disagreement counts, followed by reviewed gate evidence and preflight. The retained source review explicitly separates automated review from human scientific approval. A completed full-database hash receipt can be reused only when its trusted digest and unchanged source file identity match; otherwise preparation computes the full hash.

The older FULL_DATA decoder remains runnable using the historical template: it decodes Stata dates/codes and the inherited combined race/ethnicity rule. The new primary route explicitly binds original selected membership and separately maps available BMI; the old decoder is not a substitute for this new binding. Old source products and the original RDS are preserved.

Authorized users then provide the authenticated RDS/DTA and reviewed **version-3** manifest:

```bash
make triangulation-preflight INPUT="/explicit/input.rds"
make triangulation-preflight INPUT="/explicit/input.rds" MANIFEST="/reviewed/v3.json"
make triangulation-render INPUT="/accepted/input.rds" MANIFEST="/reviewed/v3.json"
```

The [template](config/triangulation_input.example.json) is deliberately pending. It binds the common BMI ≥30 study, exact source/input identity, original keys, mappings, approved gas/ICD policy and reviewed lineage/population/field evidence. A version-2 manifest cannot automatically qualify this original-list/available-BMI study. Preflight validates schema, mappings and evidence hashes; it does not independently reconcile raw source records. Clinical estimation requires a clean merged checkout and records its commit/tree and source hashes. No fallback dataset or unreviewed conversion is used.

Reuse [accepted upstream products](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/CURRENT_STATE.md) and existing receipts first. Reconcile all intended BMI ≥30 encounters, including patients without gases; historical compatibility membership is not a completeness proof. Distinguish testing from result-derived flags, verify raw specimen codes/units/maxima, retain legacy BMI/covariate derivations and authenticate ICD negative-versus-unknown rules. Normal gas records alone do not establish source coverage.

Optional calendar-day evidence can remain pending, with unassessed estimates/counts. Date precision suffices; pH pairing, medication activity and elapsed timestamps are not prerequisites. Request additional source work only for a demonstrated gap. See [input handoff](docs/TRIANGULATION_INPUT_HANDOFF.md) and [data management](docs/DATA_MANAGEMENT.md).

## Render a saved run

```bash
make render RUN="artifacts/triangulation/<saved-run>"
make render-html RUN="artifacts/triangulation/<saved-run>"
make render-pdf RUN="artifacts/triangulation/<saved-run>"
```

Reports and figures read validated aggregates without reopening clinical inputs or refitting. Each review creates a fresh directory inside its saved run. Version-1/2 runs dispatch to hash-verified frozen sources and keep original definitions. Bundles contain no patient identifiers, selected indexes, fitted model objects/data or individual predictions.

## Exhibit alternatives

A is the preferred paired absolute/PIF forest/table. B shows the same four observed/MAR benchmarks in outcome-first panels. C shows prespecified missing-outcome assumptions with the MAR anchor outlined; its range is not a confidence interval. BMI ≥40, timing, matched ICD and detailed diagnostics remain supporting results.

All figures use one saved ledger, signed scales and explicit unavailable positions. Exports are 190 mm wide, SVG/PDF masters plus 300-dpi PNG/JPG, with readable data/caption labels and full-size HTML/PDF galleries. Native-size, grayscale and numerical QC is recorded with actual coverage; it does not establish clinical validity. See [figure brief](docs/TRIANGULATION_FIGURE_BRIEF.md).

## Project and historical workflows

| Entry | Role |
| --- | --- |
| [Primary QMD](reports/bmi_hypercapnia_triangulation.qmd) | Report from saved common-index aggregates |
| [Common estimation](R/common_index_hypercapnia.R) and [reporting](R/common_index_reporting.R) | Models/projections, strict persistence and figures |
| [Plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) and [decisions](docs/DECISIONS.md) | Current scientific authority and dated history |
| [Source assessment](docs/TRIANGULATION_SOURCE_ASSESSMENT.md) | Existing-source qualification ledger |
| [Archive index](archive/README.md) and [comparison](docs/ANALYSIS_COMPARISON.md) | Distinct preserved specifications and provenance |

The unchanged version-2 frame-specific sources are preserved at `archive/2026-10-14-frame-specific/`. These supporting commands verify hashes and execute a copy in ignored storage:

```bash
make frame-triangulation-test
make frame-triangulation-fixture
make frame-triangulation INPUT="/accepted/input.rds" MANIFEST="/reviewed/v2.json"
```

Version-1 BMI-to-40 sources, original older R reports, repaired historical R replay and immutable/runnable Stata tracks retain their definitions. No historical result is relabeled as the new study.

```bash
make historical-test
make stata-test
make legacy-r INPUT="/explicit/historical.rds"
make legacy-r-html INPUT="/explicit/historical.rds"
make legacy-r-pdf INPUT="/explicit/historical.rds"
make render-archival
STATA_EXE="/path/to/licensed/Stata" make stata-check
STATA_EXE="/path/to/licensed/Stata" STATA_DATA_PATH="/approved/full_db.dta" make stata
```

Historical R additionally uses dplyr/forcats/gtsummary/here/modelsummary/purrr/stringr/tibble/tidyr. Stata requires version ≥18, table1_mc/mkspline2/cleanplots; reference smoke additionally uses xblc. No packages are installed automatically. See [Stata import](docs/STATA_IMPORT.md).

Generated/restricted materials remain ignored. Source acceptance, assumption credibility, scientific review and submission are separate milestones. Software licence, citation metadata and an external access procedure have not been declared; access and release permissions must not be inferred from repository access.
