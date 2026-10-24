# ICD acuity supplement

## Approved design (2026-10-23)

At the existing primary index, classify complete encounter diagnosis capture in
this precedence: J96.22 or J96.02 plus J96.12/E66.2 → acute-on-chronic or
concurrent acute/chronic coding; remaining J96.02 → acute; remaining J96.12/E66.2
→ chronic/OHS; remaining J96.92 → unspecified acuity; no target code → no target
diagnosis documented. OHS is analytically grouped with chronic coding, not proof
of chronic respiratory failure. Preserve all five flags and explicit versus
combined-code provenance. Incomplete capture is unknown, even with some codes.

Fit one five-category unpenalized multinomial spline over covariate-complete
primary patients with complete capture. Reuse the primary numeric basis and
inherited covariates. Standardize all categories over that same population.
Use the full BMI grid and supported five-unit contrasts, including category
changes and pairwise differences in changes with full joint covariance.
The fitted total is from the joint model and need not equal the existing binary
fit. No supplemental PIF, observation model, index reselection or new gas rule.

S2 mirrors S1: stacked positive-component probabilities, component curves on a
common baseline with pointwise 95% intervals, and the shared BMI frequencies.
Retain unspecified acuity. Flag sparse local evidence. Show OHS-only versus
chronic respiratory-failure coding by BMI and source-entry subgroup in the audit.
Code descriptions: https://www.cms.gov/icd10m/FY2025-NPRM-Version42-fullcode-cms/fullcode_cms/P0108.html

## Failure scenarios and planned verification (recorded before implementation)

- Mixed/overlapping codes must not double count; all 32 code patterns must reconcile
  to the original composite. Incomplete capture must never become negative.
- Original keys must not multiply or borrow another encounter's diagnosis flags.
  Unknown code systems, unexpected codes and conflicting source identities fail.
- Missing enrichment produces a pending position; partial, malformed, hash-mismatched
  or source-mismatched enrichment fails. Original fields/indexes remain unchanged.
- Five-category probabilities sum to one; positive components and covariance sum
  to the total. Independent softmax likelihood and finite-difference gradients
  verify coefficients, uncertainty and signed differences in category changes.
- Absent categories, separation and rank failure stay explicit, with no fallback.
- Original primary and S1 outputs match the pre-change artificial analysis within
  established tolerances; supplemental models never enter the PIF pipeline.
- Real HTML/PDF render from saved aggregates only, with complete tables and S2.
  Inspect native-size, grayscale and assembled pages separately from numerical tests.

Clinical source qualification and estimation are not claimed by artificial tests.
Historical reading snapshots are immutable; clinical execution requires the
repository's clean merged Mini workflow and a qualified fresh enrichment.

## Output navigation and execution boundary

`icd_acuity_categories` partitions the complete-capture reference population.
`icd_acuity_patterns` retains five-bit membership in this fixed order:
J96.02, J96.12, J96.22, J96.92, E66.2. Its counts cross original BMI bands and
historical source-entry subgroups; the explicit/concurrent and chronic-provenance
columns explain overlaps without changing their assignments.
`icd_acuity_contrasts` reports all supported five-unit intervals and the registered
40–45 interval (explicitly unavailable outside support), all category probabilities
and their intervals, ratios and six pairwise differences in component changes.
`icd_acuity_probability_covariance` supplies the complete within-grid covariance;
`icd_acuity_curve_reconciliation` checks probability sums. Standard coefficient,
reference, covariance and diagnostic tables include the new model ID.

Use `make enrich-icd-acuity` with the existing qualified input (which may already
contain S1 evidence), reviewed source configuration and fresh output. Original
fields, metadata and indexes must be invariant. The fresh manifest is
`triangulation_input.icd-acuity.json`. Source qualification and clinical estimation
require the normal reviewed, merged Mini workflow; artificial reports are not
clinical results. No release operation or abstract drafting is part of this update.

## Verification state (2026-10-23)

Artificial analysis-to-report E2E passed all 12 check groups, including independent
multinomial likelihood/uncertainty, original primary/S1 invariance, complete report
exports, aggregate-only rendering and hash-failure boundaries. Receipt:
`artifacts/triangulation/e2e-20261023T222313-62975/receipt.json`.
S2 and the new scientific section were visually inspected in color/grayscale and
assembled PDFs; exact coverage and file hashes are recorded in
`artifacts/triangulation/icd-acuity-development/figure-qc-final.json`.

On October 24, all 35 source-boundary checks passed without skips in the existing
Mini runtime, including both new ICD checks. The tested source hashes match this
implementation; later test-guide changes document the result only. Clinical
transport reconciliation, estimation and investigator interpretation remain pending.

## Clinical execution and estimability (2026-10-24)

PR #23 merged the workflow at `c0970484`. Fresh enrichment and Mini preflight
passed using the same accepted diagnosis source. All 223,514 original rows,
fields and fixed indexes were preserved; all 18,030 target source diagnosis
records reconciled, and the five-code union reproduced the original composite.
There was no demonstrated upstream change or new code-transport discrepancy.

Run `curve-analyze-20261024T022943-53435` completed once. Its primary diagnosis
population contains 176,922 patients: no target 168,288, chronic/OHS 1,769,
acute-on-chronic/concurrent 3,443, acute 3,294, and unspecified 128. The planned
five-category unpenalized model is **nonestimable because of separation**.
Unspecified diagnoses are absent in the retained Asian (995), American
Indian/Alaska Native (1,475) and Native Hawaiian/Pacific Islander (339) strata.
The full-rank planned design therefore does not guarantee a finite maximum-
likelihood fit. These are observed sampling zeros, not physiological conclusions.

All 11 original primary/S1 comparison tables agree within 1e-10; PIFs are
unchanged. Source qualification and category counts passed; ICD probability and
covariance reconciliation is **not assessed**, because there is no fitted ICD
acuity model. S2 displays the unavailable status, not estimated curves. No
category pooling, adjustment change or alternative estimator was substituted.

The [dated snapshot](../results/2026-10-24-icd-acuity/README.md) contains the
integrated reports, exact counts, model status and aggregate separation diagnostic.
A new modeling decision is needed to obtain adjusted acuity curves. Keeping the
current descriptive coding decomposition requires no such change. Investigator
interpretation remains pending; primary B/F2 and S1 snapshots are preserved.
