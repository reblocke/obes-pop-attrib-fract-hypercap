## Observed-population reporting decision — confirmed 2026-10-16

- Primary gas standardization now uses each outcome-observed model population,
  including window-specific timing and same-sample linear checks. ICD remains
  known-capture; matched pairs retain their explicit shared populations.
- Full-C gas MAR/MNAR and C40 projections are historical only. IPW is deferred.
  Full-C usable-evidence and BMI displays remain descriptive selection context.
- The observed BMI >30 minus-one scenario is unchanged, without floor/reselection;
  PIF is a descriptive model-standardized distribution-shift contrast.
- Scientific report: expanded paper with full Methods, all primary coefficients,
  key diagnostic/scenario verification, and observed-data sensitivity Results.
  The audit retains every applicable variable, model, covariance and failure.
- The owner explicitly authorized code review, commit/push/PR/merge followed by
  fresh estimation on the Mini using the existing qualified source. No source
  replacement, upstream rebuild, publication or submission is authorized.
- Schema 5 and a new analysis identity prevent relabeling old full-C projections.
  Superseded analysis and QC receipts remain immutable historical evidence.

## Release and source-acceptance decision — 2026-10-16

The owner explicitly accepted the checked original-selected-encounter source,
pre-index companion and mappings and authorized release and clinical estimation.
Twelve post-run input/evidence hashes match; existing independent field and
30-check original-population evidence is retained. This accepts the
documented-evidence source for the agreed use, not MAR/MNAR assumptions or
causal claims.

PR #7 merged as `f18d383`; its tree exactly matches the candidate tested on the
Mini (65 artificial acceptance checks, 24 adapter tests, both complete HTML/PDF
reports and recorded figure/page QC). A separate clean external-drive worktree
preserves the pre-existing Mini edits and upstream checkout. Fresh clinical
preflight and one estimation completed from the merged revision. All 21 model
positions remain visible: 20 fits succeed; ICD capture availability is constant
and its raw proportions remain available. No source, covariate or estimator rule
was changed for execution.

The private `clinical-release-20261016/` packet binds source acceptance, reviewed
manifest, merged commit/tree, clinical bundle and 48 aggregate numerical checks.
Both clinical HTML/PDF reports and all 153 figure exports pass recorded QC.
Investigator numerical/scientific review remains pending. No clinical artifacts
or effect estimates are included here.
The dated pre-run assessments below remain historical evidence, not the current
execution status.

## Automated source/audit update — 2026-10-16

The new pre-index audit companion and fresh manifest pass automated reconciliation
and preflight on the Mini using the existing accepted products. An independent
field comparison agrees with the accepted selected input. Float32 values are
promoted before CSV serialization to preserve their exact accepted values; this
is a transport correction, not a new BMI definition. All qualification function
hashes match current code. No clinical models or human scientific approval are
claimed. Release/clean-checkout and clinical model review remain subsequent gates.

# Current authority — curve/audit refactor, confirmed 2026-10-16

The curve-first scientific report and complete construction/model audit supersede
the linear-coefficient/PIF-first grid and historical bundle replay. Dated entries
below retain history; this section and the current implementation plan govern.

| Decision | Confirmed policy |
| --- | --- |
| Population | Authenticated original selected encounters; outside-list broader mapping gap is historical |
| BMI/index/source | Preserve available encounter/prior/calculated BMI, birth-year age proxy, first BMI>=30 before gas/completeness and unadjusted source rules |
| Primary estimand | Flexible documented hypercapnia-probability relationship across BMI, with observation and frequency displays |
| Models | Fixed natural BMI spline at C quantiles .05/.35/.65/.95, type 7; inherited adjustment; no model selection |
| Gas reference | C, with explicit transport/MAR interpretation for untested patients |
| ICD reference | C_icd, patients with established capture including code-positive and code-negative patients; unknown capture not projected |
| Secondary scenario | Observed BMI>30 minus exactly one without floor; named caps disabled by default |
| Audit | One cohort ledger; every variable/stage and all coefficients/covariance/diagnostics/failures visible |
| Compatibility | Breaking version-4 bundle; old results rejected without migration/relabeling |
| New source requirement | Hash-bound pre-index audit companion from existing mapped candidates; do not infer earlier-stage profiles from selected indexes |
| Review states | Software, source qualification, execution, numerical review and scientific review remain separate |

