# BMI–hypercapnia common-index implementation plan

Approved revision: **2026-10-14**, with the **2026-10-15 valid-BMI clarification** and **2026-10-16 original encounter-list correction** below. The primary study uses a common first BMI ≥30 index and separate arterial and combined-gas projections. This replaces the version-2 frame-specific grid as primary. The one-unit BMI >30 shift remains unchanged. No BMI-to-30/40 cap is adopted.

## Scientific decisions

- Adults ≥18; 2022 ED/inpatient; candidate keys must belong to the authenticated original FULL_DATA selected encounter list. Broader raw history and follow-up/return keys cannot expand membership. First qualifying encounter with valid BMI ≥30 from that encounter or earlier, selected before gas availability or adjustment-variable completeness. After completed mapping, genuine BMI absence is nonqualification for this observed-BMI cohort, not uncertain obesity. Unresolved source evidence/chronology that could change the first qualifying index remains unresolved; do not substitute a later index for that uncertainty.
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

## Home-network continuation — 2026-10-15

PR #5 released the common-index workflow before clinical qualification. The Mini is now reachable and has a clean copy of that release; accepted receipts and original-key FULL_DATA reading were authenticated. The actual dictionary requires explicit Stata-date/coded-field decoding and the inherited race/ethnicity derivation. The adapter supports that encoding and the prior typed format; BMI and age remain unchanged. A private retained-reference comparison verifies the combined categories. No clinical estimates are populated from those checks.

Direct raw consensus/accumulation exhausted bounded execution resources. Stream all raw rows in disjoint patient-hash partitions, retaining conflicts/unknowns; apply the same study scope only after consensus and check coverage in SQL before Python materialization. Do not accumulate unrelated historical candidates. The bounded SQL path has artificial parity against the upstream projection, with external scratch and the existing RAM cap.

A completed bounded check demonstrates missing approved legacy mappings for potential adult 2022 EMER/IMP keys (adult birth-year proxy). It does not determine exact age/BMI eligibility or the full gap size. Clinical execution stops at this primary gate; see [the specific mapping handoff](COMMON_INDEX_SOURCE_GAP_HANDOFF.md). Reuse existing captured records for a separately named expanded mapping, preserve historical accepted products and do not silently narrow the study. Current full-source hashing and remaining gas/ICD/window checks stay unaccepted. Authorized isolated R dependency setup is complete on the Mini, with the shared and common-index artificial checks passing. After the source evidence is supplied, follow the unchanged preflight/one-run/aggregate-review sequence in the clinical handoff. No clinical results or scientific approval are claimed.

## Valid-BMI mapping revision — 2026-10-15

