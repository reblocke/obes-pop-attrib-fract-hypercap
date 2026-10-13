# Codex implementation ticket: obesity-HRF PAF refactor and reproducibility cleanup

> Historical R refactor ticket. The maintained R report and May 2026 render
> observations are documented in `WORKLOG.md`; this is not the active Stata
> import specification. See [Stata import](docs/STATA_IMPORT.md),
> [analysis comparison](docs/ANALYSIS_COMPARISON.md), and
> [current decisions](docs/DECISIONS.md). Original ticket text is preserved below.

## Background

The current obesity/hypercapnic respiratory failure analysis has a rendered PDF draft and exploratory Quarto/R code. The trainee has made substantive progress, but the workflow has accumulated code smell: repeated derivations, undefined attrition flags, overlapping outcome definitions, and a first-pass PAF calculation that needs a named counterfactual and reproducible table/figure outputs.

The dataset is expected to come from the upstream TriNetX preprocessing repository (`https://github.com/reblocke/trinetx-preprocessing`) and be available locally as `data/raw/full_db.rds` or `full_db.rds`.

## Goal

Implement a maintainable, reproducible Quarto analysis that recreates the current conceptual outputs while making the code safer for a novice trainee to maintain.

Primary outputs to preserve or improve:

1. Data ingest and type harmonization.
2. Missingness and plausibility checks.
3. BMI parsing and BMI categories.
4. HRF v1 primary outcome.
5. HRF v2 / strict sensitivity outcomes.
6. Explicit non-HRF / compensated hypercapnia / respiratory status definitions.
7. Cohort construction and attrition table.
8. Baseline characteristics table.
9. BMI-category HRF plots.
10. Primary and sensitivity logistic models.
11. Hypercapnia subgroup model.
12. PAF/PIF table and primary BMI-risk / PIF figure.

## Files to add or modify

Add or update these files in the repo:

```text
AGENTS.md
reports/reconstructed_obesity_hrf_from_pdf.qmd
reports/obesity_hrf_paf_analysis.qmd
WORKLOG.md
```

Recommended if not already present:

```text
Makefile
README.md
docs/DECISIONS.md
docs/DATA_MANAGEMENT.md
tests/testthat/test_analysis_derivations.R
```

## Source artifacts supplied in this ticket

- `reconstructed_obesity_hrf_from_pdf.qmd`: best-effort reconstruction of the PDF-rendered exploratory report.
- `refactored_obesity_hrf_paf_analysis.qmd`: proposed maintainable analysis report.
- `AGENTS_obesity_hrf.md`: project-specific coding-agent instructions. Rename/copy to repo-root `AGENTS.md` after review.

## Required implementation steps

### 1. Place files

1. Create `reports/` if it does not exist.
2. Copy `reconstructed_obesity_hrf_from_pdf.qmd` to `reports/reconstructed_obesity_hrf_from_pdf.qmd`.
3. Copy `refactored_obesity_hrf_paf_analysis.qmd` to `reports/obesity_hrf_paf_analysis.qmd`.
4. Replace or merge the repo-root `AGENTS.md` with `AGENTS_obesity_hrf.md`.
5. Create or update `WORKLOG.md` with a short entry describing this refactor.

### 2. Ensure data path is correct

The refactored report tries:

```r
data/raw/full_db.rds
full_db.rds
```

If the data are stored elsewhere, move/copy the file to `data/raw/full_db.rds` rather than hard-coding an absolute path.

### 3. Restore environment

If `renv.lock` exists:

```bash
Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore()'
```

If no lockfile exists, install required packages interactively or initialize `renv` after confirming with the maintainer. Do not add `install.packages()` to the QMD.

Minimum packages expected:

```r
c(
  "dplyr", "forcats", "ggplot2", "gtsummary", "haven", "here",
  "modelsummary", "purrr", "stringr", "tibble", "tidyr"
)
```

### 4. Render the refactored report

```bash
quarto render reports/obesity_hrf_paf_analysis.qmd
```

This command is expected to create the configured report outputs, including PDF. Use `make render-html` only for quick local checks.

If it fails, troubleshoot in this order:

1. Data path error: confirm `full_db.rds` location.
2. Missing required column error: compare with upstream preprocessing output and update only if the source variable name truly changed.
3. Label conversion error: inspect `niv_proc`, `imv_proc`, `sex`, and `ethnicity` labels.
4. Model error due to single-level factor: check if `sex` or `ethnicity` has only one level after filtering.
5. `gtsummary`/`modelsummary` rendering issues: confirm packages and use `ci_method = "wald"` to avoid slow profile likelihood CIs.

