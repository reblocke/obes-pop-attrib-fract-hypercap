# Implementation ticket: BMI–hypercapnia probability curves, sampling, and auditable burden decomposition

**Repository:** `reblocke/obes-pop-attrib-fract-hypercap`  
**Ticket date:** 2026-10-16  
**Source reviewed:** `main` at `8735505254b8b806c20478da39f580bc4b845581`  
**Deliverable:** Implement the analysis and its reports in the working repository. This document specifies future work; it does not report completed implementation or clinical results.  
**Compatibility:** Breaking refactor. No backward-compatible readers, historical execution paths, output schemas, or figure reproductions are required.  
**Primary objective:** Describe the BMI–hypercapnia relationship, the population distribution of BMI, and the observation process. Derive named BMI-scenario PIFs from exactly the same predictions. Make every cohort transition and model auditable.

## 0. Execute this ticket, not the superseded specification

Implement a curve-first, audit-first analysis. Do not simply add plots to the existing 140-position projection registry.

The owner has approved the following changes:

1. Flexible hypercapnia probability curves across BMI become the primary scientific display.
2. BMI frequencies and outcome-observation probabilities accompany those curves.
3. Population impact fractions become secondary summaries of explicitly named, paired prediction scenarios. Display their contributions by original BMI range.
4. Descriptive statistics are required throughout cohort construction, not only in a final Table 1.
5. A detailed, CONSORT-style **observational cohort-flow diagram** and its underlying machine-readable accounting are required.
6. Every fitted regression must have a full coefficient table, sample accounting, covariance, and diagnostic report. Reporting only the BMI coefficient is unacceptable.
7. No backward compatibility is required. Replace conflicting instructions and default workflows rather than maintaining parallel scientific authorities.

Retain the valid existing source protections and common-index design. Lack of a compatibility requirement does **not** authorize changing clinical source data, silently redefining variables, or treating source qualification as complete.

### 0.1 Scope of authority

This ticket supersedes active instructions that make a single linear BMI coefficient, the one-unit PIF forest plot, or historical-version replay the primary deliverable. Update `AGENTS.md`, the main analysis plan, README, launchers, tests, and report consistently.

It does not authorize:

- Replacing the approved BMI derivation or expanding the source population without a documented decision.
- Treating untested patients as physiologically negative.
- Changing the inclusive hypercapnia thresholds or adding pH/ventilatory-support requirements.
- Adding comorbidity adjustment, imputation of adjustment variables, weighting, or automatic model selection.
- New survival/incidence analyses, a weight-loss treatment-effect claim, or a continuous-PCO2 etiologic study.
- Rewriting Git history, deleting restricted inputs or prior clinical artifacts, sending messages, or publishing clinical results.

Work from the current checkout. Inspect later commits and uncommitted work before editing; do not reset the repository to the reviewed SHA. Reconcile any subsequent changes in a short implementation note. The reviewed SHA identifies the drafting basis, not a command to discard newer work.

### 0.2 Definition of completion

There are separate completion states:

- **Software complete:** all required analysis, audit, rendering, and validation modules work end to end on artificial data, including adverse cases.
- **Source qualified:** actual study input, candidate coverage, field mappings, and evidence files have been reviewed on the authorized host.
- **Clinical run complete:** one qualified execution produces reconciled results and actual visual/numerical review.
- **Scientifically reviewed:** the investigator has reviewed interpretation, selection, model support, and source limitations.

Do not make software completion depend on access to restricted data. Do not label artificial success as any of the other states. When clinical input remains blocked, finish the software and return a precise source-gap handoff.

## 1. Scientific specification and defaults

### 1.1 Study question

> Among adults with obesity presenting for acute care, how does documented hypercapnia probability vary across BMI, how selectively is physiological evidence observed, and which BMI ranges contribute to modeled occurrence and to a specified BMI-scenario contrast?

Use **probability**, **proportion**, or **documented index-encounter occurrence**. This is not an incident-disease cohort with a disease-free baseline and follow-up horizon. Do not label the principal results incidence, cases prevented, or effects of within-person weight loss.

A BMI >=30 cohort describes variation across degrees of obesity. It does not directly estimate obesity versus nonobesity.

### 1.2 Keep these population and measurement decisions

| Component | Required rule |
|---|---|
| Source | Authenticated captured TriNetX-derived source for this study, not a national population and not automatically the historical compatibility bundle |
| Calendar scope | Encounter start on or after 2022-01-01 and before 2023-01-01 |
| Age | Age at encounter >=18, using the approved derivation |
| Setting | Reviewed emergency/inpatient codes, currently `EMER` and `IMP` |
| BMI eligibility | Approved legacy-derived observed BMI >=30 |
| Observation unit | One original patient, with one selected qualifying encounter |
| Index | First qualifying encounter within the study period, chosen before gas availability and adjustment completeness |
| Ambiguity | Unresolved earlier eligibility, conflicting index evidence, and earliest-date ties remain unresolved; never advance to a later, more complete encounter |
| Severe-obesity subgroup | Observed BMI >=40 at the original common index; subset that index cohort, without reindexing or refitting the primary BMI relationship |
| Adjustment | BMI, age, sex, combined race/ethnicity, and geographic region (`location`) |
| Other covariates | Descriptive only when already authenticated; not automatically added to models or completeness requirements |
| Repeated encounters | Used for selection and cohort auditing, not treated as independent primary outcome observations |
| Outcome timing | Selected-encounter maxima are primary; index-calendar-day maxima are sensitivities |
| Calendar-day meaning | Collection date equals encounter-start date under the reviewed source convention; not elapsed 24 hours |

Preserve any approved unknown categories versus true missingness exactly as documented. Do not choose reference levels or turn named unknowns into missing values by incidental factor ordering.

### 1.3 Outcome definitions

| `outcome_id` | Positive | Negative / evaluable | Unknown |
|---|---|---|---|
| `abg` | At least one valid arterial PCO2 >=45 mm Hg in the specified window | Usable arterial evidence exists and the valid maximum is <45 | No usable arterial result for that window |
| `any_gas` | Valid arterial PCO2 >=45 or valid venous PCO2 >=50 mm Hg | At least one usable specimen exists and every available specimen-specific maximum is below its threshold | Neither specimen has a usable result |
| `icd` | Captured encounter code J96.02, J96.12, J96.22, J96.92, or E66.2 | No target code in complete, available encounter diagnosis extraction | Unavailable/incomplete diagnosis capture under the approved source rule |

The combined negative is an **available-evidence negative**, not proof that an unmeasured specimen is normal. ICD negativity is documented-code absence, not absence of physiology. Keep E66.2 in the approved composite and identify it as obesity-containing ascertainment.

Use `abg` and `any_gas` for both encounter and calendar-day windows. Do not invent a duplicate calendar-day ICD analysis. Pure venous summaries are required for sampling audits; a new venous-outcome regression is not a prerequisite for this ticket.

Preserve `unadjusted_pco2_v1`: ordinary specimen-authenticated values, reviewed units, strict validity intervals `5 < arterial PCO2 < 200` and `10 < venous PCO2 < 250` mm Hg, and no automatic inclusion of temperature-adjusted measurements. These are the repository's source-validity rules, not newly validated physiological cutoffs. Preserve exact code/units policies in the configuration and report them.

### 1.4 Explicit population objects

Give each population a stable `population_id` and a count record:

- `Q`: all resolved, eligible common-index patients, before adjustment completeness.
- `C`: members of `Q` complete for the inherited adjustment set. This is the common standardization reference.
- `C40`: members of `C` with original BMI >=40.
- `C_k_w`: members of `C` with observed outcome `k` in window `w`. These supply the corresponding outcome model.
- `M_abg`: members of `C` with evaluable encounter ABG and known ICD capture.
- `M_any_gas`: members of `C` with evaluable encounter combined evidence and known ICD capture.
- Corresponding unknown-outcome, missing-adjustment, and unresolved-index audit sets.

`M_abg` and `M_any_gas` are different matched-comparison sets. Within each pair the two outcomes must use identical patients. Across pairs, equality is not required.

Every displayed number must identify whether its denominator is `Q`, `C`, `C_k_w`, a matched set, an encounter set, or a raw-record set. There is no single generic “analysis N.”

