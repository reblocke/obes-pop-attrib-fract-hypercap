# Diagnostic components and ICD acuity

This formerly separate supplement is now integrated into the main scientific
report and repeats in the all-valid-BMI primary and nested BMI≥30 secondary.
See [the scientific specification](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) for the
single authoritative design and [source contract](SOURCE_CONTRACT.md) for evidence.

The five categories retain all original flags and fixed precedence:

1. J96.22, or J96.02 with J96.12/E66.2: acute-on-chronic/concurrent coding.
2. Remaining J96.02: acute coding.
3. Remaining J96.12/E66.2: chronic coding/OHS.
4. Remaining J96.92: unspecified acuity.
5. No target code under complete capture: reference.

Incomplete/unavailable capture is unknown. OHS is grouped analytically with chronic
coding; it does not establish chronic respiratory failure. Acuity codes do not
measure acidemia, compensation or incident disease. No gas result is required.

## Estimation and uncertainty

The full five-category Firth mean-bias-reduced model maximizes multinomial log
likelihood plus half the log determinant of Fisher information. Inverse information
at the estimate supplies first-order full covariance. A separately registered
four-category maximum-likelihood sensitivity excludes only final unspecified-only
patients; it retains the same basis but has its own model/reference denominator.
No pooling or additional fallback is authorized.

Each main population uses its own saved three-column BMI spline and inherited
adjustment. Joint standardized probabilities sum to one. Positive components sum
to the joint composite, not necessarily the separately fitted binary prediction.
Full covariance supports pointwise intervals and component-change differences.
All contrasts remain in the audit; there are no subtype-specific PIFs.

`make prepare` extracts code flags and binary composite from the same diagnosis
stream. `R/icd_acuity.R` validates capture/classification and integrates the family;
`R/icd_bias_reduction.R` implements the registered Firth likelihood. The shared
joint-model routines retain estimator-specific fitting and covariance behavior.

## Clinical execution and estimability (2026-10-24)

The [historical unpenalized fit](../results/2026-10-24-icd-acuity/README.md) was
nonestimable due to separation. The [approved Firth revision](../results/2026-10-24-icd-bias-reduced/README.md)
fitted successfully in the former BMI-restricted cohort, alongside the four-category
sensitivity. Those reports remain immutable. They are not the new all-BMI results.
The new cohort requires fresh qualification, execution and review; numerical
success does not transfer investigator interpretation or figure approval.
