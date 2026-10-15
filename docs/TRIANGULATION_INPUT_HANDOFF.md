# Bind existing source to the common-index BMI ≥30 study

Use existing accepted products/receipts first. This handoff specifies study-specific mapping, not a default replacement export. Read [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [approved plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).

Provide a reviewed **version-3** manifest using `config/triangulation_input.example.json`. Bind `common_index_bmi_ge30_v1` and `first_2022_adult_ED_inpatient_BMI_ge30_before_gas_and_completeness`. Old version-2 population review cannot automatically qualify the expanded target. Authenticate the exact producer, variant/conversion, original-key crosswalk and input/evidence hashes.

Confirmed 2026-10-15: new clinical inputs also bind `unadjusted_pco2_v1` and the exact policy object in hashed JSON field evidence. Use ordinary specimen-authenticated gases, strict arterial 5–200 and venous 10–250 mm Hg validity screens, explicit units and captured-absence ICD negatives only with complete available extraction. Temperature-adjusted records are audited outside primary outcomes. The preparation command writes typed input/evidence plus a pending manifest; it does not confer acceptance. See [the Mini handoff](CLINICAL_RUN_HANDOFF.md) for preparation, review, preflight, execution and saved-run commands.

| Requirement | Smallest existing-source action |
| --- | --- |
| All candidate encounters and original chronology | Prefer accepted FULL_DATA/pre-screen products and canonical captured encounter access; reconcile intended 2022 adult ED/inpatient BMI ≥30 candidates, including patients without gases and uncertain earlier BMI/date evidence. |
| Legacy BMI/adjustment | Carry approved derived BMI, age, sex, race/ethnicity and region unchanged. Review timing/units/dictionaries and actual coverage; do not substitute recorded BMI or reconstruct an unreviewed baseline. |
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

The existing local RDS and acceptance receipts remain unbound. Clinical models must not run until this use/snapshot qualifies. Request upstream work only for a demonstrated unsupported field or population gap. No external message has been sent by saving this handoff.