### 1.5 Keep policy choice separate from relationship estimation

The main curve, density, and observation figures must not depend on a BMI-reduction policy.

For a fully specified first implementation, retain the active one-unit scenario as **secondary**, not as the organizing aim:

```r
g <- function(bmi) ifelse(bmi > 30, bmi - 1, bmi)
```

BMI =30 stays 30; BMI 30.2 becomes 29.2. Do not add a floor, silently switch to caps, or reapply eligibility after transformation.

Implement a small explicit policy registry capable of a named cap-at-30 or cap-at-40 scenario, but keep these disabled by default. Enabling a policy must require its own target population, eligibility, transformation, and label. This infrastructure is not a mandate to run every historical policy. Current primary curves should survive a later policy change without being redesigned.

The default fixed-BMI summary contrast is 45 versus 40, evaluated on a named common reference where supported. It is distinct from the population-average one-unit shift. Show absolute difference per 1,000 and prevalence ratio; do not call either a PIF.

## 2. Current implementation to replace and reuse

At the reviewed SHA:

- `R/common_index_hypercapnia.R` contains common selection, a fixed linear formula, models, paired standardization, and audits. `fit_common_model()` extracts only a single `"bmi"` coefficient. `common_registry()` expands models into 140 reporting positions.
- `R/common_index_reporting.R` fixes the current aggregate contract and report/figure behavior.
- `R/bmi_hypercapnia_triangulation.R` and `R/triangulation_reporting.R` also supply shared validation, index, separation, and utility functions. Isolate reusable functions from superseded scientific logic.
- `reports/bmi_hypercapnia_triangulation.qmd` is the primary report, currently organized around one-unit observed/MAR/MNAR contrasts.
- `scripts/render_triangulation.R`, `scripts/preflight_triangulation.R`, and `scripts/prepare_common_index_input.py` are current orchestration/preparation entrypoints.
- `Makefile`, tests, configuration, `AGENTS.md`, and analysis documentation retain historical-version routing.

Reuse authenticated input preparation, explicit missingness, deterministic selection, model failure handling, source checks, and no-refit rendering. Replace the scientific registry, result schema, and primary presentation rather than preserving the old 140-position shape.

No old/new schema migration or historical figure recreation is required. Old bundles should fail with a clear “superseded analysis; rerun under the current design” message. Do not reinterpret them as new results. Existing raw inputs and private artifacts remain untouched.

## 3. Source qualification, input dictionary, and audit scope

### 3.1 Known blocker to carry forward accurately

`docs/COMMON_INDEX_SOURCE_GAP_HANDOFF.md` reports authenticated historical-product receipts and decoding, but a bounded check found potentially eligible captured acute-care encounter keys absent from the historical legacy mapping. Their exact approved age/BMI eligibility and possibly earlier indexes cannot yet be adjudicated.

Do not:

- Drop these keys to obtain a runnable final cohort.
- Call them nonobese or presume they all meet BMI eligibility.
- Scale one partition's counts into an estimated total gap.
- Treat a historical FULL_DATA label as proof of complete study coverage.
- Allow a polished BMI-frequency plot to imply that the intended denominator has been established.

Keep preparation able to produce a **partial source-audit report** with the checked partition, available counts, and the exact stopping point. Downstream final-cohort and clinical-model results remain unavailable until the required mapping/qualification is complete. Unknown totals are null, never zero.

### 3.2 Mandatory variable inventory

Create `variable_dictionary.csv` or an equivalent committed configuration covering every imported analysis field and derived field. Include:

`variable_id`, source name, display label, type, unit, allowed codes/levels, reference level, derivation, time anchoring, missing-value rule, source-policy identifier, role, applicable populations, and whether it is required for cohort eligibility, model fitting, or descriptive reporting only.

Roles include identifier, selection, exposure, adjustment, observation, outcome, diagnostic, and derived basis.

Required fields already used include original keys, encounter date/type, BMI, age, sex, race/ethnicity, region, testing flags, arterial/venous maxima, ICD composite, and the optional four calendar-day value/availability fields. Add explicit flags for derivation validity, capture state, key conflicts, unresolved indexes, and each exclusion reason.

Additional already-authenticated fields may enrich description: BMI measurement timing/derivation route, gas collection dates, numbers of measurements, specimen/code/unit provenance, diagnosis components, site, and relevant clinical characteristics. Do not invent these fields, broaden source pulls by default, or require their presence to fit the inherited adjustment model. A missing optional field produces a labeled capability gap.

Identifiers receive cardinality, missingness, uniqueness, and linkage checks, not KDEs or published value lists. Every other field used in selection, modeling, outcomes, or reported diagnostics must have a descriptive entry. New derived variables must register automatically or fail coverage validation.

### 3.3 Source-level checks

Before models, report raw-to-typed mappings and counts for:

- Original versus encoded keys, unmatched joins, duplicate rows, conflicting encounter versions, and row multiplication at joins.
- Date/type consensus and unresolved chronology; explicit distinction between a birth-year proxy and exact eligibility age.
- BMI derivation, units, finite/positive values, missingness, distribution and rounding at 30/40, and temporal anchoring where available.
- Gas specimen/code family, units/conversion, ordinary versus temperature-adjusted status, unusable values, validity-range exclusions, and encounter attribution.
- Gas values below, exactly at, and above the relevant threshold, by specimen.
- Encounter maximum versus calendar-day maximum and availability consistency.
- ICD code membership, component availability, complete-capture negatives, and unknown capture.
- Regional coding distinct from encounter setting or hospital identity.

Raw invalid values are not winsorized into plausibility. Capture them in a protected diagnostic summary, apply the approved validity rule, and record what changed. A source-schema error, an individual missing value, and an entire unavailable module must remain distinguishable.

## 4. Cohort-flow accounting: first-class data, not hand-entered labels

### 4.1 One authoritative ledger

Create a canonical `cohort_nodes` and `cohort_edges` ledger plus exclusion-reason tables. All flow diagrams, stage counts, descriptive stage tables, reference Ns, and model Ns must be generated from those records and their underlying membership predicates.

Recommended node fields:

```text
node_id, parent_node_id, branch_id, display_order, label,
entity_type, population_id, predicate_id, partition_id,
n_records, n_encounter_keys, n_encounter_versions, n_patients,
count_status, reason, provenance_id
```

Recommended edge fields:

```text
edge_id, from_node_id, to_node_id, relationship_type,
entity_type, n, denominator_node_id, denominator_n,
pct_parent, pct_root, count_status
```

`relationship_type` distinguishes `partition`, `subset`, `overlap`, `unit_conversion`, and `provenance`. A graphical arrow does not by itself mean counts should add.

`count_status` distinguishes complete, partial, unavailable, pending source, and not applicable. Numeric fields are null when unknown. Each partial count identifies its evaluated scope. Counts are nonnegative integers; percentages retain both numerator and denominator.

Maintain private row/patient membership internally so that identities are checked by sets, not merely by matching totals. Do not export these memberships to the aggregate bundle.

### 4.2 Required flow stages

Implement the following stages, allowing a stage to be explicitly not applicable when the accepted upstream interface already performed it with an authenticated receipt.

| Phase | Required visible steps and branches |
|---|---|
| Source inventory | Named candidate extract/product; checked source partitions; available record, encounter, and patient counts; unexamined scope explicitly unknown |
| Linkage/typing | Original-key linkage; missing/unmapped keys; unsupported field mapping; invalid coding/units; records versus encounter keys clearly labeled |
| Duplicate/conflict handling | Raw versions, exact duplicates removed, distinct encounter versions, conflicting keys; conflicts remain represented for eligibility/index adjudication |
| Encounter eligibility | Calendar period, acute-care setting, exact adult age, approved BMI availability/validity, BMI >=30; confirmed eligible, confirmed ineligible, and uncertain eligibility |
| Patient membership | Patients with at least one confirmed eligible encounter; patients with only potentially eligible encounters; no eligible/potentially eligible encounter where ascertainable |
| Index selection | Earliest confirmed qualifying date; uncertain earlier eligible encounter; earliest-date tie; conflicting earliest evidence; resolved index |
| Cohort `Q` | All resolved eligible patients before adjustment completeness |
| Adjustment completeness | Complete `C`; incomplete adjustment branch; missingness reasons and overlaps visible |
| Observation | Four mutually exclusive usable-gas patterns; diagnosis-capture availability; separate testing-performed and usable-result accounting |
| Outcome-specific samples | Evaluable ABG, evaluable combined gas, known ICD, each with positive/negative/unknown counts and model eligibility |
| Matched comparisons | `M_abg` and `M_any_gas`, with identical within-pair row membership |
| Sensitivity references | `C40` as a subset of original `C`; calendar-day branches at the same index |
| Fitted models | Model sample, events/non-events, fitting status, and prediction-reference N; a fitting failure is not a new patient exclusion |

