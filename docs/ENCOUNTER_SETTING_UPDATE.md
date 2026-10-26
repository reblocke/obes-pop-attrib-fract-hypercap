# Encounter-setting adjustment — implementation and verification

Owner-approved on 2026-10-25. Add the authenticated index encounter setting as
an additive categorical adjustment (EMER reference; IMP inpatient) to every
registered model. No interaction, weighting, new selection, or source rebuild.
Use input schema 5; new aggregate schema 14 and analysis identity
`bmi_hypercapnia_rfs_curve_audit_v9`. Preserve historical outputs and abstract files.

## Observable failures, recorded before estimation edits

- A model family omits setting, treats it numerically, changes its reference, or
  loses the term while constructing fixed-BMI or shifted prediction matrices.
- Setting-correlated BMI/outcomes yield plausible but incorrectly unadjusted curves.
- Missing/absent factor levels silently change the sample or simplify a failed fit.
- Adding adjustment changes index selection, source fields, model/reference counts,
  events, spline knots, or the setting values held fixed during the BMI scenario.
- Joint coefficients/covariance use the wrong design ordering; component sums or
  signed scenario contributions cease to reconcile.
- An old schema-13 result receives setting-adjusted labels; a report mixes old and
  new values or reads clinical inputs during aggregate-only rendering.
- Setting-specific availability is confused with hypercapnia positivity or raw
  proportions are described as adjusted predictions.

## Execution

1. Preserve pending figure/report edits and prior artifacts; stop only this task's
   superseded jobs with a separate interruption receipt.
2. Extend independent E2E data/oracles before estimation code. Use a synthetic
   setting effect and BMI/setting association; reproduce all binary/joint models,
   gradients and scenarios independently. Retain repeatable artifacts.
3. Share adjustment/factor/design definitions; extend support/diagnostic coverage.
   Add a setting-by-BMI availability audit. Preserve every model/failure position.
4. Run `make test` and `make source-test`, review and fix, release by PR/squash merge.
5. In a fresh clean merged Mini checkout, reauthenticate the existing prepared-02
   input/manifest and run preflight, one clinical estimation, then saved rendering.
6. Reconcile unchanged membership/counts/basis against the October 24 snapshot;
   compare new curves, components, BMI 30/40/50 landmarks and PIFs.
7. Inspect exports and assembled reports using figure QC. Publish a separate dated
   aggregate snapshot and review receipts; update current links only after review.

Panel D uses “Portion with blood gas obtained”. Its caption defines obtained as a
captured usable PCO₂ result; tests without usable captured results are unidentified.
Scientific/visual approval of regenerated results remains separate. No abstract edit.

## Execution and delivery — completed 2026-10-26

Code was reviewed and squash-merged in [PR #32](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/pull/32)
at `a978145b84857d99fcfd280f67d83a04d9c9325c`. Source-boundary checks passed
35/35; the complete artificial numerical/HTML/PDF E2E receipt passed. The original
interrupted test invocation and successful documented resumption remain distinct
in the work log; no skipped check is claimed as passed.

A fresh clean Mini checkout reauthenticated the existing input/manifest and all
15 evidence files. Preflight reproduced all 160 shared cohort nodes. One clinical
estimation completed in 3,599.987 seconds, saved as
`curve-analyze-20261026T001917-75549`. All 35 fitted positions include setting and
EMER reference, including all six joint component fits; ICD capture remains the
single constant position. The numerical reviewer passed 167 checks; independent
comparison passed 15,558 sample/basis checks, and 1,566 raw setting-availability
checks reproduced Wilson intervals and pooled counts.

The [new reading packet](../results/2026-10-26-setting-adjusted/README.md) contains
64 aggregate tables, scientific/audit HTML and PDFs, all scientific export formats,
full old/new curves and BMI-30/40/50/PIF comparison ledgers. Every scientific figure
and all 54 scientific PDF pages were visually inspected, including grayscale.
All 8,902 audit pages received automated geometry/symbol checks, with 23 pages
visually sampled; complete-table verification reconstructed 510,066 profile values.
The 18-page figure booklet uses a glyph-checked Unicode caption font. All rendering
and review used aggregates only, with zero clinical reads or model refits.

Primary arterial PIF remains 1.01%; combined gas is 0.83% and ICD is 2.86%.
Setting adjustment does not reverse the lower ascertainment probabilities at BMI
40/50 than 30. Existing abstract prose was not revised. The private figure-only
working packet is separate from earlier drafts. Investigator interpretation and
approval of new exports remain pending; execution is not submission approval.
