# Analysis Decisions

## Analysis tracks and authority

- `reports/obesity_hrf_paf_analysis.qmd` is the maintained analysis entrypoint.
- `reports/reconstructed_obesity_hrf_from_pdf.qmd` is archival and should be rendered only when comparison with the prior PDF-derived report is needed.
- `stata/do/36_subpop_hazard.do` is a separate maintained runnable duplicate of the upstream severe-obesity analysis. Its estimators/PIF calculations are preserved; four profile plotting calls now use the authorized decimal-precision helper. It is not a translation of the canonical R report.
- The September trainee PDF is retained evidence of another R version, not an adopted specification or executable source.
- `reports/bmi_hypercapnia_triangulation.qmd` is a separate patient-level workflow approved on 2026-10-12. Its revised primary counterfactual was **CONFIRMED on 2026-10-13: set observed BMI >40 to 40; leave BMI ≤40 unchanged**. The primary estimand is the model-standardized potential impact fraction (PIF), superseding the original odds-ratio-primary specification and the interim BMI-minus-one proposal. Per-BMI-point odds ratios remain supporting output. The [implementation plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) records the full specification. This decision does not harmonize or replace the historical tracks; their comparison remains in [ANALYSIS_COMPARISON.md](ANALYSIS_COMPARISON.md).
- Import provenance and execution requirements are in [STATA_IMPORT.md](STATA_IMPORT.md).

## Patient-level BMI–hypercapnia triangulation

- Population: adults aged ≥18 with 2022 emergency/inpatient encounters. Select each patient's first qualifying encounter independently in three overlapping frames: BMI ≥40; ABG drawn at any BMI; either ABG or VBG drawn at any BMI. Select the index before outcome/covariate completeness checks; never replace it with a later, more complete encounter.
- Outcomes at that index: the five-code legacy ICD composite (J96.02, J96.12, J96.22, J96.92, E66.2); PaCO₂ ≥45 mm Hg; and PaCO₂ ≥45 or venous PCO₂ ≥50 mm Hg. Retain E66.2 without an exclusion sensitivity. No pH or ventilatory-support criterion is added.
- The combined gas outcome is positive if either valid result is positive, available-gas negative if at least one valid result exists and all available results are below threshold, and unknown if neither is valid. An unmeasured gas is not itself negative. Draw membership and result availability remain distinct.
- Exposure: the legacy derived `bmi`, without current-BMI substitution or reconstruction. Fit BMI and age linearly on the log-odds scale, adjusting for age at encounter, sex, combined race/ethnicity, and location as in the old Stata analysis.
- Fit complete cases after index selection, one patient per cell. Average predictions twice over that exact estimation sample: observed BMI and `pmin(bmi, 40)`, holding original frame membership, index encounter, and adjustment values fixed. Do not re-filter membership or completeness under the counterfactual.
- Primary outputs are `p_observed`, `p_counterfactual`, absolute probability difference `p_observed - p_counterfactual`, and `pif = 1 - p_counterfactual / p_observed`. This is burden associated with BMI above 40 under the model, not total obesity burden. Outcomes describe documented hypercapnia at the selected encounter; there is no incidence or follow-up analysis.
- Construct 95% PIF intervals by the delta method for the log counterfactual/observed probability ratio using the full GLM coefficient covariance, then transform to the PIF scale. Hold the empirical covariate distribution fixed. Do not bootstrap, pool the nine cells, or treat them as independent replications. Statistical intervals do not capture confounding, selection bias, or misclassification.
- Retain negative PIFs without truncation. If all modeled BMI values are ≤40, report an exact zero difference/PIF/interval with a no-change diagnostic. Report the count and percentage of counterfactual BMI values outside the fitted cell's observed BMI range; zero out-of-range values do not establish conditional positivity.
- Report BMI odds ratios per 1 kg/m² with Wald intervals as supporting output only; no odds-ratio-to-PAF conversion. The primary figure uses three panels with a common linear percentage PIF axis, zero reference, direct intervals, and model denominators. Causal interpretation requires additional model/support/confounding assumptions; no GLP-1 treatment effect is established.
- Reject unresolved identifiers/chronology and expose nonestimable models and denominator losses. No silent term removal, penalized-model substitution, later-encounter substitution, or file-order tie-breaking is authorized.
- The implementation and artificial-data verification do not accept a clinical input, qualify actual results, or establish submission readiness. Those remain distinct execution and scientific-review steps.

## Canonical R HRF definitions

- Primary HRF v1 is ventilatory support with ABG or VBG evidence of hypercapnic acidosis.
- ABG hypercapnia cutoff is PaCO2 >= 45 mmHg.
- VBG hypercapnia cutoff is CO2 >= 50 mmHg.
- Acidemia cutoff is pH <= 7.35.
- Strict sensitivity HRF requires both lab hypercapnic acidosis and ICD evidence.

## Canonical R missing gas data

- Missing ABG/VBG data are not coded as `No HRF`.
- HRF v1 is `Yes` when criteria are met, `No` when a classifiable gas pair exists and HRF criteria are not met, and unclassifiable otherwise.
- Attrition and denominator reporting should distinguish BMI availability, ABG pair availability, VBG pair availability, and any gas-pair availability.

## Canonical R respiratory status

The descriptive respiratory-status variable should keep these groups separate:

1. No hypercapnia.
2. Compensated hypercapnia.
3. HRF.
4. Other classifiable gas pattern.
5. Unclassifiable or missing.

This avoids hiding compensated hypercapnia inside a broad non-HRF comparator.

## Canonical R PAF/PIF estimands

- Use model-standardized predicted risks for observed and counterfactual BMI distributions.
- Report `risk_observed`, `risk_counterfactual`, and `pif`.
- Retain the proof-of-concept `set everyone to BMI 25` row for comparison with the exploratory draft.
- Prefer named intervention-style rows:
  - `BMI >25 set to 25`
  - `BMI >30 set to 30`
  - `BMI >40 set to 40`
  - `BMI >=40 subgroup: BMI >40 set to 40`

Use cautious language such as "model-standardized impact fraction under the specified counterfactual" unless causal assumptions are explicitly defended.

## Preserved Stata estimand

- Retain `OBESITY_rfs == 1`, BMI >=40, and complete adjustment variables; the gas-outcome models additionally restrict to `has_abg == 1`.
- Exposure is the upstream derived `bmi`, not the R report's parsed `curr_bmi`.
- Compare observed BMI with BMI assigned to 40 over each fitted model's estimation sample.
- Outcomes are the upstream `hypercap_resp_failure` diagnosis composite (four J96 codes plus E66.2) and `hypercap_on_abg` flag. No ventilatory-support or pH criterion is added by Stage 36.
- Retain linear and three-knot restricted-cubic-spline models, adjustment for age, sex, combined race/ethnicity, and location, and `margins`/`nlcom` uncertainty.
- These preserved definitions describe historical behavior; import preservation does not independently validate upstream coding, clinical meaning, causality, or transport to another population.
- Potential defects and figure limitations are documented for review. Changes require a separate scientific decision and regenerated evidence.
- On 2026-10-12 the user authorized the xblc precision repair. Four plotting calls now evaluate observed spline terms with the bundled helper, preserving the fixed-profile interpretation and log-odds confidence construction. Models, cohorts, knots, and PIF commands remain unchanged; verification is synthetic only.
