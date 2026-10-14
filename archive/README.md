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
