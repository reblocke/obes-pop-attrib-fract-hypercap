# Figure design and review

The current all-valid-BMI analysis uses aggregate schema 13 / v8. Figures read
the saved aggregate bundle; rendering must not reopen clinical inputs or refit.
The scientific specification and saved configuration control definitions and
population identities. This document controls presentation and review scope.

## Comparisons to preserve

- **F1-B:** BMI–hypercapnia probability, usable-evidence availability and patient
  frequency across the observed BMI range. Mark BMI 30, retain pointwise intervals
  and local sparse-support warnings. A/C remain layout alternatives.
- **F2:** absolute observed/shifted burden on a common 0–1,000 scale beside signed
  original-BMI-band contributions. Print PIF, confidence limits and shifted share.
  BMI≤30 remains visible in baseline burden and contributes zero scenario change.
- **Same-day components:** a coherent stacked joint probability plus component
  curves on a common baseline, their pointwise intervals and population frequency.
  State “same recorded-day co-occurrence; not verified same-sample pairing.”
- **ICD components:** joint coding categories, component intervals, observed band
  proportions and the four-category sensitivity. Identify each model/reference
  denominator; coding does not establish physiological acidemia or compensation.
- **Flow and supporting figures:** distinguish records, encounters and patients;
  show the fixed-index RFS partition, nested BMI≥30 secondary and overlapping
  endpoint samples. Obesity-only remains descriptive audit material.

Show primary and BMI≥30-secondary counterparts separately, with comparable axes
where appropriate. Current-measurement and all-OBESITY-route sensitivities retain
their own labels and denominators. Never add component-specific PIFs or derive
paired burden from marginal curves multiplied by BMI density.

## Export and verification

Apply `figure-and-medical-illustration-qc`. Use 190-mm review width, data labels
at least 9 points, direct labels, grayscale-safe distinctions, self-contained
captions and alt text. Keep editable R, SVG/PDF masters and 300-dpi PNG/JPG
exports for the scientific candidates. Preserve zero, negative contributions,
all finite interval limits and explicit unavailable states. Print confidence
limits beside estimated percentages; descriptive shares are labeled separately.

Check coordinates, intervals, denominators and covariance against the same saved
tables. `make test` exercises artificial analysis-to-report integration and
adverse cases. Clinical numerical review is separate. Check all PDF pages and
masters for bounds, broken symbols and text collisions; inspect native-size
scientific figures in color/grayscale and assembled scientific pages. Inspect
representative audit templates and record the exact scope. Automated geometry
does not imply manual reading of every audit page.

Retain a source-bound QC manifest, inspection receipt, gallery and captioned
figure booklet. Required missing figures must fail the render. Report source/hash
verification, numerical checks, actual visual inspection and investigator approval
as separate states. New results do not inherit historical figure approval.

## Historical selection

The owner selected B/F2 for the October 18 results. B remains the preferred
relationship layout; the earlier A recommendation and schema-7 review are
historical. Their original exports and receipts remain in
[the October 18 snapshot](../results/2026-10-18/README.md). Later same-day and ICD
snapshots retain their own manifests and review states; see
[the reading guide](LLM_GUIDE.json). Historical files are not relabeled or replaced.

The current verified packet is linked from [README](../README.md). Its review
receipt documents actual inspection and remaining investigator decisions.
No figure selection authorizes abstract drafting or submission.
