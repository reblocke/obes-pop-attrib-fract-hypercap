# BMI-to-40 figure creation brief

## What it is

Three alternatives for the single ATS exhibit: compare the magnitude and
precision of nine model-standardized potential impact fractions across three
overlapping patient populations and three diagnostic definitions. Each cell
uses one selected encounter per patient and its own complete-case denominator.

## Title and framing

Model-standardized hypercapnia under a BMI-to-40 scenario. BMI >40 is set to
40 kg/m²; BMI ≤40 is unchanged. Artificial outputs have a prominent artificial
data banner; clinical drafts retain their review status.

## Layout

A is a compact forest with separate outcome, interval, numerical and diagnostic
columns. B places outcomes in three columns to compare frames within an outcome.
C uses a literal frame-by-outcome 3×3 interval matrix. Fixed frame order is BMI
≥40, ABG drawn, ABG-or-VBG drawn; outcome order is ICD, ABG, ABG-or-VBG.
A is provisionally preferred, with selection justified by actual exported views.

## Exact content

Use one frozen aggregate bundle, one common linear percentage scale including
zero/all finite endpoints, one-decimal PIF/95% interval labels and integer model
N. Retain negative PIFs and asymmetric intervals. Unknown outcomes, unresolved
indexes and counterfactual values outside the observed BMI range remain visible.
A no-change estimate is genuine zero; a nonestimable cell has no numeric mark.
The report supplies full reasons and full-precision standardized probabilities.
All captions explain index selection, overlapping frames, adjustment, empirical
covariates held fixed in intervals and association-based interpretation.

## Style

Use interval segments and diamonds, dark teal/gray with redundant text and a
zero reference. Frame/outcome identity does not depend on color. Align numerical
columns outside the interval coordinate system; do not expand axes for labels.
Use Arial with data labels at least 9 points at a 190-mm intended width. Candidate
comparison is about reading structure rather than cosmetic color variants.

## Output and verification

Editable R source, SVG/PDF masters and 300-dpi PNG/JPG exports at 190-mm width;
all candidates are 180-mm high. Individual native-size views and an
HTML/PDF comparison gallery accompany the report. Every export is bound to the
same aggregate CSV/bundle hash. Use the figure-and-medical-illustration-qc
creation and unified audit workflow, retaining stable A/B/C artifact IDs.

Test negative/wide/cross-zero intervals, genuine zero, nonestimable cells,
long diagnostic text, unknown outcomes and outside-range counts. Record actual
inspection separately from planned checks in each ignored run's QC manifest
and report. Artificial design validation is distinct from clinical qualification.
