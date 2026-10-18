# BMI and documented hypercapnia

This repository estimates BMI–hypercapnia probability curves in an adult 2022
acute-care cohort and produces a scientific report plus a complete construction
and model audit. It uses authenticated original TriNetX encounter keys, one fixed
BMI-eligible index per patient, and historical source-entry membership. The
primary population has at least one non-OBESITY entry pathway, including obesity
overlaps. Obesity-only entry is confined to flow reconciliation and the audit.

**Current analysis:** schema 7, `bmi_hypercapnia_rfs_curve_audit_v2`. The qualified
clinical run completed on 2026-10-17; numerical verification and scoped report/QC
review are recorded privately. Investigator interpretation and submission approval
remain separate. The current cleanup changes the software/reading path, not the
scientific specification or saved estimates. Restricted data and clinical outputs
are not distributed here; artificial execution does not establish clinical validity.

## Run the complete artificial example

Run from the repository root with existing R ≥4.3, Quarto, XeLaTeX/TinyTeX and
Poppler (`pdftotext` and `pdfinfo`).
Required R packages are `ggplot2`, `jsonlite`, `digest`, `lpSolve`, `knitr` and
`rmarkdown`; clinical input reading also uses `haven`. Nothing is installed
automatically. Separate source-adapter checks use an existing Python environment with
pandas, DuckDB and the pinned upstream readers.

```bash
make test
```

The E2E runner creates artificial input, estimates once, renders both HTML/PDF
reports, and checks persisted results and artifacts. It prints a fresh
`artifacts/triangulation/e2e-...` receipt directory containing `receipt.json`,
`checks.csv`, `run.log` and `artifact-hashes.csv`, linked to the saved run and review.
A passed receipt documents automated coverage, not human or scientific approval.
Use `make source-test PREP_PYTHON="/existing/environment/bin/python"` for the
retained source-boundary checks. See [test scope](tests/README.md) for coverage
and dependency limitations.

For an artificial run without the E2E assertions, use `make fixture`. To change
presentation, rerender the exact saved schema-7 run rather than refitting:

```bash
make render RUN="artifacts/triangulation/<exact-saved-run>"
# Or render-html / render-pdf with the same RUN.
```

Each render creates a fresh `reviews/<timestamp>-<pid>/` with scientific and audit
HTML/PDF files, figure exports, captions, a gallery and hash-bound render receipt.
Rendering reads aggregates only. Move the whole review directory together: the
complete audit HTML links to its figure atlas. Source/configuration changes that
affect estimation require a new run; old bundles are not relabeled or migrated.

## Read or extend the analysis

| Start here | Purpose |
|---|---|
| [Scientific and interface guide](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) | Population, outcomes, models, uncertainty, outputs and commands |
| [Source contract and restricted execution](docs/SOURCE_CONTRACT.md) | Accepted products, preparation, qualification and evidence limits |
| [Decision history](docs/DECISIONS.md) | Settled choices, superseded designs and unresolved interpretation |
| [Figure QC](docs/PUBLICATION_FIGURE_QC_PLAN.md) | Figure alternatives, publication exports and actual review scope |
| [Analysis configuration](config/bmi_hypercapnia_analysis.json) / [variable dictionary](config/variable_dictionary.csv) | Machine-readable design and field definitions |
| [Archive index](archive/README.md) | Exact recovery of retired versions from Git |

`R/analysis.R` loads the active input, cohort, model, standardization and reporting
modules. `scripts/run_bmi_hypercapnia.R` audits/estimates; the render script consumes
saved aggregates. The two report sources are [scientific](reports/bmi_hypercapnia.qmd)
and [audit](reports/bmi_hypercapnia_audit.qmd). `WORKLOG.md` records recent execution and links earlier history.

Gas curves describe the outcome-evaluable population, not untested patients.
The secondary one-unit reduction applies only to observed BMI >30 and uses paired
model predictions. It is a model-standardized potential impact fraction, not a
causal effect of weight loss or an incidence reduction. No MAR/MNAR projection or
IPW is part of the current analysis. Historical source-entry flags do not exhaust
clinical criteria; this partition does not eliminate selection bias.

Clinical estimation requires a clean merged Mini checkout, an explicit qualified
input/manifest and the pre-index audit companion. Follow the source contract;
`data/raw/full_db.rds` is a historical comparator, never a fallback. Keep all raw
records, exact aggregate audits, manifests, receipts and generated reports in
ignored/private storage. Aggregate does not automatically mean safe to publish.
