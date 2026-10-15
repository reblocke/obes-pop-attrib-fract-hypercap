# BMI–hypercapnia common-index implementation plan

Approved revision: **2026-10-14**. The primary study now uses a common first BMI ≥30 index and separate arterial and combined-gas projections. This replaces the version-2 frame-specific grid as primary. The one-unit BMI >30 shift remains unchanged. No BMI-to-30/40 cap is adopted.

## Scientific decisions

- Adults ≥18; 2022 ED/inpatient; original patient/encounter keys. First qualifying BMI ≥30 encounter selected before gas availability or covariate completeness. Uncertain earlier eligibility/chronology remains unresolved, with no later-admission substitution.
- One common reference of resolved indexes with complete legacy BMI/age/sex/race-ethnicity/region values. Keep incomplete patients in cohort accounting. No covariate imputation or added predictors.
- BMI >30 decreases by exactly 1 kg/m²; BMI =30 unchanged; no floor. Retain the original index and observation status in both prediction scenarios.
- Primary encounter outcomes: PaCO₂ ≥45, and PaCO₂ ≥45 or PvCO₂ ≥50 among available usable gases. A combined negative is an available-evidence negative, not proof that an unmeasured specimen is normal. No usable result remains unknown.
- Index-calendar-day sensitivities retain those same indexes and require collection date equal to encounter-start date. Date-only precision suffices; no elapsed-24-hour, pH, support or paired-sample requirement is introduced.
- The BMI ≥40 sensitivity restricts common-index reference rows. Reuse the BMI ≥30 fitted models; do not reindex or refit.
- Fit linear logistic models using the unchanged Stata adjustment set. Failed, separated or unsupported models retain explicit empty positions. No substitute estimator or nonlinear selection.

## Estimation and comparison

Each gas/window model is fitted once among observed, covariate-complete patients. Observed benchmarks average over the corresponding observed reference subset. MAR projections average over the same full reference for both criteria. Model N, reference N, unknown-outcome N, shifted percentage and BMI support are distinct quantities.

For unobserved outcomes use the exploratory pattern mixture:

`logit(q0(B,L)) = eta(B,L) + log(r) + log(g)*(B-40)/5`.

Cross r = 0.25, 0.5, 1, 2, 4 with g = 0.5, 1, 2. r is the missing/observed odds ratio at BMI 40; g modifies the relative odds gradient per five BMI units. Evaluate the offset at shifted BMI too. Hold empirical observation status fixed. The r=g=1 MNAR anchor is identical to MAR and is not independent evidence.

Use these scenarios separately for arterial and combined criteria, both windows and both reference targets. Parameters are assumptions, not identified estimates or validated clinical bounds. MAR conditional on demographics is a strong benchmark; common standardization cannot correct unmeasured selection, testing frequency or specimen-dependent ascertainment.

Report paired probabilities, absolute difference per 1,000 and PIF `1 - p_shifted/p_observed`. Full-coefficient delta-method intervals are pointwise and conditional on empirical reference, observation membership and sensitivity parameters. Retain negative values and small nonzero estimates. Do not label the contrasts incidence reduction, causal prevention or the effect of individual weight loss.

Matched coding comparisons are separate: ICD/ABG requires usable ABG and known ICD; ICD/combined accepts either usable gas and known ICD. Each pair fits both outcomes on identical complete rows. The pairs need not share the same N. Retain J96.02/J96.12/J96.22/J96.92/E66.2; do not project missing ICD under MAR or require both gas specimens.

## Implementation and interfaces

- `R/common_index_hypercapnia.R` implements selection, eight unique models, paired standardization and audits, using existing validated source/selection helpers. The ordered registry has 140 positions: 136 gas benchmark/projection/scenario positions plus four matched-comparison positions. Many positions reuse a fitted model; they are not independent estimates.
- Version-3 input manifests bind `study_design=common_index_bmi_ge30_v1` and the exact population policy, in addition to the existing seven reviewed source gates and evidence hashes. Version-2 manifests cannot qualify the expanded study automatically.
- Version-3 aggregate-only bundles bind design/scenario/registry, exact source and input identities, model/reference counts, sensitivity parameters, probabilities/intervals and audits. No identifiers, indexes, model objects/data or individual predictions are persisted.
- Fit once per analysis run. Default `make render`, `render-html`, `render-pdf` require explicit saved RUN and never load clinical inputs or refit.
- Preserve unchanged version-2 sources at `archive/2026-10-14-frame-specific/` with commit/hash provenance. Dedicated frame commands run a verified frozen copy in ignored storage. Saved version-1/2 review dispatches to frozen readers/reports; old results retain their original labels.

## Existing-source qualification

