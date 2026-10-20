# Paired-ABG acidemia supplement

Approved implementation scope: 2026-10-20; baseline `b93c8e3`. This adds a
same-sample secondary analysis, not a replacement for the established results.
The main B/F2 figures and original one-unit PIF remain unchanged.

## Source gate and derivation

Paired means ordinary arterial PCO₂ and pH from one authenticated blood sample.
Use existing original keys and qualified readers. A source-scoped specimen,
accession or one-collection panel identifier must establish linkage. Generic
orders, encounter/date coincidence, nearest time, row order and max-CO₂/min-pH
combinations cannot establish a pair. Date-only sources with no sample identifiers
are unavailable for this analysis, even when both analytes are recorded.

`make enrich-paired-abg SOURCE_CONFIG=... INPUT=... MANIFEST=... OUTPUT=...`
uses a fresh private directory. Its original schema-4 input and evidence remain
immutable. The new schema-4 input adds a version-1 pairing module and hashes its
feasibility/policy record. The source configuration may reference a reviewed,
hashed `paired_abg_policy` JSON; the example is intentionally unqualified.
The inherited arterial pH screen is 6.5<pH<7.8, but applicability and sample-link
semantics must be authenticated before enabling clinical modeling. Source values
are evaluated before display rounding; legacy float16 summaries cannot replace
raw sample values. Ordinary PCO₂ remains 5<PCO₂<200 mm Hg.

Deduplicate representations of the same specimen/analyte. Only documented
correction/version authority can resolve conflicting values; otherwise exclude
the conflicting pair and retain its audit state. Different collection dates under
a purported single-collection ID are conflicting. Other valid pairs at that
index remain usable. Unpaired hypercapnic records remain in the original outcome.

For every index with valid pairs, compute `any(PCO₂>=45)` and
`any(PCO₂>=45 AND pH<7.35)` over the identical valid samples. No valid pair means
unknown endpoints. Zero means not documented among evaluable pairs. pH=7.35
is not acidemic. Lower-CO₂ qualifying pairs count even if the maximum-CO₂ pair
is not acidemic. Source unavailable, assessed no pair, unresolved and valid pair
are distinct states; unavailable counts are never fabricated as zero.

## Models and outputs

Schema 8 / `bmi_hypercapnia_rfs_curve_audit_v3` adds exactly:

- `primary::paired_abg/encounter/hypercapnia/spline`
- `primary::paired_abg/encounter/acidemic_hypercapnia/spline`

Both use the covariate-complete primary fixed indexes with a valid pair, identical
patients/reference rows, inherited adjustment, and the saved primary numeric
spline basis. No additional availability regression, PIF, linear, calendar-day,
VBG-acidemia or supporting-population duplicate is added. All existing analyses
remain registered and unchanged. Unsupported/disabled positions remain visible.
Corrupt supplied input/evidence fails validation; absence of a pairing module
does not prevent base analysis. Old bundles are not migrated or relabeled.

The existing ledger holds paired/unpaired population counts, availability by BMI,
age, demographics and setting, source measurement audits, and the four-stage
original/paired-patient/paired-sample/acidemia reconciliation. Complete model
outputs and pointwise probability intervals use the existing numerical methods.
The BMI 45-versus-40 contrast includes both component probability intervals,
the absolute difference and prevalence ratio. Unsupported contrasts stay missing.
Nested observed outcomes must reconcile; separately fitted curves may cross.
Every supported-grid crossing above numerical tolerance is recorded for scientific
review. Curves are never clipped or reordered and are not formally compared.

## Reporting and acceptance

The scientific report adds a focused subsection, count table and S1-paired-ABG
figure. Two curve panels share scales, denominators and intervals; the lower
panel shows the paired population's BMI counts. Complete covariance/diagnostics
remain in the audit. Acidemia does not establish acute respiratory failure;
absence does not establish compensation. Measurements may follow treatment.

Run `make test` and `make source-test PREP_PYTHON=...`. Source fixtures exercise
sample identity, thresholds, correction conflicts and partial pairing; an
independent regression oracle verifies saved curves and intervals. E2E verifies
original estimates, two extra positions, no supplemental PIF, artifact privacy,
complete rendering and unchanged source/hash guards. Actual native-size,
grayscale and assembled-page inspection is separate from automated tests.

Review and squash-merge code before clinical estimation on a clean Mini checkout.
If pairing qualifies, estimate once to a fresh run and reconcile original results.
If unavailable, publish the specific feasibility finding and unavailable
supplement; do not rerun established clinical models merely to produce empty
secondary estimates. Preserve the 2026-10-18 reading snapshot. No abstract draft
or submission is authorized by this supplement.


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
