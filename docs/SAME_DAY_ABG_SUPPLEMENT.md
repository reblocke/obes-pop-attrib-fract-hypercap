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

## Joint components and stacked curves

The current runtime supersedes the historical two binary supplemental fits with one
unpenalized three-category multinomial spline (`nnet::multinom`, no penalty,
1,000 maximum iterations). The original source flags/enrichment are unchanged.
Any documented hypercapnia–acidemia day takes priority. Categories are no
hypercapnia on co-observed days, hypercapnia without documented same-day acidemia,
and hypercapnia with same-day acidemia. No qualifying day remains unknown, not a
fourth modeled negative category. The reference outcome is no hypercapnia.

Use the same primary knots, covariates, fixed indexes and supplemental population.
Scale design columns internally for optimization, then report coefficients and
full cross-category covariance in the original design units. Check complete/quasi
multinomial separation before fitting and information rank/convergence afterward.
An absent category or failed model stays unavailable; no binary fallback.
All class probabilities are standardized over identical patients and sum to one;
the two hypercapnia probabilities sum to total hypercapnia. Pointwise logit-scale
probability intervals and signed contrast intervals use the full joint covariance,
conditional on the fixed basis and empirical reference. No PIF is added.

The full observed BMI range (0.25-unit grid plus observed endpoints) is the central
result. Keep 40–45 as a prespecified descriptive summary, and report every
supported five-unit interval anchored at multiples of five. Include both component
changes, ratios and the signed with-minus-without difference in changes with
intervals. Do not infer equal magnitudes from separate significance or interval
overlap. No multiplicity-adjusted or simultaneous inference is claimed.

S1 has stacked component probabilities, common-baseline component curves with
95% intervals, and an aligned BMI-frequency panel. With-acidemia is the lower
band; without documented same-day acidemia is the upper band's thickness. The
upper boundary is total hypercapnia, not the without-acidemia component. Faded
regions/dotted lines flag existing local sparsity thresholds separately by class;
the full observed range remains visible. Missing covariate levels remain in the
support audit. Captions retain the same-recorded-day/not-same-sample statement.

Runtime identity: aggregate schema 10 / `bmi_hypercapnia_rfs_curve_audit_v5`.
Input schema 4 and `same_day_arterial_cooccurrence_v1` remain unchanged. The
schema-9 reading packet linked below is immutable historical evidence, not the current
joint result. The new clinical run and figure approval remain pending until their
separate receipts are recorded. Primary models/PIFs and B/F2 remain unchanged.

## Verification and release

Record failure scenarios before production edits. Run `make test` and separate
`make source-test PREP_PYTHON=...`; independent raw-record cases establish same-
versus cross-date behavior, thresholds, missingness and record corruption. E2E
fits the joint likelihood independently, verifies shared references and unchanged
base estimates/PIFs, and renders all reports from aggregates. Inspect S1 at
190 mm, in grayscale and assembled reports; export R/SVG/PDF/300-dpi PNG/JPG.

Review, commit, push, PR and squash-merge before clinical estimation. On a clean
merged Mini checkout, check concurrent work, qualify new enrichment and run once
only when evidence passes. Compare the original clinical fields/indexes and
estimates with the authenticated prior run. Preserve all earlier artifacts.
Source qualification, numerical review, visual review and investigator approval
remain separate. Rendering does not provide scientific approval.

## Historical binary-model execution evidence

Software released in PR #19 at `b89d485`; qualified clinical execution completed
in `curve-analyze-20261020T174425-15236`. Both supplemental positions succeeded
with the shared N of 22,195. Original fields/indexes and primary numerical results
are preserved, with the latter reconciled at tolerance 1e-10. The
[separate reading packet](../results/2026-10-20-same-day-abg/README.md) contains
the integrated reports, S1 and complete aggregate tables. Its review receipts
separate source qualification, estimation, numerical verification, visual review
and pending investigator approval. The earlier snapshots remain immutable.
