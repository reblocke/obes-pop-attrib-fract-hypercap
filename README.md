# BMI and documented hypercapnia

**Study question:** How does documented hypercapnia probability vary across BMI,
and how much modeled burden changes under a one-unit BMI reduction **only above 30**?

This is a descriptive analysis of a selected 2022 TriNetX-derived emergency and
inpatient cohort. The current workflow includes **all valid available BMIs**,
then retains patients represented through a non-OBESITY historical source-entry
pathway. Lower-BMI patients contribute baseline burden even though the scenario
does not change their BMI. Gas findings apply to patients with evaluable evidence,
not to untested patients or the general population.

## Start here

The verified setting-adjusted all-BMI snapshot contains **380,206 primary patients** and a nested
**175,271-patient BMI≥30 secondary**, selected at the same fixed indexes. All three
endpoint families include categorical encounter-setting adjustment (EMER reference;
IMP inpatient), without interaction. Source qualification, numerical review and
scoped visual review passed; investigator interpretation and new figure approval
remain pending.

| Read without running code | Contents |
|---|---|
| [Scientific PDF](results/2026-10-26-setting-adjusted/bmi_hypercapnia.pdf) / [HTML](results/2026-10-26-setting-adjusted/bmi_hypercapnia.html) | Integrated methods, results and verification-oriented detail |
| [Complete audit PDF](results/2026-10-26-setting-adjusted/bmi_hypercapnia_audit.pdf) / [HTML](results/2026-10-26-setting-adjusted/bmi_hypercapnia_audit.html) | Exhaustive cohort accounting, coefficients, covariance and diagnostics |
| [Key-figure PDF booklet](results/2026-10-26-setting-adjusted/key_figures.pdf) / [gallery](results/2026-10-26-setting-adjusted/gallery.html) | F1-main, F2, both component families and nested secondary counterparts |
| [Aggregate tables](results/2026-10-26-setting-adjusted/TABLES.md) / [packet README](results/2026-10-26-setting-adjusted/README.md) | Complete CSVs, result navigation, verification and historical reconciliation |
| [Current scientific specification](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) | Exact all-BMI design, endpoints, models and estimand |
| [LLM reading guide](docs/LLM_GUIDE.json) | Machine-readable navigation, evidence rules and dated approval state |

For an email introduction, start with the scientific PDF and nine-figure booklet;
include the complete audit or its link for detailed checking. The audit preserves
all required rows and is much larger than the scientific report. Earlier dated
snapshots remain unchanged and retain their dated eligibility and adjustment.

Download PDFs using GitHub's **Download raw file** control. Galleries open locally
after cloning/downloading their complete folder; GitHub otherwise shows HTML source.
Verify each snapshot's manifest before quoting numbers. Snapshots are reading
packages, not runnable analysis bundles. Existing small aggregate counts are
owner-cleared for public disclosure; raw and patient-level data remain excluded.

The [setting-adjustment comparison](results/2026-10-26-setting-adjusted/verification/comparison-receipt.json) verifies unchanged source, samples, events and spline bases against the immutable [October 24 snapshot](results/2026-10-24-all-bmi/README.md). The new packet includes full old/new curves and a numerical refresh ledger; existing abstract files remain unchanged.

## What the current analysis does

1. **Select once:** first adult 2022 ED/inpatient encounter with any valid available
   BMI in the authenticated original encounter list, before gas availability,
   adjustment completeness or RFS membership. Unresolved earlier eligibility and
   ties are not bypassed. BMI is current/prior reported or calculated from observed
   height/weight under inherited rules; there is no statistical imputation.
2. **Define populations at that index:** primary has any non-OBESITY source pathway,
   including OBESITY overlaps. The BMI ≥30 secondary is nested at the same index.
   Current-BMI and overlapping all-OBESITY-route checks are retained. Obesity-only,
   unresolved membership and the combined cohort are audit-only.
3. **Estimate three connected families:** binary arterial, combined-gas and ICD
   outcomes; joint same-day hypercapnia with/without documented acidemia; and joint
   ICD acuity/chronic-OHS categories. All three families repeat in the BMI ≥30
   secondary. The integrated scientific report defines all methods before Results.
4. **Model across BMI:** a three-degree-of-freedom natural spline plus inherited age,
   sex, race/ethnicity, region and categorical index encounter setting adjustment.
   EMER is reference; predictions retain observed setting. Each main population fixes its own
   knots before fitting outcomes. Gas models use evaluable patients; diagnosis
   models use complete capture. Joint model probabilities are coherent partitions.
5. **Quantify a secondary scenario:** BMI>30 decreases exactly one; BMI≤30 stays
   unchanged. PIF is the relative change in paired modeled probabilities over the
   **entire model reference population**. Signed BMI-band contributions and full
   covariance reconcile to the total. There are no subtype-specific PIFs.

