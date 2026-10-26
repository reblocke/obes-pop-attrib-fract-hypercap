# Source contract and restricted execution

Use the existing accepted source and mapped candidates; no replacement export,
upstream rebuild or dependency installation is implied. Scientific definitions
are in [the specification](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md). Historical inputs,
source products, receipts and published snapshots remain immutable.

## Evidence and identity

| Requirement | Evidence |
|---|---|
| Candidate membership | Authenticated original FULL_DATA ED/inpatient string keys, accepted receipt, original-list reader |
| BMI/covariates | Existing accepted calendar-covariate parquet, manifest, policy and dictionaries; all original candidates, not just former obese indexes |
| Original RFS | Six source-membership flags joined by original patient/encounter keys; hashed family semantics and producer evidence |
| Gas outcomes | Exact-code ordinary arterial/venous records, reviewed units, strict validity and encounter attribution |
| Recorded-day components | Arterial 2019-8 and pH 2744-1; authenticated result-date semantics and pH policy; independent unavailable status |
| ICD components | Five original code flags and complete/incomplete/unavailable capture; negative only with complete capture |
| Selected input | Schema 5, new all-valid-BMI selection and cohort companion, source/field/component hashes |

Pinned readers use the reviewed revision/module hashes in
[the mapping profile](../config/common_index_mapping.example.json). Earlier products
retain their producer identities; a newer reader does not reissue acceptance.
Do not infer compatibility from matching column names.

Recorded current/prior BMI retains 10<BMI<50.1 masking screens; calculated BMI
has no corresponding 50.1 cap. Preserve hierarchy, rounding, observed height/weight
and transport. No statistical imputation, new BMI cap or recency threshold. Missing
BMI after a complete search is an exclusion; unavailable evidence or unresolved
chronology can block an index. History is evidence, not extra candidate encounters.

Select the first adult 2022 ED/inpatient encounter with any valid BMI once.
RFS and outcome fields cannot promote a later encounter. The nested BMI≥30
secondary is filtered at this index. Authenticate new indexes against accepted
source keys and evidence, not an identical prior clinical run.

## Encounter setting as adjustment

The setting-adjusted analysis reuses schema-5 `encounter_type` from the authenticated
original encounter list: EMER emergency and IMP inpatient. It is also an additive
categorical adjustment in every model, with EMER reference. Recheck input/evidence
hashes and setting completeness before each future run; the adjustment change alone
does not require new preparation or upstream data. Historical source receipts
retain their actual producer and review identities.

## Usable evidence versus documented testing

F1-main ascertainment uses the existing saved `observation/abg/encounter` and `observation/vbg/encounter` models. Their binary endpoints are availability of at least one ordinary unadjusted, specimen-authenticated numeric PCO₂ result after reviewed unit conversion and strict 5<ABG<200 or 10<VBG<250 mm Hg screening. Normal and elevated results qualify, without pH or encounter-start-day restrictions. Temperature-adjusted, nonnumeric, conflicting/ambiguous-specimen, unsupported-unit and out-of-range records do not establish usable evidence. These endpoints differ from `has_abg`/`has_vbg` captured numeric testing evidence and do not establish all orders or draws. Absence of usable captured evidence is not a clinical negative.

## One preparation transaction

`make prepare` uses [prepare_common_index_input.py](../scripts/prepare_common_index_input.py)
and [source_components.py](../scripts/source_components.py), replacing the former
three enrichment launchers. Existing classification functions retain their threshold,
duplicate and missingness semantics. The input contains original metadata and BMI
provenance; only aggregate lags and profiles may leave protected execution.

The private source configuration binds canonical database/sidecar, mapped product,
accepted FULL_DATA product, reader identities, reviewed code/unit/capture mappings,
`rfs_evidence` (path/hash), and optional `same_day_abg_policy` (path/hash). Missing
same-day policy produces explicit unavailable component evidence, never negatives.
ICD code flags come from the same diagnosis stream as the binary composite.

