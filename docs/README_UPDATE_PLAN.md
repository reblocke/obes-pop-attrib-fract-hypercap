# README audit and focused update plan

Audit date: 2026-10-13. Scope: the current local working tree on `main`, based on `1e78e3c2ece8771a189b910b415959d3f3734647`. Live remote `origin/main` still resolves to that commit. The primary workflow and current README edits are uncommitted; the published README still describes the older BMI-to-40 workflow.

Implementation completed 2026-10-13. The original audit and proposed sequence below are retained as dated planning context; the execution record is at the end. The update used the readme-builder repository template and research documentation checks, adapted to this R/Quarto research repository. Analysis, source rules, dependencies, licensing and publication settings remain unchanged.

## Assessment

The local [README](../README.md) is substantively aligned with the approved BMI >30 one-unit shift, fifteen-cell registry, aggregate-only rerendering and runnable historical archives. It distinguishes artificial verification from clinical source acceptance and avoids causal prevention claims. All thirteen local links resolve; all seventeen distinct documented Make targets exist. It is not yet a complete starting guide for a new collaborator.

| Requirement | Audit status and evidence | Planned correction |
| --- | --- | --- |
| Purpose and current scientific specification | Supported: README opening, [decisions](DECISIONS.md), registry and shift helper. | Preserve the specification; add intended audience and the primary report/output in one short orientation paragraph. |
| Current implementation versus clinical readiness | Partial: limitations are accurate but buried under the workflow; source status includes machine-specific access history. | Add a dated status near the top: primary code and artificial workflow verified, clinical input qualification pending. Link the [source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) for actual open checks. |
| Starting prerequisites | Partial: README environment section comes after runnable commands. Source YAML requires XeLaTeX and Arial for PDF, which are currently summarized only as a working toolchain. | Put prerequisites before quick start; state repository-root working directory, R >=4.3, Make, Quarto, installed primary packages and the actual PDF engine/font. Describe current environment as observed, not a portable lock. |
| Minimal meaningful example | Partial: supported artificial commands exist, but four different checks precede an explicit success/output guide. | Lead with `make triangulation-test` and `make triangulation-fixture`; put historical checks in their own section. Document the existing HTML-only launcher option for collaborators without the PDF toolchain, after a bounded smoke check. |
| Expected outputs and recognizable success | Partial: directory families are documented, filenames and status receipts are not. | Show a compact output map and the printed run directory. Define success using completed receipts and expected files; distinguish success from clinical qualification. |
| Source-gate wording | Contradictory count: README line 32 says nine primary input requirements. The loader requires seven named source gates; nine is the number of primary analysis cells. | Say all required primary fields, mappings and source gates must qualify; keep nine primary plus six sensitivity cells as a separate registry statement. Avoid another hard-coded input-requirement count. |
| Data interpretation and uncertainty | Supported but spread across paragraphs: model-evaluable subsets, retained unknowns, overlapping frames and conditional intervals. | Retain those meanings. Use a small outcome/window summary or a clear methods link so ABG-only and ABG-or-VBG outcomes cannot be conflated. Keep detailed dictionaries and full methods in canonical documents. |
| Data access and provenance | Partial: ignored inputs and pending manifest are clear, but no external access procedure is documented. | State that clinical data are not distributed and authorized users supply an authenticated input/reviewed manifest. Do not invent an access application process or approvals. Describe upstream evidence by its assessed immutable revision, rather than a timeless claim about current main. |
| Human reading path | Partial: useful links exist, but no short project map; historical dependencies point into agent instructions. | Add a small map of primary report/helpers, manifest, source/methods documents and archive index. Keep agent rules out of the collaborator quick start. Point historical users to human documentation and actual required packages. |
| Companion-document consistency | Contradictory historical wording: [data management](DATA_MANAGEMENT.md), lines 15-16, still calls a fallback-loading report canonical. The repaired historical launcher/report now requires explicit input. | Make a narrowly scoped clarification separating the unchanged original's former fallback from the current explicit historical input route. Preserve the dated history and archived sources. |
| Licenses and citation metadata | Missing: no root LICENSE/LICENCE or CITATION.cff was found. This does not establish reuse permission or a citation. | Leave as a maintainer decision if external reuse/release is intended. Do not create a license, author list, DOI or citation file without supported metadata and authorization. |
| Published-version alignment | Partial: current local README differs from remote main; matching implementation files are also uncommitted. | Publish documentation with the corresponding implementation only when that workflow is authorized. Do not advertise the fifteen-cell version on top of the older released code alone. |

