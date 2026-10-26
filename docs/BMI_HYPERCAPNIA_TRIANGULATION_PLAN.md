# BMI–hypercapnia: integrated scientific specification

Current implementation: input schema 5, aggregate schema 14,
`bmi_hypercapnia_rfs_curve_audit_v9`. The 2026-10-24 all-valid-BMI decision
supersedes first-BMI-≥30 selection. Earlier outputs retain their original design;
see [decisions](DECISIONS.md), [work log](../WORKLOG.md) and
[archive recovery](../archive/README.md). The [verified setting-adjusted packet](../results/2026-10-26-setting-adjusted/README.md)
records the reused accepted source, one schema-14 clinical run and numerical/scoped
visual review. Every fitted model adds EMER-reference/IMP inpatient setting.
Samples, events and spline bases match the immutable [October 24 packet](../results/2026-10-24-all-bmi/README.md).
See [setting implementation and verification](ENCOUNTER_SETTING_UPDATE.md).
Investigator interpretation and figure approval remain pending. Future runs require
fresh qualification; historical counts are not new-cohort counts.

## Cohort and populations

Use the authenticated original FULL_DATA ED/inpatient encounter list. History
supplies measurements, never extra candidate visits. Select each adult's first
2022 acute encounter with **any valid available BMI**, before gas availability,
adjustment completeness and historical reason-for-suspicion (RFS) classification.
Preserve completed-missing versus unresolved evidence, chronology, conflicting
records and earliest ties. An unresolved earlier candidate does not permit a
later convenient index. Age retains the inherited birth-year proxy.

BMI retains current/prior reported values followed by observed height/weight
calculation, original transport, rounding and masking/validity rules. No statistical
imputation or new plausibility rule is introduced. Available BMI need not be
contemporaneous. Report measurement methods, lags, component gaps and missingness.

| Population ID | Membership at the one newly selected index | Role |
|---|---|---|
| `primary` | Any confirmed non-OBESITY RFS flag, including OBESITY overlaps | All-valid-BMI primary |
| `primary_bmi_ge30` | Primary and index BMI ≥30 | Nested secondary; all three endpoint families refitted |
| `primary_current` | Primary and verified current BMI source | Binary sensitivity; primary spline basis |
| `all_obesity` | Any confirmed OBESITY membership, including overlaps | Overlapping binary sensitivity; own basis |
| `obesity_only` | OBESITY=1 and all five other flags known zero | Flow/descriptive audit only |
| `unresolved` | Membership cannot be established, including all-zero discrepancy | Audit; discrepancy investigated |
| `combined` | All resolved indexes before RFS partition | Reconciliation only |

The five non-OBESITY flags are ABG, VBG, RESPFAIL, VENTSUPPORT and PREDISPOSITION.
One known positive establishes primary even if another flag is unknown. Missing
flags never become zero. Flags describe selected historical source-file membership,
not exhaustive clinical criterion ascertainment; never recode them from outcomes.
No later encounter is substituted to enter the secondary or another RFS group.
Broader eligibility can change old indexes and their RFS membership.

## Three endpoint families

1. **Overall documented hypercapnia:** ordinary arterial PaCO₂ ≥45; ordinary
   arterial ≥45 or venous PvCO₂ ≥50; the five-code ICD composite. Gas negativity
   applies to available specimens; it does not establish an unmeasured specimen
   normal. Strict validity is 5<arterial<200 and 10<venous<250 mm Hg.
2. **Same-day physiological components:** one unpenalized three-category multinomial
   model on patients with a usable arterial PCO₂ and pH on at least one recorded
   date within the index encounter. Categories: no documented hypercapnia on
   co-observed days; hypercapnia without documented same-day acidemia; hypercapnia
   with same-day acidemia. Any day with PCO₂≥45 and pH<7.35 takes priority. Use
   6.5<pH<7.8, unrounded values and no cross-date conjunction. This is **same
   recorded-day co-occurrence; not verified same-sample pairing**. Different samples
   and treatment periods may contribute. No co-observed day means unknown.
3. **Diagnostic components:** five-category Firth mean-bias-reduced multinomial
   model on complete diagnosis capture. J96.22 or concurrent J96.02 plus
   J96.12/E66.2 takes acute-on-chronic/concurrent priority; remaining J96.02 is
   acute; remaining J96.12/E66.2 is chronic/OHS; remaining J96.92 is unspecified;
   no target code is reference. OHS grouping does not establish chronic respiratory
   failure. A registered unpenalized four-category sensitivity excludes only final
   unspecified-only cases and standardizes over that smaller sample.

All three families repeat in `primary_bmi_ge30`. Binary models alone receive PIFs.
The ICD code-level and same-day source gates remain independent; unavailable
modules retain explicit positions. Complete diagnosis capture is not positivity.

## Models and inference

Use three natural-spline BMI columns, linear age, and inherited sex, race/ethnicity
and region categories/reference levels, plus categorical index encounter setting
(EMER emergency reference; IMP inpatient) in every model. No BMI-by-setting
interaction or weighting is added; predictions retain observed setting.
Completeness means nonmissing specified
analysis values, including named Unknown categories. Do not silently recode raw
race/ethnicity or drop Unknown categories. The inherited White category includes
non-Hispanic or unknown ethnicity.

For each main population, resolve type-7 BMI quantiles .05/.35/.65/.95 on its
covariate-complete reference: two boundaries and two interior knots. Reuse the
fixed numeric basis across all endpoint families and predictions. Current-BMI
models reuse primary knots; all-OBESITY models resolve their own. Raw spline
coefficients across different bases are not comparable effects.

