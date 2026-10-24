# ICD acuity supplement

Current decision: the October 24 separation repair below supersedes the original
five-category maximum-likelihood specification. It uses Firth mean bias reduction
for all five categories, a separately fitted four-category maximum-likelihood
sensitivity, and observed BMI-band proportions. Existing qualified source evidence
is reused; the earlier design and failed run are retained here as dated history.

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

## Approved separation repair (2026-10-24)

The owner approved a mean-bias-reduced five-category multinomial spline, an
unpenalized four-category sensitivity excluding unspecified-only encounters,
and an observed BMI-band proportion companion. Source qualification, categories,
fixed indexes, primary numeric spline, adjustment and original primary/S1/PIF
analyses remain unchanged. The sensitivity retains co-coded unspecified flags
when precedence assigns a specified category; it excludes only the final
unspecified category and standardizes over that reduced sample.

The full model targets the multinomial log likelihood plus one half of the log
determinant of its Fisher information (Firth mean bias reduction). See
[Kosmidis and Firth (2011)](https://doi.org/10.1093/biomet/asr026).
A direct, small-information-matrix implementation avoids the observation-specific
nuisance columns in the package's Poisson expansion. Acceptance requires an
independent numerical likelihood oracle on separated data, the author-published
five-category brglm2 coefficients/SEs,
and a cohort-sized artificial benchmark. First-order model-based uncertainty
uses the inverse joint multinomial information at the bias-reduced estimate;
empirical references and the numeric spline basis remain fixed. This is not a
penalized-Hessian posterior interval or a remedy for selection/measurement bias.

Implement in the ICD and shared multinomial modules, report views and config;
advance the saved aggregate identity so old failed runs cannot acquire new
estimator labels. Verify with `make test` and `make source-test`, then release
and perform one fresh qualified Mini estimation. Old inputs and snapshots remain
immutable. No fallback estimator or demographic pooling is authorized. Finite
estimates do not establish adequate local support or investigator approval.

## Revised clinical execution (2026-10-24)

PR #25 merged the revision at `29687c9`. Fresh preflight passed without a source
change. Run `curve-analyze-20261024T053607-55109` fitted the five-category Firth
model in 176,922 patients and the four-category maximum-likelihood sensitivity
in 176,794 patients. The full design still has ordinary maximum-likelihood
separation; the bias-reduced fit converged in 12 iterations with a maximum absolute
adjusted score of 3.74e-8. The sensitivity had no detected separation.

The five-category counts are unchanged: 168,288 no target, 1,769 chronic/OHS,
3,443 acute-on-chronic/concurrent, 3,294 acute and 128 unspecified. The sensitivity
excludes only those 128 final unspecified-only cases. All 11 original primary,
S1 and PIF comparison tables reproduce the prior clinical run within 1e-10;
137 aggregate numerical checks passed. No new PIF was generated.

The [updated packet](../results/2026-10-24-icd-bias-reduced/README.md) contains the
integrated reports, full model/sensitivity curves and observed BMI-band proportions.
Filter curve and contrast tables by exact model ID. Pointwise intervals do not
account for source selection or coding error. Numerical verification is complete;
investigator interpretation and figure approval remain pending. No abstract draft.