Reuse accepted source products and receipts first; FULL_DATA/pre-screen evidence is preferred. Bind the actual input variant/conversion and original-key linkage. Verify complete intended BMI ≥30 encounter coverage, legacy derivations/dictionaries, source chronology, testing/missingness distinctions, exact arterial/venous mappings, units/valid maxima and ICD capture. Accepted historical compatibility membership alone is not a full-population proof.

Current engineering acceptance supersedes the stale failed-build handoff. The local RDS remains unqualified; private accepted products/receipts have not been bound here. Additional source work is requested only for a demonstrated unsupported requirement. Calendar-day evidence may remain pending, with no estimates or assessed model/reference counts for its positions.

See [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [input handoff](TRIANGULATION_INPUT_HANDOFF.md). Source qualification does not establish MAR, measurement-protocol equivalence or causal interpretation.

## Figures and verification

A is the preferred paired absolute/PIF forest/table; B compares evidence criteria in outcome-first panels. A/B show identical four encounter-wide BMI ≥30 observed/MAR benchmarks. C shows the prespecified assumption grids with MAR outlined, signed values and common shading within each statistic. Supporting tables contain BMI ≥40, timing, ICD and detailed missingness/support results. All derive from one ledger; C is an assumption display, not a confidence-interval plot.

Apply figure-and-medical-illustration-qc: 190-mm width, ≥9-point data/caption text, grayscale-safe marks, zero and every finite interval endpoint, native-size inspection, SVG/PDF masters and 300-dpi PNG/JPG. Preserve all alternatives and export/QC receipts.

Verify fixed indexes, BMI boundaries, reference/model denominators, no severe-subset refitting, specimen rules, within-pair matching, independent GLM/prediction parity, finite-difference gradients, MAR/MNAR identity, no-observation/no-change/negative/failure states, pending timing, unseen categories, input/bundle hashes, aggregate-only rendering and preserved version-1/2/historical sources. Inspect every changed report page and export. Generated materials remain ignored.

Completion means a tested workflow, reviewed artificial package and accurate qualification ledger. Clinical numerical population requires source acceptance and reconciled model diagnostics. Scientific/coauthor review and submission remain separate.

## Implementation status — 2026-10-14

Implemented locally: common-index selection, paired observed/MAR/MNAR standardization, fixed-model BMI ≥40 sensitivity, separately matched ICD comparisons, version-3 evidence/bundle contracts, aggregate-only rendering and runnable frozen version-1/2 workflows. The 24 shared artificial checks and 14 common-index check groups pass, as do historical R and nine Stata source/launcher checks. No packages were installed.

The artificial package `fixture-20261014T191709-47425` has a completed eight-page HTML/PDF review at `reviews/review-20261014T194108-48834/`. Candidate A is preferred after numerical read-back, native-size and grayscale review; all three alternatives are retained. A separate pending-calendar-day fixture verifies empty sensitivity positions without changing primary estimates. Exact receipts, source hashes and QC findings remain in ignored artifacts; see WORKLOG.md.

Clinical qualification remains **not evaluated**. The existing local input is unchanged, but no accepted-product/private-receipt binding qualifies its expanded BMI ≥30 coverage here. No clinical model was fitted. The next action is the field-specific existing-source reconciliation, not an assumed replacement export. This implementation is local and uncommitted.

## Qualification and release revision — 2026-10-15

The user approved code-first release followed by source qualification/clinical execution on the Mini. Bind new clinical inputs to `unadjusted_pco2_v1`: ordinary specimen-authenticated gases; strict 5–200 arterial and 10–250 venous mm Hg validity intervals; explicit units; captured-absence ICD negatives with complete available extraction and no other-diagnosis requirement. The BMI shift, indexes, models and MAR/MNAR specification are unchanged. See [confirmed decisions](DECISIONS.md).

Implement the study preparation command using pinned accepted readers and raw exact-code transport, with a fresh typed input, population/field evidence, aggregate preparation receipt and deliberately pending manifest. Keep the original input immutable. Require original-key and expanded-population reconciliation; fail on unmapped coverage or interrupted queries. Add the required policy identity to new version-3 clinical manifests and preserve saved bundle compatibility. Clinical estimation requires clean merged code and records commit/tree/source hashes; successful rendering does not confer scientific acceptance.

The Mini is inaccessible from the current network; the owner will resume at home. Private source qualification and clinical execution remain pending. Complete engineering release and handoff now; use [CLINICAL_RUN_HANDOFF.md](CLINICAL_RUN_HANDOFF.md) for the seven acceptance gates, exact run sequence, saved-run rerender and clinical closeout. The dated October 14 local/uncommitted status above is retained as history. Current release/verification status is recorded in WORKLOG.md.
