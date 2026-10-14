# R/Quarto plan: BMI–hypercapnia evidence triangulation

Approved implementation specification, 2026-10-12; primary counterfactual
**CONFIRMED 2026-10-13: set observed BMI >40 to 40, leaving BMI ≤40 unchanged**.
This supersedes the initial odds-ratio-primary specification and the interim
BMI-minus-one proposal. This plan defines a separate
workflow; it does not change either existing impact-fraction analysis or qualify
new clinical results. Implementation and artificial-data verification are
separate from clinical input acceptance, execution, scientific review, and
submission.

## Summary

Create `reports/bmi_hypercapnia_triangulation.qmd`, with reusable helpers in
`R/bmi_hypercapnia_triangulation.R`, to estimate the model-standardized potential
impact fraction (PIF) for the confirmed BMI-to-40 counterfactual across three
sampling frames and three outcome definitions.

The primary estimand is **1 − p_counterfactual / p_observed**, where both
probabilities are averaged over the same complete-case patients in each fitted
cell. Under the counterfactual, replace BMI with `pmin(bmi, 40)` and hold original
frame membership, selected encounter, and all adjustment values fixed. This
represents model-estimated burden associated with BMI above 40, not total
obesity-associated burden. The outcome is documented hypercapnia at the selected
encounter; there is no follow-up or incidence estimand.

BMI remains linear on the log-odds scale in the nine outcome models. The adjusted
odds ratio per 1 kg/m² higher BMI is supporting output; do not convert it into a
PAF or PIF. The nine estimates form a prespecified triangulation grid, not nine
independent replications or a formal joint specification-curve test.

