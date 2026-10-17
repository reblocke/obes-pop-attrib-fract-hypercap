# Observed-population BMI curves and expanded scientific/audit reports

## Current implementation authority — 2026-10-16

The owner approved this revision and its complete clinical refresh, including
review, commit, push, PR and merge before clinical execution on the Mini.

1. **Estimands:** gas curves, fixed contrasts and paired one-unit scenarios use
   each registered outcome-observed training population; ICD uses known capture.
   Observation curves and BMI support describe C. Retain first-index/BMI/source/
   spline/adjustment definitions and the 21-model registry. Timing, matched and
   linear-form checks remain; no estimator selection. Full-cohort MAR/MNAR and
   C40 outcome projections remain in the frozen historical run; no IPW.
2. **Scientific report:** introduction, detailed Methods, expanded Results with
   cohort/evidence, primary curves and contrasts, all primary coefficients and
   key diagnostics, paired scenario contributions, observed-data sensitivities,
   limitations and generated example conclusion wording. Aim for a readable
   mini-paper; completeness takes precedence over a fixed page cap.
3. **Complete audit:** logical ledger diagrams, all stage/variable profiles,
   all models/coefficient/covariance/failure/diagnostic entries, full-range
   coordinate plots and complete exports. Share identical summaries only after
   exact equality, with explicit aliases (not inferred membership identity).
4. **Figures/tables:** three F1 alternatives, separate outcome/availability
   quantities, one shared frequency strip, full ranges plus a labeled 30–60
   detail view. Fix crossed connectors, caption detachment, raw code labels and
   arbitrary column fragmentation. Vector PDF, SVG/PNG/JPG and actual figure QC.
5. **Identity:** schema 5, `bmi_hypercapnia_observed_curve_audit_v2`; unchanged
   source contract. Old bundles reject; preserve frozen source/results/history.
   Estimation once, then aggregate-only `make render RUN=...`.
6. **Verification/release:** independent observed-reference predictions, unchanged
   fitted models/samples, paired covariance and contribution identities, complete
   table reconstruction, adverse cases, actual artificial HTML/PDF renders and
   visual receipts. Review and merge, verify Mini checkout and source identities,
   run once into a fresh directory, reconcile against the former fit and inspect
   clinical exports. Keep source/execution/numerical/visual/scientific states separate.

## Completed observed-population release — 2026-10-16

PR #9 merged as `ca24564`. Fresh source preflight and one clinical analysis ran
from the matching clean isolated Mini checkout. Input and bound evidence hashes
remain unchanged. All 103 automated numerical checks passed, including agreement
with the former cohorts, fitted coefficients/covariance and observed scenarios.
The curve standardization reference changed as approved; no source, index,
adjustment or fitting rule changed during execution.

Both HTML/PDF reports rendered locally from the copied aggregate bundle without
clinical reads or refitting. The scientific PDF has 32 pages; the complete audit
has 808. All 215 figure layouts and all report pages were inspected in overview,
with main/dense examples inspected at full size. Automated bounds, symbol and
text-collision checks found no issues. F1-A remains preferred. Dense audit tables
remain closely spaced; complete machine-readable exports accompany them.
Investigator numerical/scientific approval remains pending. Private run identities,
commands and review scope are indexed in WORKLOG.md and ignored receipts.

## Preserved historical implementation record (superseded targets)

The following records the released version-4 workflow and its actual execution.
Its full-C gas targets and MAR/MNAR methods are not current defaults. Original
artifacts remain unchanged; the previous QC assessment is superseded by the
current repair work for crossed connectors and detached captions.

# BMI–hypercapnia curve and audit implementation plan

Authority: implementation ticket dated 2026-10-16, based on 8735505, reconciled
against the pending original-list/BMI corrections. The original plan is preserved
in `archive/2026-10-16-curve-refactor/PLAN.source.md` as superseded history.

## Execution checkpoint — 2026-10-16

PR #7 (`f18d383`) releases the tested curve/audit workflow. The owner explicitly
authorized source acceptance and clinical execution. Fresh source preflight and
one clinical analysis completed from a clean matching Mini worktree, preserving
existing source products and unrelated pending work. All 21 registered positions
are retained: 20 successful fits and one constant ICD capture-availability
position. The immutable aggregate bundle passes 48 additional numerical checks.
Both clinical HTML/PDF reports and all 153 figure exports pass recorded QC;
investigator numerical/scientific review remains pending. Private receipts and
exact run identities are indexed by WORKLOG.md. No new scientific definition
was adopted and no replacement export was requested.

## Confirmed decisions

- Retain original FULL_DATA selected ED/inpatient encounter candidates; do not
  reopen the outside-list mapping gap. Revalidate coverage within that universe.
- Preserve approved encounter/prior/calculated BMI, birth-year age proxy, first
  BMI>=30 index before gas/completeness, gas policies and inherited adjustment.
- Gas curves standardize to C; ICD curves/scenarios use C_icd with established
  capture, including positives/negatives. Do not project unknown diagnosis capture.
- Primary relationship: logistic natural BMI spline; C type-7 quantiles
  .05/.35/.65/.95, two interior/boundary knots, three basis columns; linear age.
- Default secondary policy: BMI>30 minus one, no floor/reselection. Caps disabled.
  C40 reuses the broader fit. Fixed 45-versus-40 contrast is not PIF.
- Keep independent primary/timing/observation/linear/matched fit registries and
  secondary fixed-observation MAR/MNAR projections. No automatic model selection.
