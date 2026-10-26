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
