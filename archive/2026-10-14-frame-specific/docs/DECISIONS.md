# Analysis decisions

## Primary analysis authority — confirmed 2026-10-13

`reports/bmi_hypercapnia_triangulation.qmd` is now the primary R/Quarto analysis. Default `make render`, `render-html` and `render-pdf` render an explicitly selected saved aggregate RUN. Estimation remains explicit through the dedicated triangulation command. The [saved plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) defines scientific and implementation authority.

**Current scenario:** reduce BMI by exactly 1 kg/m² for patients with observed BMI >30; BMI ≤30 remains unchanged. No floor is imposed at 30. Thus 30.2 becomes 29.2, 40 becomes 39, and 30 stays 30. Shift eligibility, sampling frames, selected encounters and adjustment values use observed data and remain fixed during prediction.

This supersedes the October 13 BMI-to-40 primary decision. The earlier unrestricted BMI-minus-one proposal was also superseded; the current BMI >30 eligibility rule distinguishes this new decision. Original dated plans, decisions, estimator and renderer remain preserved in the hashed `archive/2026-10-13-bmi-to-40/` snapshot. Existing numerical results are not relabeled or transformed into the new scenario.

## Patient-level sampling and outcomes

- Population: adults aged ≥18, emergency/inpatient encounters starting in 2022, within the authenticated captured source.
- Three intentionally different, overlapping frames: BMI ≥40; confirmed ABG testing at any BMI; confirmed ABG or VBG testing at any BMI. Differences in their populations and first indexes are part of the estimands, not a defect to remove.
- Select the first qualifying encounter separately within each frame before checking outcome or covariate completeness. Conflicts, earliest-date ties and potentially earlier qualifying encounters remain unresolved; no later, more complete encounter is substituted.
- Inclusive outcomes: the five-code ICD composite J96.02/J96.12/J96.22/J96.92/E66.2; PaCO₂ ≥45 mm Hg; PaCO₂ ≥45 or venous PCO₂ ≥50 mm Hg. Retain E66.2 and describe its obesity-containing ascertainment. No pH, ventilatory-support or E66.2-exclusion sensitivity is added.
- Gas positivity requires any valid positive evidence; an available-gas negative requires at least one valid result with no available qualifying positive. With no valid result, the outcome is unknown. Unmeasured evidence does not establish absence. Draw evidence and usable results are separate.
- Unit: one original patient per frame/cell. Frame N, resolved indexes, outcome-known N, model N and events are distinct. Complete cases after selection define the fitted population.

## Ascertainment registry — confirmed 2026-10-13

Nine encounter-wide primary cells plus six gas-only **index-calendar-day** sensitivity cells form one explicit registry keyed by frame × outcome × window. ICD is not duplicated. The sensitivity uses the original frame and index, then collection date equal to encounter-start date. It does not represent elapsed 24 hours. Later-only gases are unknown in the calendar-day analysis.

Discordant early summaries cannot create a primary duplicate/index conflict. They remain unknown and are counted separately. Qualified primary input can be analyzed while the timing source module is pending; the six unassessed positions retain missing estimates/model counts and `awaiting_source_evidence`. Patient-level unknown measurements and nonestimable models are different statuses.

## Models and interpretation

Retain the legacy derived `bmi` and the Stata adjustment set: linear BMI and age, factor sex, combined race/ethnicity and geographic region (`location`). Missing covariates do not acquire invented categories. No new covariates, nonlinear models, imputation or substitute estimator is adopted.

Predict observed and shifted BMI over exactly the same complete cases. Report both mean probabilities, their absolute difference, PIF `1 - p_shifted/p_observed`, model N, and count/percentage shifted. The shared BMI shift does not equalize the frame-specific populations. **PIF under a one-unit reduction above 30** is the adopted term; it is not a constant fraction attributable to each BMI unit or an OR conversion. The per-1-kg/m² adjusted odds ratio remains supporting output.

