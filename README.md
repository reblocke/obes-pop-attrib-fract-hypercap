# BMI and documented hypercapnia

**Current revision: historical source-entry populations.** The primary analysis
includes fixed first BMI-eligible indexes represented through at least one
non-OBESITY source pathway, retaining OBESITY overlaps. Obesity-only source entry
is the principal selection sensitivity. Historical flags record extraction
membership; zero does not establish clinical absence. The combined cohort is an
audit reference. The version-6 clinical analysis completed on the Mini from
merged revision `4fdf4eb`; all 162 aggregate numerical checks passed. Both reports
and scoped export/layout review are complete. Investigator numerical/scientific
approval remains pending, separate from the earlier version-5 clinical run.

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
make render RUN="artifacts/triangulation/<exact-version-6-run>"
make render-html RUN="artifacts/triangulation/<exact-version-6-run>"
make render-pdf RUN="artifacts/triangulation/<exact-version-6-run>"
```

For prose/table-only revisions, reuse completed figures after the bundle and
figure-source hashes match; this still creates a fresh review:

```bash
make render-reports RUN="artifacts/triangulation/<run>" \
  FIGURES_FROM="artifacts/triangulation/<same-run>/reviews/<completed-figure-review>"
```

Renders consume saved aggregates only and create fresh review directories.
Figure edits do not repeat estimation. Estimator/source/configuration changes
require a new run; hashes prevent silent reuse. HTML/PDF renders run sequentially.

Review the saved numerical identities and prepare export checks with:

```bash
Rscript scripts/review_bmi_run.R "artifacts/triangulation/<exact-version-6-run>"
python3 scripts/check_report_exports.py "artifacts/triangulation/<run>/reviews/<review>"
```

The numerical command accepts one saved run. Prior-run index and field equality
are source-qualification checks; coefficients from separately fitted RFS
populations and spline bases are not expected to remain identical.
The export command uses an existing Python with Pillow and Poppler's `pdftotext`
and `pdftoppm`. It checks page bounds, symbols and formats, then prepares page
overviews and figure sheets. It does not certify manual visual or scientific
review; record those checks separately in the review directory.

Run data-free numerical and adapter checks separately from rendering:

```bash
make test
make render-test REVIEW="artifacts/triangulation/<run>/reviews/<review>"
```

Every test run writes a fresh receipt. Rendering checks require actual completed
HTML/PDF reports; visual and scientific approval remain separate. Python adapter
checks require the existing upstream pandas/DuckDB environment, selected with
`PREP_PYTHON`; skips are reported explicitly. Historical acceptance receipts remain
unchanged. The RFS requirements are in the [current plan](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).

## Scientific definitions

Candidates are restricted to authenticated **original selected encounter keys**;
raw-history visits cannot add candidates. Select the first 2022 adult EMER/IMP
encounter with valid BMI >=30 before gas availability and adjustment completeness.
Completed missing BMI is distinct from unresolved earlier evidence. BMI uses the
approved encounter/prior reported and observed height/weight hierarchy, without
statistical imputation; age retains the birth-year proxy.

Q contains resolved indexes; C is Q complete for inherited BMI, age, sex,
race/ethnicity and region. Within each RFS group, models use a natural BMI spline with knots at that group's C
5th/35th/65th/95th percentiles, linear age and inherited categorical references.
Gas curves standardize to their outcome-observed model populations. ICD curves use C_icd with established diagnosis
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
are not used to obtain adjusted PIF. Full-cohort MAR/MNAR projections remain historical only; no IPW is applied. These are documented index-encounter
probabilities, not incidence or demonstrated effects of weight loss.

## Restricted-data execution

Upstream products come from [trinetx-preprocessing](https://github.com/reblocke/trinetx-preprocessing).
Reuse accepted products, pinned readers and existing captured evidence. Preserve
`data/raw/full_db.rds` as a historical comparator. Do not substitute it for a
qualified current study input.

The active mapper profile now binds merged upstream `751d794` and its exact
module hashes. Use its separately qualified installed environment with
`PREP_PYTHON`; see [pin adoption and historical reproduction](docs/CLINICAL_RUN_HANDOFF.md).
Existing accepted products retain their original producer/runtime identities.

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
requires the clean merged Mini checkout. Preselected inputs require a
hash-bound **pre-index cohort-audit companion**, which is generated from mapped
candidate covariates. The older selected-index input and its passing source checks
alone cannot supply the full new audit. Qualification failures retain a partial
audit and block inference; unknown totals are not zeros.

The original-list source was accepted for the earlier observed-population study.
Its version-5 run from `ca24564` and completed numerical/layout reviews remain
historical. The RFS revision adds authenticated metadata without changing those
clinical fields or indexes. Its metadata-enriched input passed source preflight,
and clinical estimation completed once from clean merged revision `4fdf4eb`.
Post-run input/evidence hashes match and all 162 aggregate numerical checks pass.
Sparse obesity-only fits retain their separation/rank-deficiency statuses; no
fallback estimator supplies an apparent comparison. Investigator numerical and
scientific approval remain separate from automated checks and layout review.
Both HTML/PDF reports and three main-figure alternatives are available in the
private review folder with a key-figure gallery. Every PDF page and figure received
automated export checks; manual inspection covers all scientific page overviews,
selected native scientific/audit pages and key figures. This is not a claim of
individual human inspection of the entire complete audit.
Exact private run paths and hashes remain in ignored release storage and WORKLOG.
Read the
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

## Add authenticated RFS and BMI provenance

Use the accepted original encounter product and existing covariate mapping to
enrich the qualified input. [RFS evidence](config/rfs_evidence.example.json) records each historical family's source,
zero semantics, extraction limitations and outcome overlap, with hashed producing
code/receipt references. This command does not rebuild upstream data or pull gases.

```bash
make enrich-rfs SOURCE_CONFIG="/private/reviewed-source.json" \
  INPUT="/private/prior-input.rds" MANIFEST="/private/prior-manifest.json" \
  PRIOR_RUN="/private/prior-aggregate-run" \
  RFS_EVIDENCE="/private/authenticated-rfs-evidence.json" OUTPUT="/private/fresh-rfs-input"
```

The fresh schema-4 input/manifest and pre-index companion must pass preflight;
clinical estimation still requires a clean merged Mini checkout. The enrichment
checks exact prior clinical-field and index identity. Unavailable historical
trigger evidence stays unresolved; current BMI never reconstructs the entry trigger.

The audit includes limited current-measurement and overlapping all-OBESITY
supporting analyses. Numeric demographic coding is preserved; inherited Unknown
categories remain nonmissing. The White reference includes unknown ethnicity.

The complete audit HTML links to its adjacent `figures/` SVG directory instead of
embedding thousands of panels. Move the whole review folder together. The scientific
HTML remains self-contained; PDF reports retain complete tables and vector figures.