The owner clarified that missing BMI is an accepted data limitation after available encounter/prior records and height–weight calculation have been considered. **No statistical BMI imputation is authorized or required.** Use [the BMI decision](DECISIONS.md#bmi-availability-and-missingness--clarified-2026-10-15) when implementing the broader mapping; the earlier requirement to preserve unresolved evidence does not mean every absent BMI invalidates a later observed-BMI index.

1. **Establish the source meaning.** Reuse captured BMI/height/weight records and their units, dates, text and masking metadata. The original Stata comment attributes its 50.1 recorded-BMI exclusion to TriNetX truncation; the Python legacy port matches. Do not raise that cutoff unless source evidence distinguishes genuine high measurements from censored values. If such measurements exist, implement the owner's proposed ceiling of about 120 in the separately named mapping and audit any differences. Do not alter accepted legacy products or infer exact values from a mask.
2. **Map available evidence on the Mini.** Extend the preprocessing interface using existing readers and original keys, covering potential adult acute-care encounters before BMI/gas/model filtering. Select valid current BMI, then valid prior BMI, then calculate from usable observed current/prior height and weight. Preserve the approved units/rounding and adjustment derivations; retain component dates and derivation method. Evaluate prior evidence relative to each candidate encounter, not one patient's unrelated historical qualifying date. Preserve later or ambiguously timed records for audit, without allowing later-encounter measurements to establish earlier BMI.
3. **Separate absence from incomplete processing.** Record whether evidence retrieval/mapping completed, BMI provenance (current, prior, calculated) and why BMI is unavailable. Reconcile every candidate key, but do not require every candidate to have a BMI value. Completed mapping with no usable BMI is a counted exclusion; unmapped keys, interrupted queries and unresolved relevant chronology remain distinct. Report missingness rather than request new measurements or an export merely to eliminate it.
4. **Update downstream selection and identity.** Consume the new mapping and explicitly qualify the revised BMI/selection policy in input manifests and saved bundles. The current `run_common_index()`/`select_frame_indexes()` path treats earlier `NA` BMI as uncertain membership and requires a focused change: known missing BMI does not block a later first valid-BMI encounter, while unresolved source evidence still can. Do not treat every `NA` as known absence or silently relabel old version-3 bundles. Keep gas outcomes, the one-unit shift, adjustment, model fitting and MAR/MNAR assumptions unchanged.
5. **Verify before clinical execution.** Use artificial end-to-end cases for current/prior/calculated BMI, absent BMI, censored versus genuine high values, units/rounding, future records, repeated encounters and chronology conflicts. Include an earlier mapped BMI-missing encounter followed by valid BMI ≥30, and an otherwise identical case with incomplete earlier mapping. Test proposed high-BMI boundaries if that conditional change is activated. Compare historical overlap against accepted derived values and explain intended differences. Reconcile source candidates, BMI availability/provenance, first indexes and covariate completeness; missing BMI counts are not model failures. Then complete the existing gas/ICD qualification and clean-release/single-run sequence.

This revision records the agreed behavior and implementation work still needed. No source data, preprocessing/analysis code, archived output or clinical result was changed while investigating this clarification.

## Broader mapping execution — 2026-10-16

The valid-BMI mapping and downstream state distinction are implemented. Upstream
`72c91a21d4ff65aadca970cf60a168971a8c4a6e` supplies a separately named, hash-bound
calendar covariate product without changing source schema or historical products.
Complete candidate coverage, original-key checks, independent first-index/census
reconciliation and BMI arithmetic checks pass on the expanded source. Historical
overlap exposed and resolved float32-before-rounding behavior in the draft mapper.
Per-encounter prior measurement and start-year age differences are documented;
the conditional high recorded-BMI ceiling was not activated.

Bounded preparation selects whole-patient partitions with the same R helper
before gas extraction, and binds the original cohort census to resolved-index
input. The new manifest and saved specification bind
`available_encounter_or_prior_bmi_v1`; older inputs/bundles keep their original
definitions. Fresh typed gas/testing/ICD/calendar-day qualification and preflight
pass under the current rules; the source freeze is ready with limitations.
Earlier unknown setting and same-day index ties remain visible under the current
conservative rule; adopting a first-documented-acute target requires an explicit
decision. No clinical model has run. Current outcomes and private evidence are
recorded in the [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and WORKLOG.
Actual old prior measurements also motivate a proposed one-year recency
sensitivity; its exact treatment of BMI/components and reference/training cases
must be decided before fitting. Primary availability remains unchanged. Code
release, human scientific review, clinical estimation and results review remain
separate from the completed automated source qualification.

## Original encounter-list correction — 2026-10-16

1. Check Mini activity, reserve this study's writer scope, and snapshot public-file
   hashes. Keep the concurrent GLP-1 job, shared upstream checkout and database
   untouched. Reject unexpected changes during code synchronization.
2. Authenticate original FULL_DATA through the pinned accepted reader. Verify
   original keys, setting codes and first-encounter flags against frozen ordering.
   Retain the complete original list as private provenance; map only original
   ED/inpatient keys. Original first flags are an audit, not a pre-BMI filter.
3. In `scripts/original_encounter_population.py` and
   `scripts/map_common_index_covariates.py`, enforce exact key equality and
   authenticated setting support. Broader history can supply prior BMI/components
   only. Reuse the approved upstream BMI mapper without editing shared upstream
   code or changing accepted products. Bind `original_selected_encounters_v1`.
4. Prepare a fresh typed input via `scripts/prepare_common_index_input.py`, selecting
   first valid-BMI ≥30 indexes within this original universe before gas extraction.
   Preserve completed-missing versus unresolved BMI and same-day tie handling.
5. Independently check original membership/first flags/raw chronology, index census,
   BMI arithmetic, typed fields, gases, testing and ICD/calendar-day evidence in
   `scripts/qualify_common_index_source.py`. Supersede, never overwrite, the broader
   mapping/preparation/qualification receipts. Run identity-bound preflight only
   after the new required evidence passes; no clinical estimation in this phase.
6. Update the decision log, source assessment, README and worklog with actual
   completion and residual issues. Existing saved aggregates retain their labels.

Verification commands: `make preparation-test PREP_PYTHON=...`,
`make source-qualification-test PREP_PYTHON=...`, `make common-index-test`,
`make triangulation-map ...`, `make triangulation-prepare ...`,
`make triangulation-qualify ...`, and `make triangulation-preflight INPUT=... MANIFEST=...`.
Success requires no outside-list candidates/indexes, independently reproduced
original first flags and new-study index census, passing source comparisons and
unchanged historical source hashes. Do not interpret the previously reported
unknown-setting attrition as a defect in this original selected cohort.

**Completion — 2026-10-16:** the corrected original-list mapping, fresh typed
preparation, all 30 independent source checks, exact nineteen-field CSV/RDS
comparison and identity-bound preflight pass on the Mini. Original first flags
reproduce; every historical/new index difference is explained. Shared-key BMI,
covariates, dates and evidence states are unchanged. Readiness is
`ready_with_limitations` for the approved source use, with within-list uncertainty
retained. Artificial regression and historical-source checks pass. The separate
GLP-1 job and shared upstream code/source were not changed. Clinical estimation,
human scientific review and code release remain subsequent work.