Terminology: a potential impact fraction describes a proportional change under
an alternative exposure distribution. It allows a specified BMI shift without
equating that shift to eliminating all obesity; see
[Barendregt and Veerman's methods paper](https://pubmed.ncbi.nlm.nih.gov/19692711/).
The user's confirmed BMI-to-40 scenario, rather than this reference alone,
determines the counterfactual used here.

## Scientific specification

Restrict the source cohort to adults aged ≥18 with emergency or inpatient
encounters starting during calendar year 2022. Preserve validated source age and
encounter-setting definitions.

| Sampling frame | Membership |
| --- | --- |
| Severe obesity | BMI ≥40 kg/m² |
| ABG obtained | An arterial blood gas was drawn, without a BMI threshold |
| Either gas obtained | An arterial or venous blood gas was drawn, without a BMI threshold |

Within each frame, count each original patient once at their **first encounter
meeting that frame's criteria**. Patients can have different index encounters
across frames. Select the index before checking outcome availability or model
completeness. Never substitute a later encounter because it contains more
complete outcome or adjustment information.

| Outcome | Definition at the selected encounter |
| --- | --- |
| ICD composite | J96.02, J96.12, J96.22, J96.92, or E66.2 |
| ABG hypercapnia | PaCO₂ ≥45 mm Hg |
| ABG-or-VBG hypercapnia | PaCO₂ ≥45 mm Hg or venous PCO₂ ≥50 mm Hg |

Use the five-code legacy ICD composite without an E66.2-exclusion sensitivity
analysis. Explain that E66.2 is an obesity-specific diagnosis. Do not add a pH or
ventilatory-support requirement.

For the combined gas outcome:

- Either valid positive gas establishes positivity.
- At least one valid gas, with every available valid gas below its corresponding
  threshold, establishes an **available-gas negative**.
- No valid gas result means unknown.

An available-gas negative does not establish what an unmeasured specimen would
have shown. Gas-draw membership and usable-result availability are separate
variables. ABG-only classification likewise requires a valid arterial result;
no arterial result is unknown, not negative.

Use the legacy Stata-derived **`bmi`** throughout. Do not substitute current-only
BMI or reconstruct missing BMI in this notebook.

## Implementation

### Input, indexing, and provenance

- Read an explicitly supplied approved analysis-ready RDS or DTA input and a
  reviewed manifest containing its SHA-256 identity, source identity, and field
  mapping. Do not search for an arbitrary fallback or convert datasets
  automatically.
- Require authenticated original patient and encounter keys, encounter dates,
  age, setting, derived BMI, adjustment variables, gas-draw indicators, gas
  outcome evidence, and the legacy ICD composite.
- Verify source coding, gas units/specimen identity, and encounter attribution
  before accepting the mapping. Never interpret factor level numbers as clinical
  codes.
- Use the [manifest template](../config/triangulation_input.example.json) to
  bind the source columns and reviewed codes. Gas columns must contain the
  maximum valid specimen-specific PCO₂ in mm Hg during the selected encounter,
  so each threshold represents any qualifying measurement in that encounter.
  The notebook does not reconstruct producer-owned gas summaries. Dates must
  already be R `Date` values with a reviewed origin. Binary flags require
  explicit 0/1/unknown mapping; settings map to EMER, IMP, OTHER, or unknown;
  adjustment categories must match the reviewed allowed source values.
- Record input identity, source version, field mapping, analysis version, and
  R/package versions in ignored local run records. Keep restricted inputs and
  machine-specific paths out of Git.
- Reconcile duplicate encounter keys before index selection. Conflicting
  duplicates or unresolved earliest-encounter ties remain explicit unresolved
  indexes, excluded from model estimation and counted in the audit. File order
  is not a tie-breaker.
- Collapse exact duplicate rows. For contradictory encounter versions, confirm
  frame membership only when all versions agree on eligibility. Conflicting
  eligibility remains uncertain; a potentially qualifying earlier encounter
  prevents advancing to a later known encounter.
- Report uncertain dates and cohort scope separately. Verified identifiers and
  chronology are prerequisites for qualifying a patient-level analysis.

### Models

Fit one logistic regression per frame/outcome cell:

```r
outcome ~ bmi + age_at_encounter +
  factor(sex) + factor(race_ethnicity) + factor(location)
```

This carries forward the old Stata adjustment set: continuous age, sex, combined
race/ethnicity, and encounter location. BMI and age are linear on the log-odds
scale. Preserve documented source categories; do not manufacture an unknown
category for missing adjustment values.

Use complete cases for the selected outcome and adjustment variables **after**
index selection. Each cell contains one observation per patient. Preserve all
index uncertainty and complete-case exclusions in the audit. Patients overlap
between cells; do not pool estimates or count significant cells as independent
evidence. Report the BMI coefficient, standard error, adjusted odds ratio, and
95% Wald confidence interval in a supporting table.

Check outcome variation, model-matrix rank, convergence, separation warnings,
and finite estimates. Mark failed or nonestimable cells with a reason. Do not
silently drop adjustment terms, switch to penalized regression, or replace the
model. This first implementation contains only the nine specified linear-logit
models; a functional-form extension needs a separately documented decision.

### Paired standardization and uncertainty

For each estimable model, obtain predicted probabilities twice on exactly its
complete-case estimation sample:

1. Observed BMI and original adjustment values.
2. BMI `pmin(bmi, 40)` and the same original adjustment values.

Do not re-filter sampling-frame membership, reselect an index, or reapply
complete-case exclusions under the counterfactual. In particular, a patient in
the severe-obesity frame stays in that frame after the BMI assignment.

Report `p_observed`, `p_counterfactual`, the absolute probability difference
`p_observed - p_counterfactual`, and
`pif = 1 - p_counterfactual / p_observed`. These are model-standardized
probabilities of the documented index-encounter outcome. A negative fraction is
permitted and must not be truncated. It does not establish a harmful causal
effect of a BMI intervention.

Use a model-based delta method for the 95% interval of
`log(p_counterfactual / p_observed)`, using the full fitted GLM coefficient
covariance matrix. For observed/counterfactual design matrices `X_o`/`X_c`,
probability vectors `p_o`/`p_c`, means `q_o`/`q_c`, and covariance matrix `V`:

```text
ell = log(q_c / q_o)
g = mean_rows(X_c * p_c * (1 - p_c)) / q_c
    - mean_rows(X_o * p_o * (1 - p_o)) / q_o
se_ell = sqrt(t(g) V g)
PIF interval = [1 - exp(ell + 1.96 * se_ell),
                1 - exp(ell - 1.96 * se_ell)]
```

Use the normal 0.975 quantile in implementation. The two prediction averages
share the same fitted coefficients; their covariance must be retained. Treat
the empirical covariate distribution as fixed. There is no bootstrap and no
joint inference over the nine cells. The interval reflects coefficient
uncertainty; it excludes uncertainty from confounding, selection bias, and
outcome misclassification. If every BMI in an estimable cell is ≤40, the
counterfactual is identical to observed data: report exact zero probability
difference and PIF, an exact zero PIF interval, and an explicit no-change
diagnostic. Invalid probability ratios or covariance calculations produce a
visible nonestimable standardization status rather than a fabricated interval.

Report the count and percentage of counterfactual BMIs outside that cell's
observed fitted BMI range. This is an extrapolation diagnostic, not proof of
adequate conditional support when zero. Interpretation depends on model form,
adequate support, measured-confounder control, and assumptions linking the
hypothetical BMI assignment to an outcome. Do not claim a treatment effect or
causally preventable cases from this descriptive EHR analysis alone.

### Report and exhibits

Generate HTML and PDF reports containing:

- The scientific specification and a cohort/index flow summary.
- A nine-cell denominator table with frame membership, resolved indexes,
  outcome availability, complete model cases, events, and exclusions.
- A primary table with the observed/counterfactual probabilities, absolute
  probability difference, PIF and 95% interval, estimation status, model N, and
  counterfactual BMI support diagnostic; a supporting BMI odds-ratio table.
- A forest plot with three panels in frame order: severe obesity, ABG obtained,
  either gas obtained. Within each panel, show ICD, ABG, and ABG-or-VBG in that
  order. Use a shared linear percentage PIF axis, reference line at zero, direct
  PIF/interval labels, and cell-specific model denominators. Preserve negative
  estimates and interval limits.
- Explicit limitations concerning source-cohort enrichment, clinically selected
  testing, available-gas classification, overlapping populations, and the
  obesity-containing ICD composite, counterfactual extrapolation, model form,
  and assumptions required for causal interpretation.

The main caption must state **model-standardized potential impact fraction for
setting BMI >40 to 40, leaving BMI ≤40 unchanged**. It must identify the
same-patient standardization, documented index-encounter outcome, and model-based
delta-method interval with fixed empirical covariates. Do not label the PIF as
incidence reduction, total obesity burden, or a GLP-1 treatment effect. The
supporting odds-ratio table must state its per-1-kg/m² scale.
Export SVG/PDF masters and PNG/JPG review copies with explicit dimensions and
readable type. Nonestimable cells receive a labeled empty position, never a
numerical mark.

Add dedicated render/test commands without changing existing default report
targets. Keep generated reports, figures, logs, and restricted provenance in
ignored output directories. Update the repository analysis index and work log
to identify this separate workflow.

From the repository root:

```bash
make triangulation-test
make triangulation-fixture
make triangulation-render INPUT="/path/to/approved/input.rds" MANIFEST="/path/to/reviewed/manifest.json"
```

The test and fixture targets use artificial records only. The fixture target
renders HTML/PDF and figure exports. The render target opens the explicitly
supplied clinical input and is not part of implementation verification.
`make triangulation-test` uses base R assertions and the installed helper
dependencies. `make test` discovers the same checks through the existing
testthat recipe when `testthat` is installed. Neither target installs packages.

## Verification and completion criteria

Use focused artificial fixtures, without clinical execution, to verify:

- Inclusive BMI 40, PaCO₂ 45, and venous PCO₂ 50 boundaries.
- All combinations of positive, below-threshold, and missing gas evidence.
- A gas drawn without a usable result still establishes sampling-frame
  membership.
- One patient can have different first qualifying encounters across frames.
- Missing outcomes or covariates at the selected index never trigger selection
  of a later encounter.
- Duplicate keys, ambiguous dates/ties, and factor-coded inputs are handled
  explicitly.
- All nine models use the exact adjustment set and one patient per cell.
- BMI values ≤40 are unchanged; values >40 are set to 40 for counterfactual
  predictions only.
- The same model sample, frame membership, indexes, and adjustment values are
  used for observed and counterfactual predictions.
- Independent prediction averaging and numerical-gradient delta calculations
  reproduce the reported point estimates and interval calculations.
- Null BMI effects yield zero fractions; negative fractions remain visible;
  all-BMI-≤40 samples produce the exact no-change result and diagnostic.
- Counterfactual out-of-range counts and percentages match the fitted cell's
  observed BMI support.
- Denominators reconcile and plot values come directly from the results table.
- Nonestimable models produce visible explanations instead of misleading
  estimates.

Render a clearly labeled artificial-data report. Inspect every page, symbols,
labels, clipping, and grayscale readability. Verify historical analysis files
remain unchanged and generated outputs are ignored.

Implementation completion means a tested notebook, helper functions,
reproducible report layout, and documented input requirements. Actual-data
execution, qualification of clinical results, abstract revision, and submission
remain subsequent tasks requiring accepted inputs and applicable execution
scope. Artificial outputs cannot establish clinical findings or submission
readiness.


## Execution and figure revision, 2026-10-13

The existing estimator is preserved byte-for-byte. Clinical execution starts
with `make triangulation-preflight INPUT=...`, a schema/aggregate-only audit.
The local RDS is not authenticated by matching names or labels. Missing source
semantics trigger the field-specific [upstream handoff](TRIANGULATION_INPUT_HANDOFF.md),
without a legacy-proxy substitution or clinical model run.

The launcher estimates once, writes an aggregate-only RDS/CSV bundle and hashes
all bundle members. Quarto loads that bundle for both formats. A separate
`make triangulation-review RUN=...` produces a fresh review directory without
loading clinical inputs or evaluating models. Bundle hash mismatches, unexpected
fields, incorrect cell identities or denominator discrepancies fail explicitly.
Historical analysis outputs and the original estimator remain unchanged.

The [figure brief](TRIANGULATION_FIGURE_BRIEF.md) specifies A (compact forest),
B (outcome-first triptych), and C (3×3 mini-forest matrix). Every version uses the
same ledger and axis, direct PIF/95% interval/N labels, evidence/support diagnostics,
and explicit unavailable/no-change states. Exports are 190×180 mm, vector
SVG/PDF plus 300-dpi PNG/JPG, with HTML/PDF comparison galleries. Figure-and-medical-
illustration QC includes numerical read-back, full-size export inspection,
grayscale review and a run-specific manifest/receipt. Selection remains subject
to the actual result distribution and scientific/coauthor review.
