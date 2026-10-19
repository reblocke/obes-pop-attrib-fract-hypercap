# Aggregate table index

All 49 CSVs are complete, byte-identical exports from the qualified clinical run.
They contain group summaries and model/grid coordinates, not patient records.
Blank values and explicit unavailable statuses are not zeros. The two empty
projection tables are historical schema positions, not current MAR/MNAR analyses.

Start with `cohort_nodes`, `model_registry`, `probability_curves` and `policy_totals`.
For primary results select `analysis_population_id=primary`,
`ascertainment_window=encounter`, and `model_form=spline` where present.
Also restrict main results to these exact `model_id` values:

- `primary::abg/encounter/spline`
- `primary::any_gas/encounter/spline`
- `primary::icd/encounter/spline`

Population/window/form alone also select matched-sample sensitivity results.
Use `policy_id=bmi_gt30_minus1_v1` for the secondary scenario. Preserve model and
reference IDs; do not sum overlapping samples. Probabilities/PIFs are fractions
(multiply by 100 for percent). Fields ending in `per1000` are already scaled.
`population_id` in cohort/descriptive tables denotes a stage within the analysis
population; it is not always interchangeable with `analysis_population_id`.

The [machine index](table_index.csv) adds all column names, row counts and hashes.

| Table | Rows | Contents |
|---|---:|---|
| [bmi_basis.csv](tables/bmi_basis.csv) | 12 | Saved numeric spline knots and basis identities |
| [bmi_provenance.csv](tables/bmi_provenance.csv) | 1,420 | Current/prior/calculated BMI-source accounting |
| [category_counts.csv](tables/category_counts.csv) | 23,006 | Complete categorical distributions by stage and population |
| [coefficient_covariance.csv](tables/coefficient_covariance.csv) | 5,570 | Complete coefficient covariance matrices |
| [coefficients.csv](tables/coefficients.csv) | 458 | Every fitted coefficient, standard error and interval |
| [cohort_edges.csv](tables/cohort_edges.csv) | 153 | Links and count reconciliation between cohort stages |
| [cohort_nodes.csv](tables/cohort_nodes.csv) | 204 | Authoritative cohort counts with record/encounter/patient units |
| [comissingness.csv](tables/comissingness.csv) | 2,875 | Joint variable missingness summaries |
| [coverage_index.csv](tables/coverage_index.csv) | 721 | Report-entry/status index for populations, variables and models |
| [demographic_crosswalk.csv](tables/demographic_crosswalk.csv) | 126 | Aggregate raw race by raw ethnicity by inherited combined category |
| [distribution_bins.csv](tables/distribution_bins.csv) | 36,097 | Histogram frequencies with saved edges and denominators |
| [distribution_curves.csv](tables/distribution_curves.csv) | 176,152 | Aggregate ECDF and KDE coordinates for variable profiles |
| [evidence_by_bmi.csv](tables/evidence_by_bmi.csv) | 2,282 | Raw evidence availability by BMI bin |
| [exclusion_overlaps.csv](tables/exclusion_overlaps.csv) | 24 | Overlapping exclusion reasons; do not sum as a partition |
| [exclusion_reasons.csv](tables/exclusion_reasons.csv) | 55 | Explicit exclusions and unresolved eligibility categories |
| [expected_models.csv](tables/expected_models.csv) | 27 | Configured model positions, including expected failures or unavailable positions |
| [factor_references.csv](tables/factor_references.csv) | 338 | Categorical reference levels for each model |
| [fixed_bmi_contrasts.csv](tables/fixed_bmi_contrasts.csv) | 15 | Supported BMI 45 versus 40 probabilities and contrasts |
| [implied_missing_probabilities.csv](tables/implied_missing_probabilities.csv) | 0 | Retired projection table retained empty; no current MAR/MNAR estimates |
| [linear_spline_comparison.csv](tables/linear_spline_comparison.csv) | 5 | Same-sample linear-BMI versus spline sensitivity |
| [missingness_patterns.csv](tables/missingness_patterns.csv) | 123 | Counts of complete missingness patterns |
| [model_fit_diagnostics.csv](tables/model_fit_diagnostics.csv) | 287 | Apparent fit, convergence, rank and related model diagnostics |
| [model_influence_summary.csv](tables/model_influence_summary.csv) | 78 | Aggregate influence diagnostics without individual records |
| [model_registry.csv](tables/model_registry.csv) | 27 | Model status, sample size, events and failure reasons |
| [model_residual_bins.csv](tables/model_residual_bins.csv) | 10,579 | Aggregated residual diagnostics |
| [model_sample_audit.csv](tables/model_sample_audit.csv) | 27 | Reference, complete-case and outcome-evaluable sample reconciliation |
| [model_support.csv](tables/model_support.csv) | 5,573 | Local BMI-by-covariate counts, events and sparsity flags |
| [numerical_reconciliation.csv](tables/numerical_reconciliation.csv) | 2,332 | Saved numerical equalities and unresolved audit quantities |
| [observation_curves.csv](tables/observation_curves.csv) | 1,447 | Modeled evidence-availability probabilities across BMI |
| [observation_patterns.csv](tables/observation_patterns.csv) | 288 | Mutually exclusive ABG-only, VBG-only, both and neither availability |
| [policy_contribution_covariance.csv](tables/policy_contribution_covariance.csv) | 2,091 | Full covariance of signed BMI-band contributions |
| [policy_contributions.csv](tables/policy_contributions.csv) | 177 | Signed original-BMI-band contributions and intervals for F2 |
| [policy_registry.csv](tables/policy_registry.csv) | 1 | Named secondary BMI transformation and policy status |
| [policy_totals.csv](tables/policy_totals.csv) | 15 | Paired observed/shifted probabilities, absolute differences, PIFs and intervals |
| [population_registry.csv](tables/population_registry.csv) | 231 | Population and stage ledger with units, counts and statuses |
| [prediction_support.csv](tables/prediction_support.csv) | 41 | Fixed-grid and transformed-BMI prediction support |
| [prior_run_reconciliation.csv](tables/prior_run_reconciliation.csv) | 12 | Prior-run index/field stability and unresolved comparison audits |
| [probability_curves.csv](tables/probability_curves.csv) | 4,742 | Adjusted BMI-grid probabilities, intervals and local support for F1 |
| [rfs_by_bmi.csv](tables/rfs_by_bmi.csv) | 192 | Source-entry frequencies by BMI band |
| [rfs_combinations.csv](tables/rfs_combinations.csv) | 189 | Counts for historical RFS membership patterns |
| [rfs_outcomes.csv](tables/rfs_outcomes.csv) | 30 | Outcome evaluability and positives by source-entry group |
| [rfs_semantics.csv](tables/rfs_semantics.csv) | 6 | Authenticated source-membership meaning and unresolved historical extraction details |
| [rfs_summary.csv](tables/rfs_summary.csv) | 3 | Source-entry partition and overlap subgroup counts |
| [sensitivity_results.csv](tables/sensitivity_results.csv) | 0 | Retired projection table retained empty; use model-keyed timing/linear results |
| [source_audit.csv](tables/source_audit.csv) | 58 | Source qualification states and overlapping source-record counters |
| [stage_summary.csv](tables/stage_summary.csv) | 11,249 | Before/after per-variable profiles and completeness by stage |
| [timing_audit.csv](tables/timing_audit.csv) | 108 | Encounter-wide versus index-calendar-day evidence transitions |
| [variable_dictionary.csv](tables/variable_dictionary.csv) | 77 | Complete saved field definitions, coding and missingness rules |
| [variable_summary.csv](tables/variable_summary.csv) | 11,249 | Complete per-variable summaries and unavailable states |
