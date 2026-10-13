# Comparison of the obesity impact-fraction analyses

Reviewed October 12, 2026. The Stata and R tracks estimate different conditional
impact fractions. The Stata import consolidates access to an existing analysis;
it does not resolve the target population or select the primary ATS estimand.
No clinical model or report was rerun for this comparison.

## Evidence and version map

| ID | Version/source | Role and evidence status |
| --- | --- | --- |
| S1 | [Preserved Stata source](../archive/stata/36_subpop_hazard.source.do), upstream commit `d5d269168eafc7905c9238a5486fc03a62b55ec3` | Source-implemented severe-obesity analysis; [runnable duplicate](../stata/do/36_subpop_hazard.do) preserves the estimators/PIF calculations with four declared profile-plotting substitutions |
| S2 | Upstream `reports/legacy/hypercapnia-subpop-hazard/16 Mar 2026/` and `17 Mar 2026/` tables/figures | Retained aggregate output inspected; producing input/run provenance unverified |
| R1 | [Canonical R QMD](../reports/obesity_hrf_paf_analysis.qmd) and its retained local PDF | Source-implemented analysis and retained output inspected; exact input/render lineage unverified |
| R2 | [September trainee PDF](../Documents/AS-edits-9-8------obesity-hrf.pdf) | Retained output inspected; corresponding updated QMD unavailable; not adopted canonical source |
| H1 | [Archival reconstruction](../reports/reconstructed_obesity_hrf_from_pdf.qmd) | Earlier everyone-to-BMI-25 calculation and recovered workflow; archival |
| H2 | `Code/obesity hrf.qmd`, `Code/BL edits - obesity hrf.qmd`, `Code/reconstructed_obesity_hrf_from_pdf.qmd`, `Code/refactored_obesity_hrf_paf_analysis.qmd` | Historical exploratory/edit/reconstruction/refactor sources; not parallel current entrypoints |

The September commit added a PDF, not an updated canonical QMD. Earlier sources
had weaker missing-gas handling and undefined attrition flags; the refactor
introduced explicit availability flags, respiratory-status groups, and model-frame
standardization. None of the historical versions is silently deleted or promoted.

The [import receipt](stata_import_provenance.json) pins S1. The
[structured audit records](audits/analysis_comparison.json) pin reviewed sources,
PDFs, and aggregate exhibits by SHA-256 and record missing evidence. Local
extractions, receipts, previews, and original aggregate files are under ignored
`artifacts/evidence/`; they are not distributed by a fresh clone.

## Methods compared

| Dimension | S1: Stata severe-obesity track | R1: canonical R | R2: September trainee output |
| --- | --- | --- | --- |
| Question | Within the obesity-source/BMI >=40 cohort, compare observed BMI with assignment to 40 | Within BMI-recorded/classifiable-HRF encounters, compare observed BMI with named BMI interventions | Same broad R question, with different gas rule and interventions |
| Population/grain | `OBESITY_rfs == 1`, `bmi >=40`, complete BMI/age/sex/race-ethnicity/location; ABG outcome additionally requires `has_abg == 1` | Recorded current BMI and classifiable HRF; fitted-model rows additionally require complete model covariates | Printed primary cohort has 112,009 rows and no missing model covariates |
| Source selection | Shared enriched suspicion cohort; obesity-branch restriction explicitly avoids making gas testing the denominator for diagnosis outcome | Further conditions on recorded BMI and a usable gas pair | Similar BMI/gas restriction; source selection not independently established |
| BMI | Derived `bmi`: upstream current, prior, then height/weight fallback; provenance/timing varies | Numeric parse of `curr_bmi` only | Current BMI parse |
| Primary outcome | Upstream diagnosis composite: J96.02/J96.12/J96.22/J96.92 plus E66.2 | NIV or IMV plus hypercapnic acidosis from either qualifying ABG or VBG | NIV or IMV plus hypercapnic acidosis, using ABG first when a complete arterial pair exists |
| Gas outcome/thresholds | `hypercap_on_abg` from upstream `paco2_flag >=45` criterion in ABG subset; no pH/support condition added | Arterial CO2 >=45 or venous CO2 >=50 with pH <=7.35 | Same CO2 thresholds, but primary pH <7.35 (printed p.10) |
| Missingness | Drops missing adjustment fields; spline models also drop missing outcomes; inherits upstream diagnosis/gas flag semantics | Missing gases unclassifiable; unknown sex/ethnicity explicit; strict sensitivity excludes lab/ICD-discordant records | Printed cohort complete; differing source precedence and boundary can alter cases |
| Adjustment | Age, sex, combined race/ethnicity, location | Age, sex, ethnicity | Age, sex, ethnicity |
| Functional form | Linear BMI/age and restricted cubic splines, three knots at each model sample's p5/p50/p95 | Linear BMI and age on log-odds scale | Linear BMI and age on log-odds scale |
| Counterfactual | Everyone in each fitted severe-obesity model sample assigned BMI 40 | Everyone to25 proof of concept; caps at25/30/40; separately refitted BMI >=40 subgroup capped at40 | Everyone to30 or25; BMI >=30 assigned29.9; clamp BMI to18.5-25 |
| Standardization | `margins` observed and counterfactual probabilities over each estimation sample | Average predictions over exactly the complete-case `model.frame` | Average predictions over the regression cohort; point function uses an outer observed-risk variable |
| Uncertainty | `nlcom` model-based/delta-method PIF intervals; model covariance also underlies plotting intervals | Model coefficient intervals; no PIF or curve intervals | Row-resampling bootstrap with model refitting and recomputed risks; actual `n_boot=200` overrides default2,000 |
| Dependence/weights | Unweighted; no patient/site clustering in model calls | Unweighted; no patient/site clustering | Unweighted row bootstrap; no patient clustering |

