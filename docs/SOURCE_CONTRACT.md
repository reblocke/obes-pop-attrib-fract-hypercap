# Source contract and restricted execution

This document covers the existing accepted source, not a request to recreate or
replace it. Scientific rules are in the [current guide](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).
Raw inputs, accepted products and prior bundles are immutable. Examples below use
placeholder paths and must not be mistaken for authenticated clinical inputs.

## Authoritative interfaces

| Contract | Authority |
|---|---|
| Original candidate membership | [Original-list reader](../scripts/original_encounter_population.py), accepted FULL_DATA receipt and original string keys |
| BMI hierarchy/transport | [BMI policy](../config/common_index_bmi_policy.json), reviewed mapped-candidate manifest |
| Ordinary gases and ICD capture | [Source policy](../config/common_index_source_policy.json) and hashed field evidence |
| Installed upstream reader identity | [Mapping profile](../config/common_index_mapping.example.json), exact revision/module hashes |
| Preparation inputs | [Mapped-source profile](../config/common_index_mapping.example.json) and [adapter](../scripts/prepare_common_index_input.py) |
| Historical RFS semantics | [RFS evidence example](../config/rfs_evidence.example.json), producer/acceptance receipts |
| Analysis input | [Input contract](../R/input_contract.R), schema-4 manifest and pre-index companion |

