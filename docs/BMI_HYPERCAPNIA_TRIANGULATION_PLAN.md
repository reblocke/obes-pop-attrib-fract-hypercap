# Primary R/Quarto plan: BMI–hypercapnia evidence triangulation

Approved revision: **2026-10-13**. The primary scenario is now **one kg/m² less for every patient with observed BMI >30; BMI ≤30 unchanged**, without a floor at 30. This supersedes the October 13 BMI-to-40 primary scenario. It differs from the earlier unrestricted BMI-minus-one proposal because eligibility is explicitly based on observed BMI >30. Original documents and executable BMI-to-40 sources remain under `archive/2026-10-13-bmi-to-40/`, with hashes and source-commit provenance.

## Scientific specification

The shared scenario is applied to intentionally different populations/outcomes, rather than treating their differences as defects. Scope is adults aged ≥18 with emergency/inpatient encounters starting in calendar-year 2022 within the authenticated captured source.

| Sampling frame | Membership |
| --- | --- |
| Severe obesity | Observed legacy derived BMI ≥40 kg/m² |
| ABG obtained | Confirmed arterial testing, at any BMI |
| Either gas obtained | Confirmed arterial or venous testing, at any BMI |

Each original patient contributes the first qualifying encounter independently within each frame. Choose indexes before outcome/covariate completeness. Keep ambiguous earliest indexes and uncertain earlier membership visible; never advance to a later, more complete encounter. Exact primary-field duplicates collapse; conflicting primary versions cannot provide resolved indexes. Early evidence does not alter primary deduplication or selection.

| Outcome | Definition | Window / role |
| --- | --- | --- |
| ICD | J96.02, J96.12, J96.22, J96.92 or E66.2 | Encounter / primary |
| ABG | PaCO₂ ≥45 mm Hg | Encounter / primary |
| Either gas | PaCO₂ ≥45 or venous PCO₂ ≥50 mm Hg | Encounter / primary |
| ABG | The same arterial threshold | Index calendar day / sensitivity |
| Either gas | The same combined threshold | Index calendar day / sensitivity |

`triangulation_registry()` specifies these five cells within each frame: **nine primary plus six sensitivity cells**. Identity is frame × outcome × ascertainment window. There is no ICD timing duplicate. All boundaries above are inclusive; the shift eligibility boundary is strictly BMI >30. Neither pH nor ventilatory support is required. E66.2 remains included and described as obesity-containing ascertainment.

For gas outcomes, either valid positive result establishes combined positivity; at least one valid result with every available result below threshold establishes an available-gas negative; no usable result means unknown. An unmeasured specimen is not a negative result. Draw evidence is distinct from usable-result availability.

Index calendar day means collection date equals the source encounter-start date under its authenticated date convention. It does not mean elapsed 24 hours. Retain the primary frame/index and use separately authenticated specimen-specific day maxima and availability fields. Later-only results leave the early outcome unknown. Discordant day summaries remain unknown and are counted separately.

## Models and standardization

Use the unchanged legacy-derived `bmi` and Stata adjustment set:

```r
outcome ~ bmi + age_at_encounter +
  factor(sex) + factor(race_ethnicity) + factor(location)
```

BMI and age are linear in log odds; `location` denotes reviewed regional coding. Fit complete cases for that selected outcome and adjustment variables after index selection. Do not add mediators, nonlinear terms, imputation or alternative estimators. Check rank, outcome/exposure variation, convergence, warnings, separation and finite quantities. Failed models retain their positions/reasons.

For the same model cases, predict twice:

```r
bmi_shifted <- ifelse(bmi > 30, bmi - 1, bmi)
```

Examples: 30 stays 30; 30.2 becomes 29.2; 40 becomes 39. Hold original membership, selected encounter and all adjustment values fixed. Do not impose a floor at 30. Report observed/shifted standardized probabilities, their absolute difference, `PIF = 1 - mean(p_shifted) / mean(p_observed)`, model N and the count/percentage shifted. Report the count outside the cell's fitted marginal BMI range; zero does not establish conditional support. In the BMI ≥40 frame, shifted values can fall below its observed lower boundary.

