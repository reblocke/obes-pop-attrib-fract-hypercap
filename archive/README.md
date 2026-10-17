# Historical analysis index

The active workflow is the [observed-population curve report](../reports/bmi_hypercapnia.qmd)
and its [complete audit](../reports/bmi_hypercapnia_audit.qmd). Current commands
accept only version-5 bundles. The command descriptions below record historical
interfaces; they are not promises of compatibility with the current launcher.

## Version-4 curve / MAR–MNAR reports, preserved 2026-10-16

The unchanged source is retained at Git commit `1626a6db8ac5d347df7f5c0444b5bcac755ea457`
(clinical analysis release `f18d383`). The private clinical run
`curve-analyze-20261016T160703-17017` and its hashed bundle remain immutable.
It includes the earlier full-C gas projections and MNAR scenarios. These are
superseded scientific outputs; the current renderer rejects them rather than
changing their labels. The new observed-population run
`curve-analyze-20261016T225112-24371`, estimated from merged `ca24564`, retains its
own identity. Its automated comparison confirms unchanged models/cohorts and
observed scenarios against that historical bundle. Earlier visual-QC limitations
are documented in the current handoff; historical receipts are not overwritten.

## Earlier archive index (historical command descriptions)

# Runnable historical analyses and unchanged originals

The primary analysis is [the patient-level one-unit BMI shift report](../reports/bmi_hypercapnia_triangulation.qmd). Historical tracks retain distinct populations/outcomes/counterfactuals and must not supply its estimates.

| Source | Role | Command / provenance |
| --- | --- | --- |
| [Dated unchanged sources](2026-10-13-bmi-to-40/provenance.json) | Original R reports, prior triangulation helpers/report/launcher/fixture and prior decisions before the authorized change | Exact bytes and SHA-256 from source commit `1e78e3c`; frozen reader/report for version-1 saved runs. |
| [Repaired historical R report](r/obesity_hrf_paf_analysis.qmd) | Historical HRF analysis with focused missingness, ICD and attrition repairs; original model/estimand definitions retained | `make legacy-r INPUT=...`, `legacy-r-html`, `legacy-r-pdf`; ignored fresh historical output. `make historical-test` reproduces original defects and checks repairs. |
| [Earlier reconstructed report](r/reconstructed_obesity_hrf_from_pdf.qmd) | Unchanged archival reconstruction with its original limitations | `make render-archival`; not the repaired historical or primary analysis. |
| [Immutable Stata original](stata/36_subpop_hazard.source.do) | Exact upstream source | Existing `docs/stata_import_provenance.json` binds its hash/source identity. |
| [Runnable Stata repaired copy](../stata/do/36_subpop_hazard.do) | Preserved historical analysis plus previously authorized decimal plotting repair | Explicit `make stata-check`, `make stata-test`, and `make stata` with approved DTA/installed licensed runtime. |

Version-1 BMI-to-40 runs remain immutable. `make render RUN=<version-1 run>` validates them and uses their frozen original report/figures, preserving nine cells and BMI-to-40 labels. Version-2 runs use the fifteen-cell, BMI >30 one-unit-shift definition. This compatibility path performs no clinical data load or model refit.

Only source originals are tracked here. Raw data, generated reports, clinical artifacts, input paths and local receipts are ignored. Archive hash tests are a preservation check, not acceptance of a historical clinical result.

## Frame-specific version 2, preserved 2026-10-14

`2026-10-14-frame-specific/` contains sixteen unchanged sources/documents from `d8909df`, with hashes in provenance.json. It retains the BMI >30 minus-one contrast in three independently indexed frames and fifteen cells. It is supporting work, not the new common-index study.

Use `make frame-triangulation-test`, `make frame-triangulation-fixture` or explicit `make frame-triangulation INPUT=... MANIFEST=...` (version 2). The wrapper verifies hashes and executes a copy inside ignored `artifacts/triangulation/frame-workspaces/`; it does not modify the archive. Default saved-run render dispatches version-1/2 bundles to these frozen sources. Existing historical R/Stata commands remain unchanged.