Binary logistic and unpenalized multinomial estimates use their full coefficient
covariance. Firth maximizes multinomial log likelihood plus half the log determinant
of Fisher information; inverse information at the resulting estimate supplies
first-order joint covariance. Preserve all coefficients, categorical references,
full covariance, model N/events and diagnostic/failure states. No hidden estimator
fallback, category pooling, penalization of other failed positions or model selection.

Standardize each model over its own outcome-evaluable covariate-complete patients.
Gas results are not projections to untested patients. Joint class probabilities
sum to one; positive components sum to their joint total, which need not equal a
separate binary fit. Pointwise 95% intervals condition on the empirical reference
and fixed basis. They do not cover selection, measurement or confounding bias.
Apparent calibration is in-sample, not independent validation.

Use the full observed BMI range with local patient/event/covariate support diagnostics.
Flag sparse/extrapolated regions. Supported five-unit contrasts, including 40–45,
are audit summaries rather than the main display; no multiplicity-adjusted or
between-population test is implied.

## Usable-evidence ascertainment

The primary ABG and VBG observation models describe at least one captured, encounter-linked ordinary unadjusted PCO₂ result with authenticated specimen assignment, reviewed units convertible to mm Hg and strict validity limits of 5<arterial<200 or 10<venous<250 mm Hg. Normal and elevated results count; pH is not required. Evidence can occur at any time within the index encounter, including later or post-treatment results. These models use the full adjustment-complete primary reference and the existing fixed spline/adjustment, not outcome-evaluable gas subsets. Captured usable evidence is not every test ordered or drawn; absent usable evidence does not establish no testing or physiological normality. Separate specimens overlap and cannot be summed.

## Secondary modeled burden

Policy `bmi_gt30_minus1_v1`: observed BMI>30 becomes BMI−1; BMI≤30 stays unchanged.
No floor, index/RFS/covariate change or reselection. Thus 30.2 becomes 29.2.

For every binary model, pair predictions on every reference row:

`PIF = (sum(p_observed) - sum(p_shifted)) / sum(p_observed)`.

Patients at BMI≤30 contribute baseline burden and exactly zero difference. Report
both standardized probabilities, signed absolute difference, PIF and full-covariance
delta-method intervals, model/reference N, eligible share, actual decrement and
transformed-support diagnostics. Original BMI-band contributions and their covariance
reproduce the total difference/variance. Never integrate a marginal adjusted curve
against marginal BMI density. No component-specific PIFs, MAR/MNAR, IPW,
incident-disease or causal-prevention claims.

## Sensitivities and audit

Primary-only ancillary positions retain recorded-result-date=start-date gas
sensitivities, matched ICD/gas samples and same-sample linear BMI checks. Calendar-day
source pending does not block qualified encounter-wide analyses. Current-measurement
and all-OBESITY-route binary checks remain distinct from the nested BMI secondary.

The ledger is the count authority. Distinguish records, encounters and patients;
RFS groups partition the common index cohort; adjustment complete/incomplete and
outcome-known/unknown partitions reconcile within each group. Endpoint samples
and all-OBESITY sensitivity overlap. Every variable and model has an audit entry,
complete coefficient/covariance table, diagnostic or explicit unavailable status.

Historical reconciliation is separate from acceptance: count newly eligible
patients, changed indexes/RFS, same-patient different-index, old-only patients,
and unchanged-key BMI/covariate/outcome fields. Do not require old and new model
coefficients to agree when their fitting populations or bases change. Same-input
numerical kernel checks must still agree within established tolerances.

## Execution and deliverables

One `make prepare` builds typed BMI/covariates, RFS, ordinary gases, recorded-day
components and code-level diagnoses from existing accepted mapping/readers. It
binds independent evidence statuses to the new input and selection hashes. No
historical clinical run is a prerequisite for source acceptance. See
[SOURCE_CONTRACT.md](SOURCE_CONTRACT.md) for qualification and private boundaries.

Run preparation → qualification → preflight → estimate once → render saved aggregates.
Current runtime bundles reject older schemas; historical published snapshots remain
immutable. No compatibility/migration layer is maintained.

The scientific mini-paper presents cohort, overall curves, physiological components,
diagnostic components, burden, nested secondary and other sensitivities, then
interpretation. The separate audit retains exhaustive tables and contrasts.
F1-main is the preferred primary relationship figure: combined-gas hypercapnia (A), nested arterial hypercapnia (B), stacked same-day arterial components (C), and separate ABG/VBG usable-evidence ascertainment (D). Its landmark table uses BMI 30 and 40 kg/m² with pointwise intervals. The existing F1 A–C alternatives and secondary/supporting figures remain available; F2 shows absolute burden and signed
contributions, including unshifted lower-BMI baseline burden. S1 and ICD displays
are integrated with population-labeled counterparts. Retain A/C alternatives,
editable sources, SVG/PDF and 300-dpi PNG/JPG, captions and gallery.

Verification: `make test`, `make source-test PREP_PYTHON=...`, aggregate-only numerical
review, figure QC at 190 mm/≥9pt, native/grayscale/assembled-page inspection.
Software, source acceptance, numerical review, visual review and investigator approval
are separate. Release code by reviewed PR/squash merge before clinical execution on a
clean merged Mini checkout. No abstract drafting is part of this change.
