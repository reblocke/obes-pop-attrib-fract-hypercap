# Primary input and historical data contracts

The primary patient-level analysis uses an explicit authenticated input plus the version-2 study manifest. Its required fields, optional calendar-day module and source-acceptance boundary are specified in [the saved plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md), [current decisions](DECISIONS.md), [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and `config/triangulation_input.example.json`.

Default render commands consume a selected saved aggregate RUN. They never use `data/raw/full_db.rds` as a fallback. Clinical estimation remains explicit and requires qualified primary source requirements. Calendar-day source may be pending, with six unassessed result positions; missing evidence cannot become zero.

Current upstream acceptance records are reused within their scope. A stale local failed-build handoff does not reopen that upstream task. The local RDS still needs a producer/variant/conversion binding and original-key/field mapping. Existing exact-code raw source selection can avoid syndrome-positive catalog filters; normal results alone do not prove complete frames. No pH pairing or medication-status evidence is required for this study.

Aggregate version-2 runs retain scenario/registry definitions, denominators, timing and BMI-bin diagnostics, source/input hashes and environment, with no identifiers/model rows/individual predictions. Version-1 results retain the historical BMI-to-40 definition and frozen rendering source. All run artifacts remain ignored.

The original data-management history below concerns the now archived R and preserved historical Stata tracks, not authority to execute the new primary analysis.

# Historical data management and analysis input

The [unchanged original R report](../archive/2026-10-13-bmi-to-40/reports/obesity_hrf_paf_analysis.qmd)
formerly loaded `data/raw/full_db.rds`, falling back to root `full_db.rds`.
Those paths are local/ignored. The [repaired historical R report](../archive/r/obesity_hrf_paf_analysis.qmd)
now requires an explicit input through `make legacy-r INPUT=...`; it has no
fallback. The primary patient-level workflow instead uses explicit input and
manifest paths for estimation, or an explicit saved RUN for rendering, as
described above. Restricted TriNetX data, row-level derivatives, render outputs
and machine-specific paths must stay out of Git and be handled under approved
access and release rules.

## Lineage boundary

`trinetx-preprocessing` is named in earlier instructions as the expected
upstream source. A candidate conversion route was subsequently found in the
shared analysis repository:
[`r/reports/90_stata_to_r.qmd`](https://github.com/reblocke/trinetx-hypercapnia-code/blob/d5d269168eafc7905c9238a5486fc03a62b55ec3/r/reports/90_stata_to_r.qmd).
It imports `full_db.dta`, converts labelled columns to factors, and writes
`full_db.rds`. This does not prove it produced the current local RDS.
The producer commit, original snapshot/conversion chain and RDS serialization
version for the local analysis-ready file remain unauthenticated. The new
triangulation preflight records input/schema hashes in ignored storage; those
hashes identify the inspected file but do not authenticate its lineage. A prior [worklog](../WORKLOG.md) records a successful local
read/render, but not these identities. Obtain the source and conversion chain
from the data steward; do not infer it from a matching filename or row count.

## Fields used by the historical R report

The [archived R QMD](../archive/r/obesity_hrf_paf_analysis.qmd) requires
`curr_bmi`, `niv_proc`, `imv_proc`, `highest_paco2`, `abg_ph`, `vbg_co2`,
`vbg_ph`, `age_at_encounter`, `sex`, `ethnicity`, and `has_j9612`, `has_j9622`,
`has_j9692`, `has_j9602`. It parses BMI as numeric kg/m²; PaCO₂ and VBG CO₂
are interpreted as mmHg, pH is unitless, age is years, and NIV/IMV labels
are converted to binary with unrecognized values left missing. Sex and
ethnicity become factors with explicit unknown levels. Gas-pair availability,
BMI availability and missingness enter attrition; missing gases are not a
negative HRF classification. The QMD does not require an identifier column or
assert unique encounters, and the source collection window is not established.
Refer to [analysis decisions](DECISIONS.md) for report-specific outcomes,
cutoffs and counterfactuals rather than replacing them with an upstream rule.

## Stata input and local evidence

The Stata runner accepts the approved `full_db.dta` through `STATA_DATA_PATH`,
defaulting to ignored `data/raw/full_db.dta`. It checks required columns before
the inherited analysis loads the file:

`OBESITY_rfs`, `bmi`, `age_at_encounter`, `sex`, `race_ethnicity`, `location`,
`hypercap_resp_failure`, `has_abg`, and `hypercap_on_abg`.

The inherited models expect numeric variables, with categorical codes/value
labels usable by Stata factor notation. No field is reconstructed or recoded
by the importer. The diagnosis composite includes four J96 codes and E66.2;
`hypercap_on_abg` comes from the upstream `paco2_flag`. Source labels alone do
not establish specimen identity or the claimed day-0 measurement window.
Confirm the source variant, producer, keys, units, label semantics, and timing
before a clinical run. Source compatibility checks do not authenticate a dataset.

Shared documentation describes `full_db.dta` as an enriched suspicion cohort,
not all acute-care encounters. The derived `bmi` uses current, prior, then
height/weight fallback; the R exposure is current BMI only. Neither the Stata
stage nor the R report verifies patient/encounter uniqueness or clusters its
uncertainty by patient. See the [comparison](ANALYSIS_COMPARISON.md).

All execution directories under `artifacts/stata/` and the local evidence
bundle under `artifacts/evidence/` are ignored. Invocation receipts may contain
restricted input paths and hashes; they remain local. Historical aggregate
figures/tables are copied byte-for-byte with an inventory, not regenerated.
Their producing input identities remain unverified. Raw logs and row-level
extracts are not added to shared documentation.

## Handoff

Before reproducing, verify the authorized file identity and schema against
the report's requirements, establish the permitted environment/storage and
output-release review, and use the README's render routes. The `renv-init`
target is a separate environment-construction step; routine rendering does not
snapshot packages. No data or environment reconstruction is certified by this
note.


## Patient-level triangulation input audit

The separate triangulation preflight reads an explicit RDS/DTA and exports
schema and aggregate characteristics without identifiers or model fitting.
The local RDS audit found candidate fields, but original-key provenance,
independent gas draws, specimen-specific encounter maxima and ICD-negative
capture remain unresolved. No clinical impact fractions were estimated.
See [the field-specific handoff](TRIANGULATION_INPUT_HANDOFF.md).

Clinical estimation requires an evidence-backed manifest; matching column names
or result-availability counts cannot supply missing semantics. The launcher then
estimates once and freezes an aggregate-only bundle. Subsequent report/figure
reviews validate saved hashes and do not reopen the clinical source.
