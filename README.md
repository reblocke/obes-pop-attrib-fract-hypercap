# Obesity and hypercapnic respiratory failure: BMI impact fractions

This workspace contains two historical BMI impact-fraction analysis tracks and
a separate patient-level BMI–hypercapnia triangulation workflow.
The canonical R/Quarto report studies **encounter observations** with recorded
BMI and classifiable hypercapnic respiratory failure (HRF). The imported Stata
analysis studies the obesity source branch with BMI >=40, comparing observed
BMI with BMI assigned to 40 for diagnosis-coded HRF and ABG hypercapnia.
Both use model-standardized probabilities. A causal interpretation requires
additional assumptions not established here. These historical tracks remain
separate. The triangulation workflow's primary estimand, confirmed October 13,
2026, is the model-standardized potential impact fraction for setting BMI >40
to 40, leaving BMI ≤40 unchanged, across three sampling frames and three
hypercapnia outcomes. It compares predictions on the same patients with fixed
original membership, indexes, and adjustment values. This describes modeled
burden above BMI 40 and documented hypercapnia at the selected encounter, not
incidence or total obesity burden. Per-BMI-point odds ratios are supporting
output. Read its
[approved plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md), the historical
[methods and findings comparison](docs/ANALYSIS_COMPARISON.md), and
[analysis decisions](docs/DECISIONS.md) before comparing their results.

| Report | Role | Render target |
| --- | --- | --- |
| [`reports/bmi_hypercapnia_triangulation.qmd`](reports/bmi_hypercapnia_triangulation.qmd) | Separate patient-level 3×3 BMI-to-40 PIF workflow; paired model-standardized probabilities, explicit outcome availability, and first qualifying encounter per frame | `make triangulation-fixture` for artificial HTML/PDF; explicit `make triangulation-render INPUT=... MANIFEST=...` for accepted clinical input |
| [`reports/obesity_hrf_paf_analysis.qmd`](reports/obesity_hrf_paf_analysis.qmd) | Maintained analysis, including attrition, descriptive/model tables, BMI plots and PIFs | HTML and PDF configured; `make render-html`, `make render-pdf`, or both via `make render` |
| [`reports/reconstructed_obesity_hrf_from_pdf.qmd`](reports/reconstructed_obesity_hrf_from_pdf.qmd) | Archival reconstruction of an earlier PDF-derived draft, not the maintained analysis | `make render-archival` produces HTML only |
| [`stata/do/36_subpop_hazard.do`](stata/do/36_subpop_hazard.do) | Runnable duplicate of the historical BMI-to-40 analysis, with estimators/PIFs preserved and decimal plotting repaired | `make stata-check`; explicit `make stata` |
| [`Documents/AS-edits-9-8------obesity-hrf.pdf`](Documents/AS-edits-9-8------obesity-hrf.pdf) | September trainee output with refitting-bootstrap intervals; corresponding updated QMD unavailable | Existing output only; not the canonical R source |

## Input and provenance

The triangulation workflow requires an explicitly supplied, authenticated RDS or
DTA input plus a reviewed SHA-256/source/field-mapping manifest
([incomplete template](config/triangulation_input.example.json)),
with patient/encounter identifiers, dates, derived `bmi`, gas-draw and gas-result
evidence, the five-code ICD composite, and the old Stata adjustment variables.
It selects adults with 2022 ED/inpatient encounters, once per patient within each
frame (BMI ≥40, ABG drawn, either ABG/VBG drawn). Each of nine linear-logit models
uses the old Stata adjustment set and its own complete-case estimation sample
for both observed and counterfactual predictions. The PIF interval uses a delta
method for the log probability ratio with full coefficient covariance and fixed
empirical covariates; no bootstrap or joint nine-cell inference is included.
Negative PIFs remain visible. Its report and artificial-data checks do not
qualify clinical results. See the
[plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) for index selection, missing
gas rules, and the exact model. The following input history describes the
existing canonical PAF/PIF report.

From the repository root, the canonical report calls `readRDS()` on the first
existing path: `data/raw/full_db.rds` (preferred), then root `full_db.rds`
(legacy fallback). The file is restricted and absent from Git. Keep input
records and machine-local paths out of tracked files; approved local inputs
remain ignored.

The current documents name `trinetx-preprocessing` as the expected upstream
source, and an older local [worklog](WORKLOG.md) records that an RDS was read for
a prior render. That does **not** identify a producer commit, exact source
snapshot, conversion/serialization step or schema identity for this particular
`full_db.rds`. A candidate converter exists in `trinetx-hypercapnia-code` at
`r/reports/90_stata_to_r.qmd`; it writes an RDS after importing a DTA and
converting labelled vectors to factors. Its existence does not authenticate
this particular input. The input must be authenticated and its transformation chain
supplied by the data steward before a new reproduction claim. The
[data-management note](docs/DATA_MANAGEMENT.md) records the required field
contract and this gap; it is not a substitute for source provenance.

The report checks required clinical fields, not a stable patient/encounter key
or row uniqueness. Treat its rows as encounter observations as coded; do not
infer independent patients or a verified join grain. No source capture period,
lookback or release coverage is established here. The report converts labelled
NIV/IMV and covariates, parses BMI (kg/m²), uses PaCO₂/VBG CO₂ (mmHg) and pH,
and keeps missing gas information unclassifiable rather than negative. Its
primary model uses recorded BMI, age at encounter, sex and ethnicity; it does
not verify that upstream case definitions match its own. See the
[canonical QMD](reports/obesity_hrf_paf_analysis.qmd) and
[decisions](docs/DECISIONS.md) for exact calculations.

## Environment and commands