The principal diagram should be readable at publication size. Also generate a detailed audit version with all reasons and branch references, using multiple pages/diagrams if necessary. Do not shrink an enormous diagram into unreadable text.

### 4.3 Eligibility and exclusion semantics

Define the actual combined eligibility state before constructing a display funnel. Known disqualifying evidence can establish ineligibility even when another criterion is missing. Otherwise, unresolved information remains uncertain. Display sequencing must not change the selected set.

Use a fixed first-failure hierarchy for **mutually exclusive displayed ineligibility reasons**, for example: out of calendar scope, nonacute setting, age <18, then BMI <30, among records with enough evidence for that failure. Keep an independent all-reasons table for overlapping failures and uncertainty. Never sum the all-reasons table as if it were a partition.

Unknown setting is not confirmed nonacute. Missing/unmapped BMI is not BMI <30. A missing gas is not a failed obesity-eligibility criterion.

Before selecting an index, retain uncertain records that could precede the earliest confirmed qualifying encounter. Do not filter them away because later records are complete. An encounter disqualified by reliable evidence need not block a later index merely because an unrelated field is missing.

### 4.4 Accounting across units

At the raw-record stage, duplicate removal is a record count. At the encounter stage, eligibility concerns encounter keys/versions. At index selection, convert explicitly to patients.

Patient counts attached to two disjoint encounter branches can overlap because a patient can have both an excluded and an included encounter. Do not assert that these patient counts add to their parent. Assert record/encounter partition identities at the appropriate grain and patient-set unions separately.

After selecting one index per patient, patient and index-encounter counts must agree. Thereafter, true partitions must add at the patient level.

ABG-evaluable and combined-evaluable samples overlap; the former is nested in the latter under the approved combined rule. ICD samples overlap both. Draw them as parallel analytic branches, not randomized treatment arms or mutually exclusive allocations.

### 4.5 Required reconciliation identities

Examples, with exact sets rather than rounded display numbers:

```text
raw records = retained distinct records + removed exact duplicates
resolved Q = complete C + incomplete-adjustment Q
C = ABG-only usable + VBG-only usable + both usable + neither usable
N(C) = outcome-evaluable(k,w) + outcome-unknown(k,w)
outcome-evaluable(k,w) = positive(k,w) + negative(k,w)
C40 is a subset of C, with the same selected encounter for each patient
M_abg is a subset of C_abg_encounter and of C_icd_encounter
M_any_gas is a subset of C_any_gas_encounter and of C_icd_encounter
fitted model N = its registered model-membership N
```

The exact duplicate identity must use the actual row representation for that stage. Additional early-window evidence must not change primary deduplication or selected indexes.

### 4.6 Flow diagram requirements

Use a programmatically generated CONSORT-style box-and-arrow layout labeled **“Observational cohort selection and analysis populations.”** Do not use randomized, allocated, intention-to-treat, lost to trial follow-up, or other trial terminology.

Every node shows a stable stage code, an explicit unit, count, and parent denominator where appropriate. Distinguish exclusions, unresolved states, and analysis subsets by both text and line/fill style. Terminal model boxes link to their model audit pages.

Produce editable vector SVG/PDF and a high-resolution PNG, with an equivalent accessible text/table representation. No manually typed counts. The methods standard informing the reporting is STROBE/RECORD; “CONSORT-style” describes layout only [M1].

## 5. Stage-by-stage descriptive statistics and variable atlas

### 5.1 Two levels of description

**Compact stage table:** one row per meaningful cohort step, showing units/counts, missingness, BMI/age summaries, setting, sex, race/ethnicity, region, gas availability, and outcome-positive/evaluable counts when those quantities exist.

**Detailed stage atlas:** every registered analytic variable at every applicable stage and in key branches. This is the full audit resource, not a selectively curated Table 1.

Make all stage changes inspectable. A summary must say whether it describes raw records, encounters, or unique indexed patients. Pre-index encounter distributions are encounter-weighted; do not call them patient distributions.

### 5.2 Required descriptive populations

Profile at least:

- Each stage before and after major eligibility/selection operations, where fields exist.
- Confirmed ineligible and uncertain-eligibility branches, with available characteristics.
- Resolved versus unresolved index groups, without inventing an index-specific BMI for an unresolved patient.
- `Q`, incomplete-adjustment `Q`, `C`, and `C40`.
- Each four-way usable-gas pattern within `Q` and within `C`.
- Each outcome-observed versus outcome-unknown group within `C`.
- Every unique model sample, including matched samples.
- Each fixed 5-unit BMI band.
- Encounter-wide versus early-window evaluable sets and their intersection.

A variable atlas entry can be unavailable/not applicable when no defensible person-level value exists. For unresolved patients, describe encounter-level evidence and ambiguity rather than selecting a convenient encounter for description.

### 5.3 Continuous variables

For each variable/population, save total N, observed N, missing N/percent, distinct observed values, invalid N, mean, SD, min, max, and prespecified quantiles: 1st, 5th, 25th, 50th, 75th, 95th, and 99th percentiles. Use a declared quantile algorithm.

Provide:

- A histogram or ECDF as the default display.
- A small sparkline in the atlas plus a linked full-size distribution.
- KDE where it adds useful shape information, with bandwidth/kernel documented and common settings for comparisons of the same variable.
- An explicit missingness bar/annotation; do not bury missing observations in the denominator of a normalized density.
- Full-range diagnostics plus a clearly labeled central-range zoom when tails compress the plot. Never silently trim data to make a plot attractive.

For constant or very small samples, use a point/range display and a reason that KDE was not estimated. Do not jitter data to manufacture variation. Counts/dates receive suitable discrete histograms, not inappropriate smooth densities.

Required continuous profiles include BMI, age, specimen-specific encounter maxima, available calendar-day maxima, and any authenticated timing/count diagnostics. CO2 profiles are audit outputs, not a new primary aim or an automatic continuous-outcome regression.

### 5.4 Categorical and binary variables

Save every reviewed level, including explicit unknown and missing states. Show counts, percent of all rows in that population, and percent among nonmissing values; label which is plotted. Do not treat factor-level integers as clinical codes.

Use bars/sparklines with stable category ordering. Preserve rare categories in the protected audit. Reference categories for regressions must be explicit, not determined by which category happens to occur first.

Identifiers are exempt from value displays but not from data-quality summaries. Do not publish row values, direct identifiers, or patient-level dates.

### 5.5 Missingness and sample-change audit

Required outputs:

- Variable missingness table by stage, BMI band, and usable-gas pattern.
- Co-missingness matrix and missingness-pattern counts for adjustment variables and main evidence variables.
- Sequential first-missing-variable accounting for the adjustment-completeness exclusion, plus overlapping per-variable missingness counts.
- Retained versus removed descriptive comparison at major steps. Show differences directly; optional standardized differences must state the standardization denominator and are diagnostics, not proof of balance or missing-at-random.
- At least BMI-by-age support summaries and BMI-by-categorical-adjustment counts for each model sample versus its reference.

Do not fit a significance test to every Table 1 row. Descriptive differences are not hypothesis-screening criteria for changing the model.

### 5.6 Timing and measurement provenance

When source evidence supports it, show BMI observation date relative to index, encounter-to-gas collection lag, number of gases, and first-day/encounter maximum differences. Distinguish date-level from timestamp-level precision.

If the approved BMI is carried forward or derived from history rather than measured at admission, say so. Do not present it as contemporaneous simply because it appears on an encounter row.

If measurement counts or chronology are unavailable, show that limitation. Do not make “first gas” or “number of draws” from a maximum-only input. Additional data acquisition is not a default prerequisite for completing this software refactor.

