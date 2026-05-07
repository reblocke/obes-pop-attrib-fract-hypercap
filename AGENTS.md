# AGENTS.md

## Project overview

- This repository supports a clinical epidemiology analysis of obesity, BMI, hypercapnia, and hypercapnic respiratory failure (HRF) using a TriNetX-derived dataset.
- The input dataset is expected to be generated upstream by `https://github.com/reblocke/trinetx-preprocessing` and made available locally as `data/raw/full_db.rds`.
- The primary deliverable is a Quarto report/manuscript analysis estimating model-standardized population attributable fractions / potential impact fractions (PAF/PIF) for BMI counterfactuals.
- The primary language is **R**. Use Stata only when explicitly requested for a separate analysis or translation.
- Do not invent results. If the data are unavailable, make code changes and state that render/validation could not be completed.

## Repository map

Preferred structure:

- `reports/` - Quarto reports and manuscript-facing outputs.
- `data/raw/` - immutable local source data (`full_db.rds`; not committed if PHI/restricted).
- `data/processed/` or `data/derived/` - derived non-PHI artifacts only when explicitly safe and allowed.
- `figures/` or `artifacts/figures/` - exported manuscript figures.
- `tables/` or `artifacts/tables/` - exported manuscript tables.
- `R/` - optional reusable helper functions once logic is stable and tested.
- `tests/testthat/` - tests for any helper code extracted to `R/`.
- `docs/` - decisions, workflow notes, codebook notes, and manuscript planning.
- `WORKLOG.md` - running handoff log for coding-agent and trainee continuity.

Current canonical analysis entrypoint:

- `reports/obesity_hrf_paf_analysis.qmd`

Archival reconstruction:

- `reports/reconstructed_obesity_hrf_from_pdf.qmd`

## Commands

Use relative paths and run commands from the repo root.

- Restore environment, if `renv.lock` exists:
  - `Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::restore()'`
- Render the main report as HTML for routine verification:
  - `quarto render reports/obesity_hrf_paf_analysis.qmd --to html`
- Render the main report as PDF when the local TeX installation is ready:
  - `quarto render reports/obesity_hrf_paf_analysis.qmd --to pdf`
- Render a recovered exploratory report, if needed:
  - `quarto render reports/reconstructed_obesity_hrf_from_pdf.qmd`
- Run tests, if tests exist:
  - `Rscript -e 'testthat::test_dir("tests/testthat")'`
- If adding packages, show but do not run automatically:
  - `Rscript -e 'renv::snapshot()'`

If a `Makefile` is present, prefer:

- `make render`
- `make render-pdf`
- `make render-archival`
- `make test`
- `make renv-init` only after maintainer approval to install/bootstrap `renv`, initialize the project library, and snapshot dependencies.

## Environment and dependencies

- Use R >= 4.3.
- Use `renv` when a lockfile exists. Never place `install.packages()` in committed analysis code.
- This repo currently has no committed `renv.lock`; do not initialize `renv` or create a lockfile without maintainer approval.
- Core packages currently used: `dplyr`, `tidyr`, `purrr`, `stringr`, `forcats`, `haven`, `ggplot2`, `gtsummary`, `modelsummary`, `here`, `tibble`.
- Show required `library()` calls in examples and chunks so code can run from a fresh R session.
- For random operations, set an explicit seed near the beginning, for example `set.seed(1234)`.
- Do not add heavy workflow frameworks (`targets`, `drake`, databases, containers) unless requested or clearly justified.

## Scientific definitions and guardrails

### Cutoffs

- ABG hypercapnia cutoff: PaCO2 >= 45 mmHg.
- VBG hypercapnia cutoff: CO2 >= 50 mmHg.
- Acidemia cutoff: pH <= 7.35.
- Obesity cutoff: BMI >= 30 kg/m^2.
- Severe obesity threshold often used for subgroup/PIF: BMI >= 40 kg/m^2.

### Outcomes

Primary HRF definition:

- HRF v1 = ventilatory support (NIV or IMV) plus ABG or VBG evidence of hypercapnic acidosis.
- Missing gas data must **not** be silently coded as non-HRF. Use `NA`/unclassifiable unless there is enough information to classify.

Sensitivity definitions:

- Lab-only hypercapnic acidosis.
- ICD-only hypercapnic respiratory failure.
- Strict lab + ICD definition.
- HRF vs compensated hypercapnia among physiologically hypercapnic patients.

### Respiratory status

Prefer a mutually exclusive status variable for descriptive work:

1. No hypercapnia.
2. Compensated hypercapnia.
3. HRF.
4. Other classifiable gas pattern.
5. Unclassifiable/missing.

Do not leave compensated hypercapnia hidden inside a vague "No HRF" comparator when that distinction matters.

