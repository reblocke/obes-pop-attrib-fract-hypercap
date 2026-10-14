# BMI and hypercapnia: patient-level evidence triangulation

This R/Quarto research workflow is for clinical collaborators running or reviewing the patient-level BMI–hypercapnia analysis. Its primary output is a report of the **model-standardized potential impact fraction under a one-unit BMI reduction among patients with observed BMI >30 kg/m²**. BMI ≤30 is unchanged; there is no floor at 30. The same cell-specific model cases supply observed and shifted predictions with fixed sampling-frame membership, selected encounters and adjustment values.

The three intentionally different frames are BMI ≥40, ABG obtained, and ABG or VBG obtained. Each selects the first qualifying 2022 adult emergency/inpatient encounter per original patient. Nine encounter-wide primary cells and six index-calendar-day gas sensitivities use one registry. The fraction depends on each model-evaluable population's BMI distribution, percentage shifted and outcome probability. It is not a constant fraction attributable to a BMI unit. Causal prevention and incidence reduction are not established.

**Status (2026-10-13):** the primary workflow, artificial HTML/PDF reports and three exhibit alternatives have been verified locally. Clinical input qualification remains pending; artificial results do not reproduce clinical findings. The [source assessment](docs/TRIANGULATION_SOURCE_ASSESSMENT.md) identifies the remaining checks. Older R and Stata analyses remain distinct runnable historical archives.

## Prerequisites

Run commands from the repository root in a shell with Make, R ≥4.3 and Quarto available. Primary R dependencies must already be installed: `lpSolve`, `jsonlite`, `digest`, `haven`, `ggplot2`, `knitr` and `rmarkdown`. The dedicated test runner uses `testthat` when available and the same shared base-R checks when it is absent.

PDF report rendering additionally requires a working XeLaTeX toolchain and the Arial font available to Quarto. The HTML-only route below skips LaTeX report compilation; R still exports the figure PDF masters and PDF gallery.

The artificial workflow has been exercised on macOS with R 4.6.1 and Quarto 1.10.18. Other environments have not been qualified here. There is no committed `renv.lock`; actual versions are recorded per run. Commands do not automatically install packages. `make renv-init` remains a separately approved environment task, not a quick-start step.

## Quick start with artificial data

No clinical data or manifest is needed for this demonstration:

```bash
make triangulation-test
make triangulation-fixture
```

The fixture estimates once and creates a fresh directory under `artifacts/triangulation/`, containing HTML/PDF reports and A/B/C figure exports. The launcher prints the run directory, status and log location. To produce an HTML report without LaTeX report compilation, use the existing launcher option instead of the full fixture command:

```bash
Rscript --vanilla scripts/render_triangulation.R fixture html
```

Both fixture routes use simulated data and label every report/figure accordingly. They demonstrate execution and output structure, not source acceptance or clinical reproduction.

## Expected outputs and success checks

Open `rendered/bmi_hypercapnia_triangulation.html` and `figure-gallery.html` inside the printed run directory. The full fixture command also produces the report PDF. All run artifacts are local/ignored and are absent from a fresh clone.

| Within the run directory | Purpose |
| --- | --- |
| `aggregate_bundle.rds`, `aggregate_results.csv`, `specification_registry.csv`, `bundle_manifest.json` | Full-precision aggregate results, fifteen-cell/scenario definitions and file identities |
| `frame_counts.csv`, `scope_counts.csv`, `timing_audit.csv`, `bmi_summary.csv`, `bmi_diagnostics.csv` | Denominator, timing-transition and BMI/model-shape audits |
| `analysis_status.json`, `analysis_receipt.json`, `input_receipt.json`, `session_info.txt` | Analysis completion, one-estimation receipt, reviewed input declarations and actual runtime/package versions |
| `rendered/`, `figures/`, `figure-gallery.html`, `figure-gallery.pdf` | Selected report formats, SVG/PDF/PNG/JPG candidates and comparison galleries |
| `render_status.json`, `quarto-render.log` | Render completion/failure and expected-output/source-stability checks |

A successful fixture exits zero, records `analysis_completed`, then `render_completed` with `expected_outputs_present=true` and `render_sources_unchanged=true`. Confirm the artificial-data banner. Inspect the ledger for source-pending or nonestimable cells: they retain explicit reasons and do not become zero estimates. Successful execution or matching hashes does not establish clinical or scientific acceptance. Failure receipts/logs remain in the fresh run directory.

## Clinical data, access and source qualification