## 6. Descriptive sampling and observed-occurrence layer

Within each population, BMI band, outcome definition, and available window, save:

- `N`: reference patients.
- `M`: patients with an evaluable outcome.
- `H`: observed positive patients.
- `M/N`: evaluability fraction.
- `H/M`: positivity among evaluable patients, undefined when M=0.
- `H/N`: documented-positive fraction, provided the captured-data denominator is defined.

The identity `(M/N)*(H/M)=H/N` is checked where M>0. With M=0 and N>0, documented captured positives are zero while conditional positivity remains unavailable. That zero is not a statement about underlying physiology. With N=0, all corresponding proportions are unavailable.

For gases, distinguish **test performed** from **usable result available**. A positive result requires authentic specimen/result evidence. An absent usable result does not establish that no test was ordered. Availability models use an explicit observed-result indicator; any additional testing models use the separately authenticated testing flag and exclude unknown testing status from that particular model only.

Show ABG-only, VBG-only, both, and neither as mutually exclusive usable-evidence patterns. Produce a separate table for tested-but-unusable, capture unknown, and source-invalid result reasons. For early-window figures, do not use encounter-wide testing flags as evidence of early testing.

For raw band proportions use a prespecified binomial interval, such as Wilson, with the exact denominator. Do not apply a binomial interval to a standardized mean from a regression.

## 7. Regression specification and model registry

### 7.1 Primary model form

Fit outcome-specific logistic regressions on `C_k_w`:

```r
outcome ~ ns(bmi, knots = K_interior, Boundary.knots = K_boundary) +
  age_at_encounter + factor(sex) + factor(race_ethnicity) + factor(location)
```

Implementation default: four total natural-spline knots at the 5th, 35th, 65th, and 95th BMI percentiles in `C`, computed once without using outcomes. Use the middle two as interior knots and the outer two as natural boundary knots. With `intercept=FALSE`, this is three BMI basis columns plus the model intercept. This numeric choice is a prespecified implementation default, not an empirically established optimum.

Persist numeric knot locations, quantile method, reference-population identity, basis class, column ordering, and software version. Use the same basis specification across outcomes/windows/paired comparisons. Never call `ns(..., df=...)` independently within each model sample or recompute knots on shifted/prediction data. R supports reuse of explicitly defined spline bases [M2].

Natural boundary knots are not the observed data-support boundaries. The fitted spline has linear tails beyond its boundary knots, even where data remain available. Keep those concepts separate in diagnostics.

If knots duplicate or a model lacks sufficient support/rank, emit a specific failure. Do not silently reduce degrees of freedom or pool categories until the estimate appears.

Age remains linear in the initial implementation. Do not add clinical covariates or change the approved completeness set. Use explicit `na.action=na.fail` after constructing the registered model sample so that `glm` cannot silently make another exclusion.

### 7.2 Required model families

| Family | Models and purpose |
|---|---|
| Primary relationship | Adjusted spline models for encounter ABG, combined available-gas, and ICD outcomes |
| Timing sensitivity | Adjusted spline models for the two calendar-day gas outcomes, when qualified |
| Functional-form sensitivity | Linear-BMI models on the exact same samples as each primary/timing outcome model |
| Observation | Adjusted spline models for usable ABG, usable VBG, usable either-gas, and known ICD ascertainment in `C`; early usable-gas observation models when qualified |
| Matched definition comparison | Separate ICD/ABG and ICD/combined pairs; fit both outcomes on identical within-pair patients using the same spline basis |
| Other diagnostic regressions | Only when needed for a defined diagnostic; register and report them like every other fitted model |

Do not automatically cross all models with every historical policy, subgroup, and MNAR assumption. A registry entry describes a distinct fit; a projection registry describes uses of that fit. Reuse one fit for different targets where intended. Report the number of unique fits separately from the number of predictions/projections.

A pure-VBG outcome model, J96-only/E66.2 component analysis, or recognition model conditional on measured CO2 may be added as an explicitly labeled supporting module when the required fields are authenticated. They are not automatic changes to the three approved primary definitions.

### 7.3 Model registry schema

At minimum:

```text
model_id, family, outcome_id, window_id, formula_text, model_form,
training_population_id, eligibility_predicate_id, source_policy_id,
basis_id, factor_reference_id, weight_specification, covariance_method,
n_eligible, n_excluded_outcome, n_excluded_adjustment, n_model,
n_patients, n_events, n_nonevents, n_parameters, model_rank,
status, failure_reason, warnings, fit_runtime, diagnostic_output_id
```

Use no weights by default. Never import the equity project's weights automatically.

Status must distinguish not attempted, pending source, no evaluable sample, constant outcome, rank deficiency, separation, convergence failure, fitted with diagnostic concerns, and successfully fitted. A failed planned model retains its registry entry and sample profile. Do not silently substitute another estimator.

## 8. Full regression audit: every coefficient and every model

This is a core deliverable. It must be usable without opening an R session.

### 8.1 Complete coefficient output

For every fitted model, save and render **all** estimated parameters, including intercept, spline basis terms, age, all factor contrasts, any approved interactions, and parameters of any additional diagnostic regression.

Required coefficient fields:

```text
model_id, term_id, term_label, source_variable, term_type,
level, reference_level, estimate, std_error, conf_low, conf_high,
test_statistic, test_df, p_value, estimate_scale,
exp_estimate, exp_conf_low, exp_conf_high, exponentiation_meaning,
estimation_status, covariance_method
```

Rules:

- Raw log-odds coefficients and standard errors are mandatory.
- Label spline coefficients as basis parameters, not per-BMI-unit clinical effects. Exponentiated basis coefficients are not useful clinical odds ratios; leave clinical-OR fields not applicable or label their mathematical-only meaning explicitly.
- Show factor reference categories as nonestimated reference rows, not coefficients with fabricated standard errors or P values.
- Show aliased/nonestimable terms with reasons. Do not silently omit them.
- Do not filter on P value, significance, coefficient size, or author interest. Do not add significance stars.
- Preserve full precision in data exports. Format the human table without hiding small nonzero values.
- Save the complete coefficient covariance and correlation matrices in long form with matching term order, plus the model specification needed to interpret them.
- No clinical fitted-model object or model frame needs to be exported to provide this audit.

### 8.2 Sample and design diagnostics

Each model audit page must show:

- Exact training population, exclusions, N, unique patients, events and non-events.
- Formula, link/family, numeric knots, categories/reference levels, weights, covariance method, software version, and warnings.
- Design-matrix dimensions/rank, parameter count, residual degrees of freedom, outcome and predictor variation, and support summaries.
- Convergence status/iterations; complete/quasi-separation checks; boundary/fitted-probability problems.
- Scaled design-matrix condition diagnostic and coefficient correlations. Scaling used for diagnosis does not silently change fitted covariate definitions.
- Event/non-event counts per model degree of freedom as descriptive sparsity information, not an automatic validity certificate.
- Full covariate summaries for its actual sample, linked to the atlas.

A predictor that is constant in a particular sample must not disappear silently. Under the specified model, report the nonestimability/structural limitation. Any reduced-form fit requires a separately named variant, not replacement of the planned model.

### 8.3 Fit and residual diagnostics

Provide at least:

- Log likelihood, null and residual deviance, AIC, Brier score, and log loss on training data.
- Observed-versus-fitted probability summaries by BMI band and by prespecified fitted-probability groups.
- Binned residual plots against BMI and age, and appropriate categorical residual summaries.
- Leverage, Cook's distance, and coefficient-influence summaries, using aggregates/quantiles and counts above declared screening thresholds.
- Histograms/ECDFs of fitted probabilities and residuals with event/non-event context.
- Observed versus predicted event totals in the fitting sample; explain the expected approximate equality for an ordinary unpenalized logistic model with intercept.

These are **apparent/in-sample** diagnostics. Do not present apparent AUC, calibration, or loss as external validation. AUC is optional and not the criterion for choosing the BMI model.

Do not use a normal-residual QQ plot as a normality requirement for a binomial outcome. Do not make Hosmer–Lemeshow P values or automatic outlier deletion the pass/fail rule.

