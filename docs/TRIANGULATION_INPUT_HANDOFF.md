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

# Bind existing source to the common-index BMI ≥30 study

Use existing accepted products/receipts first. This handoff specifies study-specific mapping, not a default replacement export. Read [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [approved plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).

Provide a reviewed **version-3** manifest using `config/triangulation_input.example.json`. Bind `common_index_bmi_ge30_v1` and `first_2022_adult_ED_inpatient_BMI_ge30_before_gas_and_completeness`. Older population review cannot automatically qualify the corrected original-list target. Authenticate the exact producer, variant/conversion, original-key crosswalk and input/evidence hashes.

Confirmed 2026-10-15: new clinical inputs also bind `unadjusted_pco2_v1` and the exact policy object in hashed JSON field evidence. Use ordinary specimen-authenticated gases, strict arterial 5–200 and venous 10–250 mm Hg validity screens, explicit units and captured-absence ICD negatives only with complete available extraction. Temperature-adjusted records are audited outside primary outcomes. The preparation command writes typed input/evidence plus a pending manifest; it does not confer acceptance. See [the Mini handoff](CLINICAL_RUN_HANDOFF.md) for preparation, review, preflight, execution and saved-run commands.

The original-list source route uses [schema-2 preparation configuration](../config/common_index_mapping.example.json) and the separately named upstream `calendar_encounter_covariates_v1` product. The active mapper pin is merged `751d794e0a277f72ced2e2b5b48246858f4dcf9b`, paired with its exact module hashes; historical `72c91a2` products retain their original child source and runtime as described in the [pin-adoption handoff](CLINICAL_RUN_HANDOFF.md). It binds `available_encounter_or_prior_bmi_v1` and exact BMI policy evidence. Missing BMI after completed search is a counted exclusion; incomplete/ambiguous evidence stays unresolved. Inherited float16/CSV numeric transport and Stata float32 BMI storage are retained. No statistical BMI imputation is used.

For large sources, preparation selects indexes in bounded whole-patient partitions using the same R helper, before extracting gases or dropping incomplete adjustment values. The private typed input contains resolved original indexes; `selection-evidence.json` retains the original cohort/scope census and is hash-bound in the manifest. `index_preselected=true` requires this evidence and exact denominator reconciliation. Independent SQL qualification reconstructs index selection from the full mapped source. Historical inputs without this evidence retain their original route/policy.

| Requirement | Smallest existing-source action |
| --- | --- |
| All candidate encounters and original chronology | Prefer accepted FULL_DATA/pre-screen products and canonical captured encounter access; reconcile intended 2022 adult ED/inpatient BMI ≥30 candidates, including patients without gases and uncertain earlier BMI/date evidence. |
| BMI/adjustment | Preserve inherited BMI calculation, numeric precision and adjustment coding. The separate available-BMI product evaluates recorded/prior measurements and start-year age relative to each candidate; historical products keep their original anchor. Review timing/units/dictionaries and actual coverage; no unreviewed baseline or statistical imputation. |
| Gas evidence | Use exact arterial/venous raw selectors without syndrome-positive filtering; inspect normal/boundary/positive/unusable records, units, valid maxima and original-encounter attribution. Keep temperature-adjusted concepts distinct. |
| Testing/availability states | Usable measurements establish outcome observation. Distinguish confirmed testing with unusable results, no captured evidence and unknown capture where records support it; result-derived flags cannot establish performed testing by name alone. |
| ICD capture | Preserve all five codes including E66.2. Authenticate captured absence versus unknown; matched comparisons require known coding and their own qualifying gas, not both specimens. |
| Optional timing | Map separate arterial/venous start-calendar-day maxima/availability from dated records. Do not infer elapsed hours, pair pH or acquire timestamps for this definition. |

All seven primary review gates require identity-bound source evidence. The timing module may be pending with no mapped columns; its positions are unassessed, not measured zeros. Qualified values require their own evidence/hash and cannot exceed encounter-wide maxima. Schemas/hashes verify declarations, not their scientific truth.

```bash
make triangulation-preflight INPUT="/explicit/input.rds"
make triangulation-preflight INPUT="/explicit/input.rds" MANIFEST="/reviewed/v3.json"
make triangulation-render INPUT="/accepted/input.rds" MANIFEST="/reviewed/v3.json"
```

The original local RDS remains a historical comparator. The earlier broader mapping and its preflight are superseded; corrected original-list qualification and preflight pass on the Mini. The separately named automated-reviewed manifest and source-freeze receipt retain explicit limitations and human-review status. Do not apply those labels to the historical RDS. Clinical models require clean merged code; the current implementation branches are not yet merged. Retain within-list index uncertainty and the approved uncapped measurement-recency policy before fitting. No replacement export or external message is required by the completed source checks.