Same-day co-occurrence is not verified same-sample pairing. ICD acuity is coding,
not acidemia or compensation. Known capture is not a positive diagnosis. Missing
or unusable evidence is not negative. Pointwise model intervals do not quantify
selection, measurement or confounding bias. No MAR/MNAR, IPW, incident-disease or
causal-prevention claim is part of this workflow.

The current renderer prefers **F1-main** for the primary analysis: combined-gas and nested arterial curves, stacked same-day components, and separate ABG/VBG usable-evidence ascertainment. The table uses BMI 30 and 40 kg/m². F1 A–C and existing secondary/sensitivity displays remain available; F2 now presents absolute
burden and signed contributions. Component figures are integrated in the same
scientific PDF, with secondary-population counterparts. Earlier scientific or
figure approval does not automatically approve new estimates. **No abstract is
being drafted.** ATS 2027/November 4 remains the owner's stated target.

The schema-14 clinical run and aggregate-only reports are complete. All 35 fitted
positions include setting; the constant ICD-capture position remains explicit.
See [implementation and verification](docs/ENCOUNTER_SETTING_UPDATE.md). The new
primary PIFs are 1.01% for arterial and 0.83% for combined-gas hypercapnia. These
are modeled scenario estimates, not treatment effects.

## Repository map

| Path | Purpose |
|---|---|
| `R/` | Typed input, one cohort ledger, population/model registry, fitting, standardization and presentation |
| `scripts/` | Preparation, qualification, one estimation launcher, aggregate-only rendering and review |
| `config/` | Executable scientific settings, variable dictionary and source examples |
| `reports/` | Scientific mini-paper and complete audit Quarto sources |
| `results/` | Immutable dated reports, figures and aggregate tables; no patient rows |
| `docs/` | Scientific/source authorities, decisions, LLM navigation and QC |
| `tests/` | Artificial end-to-end evidence and justified source/numerical boundaries |
| `archive/`, `Code/`, `Documents/` | Recovery index and retained historical material, not current analysis |
| `data/`, `artifacts/` | Ignored private inputs and local execution/review bundles |

[AGENTS.md](AGENTS.md) governs repository work. [The source contract](docs/SOURCE_CONTRACT.md)
governs qualification and privacy. [The decision log](docs/DECISIONS.md) preserves
scientific history; [WORKLOG.md](WORKLOG.md) records commands, artifacts and actual
verification. The JSON guide is documentation, not a second analysis configuration.

## Run the software

Run from the repository root with existing R ≥4.3, Make, Quarto, XeLaTeX and Poppler.
Required R packages: `ggplot2`, `jsonlite`, `digest`, `lpSolve`, `nnet`, `knitr`,
`rmarkdown`; clinical reading also uses `haven`. Source preparation uses the pinned
upstream Python environment with pandas/DuckDB. Nothing installs automatically.

```bash
make test
make source-test PREP_PYTHON="/existing/source-environment/bin/python"
```

Each report render stages byte-verified QMD/CSS inputs in its own review directory, so Quarto intermediates do not collide across jobs. This does not copy clinical inputs or refit models.

`make test` creates artificial data, estimates once, renders both reports and
checks independent calculations, source/hash rejection, completeness and figures.
It leaves a fresh `artifacts/triangulation/e2e-.../receipt.json`, `checks.csv`, logs
and repeatable artifact hashes. The source suite has a separate receipt. Skipped
checks are unavailable, not passed; artificial success is not clinical qualification.
The complete audit can take substantial time to render.

Clinical workflow (exact private paths required):

```bash
make prepare PREP_PYTHON="/existing/source-environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" OUTPUT="/private/fresh-input"
make qualify PREP_PYTHON="/existing/source-environment/bin/python" \
  SOURCE_CONFIG="/private/reviewed-source.json" \
  PREPARED="/private/fresh-input" OUTPUT="/private/fresh-qualification"
# Complete the pending manifest only from verified qualification evidence.
make preflight INPUT="/private/fresh-input/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make analyze INPUT="/private/fresh-input/study-input.rds" MANIFEST="/private/reviewed-manifest.json"
make render RUN="artifacts/triangulation/<exact-saved-run>"
```

Preparation combines source metadata and all endpoint evidence in one transaction;
there are no separate enrichment commands. It reuses the accepted candidate map.
Clinical estimation requires a clean merged Mini checkout and qualified input.
Use `make render-html`, `make render-pdf`, or `make render-reports RUN=... FIGURES_FROM=...`
for presentation work from explicit saved aggregates, without clinical reads/refits.
`make fixture` runs the artificial example; `make cohort-audit` fits no models.

Current runtime: input schema 5; aggregate schema 14;
`bmi_hypercapnia_rfs_curve_audit_v9`. Historical bundles are rejected, not migrated
or relabeled. Historical reading snapshots remain accessible under `results/`.
Source acceptance, execution, numerical review, visual review, investigator
interpretation and submission approval remain separate states.
