# One-unit BMI shift: figure creation brief

## What it is

Three scientific exhibit alternatives for the primary patient-level study. Compare cell-specific model-standardized PIF magnitudes/precision and ascertainment changes across intentionally different sampling frames. Fifteen fixed identities comprise nine encounter primary and six index-calendar-day gas sensitivities. Do not sort by significance or pool estimates.

## Title and framing

**Modeled hypercapnia under a one-unit BMI reduction above 30**. Eligibility uses observed BMI >30; subtract exactly one with no floor. BMI ≤30 remains unchanged. The full cell-specific model sample supplies both prediction averages; shifted percentages explain how much of each population contributes.

## Layout

- A — preferred forest/table: three frame blocks and five rows each; one quantitative axis with separate PIF/CI and model-N/shifted columns.
- B — outcome-first panels: three outcome columns, comparing frames and paired gas windows. ICD has one window only.
- C — frame-by-outcome matrix: frame rows and outcome columns, with paired timing estimates in the gas cells.

Keep frame order BMI ≥40, ABG obtained, either gas obtained. Within frame use ICD encounter, ABG encounter/day, either gas encounter/day. Figures preserve the same saved values and limits. Increased height prevents fifteen-row typography from colliding; do not force the old 180-mm height.

## Exact content

PIF percentage, asymmetric pointwise delta-method 95% CI, model N and % with observed BMI >30. Numeric precision distinguishes small nonzero values from genuine zero. Zero/reference and every finite endpoint remain on a shared linear scale. Pending source has no estimates or measured model N. Nonestimable cells retain an empty quantitative position and an explanatory status. Detailed outcome/index missingness, BMI support and timing transitions stay in supporting tables.

Caption: first qualifying 2022 adult ED/inpatient index per frame; overlapping frames and different indexes; same complete cases in paired predictions; linear BMI/age, sex, race/ethnicity, region adjustment; fixed-covariate model uncertainty; available-gas limitations, exact thresholds and ICD codes. The contrast does not establish causal prevention or an incidence effect.

## Style and rationale

Filled/open points and direct window labels identify encounter/day ascertainment in grayscale. Related comparisons share axes. Numerical labels lie outside the quantitative axis. Frame headers identify population, while count/shift columns facilitate retrieval. The near-zero tick labels are spaced on rounded bounds rather than inserting a long endpoint label next to zero.

Default exports are **190 ×275 mm**, PNG/JPG at 300 dpi and SVG/PDF masters, with editable R source. Data labels are at least 9.5 pt; report figures use a 270-mm device height and 96% of a 190-mm A4 text area to preserve readability with the page caption. Footnotes remain distinct from numerical labels.

## Output and verification

Use `figure-and-medical-illustration-qc` creation/forest/unified workflows. Compare all three against `figure_display_ledger.csv`, inspect individual native-size vector/raster exports and every report page, and review grayscale. Stress negative/cross-zero/wide intervals, source-pending and model failures, genuine zero, tiny nonzero values, large N and long explanations. Record clipping, collisions, symbols, interval visibility, actual font/dimensions, quantity agreement and export identities in the QC manifest/receipt. Separate completed checks from planned checks and record optional accessibility coverage limits.

Saved runs and fresh review directories retain their prior exports. Version-1 BMI-to-40 reviews use the frozen historical sources and keep their original definitions/dimensions. Artificial figures are prominently labeled and supply no clinical results. Publication selection follows actual clinical estimates and author review.