Influential patient details, when needed, stay in explicitly protected local review output, not in aggregate HTML/PDF or Git. Influence flags do not authorize removing patients.

### 8.4 Functional-form comparison

Show spline and linear curves on the same scale and the same model/reference populations. Report a valid nested-model likelihood-ratio comparison and degrees of freedom where assumptions and nesting hold, plus direct changes in clinically interpretable contrasts. Verify row identity before comparing likelihoods.

Do not choose the primary model according to the comparison P value. A supported departure from linearity helps interpretation; it is not a gate for whether the approved spline is allowed to run.

### 8.5 Prediction support

For each model/reference/grid/scenario, report:

- Fitting-sample BMI minimum/maximum and dense/sparse ranges.
- Original and transformed BMI outside the observed fitting range, count and percent.
- Numeric gap outside the range, not just a yes/no flag.
- Factor levels unseen in training.
- Local sample/events/non-events around each displayed BMI and BMI-by-age/category coverage.
- Reference N and whether any predictions are unsupported.

Use local sparsity flags as warnings, not undisclosed exclusion rules. Specify their values in configuration; for example, low local N or event counts can mark a segment as sparse, but no claim of universally valid thresholds is warranted.

Never trim different reference patients at different BMI grid points to make curves look well supported. If an unseen factor level prevents a common-reference prediction, show the corresponding curve/reference as unavailable or explicitly define a separately named restricted reference.

## 9. Probability curves, common reference, and uncertainty

### 9.1 Fixed-BMI relationship curves

For outcome k, fit `m_k(b,L)` among its observed-evidence sample and compute:

\[
\mu_{k,C}(b)=\frac{1}{N_C}\sum_{i\in C}\widehat m_k(b,L_i).
\]

Use a prespecified continuous BMI grid, initially 0.25 kg/m2 spacing over the supported displayed range. Save the grid and ranges. Retain an audit view of the full range; do not hide extreme observations to improve the main figure.

Label the common-reference curve:

> Outcome-observed model standardized to the common covariate-complete reference.

This standardizes measured case mix. Calling it the actual physiological probability among untested patients additionally requires an observation-exchangeability/MAR assumption. Do not draw a second numerically identical “MAR curve” as independent confirmation.

Native observed-sample standardization can be retained in the audit, with its different reference explicitly labeled. Crude band proportions belong in a separate panel or comparison with sample-fitted predictions, not as supposed residuals from a common-reference adjusted curve.

### 9.2 Observation curves

Model or tabulate outcome evaluability over the same BMI axis. The principal observation quantity is availability of usable evidence, not the clinical decision to order a test unless authentic ordering/testing evidence is modeled separately.

When using regression, standardize to `C` and show its full raw coefficients/diagnostics. Observed sampling-pattern histograms should be displayed for both `Q` and `C` in the audit so adjustment-completeness selection remains visible.

### 9.3 Pointwise intervals

Use full coefficient covariance for pointwise probability and contrast intervals. For a logistic model with fixed spline basis, accumulate average prediction gradients over the actual reference rows. For probability curves, use an appropriate bounded transformation, such as a delta interval on the logit of the standardized mean, and label the method.

A pointwise 95% band is not a simultaneous band or an uncertainty interval for the missingness assumptions. Do not infer between-definition differences from whether separate bands overlap or cross a reference.

Default inference may remain model-based and conditional on the empirical reference, as in the current workflow. State that these intervals do not include uncertainty in source selection, missingness assumptions, or model misspecification. If a joint patient bootstrap is implemented, document its target, resample shared patients jointly, and do not mix its intervals with conditional intervals without labels.

No facility-cluster correction should be invented from the region variable. If authentic facility identifiers exist, a cluster-aware sensitivity requires a declared covariance plan and cluster counts.

## 10. Exact burden decomposition and secondary PIF

### 10.1 Paired standardization

For a named reference T, outcome model, and BMI transformation g:

\[
p_0=\frac{1}{N_T}\sum_{i\in T}\widehat m(B_i,L_i),\qquad
p_g=\frac{1}{N_T}\sum_{i\in T}\widehat m\{g(B_i),L_i\}.
\]

\[
\Delta=p_0-p_g,\qquad \mathrm{PIF}=1-p_g/p_0.
\]

Keep original reference membership, index, covariates, and weights fixed. This is a model-standardized scenario contrast. It is not automatically a causal estimand.

Required output: both probabilities, signed absolute difference, difference per 1,000, PIF, intervals, reference N, model N, number/percent whose BMI changes, decrement distribution, and support/extrapolation diagnostics.

Default secondary scenario: the active one-unit reduction among observed BMI >30. Default references: each outcome-evaluable sample for its observed-evidence burden, and separately `C` under an explicit common-reference MAR projection. `C40` is a named supporting target reusing the broader primary fit, not another independently estimated relationship.

Do not use undocumented/unknown ICD values as negatives or project missing ICD into the full reference by default. ICD-scenario summaries use a reference with known capture. Within-pair ICD/gas summaries use the same matched reference.

### 10.2 Original-BMI-bin contribution

For original BMI band j:

\[
w_j=N_j/N_T,\quad
\bar p_{0j}=N_j^{-1}\sum_{i\in j}\widehat m(B_i,L_i),\quad
\bar p_{gj}=N_j^{-1}\sum_{i\in j}\widehat m\{g(B_i),L_i\}.
\]

\[
A_j=w_j\bar p_{0j},\quad G_j=w_j\bar p_{gj},\quad
D_j=w_j(\bar p_{0j}-\bar p_{gj}).
\]

Save `A_j`, `G_j`, and `D_j`, together with N, weight, paired bin means, decrement summaries, and support flags. Then:

\[
\sum_j A_j=p_0,\quad \sum_j G_j=p_g,\quad
\sum_j D_j=\Delta,\quad
\mathrm{PIF}=\frac{\sum_j D_j}{\sum_j A_j}.
\]

`1000*D_j` is the band's contribution per 1,000 **reference patients**, not per 1,000 patients in that band. Display the latter only with a different label.

Assign bands using original BMI in both scenarios. Do not move a patient's contribution to a new band after transformation. Empty bands have zero population mass and zero contribution, but their conditional mean probabilities are unavailable. Negative contributions remain negative.

Do not divide by total change to present “percent of benefit” when total change is near zero or contributions have mixed signs.

### 10.3 Do not calculate adjusted PIF from a picture

A fixed-BMI common-covariate curve and a marginal BMI density do not generally reproduce the adjusted cohort PIF, because that operation can break the observed association between BMI and the other covariates.

Use paired predictions on the original joint BMI/covariate rows. The policy-bin means above are the exact visual decomposition. They are not interchangeable with the fixed-BMI relationship curve in Section 9.

Histogram/KDE smoothing choices and plot bins must not change the patient-level standardized PIF. Never numerically integrate a rendered graphic or digitize its shaded area.

### 10.4 Covariance and numerical checks

For observed and transformed average probabilities, use the full coefficient-gradient vectors. For the difference use `grad(p0)-grad(pg)`. For the relative contrast use the gradient of `log(pg/p0)` and back-transform in the correct order.

Apply the same principle to bin contributions. Save the covariance across bin contributions, or equivalent gradient data with full model covariance, so that the variance of their sum reproduces the total-difference variance. Do not add interval endpoints or sum variances while discarding covariance.

Identity transformations must return exact zero differences/PIFs. Zero modeled baseline probability makes a relative fraction undefined; report it explicitly. No clipping of negative fractions or confidence limits. Fixed empirical-reference inference must be labeled as such.

For cross-model contrast inference, account for shared patients/models, for example with a declared joint patient bootstrap. Independent-model intervals are not a valid default for matched or overlapping analyses. Displaying two separately estimated quantities does not require a cross-model hypothesis test.

## 11. Missingness sensitivities: secondary, explicit, and bounded in scope

Keep observed-evidence results, common-reference model projections, and missing-outcome assumptions distinguishable. Do not make a dense grid of assumption-dependent summaries the primary figure.

Implement the existing conditional MAR benchmark and expose the existing MNAR pattern-mixture module as a separate secondary analysis. Its currently documented fixed-observation-status scenario is:

\[
\operatorname{logit}q_0(B,L)=\widehat\eta(B,L)+\log(r)+\log(g_s)(B-40)/5,
\]