### 5. Render the reconstructed report only if needed

```bash
quarto render reports/reconstructed_obesity_hrf_from_pdf.qmd
```

This file is archival and should not be used as the main source of truth after the refactor is accepted.

## Bugs the refactor must fix

### Undefined attrition flags

The exploratory report attempted to use `has_bmi` and `has_any_gas_pair` before creating them. The refactor must create and use:

- `has_bmi`
- `has_abg_pair`
- `has_vbg_pair`
- `has_any_gas_pair`

Acceptance criterion: the attrition table renders without warnings about unknown columns.

### Missing gas data coded as non-HRF

Missing ABG/VBG data must not be coded as `No HRF`. The primary HRF variable should be:

- `1` if HRF criteria are met.
- `0` if a classifiable gas pair exists and HRF criteria are not met.
- `NA` if HRF status is not classifiable.

Acceptance criterion: the report includes counts for unclassifiable HRF status and the primary cohort filters to classifiable rows.

### Compensated hypercapnia hidden in non-HRF

The refactor should create a mutually exclusive `respiratory_status` variable that separates:

- `No hypercapnia`
- `Compensated hypercapnia`
- `HRF`
- `Other classifiable gas pattern`
- missing/unclassifiable

Acceptance criterion: the respiratory status count table is visible and is used to describe the classification scheme.

### PAF/PIF counterfactual ambiguity

The current first-pass PAF sets everyone to BMI 25. The refactor must retain that as a proof-of-concept row but also report named counterfactuals:

- `BMI >25 set to 25`
- `BMI >30 set to 30`
- `BMI >40 set to 40`
- `BMI >=40 subgroup: BMI >40 set to 40`

Acceptance criterion: the PIF table includes observed risk, counterfactual risk, and impact fraction for each named counterfactual.

## Validation checklist

After rendering, inspect the report for the following:

- [ ] Source dataset N matches the expected order of magnitude (~833,476 rows in the current draft).
- [ ] BMI missingness is reported.
- [ ] ABG/VBG pair availability is reported.
- [ ] Attrition table has no zero rows caused by missing `has_bmi`/`has_any_gas_pair` variables.
- [ ] Primary cohort N is plausible relative to the prior draft (~112,009, allowing for differences due to safer definitions).
- [ ] HRF v1 table includes `No`, `Yes`, and `NA`/unclassifiable counts.
- [ ] Baseline table renders.
- [ ] BMI-category HRF plot renders.
- [ ] Primary and strict model tables render with odds ratios.
- [ ] PIF table renders and includes the proof-of-concept row that should be close to the prior PAF (~0.075) if definitions match.
- [ ] BMI-risk curve renders with reference lines at BMI 25, 30, and 40.
- [ ] Every figure has a caption and alt text.

## Optional enhancements after first clean render

1. Add bootstrap confidence intervals for PIF estimates.
2. Add tests for derivation functions by extracting them to `R/analysis_derivations.R`.
3. Add a `Makefile` target:

```make
.PHONY: render
render:
	quarto render reports/obesity_hrf_paf_analysis.qmd

.PHONY: test
test:
	Rscript -e 'testthat::test_dir("tests/testthat")'
```

4. Add a Figure 1 composite using `patchwork` if the team wants a single multi-panel manuscript figure.
5. Add a sensitivity grid for ABG-only, VBG-only, ICD-only, and strict lab+ICD outcomes.

## Suggested WORKLOG entry

```md
## 2026-05-07 - Refactor obesity/HRF PAF analysis

- Added archival reconstruction of rendered PDF: `reports/reconstructed_obesity_hrf_from_pdf.qmd`.
- Added refactored maintainable analysis report: `reports/obesity_hrf_paf_analysis.qmd`.
- Added project-specific coding-agent instructions: `AGENTS.md`.
- Key fixes: defined gas/BMI availability flags, avoided missing gas = No HRF, separated compensated hypercapnia, created named PIF counterfactuals.
- Validation pending: render with local `full_db.rds`.
```

## Definition of done

This ticket is complete when:

1. `quarto render reports/obesity_hrf_paf_analysis.qmd` succeeds from a clean R session on a machine with the dataset.
2. The attrition, baseline, model, and PIF outputs all render.
3. The PIF table and BMI-risk figure are ready for mentor review.
4. `WORKLOG.md` records render command, package issues, warnings, and next steps.
5. `AGENTS.md` reflects this project, not the generic starter or unrelated repository.