Use the full GLM coefficient covariance for the delta method on the log probability ratio, then back-transform pointwise 95% PIF limits. Empirical covariates are fixed. Retain negative fractions/limits. With no BMI >30, the difference, PIF and interval are exactly zero. Report counterfactual BMI outside the fitted marginal range; zero does not prove conditional support.

Do not pool estimates, count significant cells, or call them independent replications. No joint specification-curve inference or bootstrap is adopted. Documented index hypercapnia is the outcome; incidence reduction, treatment effects and causal prevention are not established. Descriptive BMI-bin/model checks inform review without automatically selecting another functional form.

## Source acceptance and reporting

Reuse upstream's accepted encounter/source products and receipt chain. The stale local September failed-build status is superseded by current upstream delivery evidence. Study input binding, population coverage and field mapping still require evidence. Existing exact-code transport can expose captured raw gas records without syndrome-positive catalog filtering; paired pH/sample identifiers and medication-activity evidence are not requirements here.

The [bounded source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) records repository evidence, local schema/aggregate checks and inaccessible private receipts. No replacement export is presumed necessary. Resolve existing-source mapping first and request upstream work only for demonstrated unsupported required fields.

New estimation uses manifest/bundle version 2 with the precise scenario and fifteen-cell registry. Hashes bind the input, reviewed evidence files, aggregate artifacts and source versions. Hash checks do not establish scientific truth by themselves. Version-1 BMI-to-40 bundles remain reviewable through their frozen original reader/report/figures; they cannot enter the new display or authorize new estimation. Rendering never reopens clinical inputs or refits models.

## Figures

A shared-axis forest/table is preferred; retain outcome-first B and matrix C as alternatives. All use identical saved cells, PIF limits, model N and shifted percentages. Separate quantitative marks from numerical columns; retain common linear scales, zero and every finite endpoint. Source-pending and nonestimable cells have labeled empty positions. The figure QC skill governs native-size and grayscale inspection, captions, alt text and review receipts. Scientific acceptance/submission remains separate.

## Runnable historical archives

The user confirmed **runnable archives**, not deletion or reference-only retirement. Unchanged older R originals and prior triangulation sources are preserved with hashes/source-commit provenance. The repaired R replay is `archive/r/obesity_hrf_paf_analysis.qmd`; the unchanged earlier reconstruction is `archive/r/reconstructed_obesity_hrf_from_pdf.qmd`. Use explicit `make legacy-r INPUT=...` and its HTML/PDF variants. They do not supply primary-analysis estimates.

Historical R repairs preserve its original formulas, BMI scenarios and outcomes while correcting:

- Unknown ventilation with documented hypercapnic acidosis remains unclassifiable, rather than HRF-negative.
- ICD flags decode actual reviewed 0/1 values, not factor positions. Any positive establishes the union; all observed negatives establish negative; partial/all unknown evidence remains unknown without positivity.
- Missing gas evidence propagates to laboratory/physiologic outcomes.
- Parallel sensitivity/subgroup cohorts report exclusions from their actual parent rather than a sequential previous branch.

The historical R specifications retain ventilatory-support plus hypercapnic-acidosis HRF v1, strict lab + ICD sensitivity, PaCO₂ ≥45 / VBG ≥50, pH ≤7.35, recorded `curr_bmi`, age/sex/ethnicity adjustment, and its named BMI-25/30/40 scenarios. These are distinct from the primary patient-level analysis.

Stata remains an explicit historical runnable track. Its immutable source is `archive/stata/36_subpop_hazard.source.do`, and its repaired runnable copy is `stata/do/36_subpop_hazard.do`. Preserve the obesity-source/BMI ≥40 cohort, legacy derived BMI, five-code composite/ABG flag, linear/spline specifications, demographic/region adjustment and BMI-to-40 PIF commands. The authorized October 12 repair changes only four plotting calls through the precision helper. Import provenance remains in `STATA_IMPORT.md` and `stata_import_provenance.json`.

Engineering checks and artificial renders do not qualify actual clinical results or submission readiness.