Clinical inputs are not distributed with this repository. Authorized users supply an authenticated RDS or DTA and a reviewed version-2 manifest; an external data-access procedure is not documented here. Restricted inputs and local manifests remain ignored. See [data management](docs/DATA_MANAGEMENT.md) and the [existing-source handoff](docs/TRIANGULATION_INPUT_HANDOFF.md).

```bash
make triangulation-preflight INPUT="/explicit/input.rds"
make triangulation-preflight INPUT="/explicit/input.rds" MANIFEST="/reviewed/v2.json"
make triangulation-render INPUT="/accepted/input.rds" MANIFEST="/reviewed/v2.json"
```

The [manifest template](config/triangulation_input.example.json) deliberately contains pending declarations and is rejected until actual review/evidence supplies them. All required primary fields, mappings and source gates must qualify. Preflight inspects schema/aggregates and, when given a manifest, verifies reviewed declarations and referenced evidence-file hashes; it does not independently reconcile raw source records. No arbitrary input fallback or source conversion occurs.

Calendar-day evidence can remain pending: the six sensitivity cells retain explicit source-pending status and missing estimates/model counts. This differs from patient-level unknown measurements within a qualified source and from a nonestimable model.

The [assessed upstream revision](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/CURRENT_STATE.md) records accepted encounter products with original keys and private linkage/coverage validation. It supersedes the older failed-build handoff within that accepted scope. Reuse existing products and their receipt chain; request additional source work only for a demonstrated unsupported required field.

Compatibility-backed membership still needs reconciliation with this study's intended gas/BMI frames. Raw exact-code transport can retain normal and unusable gas records without syndrome-positive catalog filtering. Legacy `has_abg`/`has_vbg` remain result-derived and need reviewed testing-evidence mapping. Dates support the chosen calendar-day sensitivity; elapsed timestamps, pH pairing and medication activity are not requirements here. The primary clinical input remains unqualified as recorded in the dated [source assessment](docs/TRIANGULATION_SOURCE_ASSESSMENT.md).

## Review a saved run without refitting

Replace `<saved-run>` with the run directory printed by an earlier estimation. Default render targets require this explicit aggregate run:

```bash
make render RUN="artifacts/triangulation/<saved-run>"       # HTML and PDF
make render-html RUN="artifacts/triangulation/<saved-run>"
make render-pdf RUN="artifacts/triangulation/<saved-run>"
make triangulation-review RUN="artifacts/triangulation/<saved-run>"
```

Estimation runs once. Report/figure revisions validate the saved bundle and read its aggregates without clinical input access or model fitting. Each review creates a fresh `reviews/<review-id>/` directory inside the saved run and preserves previous artifacts.

Version-2 bundles contain no patient identifiers, indexes, model rows or individual predictions. They retain the scenario/registry, denominator and diagnostic tables, input/source/evidence identities and environment. Shared patients do not become independent replications; no pooling or joint specification-curve inference is performed.

## Analysis and project map

Models use unchanged legacy-derived BMI, linear BMI/age and the Stata adjustment set: sex, combined race/ethnicity and region. Both probabilities average the same complete model cases. Outputs include paired probabilities, absolute differences, PIF with pointwise full-covariance delta-method limits conditional on empirical covariates, supporting BMI odds ratios, shifted percentage and support diagnostics.

| Outcome | Encounter-wide primary | Index-calendar-day sensitivity |
| --- | --- | --- |
| ICD composite | J96.02, J96.12, J96.22, J96.92 or E66.2 | No duplicate timing cell |
| ABG | PaCO₂ ≥45 mm Hg | Same threshold, collection date equals encounter-start date |
| ABG or VBG | PaCO₂ ≥45 or PvCO₂ ≥50 mm Hg | Same thresholds and calendar-day window |

Thresholds are inclusive. No pH/support criterion is added, and missing measurements remain unknown. Each fraction describes its model-evaluable subset; full-frame inference requires additional missing-data assumptions. Detailed definitions and scientific authority remain in the documents below.

