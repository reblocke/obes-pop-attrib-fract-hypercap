# Complete aggregate tables

Schema 12; run `curve-analyze-20261024T053607-55109`. Use exact model/population/window keys.

| Table | Rows |
|---|---:|
| [bmi_basis.csv](tables/bmi_basis.csv) | 12 |
| [bmi_provenance.csv](tables/bmi_provenance.csv) | 1,420 |
| [category_counts.csv](tables/category_counts.csv) | 27,033 |
| [coefficient_covariance.csv](tables/coefficient_covariance.csv) | 12,095 |
| [coefficients.csv](tables/coefficients.csv) | 593 |
| [cohort_edges.csv](tables/cohort_edges.csv) | 155 |
| [cohort_nodes.csv](tables/cohort_nodes.csv) | 208 |
| [comissingness.csv](tables/comissingness.csv) | 2,975 |
| [cooccurrence_availability.csv](tables/cooccurrence_availability.csv) | 36 |
| [cooccurrence_categories.csv](tables/cooccurrence_categories.csv) | 3 |
| [cooccurrence_measurements.csv](tables/cooccurrence_measurements.csv) | 104 |
| [cooccurrence_reconciliation.csv](tables/cooccurrence_reconciliation.csv) | 4 |
| [cooccurrence_status.csv](tables/cooccurrence_status.csv) | 1 |
| [coverage_index.csv](tables/coverage_index.csv) | 860 |
| [demographic_crosswalk.csv](tables/demographic_crosswalk.csv) | 126 |
| [distribution_bins.csv](tables/distribution_bins.csv) | 40,189 |
| [distribution_curves.csv](tables/distribution_curves.csv) | 187,680 |
| [evidence_by_bmi.csv](tables/evidence_by_bmi.csv) | 2,282 |
| [exclusion_overlaps.csv](tables/exclusion_overlaps.csv) | 24 |
| [exclusion_reasons.csv](tables/exclusion_reasons.csv) | 55 |
| [expected_models.csv](tables/expected_models.csv) | 30 |
| [factor_references.csv](tables/factor_references.csv) | 389 |
| [fixed_bmi_contrasts.csv](tables/fixed_bmi_contrasts.csv) | 15 |
| [icd_acuity_categories.csv](tables/icd_acuity_categories.csv) | 5 |
| [icd_acuity_contrasts.csv](tables/icd_acuity_contrasts.csv) | 220 |
| [icd_acuity_curve_reconciliation.csv](tables/icd_acuity_curve_reconciliation.csv) | 2 |
| [icd_acuity_observed_bands.csv](tables/icd_acuity_observed_bands.csv) | 60 |
| [icd_acuity_patterns.csv](tables/icd_acuity_patterns.csv) | 343 |
| [icd_acuity_probability_covariance.csv](tables/icd_acuity_probability_covariance.csv) | 14,701 |
| [icd_acuity_reconciliation.csv](tables/icd_acuity_reconciliation.csv) | 5 |
| [icd_acuity_status.csv](tables/icd_acuity_status.csv) | 1 |
| [implied_missing_probabilities.csv](tables/implied_missing_probabilities.csv) | 0 |
| [linear_spline_comparison.csv](tables/linear_spline_comparison.csv) | 5 |
| [missingness_patterns.csv](tables/missingness_patterns.csv) | 127 |
| [model_fit_diagnostics.csv](tables/model_fit_diagnostics.csv) | 312 |
| [model_influence_summary.csv](tables/model_influence_summary.csv) | 81 |
| [model_registry.csv](tables/model_registry.csv) | 30 |
| [model_residual_bins.csv](tables/model_residual_bins.csv) | 10,987 |
| [model_sample_audit.csv](tables/model_sample_audit.csv) | 30 |
| [model_support.csv](tables/model_support.csv) | 8,222 |
| [numerical_reconciliation.csv](tables/numerical_reconciliation.csv) | 2,333 |
| [observation_curves.csv](tables/observation_curves.csv) | 1,447 |
| [observation_patterns.csv](tables/observation_patterns.csv) | 288 |
| [policy_contribution_covariance.csv](tables/policy_contribution_covariance.csv) | 2,091 |
| [policy_contributions.csv](tables/policy_contributions.csv) | 177 |
| [policy_registry.csv](tables/policy_registry.csv) | 1 |
| [policy_totals.csv](tables/policy_totals.csv) | 15 |
| [population_registry.csv](tables/population_registry.csv) | 235 |
| [prediction_support.csv](tables/prediction_support.csv) | 41 |
| [prior_run_reconciliation.csv](tables/prior_run_reconciliation.csv) | 12 |
| [probability_curves.csv](tables/probability_curves.csv) | 8,293 |
| [rfs_by_bmi.csv](tables/rfs_by_bmi.csv) | 192 |
| [rfs_combinations.csv](tables/rfs_combinations.csv) | 189 |
| [rfs_outcomes.csv](tables/rfs_outcomes.csv) | 30 |
| [rfs_semantics.csv](tables/rfs_semantics.csv) | 6 |
| [rfs_summary.csv](tables/rfs_summary.csv) | 3 |
| [same_day_contrasts.csv](tables/same_day_contrasts.csv) | 55 |
| [same_day_curve_reconciliation.csv](tables/same_day_curve_reconciliation.csv) | 1 |
| [same_day_probability_covariance.csv](tables/same_day_probability_covariance.csv) | 3,600 |
| [sensitivity_results.csv](tables/sensitivity_results.csv) | 0 |
| [source_audit.csv](tables/source_audit.csv) | 58 |
| [stage_summary.csv](tables/stage_summary.csv) | 12,311 |
| [timing_audit.csv](tables/timing_audit.csv) | 108 |
| [variable_dictionary.csv](tables/variable_dictionary.csv) | 99 |
| [variable_summary.csv](tables/variable_summary.csv) | 12,639 |

The full model is `primary::icd_acuity/encounter/multinomial_spline`; the sensitivity is `primary::icd_acuity_specified/encounter/multinomial_spline`. Their denominators differ. Primary/S1/PIF keys are unchanged.
