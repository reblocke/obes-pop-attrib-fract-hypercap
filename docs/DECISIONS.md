# Analysis decisions

## Primary authority — confirmed 2026-10-14

The [implementation plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) and `reports/bmi_hypercapnia_triangulation.qmd` define the primary **common-index BMI ≥30 study**. This replaces the frame-specific grid as primary; that grid remains runnable supporting work.

| Decision | Confirmed specification |
| --- | --- |
| Common population | Adults ≥18; first qualifying 2022 ED/inpatient encounter with legacy BMI ≥30, selected before gas availability/completeness |
| BMI contrast | Observed BMI >30 minus exactly one; BMI =30 unchanged; no floor, caps or reselection |
| Reference | Resolved common indexes with complete inherited adjustment; same full reference for both gas projections |
| Models | Linear BMI/age, factor sex/race-ethnicity/region; legacy derived BMI; no new predictors or imputation |
| Evidence definitions | ABG ≥45 separately from ABG ≥45 or VBG ≥50; inclusive thresholds; either usable specimen suffices for combined evidence |
| Missing gases | Unknown preserved; observed benchmark plus conditional MAR and exploratory MNAR projections |
| MNAR assumptions | Missing/observed odds at BMI 40: 0.25/0.5/1/2/4; relative odds-gradient multiplier per five BMI: 0.5/1/2; membership fixed and offset evaluated at shifted BMI |
| BMI ≥40 sensitivity | Restrict original common indexes and re-average primary models; no new index or refit |
| Timing | Encounter maxima primary; original-index calendar-day sensitivity, not elapsed 24 hours; pending source evidence allowed |
| ICD comparison | Separate matched ICD/arterial and ICD/either-gas pairs with known ICD capture; no both-specimen requirement, no missing-ICD projection |
| Uncertainty | Pointwise full-coefficient delta method; empirical references/observation status and sensitivity parameters fixed |
| Terminology | Model-standardized probability difference and potential impact fraction; no incidence-reduction or causal-prevention claim |

A common BMI shift alone did not align the previous populations, reference distributions or clinical episodes. This decision fixes the index and target for the new projections. Observed benchmarks still average selected measured cases; MAR/MNAR full-reference projections require assumptions. The combined criterion also changes specimen ascertainment. Matching PIFs are not evidence that those differences are absent.

An available-gas negative does not establish negativity of an unmeasured specimen. No usable evidence stays unknown. Retain the five-code ICD composite including E66.2, describing its obesity-containing coding. No pH/support criterion or E66.2 exclusion is introduced.

## Source policy and release — confirmed 2026-10-15

- Use ordinary unadjusted PCO₂. LOINC 2019-8 is arterial and 2021-4 venous; 11557-6 alone is unspecified blood and requires authenticated specimen evidence. Temperature-adjusted records remain outside primary outcomes and are reported in preparation audits.
- Retain strict validity intervals 5 < arterial PCO₂ <200 and 10 < venous PCO₂ <250 mm Hg, with explicit reviewed conversion. These differ from inclusive outcome thresholds ≥45/≥50. Missing/incompatible units and unusable results remain unknown.
- No target code in a complete available captured encounter diagnosis extract is documented-ICD negative; another diagnosis is not required. Incomplete/unavailable capture remains unknown. Retain all five codes.
- Bind `unadjusted_pco2_v1` in new version-3 clinical manifests and hashed JSON field evidence. Existing bundles retain their recorded definitions and are never relabeled under this policy.
- Review/commit/push/merge code before qualification, then execute on the Mini from the clean merged revision. The owner will resume on the home network. Private reconciliation and clinical execution remain unrun here; calendar-day evidence may remain pending.

## Data and interpretation judgments still requiring evidence

The [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) identifies exact input/variant/conversion, original keys and chronology, expanded BMI ≥30 coverage, legacy derivation/dictionary coverage, actual specimen/unit/window mappings, testing evidence, ICD capture and calendar-day mapping. Scientific source rules above are settled; their application still needs actual evidence. Use the [home-network handoff](CLINICAL_RUN_HANDOFF.md).

Existing accepted upstream evidence is reused first; source absence is not inferred from an unavailable product on this host. No replacement export or timestamp acquisition is presumed necessary. Version-3 review must bind the expanded study; an old schema/hash pass alone is insufficient. Remaining source judgments are made from actual records/receipts, not invented here.

Scientific limits remain after source qualification: demographics-only MAR, informative ordering/specimen/frequency, model form, covariate missingness, shifted BMI support and causal confounding. The MNAR range is exploratory, not a clinical plausibility certificate.

## 2026-10-15 operational source bindings

The accepted FULL_DATA dictionary uses Stata calendar days, coded settings/demographics and separate `race`/`ethnicity`; the preparation configuration explicitly selects `accepted_stata_full_data_v1`. Decode the dictionary and reproduce the inherited ordered combined-category rule, leaving BMI/age unchanged. Missing raw race/ethnicity requires review rather than a new default assignment. The independent retained-reference category comparison passed. Previously typed preparation configurations retain `typed_v1`; saved results are unchanged.

Raw-source projection streams disjoint patient-hash partitions because direct projection/accumulation exceeded the execution caps. All raw rows for every original key remain together before consensus; only then is the agreed study scope applied and covered keys retained. Contradictory, missing and explicitly unknown settings remain uncertain. This is a resource fix, with reconciliation and fail-closed coverage, not a different sampling frame. External research scratch is required on this Mini; source products are never rebuilt or overwritten. No estimand, counterfactual, threshold or missing-outcome assumption changes here.

The completed bounded Mini check demonstrated missing legacy mappings for potential adult 2022 EMER/IMP keys (adult birth-year proxy, exact age/BMI not adjudicated). The approved study is not silently restricted to historical compatibility membership. Clinical estimation stops pending the separately named mapping described in [the source-gap handoff](COMMON_INDEX_SOURCE_GAP_HANDOFF.md); other primary gas/ICD qualification remains required.

## Dated superseded history and runnable archives

- **2026-10-13:** observed BMI >30 minus one became primary within three independently indexed frames (BMI ≥40, ABG obtained, either gas obtained), with nine encounter and six calendar-day cells. Its unchanged source, report, plan, decisions and tests are preserved at `archive/2026-10-14-frame-specific/` from commit `d8909df`. Default saved-run review recognizes those version-2 bundles. Dedicated frame commands retain estimation/testing in ignored workspaces.
- **Earlier 2026-10-13:** BMI >40 set to 40 was primary; superseded by the eligibility-restricted one-unit shift. The older unrestricted BMI-minus-one proposal was also superseded. Exact original sources/documents and version-1 BMI-to-40 report machinery remain under `archive/2026-10-13-bmi-to-40/`.
- Historical R remains a distinct repaired runnable track at `archive/r/obesity_hrf_paf_analysis.qmd`, with its HRF/acidosis/support outcomes, recorded BMI, age/sex/ethnicity and BMI-25/30/40 scenarios. Unknown ventilation/labs, actual 0/1 ICD decoding and parent-branch attrition were repaired without changing its historical model definitions. The reconstruction remains unchanged.
- Stata retains its immutable source and runnable repaired copy, obesity-source/BMI ≥40 cohort, legacy derived BMI, five-code/ABG definitions, demographic/region adjustment, spline/linear models and BMI-to-40 PIF. The authorized four-call precision repair remains its only analysis-body substitution beyond documented import changes. No new Stata edits are authorized by this update.

No archived estimate is relabeled as the common-index study. See [archive index](../archive/README.md) and [historical comparison](ANALYSIS_COMPARISON.md).