| Start here | Role |
| --- | --- |
| [Primary QMD](reports/bmi_hypercapnia_triangulation.qmd) | Human-facing report from saved aggregates |
| [Estimation](R/bmi_hypercapnia_triangulation.R) and [reporting](R/triangulation_reporting.R) helpers | Selection, fifteen-cell estimation, persistence and exhibits |
| [Manifest template](config/triangulation_input.example.json) and [input handoff](docs/TRIANGULATION_INPUT_HANDOFF.md) | Required source binding/mapping and optional timing module |
| [Approved plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) and [decisions](docs/DECISIONS.md) | Current estimand, methods and dated decisions |
| [Source assessment](docs/TRIANGULATION_SOURCE_ASSESSMENT.md) and [audit response](docs/AUDIT_RESPONSE_2026-10-13.md) | Qualification evidence, remaining gaps and audit dispositions |
| [Archive index](archive/README.md) and [historical comparison](docs/ANALYSIS_COMPARISON.md) | Preserved originals, repaired historical tracks and distinct estimands |

Earlier drafts in `Code/` are retained for reference and are not the primary entrypoint. [WORKLOG.md](WORKLOG.md) records execution and verification history; it does not replace source receipts or scientific decisions.

## Exhibit alternatives

[The figure brief](docs/TRIANGULATION_FIGURE_BRIEF.md) defines the comparison and QC:

| Candidate | Reader's comparison |
| --- | --- |
| A — preferred forest/table | Magnitude, precision, N and percentage shifted across fifteen frame-grouped rows |
| B — outcome-first panels | Frames and gas windows within a fixed outcome |
| C — frame-by-outcome matrix | The triangulation design with paired timing estimates |

All use one saved ledger and common linear axes containing zero and every finite confidence limit. Pending/nonestimable positions have no numerical marks. Exports include SVG/PDF masters, 300-dpi PNG/JPG, editable R sources, individual full-size views and HTML/PDF galleries. Current exports are 190 ×275 mm with at least 9.5-point data labels. Native-size/grayscale inspections and numerical reconciliation are recorded in local QC receipts. These are alternatives for one exhibit, not three independent findings.

## Runnable historical archives

The [archive index](archive/README.md) distinguishes originals, repaired replay sources and their estimands. Original sources and prior BMI-to-40 decisions are preserved byte-for-byte with hashes and source-commit provenance under `archive/2026-10-13-bmi-to-40/`.

The [repaired historical R report](archive/r/obesity_hrf_paf_analysis.qmd) retains its original HRF outcomes, recorded-BMI/age/sex/ethnicity models and BMI-25/30/40 scenarios. Focused repairs preserve unknown ventilation, decode ICD values explicitly, propagate missing gas evidence and use correct parent cohorts for branch attrition. Its additional R packages are `dplyr`, `forcats`, `gtsummary`, `here`, `modelsummary`, `purrr`, `stringr`, `tibble` and `tidyr`.

```bash
make historical-test         # artificial regression checks and original-source hashes
make stata-test              # Stata source/launcher checks; no licensed runtime needed
make legacy-r INPUT="/explicit/historical.rds"
make legacy-r-html INPUT="/explicit/historical.rds"
make legacy-r-pdf INPUT="/explicit/historical.rds"
make render-archival          # unchanged reconstruction; original reproduction limits apply
```

Version-1 nine-cell BMI-to-40 saved runs remain reviewable through `make render RUN=...` using their frozen reader/report/figures. They retain original labels and cannot authorize new estimation or enter a version-2 figure.

The preserved Stata launcher and source tests also require Python 3. Its analysis uses explicit historical commands:

```bash
STATA_EXE="/path/to/licensed/Stata" make stata-check
STATA_EXE="/path/to/licensed/Stata" STATA_DATA_PATH="/approved/full_db.dta" make stata
```

Require Stata ≥18, `table1_mc`, `mkspline2` and `cleanplots`; reference smoke also uses `xblc`. No packages are installed automatically. The immutable source and runnable copy retain their source/body contract and previously authorized four-call plotting repair. See [Stata import and commands](docs/STATA_IMPORT.md).

## Reproducibility and remaining limits

Artificial execution and verification are documented in [WORKLOG.md](WORKLOG.md), with code/input identities, environment and actual checks retained in local run manifests/receipts. The primary clinical run remains pending source qualification; successful artificial execution does not validate clinical results. Conditional model-based intervals do not quantify confounding, selection, incomplete source capture or uncertainty in the empirical covariate distribution.

Primary outputs live under `artifacts/triangulation/`; historical R outputs under `artifacts/historical-r/`; Stata outputs under `artifacts/stata/`. Source originals are tracked; restricted inputs and generated data/reports/figures/receipts are not. Engineering completion, clinical input acceptance, scientific review and submission are separate milestones. Software licensing and preferred citation metadata have not been declared in this repository; restricted-data access and release permissions remain separate.
