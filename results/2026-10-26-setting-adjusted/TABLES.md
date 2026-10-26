# Aggregate table navigation

All rows are retained. Exact model, population and window identities distinguish estimates.

| Table | Rows |
|---|---:|
| [bmi_basis.csv](tables/bmi_basis.csv) | 16 |
| [bmi_provenance.csv](tables/bmi_provenance.csv) | 1,420 |
| [category_counts.csv](tables/category_counts.csv) | 29,894 |
| [coefficient_covariance.csv](tables/coefficient_covariance.csv) | 21,972 |
| [coefficients.csv](tables/coefficients.csv) | 858 |
| [cohort_edges.csv](tables/cohort_edges.csv) | 117 |
| [cohort_nodes.csv](tables/cohort_nodes.csv) | 169 |
| [comissingness.csv](tables/comissingness.csv) | 4,542 |
| [cooccurrence_availability.csv](tables/cooccurrence_availability.csv) | 77 |
| [cooccurrence_categories.csv](tables/cooccurrence_categories.csv) | 6 |
| [cooccurrence_measurements.csv](tables/cooccurrence_measurements.csv) | 226 |
| [cooccurrence_reconciliation.csv](tables/cooccurrence_reconciliation.csv) | 8 |
| [cooccurrence_status.csv](tables/cooccurrence_status.csv) | 2 |
| [coverage_index.csv](tables/coverage_index.csv) | 929 |
| [demographic_crosswalk.csv](tables/demographic_crosswalk.csv) | 126 |
| [distribution_bins.csv](tables/distribution_bins.csv) | 111,325 |
| [distribution_curves.csv](tables/distribution_curves.csv) | 356,405 |
| [encounter_setting_audit.csv](tables/encounter_setting_audit.csv) | 354 |
| [evidence_by_bmi.csv](tables/evidence_by_bmi.csv) | 3,423 |
| [exclusion_overlaps.csv](tables/exclusion_overlaps.csv) | 4 |
| [exclusion_reasons.csv](tables/exclusion_reasons.csv) | 10 |
| [expected_models.csv](tables/expected_models.csv) | 36 |
| [factor_references.csv](tables/factor_references.csv) | 549 |
| [fixed_bmi_contrasts.csv](tables/fixed_bmi_contrasts.csv) | 18 |
| [icd_acuity_categories.csv](tables/icd_acuity_categories.csv) | 10 |
| [icd_acuity_contrasts.csv](tables/icd_acuity_contrasts.csv) | 500 |
| [icd_acuity_curve_reconciliation.csv](tables/icd_acuity_curve_reconciliation.csv) | 4 |
| [icd_acuity_observed_bands.csv](tables/icd_acuity_observed_bands.csv) | 140 |
| [icd_acuity_patterns.csv](tables/icd_acuity_patterns.csv) | 772 |
| [icd_acuity_probability_covariance.csv](tables/icd_acuity_probability_covariance.csv) | 34,282 |
| [icd_acuity_reconciliation.csv](tables/icd_acuity_reconciliation.csv) | 10 |
| [icd_acuity_status.csv](tables/icd_acuity_status.csv) | 2 |
| [linear_spline_comparison.csv](tables/linear_spline_comparison.csv) | 5 |
| [missingness_patterns.csv](tables/missingness_patterns.csv) | 135 |
| [model_fit_diagnostics.csv](tables/model_fit_diagnostics.csv) | 370 |
| [model_influence_summary.csv](tables/model_influence_summary.csv) | 93 |
| [model_registry.csv](tables/model_registry.csv) | 36 |
| [model_residual_bins.csv](tables/model_residual_bins.csv) | 12,899 |
| [model_sample_audit.csv](tables/model_sample_audit.csv) | 36 |
| [model_support.csv](tables/model_support.csv) | 16,326 |
| [numerical_reconciliation.csv](tables/numerical_reconciliation.csv) | 3,643 |
| [observation_curves.csv](tables/observation_curves.csv) | 1,927 |
| [observation_patterns.csv](tables/observation_patterns.csv) | 336 |
| [policy_contribution_covariance.csv](tables/policy_contribution_covariance.csv) | 4,179 |
| [policy_contributions.csv](tables/policy_contributions.csv) | 273 |
| [policy_registry.csv](tables/policy_registry.csv) | 1 |
| [policy_totals.csv](tables/policy_totals.csv) | 18 |
| [population_registry.csv](tables/population_registry.csv) | 199 |
| [prediction_support.csv](tables/prediction_support.csv) | 47 |
| [prior_run_reconciliation.csv](tables/prior_run_reconciliation.csv) | 69 |
| [probability_curves.csv](tables/probability_curves.csv) | 15,339 |
| [rfs_by_bmi.csv](tables/rfs_by_bmi.csv) | 216 |
| [rfs_combinations.csv](tables/rfs_combinations.csv) | 189 |
| [rfs_outcomes.csv](tables/rfs_outcomes.csv) | 30 |
| [rfs_semantics.csv](tables/rfs_semantics.csv) | 6 |
| [rfs_summary.csv](tables/rfs_summary.csv) | 3 |
| [same_day_contrasts.csv](tables/same_day_contrasts.csv) | 125 |
| [same_day_curve_reconciliation.csv](tables/same_day_curve_reconciliation.csv) | 2 |
| [same_day_probability_covariance.csv](tables/same_day_probability_covariance.csv) | 8,480 |
| [source_audit.csv](tables/source_audit.csv) | 63 |
| [stage_summary.csv](tables/stage_summary.csv) | 15,176 |
| [timing_audit.csv](tables/timing_audit.csv) | 126 |
| [variable_dictionary.csv](tables/variable_dictionary.csv) | 99 |
| [variable_summary.csv](tables/variable_summary.csv) | 15,832 |

`encounter_setting_audit.csv` gives raw setting-by-BMI usable-evidence proportions with Wilson intervals; `observation_curves.csv` contains adjusted observation probabilities. `model_registry.csv`, `factor_references.csv`, `coefficients.csv` and `coefficient_covariance.csv` document encounter-setting adjustment.

For `encounter_setting_audit.csv`, **N** is the population count within the given
setting and original five-unit BMI band; **M** has usable gas evidence; **H** is
hypercapnia-positive among those with usable evidence. `observation=M/N`; its
bounds are Wilson 95% limits. `n_reference` is the entire adjustment-complete
population, `setting_population_n` is that setting's total, and
`bmi_population_n` is the pooled BMI-band count. Fractions are not percentages.
`pct_shifted` in scenario tables is already a percentage (0–100).