The active mapper profile binds merged upstream `751d794` with its exact module
hashes. Earlier accepted products retain their original `72c91a2` producer and
runtime identities. An active profile update does not reissue their acceptance.
Do not cross old/new revision/hash pairs or edit accepted manifests in place.
Use existing qualified installed readers from
[trinetx-preprocessing](https://github.com/reblocke/trinetx-preprocessing); do not
rebuild upstream data merely to rerender or refit an unchanged accepted input.

The recorded-BMI mask screen is inherited, not a demonstrated Python/Stata
mismatch. Current/prior recorded BMI uses 10<BMI<50.1; height/weight-derived BMI
has no corresponding 50.1 cap. Preserve the exact transport and rounding policy.
No authenticated noncensored high-BMI rule has replaced it. Prior measurements
have no recency cap; preserve dates privately and publish only aggregate lags.
Completed absence after searching available records is missing BMI, not failed
qualification; unavailable capture or conflicting relevant chronology is unresolved.

## Qualification evidence

A passing schema check alone does not authenticate a dataset. Bind the actual
input, source config, producer/variant/conversion, source receipt and policy hashes.
The evidence ledger must cover:

- Exact original encounter-key membership, duplicate/conflicting keys, captured
  start/settings, chronology and first-index selection. History may supply prior
  measurements but cannot add candidates. No later more complete index is promoted.
- Candidate-level BMI/adjustment mappings and their missingness, units, dictionaries
  and timing. The pre-index companion must reconcile candidate stages; a selected-
  index input alone cannot supply those distributions.
- Ordinary gas code/specimen/unit/window mappings and raw-source maxima, including
  normal, threshold-boundary, positive, unusable, adjusted and unspecified records.
  LOINC 11557-6 alone is unspecified blood. Use the explicit mm Hg/kPa mapping;
  missing/incompatible units are unusable unless authenticated metadata supplies them.
- Testing evidence distinct from usable results and no captured testing evidence;
  unavailable capture remains separately identifiable where supported.
- Complete available diagnosis capture for a negative five-code composite; no other
  diagnosis is required. Incomplete/unavailable capture remains unknown.
- Calendar-day recorded-result=start dates and maxima bounded by encounter maxima;
  unavailable evidence leaves sensitivities pending without invalidating qualified
  encounter-wide primary outcomes.
- RFS metadata original-key joins, zero/missing semantics and exact preservation
  of prior clinical fields/indexes. Never reconstruct flags from final BMI or
  current gas/outcome evidence.

Do not invent reviewer approval. Automated source comparison, owner acceptance,
execution, numerical review, visual review and investigator scientific review
are distinct states. A failed gate produces a specific unresolved item and blocks
unsupported inference, rather than silently narrowing the cohort or substituting
legacy proxies.

## Commands

Clinical estimation requires a clean merged Mini checkout matching `origin/main`.
Before remote writes, check active jobs/worktrees and avoid overlapping changes.
Use the existing isolated runtime through `PREP_PYTHON` and its documented R
activation; local runtime paths are private and are not installed by these commands.

Only when preparing a new source product, use a reviewed source configuration and
fresh destinations. Existing accepted products do not need regeneration:

```bash
make map PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-mapping.json" OUTPUT="/private/fresh-mapping"
make prepare PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" OUTPUT="/private/fresh-prepared"
make qualify PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" \
  PREPARED="/private/fresh-prepared" OUTPUT="/private/fresh-qualification"
```

The preparation stage does not itself approve its generated pending manifest.
Complete it only from the reviewed qualification evidence. For the RFS analysis,
enrich the qualified input using accepted original metadata and its prior run:

```bash
make enrich-rfs PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" \
  INPUT="/private/prior-input.rds" MANIFEST="/private/prior-manifest.json" \
  PRIOR_RUN="/private/prior-aggregate-run" \
  RFS_EVIDENCE="/private/authenticated-rfs-evidence.json" \
  OUTPUT="/private/fresh-rfs-input"
make preflight INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make cohort-audit INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make analyze INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
```

Preserve the printed run directory. Presentation revisions use `make render RUN=...`
only. An estimation/source correction requires fresh qualification as applicable
and a new run; retain all previous evidence.

## Current evidence and limits

The original-list mapping, first-index/field reconciliation and metadata-qualified
schema-4 input have accepted evidence. The schema-7 clinical run completed from
merged `043fea6` on 2026-10-17 with unchanged input/evidence identities and retained
primary/supporting results. Exact private paths, hashes and review scopes live in
ignored release storage and `WORKLOG.md`; no new export is indicated by this
software cleanup. The original broader-history UNKNOWN-setting blocker is retired
because those visits are outside the approved candidate list.

Historical exact RFS extraction thresholds/windows and individual obesity triggers
are not fully authenticated from current defaults. Sparse residual gases in
obesity-only membership remain visible and unadjudicated. Additional cross-project
key decomposition and the previously noted historical diagram discrepancy remain
unassessed. Prior-measurement age, selection/measurement mechanisms and causal
interpretation remain scientific limitations after source acceptance.

Keep patient identifiers, exact individual dates, raw records, row-level derivations,
model frames and individual predictions in protected execution only. On 2026-10-18
the owner clarified that reports, figures and aggregate result tables may be
included in Git and shared as analysis outputs. Local source-access details,
credentials and patient-level evidence remain excluded. The blanket ignore rule
for local runs is not a restriction on versioning aggregate outputs. This permission
does not authorize abstract submission or imply coauthor approval.

The [versioned reading snapshot](../results/2026-10-18/README.md) contains the
clinical reports, selected figures and complete aggregate tables. Its manifest
records original bundle/review identities without source-access paths or patient
records. This packages existing results; it does not requalify inputs or rerun
estimation. Private input and execution receipts remain outside Git.

## Optional same-sample arterial supplement

The [paired-ABG extension](PAIRED_ABG_SUPPLEMENT.md) uses the same accepted source
and a fresh additive input. The versioned pairing evidence binds original input,
manifest, canonical source and reviewed policy. Existing source acceptance does
not establish same-sample linkage. Raw pair identifiers, dates and row-level
evidence stay private; only counts, policy and feasibility findings are shared.
The pinned upstream audit reports date-only records and absent specimen/panel
links in its historical snapshot. Reconcile those receipts to the actual study
source before claiming availability. A missing module does not invalidate the
base analysis; a supplied corrupt module fails explicitly.


### 2026-10-20 accepted-source feasibility

The actual accepted-source query covered 223,514 study-input encounter keys and
541,828 selected gas records: 192,909 ordinary arterial PCO₂ and 145,993 arterial
pH records. All queried records had date-only precision. Specimen, panel,
accession, collection-time and dedicated result_status/result_version fields had no
populated values. Generic status/order_status columns exist but do not have
authenticated correction semantics. Record counts are not distinct patient or draw counts.
Same-sample linkage is therefore unavailable, not an assessed zero-pair result.
No clinical supplemental models are fitted; no approximate pairing is adopted.
The existing clinical snapshot and B/F2 remain unchanged. See the
[separate feasibility report](../results/2026-10-20-paired-abg/README.md).

## Recorded-day arterial co-occurrence

The [same-day supplement](SAME_DAY_ABG_SUPPLEMENT.md) supersedes the unavailable
same-sample runtime. Direct inspection of the original laboratory CSV header,
export manifest and dictionary confirmed no sample/panel/accession identifier;
`source_id` denotes provenance, and laboratory `date` is a recorded-result date.
This evidence supports recorded-day grouping, not a collection-time claim.
Use a fresh `same_day_arterial_cooccurrence_v1` enrichment and retain the original
input. Bind the exact accepted database, original input/manifest, recorded-date
semantics, arterial codes, explicit units and owner-approved 6.5<pH<7.8 bounds.
No upstream rebuild or replacement export is needed. The command is
`make enrich-same-day-abg SOURCE_CONFIG=... INPUT=... MANIFEST=... OUTPUT=...`.
Source values, dates and row identifiers stay private. Source qualification and
clinical results require separate evidence and run reconciliation.

The October 20 enrichment passed source qualification against the same accepted
database and original input. All original fields and 223,514 fixed indexes were
unchanged. All queried ordinary arterial PCO₂ and arterial pH records had reviewed
units and parseable recorded dates. There were 22,217 co-observed indexes overall
and 22,195 in the covariate-complete primary population. These are distinct
denominators. The fresh clinical run from merged `b89d485` completed and its
original estimates reconciled to the authenticated prior run within 1e-10.
The [supplement snapshot](../results/2026-10-20-same-day-abg/README.md) records
source, numerical and visual evidence separately; investigator approval remains
pending. No same-sample linkage has been recovered or inferred.

The legacy source-policy identifier uses the term `collection_date`; that stored
identifier remains unchanged to preserve input/receipt identities. The source
field it actually checks is the recorded-result date. This wording correction
does not change existing calendar-day selections or numerical results.

The joint-component update reuses this same qualified enrichment unchanged. Its
three mutually exclusive categories are derived from the authenticated nested
flags, with any same-day hypercapnia–acidemia event taking priority. No source
re-extraction or stronger temporal/specimen claim is introduced. The new model
requires a fresh aggregate run and numerical reconciliation, not a new raw export.
