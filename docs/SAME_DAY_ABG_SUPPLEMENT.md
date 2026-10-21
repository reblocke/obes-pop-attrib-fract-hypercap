# Same-day arterial PCO₂/pH co-occurrence supplement

Owner-approved 2026-10-20. This replaces the inactive same-sample runtime with
recorded-day co-occurrence. The original [pairing feasibility](../results/2026-10-20-paired-abg/README.md)
and [clinical reading snapshot](../results/2026-10-18/README.md) remain immutable.
Primary populations, indexes, models, PIFs and selected B/F2 are unchanged.

## Definition and source

Use any recorded date within the existing index encounter containing at least
one valid ordinary arterial PCO₂ and one valid arterial pH. This is **same
recorded-day co-occurrence; not verified same-sample pairing**. The original
export dictionary defines the date when the result was recorded. It supplies
neither collection time nor a shared sample identifier. Do not describe this
as simultaneous physiology, elapsed 24 hours or verified collection-day pairing.

Use [LOINC 2019-8](https://loinc.org/2019-8), explicit reviewed mm Hg/kPa conversion and 5<PCO₂<200 mm Hg.
Arterial pH uses [LOINC 2744-1](https://loinc.org/2744-1), explicit pH/[pH] units and 6.5<pH<7.8. Classify
unrounded source values. Adjusted, venous and unspecified records are excluded.
Within each exact source/patient/encounter/date, derive:

- Hypercapnia on co-observed days: any valid PCO₂ ≥45 on a date with valid pH.
- Hypercapnia–acidemia co-occurrence: any such date also containing pH <7.35.

Values can come from different samples. Never combine different dates. Repeated
transport of the same source row is deduplicated; conflicting contents under
one row identity fail. Different values on a date are not specimen conflicts,
and no correction or latest-result authority is invented.

At least one usable co-observed date establishes evaluability. Other unusable,
undated or single-analyte records remain in the audit. Without a usable day,
endpoints remain unknown; distinguish no co-observed day, unresolved dates and
unavailable source. Negative means no documented positive among eligible days.

## Interface and models

`make enrich-same-day-abg SOURCE_CONFIG=... INPUT=... MANIFEST=... OUTPUT=...`
reads the immutable original schema-4 input and writes a fresh private additive
input, summary and hash-bound evidence. Use the [policy example](../config/same_day_abg_policy.example.json)
with authenticated export/date/code/unit evidence; placeholders are rejected.
The extension identity is `same_day_arterial_cooccurrence_v1` version 1. The
aggregate contract is schema 9, `bmi_hypercapnia_rfs_curve_audit_v4`.
Historical pairing bundles are not migrated or relabeled.

Exactly two secondary positions replace the unavailable pairing positions:

- `primary::same_day_abg/encounter/hypercapnia/spline`
- `primary::same_day_abg/encounter/hypercapnia_acidemia_cooccurrence/spline`

Both use identical complete-adjustment primary patients with a co-observed day,
the original primary numeric BMI basis, inherited covariates and a shared
supplemental reference. Retain curves, pointwise intervals, BMI 45-versus-40
contrasts with both probability intervals, complete coefficients/covariance,
diagnostics and failed positions. Do not add PIFs, observation regressions,
timing/linear duplicates or additional population models. Flag curve crossings;
do not clip them. No verified same-sample analysis is inferred from this module.

## Ledger and reports

Reconcile original arterial-evaluable patients → co-observed patients with their
original arterial outcome → the same patients restricted to co-observed dates
→ the same patients with same-date hypercapnia and acidemia. Retain counts and
Wilson intervals, stratified availability, usable/invalid/undated records,
single-analyte days and multiplicity. Distinguish patients, days and source rows;
reported source-row totals cover only assessed capture.

The scientific report contains a focused subsection, reconciliation table and
S1-same-day-ABG figure. Its two curves share axes and patients; BMI frequencies
appear below. Display N, events, pointwise 95% intervals and support warnings.
The complete audit retains all tables. Supplemental captions explicitly state
“same recorded-day co-occurrence; not verified same-sample pairing.” Findings
may span different samples or treatment periods and do not establish acute
respiratory failure or compensation. No abstract drafting is authorized.

## Verification and release

Record failure scenarios before production edits. Run `make test` and separate
`make source-test PREP_PYTHON=...`; independent raw-record cases establish same-
versus cross-date behavior, thresholds, missingness and record corruption. E2E
refits both models independently, verifies identical references and unchanged
base estimates/PIFs, and renders all reports from aggregates. Inspect S1 at
190 mm, in grayscale and assembled reports; export R/SVG/PDF/300-dpi PNG/JPG.

Review, commit, push, PR and squash-merge before clinical estimation. On a clean
merged Mini checkout, check concurrent work, qualify new enrichment and run once
only when evidence passes. Compare the original clinical fields/indexes and
estimates with the authenticated prior run. Preserve all earlier artifacts.
Source qualification, numerical review, visual review and investigator approval
remain separate. Rendering does not provide scientific approval.

## Execution evidence

Software released in PR #19 at `b89d485`; qualified clinical execution completed
in `curve-analyze-20261020T174425-15236`. Both supplemental positions succeeded
with the shared N of 22,195. Original fields/indexes and primary numerical results
are preserved, with the latter reconciled at tolerance 1e-10. The
[separate reading packet](../results/2026-10-20-same-day-abg/README.md) contains
the integrated reports, S1 and complete aggregate tables. Its review receipts
separate source qualification, estimation, numerical verification, visual review
and pending investigator approval. The earlier snapshots remain immutable.
