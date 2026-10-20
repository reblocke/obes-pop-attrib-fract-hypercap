# Current scientific and interface guide

This is the authority for the RFS curve/audit analysis. The retained filename
reflects the earlier triangulation design; that design is retired. Machine
configuration is [bmi_hypercapnia_analysis.json](../config/bmi_hypercapnia_analysis.json),
with input fields in the [variable dictionary](../config/variable_dictionary.csv).
The active identity is `bmi_hypercapnia_rfs_curve_audit_v3`, aggregate schema 8,
metadata-qualified input schema 4. Prior schemas fail explicitly; no replay or
migration layer is maintained. See [decisions](DECISIONS.md) for dated history.

## Population and index

Candidates are authenticated original FULL_DATA selected ED/inpatient encounters
(`original_selected_encounters_v1`), not every visit in captured history. Select
one index per patient before gas availability or adjustment completeness: the
first 2022 EMER/IMP encounter at age ≥18 with valid available BMI ≥30. Age uses the
approved birth-year proxy. Earlier unresolved eligibility, conflicting defining
evidence and earliest-day ties remain unresolved; a later more complete encounter
cannot replace them. A reliable exclusion overrides unrelated missing evidence.

BMI follows `available_encounter_or_prior_bmi_v1`: valid current reported BMI,
then prior reported BMI, then observed height/weight calculation, with inherited
transport, rounding and plausibility screens. Completed missing BMI does not
qualify; incomplete source or conflicting chronology remains unresolved. There
is no statistical BMI/covariate imputation or measurement-recency cap. Available
BMI is not necessarily contemporaneous or measured before the outcome.

Classify RFS membership at that fixed index, using the six authenticated original
family indicators, not current outcome/draw flags or numeric `rfsgroup` codes:

| Population | Definition and role |
|---|---|
| `primary` | Any confirmed ABG, VBG, RESPFAIL, VENTSUPPORT or PREDISPOSITION membership; retain OBESITY overlaps |
| `obesity_only` | OBESITY=1 and all five other families authenticated zero; descriptive audit only |
| RFS unresolved | Membership cannot be established; all-six-zero source discrepancies remain explicit |
| `primary_current` | Primary patients with verified current-encounter BMI source; supporting models, unchanged index |
| `all_obesity` | Any confirmed OBESITY membership; overlapping supporting models, not a disjoint comparator |

Source flags denote historical extraction membership, not every criterion present
clinically. Unknown is not zero. Obesity-only gas evaluability is depleted by the
entry mechanism; residual captured gases stay in the audit without recoding flags.
No obesity-only adjusted model, curve, PIF, scientific comparison or weighting
analysis is registered. Combined indexes remain a reconciliation reference.

## Outcomes and reference populations

Primary ascertainment uses the selected encounter, with ordinary unadjusted PCO₂
and authenticated specimen/units under `unadjusted_pco2_v1`:

| Outcome | Definition |
|---|---|
| Arterial | Valid ABG PaCO₂ ≥45 mm Hg |
| Combined gas | Valid ABG PaCO₂ ≥45 or VBG PvCO₂ ≥50 mm Hg; either usable specimen suffices |
| Documented ICD | J96.02, J96.12, J96.22, J96.92 or E66.2 with known diagnosis capture |

Strict gas validity is 5<arterial<200 and 10<venous<250 mm Hg. Missing/unusable gas
results remain unknown. A combined negative describes available evidence, not
normality of an unmeasured specimen. No target ICD code in a complete available
extract is captured absence; unavailable/incomplete capture stays unknown. ICD
capture is a source-coverage count, not ICD positivity or an informative constant
availability curve. E66.2 is explicitly part of the outcome.

Q is resolved indexes; C is Q complete for inherited BMI, age, sex, race/ethnicity
and region. Retained named Unknown categories count as nonmissing; completeness
does not establish knowledge of every underlying attribute. Numeric demographic
coding is unchanged; the White reference includes unknown ethnicity.

Gas curves/scenarios standardize within each outcome-evaluable model population.
ICD uses known-capture C_icd. Observation displays use C. Calendar-day gas
sensitivities retain indexes and require collection date = encounter-start date,
not elapsed 24 hours. Unavailable sensitivity source is pending, distinct from
individual missing outcomes. Matched ICD/gas comparisons use identical within-pair
rows; they do not require both gas specimens. Linear-BMI sensitivity uses the same
sample as its spline counterpart. BMI ≥40 remains descriptive only.

## Estimation and interpretation

Use logistic regression with a three-column natural BMI spline, linear age and
the inherited sex/race-ethnicity/region factors. Resolve numeric knots using C
quantiles .05/.35/.65/.95 (type 7): middle knots interior, outer knots boundary.
Primary models reuse the primary basis, including current-measurement supporting
models; all-OBESITY uses its own basis. Persist numeric knots and factor references.
Do not compare raw spline coefficients from different bases as the same contrast.