The separate triangulation workflow has dedicated targets:

```bash
make triangulation-test     # helper checks using artificial records
make triangulation-fixture  # estimate artificial data once; HTML/PDF and A/B/C figures
make triangulation-preflight INPUT="/explicit/source.rds"  # schema/aggregate audit only
```

After clinical input acceptance and applicable execution scope are established:

```bash
make triangulation-render INPUT="/path/to/approved/input.rds" MANIFEST="/path/to/reviewed/manifest.json"
```

Clinical estimation is currently paused pending authenticated source semantics;
see [the upstream field request](docs/TRIANGULATION_INPUT_HANDOFF.md). The local
RDS schema audit alone does not qualify its gas-draw, specimen or ICD-capture
fields. Keep definitions fixed rather than substituting legacy proxies.

Each analysis saves a hash-checked aggregate-only bundle, CSV ledgers and source
receipts. Both report formats and all figures read that bundle without refitting.
To revise figures or reports without opening the clinical input:

```bash
make triangulation-review RUN="artifacts/triangulation/<saved-run>"
```

Reviews use fresh nested directories and preserve the saved analysis. They include
`figure-gallery.html`, a three-page PDF gallery, and A/B/C SVG/PDF/PNG/JPG exports.
[The figure brief](docs/TRIANGULATION_FIGURE_BRIEF.md) defines comparisons and QC.

The render target requires explicit input and manifest paths; it does not select
a fallback dataset. Artificial fixtures exercise implementation behavior only.
They provide no clinical findings or qualification of an actual-data run.

The helper checks require the installed `lpSolve`, `jsonlite`, `digest`, and
`haven` packages. Rendering additionally requires `ggplot2`, `knitr`,
`rmarkdown`, Quarto, and a working PDF toolchain. No target installs packages.
`make triangulation-test` runs the shared checks with base R assertions; the
same checks are available through `make test` when `testthat` is installed.
Run outputs are saved in fresh, ignored `artifacts/triangulation/` directories.

Run these targets from the repository root only after an authorized input and
working R/Quarto environment are available:

```bash
make render-html      # canonical HTML
make render-pdf       # canonical PDF; needs a working LaTeX installation
make render           # both configured formats
make render-archival  # archival HTML only
```

Quarto normally writes `reports/obesity_hrf_paf_analysis.html` and `.pdf`
beside the canonical QMD, or
`reports/reconstructed_obesity_hrf_from_pdf.html` for the archival target.
Check process completion and the rendered attrition, missingness, model and
named PIF sections; an output file alone does not establish a valid analysis.
The canonical source suppresses chunk warnings/messages in the rendered page,
so inspect the render log too.

The repository declares R >= 4.3 in its [instructions](AGENTS.md). The
canonical QMD imports `dplyr`, `forcats`, `ggplot2`, `gtsummary`, `haven`, `here`,
`modelsummary`, `purrr`, `stringr`, `tibble` and `tidyr`. No `renv.lock` is
committed, so dependency versions and environment reconstruction are **not
locked**. The [2026-05-07 setup entry](WORKLOG.md#2026-05-07-0831-mdt---refactor-obesityhrf-paf-repository-setup)
records an HTML render under R 4.5.3 and Quarto 1.9.36, with an initial PDF
failure from the then-local TeX Live update mismatch. A [later same-day entry](WORKLOG.md#2026-05-07---align-pdf-output-cutoff-and-flag-wording)
records successful canonical HTML and PDF renders after a report-format change.
These are dated local observations, not verification of the current environment
or a new render.

The earlier canonical-report setup had no `tests/testthat` suite; its historical
no-tests message was not a passing R test result. The new triangulation workflow
adds focused artificial-data checks, separate from clinical qualification.
`make stata-test` runs separate standard-library Python
tests for import preservation and launcher boundaries. Python supports the
launcher; the statistical analysis remains Stata.
`make renv-init` may install `renv`, initialize a project
library and snapshot dependencies. It has side effects and is reserved for a
separate maintainer-approved environment task; it was not run for this README.
No packages or locks were installed or changed during the Stata import.

## Stata entrypoint

From the repository root, set `STATA_EXE` to your licensed Stata 18+ executable:

```bash
export STATA_EXE="/path/to/licensed/Stata"
make stata-check       # version/packages only; no clinical input opened
make stata-test        # source/launcher unit tests; no Stata required
```

After the input identity and permitted execution are established, run explicitly:

```bash
STATA_DATA_PATH="/path/to/approved/full_db.dta" make stata
```

The default input is `data/raw/full_db.dta`. Required variables are documented in
[data management](docs/DATA_MANAGEMENT.md). An RDS is not accepted or converted.
Each run writes a new ignored directory under `artifacts/stata/` with source
snapshots, logs, figures, tables, and completion evidence. Success requires natural
process completion and native Stata return code zero. Exact native failure codes
remain in `execution/result.json`; shell statuses are capped at 255.
See [Stata import and commands](docs/STATA_IMPORT.md) for dependencies,
synthetic verification, inherited failures, and provenance.

The ignored historical evidence bundle and its inventory live under
`artifacts/evidence/stata-historical/`. Those local outputs are not included in a
fresh clone; the comparison documents portable source identities and limitations.

## What remains to reproduce

An authorized maintainer needs (1) the producer/source snapshot and exact RDS
serialization/schema receipt, (2) approved access and output-sharing rules,
(3) a reviewed locked R package environment and working PDF toolchain if PDF
is required, and (4) a data-bound render plus scientific review. An earlier HTML
render and a no-tests message do not close those gates. Repository code rights
do not grant rights to the restricted input or to publish derived results.