with `r` in {0.25, 0.5, 1, 2, 4} and gradient multiplier `g_s` in {0.5, 1, 2}. Use a different symbol/name from the BMI transformation g in code and reports. Evaluate the sensitivity offset at transformed BMI as specified, retaining factual observation membership for that scenario.

Label this **fixed-observation-stratum sensitivity projection**. It is not automatically the reconstructed full-population conditional BMI curve, a natural testing-policy effect, or an identified causal weight-loss effect. A different reconstruction that models observation probability at each BMI is a separate estimand amendment, not a hidden rendering change.

The `r=1, g_s=1` anchor must reproduce the MAR calculation and must not count as additional evidence. Save implied probabilities for unobserved patients at representative BMI values, and distinguish scenario ranges from sampling intervals.

This module must not alter cohort membership, primary coefficients, or primary figures. It can be switched off for a descriptive-only run. Do not add imputation of covariates, an observation-weighting estimator, or new auxiliary-variable adjustment as part of this ticket.

## 12. Required figures and audit displays

### F0. Observational cohort-flow diagram

Produce a compact main version and a detailed audit version from the same ledger. Include source/linkage stages, three-state eligibility, patient/index resolution, adjustment completeness, observation patterns, and actual model branches. Include an accessible tabular equivalent and links to stage profiles. Use multi-page detail rather than illegible text.

### F1. BMI relationship and sampling support

Use a shared continuous BMI axis with aligned panels:

1. Adjusted hypercapnia-probability curves with pointwise intervals, outcome definition, training sample, reference population, and support shown.
2. Usable-evidence probability across BMI. Keep test performed versus result available separate.
3. BMI frequency as percentage of the named reference population per bin, partitioned into ABG only, VBG only, both, and neither usable.

Use outcome facets/paired figures rather than overlaying many indistinguishable curves. Include the approved ICD, arterial, and combined definitions without suggesting biological equivalence.

Use common scales for comparisons where meaningful. Explain any different scales. No double y-axis combining density and risk. No extrapolated segment shown as a solid, fully supported result. Do not multiply ABG and VBG group masses by stacking overlapping subsets.

A smooth density can supplement the histogram, but each group's density must either be clearly area-one for shape comparison or be weighted by its reference-population mass. For the burden-support figure, use the latter or the direct histogram. Display tails and missingness explicitly. Densities do not determine the numerical PIF.

### F2. Named BMI-scenario burden decomposition

For each selected outcome/reference/policy:

- Upper: observed-BMI and transformed-BMI mean predictions by **original** BMI band.
- Lower: signed `1000*D_j` contribution bars, with uncertainty where estimable.
- Header/footer: p0, pg, total difference per 1,000, PIF, model/reference N, changed-BMI percentage, and support warning.

The plotted contributions must sum to the displayed total before formatting. Do not relabel common-reference projections as observed patient counts. Distinguish modeled occurrence from actual H_j.

### F3. Descriptive variable atlas

A full audit figure collection, indexed by variable and stage. Include distribution sparklines with numeric summaries and linked full-size plots. Categorical variables use counts/bars; continuous variables use histograms/ECDFs and selected KDEs. Show retained/excluded and measured/unmeasured comparisons.

### F4. Regression audit pages

One page/section per unique model with full coefficients, covariance access, exact sample, diagnostics, fit plots, influence summaries, and support. Include linear-versus-spline views. Any diagnostic regression also receives full coefficient/sample output.

### F5. Focused supporting results

Show calendar-day comparisons and matched definition analyses with denominator changes; severe-subgroup projections; and the separate missingness sensitivity display. CO2 distributions appear here or in F3 only when they help audit sampling or thresholds.

### Figure/export standards

Use code-generated R/ggplot2/grid/vector figures and editable source, consistent with the working repository. Do not use generative image tools for data-bearing diagrams or plots. This ticket does not require a dashboard framework.

Use readable type at native size, approximately 180–190 mm for full-width manuscript figures and suitable page dimensions for detailed audit diagrams. At least 9-point data labels at final scale; more space rather than smaller text. Provide SVG/PDF masters and 300-dpi PNG. Never distribute font files.

Use redundant line/marker/fill patterns and check grayscale. Titles and captions identify outcome, window, denominator, reference, adjustment, and interval interpretation. Each figure links to its exact aggregate table. No manually copied numbers or fixed legend Ns.

## 13. Reports and machine-readable outputs

### 13.1 Two reports from one saved analysis bundle

**Scientific report:** question, source/denominator summary, concise cohort flow, principal descriptive results, F1, F2, focused sensitivities, and interpretation limitations.

**Full audit report:** complete source status, detailed F0, stage atlas, variable dictionary and distributions, missingness, every regression and raw coefficient, prediction support, numerical reconciliation, and test/render findings.

Both should be generated as self-contained HTML and printable PDF when the environment supports it. Audit HTML may use collapsible sections, but PDF and CSV exports must contain the full content, not only currently expanded sections or the first page of a paginated table. Supply repeated headers/page breaks so long coefficient tables remain readable.

The audit report is not a short summary. No `head()`-only output as a substitute for complete tables. Failed and pending models remain visible. Add a coverage index linking each required stage/variable/model to its report section and exported table.

Use relative links within a run. The report opens with actual source/estimation/review status and unresolved warnings. Do not mark it scientifically accepted because Quarto rendered.

### 13.2 Minimum aggregate output contract

Use typed CSV/JSON/RDS or equivalent, with explicit identifiers and full precision. Suggested tables:

| Output | Contents |
|---|---|
| `source_audit` | Source evidence, coverage scope/status, join/typing/validity counts |
| `cohort_nodes`, `cohort_edges` | All flow accounting and denominator identities |
| `exclusion_reasons`, `exclusion_overlaps` | Sequential versus independent reasons |
| `population_registry` | Exact population definitions, grain, counts, and relationships |
| `variable_dictionary` | All field definitions, units, coding, missingness, and roles |
| `stage_summary` | Compact stage descriptors |
| `variable_summary`, `category_counts` | Complete variable-by-stage/profile statistics |
| `distribution_bins`, `distribution_curves` | Histogram/ECDF/KDE-ready aggregates and their normalization metadata |
| `missingness_patterns` | Marginal and joint missingness accounting |
| `evidence_by_bmi` | N/M/H, probability denominators, and raw bin intervals |
| `observation_patterns`, `timing_audit` | Specimen-pattern and window transitions |
| `model_registry`, `model_sample_audit` | Every fit and its sample/exclusion/status |
| `coefficients`, `coefficient_covariance` | Every parameter and the full covariance matrix |
| `model_fit_diagnostics`, `model_residual_bins`, `model_influence_summary` | Full regression diagnostic package |
| `bmi_basis`, `factor_references` | Numeric spline basis and category encoding |
| `prediction_support` | Grid/scenario/model/reference coverage |
| `probability_curves`, `observation_curves` | Fixed-BMI predictions and intervals with explicit targets |
| `fixed_bmi_contrasts` | Prespecified common BMI contrasts |
| `policy_registry`, `policy_totals`, `policy_contributions` | Paired scenario results and exact decomposition |
| `policy_contribution_covariance` | Covariance needed to reconcile contribution uncertainty |
| `sensitivity_results` | Named MAR/MNAR, timing, and matched outputs without artificial replication counts |
| `reconciliation_checks`, `report_coverage` | Pass/fail/not-run identities and report completeness |

Equivalent table consolidation is acceptable when keys and coverage remain clear. Do not build unnecessary duplicate schemas. Do not persist individual predictions, selected patient/encounter identifiers, or model frames in aggregate artifacts.

Each result should be joinable to `run_id`, analysis/specification ID, population/reference ID, model ID, outcome/window, and policy/method where relevant. Human labels must be generated from this metadata.

## 14. Suggested code organization and command interface

These are proposed module boundaries, not a requirement to create a large framework:

```text
R/
  input_contract.R          # typed fields, source policy, coding validation
  cohort_selection.R       # eligibility, first index, population membership
  cohort_audit.R           # flow ledger, exclusions, stage/variable summaries
  evidence_definitions.R   # observation states and outcome/window logic
  bmi_models.R             # spline specification, model registry, all coefficients
  model_diagnostics.R      # sample, fit, residual, influence, support output
  standardization.R        # fixed-BMI curves and paired policy predictions
  burden_decomposition.R   # original-BMI-band contributions and covariance
  sensitivity_analysis.R   # isolated, explicitly named secondary methods
  reporting.R              # saved-aggregate validation, figures, report data
scripts/
  prepare_common_index_input.py
  run_bmi_hypercapnia.R
  render_bmi_hypercapnia.R
reports/
  bmi_hypercapnia.qmd
  bmi_hypercapnia_audit.qmd
config/
  bmi_hypercapnia_analysis.json
  variable_dictionary.csv
  common_index_source_policy.json
```

Consolidate adjacent helpers if simpler. Existing filenames can be reused, but the new default path must not source frozen historical analysis code to obtain current functions.

Required callable capabilities:

```text
validate_input()
construct_cohort_and_memberships()
build_flow_ledger()
profile_stage_variables()
derive_evidence_states()
resolve_bmi_basis()
fit_registered_models()
extract_complete_model_audit()
standardize_probability_curves()
standardize_policy_and_contributions()
validate_analysis_bundle()
render_scientific_report()
render_audit_report()
```

Recommended Make/CLI separation:

```bash
make test                         # current artificial unit/integration tests
make fixture                      # artificial analysis + both reports + figures
make preflight INPUT=... MANIFEST=...
make cohort-audit INPUT=... MANIFEST=... CONFIG=...
make analyze INPUT=... MANIFEST=... CONFIG=...
make render RUN=...               # scientific + audit, from saved aggregates
make render-html RUN=...
make render-pdf RUN=...
```

These are target interface specifications to implement, not claims that they currently exist. Names may differ if README and tests remain unambiguous.

`cohort-audit` performs no outcome regressions. `analyze` includes the required cohort audit and fits once per unique registered model. `render` never reads clinical inputs or refits. Repeated renders create fresh outputs or explicitly replace only the generated view, not the analysis bundle.

Retire old primary-launcher aliases and historical routing instead of supporting every prior version. Leave Git history and private artifacts intact. Remove or deprecate obsolete default tests that enforce superseded scientific definitions, and replace them with the tests below. Preserve useful behavioral tests by adapting them, not by retaining old scientific paths.

## 15. Performance, privacy, and failure behavior

### 15.1 Performance

Respect the existing source-preparation resource limits and authorized host. Do not pull an entire upstream database into a laptop simply to make more descriptive plots.

- Stream or partition source-level stage summaries where necessary.
- Compute exact means/counts and clearly label any approximate quantiles or plot-only sampling; exact is preferred for principal cohort summaries.
- Generate fixed-BMI predictions in bounded row/grid chunks rather than materializing all patients times all grid points.
- Paired policy predictions must use all reference rows. Do not substitute a random plotting subsample in the numerical PIF.
- Reuse models and basis objects. Distribution plotting and report rendering must not rerun estimation.
- Optional expensive influence summaries may use a declared algorithm or be explicitly unavailable; do not claim a full check after sampling only part of the model.
- Record elapsed time, peak-memory information where available, dependencies, and commands actually run. Do not automatically install packages or rebuild environments without the existing authorization.

### 15.2 Privacy

The full audit is a protected research artifact. Aggregate does not automatically mean safe for public release, especially with rare categories, extrema, or many linked small-cell tables.

Keep clinical inputs, membership sets, patient-level diagnostics, and exact patient dates in protected ignored storage. Do not put them in Git or public HTML. Apply any authorized disclosure rules when producing shareable exports; retain exact internal counts for reconciliation. Disclose suppression and do not turn suppressed values into zero.

No new external publication, email, upload, or upstream write is authorized by this ticket. All default figures and reports remain local/private unless separately approved.

### 15.3 Failure behavior

Separate:

1. Source/candidate coverage failures: stop clinical inference, retain available diagnostic output with partial/unavailable status.
2. Individual unknown eligibility/index: retain in cohort accounting; no invented replacement.
3. Unknown outcome: retain reference membership; exclude only from the relevant observed-outcome fit.
4. Pending optional timing: primary outputs can proceed after primary qualification; early outputs remain pending.
5. Model failure: retain model/sample diagnostics, no substituted estimate.
6. Prediction-support failure: retain the fitted model but mark that model/reference/scenario unavailable or extrapolated as specified.
7. Rendering failure: retain the completed analysis bundle and a clear output failure; do not refit to retry a figure.

Write failure/status records in plain language. No false “all tests passed” when dependencies or private checks were not run.

## 16. Acceptance tests

Implement independent expected-value tests, not only tests comparing two calls to the same helper.

### A. Source and eligibility

- [ ] Reviewed codes/units decode correctly; unknown codes cannot silently become zero.
- [ ] Encoded IDs cannot pass as original IDs without the accepted mapping.
- [ ] Input with an uncovered candidate mapping blocks clinical inference and reports checked scope.
- [ ] Partial-partition counts cannot appear as full-source totals.
- [ ] Exact duplicate records are counted and removed correctly; conflicting versions remain distinguishable.
- [ ] Date 2022-01-01 and age 18 are included; 2023-01-01 and age <18 are excluded.
- [ ] BMI 30 and BMI 40 boundaries are inclusive for cohort/subgroup membership.
- [ ] Missing BMI/age/setting can yield uncertain eligibility, not automatic nonobesity/nonacute exclusion.
- [ ] Reliable disqualifying evidence remains disqualifying despite unrelated missing fields.

### B. Index and cohort ledger

- [ ] First qualifying encounter is chosen before gas and adjustment completeness.
- [ ] Earlier uncertain membership blocks later-index substitution when relevant.
- [ ] Earliest ties/conflicting evidence are not resolved by row order or gas availability.
- [ ] Calendar-day data and altered outcomes do not alter primary indexes.
- [ ] Post-index patient and encounter counts agree.
- [ ] Record, encounter, and patient partitions are checked at the correct grain.
- [ ] First-failure exclusions are exclusive; all-reason overlaps are not incorrectly added.
- [ ] Every flow label reproduces its ledger value; all edges declare their relation and denominator.
- [ ] `C40` and all matched samples have the expected set relationships.

### C. Evidence and descriptive outputs

- [ ] Gas thresholds at 45/50 are inclusive; validity endpoints remain exclusive as configured.
- [ ] Untested and unusable gases remain unknown physiological outcomes.
- [ ] A single available negative establishes only the approved available-evidence negative.
- [ ] Early maxima cannot exceed corresponding encounter maxima; early positive implies encounter positive.
- [ ] Four usable-gas patterns are disjoint and exhaustive in each qualified population/window.
- [ ] N/M/H and the documented-occurrence identity reconcile, including M=0 and N=0.
- [ ] Known-code absence and unavailable diagnosis capture stay distinct.
- [ ] Every registered nonidentifier variable appears in the applicable descriptive atlas or has a justified unavailable state.
- [ ] Category/missing counts, histogram masses, and source-stage totals reconcile.
- [ ] No unweighted mean of subgroup percentages replaces a ratio of summed counts.
- [ ] Constant/sparse variables do not produce fabricated KDEs.

### D. Models and audit coverage

- [ ] Spline numeric knots/basis are fixed across fit/predict/scenario operations.
- [ ] Independent natural-spline prediction checks reproduce fitted probabilities.
- [ ] Linear and spline comparisons use identical training rows.
- [ ] Explicit sample construction matches actual fitted N; no hidden `na.omit` exclusions.
- [ ] Constant outcomes, duplicated knots, rank deficiency, complete/quasi-separation, and convergence failures retain planned model entries.
- [ ] All coefficient terms, including intercept and spline terms, appear in the coefficient table.
- [ ] Reference and aliased terms cannot masquerade as estimated zero effects.
- [ ] Coefficient covariance dimensions/names agree with the model matrix and coefficient vector.
- [ ] Every fitted model, including observation/diagnostic models, has a linked sample profile and diagnostic section.
- [ ] Model-based inference and apparent performance are labeled correctly.
- [ ] Unseen reference categories do not trigger silent target restriction.

### E. Curves and scenario decomposition

