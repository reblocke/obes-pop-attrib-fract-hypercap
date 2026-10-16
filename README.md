# BMI and documented hypercapnia probability

An R/Quarto analysis of how documented index-encounter hypercapnia varies across
BMI in a selected TriNetX-derived acute-care cohort. The main displays combine
flexible probability curves, usable-evidence availability and BMI frequencies.
Named BMI-scenario potential impact fractions (PIFs) are secondary summaries.

Two reports share one immutable aggregate bundle:

- **Scientific report:** relationship curves, concise cohort flow, sampling support,
  exact original-BMI-band scenario contributions and focused sensitivities.
- **Complete audit:** source/eligibility/index accounting, every variable at each
  applicable stage, every planned model's coefficients/covariance, diagnostics,
  failures and numerical reconciliation.

The 2026-10-16 refactor breaks compatibility with earlier analysis bundles. Prior
inputs, outputs and Git history are preserved; old bundles are rejected explicitly.
This repository does not distribute restricted source data or clinical results.
Artificial examples do not establish source or scientific qualification.

## Start with artificial data

Run from the repository root. Use existing **R >=4.3**, Quarto and a working
XeLaTeX/TinyTeX installation for PDF. R dependencies are `ggplot2`, `jsonlite`,
`digest`, `lpSolve`, `knitr`, `rmarkdown`; `haven` is also required by the clinical
input loader. Base R `splines`, `stats`, `graphics` and `grid` supply modeling and
vector drawing. Nothing is installed automatically.

```bash
make fixture
```

The command prints a fresh `artifacts/triangulation/curve-fixture-...` run and a
review directory. A successful fixture produces both HTML/PDF reports, complete
CSV/RDS aggregates, F0–F5 exports, the three F1 alternatives and `figures/gallery.html`.
A failed render preserves estimation: rerender the printed run rather than refit.

```bash
make render RUN="artifacts/triangulation/<exact-version-4-run>"
make render-html RUN="artifacts/triangulation/<exact-version-4-run>"
make render-pdf RUN="artifacts/triangulation/<exact-version-4-run>"
```

Renders consume saved aggregates only and create fresh review directories.
Figure edits do not repeat estimation. Estimator/source/configuration changes
require a new run; hashes prevent silent reuse. HTML/PDF renders run sequentially.

After actual figure/page inspection, run the acceptance checks against that review:

```bash
make test BMI_TEST_REVIEW="artifacts/triangulation/<run>/reviews/<review>"
```

The 65-check runner preserves a result ledger under ignored artifacts. Checks
requiring rendered reports or visual inspection fail explicitly when their actual
receipts are absent. Source-adapter tests use Python; one optional SQL case needs
the existing upstream Python environment. `PREP_PYTHON` selects it. No patient data
are used by tests. See [acceptance requirements](docs/CURVE_AUDIT_ACCEPTANCE.csv).

## Scientific definitions

Candidates are restricted to authenticated **original selected encounter keys**;
raw-history visits cannot add candidates. Select the first 2022 adult EMER/IMP
encounter with valid BMI >=30 before gas availability and adjustment completeness.
Completed missing BMI is distinct from unresolved earlier evidence. BMI uses the
approved encounter/prior reported and observed height/weight hierarchy, without
statistical imputation; age retains the birth-year proxy.

Q contains resolved indexes; C is Q complete for inherited BMI, age, sex,
race/ethnicity and region. Models use a natural BMI spline with knots at C's
5th/35th/65th/95th percentiles, linear age and inherited categorical references.
Gas curves standardize to C. ICD curves use C_icd with established diagnosis
capture, including positive and negative patients. Denominators are printed.

Arterial hypercapnia is valid ordinary PCO2 >=45 mm Hg; combined evidence accepts
arterial >=45 or venous >=50. Missing/unusable gases remain unknown. The combined
negative concerns available specimens only. The ICD composite includes
J96.02/J96.12/J96.22/J96.92/E66.2; complete captured absence is negative, unknown
capture remains unknown. Start-calendar-day sensitivities retain the same indexes.

The default secondary scenario reduces **observed BMI >30 by exactly one**, with
no floor or reselection. PIF = 1 - shifted/observed-BMI modeled probability; it is
population-dependent. Signed original-band contributions use paired patient
predictions and reconcile exactly. Curves multiplied by marginal BMI densities
are not used to obtain adjusted PIF. The separate MAR/MNAR projections require
assumptions beyond source acceptance. These are documented index-encounter
probabilities, not incidence or demonstrated effects of weight loss.

## Restricted-data execution

Upstream products come from [trinetx-preprocessing](https://github.com/reblocke/trinetx-preprocessing).
Reuse accepted products, pinned readers and existing captured evidence. Preserve
`data/raw/full_db.rds` as a historical comparator. Do not substitute it for a
qualified current study input.

```bash
make prepare PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source-config.json" OUTPUT="/private/fresh-output"
make qualify PREP_PYTHON="/existing/environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source-config.json" \
  PREPARED="/private/fresh-output" OUTPUT="/private/fresh-qualification"
make preflight INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make cohort-audit INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make analyze INPUT="/private/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
```

The paths are placeholders, not discovered clinical inputs. Clinical estimation
requires the clean merged Mini checkout. Preselected inputs now require a new
hash-bound **pre-index cohort-audit companion**, which is generated from mapped
candidate covariates. The older selected-index input and its passing source checks
alone cannot supply the full new audit. Qualification failures retain a partial
audit and block inference; unknown totals are not zeros.

The original-list source and pre-index companion are accepted for this use.
On 2026-10-16, the owner authorized acceptance and clinical execution; fresh
preflight and one clinical estimation completed on the clean merged Mini checkout
at `f18d383` (PR #7). All 21 registered positions are retained: 20 fits succeeded,
and constant ICD capture availability is explicitly not fitted. Aggregate
numerical reconciliation passes. Both clinical HTML/PDF reports and all 153
figure exports pass recorded QC.
Investigator numerical/scientific review remains pending. Exact run paths,
hashes and protected receipts are recorded in ignored release storage and
WORKLOG. Read the
[current plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md),
[source assessment](docs/TRIANGULATION_SOURCE_ASSESSMENT.md),
[clinical handoff](docs/CLINICAL_RUN_HANDOFF.md) and
[decision log](docs/DECISIONS.md) before restricted execution.

## Code and outputs

- `R/analysis.R` loads the current source, cohort, model, prediction and reporting modules.
- `config/bmi_hypercapnia_analysis.json` and `config/variable_dictionary.csv` define analysis defaults and variables.
- `reports/bmi_hypercapnia.qmd` and `reports/bmi_hypercapnia_audit.qmd` render saved aggregates.
- `scripts/run_bmi_hypercapnia.R` estimates/audits; `scripts/render_bmi_hypercapnia.R` renders.
- `artifacts/triangulation/` is ignored private storage for bundles, receipts and figures.
- `WORKLOG.md` records actual commands, results and outstanding work.

Exact aggregate audits may expose rare categories and remain protected. Public
sharing or abstract submission requires separate review. Historical source files
are retained for provenance; the Makefile has one current scientific workflow.