Preparation emits a new RDS, private CSV, full pre-index companion, selection and
source receipts, component evidence files and a **pending** schema-5 manifest.
Each component binds the resulting input SHA-256, selection-evidence SHA-256,
canonical source, policy and adapter identities. Conflicting duplicate source IDs,
uncovered keys, different-source evidence and corrupted hashes fail explicitly.
No source eligibility or investigator approval is invented by successful preparation.

## Qualification and execution

Before remote writes, inspect active jobs/leases and use a fresh private directory.
Use existing isolated R/Python environments. Example paths below are placeholders:

```bash
make prepare PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" OUTPUT="/private/fresh-input"
make qualify PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" \
  PREPARED="/private/fresh-input" OUTPUT="/private/fresh-qualification"
make preflight INPUT="/private/fresh-input/study-input.rds" \
  MANIFEST="/private/fresh-input/reviewed-manifest.json"
make analyze INPUT="/private/fresh-input/study-input.rds" \
  MANIFEST="/private/fresh-input/reviewed-manifest.json"
make render RUN="artifacts/triangulation/<exact-saved-run>"
```

The independent qualifier reconciles original membership, all-BMI chronology,
BMI/covariates, RFS/raw-demographic joins, gas maxima/units/windows, code flags and
recorded-day outcomes. Review normal, boundary, adjusted, unspecified and unusable
source evidence. Ordinary PCO₂ is primary; 11557-6 alone is unspecified specimen.
Capture completeness permits an ICD-negative without another diagnosis. The seven
primary gates must pass before the pending manifest is accepted; retain automated
results and human/scientific review as distinct records. A demonstrated discrepancy
requires a specific correction or decision, not silent exclusion or legacy substitution.

Clinical estimation requires clean merged Mini code matching `origin/main` and a
qualified manifest. Run once into a new saved directory. Render takes only that
aggregate bundle; no source reads/refits. A render repair reuses the run; a source
or estimator correction requires a new run. `make map` remains available only when
an actual mapping gap is demonstrated; the approved update reuses the existing map.

## Reconciliation, privacy and limits

Compare new and prior inputs by original keys separately from qualification:
new patients, old-only patients, changed indexes, changed RFS assignments and
unchanged-key field stability. Expected refit changes are not source discrepancies.
Preserve completed-missing/unresolved counts, candidate profiles and sparse support.
Do not hard-code a historical cohort size as a new invariant.

Keep identifiers, dates, raw measurements, row-level derivations, model frames,
individual predictions, credentials and exact source-access details private. The
owner permits reports, figures and aggregate tables in Git and collaborator
material. Local run bundles stay ignored; published reading snapshots are not
runnable bundles. Verify their manifests before numerical claims.

Historical source thresholds/trigger details remain imperfectly authenticated;
RFS zero is not complete clinical absence. Outcome-dependent entry, selective gas
measurement, prior BMI, diagnostic incorporation and confounding remain limitations.
Numerical/source/visual verification does not establish causal identification or
investigator approval. Current clinical execution status is in [WORKLOG.md](../WORKLOG.md).

## Current qualified execution

The [all-valid-BMI snapshot](../results/2026-10-24-all-bmi/README.md) binds the
qualified input and source receipts to merged code `75e55ee` and the saved run.
Its [source qualification](../results/2026-10-24-all-bmi/verification/qualification.json)
contains all 46 discrepancy checks and unresolved-index counts. The separate
acceptance, numerical and visual receipts distinguish their review scopes.
Historical comparison is retained alongside the exact numeric-transport correction;
no new scientific BMI rule or upstream export was introduced. This qualification
does not authorize inference to untested patients or establish causal identification.

## Encounter-setting release evidence — 2026-10-26

The [schema-14 reading packet](../results/2026-10-26-setting-adjusted/README.md)
reuses the exact accepted all-BMI schema-5 input and reviewed manifest. All 15
referenced evidence hashes were reauthenticated; fresh preflight reproduced all
160 shared cohort nodes. No preparation, new extraction or upstream rebuild was
performed. The 380,206-patient primary reference has 156,509 EMER and 223,697 IMP
encounters, with no missing setting. All model/reference samples, event counts and
numeric spline bases match the earlier run. The packet distinguishes reused
source acceptance, fresh identity/preflight verification, clinical execution,
numerical review and scoped visual review from investigator approval.