- [ ] Fixed-BMI common-reference predictions match independent row-level averaging.
- [ ] Correlated BMI/covariate artificial data demonstrate why multiplying a marginal curve by a marginal BMI density is not used for adjusted PIF.
- [ ] Paired policy predictions retain original covariates, index, and population.
- [ ] One-unit shift acts only above 30 with no floor; exact 30 remains unchanged.
- [ ] An identity policy returns zero difference, PIF, and interval width.
- [ ] Null and negative BMI relationships retain zero/negative contributions without truncation.
- [ ] Original-BMI-bin contributions sum to patient-level p0, pg, difference, and PIF.
- [ ] Display-bin changes do not change the patient-level PIF.
- [ ] Empty bins have zero mass/contribution and unavailable conditional means.
- [ ] Analytic gradients match independent finite differences for curves, differences, PIFs, and contributions.
- [ ] Contribution covariance reproduces the overall difference variance.
- [ ] Unsupported transformed values are counted; no silent floor or re-eligibility filtering.
- [ ] MAR/MNAR identity at the sensitivity anchor is exact within numerical tolerance.
- [ ] Scenario changes do not alter fitted primary models or cohort membership.

### F. Reports, safety, and breaking refactor

- [ ] Clean-session artificial execution produces both reports and all required tables/figures.
- [ ] Reports consume saved aggregates with tripwires proving no clinical-input read or model refit.
- [ ] Full coefficient/category/stage tables survive HTML and PDF export without row truncation.
- [ ] Missing, pending, failed, zero, and not-applicable states have distinct displays.
- [ ] Large Ns, small probabilities, negative contributions, sparse tails, long labels, and mixed missingness render legibly.
- [ ] Native-size and grayscale review is actually performed and recorded.
- [ ] Report coverage identifies missing stage/variable/model sections; no silent omission.
- [ ] No patient identifiers, individual predictions, model frames, or direct dates appear in aggregate bundles/reports.
- [ ] Old bundles fail clearly rather than being relabeled or auto-migrated.
- [ ] Default commands/instructions have one current scientific authority and no hidden historical dispatch.
- [ ] Input/config/source identities are recorded and changed inputs cannot silently reuse cached results.

## 17. Implementation work packages

### WP1. Replace scientific authority and registry

Update `AGENTS.md`, plan, README, entrypoints, and configuration. Define populations, models, references, evidence windows, display bins, knots, and policies independently. Remove obsolete compatibility paths from the active workflow. Acceptance: one unambiguous current specification and callable artificial pipeline skeleton.

### WP2. Build cohort ledger and descriptive atlas first

Instrument existing preparation/selection functions; implement stage memberships, flow identities, profiles, missingness, and partial-source reports. Acceptance: a complete artificial audit report without fitting any outcome models, including unresolved and excluded branches.

### WP3. Fit flexible models and publish the full model audit

Implement fixed spline basis, required regression families, complete coefficients/covariance, diagnostics, and prediction support. Acceptance: every artificial fit and planned failure has matching sample and report coverage.

### WP4. Implement curves and exact burden contributions

Generate common-reference curves, observational summaries, fixed BMI contrasts, paired policy quantities, bin contributions, and covariance. Acceptance: independent numerical identities and gradient tests pass.

### WP5. Produce scientific and audit figures/reports

Generate F0–F5 and complete HTML/PDF/CSV output from saved aggregates. Acceptance: actual full-report/native-size/grayscale review with a coverage record, including adverse artificial scenarios.

### WP6. Isolate sensitivities and finish the handoff

Wire timing, matched comparisons, severe-target, linear-form, and named missingness modules without altering primary definitions. Document clinical source/environment blockers, exact commands to run on the authorized host, and what remains unrun. Acceptance: all software requirements satisfied or individually identified, with no clinical success claim absent execution.

Each work package should leave a coherent, testable repository. Do not postpone the descriptive audit to the end as cosmetic reporting.

## 18. Required Codex closeout

Return:

1. Files changed, obsolete paths removed, and the current entrypoint/commands.
2. A brief mapping from this ticket's work packages to implemented modules and outputs.
3. Exact commands run, test results, skipped checks/dependencies, and any model/render failures encountered on artificial data.
4. Paths to artificial scientific and audit reports, flow diagrams, full coefficient tables, and reconciliation results.
5. An explicit statement of whether clinical data were opened, whether source qualification passed, and whether any clinical models ran.
6. Remaining scientific/data decisions, separated from engineering defects. Do not re-open settled decisions merely because an old instruction file disagrees with this ticket.

End-to-end artificial success plus a precise private-source blocker is an acceptable software handoff. A few new figures without stage accounting, complete coefficients, and exact burden reconciliation is not.

## 19. Source basis and methodological references

The implementation requirements above are the owner's approved refactor plus explicit implementation defaults. They are not claims that these modules already exist. Sources describe the current starting point and the reasoning constraints; they do not independently endorse the chosen knot/count/display defaults.

### Repository basis, read at the stated commit

- [R1: Current analysis instructions](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/AGENTS.md)
- [R2: Common-index estimator](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/R/common_index_hypercapnia.R)
- [R3: Aggregate/reporting contract](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/R/common_index_reporting.R)
- [R4: Current Quarto report](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/reports/bmi_hypercapnia_triangulation.qmd)
- [R5: Current commands](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/Makefile)
- [R6: Demonstrated candidate-mapping gap](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/docs/COMMON_INDEX_SOURCE_GAP_HANDOFF.md)
- [R7: Approved gas/ICD source policy](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/blob/8735505254b8b806c20478da39f580bc4b845581/config/common_index_source_policy.json)
- [R8: Equity project structural template](https://github.com/reblocke/hypercapnia-diagnostic-equity/blob/0d38bedc262920880234640e2d17a844648ba72a/stata/do/35_racial_disparities.do). Borrow the testing/evidence/recognition organization, not its weights, eligibility, fixed legend counts, or repeated-encounter estimand.

### Methods and implementation support

- **[M1]** Benchimol EI et al. *The REporting of studies Conducted using Observational Routinely-collected health Data (RECORD) Statement.* PLoS Medicine. 2015;12:e1001885. [doi:10.1371/journal.pmed.1001885](https://doi.org/10.1371/journal.pmed.1001885). Supports detailed selection/linkage reporting and code/algorithm transparency; not a trial-design label.
- **[M2]** R Core / `splines` documentation, [`ns`](https://stat.ethz.ch/R-manual/R-devel/library/splines/html/ns.html) and [`predict.ns`](https://stat.ethz.ch/R-manual/R-devel/library/splines/html/predict.bs.html). Supports fixed natural-spline bases and safe evaluation; numeric knot defaults here are design choices.
- **[M3]** Arel-Bundock V, Greifer N, Heiss A. *How to Interpret Statistical Models Using marginaleffects for R and Python.* J Stat Softw. 2024;111(9). [doi:10.18637/jss.v111.i09](https://doi.org/10.18637/jss.v111.i09). Project source; separates quantity, prediction grid, aggregation, and uncertainty.
- **[M4]** Degtiar I, Rose S. *A Review of Generalizability and Transportability.* Annu Rev Stat Appl. 2023;10:501–524. [doi:10.1146/annurev-statistics-042522-103837](https://doi.org/10.1146/annurev-statistics-042522-103837). Project source; distinguishes study/analysis/reference populations and assumptions for generalization.
- **[M5]** Weiskopf NG et al. *Healthcare utilization is a collider: an introduction to collider bias in EHR data reuse.* JAMIA. 2023;30:971–977. [doi:10.1093/jamia/ocad013](https://doi.org/10.1093/jamia/ocad013). Project source; motivates explicit observation/selection accounting.
- **[M6]** Hernán MA, Taubman SL. *Does obesity shorten life? The importance of well-defined interventions to answer causal questions.* Int J Obes. 2008;32:S8–S14. [doi:10.1038/ijo.2008.82](https://doi.org/10.1038/ijo.2008.82). Project source; distinguishes BMI substitution from a well-defined weight-loss intervention.

**Final acceptance principle:** A reviewer must be able to follow an estimate backward from the figure to its paired predictions, model, exact analysis sample, variable definitions, cohort transitions, and qualified source. Every transition must be inspectable without treating a plotting choice as an epidemiologic assumption.
