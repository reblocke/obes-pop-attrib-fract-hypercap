# Map the existing accepted source to the primary BMI-shift analysis

Use the existing accepted products first. Read [the bounded assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [the approved plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md). Current upstream acceptance supersedes the stale local failed-build handoff. This note requests a study-specific binding/mapping, not a replacement export by default.

Provide a version-2 study manifest referencing existing identity-bound lineage, population and field-review evidence. The template is `config/triangulation_input.example.json`; all pending review declarations must be replaced from actual evidence. Accepted receipt bytes and source products are not available on the current machine; the local RDS alone does not authenticate its producer or semantics.

| Required mapping | Existing route / verification |
| --- | --- |
| Original keys, encounter dates/settings and chronology | Reuse accepted original-key products/crosswalks. Reconcile all required source candidate encounters and unresolved starts before frame-specific index selection. |
| Derived BMI, age, sex, race/ethnicity and region | Reuse the unchanged legacy derivations and reviewed code dictionaries; verify coverage of the actual study population. |
| Arterial/venous testing | Authenticate confirmed testing independently of numeric-result availability using existing raw evidence and capture states. Legacy result-derived flags cannot simply be renamed. |
| Encounter-wide PCO₂ | Use reviewed exact-code raw selection without syndrome-positive catalog filters; verify units, arterial/venous designation, valid maxima and encounter attribution. No pH/sample pairing is required. |
| Five-code ICD composite | J96.02/J96.12/J96.22/J96.92/E66.2; distinguish a captured absence of the composite from unknown diagnosis capture. |
| Optional qualified calendar-day module | Separate `abg_pco2_index_day`, `vbg_pco2_index_day`, `abg_index_day_available`, `vbg_index_day_available`, based on collection date equal to encounter-start date. No usable early result remains unknown. |

Qualify all primary requirements. If calendar-day evidence is not yet mapped, declare `index_day.status="pending"` with no mapped early columns. The nine primary analyses may proceed; the six sensitivity rows retain missing estimates/counts and explicit source-pending status. Qualified early values require their own evidence-file/hash binding and cannot exceed the encounter-wide maxima.

```bash
make triangulation-preflight INPUT="/explicit/input.rds"
make triangulation-preflight INPUT="/explicit/input.rds" MANIFEST="/reviewed/v2.json"
make triangulation-render INPUT="/accepted/input.rds" MANIFEST="/reviewed/v2.json"
```

Schema and file hashes authenticate declared inputs, not scientific truth. Retain actual source comparisons and reviewer evidence. Request new upstream work only when existing accepted products cannot resolve a demonstrated gap. This is a saved handoff, not an external message.