### PAF/PIF interpretation

- Be explicit about the target population and counterfactual BMI intervention.
- Use `PIF = 1 - risk_counterfactual / risk_observed` from model-standardized predicted risks.
- Name each estimand clearly, for example:
  - `BMI >25 set to 25`.
  - `BMI >30 set to 30`.
  - `BMI >40 set to 40`.
  - `BMI >=40 subgroup: BMI >40 set to 40`.
- Avoid causal overclaiming. Use language such as "model-standardized impact fraction under the specified counterfactual" unless causal assumptions are explicitly defended.
- Avoid adjusting for likely mediators of obesity when estimating a total effect (for example OSA, diabetes, chronic cardiopulmonary conditions) unless the estimand is explicitly a controlled direct effect.

## R style and maintainability

- Prefer tidyverse-style code with native pipe `|>` or consistent magrittr pipe `%>%`; do not mix styles in a single chunk without reason.
- Use descriptive snake_case names.
- Use explicit namespaces in package-like code when ambiguity is possible, for example `dplyr::mutate`.
- Centralize constants near the top of the report.
- Define variables once in a derivation section, then reuse them.
- Treat missingness and classification flags as first-class variables (`has_bmi`, `has_abg_pair`, `has_vbg_pair`, `has_any_gas_pair`, `classifiable_hrf`).
- Avoid repeated copy-pasted logic for ABG/VBG classification, BMI categories, or PIF calculations. Use small helper functions with clear names.
- Keep comments focused on assumptions and non-obvious choices.
- Include basic diagnostics when proposing models, such as residual plots, convergence checks, or clearly stated model limitations as appropriate.
- Avoid interactive-only calls (`View()`, `fix()`, `browser()`) in committed code.
- Avoid `setwd()`, absolute paths, `attach()`, hidden global state, `<<-`, or reliance on saved RStudio workspaces.

## Quarto conventions

- Reports are written in Quarto (`.qmd`), not R Markdown.
- Use explicit YAML metadata with a title.
- Use chunk options via comment YAML, for example `#| label:` and `#| fig-cap:`, where practical.
- Label chunks with informative names that match their purpose, for example `data-cleaning` or `fit-primary-model`.
- For final PDF reports, prefer LaTeX PDF with:

```yaml
format:
  pdf:
    pdf-standard: ua-2
```

- Every manuscript-facing figure must have `fig-cap` and `fig-alt`.
- Keep final figures and tables generated by code, not by manual copy/paste.
- Do not add website-only Quarto features such as `llms-txt` unless the repo becomes a public documentation website.

## Figure standards

- Use `ggplot2` and a consistent project-level theme helper.
- Separate figure data preparation from plot construction.
- Use explicit axis labels and units.
- Avoid raw `theme_gray()` defaults for manuscript figures.
- Use readable text at final size.
- Export with explicit dimensions when writing figure files (`ggsave(width=, height=, units=, dpi=)`).
- No manual editing in PowerPoint/Illustrator as part of the primary reproducible workflow unless documented as journal-specific post-processing.

## Testing and validation

Before considering a change complete:

1. Confirm all required columns are validated before use.
2. Render the QMD from a clean R session when data are available.
3. Confirm the attrition table uses defined variables and no longer prints warnings for missing `has_bmi` or `has_any_gas`.
4. Confirm missing gases are not classified as "No HRF".
5. Confirm the PIF table reports observed risk, counterfactual risk, and impact fraction for named counterfactuals.
6. Confirm figures have captions and alt text.
7. Run tests if helper functions were added or modified.

Use `testthat` under `tests/testthat` for helper functions extracted to `R/`.

## Reproducibility and logging

- Keep a `WORKLOG.md` at the repo root.
- Update `WORKLOG.md` after any substantial analysis, render, or debugging session.
- Each worklog entry should include:
  - date/time,
  - task attempted/completed,
  - files changed,
  - commands run,
  - outputs generated,
  - errors/failures,
  - next steps.
- If the chat context is stale, treat the repo files, `WORKLOG.md`, and git history as source of truth.

## What not to do

- Do not recode missing gas results as normal/negative.
- Do not change scientific cutoffs without documenting the reason.
- Do not add new covariates to the primary PIF model without considering whether they are confounders, mediators, or colliders.
- Do not silently change denominators between tables, models, and figures.
- Do not move from exploratory plots to manuscript figures without cleaning labels, captions, and denominators.
- Do not commit restricted data, PHI, generated raw extracts, or machine-specific paths.
- Do not introduce hidden global state or non-determinism without clear explanation.
- Do not restructure code into new frameworks without being asked, for example do not switch to `targets` or `drake` unless requested.