## Proposed update sequence

1. **Correct consequential wording.** Update source-gate language and scope current clinical readiness specifically to the primary workflow. Replace references to a particular machine/Mini outage with the dated assessment link. Preserve every missingness, source-qualification and historical-definition boundary.
2. **Make the quick start self-contained.** Move environment/root-directory requirements before the commands. Separate artificial demonstration, clinical estimation and saved-run review. Keep the existing installed-package workflow; there is no committed `renv.lock`, and this task does not authorize package installation or environment initialization.
3. **Show what to open and how to recognize success.** Document the existing outputs below and fresh `reviews/<review-id>/` directory used for saved-run rendering. Explain that nonestimable/source-pending cells are recorded outcomes of the workflow rather than numerical zeros.
4. **Add a small navigation map.** Link the primary QMD, estimation/reporting helpers, input manifest, decisions/source handoff and archive index. Keep earlier `Code/` drafts clearly subordinate to the primary entrypoint; do not move or rename them during this documentation change.
5. **Keep the root concise.** Retain the existing exhibit and archive summaries. Move no scientific authority into the README: detailed analysis rules remain in decisions/plan, source qualification in assessment/handoff, provenance in manifests and verification history in WORKLOG.md. Make only the companion data-management clarification identified above.
6. **Verify before delivery.** Check links, command/format behavior, output names, meaning and privacy; review a small documentation-only diff. A later authorized publish must include the matching code version.

Proposed root reading order: purpose and dated status; prerequisites and artificial quick start; expected outputs; qualified-data workflow; saved-run review; project/methods links; exhibit alternatives; runnable historical archives; reproducibility and limitations. Adapt existing headings instead of importing unused template sections.

## Exact supported routes and output map

These are inspected existing commands, not new Make targets:

```bash
make triangulation-test
make triangulation-fixture
Rscript --vanilla scripts/render_triangulation.R fixture html
make render RUN="artifacts/triangulation/<saved-run>"
make render-html RUN="artifacts/triangulation/<saved-run>"
make render-pdf RUN="artifacts/triangulation/<saved-run>"
```

The HTML-only fixture command is supported by the launcher argument parser, but this particular standalone invocation was not executed during the README audit. It must not be described as `make triangulation-fixture FORMAT=html`, because that Make target does not forward a format argument. Clinical/preflight commands remain in their separate qualified-data section and are not part of onboarding smoke verification.

| Existing output | Meaning / generating path |
| --- | --- |
| `aggregate_bundle.rds`, `aggregate_results.csv`, `specification_registry.csv`, `bundle_manifest.json` | Saved aggregate analysis and exact scenario/registry/file identities from estimation. |
| `frame_counts.csv`, `scope_counts.csv`, `timing_audit.csv`, `bmi_summary.csv`, `bmi_diagnostics.csv` | Cohort/denominator, timing and BMI/model-shape checks; not patient-level data. |
| `analysis_status.json`, `analysis_receipt.json`, `input_receipt.json`, `session_info.txt` | Run completion, input/source declarations, one-estimation receipt and actual package/runtime versions. |
| `rendered/bmi_hypercapnia_triangulation.html` and `.pdf` | Human review report, with output format dependent on the selected command. |
| `figure-gallery.html`, `figure-gallery.pdf`, `figures/candidate-A.*`, `candidate-B.*`, `candidate-C.*` | Three alternatives generated from the same saved ledger, with SVG/PDF/PNG/JPG exports. |
| `render_status.json`, `quarto-render.log` | Render completion/failure and expected-output/source-stability checks. |

A fixture/clinical run writes a fresh directory under `artifacts/triangulation/`. A saved-run render writes a fresh review directory inside that run. All generated artifacts remain ignored and are absent from a fresh clone. No repository-root link should pretend that a particular ignored local report is distributed.

