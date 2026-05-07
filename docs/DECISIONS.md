# Analysis Decisions

## Canonical Report

- `reports/obesity_hrf_paf_analysis.qmd` is the maintained analysis entrypoint.
- `reports/reconstructed_obesity_hrf_from_pdf.qmd` is archival and should be rendered only when comparison with the prior PDF-derived report is needed.

## HRF Definitions

- Primary HRF v1 is ventilatory support with ABG or VBG evidence of hypercapnic acidosis.
- ABG hypercapnia cutoff is PaCO2 >= 45 mmHg.
- VBG hypercapnia cutoff is CO2 >= 50 mmHg.
- Acidemia cutoff is pH <= 7.35.
- Strict sensitivity HRF requires both lab hypercapnic acidosis and ICD evidence.

## Missing Gas Data

- Missing ABG/VBG data are not coded as `No HRF`.
- HRF v1 is `Yes` when criteria are met, `No` when a classifiable gas pair exists and HRF criteria are not met, and unclassifiable otherwise.
- Attrition and denominator reporting should distinguish BMI availability, ABG pair availability, VBG pair availability, and any gas-pair availability.

## Respiratory Status

The descriptive respiratory-status variable should keep these groups separate:

1. No hypercapnia.
2. Compensated hypercapnia.
3. HRF.
4. Other classifiable gas pattern.
5. Unclassifiable or missing.

This avoids hiding compensated hypercapnia inside a broad non-HRF comparator.

## PAF/PIF Estimands

- Use model-standardized predicted risks for observed and counterfactual BMI distributions.
- Report `risk_observed`, `risk_counterfactual`, and `pif`.
- Retain the proof-of-concept `set everyone to BMI 25` row for comparison with the exploratory draft.
- Prefer named intervention-style rows:
  - `BMI >25 set to 25`
  - `BMI >30 set to 30`
  - `BMI >40 set to 40`
  - `BMI >=40 subgroup: BMI >40 set to 40`

Use cautious language such as "model-standardized impact fraction under the specified counterfactual" unless causal assumptions are explicitly defended.
