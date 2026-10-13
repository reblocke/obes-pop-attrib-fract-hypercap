# Upstream handoff: patient-level BMI-to-40 triangulation

Clinical estimation is paused. The local RDS has been inspected for schema and
aggregate characteristics, but its producer/conversion lineage and required
semantics are not authenticated. The ignored preflight receipt records its exact
identity. No clinical models or impact fractions were calculated.

The agreed definitions remain fixed. Do not resolve this handoff by renaming
legacy proxies or filling manifest assertions without source evidence.

## Requested analysis-ready input and evidence

Provide an authenticated RDS or DTA plus the producer commit, source variant,
snapshot identity, conversion history and field dictionary. Preserve all source
encounters needed to select adults' first qualifying 2022 ED/inpatient encounter
within each frame. The study notebook must not reconstruct producer-owned fields.

| Field or requirement | Current audit finding | Required upstream handoff |
| --- | --- | --- |
| Original patient and encounter keys | Local `patient_id` is numeric; `encounter_id` is character. Original-key provenance is absent. The candidate producer replaces patient keys with numeric group codes. | Original string keys, or authenticated source/crosswalk evidence delivered as original keys in the analysis-ready input. Include key stability across source variants and duplicate/version handling. |
| Encounter date, age and setting | Local `encounter_date` is Date; age and setting fields exist. Their derivation and conversion remain unverified. | Encounter-start date/origin, age derivation, ED/inpatient code dictionary and chronology/version policy. Do not substitute `first_encounter` for frame-specific index selection. |
| Legacy derived BMI | Local `bmi` exists separately from `curr_bmi`. | Authenticate the existing current/prior/height-weight fallback derivation, kg/m² units, missingness and alignment to each encounter. Supply it unchanged. |
| Adjustment variables | Sex, combined race/ethnicity and region/location categories exist. | Reviewed source codes/labels and missingness matching the inherited Stata adjustment set, including explicit source "Unknown" categories versus missing values. |
| ABG/VBG drawn | Local flags are present; aggregate totals agree with corresponding nonmissing gas results. Candidate producer explicitly derives flags from nonmissing results. | Independent specimen-specific collection/draw evidence at each encounter, retaining draws without usable results and distinguishing no draw from unknown capture. Procedure-history fields alone are insufficient without completeness and encounter-window evidence. |
| Arterial PCO₂ maximum | Local `paco2` and `highest_paco2` exist. Candidate producer combines arterial concepts with specimen-unspecified blood CO₂. | Maximum valid arterial PCO₂ in mm Hg during the encounter, with specimen identity, units, validity rules and encounter attribution. Do not include unspecified blood measurements as arterial by default. |
| Venous PCO₂ maximum | Local `vbg_co2` and `highest_vbg_co2` are separate fields with different availability. | Maximum valid venous PCO₂ in mm Hg during the encounter, with the same specimen/window/validity evidence. A first or day-0 summary cannot silently replace an encounter maximum. |
| ICD composite and capture | Local composite has no missing values. Candidate producer returns zero when no component equals one, including all-missing evidence. | J96.02/J96.12/J96.22/J96.92/E66.2 at the selected encounter; capture evidence distinguishing documented code absence from unknown ascertainment. Deliver reviewed positive/negative/unknown coding. |

The local source has not been proven to originate from the candidate producer;
these producer findings identify risks requiring evidence, rather than prove
that every local field has those semantics. Matching filenames, labels, row
counts or availability totals cannot authenticate lineage.

## Inspected candidate source

Producer commit: `c857ee5c9bdb0ee8c96400937e2afd2480c80a61`.

- [Patient-key encoding and gas-availability flags](https://github.com/reblocke/trinetx-preprocessing/blob/c857ee5c9bdb0ee8c96400937e2afd2480c80a61/src/trinetx_preprocessing/encounters/legacy/pipeline.py).
- [Arterial-source composition and ICD indicator construction](https://github.com/reblocke/trinetx-preprocessing/blob/c857ee5c9bdb0ee8c96400937e2afd2480c80a61/src/trinetx_preprocessing/encounters/legacy/per_file_cleaning.py).
- [LOINC 11557-6: blood PCO₂](https://loinc.org/11557-6) versus
  [2019-8: arterial blood PCO₂](https://loinc.org/2019-8), checked 2026-10-13.
  An unspecified blood code alone does not identify the specimen as arterial.
- [Local lineage boundary](DATA_MANAGEMENT.md).

## Acceptance and next command

Complete `config/triangulation_input.local.json` only from inspected source
and actual review evidence. Retain the exact input/manifest hashes and review
receipt in ignored storage. The example manifest remains intentionally pending.

```bash
make triangulation-preflight INPUT="/explicit/source.rds"
make triangulation-render INPUT="/explicit/accepted.rds" MANIFEST="/explicit/reviewed.json"
```

Schema preflight never establishes scientific validity. If any required evidence
remains unavailable, retain this handoff and report the unresolved field; do not
fit a subset of clinical models as though the nine-cell workflow were qualified.
This is a saved request, not a message sent to a data steward.