**Current population correction — 2026-10-16:** candidate membership is restricted to the authenticated original FULL_DATA selected encounter list. See [the confirmed correction](#original-encounter-list-correction--confirmed-2026-10-16); earlier broader-source readiness is superseded for this use. The BMI rule and common-index model specification remain unchanged.

# Analysis decisions

## Historical primary authority — 2026-10-14, superseded by curve/audit refactor

The [implementation plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) and `reports/bmi_hypercapnia_triangulation.qmd` define the primary **common-index BMI ≥30 study**. This replaces the frame-specific grid as primary; that grid remains runnable supporting work.

| Decision | Confirmed specification |
| --- | --- |
| Common population | Adults ≥18; first qualifying 2022 ED/inpatient encounter with legacy BMI ≥30, selected before gas availability/completeness |
| BMI contrast | Observed BMI >30 minus exactly one; BMI =30 unchanged; no floor, caps or reselection |
| Reference | Resolved common indexes with complete inherited adjustment; same full reference for both gas projections |
| Models | Linear BMI/age, factor sex/race-ethnicity/region; legacy derived BMI; no new predictors or imputation |
| Evidence definitions | ABG ≥45 separately from ABG ≥45 or VBG ≥50; inclusive thresholds; either usable specimen suffices for combined evidence |
| Missing gases | Unknown preserved; observed benchmark plus conditional MAR and exploratory MNAR projections |
| MNAR assumptions | Missing/observed odds at BMI 40: 0.25/0.5/1/2/4; relative odds-gradient multiplier per five BMI: 0.5/1/2; membership fixed and offset evaluated at shifted BMI |
| BMI ≥40 sensitivity | Restrict original common indexes and re-average primary models; no new index or refit |
| Timing | Encounter maxima primary; original-index calendar-day sensitivity, not elapsed 24 hours; pending source evidence allowed |
| ICD comparison | Separate matched ICD/arterial and ICD/either-gas pairs with known ICD capture; no both-specimen requirement, no missing-ICD projection |
| Uncertainty | Pointwise full-coefficient delta method; empirical references/observation status and sensitivity parameters fixed |
| Terminology | Model-standardized probability difference and potential impact fraction; no incidence-reduction or causal-prevention claim |

A common BMI shift alone did not align the previous populations, reference distributions or clinical episodes. This decision fixes the index and target for the new projections. Observed benchmarks still average selected measured cases; MAR/MNAR full-reference projections require assumptions. The combined criterion also changes specimen ascertainment. Matching PIFs are not evidence that those differences are absent.

An available-gas negative does not establish negativity of an unmeasured specimen. No usable evidence stays unknown. Retain the five-code ICD composite including E66.2, describing its obesity-containing coding. No pH/support criterion or E66.2 exclusion is introduced.

## Source policy and release — confirmed 2026-10-15

- Use ordinary unadjusted PCO₂. LOINC 2019-8 is arterial and 2021-4 venous; 11557-6 alone is unspecified blood and requires authenticated specimen evidence. Temperature-adjusted records remain outside primary outcomes and are reported in preparation audits.
- Retain strict validity intervals 5 < arterial PCO₂ <200 and 10 < venous PCO₂ <250 mm Hg, with explicit reviewed conversion. These differ from inclusive outcome thresholds ≥45/≥50. Missing/incompatible units and unusable results remain unknown.
- No target code in a complete available captured encounter diagnosis extract is documented-ICD negative; another diagnosis is not required. Incomplete/unavailable capture remains unknown. Retain all five codes.
- Bind `unadjusted_pco2_v1` in new version-3 clinical manifests and hashed JSON field evidence. Existing bundles retain their recorded definitions and are never relabeled under this policy.
- The released baseline followed the code-first release sequence. The subsequent broader-mapping checks are pre-release source validation on explicitly recorded implementation branches. Review/commit/push/merge and synchronize final code before clinical estimation; repeat affected qualification after a material source/definition change. Calendar-day evidence may remain pending when unavailable.

## Data and interpretation judgments still requiring evidence

The [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md#expanded-source-qualification--2026-10-16) now records passing actual source checks for the separately prepared input, including original keys/chronology, expanded coverage, BMI/adjustment, gas/testing, ICD capture and calendar day. This is automated technical source qualification under the current rules. Human scientific review, code release and clinical estimation remain separate. Use the [home-network handoff](CLINICAL_RUN_HANDOFF.md).

Existing accepted upstream evidence is reused first; source absence is not inferred from an unavailable product on this host. No replacement export or timestamp acquisition is presumed necessary. Version-3 review must bind the expanded study; an old schema/hash pass alone is insufficient. Remaining source judgments are made from actual records/receipts, not invented here.

Scientific limits remain after source qualification: demographics-only MAR, informative ordering/specimen/frequency, model form, covariate missingness, shifted BMI support and causal confounding. The MNAR range is exploratory, not a clinical plausibility certificate.

## BMI availability and missingness — clarified 2026-10-15

The owner defines the source population by **valid BMI from the encounter or earlier**. Retain the adult, 2022 ED/inpatient and BMI ≥30 restrictions, the first qualifying encounter before gas availability, and the one-unit shift for observed BMI >30. This clarification does not make all acute-care patients the analysis denominator.

- Prefer valid recorded encounter BMI, then valid prior BMI, then BMI calculated from available observed height and weight. Preserve the inherited preference for current versus prior component measurements and record their dates. Encounter evidence may occur during the selected encounter; prior evidence must precede it. Do not use a subsequent encounter or substitute an encounter-start-only BMI window. Audit measurement age and ambiguous timing.
- No statistical BMI imputation, prediction from other characteristics, interpolation or assignment from obesity codes. Calculating weight/height² from usable observed measurements is permitted; preserve units, rounding and component provenance. A masked/censored value is not an exact measurement and cannot supply an invented exact BMI.
- After a completed source search/mapping, no usable recorded or calculable BMI is **missing BMI**, an ordinary data limitation. Count and report these encounters/patients; they do not qualify for the valid-BMI cohort and are not classified as BMI <30. A genuinely BMI-missing earlier encounter does not prevent a later encounter from being the first with valid BMI ≥30. No usable BMI anywhere leaves the patient outside this cohort, without imputation.
- An unprocessed key, incomplete evidence query, unresolved linkage or ambiguous timing is different from confirmed absence of usable BMI. Complete the mapping before assigning a missing-BMI reason; preserve uncertainty that could change the first valid-BMI index. Missing BMI values alone are not a reason to reject the entire source or request a replacement export.

The original Stata preprocessing explicitly comments that BMI is truncated at 50 by TriNetX and recodes current/prior recorded BMI ≥50.1 to missing. The accepted Python legacy cleaner reproduces that rule and the recorded-current → recorded-prior → calculated hierarchy. The final calculated BMI does not receive the 50.1 upper cutoff. This code comparison demonstrates inherited behavior, not a newly discovered Stata/Python discrepancy; see [the source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md#bmi-source-clarification--2026-10-15).

The owner's proposed upper limit of about **120 kg/m²** is conditional: if existing source evidence establishes genuine noncensored high BMI rather than masking, retain such values through the proposed plausibility ceiling in the new mapping and document the departure from legacy filtering. Do not merely change 50.1 to 120, reinterpret a top-code as an exact value, or describe 120 as a proven physiologic maximum. The precise masking encoding in this snapshot has not been established by the code comment or generic de-identification documentation. Historical accepted products remain unchanged.

**Implementation status:** the new mapping/index path uses `available_encounter_or_prior_bmi_v1` and explicit `bmi_evidence_state`; completed-missing BMI permits a later first valid-BMI index, while unresolved source evidence remains uncertain. Untagged historical inputs and saved bundles retain their original definitions. Bounded preparation uses the same R selector before gas extraction and binds the original aggregate census to resolved-index input. Actual source checks and preflight pass under this policy; see [the implementation plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md#valid-bmi-mapping-revision--2026-10-15).

## 2026-10-15 operational source bindings

The accepted FULL_DATA dictionary uses Stata calendar days, coded settings/demographics and separate `race`/`ethnicity`; the preparation configuration explicitly selects `accepted_stata_full_data_v1`. Decode the dictionary and reproduce the inherited ordered combined-category rule, leaving BMI/age unchanged. Missing raw race/ethnicity requires review rather than a new default assignment. The independent retained-reference category comparison passed. Previously typed preparation configurations retain `typed_v1`; saved results are unchanged.

Raw-source projection streams disjoint patient-hash partitions because direct projection/accumulation exceeded the execution caps. All raw rows for every original key remain together before consensus; only then is the agreed study scope applied and covered keys retained. Contradictory, missing and explicitly unknown settings remain uncertain. This is a resource fix, with reconciliation and fail-closed coverage, not a different sampling frame. External research scratch is required on this Mini; source products are never rebuilt or overwritten. No estimand, counterfactual, threshold or missing-outcome assumption changes here.

The initial bounded Mini check demonstrated missing legacy mappings for potential adult 2022 EMER/IMP keys. That finding motivated the separately named mapping described in [the source handoff](COMMON_INDEX_SOURCE_GAP_HANDOFF.md); it did not justify restricting the study to historical compatibility membership. The current implementation is recorded below.

## Original encounter-list correction — confirmed 2026-10-16

This decision supersedes the broader-source candidate population and the proposed
choice about earlier `UNKNOWN` history records. Candidate membership is the
**authenticated original FULL_DATA selected encounter list**, restricted to its
recorded ED/inpatient settings. Raw source `LAB`, `UNKNOWN`, other-history and
return-visit keys cannot add candidates or block an index outside that list.
The original list already represents the original reason-for-suspicion selection;
it is not a census of all encounters. Preserve that selected-population limitation.

Verify the original `first_encounter` flags using the frozen patient/date/hash
ordering. They identify the first row across original branches/settings; do not
apply them as a prefilter before the agreed BMI ≥30/acute-care eligibility.
Select one first qualifying adult 2022 BMI ≥30 encounter **within the original
list**, before gases or adjustment completeness. The new index orders captured
encounter starts; the historical flag orders original qualifying dates. Audit
that distinction explicitly rather than relabeling one date as the other. Same-day eligible ties and
unresolved relevant evidence within that list remain explicit; no arbitrary
key ordering or later replacement is introduced into the new study.

Use `FULL_DATA` membership, not AFTER_EXCLUSION imputed values. Retain
`available_encounter_or_prior_bmi_v1`: current, then prior recorded BMI, then
calculation from observed height/weight; no statistical imputation. Broader
history remains available solely to retrieve permitted prior evidence. Preserve
the exact one-unit shift for observed BMI >30, inclusive gas thresholds,
adjustment, models and observation-status rules.

New mapping/preparation/qualification binds `original_selected_encounters_v1`,
the original acceptance receipt and actual product/input hashes. Earlier broader
products, counts, readiness assessments and preflight receipts are retained as
superseded evidence for their original scope; they do not qualify this corrected
population. Old saved results retain their recorded specifications.

Execution is limited to mapping, preparation, source qualification and preflight;
no clinical models, publication or submission are authorized by this correction.
The Mini's separate GLP-1 qualification process is not modified. Shared upstream
code and captured databases remain read-only; this study uses its own private
outputs, a writer lease and guarded file synchronization.

**Current verification:** the original-list mapping is complete; all original first flags reproduce and exact acute-key coverage passes. Fresh dependent qualification passes all 30 independent source comparisons with zero disagreements. Technical completion, human scientific review and clinical
results remain distinct. See the source assessment and worklog for final receipts.

## Broader mapping implementation — 2026-10-16 (superseded population)

The separate upstream product uses original keys and captured records before gas/BMI/completeness selection. BMI provenance and `valid`/`missing`/`unresolved` states are explicit. Coverage, prepared-field equality, index/BMI, gas/testing, ICD/calendar-day checks and preflight pass. Products and clinical evidence remain private and historical products are unchanged.

Preserve the complete inherited numeric chain: normalized float16/CSV decimals, float32 source storage, Stata rounding, float32 intermediate and final BMI. The historical overlap audit exposed a defect in the draft mapper's intermediate storage order; it was reproduced and repaired before qualification or model fitting. When selected components agree, no unexplained BMI precision discrepancy remains. Per-candidate prior evidence and encounter-start-year age intentionally differ from the historical qualifying-event anchor.

The source contains no recorded BMI above 50.1. The conditional ceiling near 120 is therefore not activated. This does not prove that the observed value 50 is or is not top-coded; no exact masked value is inferred. Calculated BMI retains its approved arithmetic and does not receive the recorded-BMI cap.

Earlier unknown encounter setting and same-calendar-day index ties cause material attrition. Retain the existing conservative unresolved-index rule while the owner considers whether a **first documented ED/inpatient** target is preferable. No unknown setting is silently recoded nonacute and no arbitrary tied encounter is selected. Missing BMI after complete mapping remains an ordinary nonqualifying encounter, not unresolved evidence. Scientific source review, code release and clinical estimation remain separate.

## Remaining source-related choices — 2026-10-16

These are scientific choices exposed by actual source audits, not missing export
or mapping requirements. Exact counts and timing distributions remain private.

| Item | Current rule and proposal |
| --- | --- |
| Earlier unknown setting outside the original list | Resolved by the original-list correction above: outside-list history cannot block indexing. This was an artifact of the superseded candidate universe, not a missing-type-field defect in the original cohort. Within-list source conflicts remain separately audited. |
| Same-day earliest encounters | Keep unresolved without authentic ordering evidence. Do not pick by key, gas availability, ED-before-inpatient assumption or a later encounter. |
| Age of prior BMI/weight | Current approved availability rule has no recency cap. Actual prior measurements can be old. Retain that primary definition; propose a prespecified one-year recency sensitivity before clinical fitting. Define its BMI/component requirements and training/reference changes explicitly, retaining original indexes rather than substituting later encounters. No recency restriction is implemented here. |
| Measurements during the encounter | Current-encounter BMI/components may be recorded after admission, as allowed. Retain their dates and describe the encounter-wide evidence window; do not label them guaranteed pre-outcome baseline measurements. A start-day-only BMI definition would be a new scientific choice. |

The automated source review and identity-bound preflight pass for the current
rules. Human source/scientific approval is not invented; the private review
records its absence. Code publication, clinical estimation, numerical review and
coauthor interpretation remain subsequent steps.

## Dated superseded history and runnable archives

- **2026-10-13:** observed BMI >30 minus one became primary within three independently indexed frames (BMI ≥40, ABG obtained, either gas obtained), with nine encounter and six calendar-day cells. Its unchanged source, report, plan, decisions and tests are preserved at `archive/2026-10-14-frame-specific/` from commit `d8909df`. Default saved-run review recognizes those version-2 bundles. Dedicated frame commands retain estimation/testing in ignored workspaces.
- **Earlier 2026-10-13:** BMI >40 set to 40 was primary; superseded by the eligibility-restricted one-unit shift. The older unrestricted BMI-minus-one proposal was also superseded. Exact original sources/documents and version-1 BMI-to-40 report machinery remain under `archive/2026-10-13-bmi-to-40/`.
- Historical R remains a distinct repaired runnable track at `archive/r/obesity_hrf_paf_analysis.qmd`, with its HRF/acidosis/support outcomes, recorded BMI, age/sex/ethnicity and BMI-25/30/40 scenarios. Unknown ventilation/labs, actual 0/1 ICD decoding and parent-branch attrition were repaired without changing its historical model definitions. The reconstruction remains unchanged.
- Stata retains its immutable source and runnable repaired copy, obesity-source/BMI ≥40 cohort, legacy derived BMI, five-code/ABG definitions, demographic/region adjustment, spline/linear models and BMI-to-40 PIF. The authorized four-call precision repair remains its only analysis-body substitution beyond documented import changes. No new Stata edits are authorized by this update.

No archived estimate is relabeled as the common-index study. See [archive index](../archive/README.md) and [historical comparison](ANALYSIS_COMPARISON.md).

## Corrected-population source acceptance — 2026-10-16

The original-list mapping and fresh preparation completed naturally. All thirty
independent source comparisons have zero disagreements. Historical first flags,
exact original-key coverage, captured setting support, raw start-date consensus,
new first-index census, BMI arithmetic/states and typed fields reconcile. All
nineteen CSV/RDS fields agree exactly; gas/testing, ICD and calendar-day evidence
also reconcile. No unexplained historical/new index difference remains.

The source-freeze receipt is **ready_with_limitations** for the corrected
original-selected-cohort use. The identity-bound preflight passes with zero
models fitted. These are automated technical source checks; human scientific
approval and clinical results remain unrun. Broader receipts remain superseded
for this target and retain their historical labels.

No new source-export or membership decision is required to proceed under the
agreed rules. Within-list BMI/date uncertainty and same-day ties stay unresolved;
patients with only uncertain membership remain separate from confirmed patients.
The uncapped prior-measurement policy is retained. Any alternative tie resolution,
requirement for the historical global first flag, recency cap or different date
anchor would require an explicit new decision and dependent qualification.
Review/release and synchronize clean merged code before clinical estimation.