Use the full-coefficient delta method for the log ratio of mean probabilities and back-transform its pointwise 95% limits. Retain negative fractions/limits. Treat empirical covariates as fixed. With no observed BMI >30, report exact zero difference/PIF/interval. The per-BMI-unit adjusted odds ratio is supporting output, not an OR-to-PIF conversion.

Terminology: **model-standardized potential impact fraction under a one-unit BMI reduction among patients with observed BMI >30**. It depends on the population's exposure distribution, fraction shifted and outcome probability; it is not a constant fraction attributable to each BMI unit. It concerns documented index-encounter hypercapnia, without an incidence or follow-up estimand. Causal prevention, treatment benefit and exchangeability are not established. See [Barendregt and Veerman](https://pubmed.ncbi.nlm.nih.gov/19692711/).

## Existing-source assessment and input contract

Reuse current upstream acceptance evidence. The local preprocessing checkout/handoff is stale; upstream `main` at `787fba64319c0285244e2e17a9e303c739f31a14` records accepted original-key encounter products and source coverage. Compatibility-backed populations still require study-specific coverage checks. Normal gas presence does not alone establish complete frames. Exact-code raw transport can retain normal and unusable evidence without syndrome-positive catalog filtering.

The bounded assessment is in [TRIANGULATION_SOURCE_ASSESSMENT.md](TRIANGULATION_SOURCE_ASSESSMENT.md). No new export is the default next step. Authenticate the existing input/products and resolve downstream mapping first; request new upstream evidence only for a demonstrated unsupported field.

New estimation requires a version-2 reviewed manifest with:

- Exact input SHA-256, producer/variant/conversion identity and reviewer metadata.
- Original patient/encounter keys, reviewed Date origin/setting codes, derived BMI, age and adjustment coding.
- Confirmed testing evidence, encounter-wide arterial/venous valid maxima in mm Hg, and positive/negative/unknown ICD capture.
- Explicit accepted declarations for lineage, population scope, keys/chronology, BMI/adjustment, draws, gas units/windows and ICD capture.
- Existing identity-bound evidence files for lineage, population and field mapping, with paths and SHA-256. The caller's reviewed manifest is the trust authority; hashes authenticate those declared files, not their scientific truth.
- `index_day.status` as `qualified` or `pending`. Qualified timing maps four separate fields (`abg_pco2_index_day`, `vbg_pco2_index_day`, `abg_index_day_available`, `vbg_index_day_available`), reviewed 0/1/unknown availability codes, the explicit calendar-day semantics and a hashed timing-evidence reference. Availability=1 requires a valid maximum; early maxima cannot exceed encounter maxima. Pending timing supplies no mapped columns.

All required primary fields and source gates must qualify before clinical estimation. Primary models may run while the timing module is pending: its six rows remain `awaiting_source_evidence`, with unassessed outcome/model counts and estimates missing, never zero. Patient-level unknown outcomes within a qualified module are a different state.

## Execution and frozen outputs

Estimate once per run. Version-2 bundles retain the precise scenario, registry/hash, full-precision results, frame/scope audits, timing cross-tables, BMI summaries, fixed 5-kg/m² bin counts/events/mean predictions, source/input identities and environment. Never export identifiers, patient indexes, fitted model data or individual predictions. Saved bundles are immutable and hash-checked.

Every HTML/PDF/figure review consumes saved aggregates only. Version-1 nine-cell BMI-to-40 bundles use the frozen original reader, renderer and labels. They cannot authorize new estimation or enter the current fifteen-cell display.