Registry positions come from saved configuration. Constant outcomes, duplicated
knots, rank deficiency, separation, inadequate variation and convergence failures
retain explicit statuses; no automatic simplification, penalization, pooled
categories or hidden complete-case exclusions. Every model retains all coefficients,
standard errors, intervals, reference levels and full covariance, plus sample/event
counts, diagnostics and failures.

Curves are model-standardized documented index-encounter probabilities. Intervals
are pointwise and model-based, conditional on the empirical reference population
and fixed basis. They exclude source-selection, measurement-error and unmeasured-
confounding uncertainty. Local sample/event and covariate counts reveal sparsity;
being within the global training BMI range does not prove joint support. Apparent
calibration and mean fitted probability are in-sample diagnostics, not validation.
The 45-versus-40 contrast is reported only where supported, with both probabilities,
difference, ratio and uncertainty.

The named secondary policy `bmi_gt30_minus1_v1` subtracts exactly one from observed
BMI >30; BMI=30 stays unchanged, no floor/reselection/index/RFS/covariate change.
Compute paired observed and shifted probabilities, their absolute difference and
PIF = 1 − shifted/observed probability using full-covariance delta-method intervals.
Signed contributions by original BMI band reconcile to the total difference and
its variance. Changing display bins cannot change the patient-level PIF. Never
multiply a marginal curve by marginal BMI density to obtain adjusted PIF.
Report model/reference N, number shifted, actual decrement and transformed-support
limits. Negative differences remain negative; undefined estimates are not zero.

No full-cohort MAR/MNAR projection, IPW, causal prevention or incident-disease claim
is part of the analysis. Source-entry partitioning does not eliminate selection
bias, selective gas measurement or residual confounding.

## Outputs and interfaces

The cohort ledger is the count authority. Record grain (record/encounter/patient)
and partition versus overlap. Q reconciles to primary + obesity-only + unresolved;
each group splits into complete/incomplete adjustment, and each complete group
into outcome-known/unknown. Do not add overlapping gas/model samples.

A run contains immutable aggregate data, CSV exports, configuration, registry,
source/input/evidence identities and hashes. No identifiers, exact dates, individual
predictions/diagnostics, model frames or fitted model objects enter the bundle.
Result keys include population, model, outcome, window, model form, reference
population and scenario policy where applicable. Failed/unavailable positions
remain present. Reports, figures and aggregate audit/result tables may be versioned
and shared under the owner's 2026-10-18 clarification; raw and patient-level data
remain excluded. The [collaborator snapshot](../results/2026-10-18/README.md)
versions complete report PDFs, B/F2, a local gallery and all 49 CSVs with hashes.
Local execution bundles remain ignored; the reading snapshot cannot be used as
a `make render` run directory.

| Command from repository root | Behavior |
|---|---|
| `make test` | Repeatable artificial E2E estimation, both report formats and artifact assertions; [test scope](../tests/README.md) |
| `make fixture` | Artificial run and reports without the E2E assertions |
| `make preflight INPUT=... MANIFEST=...` | Validate qualified source and ledger without models |
| `make cohort-audit INPUT=... MANIFEST=...` | Save source/cohort audit without model fitting |
| `make analyze INPUT=... MANIFEST=...` | Estimate once on clean merged Mini checkout |
| `make render RUN=...` | Fresh HTML/PDF review from explicit saved aggregates only |
| `make render-html RUN=...` / `make render-pdf RUN=...` | One output format for both reports |
| `make render-reports RUN=... FIGURES_FROM=...` | Prose/table rebuild using hash-matched figures from the same saved run |

`scripts/review_bmi_run.R RUN` independently reconciles saved numerical quantities.
`scripts/check_report_exports.py REVIEW` checks exports and prepares visual-review
sheets using existing Pillow/Poppler. Neither creates investigator approval.

The scientific mini-paper contains detailed Methods, primary relationships,
observation/BMI displays, verification-oriented Results and example conclusions.
The audit contains complete stage/variable profiles, all models/covariances,
failures, provenance and supporting analyses; full coordinate exports accompany
full-range plots. No preview may substitute for a complete table. The owner selected
F1-B and F2 as the working main figures on 2026-10-18; A/C remain alternatives.
The saved scientific PDF embeds A with identical values; use standalone B for
the selected presentation. See [figure QC](PUBLICATION_FIGURE_QC_PLAN.md).

Preparation, mapping, qualification and RFS metadata enrichment are separate
source operations described in [the source contract](SOURCE_CONTRACT.md).
Estimation failures preserve evidence; rendering failures are rerendered from the
same run without reading clinical input or refitting. Source or estimator changes
require a fresh qualified run and preserved prior evidence.

## Same-sample arterial acidemia supplement

See [the approved supplement](PAIRED_ABG_SUPPLEMENT.md). Exactly two secondary
positions reuse primary indexes, adjustment and knots; no new PIF is computed.
