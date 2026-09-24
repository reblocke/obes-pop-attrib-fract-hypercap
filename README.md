# Obesity and hypercapnic respiratory failure: BMI impact fractions

This R/Quarto research workspace examines BMI and hypercapnic respiratory
failure (HRF) among **encounter observations** with recorded BMI and
classifiable gas/HRF information. Its canonical report estimates adjusted
associations and model-standardized impact fractions under named BMI
counterfactuals. These are model-based comparisons; a causal interpretation
requires additional assumptions not established by this repository. See the
[analysis decisions](docs/DECISIONS.md) for definitions and missingness rules.

| Report | Role | Render target |
| --- | --- | --- |
| [`reports/obesity_hrf_paf_analysis.qmd`](reports/obesity_hrf_paf_analysis.qmd) | Maintained analysis, including attrition, descriptive/model tables, BMI plots and PIFs | HTML and PDF configured; `make render-html`, `make render-pdf`, or both via `make render` |
| [`reports/reconstructed_obesity_hrf_from_pdf.qmd`](reports/reconstructed_obesity_hrf_from_pdf.qmd) | Archival reconstruction of an earlier PDF-derived draft, not the maintained analysis | `make render-archival` produces HTML only |

## Input and provenance

From the repository root, the canonical report calls `readRDS()` on the first
existing path: `data/raw/full_db.rds` (preferred), then root `full_db.rds`
(legacy fallback). The file is restricted and absent from Git. Do not copy it,
its records or machine-local paths into this repository.

The current documents name `trinetx-preprocessing` as the expected upstream
source, and an older local [worklog](WORKLOG.md) records that an RDS was read for
a prior render. That does **not** identify a producer commit, exact source
snapshot, conversion/serialization step or schema identity for this particular
`full_db.rds`. No `saveRDS` producer was found in the inspected upstream
source/docs. The input must be authenticated and its transformation chain
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
locked**. The 2026-05-07 worklog reports an HTML render under R 4.5.3 and
Quarto 1.9.36, and a PDF failure from the then-local TeX Live update mismatch;
those are historical observations, not current verification. On the executing
host for this README review, R 4.6.1 and Quarto 1.10.18 are present but the
listed R packages are absent. No render was attempted here.

`make test` currently prints `No tests/testthat directory yet.`; that is not a
passing test suite. `make renv-init` may install `renv`, initialize a project
library and snapshot dependencies. It has side effects and is reserved for a
separate maintainer-approved environment task; it was not run for this README.
No packages or locks were installed or changed here.

## What remains to reproduce

An authorized maintainer needs (1) the producer/source snapshot and exact RDS
serialization/schema receipt, (2) approved access and output-sharing rules,
(3) a reviewed locked R package environment and working PDF toolchain if PDF
is required, and (4) a data-bound render plus scientific review. An earlier HTML
render and a no-tests message do not close those gates. Repository code rights
do not grant rights to the restricted input or to publish derived results.