- Breaking analysis schema version 4; preserve the accepted source contract,
  private artifacts and history. Old bundles reject rather than migrate.

## Work packages

1. **Authority/interfaces:** replace default routing, current instructions and
   registry; independent source/analysis/render commands and explicit configuration.
2. **Ledger/atlas first:** instrument pre-index candidate selection, preserve
   grain/uncertainty/overlap, complete variables, exclusions, missingness and
   distributions; support model-free and partial-source audit reports.
3. **Models:** register 21 planned fits when timing qualifies; complete coefficient,
   covariance/reference, sample, failure, residual, influence and support outputs.
4. **Predictions:** fixed-BMI common-reference curves, pointwise full-covariance
   uncertainty, supported 45-vs-40 contrasts, exact paired original-band burden
   decomposition and cross-band covariance; separate sensitivities.
5. **Reports/figures:** complete scientific/audit HTML/PDF, F0–F5, three F1 layouts,
   editable/vector/raster exports and actual QC at 190 mm and grayscale.
6. **Verification/handoff:** all 65 acceptance requirements mapped in
   `CURVE_AUDIT_ACCEPTANCE.csv`; independently verify predictions, gradients,
   reconciliation, full tables, adverse states, privacy and no-refit rendering.

## Source assessment amendment

The existing selected-index input cannot reconstruct pre-index distributions.
Prepare a fresh hash-bound companion from the existing mapped candidate product;
no upstream rebuild or new clinical export is presumed. It binds selected key and
covariate identity and contains aggregate stage audit only. Candidate profiles are
exact; partition quantiles are not averaged. Pre-index gases/diagnoses not extracted
are capability gaps, not patient-level negative/missing outcomes.

The earlier original-list mapping passed 30 independent checks and preflight.
That evidence remains useful but does not authenticate the new companion. On the
Mini, coordinate active jobs before remote writes; use fresh private locations and
reconcile the new companion against accepted products/input. Uncovered candidates
within the approved population block inference. No human review is invented.

## Interfaces and completion

`make fixture`, `make test BMI_TEST_REVIEW=...`, `make preflight/cohort-audit/analyze
INPUT=... MANIFEST=... CONFIG=...`, and `make render/render-html/render-pdf RUN=...`.
The model-free audit, once-per-model estimation and aggregate-only render are
separate. Saved bundle/source hashes prevent estimator changes from silently
reusing results. Figure revisions may render without refitting.

Software completion requires artificial end-to-end/adverse checks plus actual
full-report/native-size/grayscale inspection. Source qualification, clinical run,
numerical review and investigator scientific review are separately recorded.
Clinical analysis requires a clean reviewed merged Mini checkout; this ticket
itself does not authorize external publication, submission or upstream writes.

## Execution evidence — 2026-10-16

The refactor is implemented in the current working tree. The current source
qualification functions match the isolated Mini snapshot. The accepted mapped
candidate product, new aggregate companion, original selected input fields and
complete ledger reconcile; fresh identity-bound preflight passes. Existing source
and input products are unchanged. Private receipts are under ignored
`artifacts/triangulation/curve-refactor-source-review/`; no clinical models ran.

All 65 artificial acceptance requirements pass against the completed two-report
package. All 24 source-adapter tests pass without skips on the Mini. The local
Python run skips 12 optional dependency-backed cases, which the Mini run covers.
The optional testthat interface uses the same checks as the standalone runner;
no package was installed. All 13 qualification-function identities and the
estimation-file hashes agree with the isolated Mini snapshot.

Final artificial run: `artifacts/triangulation/curve-fixture-20261016T144730-79118/`.
Final review: `reviews/20261016T151707-glyph-81498/` within that run. Both HTML/PDF
reports, complete coefficients/covariances, reconciliation tables, F0–F5 and the
three F1 alternatives are present. F1-A remains preferred. The focused final
scientific-label repair reused the unchanged audit and figures with checked
hashes; it did not refit models or reopen clinical input.

Actual QC covers all 230 scientific figures in grayscale/native-size views,
every report page in layout overview, all-page text geometry, and representative
complete audit tables at native raster size. The audit has 1,094 pages and the
scientific report nine. Complete row and covariance coverage is independently
checked, rather than claiming manual reading of every cell. The large audit has
a slow cold HTML load, and some long captions continue on the next PDF page;
these are recorded presentation limitations, not missing content. Receipts and
exact commands are in WORKLOG.md and ignored run/QC evidence.

### Implemented work-package map

| Package | Modules / deliverables |
|---|---|
| WP1 authority/interfaces | Makefile, README, AGENTS, config, scripts/run_bmi_hypercapnia.R, scripts/render_bmi_hypercapnia.R |
| WP2 ledger/atlas | R/input_contract.R, R/cohort_audit.R, variable dictionary, cohort/retained-excluded/missingness/distribution exports |
| WP3 model audit | R/bmi_models.R, 21-position registry, complete coefficients/covariance/correlation/sample diagnostics |
| WP4 curves and burden | R/standardization.R, fixed-BMI curves/contrasts, paired scenarios and signed contribution covariance |
| WP5 reports/exhibits | R/reporting.R, two Quarto reports, F0–F5, F1 A/B/C, captions, gallery and QC receipts |
| WP6 verification | 65-check standalone/testthat interface, independent artificial source tests, private Mini preflight and source receipts |

The preceding artificial/preflight evidence records the pre-release checkpoint.
It is superseded for execution status by the current checkpoint above; its
receipts and artifacts are preserved. Investigator scientific review is not
asserted. No new scientific rule or replacement export was required.