These are not equivalent R/Stata/Python implementations of one analysis. Different
outcomes, exposure sources, selection rules, adjustment, and interventions prevent
interpreting numerical differences as port failures. No arbitrary shared sample
size or universal outcome definition is imposed.

R1 also fits a strict lab-plus-ICD sensitivity model in a concordant-case/control
cohort and an HRF-versus-compensated-hypercapnia model in a physiological
hypercapnia subgroup. These are additional selected populations, not sequential
attrition steps or replications of the primary PIF. The severe-obesity R PIF is
computed from a separately refitted model. Its optional PIF divided by mean
BMI excess is an approximation, not an independently estimated effect per BMI
point, and is not promoted as a finding here.

Source anchors: S1 cohort lines135-141, linear models/margins lines231-254,
splines lines274-336 and430-481 in the archived file. R1 definitions lines196-247,
cohorts457-481, standardization308-338, interventions655-703. R2 printed pages10,
16-17,25,40-52. The imported file's line numbering differs because its header
was adapted.

## Available findings

All values below are transcribed from inspected retained output. They are not
newly reproduced or accepted submission estimates.

### Cohorts and events

| Evidence | Denominator | Events/other observed fields | Exact location and limits |
| --- | ---: | --- | --- |
| S2 baseline cohort | 148,321 | Diagnosis HRF:1,890 (printed1.3%); ABG obtained:4,463 (3.0%); hypercapnia flag:2,046 (1.4%); median BMI43.3 (IQR41.3-46.4) | Both March workbooks, `Sheet1!B2:B3,B21:B23`; baseline table denominator, not verified denominator for every fitted model |
| R1 primary cohort | 112,009 | HRF:10,184; non-HRF:101,825 | Canonical PDF p.19; BMI-category totals p.16 agree. Input/render identity unverified |
| R2 primary cohort | 112,009 | HRF:9,200; non-HRF:102,809 | September PDF pp.16-17; identical total N does not establish identical cases |
| R1 severe-obesity model | 10,217 | Model-standardized observed probability0.1266 | Canonical PDF p.25; separately fitted R subgroup, not the S2 cohort |

S2 is a source-branch severe-obesity cohort, while R1/R2 are gas-classifiable
cohorts across BMI. Their diagnosis and support-plus-acidosis event counts should
not be compared as prevalence estimates of the same construct. The shared
enriched source cohort is not a population sampling frame for all hospital
encounters. Current RDS/DTA lineage and key uniqueness remain unverified.

### Model-standardized intervention results

| Version/population | Intervention | Observed probability | Counterfactual probability | PIF | 95% interval |
| --- | --- | ---: | ---: | ---: | --- |
| R1 primary | Everyone to BMI25 | 0.0909 | 0.0848 | 6.70% | Unavailable |
| R1 primary | BMI >25 capped at25 | 0.0909 | 0.0833 | 8.37% | Unavailable |
| R1 primary | BMI >30 capped at30 | 0.0909 | 0.0871 | 4.25% | Unavailable |
| R1 primary | BMI >40 capped at40 | 0.0909 | 0.0903 | 0.65% | Unavailable |
| R1 BMI >=40 subgroup | BMI >40 capped at40 | 0.1266 | 0.1043 | 17.56% | Unavailable |
| R2 primary | Everyone to BMI30 | 0.0821 | 0.0831 | -1.18% | -1.29% to -1.07% |
| R2 primary | Everyone to BMI25 | 0.0821 | 0.0760 | 7.49% | 6.19% to8.65% |
| R2 primary | BMI >=30 assigned29.9 | 0.0821 | 0.0782 | 4.83% | 4.12% to5.73% |
| R2 primary | Clamp BMI to18.5-25 | 0.0821 | 0.0746 | 9.19% | 7.89% to10.87% |
| S1/S2 | BMI assigned40, linear/spline diagnosis and ABG models | Unavailable | Unavailable | Unavailable | Source-implemented; retained numerical output not located |

R1 values are from canonical PDF p.25 (Table1); R2 values from September PDF
p.52. Probabilities/PIFs use their printed precision, so do not recalculate
ratios from rounded display values. R2's negative everyone-to30 result is
retained: that intervention increases BMI for some encounters. It is not an
obesity-removal intervention. The R2 formatted negative interval contains an
ambiguous dash sequence; the separate lower/upper columns establish both
bounds as negative. Do not attach R2 intervals to R1 estimates.