Success means a zero command exit, `analysis_completed` for estimation, `render_completed` for the requested report formats, `expected_outputs_present=true` and unchanged render-source hashes. The fixture must retain its artificial banner. Clinical/source/scientific acceptance does not follow from these status strings or a hash match.

## Verification and completion criteria

- Recheck all repository-local links and every documented Make target/launcher format against the same source version. No second documentation validation framework is needed.
- Reuse the latest evidence where content is unchanged. Prior `make triangulation-test` passed twenty-four artificial groups; the post-fix fixture completed HTML/PDF/all exhibits. This audit inspected those receipts rather than repeating models or opening clinical data.
- For a newly documented HTML-only starting route, use a bounded artificial smoke on an authorized implementation turn, confirm its actual output/status, and label any unrun platform/environment paths. Do not execute clinical, Stata, installation or `renv-init` commands just to validate prose.
- Confirm prerequisites against the QMD/launcher and existing installed dependencies; do not infer cross-platform support. The audit observed R 4.6.1 and Quarto 1.10.18 locally; they are observed versions, not a newly imposed minimum or a lockfile.
- Verify that primary/specification authority, explicit INPUT/MANIFEST/RUN requirements, 15-cell identity, source-pending states, aggregate-only rerendering and version-1 archive behavior are all preserved.
- Review for patient data, sensitive paths, unsupported validation/licensing claims and duplicated scientific definitions. Run `git diff --check`; confirm generated evidence remains ignored.
- Confirm README scope stays documentation-only and unchanged originals remain unchanged. Log the implemented documentation changes separately from this planning audit.

Completion means a collaborator can identify the primary analysis, run a supported artificial example, find its report/ledger/receipts, understand the clinical input gate and distinguish historical tracks without reading agent instructions. Missing clinical acceptance, external access terms, licensing/citation decisions and untested environments remain explicit; none is silently resolved by documentation.

## Evidence examined in this audit

Current local README, Makefile, root/scoped instruction inventory, primary launcher/helpers/QMD, manifest loader/template, historical launcher/report, archive map, source assessment/handoff, data-management history and latest artificial analysis/render receipts. Static checks found thirteen valid local links and seventeen defined Make targets. Live remote main matches the base commit above. No analysis was rerun, restricted input opened, package installed, README edited, commit made or external message sent.

## Execution record — 2026-10-13

- Updated the root README with collaborator purpose, dated implementation/clinical status, prerequisites before commands, an artificial quick start, exact output/success map, separate clinical and saved-run routes, outcome/window and project maps, portable source-readiness wording and explicit historical dependencies. Corrected the source-gate count wording. Licensing/citation and external data-access information remain explicitly undeclared rather than invented.
- Clarified `docs/DATA_MANAGEMENT.md`: fallback paths describe the unchanged original R report; the repaired historical replay requires explicit INPUT, and the primary workflow requires explicit INPUT/MANIFEST or saved RUN. Archived sources were not edited.
- Executed `Rscript --vanilla scripts/render_triangulation.R fixture html` successfully in a fresh ignored artificial run. Analysis ran once, all fifteen cells were retained, HTML rendered, PDF figure masters/gallery were exported, and no report PDF was requested or created. Full-precision results match the previous fixture. No clinical data was opened.
- Checked twenty-two README-local links, ten data-management links, all seventeen distinct documented Make targets, exact artifact names/statuses and unchanged source/archive hashes. The README also parses successfully through the installed Quarto/Pandoc GFM renderer. `git diff --check` passes.
- Preserved pre-edit documents and source-hash baseline, plus a documentation verification receipt, under ignored `artifacts/triangulation/readme-update-20261013/`. The HTML-only run is `artifacts/triangulation/fixture-20261014T043753-20169/`; this UTC directory name corresponds to October 13 in America/Denver. Existing verification evidence was reused for unchanged paths rather than rerunning clinical or historical analyses.
- No installation, environment initialization, code/scientific-rule edit, source qualification, publication, commit or push occurred. This is a completed local documentation update; publication with the matching implementation remains a separate action.
