# BMI and documented hypercapnia

**Study question:** How does the probability of documented hypercapnia vary with
BMI among adults with obesity receiving emergency or inpatient care, when the
relevant outcome can be evaluated?

This is a descriptive analysis of a selected 2022 TriNetX-derived cohort. Its main
result is an adjusted BMI–hypercapnia probability curve. A secondary analysis
compares modeled probabilities before and after a one-unit BMI reduction among
patients whose observed BMI is above 30. The repository produces an expanded
scientific report and a complete audit of cohort construction and modeling.

## If you are helping write the abstract

You do not need to run the code to review the study. The
**[collaborator snapshot](results/2026-10-18/README.md)** contains the clinical
reports, selected figures and complete aggregate tables in Git. A normal clone
includes these results; raw and patient-level data remain excluded.

| Read in this order | What to look for |
|---|---|
| [Scientific report — 34 pages](results/2026-10-18/bmi_hypercapnia.pdf) | Rationale, detailed methods, results, sensitivity analyses and interpretation limits |
| [B/F2 figure PDF — 2 pages](results/2026-10-18/selected_figures.pdf) | Selected relationship and secondary-scenario figures with full captions; convenient for email |
| [B: relationship](results/2026-10-18/figures/F1-B.pdf) / [F2: secondary scenario](results/2026-10-18/figures/F2.pdf) | Individual vector masters; SVG, PNG and JPG versions are beside them |
| [Offline gallery](results/2026-10-18/gallery.html) | B/F2 at full size, captions, format downloads and source-table links |
| [Complete audit — 2,970 pages](results/2026-10-18/bmi_hypercapnia_audit.pdf) | Full cohort profiles, model samples, coefficients, covariance and diagnostics |
| [Aggregate tables](results/2026-10-18/TABLES.md) | All 49 complete CSV exports, with a machine-readable field/row/hash index |

For email, start with the scientific and B/F2 PDFs; the audit is a separate 30.4-MB
reference. Download PDFs with GitHub's **Download raw file** control when needed.
For the gallery, clone/download the folder and open `gallery.html` locally; GitHub
shows its HTML source. All gallery assets are local.

**Current working selection: F1-B and F2**, chosen by the owner on October 18,
2026. F1-A/C remain alternatives. The saved scientific PDF still embeds layout A;
use standalone **F1-B** for the selected presentation. A/B/C contain the same
estimates. The compact gallery covers B/F2; supporting figures remain in the full
audit. Keep the snapshot folder together for its local links to work.

**Current status:** the qualified clinical analysis completed on October 17, 2026;
numerical verification and scoped figure/report QC are recorded. The owner granted
provisional scientific approval and selected B/F2 for the working main figure set.
The ATS 2027 deadline is **November 4, 2026**, reconfirmed by the owner. Final
submission packaging and submission approval remain separate. **Abstract drafting
is currently deferred at the owner's request.** See the [decision log](docs/DECISIONS.md).

When preparing a later draft, trace each number to the supplied clinical report or
saved aggregate table, retaining its population, outcome, timing window and
denominator. Resolve wording, authorship/affiliations and final exhibit packaging
with the project owner. Do not use artificial-example outputs or historical
analysis versions as current findings.

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

The active analysis is `bmi_hypercapnia_rfs_curve_audit_v4` (aggregate schema 9).
`R/analysis.R` loads the current modules; `scripts/run_bmi_hypercapnia.R` audits
and estimates; `scripts/render_bmi_hypercapnia.R` renders saved aggregates. The
[scientific](reports/bmi_hypercapnia.qmd) and [audit](reports/bmi_hypercapnia_audit.qmd)
Quarto documents are the report sources. The JSON reading guide is documentation,
not another analysis configuration.

The repository is laid out as follows:

```text
results/2026-10-20-paired-abg/  Source-feasibility supplement; no new clinical models
results/2026-10-18/  Clinical reading snapshot: PDFs, B/F2, gallery, 49 CSVs and hashes
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

For LLM-assisted review, begin with [LLM_GUIDE.json](docs/LLM_GUIDE.json) and the
[table index](results/2026-10-18/table_index.csv), then read the relevant CSVs.
The [snapshot manifest](results/2026-10-18/manifest.json) identifies the clinical
run and file hashes. Use current guides for methods and the dated snapshot for
reported numbers; historical files are background only.

## Reproduce the software workflow

Run from the repository root with existing **R ≥4.3**, Quarto,
XeLaTeX/TinyTeX and Poppler (`pdftotext`, `pdfinfo`). Required R packages are
`ggplot2`, `jsonlite`, `digest`, `lpSolve`, `knitr` and `rmarkdown`; clinical input
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

For presentation changes, use an explicitly selected saved schema-8 run:

```bash
make render RUN="artifacts/triangulation/<exact-saved-run>"
# Use render-html or render-pdf for one format of both reports.
```

Replace the placeholder with the actual run directory. A successful render creates
`reviews/<timestamp>-<pid>/` with scientific/audit reports, figures, captions and a
completed `render-receipt.json`. Rendering reads aggregates only and does not refit
models. Changed estimation sources require a new run; incompatible bundles fail
instead of acquiring new labels.

The versioned `results/2026-10-18/` folder is a reading snapshot, not a complete
saved execution bundle. Its CSVs/PDFs can be inspected without data access, but it
cannot be passed to `make render`: the binary bundle and private receipts are not
included. The snapshot README provides a dependency-free hash-verification command.

Source-boundary checks are separate:

```bash
make source-test PREP_PYTHON="/existing/environment/bin/python"
```

Use the existing source-reader Python environment with pandas and DuckDB; source
preparation also requires the pinned upstream readers. The latest local checks
passed the artificial E2E and 18 source checks; nine source checks were unavailable
without DuckDB. See [test scope](tests/README.md) and [dated receipts](WORKLOG.md).
No analysis was rerun to package the collaborator outputs.

## Data access and full clinical reproduction

Reports, figures and aggregate analysis tables may be versioned and shared with
the repository, as confirmed by the owner on October 18, 2026. The
[versioned snapshot](results/2026-10-18/README.md) comprises the scientific report,
complete audit, selected gallery/exports and saved aggregate tables. Logs,
temporary runs and source-access receipts are not included in the reading packet.

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

The [supplement specification](docs/SAME_DAY_ABG_SUPPLEMENT.md) adds two models
of same recorded-day co-occurrence, **not verified same-sample pairing**.
Both use the same co-observed primary patients, inherited adjustment and primary
BMI spline knots; no new PIF is computed. Current software uses aggregate schema 9.
The primary clinical snapshot and selected B/F2 remain unchanged. Clinical
qualification and new estimates are pending completion of this release.

The [historical pairing-feasibility report](results/2026-10-20-paired-abg/README.md)
remains available. Its raw-export trace confirmed that sample identifiers were
not supplied in the original laboratory export. The new definition requires a
common recorded date, not a specimen identifier. See the source contract for
private enrichment and qualification; ordinary report rendering reads saved
aggregates only. No abstract is drafted by this update.