The original everyone-to25 result is distinct from a BMI cap that leaves lower
BMI unchanged. The two severe-obesity tracks also differ: R1's17.56% is not
evidence of agreement with the unavailable S1 PIF.

### Bounded search for Stata estimates

Checked `reports/stata-logs/hypercapnia/subpop-hazard/`,
`reports/tables/hypercapnia/subpop-hazard/`,
`reports/figures/hypercapnia/subpop-hazard/`, and
`reports/legacy/hypercapnia-subpop-hazard/` in the three available local
TriNetX checkouts (main Box checkout, historical Research checkout, encounter
checkout). The current output roots were absent. Legacy roots contained source
snapshots, two baseline workbooks, and four TIFFs, but no result logs or PIF
tables. No other host or private execution namespace was searched.
This is unavailable evidence in the inspected locations, not proof that the
historical estimates never existed. The local search receipt is retained.

## Exhibits and what they support

| Exhibit | Observed content | Limitations/reuse recommendation |
| --- | --- | --- |
| S2 ABG BMI spline, March16/17 | Increasing plotted probability across BMI40-75 with dashed interval bounds | `xblc, pr eform` holds other covariates at zero; not standardized over the cohort. No figure-level description of denominator/profile/interval method. Do not digitize it to recover a PIF |
| S2 ABG age spline, March16/17 | Increasing plotted probability across the shown age range, with widening interval bounds | Same conditional-profile issue; metadata alone does not establish manuscript resolution. Preserve the historical file and review before submission |
| S2 baseline workbook | Cohort composition and observed flags summarized above | Aggregate source inspected; not a standardized-risk or PIF table |
| R1 Figure1, p.17 | Crude HRF proportions elevated at underweight and severe-obesity categories | Supports descriptive pattern, not an adjusted BMI shape or causal effect |
| R1 Figure2, p.22 | Strict-definition category proportions | Different selected concordant lab/ICD denominator |
| R1 Figure3, p.25 | Four primary-population PIF points | No uncertainty, title clipped; proof-of-concept and intervention rows need clearer hierarchy |
| R1 Figure4, p.27 | Standardized BMI-risk curve over covariate distribution | Monotonic by linear-logit specification; no interval. Unlike S2 curves, this is cohort standardization |
| R2 result table, p.52 | Four interventions with bootstrap intervals | Only200 refits, updated executable source unavailable, and row dependence unaddressed |

S2 TIFFs are808x538 pixels. Their saved DPI metadata does not justify a
publication-resolution claim. PNG previews were produced only for local
inspection; original TIFF bytes were preserved. R PDF pages19,25,27 and the
September pages10,17,49,52 were visually checked for the comparisons above.
The native PDF extraction receipt was reused after hash verification for R1;
R2 required whole-document Poppler fallback because the initial router returned
sparse pages. No unreadable native fragments were used as authoritative results.

## Prioritized unresolved questions and proposed next steps

1. **Choose the scientific question before the abstract.** Is the goal excess
   BMI above40 within the obesity-selected source cohort, or BMI interventions
   within gas-classifiable encounters? Both can be useful, but neither is
   automatically the primary analysis. Decide target population, outcome,
   intervention, and encounter-versus-patient interpretation together.
2. **Authenticate source and timing.** Bind the RDS/DTA to a producer, variant,
   conversion, and patient/encounter keys. Verify current/prior/calculated BMI,
   gas specimen/time pairing, measured versus calculated pH, and support timing.
   The shared converter is a lead, not proof of the local RDS lineage.
3. **Recover missing result/source evidence.** Seek the retained S1 PIF logs in
   the known private execution location and recover the September QMD. If neither
   is available, retain the gaps and plan a separately authorized reproduction.
4. **Review inherited implementation and missingness issues.** The archived Stata fails with decimal double-precision BMI at `xblc`; the
   October 12 precision repair now completes decimal and integer fixtures.
   The archive and failed receipts remain unchanged. `ds s_bmi*` includes `s_bmi40*` during an ICD
   plotting refit. In R1, unknown ventilation can fall through to HRF-negative;
   numeric coercion can misinterpret factor-coded ICD flags. Clinical impact of
   these findings is unmeasured. The authorized plotting precision repair leaves these other scientific
   questions unresolved.
5. **Resolve R definition drift and inference.** R1/R2 differ on source precedence,
   pH boundary, and intervention. R1's strict sensitivity changes denominator,
   and its attrition differences treat separate cohort branches as sequential.
   Review BMI functional form, patient/site dependence, and interval stability
   for the chosen estimand. Avoid automatically adding likely mediators.
6. **Build one abstract story and exhibit after decisions.** Select a supported
   conditional impact-fraction claim, its observed/counterfactual probabilities,
   uncertainty, and a readable exhibit. Preserve actual negative/null results
   and keep the other analysis clearly secondary or exploratory.

These recommendations are proposed. The import did not select an ATS estimand,
change either scientific specification, rerun clinical analyses, or publish
historical results.