```bash
make triangulation-test
make historical-test
make stata-test
make triangulation-fixture
make triangulation-preflight INPUT="/explicit/input.rds"
make triangulation-preflight INPUT="/explicit/input.rds" MANIFEST="/reviewed/v2.json"
make triangulation-render INPUT="/accepted/input.rds" MANIFEST="/reviewed/v2.json"
make render RUN="artifacts/triangulation/<saved-run>"
make render-html RUN="artifacts/triangulation/<saved-run>"
make render-pdf RUN="artifacts/triangulation/<saved-run>"
```

`make render*` now addresses the primary workflow and requires an explicit saved run. `make triangulation-review RUN=...` remains supported. The launcher also accepts `review RUN [all|html|pdf]`. No target installs dependencies or selects a fallback clinical dataset.

## Report, exhibits and figure QC

Use three alternatives from one display ledger:

- A: preferred shared-axis forest/table; three frame blocks, five rows each.
- B: outcome-first panels comparing populations and paired gas windows.
- C: frame-by-outcome matrix with paired timing rows in gas cells and one ICD row.

Title: **Modeled hypercapnia under a one-unit BMI reduction above 30**. Show PIF, CI, model N and shifted percentage. Preserve common linear scales containing zero and every finite limit, negative quantities, informative empty positions, and precision distinguishing small nonzero estimates. Detailed unknowns, unresolved indexes and support counts remain in denominator tables. Include timing-transition and BMI/model-shape diagnostics without extra fitted comparisons.

Apply `figure-and-medical-illustration-qc`: native 190-mm width, sufficient height (currently 275 mm), at least 9.5-point data labels, grayscale-safe primary/sensitivity markers, captions/alt text and actual export inspection. Keep editable R source, SVG/PDF masters, 300-dpi PNG/JPG and individual/gallery reviews. Scientific selection and submission remain separate from figure QC.

## Primary authority and runnable archives

The primary report is `reports/bmi_hypercapnia_triangulation.qmd`. Older R originals are preserved byte-for-byte in the dated archive; the repaired historical R replay and unchanged reconstructed report are in `archive/r/`. Focused repairs concern ventilation uncertainty, explicit ICD decoding/composite missingness, missing-gas propagation and branch attrition. Historical outcomes, adjustment and BMI scenarios remain separate. `make legacy-r INPUT=...` (and HTML/PDF variants) renders the repaired historical report into ignored output. `make render-archival` retains the earlier reconstruction's reproduction role and original limitations.

The immutable Stata source remains `archive/stata/36_subpop_hazard.source.do`; its existing runnable repaired copy remains `stata/do/36_subpop_hazard.do`, with the preserved source/body contract and explicit `make stata*` commands. It is a historical track, not the primary analysis.

## Verification and completion

Test exact BMI-30 boundaries/crossing, independent shifted predictions/full-covariance gradients, null/negative/no-change results, unchanged primary models/indexes, fixed timing indexes, day conflicts, fifteen identities, pending evidence, model/denominator reconciliation, receipt/hash failures, version-1 compatibility and aggregate-only rerendering. Reproduce historical defects and verify repaired truth tables/branch accounting and every original hash. Inspect every revised report page and candidate export, including grayscale and synthetic negative/wide/missing/large-count cases. Record actual checks and unresolved coverage in QC receipts.

Engineering completion is a tested primary workflow, reviewed artificial figures/reports, saved decisions/source assessment and runnable historical archives. Clinical completion requires authenticated study input and a reconciled run followed by scientific review. A successful artificial render is not a clinical result.

## Implementation verification — 2026-10-13

The primary workflow, fifteen-cell persistence, three reviewed alternatives and runnable archives are implemented. Twenty-three artificial check groups, historical regression/preservation checks and nine Stata source tests passed. Both primary and source-pending artificial reports render successfully; old version-1 bundles retain original labels. The final artificial figure/report review, source-readiness receipt and specific evidence gaps are recorded in WORKLOG.md. Clinical results remain unpopulated until the existing accepted input/receipts are bound and reconciled.
