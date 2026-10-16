**Current workflow amendment — 2026-10-16 curve/audit refactor:** the original
selected encounter scope is retained. Prior passing original-list source checks
remain evidence for that scope; the earlier outside-list mapping gap is historical.
The new analysis additionally requires a hash-bound pre-index cohort-audit companion
from the existing mapped candidate covariates. The earlier selected-index input
alone cannot establish those stage distributions. New companion reconciliation and identity-bound preflight now pass on the Mini,
using the unchanged accepted input and a fresh private manifest. The independent
field comparison and current qualification-function hashes agree. Clinical model
execution remains unrun; human/scientific review is not asserted. Current commands are
`make prepare`, `make qualify`, `make preflight`, `make cohort-audit`, `make analyze`
and `make render RUN=...`; dated commands below describe superseded workflows.
The active plan and README define the current interface. Preserve existing inputs,
accepted products and human-review status.

**2026-10-16 correction:** use authenticated original FULL_DATA selected encounter membership, bound as `original_selected_encounters_v1`. Broader-history candidate qualification is superseded. Retain available current/prior/calculated BMI and the first BMI-eligible index within the original list; verify historical first flags separately. Fresh original-list mapping, preparation and all 30 independent source checks pass; identity-bound preflight passes with zero models fitted. See [the governing decision](DECISIONS.md#original-encounter-list-correction--confirmed-2026-10-16). No clinical models have run.

# Original-encounter mapping and qualification

Updated 2026-10-16. The corrected mapper restricts candidates to authenticated
original FULL_DATA ED/inpatient keys and verifies historical first flags. The
upstream available-BMI implementation remains unchanged at the reviewed pin;
shared preprocessing code/source are read-only. Fresh dependent qualification
passes all 30 source checks with zero disagreements. No clinical models have run.

## Superseded broader-population gap

The earlier mapping found source encounters outside historical compatibility
membership. That was a coverage gap only for the then-proposed broader target.
The owner has now confirmed the original selected encounter population, so those
outside-list keys are not missing candidates and do not require a new export or
broader mapping. Preserve the dated broader receipts as history, not acceptance
of this corrected scope. Available BMI still requires a completed source search
within original keys; absent usable BMI remains missing without imputation.

## Implemented corrective product

Existing captured records now produce a **separately named study-specific covariate mapping**, preserving the accepted FULL_DATA/AFTER_EXCLUSION bundles and original RDS unchanged. `encounters.calendar_covariates` supplies the producer/reader; downstream `make triangulation-map`, `triangulation-prepare` and `triangulation-qualify` bind its policy and hashes. See [the commands](../README.md#restricted-data-execution). This does not rebuild upstream source products or qualify the historical RDS under a new label.

- Supply exactly the authenticated original selected ED/inpatient keys, captured calendar starts with uncertainty, available BMI and age/sex/combined race-ethnicity/region. Preserve inherited adjustment derivations and apply [the clarified BMI hierarchy](DECISIONS.md#bmi-availability-and-missingness--clarified-2026-10-15): valid current BMI, then valid prior BMI, then calculation from observed height/weight. Record method, component dates, completed-versus-unresolved mapping and missingness reasons. No statistical BMI/covariate imputation.
- Original reason-for-suspicion membership is inherited, not recomputed. Retain within-list unresolved chronology/BMI and candidates without usable gases; do not add new gas-positivity, result-availability or model-completeness filters.
- Bind the mapping to actual producer/source/variant identities, dictionary, conversion history and a trusted acceptance receipt. Reconcile original-key coverage in both directions and explain every unsupported field or conflict. Do not silently broaden the meaning of the historical FULL_DATA variant.
- Retain all captured rows per original key for chronology/conflict audits. Original accepted setting determines cohort membership and requires matching captured setting evidence. Outside-list UNKNOWN/LAB/history/return keys cannot enter or block selection.
- Provide aggregate coverage/missingness/conflict checks and private keyed outputs through the existing owner-held handoff. Raw identifiers and source records stay outside Git and shared documents.

Reuse the approved legacy transformation where it implements the clarified rule. Its 50.1 recorded-BMI cutoff is explicitly attributed to TriNetX truncation in Stata and reproduced by the Python port; calculated BMI is not capped there. Only activate the proposed high-BMI retention through about 120 if source evidence establishes genuine noncensored values. Preserve accepted historical products and document any intended new-mapping differences. If a required derivation remains unsupported, report that exact field/timing gap. Genuine missing BMI after completed mapping is a limitation, not a demand to create or impute a value. Original selected membership is now explicitly approved; the broader candidate universe is superseded.

## Remaining qualification ledger

| Item | Current evidence and next action |
|---|---|
| Historical product lineage | Trusted receipt/reader/dictionary checks passed. A fresh full canonical hash completed with stable identity; new mapping and typed-input identities are recorded separately. |
| Original population | Exact original selected ED/inpatient keys are mapped before BMI/gas/completeness selection; independent qualification passes all 30 checks with zero disagreements. |
| Keys and chronology | Original keys are unique. Independent SQL reproduces R-selected indexes, unresolved indexes and date ties without a later substitute. Outside-list unknown settings no longer enter. Within-list chronology conflicts and same-day ties remain explicit. |
| BMI/adjustment | Actual units and vocabulary reviewed. Corrected float16/CSV → float32 → Stata-rounding order matches historical values when selected components agree. Remaining age differences reflect start-year versus historical qualifying-year anchoring; BMI timing is relative to each candidate, as approved. Genuine missing BMI remains missing. |
| Gas/testing/units/windows | Independent ordinary maxima, testing states and availability agree with the prepared input; source audits retain excluded adjusted, unspecified and unusable records. No legacy proxy substitution. |
| ICD capture | Inventoried captured extraction, code systems and independent five-code/captured-absence comparison pass. Captured absence does not establish complete clinical history. |
| Calendar day | Independent fixed-index start-day maxima/availability pass. The module is qualified; no timestamp acquisition or pH pairing is needed. |
| Mini environment | R dependency setup completed after owner authorization on 2026-10-15. All seven primary packages load using framework R 4.6.1 and the ignored project library; 24 shared and 14 common-index artificial check groups pass. System-library file hashes are unchanged. Activate the local environment as documented in the clinical handoff; a full Mini report render remains unverified. |

## Resume

The seven primary source gates and calendar-day module have automated passing evidence. The private automated-reviewed manifest passes preflight; the original pending manifest remains unchanged. Review [the actual choices](DECISIONS.md#remaining-source-related-choices--2026-10-16), especially unknown-setting attrition and prior measurement recency. The current conservative index and unrestricted prior-availability rules remain unchanged. Source qualification does not validate MAR/MNAR, model form or causal interpretation.

After code review/publication and a clean synchronized Mini checkout, follow [the clinical handoff](CLINICAL_RUN_HANDOFF.md) for preflight, one clinical estimation run, aggregate-only rerender and numerical/figure review. Rendering never supplies missing source acceptance or scientific review. Clinical artifacts remain private; no abstract submission is authorized by this handoff.
