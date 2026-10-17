# RFS-stratified BMI–hypercapnia implementation plan

Approved 2026-10-17; baseline `dd6b9277f69d75b343014c91c29f26ef6234cfd9`.
This supersedes the combined-cohort primary organization, retaining its dated
history in Git and immutable version-5 clinical bundle.

## Scientific authority

Select the existing first qualifying adult 2022 ED/inpatient BMI≥30 index from
original FULL_DATA keys before RFS, gas or adjustment availability. Partition at
that fixed index: primary any non-OBESITY source membership; obesity-only
sensitivity OBESITY=1 and all five other flags authenticated zero; unresolved
otherwise. All-zero discrepancies require investigation. Overlap remains primary.
Flags describe historical source-file membership, not exhaustive clinical criteria.
Do not reconstruct extraction without its obesity query or promote later indexes.

Retain ordinary ABG≥45, ABG≥45 or VBG≥50, known-capture five-code ICD, established
validity/units, adjustment and available-BMI hierarchy. Independently fit natural
BMI splines per RFS group using C quantiles .05/.35/.65/.95 (type 7). Preserve
all planned observation, matched, calendar-day and same-sample linear positions.
No full-cohort projection, MAR/MNAR, IPW, new recoding or BMI imputation.

Standardize each model to its outcome-evaluable population. Secondary paired
scenario: observed BMI>30 minus exactly one, no floor/reselection; BMI=30 unchanged.
Persist support and exact signed contribution/covariance reconciliation. Require
training support for 40/45 contrasts. Retain failures without estimator substitution.

## Implementation checkpoints

1. Authenticate historical flags/producer, extraction semantics, dictionaries,
   exact original-key linkage, BMI provenance and raw demographic categories.
   Extend accepted metadata transport; no upstream rebuild or gas re-extraction.
2. Enrich the qualified input into a fresh schema-4 input and pre-index companion.
   Bind prior input/manifest/run and RFS evidence. Verify index/field invariance.
3. Construct the partition ledger and RFS outcome-incorporation tables. Show
   overlaps, boundary counts, BMI/provenance lags, demographic cross-tabs,
   fine bins 35–55, retained/excluded profiles and explicit unavailable quantities.
4. Generate the configured model registry, group-specific basis identities,
   complete output and schema-6 aggregate bundle. Fit limited current-measurement
   sensitivities using the selected current BMI, and all-OBESITY supporting fits.
   Current-measurement sensitivities reuse the parent basis; all-OBESITY gets its
   own basis. These supporting groups each have three encounter-wide spline fits.
5. Render scientific and complete-audit reports from aggregates only. Produce
   parallel F1-A/B/C, source-entry/flow figures and paired contribution exhibits.
   Inspect native-size/grayscale exports under the figure QC skill.
6. Review/test/release code, qualify fresh metadata on the Mini, execute once from
   clean merged code and reconcile. Preserve every prior input/run/review receipt.

## Verification and review

`make test` is data-free numerical/adapter verification; missing optional Python
SQL dependencies are explicitly skipped, not passed. `make fixture` performs
actual artificial estimation and full rendering. `make render-test REVIEW=...`
checks actual completed HTML/PDF table coverage and aggregate-only tripwires.
Human visual/scientific reviews have separate receipts and cannot be synthesized
from automated export success. New run-specific acceptance receipts never overwrite
the previous 73-check clinical ledger.

Compare prior keys/fields and count alternative-index changes without fitting an
alternative design. Reuse the BMI-coverage cross-project audit and identify remaining
unassessed decomposition/diagram evidence explicitly. Counts alone are not keyed
reconciliation. Do not edit other projects.

Completion: revised code, independent checks, source-qualified enriched input,
reconciled clinical execution, complete reports/figures and change log. Any remaining
source or scientific review limitation must accompany the delivery.

## Execution checkpoint — 2026-10-17

PR #12 merged as `4fdf4eb`. The clean Mini checkout passed final source preflight
and completed one clinical estimation. All 162 aggregate numerical checks pass;
post-run input and evidence hashes match. The configured registry contains all
planned positions, including constant-outcome, separation and rank-deficiency
statuses. Sparse obesity-only fits are not replaced with another estimator.

Both reports and figure alternatives are generated from that saved bundle;
presentation repairs do not authorize another estimation. Exact private paths,
hashes, rendering and scoped visual-review receipts remain in ignored release
storage. Investigator numerical/scientific approval and cross-project keyed
decomposition remain distinct outstanding work. Historical query parameters and
individual entry triggers remain unavailable, rather than reconstructed.
