# BMI and documented hypercapnia

**Study question:** How does the probability of documented hypercapnia vary with
BMI among adults with obesity receiving emergency or inpatient care, when the
relevant outcome can be evaluated?

This research repository contains a descriptive analysis of body mass index
(BMI) and documented hypercapnia in a selected 2022 TriNetX-derived cohort. Its main
result is an adjusted BMI–hypercapnia probability curve. A secondary analysis
compares modeled probabilities before and after a one-unit BMI reduction among
patients whose observed BMI is above 30. It includes analysis code, scientific
reports, figures and complete aggregate audit/result tables for researchers
reviewing the methods or findings.

Start with **[the saved results](#read-the-results)** to review the study without
running code, or **[the synthetic workflow](#reproduce-the-software-workflow)** to
exercise the software without clinical data.

## Study and release status

The qualified primary clinical analysis completed on October 17, 2026; the joint
same-day component analysis completed on October 20. Numerical reconciliation and
scoped figure/report review are recorded separately from investigator review.
Primary scientific approval is **provisional**. **F1-B and F2** are the working
main figures; investigator interpretation and approval of supplemental S1 remain
**pending**. The same-day update preserves the primary estimates and PIFs.

On October 23, 2026, the owner confirmed that the existing reports, figures and
aggregate tables are cleared for public release under the source-data agreement,
including the existing small aggregate counts. Raw and patient-level data remain
excluded. Disclosure clearance does not confer scientific or submission approval.
See the [decision log](docs/DECISIONS.md) for dated decisions and publication
planning, and the [public-release review](docs/PUBLIC_RELEASE_REVIEW.md) for checks
and outstanding release tasks.

## Read the results

You do not need to run the code to review the study. The
**[collaborator snapshot](results/2026-10-18/README.md)** contains the clinical
reports, selected figures and complete aggregate tables in Git. A normal clone
includes these results; raw and patient-level data remain excluded.

The **[joint same-day component supplement](results/2026-10-20-same-day-components/README.md)**
contains the latest integrated scientific/audit reports and stacked figure S1.
It separates hypercapnia with and without documented same-day acidemia in one
joint model, across the full observed BMI range. This is **same recorded-day
co-occurrence; not verified same-sample pairing**. Primary estimates and selected
B/F2 remain unchanged; investigator interpretation and S1 approval are pending.
The [earlier binary supplement](results/2026-10-20-same-day-abg/README.md) is historical.

| Read in this order | What to look for |
|---|---|
| [Current scientific report](results/2026-10-20-same-day-components/bmi_hypercapnia.pdf) | Rationale, detailed methods, results, sensitivity analyses and interpretation limits |
| [B/F2 figure PDF — 2 pages](results/2026-10-18/selected_figures.pdf) | Selected relationship and secondary-scenario figures with full captions |
| [B: relationship](results/2026-10-18/figures/F1-B.pdf) / [F2: secondary scenario](results/2026-10-18/figures/F2.pdf) | Individual vector masters; SVG, PNG and JPG versions are beside them |
| [Supplemental S1](results/2026-10-20-same-day-components/supplement_figure.pdf) | Captioned joint same-day component figure; investigator interpretation and approval pending |
| [Offline gallery](results/2026-10-18/gallery.html) | B/F2 at full size, captions, format downloads and source-table links |
| [Current complete audit](results/2026-10-20-same-day-components/bmi_hypercapnia_audit.pdf) | Full cohort profiles, model samples, coefficients, covariance and diagnostics |
| [Current aggregate tables](results/2026-10-20-same-day-components/TABLES.md) | Complete CSV exports, with a machine-readable field/row/hash index |

Download PDFs with GitHub's **Download raw file** control when needed.
For the gallery, clone/download the folder and open `gallery.html` locally; GitHub
shows its HTML source. All gallery assets are local.

**Current working selection: F1-B and F2**, chosen by the owner on October 18,
2026. F1-A/C remain alternatives. The saved scientific PDF still embeds layout A;
use standalone **F1-B** for the selected presentation. A/B/C contain the same
estimates. The compact gallery covers B/F2; supporting figures remain in the full
audit. Keep the snapshot folder together for its local links to work.

Trace each numerical claim to the supplied clinical report or saved aggregate
table, retaining its population, outcome, timing window, denominator and interval
type. Artificial-example outputs and historical analysis versions are not current
clinical findings.

## What was analyzed

- **One index per patient:** the first qualifying adult 2022 emergency/inpatient
  encounter with available BMI ≥30 within the original selected encounter list.
  Selection occurs before checking gas availability or adjustment completeness.
- **Source-entry restriction:** the primary population entered through at least
  one historical non-OBESITY reason-for-suspicion pathway, including patients who
  also entered through the OBESITY pathway. Obesity-only entry is retained in the
  flow and audit, without adjusted models or a physiological comparison group.
- **Three outcomes:** arterial PCO₂ ≥45 mm Hg; arterial ≥45 or venous ≥50 mm Hg;
  and a documented five-code ICD composite including E66.2. Gas definitions use
  ordinary specimen-authenticated measurements during the index encounter.
- **Model:** logistic regression with a flexible three-degree-of-freedom natural
  BMI spline, adjusted for age, sex, inherited race/ethnicity category and region.
  Gas curves describe outcome-evaluable patients; ICD curves use known diagnosis
  capture. Outcome-specific samples overlap and must not be summed.
- **Secondary scenario:** subtract exactly one BMI unit when observed BMI >30;
  BMI=30 is unchanged, with no floor or patient reselection. The potential impact
  fraction (PIF) is the relative change in paired modeled probabilities, not a
  constant effect attributable to each BMI unit.

The [scientific guide](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) contains the exact
definitions, adjustment, timing sensitivities and uncertainty calculations.

## How to interpret the results

The curves describe documented hypercapnia in selected, evaluable populations.
They do not establish incident disease, the causal effect of weight loss, or
hypercapnia probability among untested patients. Historical entry pathways and
selective gas measurement can affect the association itself. No MAR/MNAR
projection or inverse-probability weighting is part of this analysis.

Available BMI may be current, prior, or calculated from observed height/weight;
there is no statistical BMI imputation. Known diagnosis capture is not ICD
positivity. Missing/unusable evidence is not a negative outcome. Confidence
intervals are model-based; they do not cover selection bias, measurement error or
unmeasured confounding. The [source contract](docs/SOURCE_CONTRACT.md) and
[decision log](docs/DECISIONS.md) retain the remaining evidence limitations.

## Where to find methods, evidence and code

| Resource | Purpose |
|---|---|
| [Scientific guide](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) | Exact study design, estimands, outputs and execution interfaces |
| [Source contract](docs/SOURCE_CONTRACT.md) | Provenance, preparation, qualification and restricted execution |
| [Configuration](config/bmi_hypercapnia_analysis.json) / [variable dictionary](config/variable_dictionary.csv) | Executable settings and field definitions |
| [Figure QC record](docs/PUBLICATION_FIGURE_QC_PLAN.md) | Existing inspection scope and current figure choice |
| [LLM reading guide](docs/LLM_GUIDE.json) / [agent instructions](AGENTS.md) | Structured evidence navigation and operating rules for assistants |
| [Work log](WORKLOG.md) / [archive index](archive/README.md) | Execution evidence and recovery of superseded versions |

The current implementation is `bmi_hypercapnia_rfs_curve_audit_v6` (aggregate
schema 11). The published joint same-day clinical snapshot remains schema 10;
the ICD-acuity clinical supplement is pending its fresh run and reconciliation.
`R/analysis.R` loads the current modules; `scripts/run_bmi_hypercapnia.R` audits
and estimates; `scripts/render_bmi_hypercapnia.R` renders saved aggregates. The
[scientific](reports/bmi_hypercapnia.qmd) and [audit](reports/bmi_hypercapnia_audit.qmd)
Quarto documents are the report sources. The JSON reading guide is documentation,
not another analysis configuration.

The repository is laid out as follows:

```text
results/2026-10-20-same-day-components/  Current integrated reports, joint S1 and tables
results/2026-10-18/                    Primary snapshot: B/F2, reports and tables
results/2026-10-20-same-day-abg/        Historical binary co-occurrence supplement
results/2026-10-20-paired-abg/          Historical pairing-feasibility report; no new models
docs/                Scientific/source guides, decisions, figure QC and LLM navigation
config/              Executable study settings, variable dictionary and source examples
R/                   Cohort audit, models, standardization and reporting modules
scripts/             Source mapping/qualification, estimation, rendering and review commands
reports/             Editable Quarto scientific/audit reports and shared formatting
tests/               Artificial end-to-end workflow and justified source-boundary checks
archive/             Recovery index and retained historical source
Code/, Documents/    Historical Stata code and older study documents; not current results
data/, artifacts/    Local raw inputs and working runs; their contents stay out of Git
```

For LLM-assisted review, begin with [LLM_GUIDE.json](docs/LLM_GUIDE.json), then use
the [current table index](results/2026-10-20-same-day-components/table_index.csv)
or [original primary index](results/2026-10-18/table_index.csv) and the relevant
CSVs. Each snapshot's manifest identifies its clinical run and file hashes. Use
current guides for methods and the appropriate dated snapshot for reported numbers.

## Reproduce the software workflow

The recorded workflow uses macOS. Run from the repository root with Make,
existing **R ≥4.3**, Quarto,
XeLaTeX/TinyTeX and Poppler (`pdftotext`, `pdfinfo`). Required R packages are
`ggplot2`, `jsonlite`, `digest`, `lpSolve`, `nnet`, `knitr` and `rmarkdown`; clinical input
reading also uses `haven`. Nothing is installed automatically. The full audit
exports many figures and tables, so this is a complete integration run, not a
quick preview. No portable runtime estimate is established.

```bash
make test
```

This creates artificial input, estimates once, renders both HTML/PDF reports, and
checks numerical results and output completeness. Success prints the path to a
fresh `artifacts/triangulation/e2e-.../receipt.json` with `status: passed`, alongside
`checks.csv`, logs and `artifact-hashes.csv`. This verifies software behavior; it
does not reproduce clinical estimates or confer scientific approval. `make fixture`
runs the artificial example without the E2E assertions.

For presentation changes, use an explicitly selected saved run that matches the
checked-out analysis version. The current ICD-supplement development requires
schema 11; the published clinical reading packet remains schema 10:

```bash
make render RUN="artifacts/triangulation/<exact-saved-run>"
# Use render-html or render-pdf for one format of both reports.
```

Replace the placeholder with the actual run directory. A successful render creates
`reviews/<timestamp>-<pid>/` with scientific/audit reports, figures, captions and a
completed `render-receipt.json`. Rendering reads aggregates only and does not refit
models. Changed estimation sources require a new run; incompatible bundles fail
instead of acquiring new labels.

The versioned clinical `results/` folders are reading snapshots, not complete
saved execution bundles. Their CSVs/PDFs can be inspected without data access;
the binary analysis bundles and private receipts needed by `make render` are
omitted. Each snapshot README provides a dependency-free Python hash-verification
command. The historical pairing-feasibility README documents its separate
aggregate-report command; it is not the current analysis renderer.

Source-boundary checks are separate:

```bash
make source-test PREP_PYTHON="/existing/environment/bin/python"
```

Use the existing source-reader Python environment with pandas and DuckDB; source
preparation also requires the pinned upstream readers. The same-day release passed
the artificial E2E and all 33 source checks using the existing Mini environment,
without skips or dependency installation. See [test scope](tests/README.md) and
[dated receipts](WORKLOG.md). Artificial checks do not establish clinical results.
The [public-release review](docs/PUBLIC_RELEASE_REVIEW.md) records verification
of the documented release, installed versions and any unavailable dependencies.

## Data access and full clinical reproduction

Reports, figures and aggregate analysis tables are included in the repository;
the owner confirmed public disclosure clearance for the existing outputs on
October 23, 2026. Each reading snapshot includes its own provenance and integrity
manifest. Temporary runs and private source-access receipts remain outside the
reading packets. Public disclosure clearance and reuse licensing are separate;
see [citation, reuse and support](#citation-reuse-and-support).

Raw records, patient-level inputs/derivations, identifiers, exact individual dates,
model frames and individual predictions stay in ignored/private storage. Do not
copy credentials or local source-access details into the review outputs. Source
access remains separate: obtain it from the project owner; no self-service
data-access process is documented. Repository access does not grant raw-data access.

Full clinical estimation requires the qualified input/manifest and pre-index audit
companion on a clean, merged Mini checkout. Follow the [source contract](docs/SOURCE_CONTRACT.md).
`data/raw/full_db.rds` is a historical comparator, never a fallback input. Preserve
prior products and reports; source corrections and new models require fresh,
traceable runs. Submission and external sharing are separate actions.

## Same-day arterial PCO₂/pH supplement

The [supplement specification](docs/SAME_DAY_ABG_SUPPLEMENT.md) now uses one
joint multinomial spline to distinguish hypercapnia with and without documented
same-day acidemia, with no documented hypercapnia as the reference. Any eligible
hypercapnia–acidemia day takes priority. S1 stacks the two components across the
full observed BMI range and shows their separate intervals on a common baseline.
The input and primary models/PIFs are unchanged. The joint-component release uses aggregate
schema 10; the schema-9 snapshot is preserved as historical evidence.

See the [current reading packet](results/2026-10-20-same-day-components/README.md)
for the shared model/reference denominator, category counts, full-range
probabilities, five-unit component contrasts, numerical reconciliation and
separate review states. S1 interpretation and investigator figure approval
remain pending.

The [historical pairing-feasibility report](results/2026-10-20-paired-abg/README.md)
remains available. Its raw-export trace confirmed that sample identifiers were
not supplied in the original laboratory export. The new definition requires a
common recorded date, not a specimen identifier. See the source contract for
private enrichment and qualification; ordinary report rendering reads saved
aggregates only.

## Citation, reuse and support

A project license and preferred citation are not yet documented in this repository.
Authorship and code/output reuse terms await owner confirmation before release;
no DOI or published-paper citation is asserted. For a traceable reference,
identify the [repository](https://github.com/reblocke/obes-pop-attrib-fract-hypercap),
the exact commit and the dated result snapshot used. Third-party assets retain
their own notices. See the [release review](docs/PUBLIC_RELEASE_REVIEW.md).

Use [repository issues](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/issues)
for code or documentation questions, including the command, software versions and
sanitized error. Keep restricted records, credentials and private access paths
out of issues. Clinical-data access requires a separate arrangement with the
project owner; no public self-service access process is documented.

## ICD acuity supplement (implementation; clinical results pending)

The [ICD supplement plan](docs/ICD_ACUITY_SUPPLEMENT.md) adds a stacked S2 figure
for chronic/OHS, acute-on-chronic or concurrent coding, acute, and unspecified
acuity. It preserves existing clinical results and S1. A fresh code-level
enrichment is required; the historical reading snapshots do not contain these
new results. See the [source command](docs/SOURCE_CONTRACT.md#icd-acuity-enrichment).
