# Execution log

Current scientific rules: [analysis guide](docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).
Source requirements: [source contract](docs/SOURCE_CONTRACT.md). This log records
recent execution; settled decisions belong in [DECISIONS](docs/DECISIONS.md).

## Prior evidence retained

The full earlier log is recoverable at Git
`0e5641f9579b4c8f20d90ed22732a0ebcf0ed2d6:WORKLOG.md`. Its uncommitted continuation,
including the complete publication-QC record before this cleanup, is preserved
privately at
`artifacts/triangulation/repository-refactor-20261017T210721/WORKLOG.before.md`
(SHA-256 `8406114dac0f4df593912ca3042078a66c7481b4a3a17edd82203699d022a5d2`).
No historical clinical result or receipt was deleted or relabeled.

- The schema-7 clinical run `curve-analyze-20261017T175520-51541` was estimated
  from merged `043fea6` after source qualification. Later presentation revisions
  did not refit models or read clinical inputs.
- Publication review `20261017T205353-20587` contains both scientific/audit
  HTML/PDFs, 1,242 figure sets, 39 key layouts and scoped agent visual receipts.
  All 74 then-registered acceptance checks and 27 focused checks passed. These
  are historical receipt counts, not requirements for future test architecture.
  Exact scope/limits are in the private review and the [figure QC plan](docs/PUBLICATION_FIGURE_QC_PLAN.md).
- Investigator interpretation, final venue sizing and submission remain separate.

## 2026-10-17 — Focused repository and E2E refactor

Owner request: retire stale version support, reduce low-signal tests, use parallel
agents, and record an E2E-first testing policy. The pre-edit plan, source hashes,
worktree patch and original fixture analysis are in
`artifacts/triangulation/repository-refactor-20261017T210721/`.

Work was split into runtime/source preparation, testing, and documentation/archive
agents; the parent owned entrypoint/instruction integration and final verification.
Existing uncommitted publication edits were preserved before cleanup.

Changes:

- Removed five unreachable legacy R modules, superseded launchers, frame-grid
  reports, runnable Stata wrappers and duplicate historical source packages.
  The immutable original Stata program and all historical rendered artifacts
  remain. Exact retired source identities are in `archive/retired_sources.csv`.
- Retired schema-1 broader-history preparation. Current schema-2 original-list
  mapping remains; schema-3 typed input is still an intermediate before schema-4
  RFS metadata enrichment. No current estimator/configuration equations changed.
- Replaced obsolete/duplicative test runners and checklist gates with one public
  artificial analysis-to-report E2E and independent output oracles. Source
  boundary checks remain separately justified because typed-input E2E cannot
  authenticate upstream transport. No synthetic human-review success is asserted.
- Condensed README, scientific/interface guide, source contract and decision log;
  removed superseded plans. AGENTS.md includes the three requested testing rules.

Checks completed before the final E2E:

- Baseline artificial analysis saved before edits. The current aggregate clinical
  bundle still loads with its original source/hash validation; no clinical input
  was opened.
- Four artificial mapped-preparation cases compare 32 output artifacts before and
  after retirement, using reader/selection stand-ins plus the real R writer.
  Data/evidence are identical except the expected preparation-source hash.
  This is not clinical source qualification.
- Historical source recovery was checked against Git; a CRLF working-tree
  normalization exception is recorded rather than misreported as a byte match.

Verification:

- `make test` completed the public artificial launcher and both full HTML/PDF
  reports. The saved run is `curve-fixture-20261017T211707-27225`; its scientific
  PDF has 34 pages and its complete audit PDF has 3,342 pages. Subsequent oracle
  revisions reused this exact run/review rather than repeating full estimation
  or rendering. Numerical checks independently reconstruct indexes, samples,
  spline fits, probabilities, intervals and paired contributions.
- All 49 aggregate tables match the pre-refactor artificial analysis exactly,
  apart from measured `fit_runtime` in two diagnostic tables. The initial literal
  comparison and explicit timing exception remain in the cleanup evidence.
- Independent review reproduced false passes for omitted curves/scenarios,
  collapsed curve intervals, invented model failures and duplicated covariance
  coordinates. The replacement E2E now requires complete expected inventories
  and independently calculated values, rather than checking only rows present.
- `make source-test` with the existing bundled Python ran 18 checks successfully;
  nine DuckDB-dependent checks remain unavailable. The runner reports incomplete
  status/exit 78, not success. Its source hashes remained stable; nothing was
  installed. This does not issue clinical source acceptance.
- The 21 retained analysis/configuration/report files match their pre-cleanup
  hashes. All 22 historical assets/original Stata files remain unchanged. The
  94-row retirement index verifies against Git, covering 93 removed files and
  the retained immutable Stata original.
- Current documentation links, Python syntax and `git diff --check` pass.
  Generated artifacts remain ignored. Scientific PDF pages 7 and 16 were
  visually spot-checked for readable tables, intervals and captions; this is
  not a claim of a new full visual or scientific review.

The final receipt paths, source identities, artifact verification and reduction
measurements are recorded in the cleanup directory's `closeout.json` and
`reduction-summary.json`. Previous failed/intermediate receipts are retained.
No installation, clinical estimation, remote change, commit/push/merge or
submission occurred during this task.

## 2026-10-17 — Review and release of the focused workflow

The owner authorized review, fixes, commit, push, PR and merge. Review covered
the complete staged/unstaged/new-file change against `origin/main` at
`0e5641f9579b4c8f20d90ed22732a0ebcf0ed2d6`, including the preceding publication
figure changes. Release work uses `codex/focused-curve-workflow`.

One actionable presentation defect was reproduced: F2 used a hard-coded one-unit
scenario title/caption even though the saved configuration can explicitly name
another policy. The existing output-level E2E was extended before the fix; its
old-export assertion failed at `e2e-20261017T220219-32507/receipt.json`. F2 now
uses the saved policy label, and describes its intervals as model-based. The
failure plan and review evidence are in
`artifacts/triangulation/release-review-20261017T220210/`.

The scientific estimators and configuration are unchanged. The fresh aggregate-only
render/E2E passed against the existing artificial bundle. Its receipt is
`artifacts/triangulation/e2e-20261017T220313-32607/receipt.json` (SHA-256
`2ca69af0f9942976c802d8243c57d91ae8e1b09c42a51bb3349433b51099bbff`).
Both full HTML/PDF reports rendered, including all 3,342 audit pages. Independent
numerical and printed-interval checks passed; all 5,247 indexed artifacts were
rehash-verified without mismatches. Stale-source, old-schema, corrupted-bundle
and unrelated-figure reuse were rejected as expected.

Focused visual review inspected all three affected F2 exports, scientific PDF
page 16 and audit pages 3295, 3301 and 3307. Labels, intervals and captions are
readable in grayscale without visible clipping or collisions. This is a scoped
artificial-data presentation review, not a fresh whole-audit manual review or
investigator scientific approval; details are in `focused-visual-review.json`.

Python syntax, local documentation links, retired-source recovery identities and
staged privacy checks pass. The unchanged source-boundary receipt remains
incomplete: 18 checks passed and nine require unavailable DuckDB. No dependency
installation or clinical rerun was performed. Generated evidence remains ignored;
the release receipt in the review directory records the final commit and PR.

## 2026-10-18 — Investigator approval and figure selection

Owner reconfirmed the ATS 2027 deadline as November 4, 2026 and granted provisional
scientific approval, requesting the figures for separate review and no abstract
drafting yet. Recorded this decision without changing scientific rules or treating
it as figure/submission approval.

Displayed the clinical review `20261017T205353-20587` main alternatives F1-A/B/C
and secondary F2; the publication gallery retains the supporting views and full
captions. Reverified its clinical bundle-manifest identity and all 3,765 figure
export hashes. Inspected the four displayed PNGs; no figures were regenerated and
no clinical data were read or models refitted. The separate private record
`artifacts/triangulation/investigator-review-20261018/approval-status.json` binds
the provisional approval and pending figure choice to this exact run/review.
The date is owner-confirmed, not newly portal-verified. No abstract text was written.

## 2026-10-18 — Selected figures and collaborator documentation

Owner selected primary/F1-B and primary/F2 as the working main figures and requested
a human-oriented README plus machine-readable LLM instructions for a collaborator.
Used the readme-builder skill. Preserved provisional scientific approval and the
instruction to defer abstract drafting; final submission packaging remains separate.

The README now leads with the study question, clinical packet reading order,
selected figures and interpretation limits, followed by methods/code navigation
and reproduction. It states that the existing scientific PDF embeds A while the
selected standalone B uses identical values, and that private results are absent
from a Git clone. `docs/LLM_GUIDE.json`, linked from AGENTS.md, supplies dated
authority/evidence pointers, approval boundaries, result keys, units and missing-
evidence handling without becoming another analysis configuration. The scientific
guide, decision log and figure QC note now reflect B/F2; prior exports and review
receipts remain unchanged. A separate private `figure-selection.json` links the
owner's choice to the previous approval record and exact clinical exports.

Verification: all 27 relative documentation links resolve; the JSON parses and its
authority/output paths, analysis identity, selected figure hashes, result columns
and main population/window/model/policy filters match the saved clinical bundle.
Six `make -n` checks verify documented targets without execution. All 42 tracked
analysis/configuration/report/test source files match their pre-edit hashes, and
`git diff --check` passes. Evidence is in
`artifacts/triangulation/collaborator-docs-20261018/verification.json`.
No estimation, report regeneration, dependency installation, abstract drafting,
external sharing, commit or push occurred in this documentation task.

## 2026-10-18 — Correct output-sharing scope

Owner clarified that analysis outputs may be included in Git; only raw and
patient-level data need to remain excluded. The previous collaborator wording
overstated the restriction by calling the entire review set private. Verified
that `.gitignore` currently excludes `artifacts/triangulation/`, including the
scientific/audit reports, figures and aggregate tables; historical rendered outputs
are already tracked elsewhere. The current review set consists of reports,
gallery/figure exports and QC evidence, with aggregate CSVs in its parent run.

Corrected README, LLM guide, agent guidance, source/scientific contracts and the
decision log. Clarified the ignore-rule comment without unignoring local runs or
patient data. No outputs were added to Git in this clarification; packaging them
for versioning remains distinct from permission to include them. JSON parsing,
relative-link checks and `git diff --check` verify this documentation-only change.
No clinical rerun, abstract text, external sharing or release was performed.

## 2026-10-18 — Versioned collaborator outputs and email PDFs

Owner authorized adding clinical reports, selected B/F2 figures, gallery and
aggregate tables to Git, updating human/LLM navigation, and reviewing/releasing
through a PR. Used readme-builder, figure-and-medical-illustration-qc and PDF skills.
This packages existing results without a new analysis or abstract draft.

`results/2026-10-18/` contains exact copies of the 34-page scientific PDF, 2,970-page
audit PDF, eight B/F2 exports, saved configuration and all 49 aggregate CSVs.
It adds a two-page vector-figure PDF with full captions, an offline B/F2 gallery,
human/machine table indexes, a package manifest and a separate dated review-state
record. Original reports and their creation-time approval flags remain unchanged;
the owner's later provisional approval and figure selection are recorded separately.
The scientific PDF still embeds F1-A; standalone B contains the same estimates.

README now links directly to the snapshot and explains the repository layout,
email starting set, historical files and source-access boundary. LLM_GUIDE.json
points to portable package paths and exact main-model IDs, avoiding accidental
selection of matched-sample sensitivities by population/window/form alone. The
snapshot is explicitly not a runnable aggregate bundle. Raw/patient data, model
frames/predictions, binary run objects, source-access receipts and local logs stay
excluded. `.gitattributes` preserves snapshot bytes across checkouts so CSV line-
ending normalization cannot invalidate recorded hashes.

Verification: 60 source copies match their original hashes; 68 packaged files are
manifested. All 49 tables (300,772 aggregate rows) retain their complete fields and
rows. The three intended main-model rows reproduce saved PIF and absolute-difference
scaling. All 122 documentation links and 22 gallery asset/links resolve locally;
the gallery has no external assets. Both new PDF pages were inspected at original
figure width and in grayscale. A missing CO₂ caption glyph was repaired with an
existing embedded Unicode font. PDF text and CSV field/category checks found no
patient identifiers, individual dates, source-access paths or credentials.

Browser visual inspection of the local HTML was blocked by the browser URL policy;
this was not bypassed and is recorded separately from completed PDF visual checks.
The complete audit retains its prior automated/full-table checks and sampled visual
review; no new claim of individual visual inspection of all 2,970 pages is made.
Evidence and repeatable packaging/check scripts are in the ignored
`artifacts/triangulation/collaborator-package-20261018/` directory. The package README
also provides a dependency-free integrity check usable from a clone. No analysis,
source pull, dependency installation, email or abstract drafting occurred.

Final release review exported the staged index into a clean temporary checkout
without private data/local runs and repeated package verification successfully.
All 43 analysis/configuration/report/test source files match the pre-edit baseline;
the 69 snapshot files retain exact bytes after Git checkout. `git diff --cached
--check` passes. The new package index/captions use LF endings; original CSVs are
unchanged. Full estimation E2E was not repeated for this output/documentation-only
release. `final-staged-verification.json` records the clean-checkout evidence;
the release receipt will bind the resulting PR and merged revision.

## 2026-10-20 — Paired-ABG supplement implementation

Baseline b93c8e3, branch codex/paired-abg-acidemia. Read ticket, source contract,
scientific plan and figure-QC skill. Recorded failure cases and wrote independent
source/paired-model fixtures before implementation. Source boundary tests passed.
Initial synthetic acidemic example correctly returned separation; revised the
artificial demonstration to exercise two fitted curves without changing clinical
failure handling or base fixture variables. Captured pre-change base estimates
in ignored paired-abg-development storage. Mini's original research checkout is
dirty with unrelated historical work: preserved it and plan isolated release
checkout. No new clinical model has been fitted or paired source accepted.

The read-only Mini query completed on the actual accepted canonical source,
covering 223,514 original study-input keys and 541,828 selected gas records.
All had date-only precision; no specimen/panel/accession/collection-time or
dedicated result_status/result_version fields were populated. Generic status
columns exist but their correction semantics are unreviewed. Pairing is unavailable. The 192,909
ordinary arterial PCO2 and 145,993 arterial pH records are not pair counts.
No clinical supplemental models were fitted. A separate aggregate-only report
is in `results/2026-10-20-paired-abg/`; the old reading snapshot is unchanged.

Review reproduced and fixed fallback to an old valid pH when an authoritative
new correction was unusable. Verified that case manually and retained the
independent correction/ambiguity fixtures. The initial clinical enrichment
stopped conservatively because dataframe subsetting stripped attributes; the
second comparison found attribute-order differences. Original column values and
all source attributes were identical. The corrected guard compares each original
column and named source attribute, and checks first indexes independently.
Fresh enrichment attempt 03 verified all 223,514 rows/indexes unchanged and
loaded successfully with both outcomes unknown. Failed attempts were retained.
The final adapter additionally binds the intermediate pairing summary hash.

Source-boundary verification passed all 31 checks without skips in the existing
Mini environment (receipt `source-tests-20261020T141115-11195`); no dependency
installation or upstream rebuild occurred. Raw source products and the dirty
historical Mini checkout were preserved. Main model coefficients, covariance,
curves and PIF quantities match the pre-edit artificial baseline and the
independent unchanged-input oracle. Native 190-mm grayscale S1 and the new
scientific-report pages were inspected; full E2E/audit review continues below.

Final `make test` passed in `e2e-20261020T135917-52754`. Expanded acceptance
(component probability intervals, disabled optional module and constant narrow
outcome) passed by replaying verification against the same source-matched saved
run: `Rscript --vanilla tests/run_e2e.R artifacts/triangulation/curve-fixture-20261020T135947-52784`,
receipt `e2e-20261020T141529-58534`. Reports contain 39 scientific pages and 3,459
complete artificial audit pages; complete table counts and covariance dimensions
reconcile independently. The 499 audit pages containing supplemental terms were
rendered and checked for page-bound overflow (none). Detailed visual inspection
covered S1 at native width/grayscale, all new scientific section pages 35–39,
paired audit tables and both complete model blocks/contrast pages; the exact
scope is in the public supplement review receipt. No claim of manual inspection
of every unrelated audit page or investigator approval is made.

The two-page public feasibility report and JPG/PDF/SVG/PNG unavailable S1 exports
were inspected and hashed. Old snapshot bytes and primary numerical outputs are
unchanged. No raw or patient-level product is staged. The supplied clinical
input remains schema 4; aggregate software identity is v3/schema 8.

## 2026-10-20 — Same-day arterial co-occurrence implementation

Owner authorized the recorded-day replacement, code release and conditional
clinical execution. Branch: `codex/same-day-abg-cooccurrence`; baseline `199071c`.
Failure scenarios/source fixtures were written first; the preimplementation test
failed with the expected missing replacement module. Six raw-record boundary
cases then passed. The full artificial baseline is saved privately under
`artifacts/triangulation/same-day-abg-development/baseline.rds`.

Replaced the inactive pairing runtime with a hash-bound recorded-day enrichment,
two common-reference spline positions, reconciliation and updated scientific/audit
presentation. No primary estimand changes or new PIFs. Source records are not
samples; differing values on a day remain valid co-occurrence. Active schema 9 /
analysis v4 rejects historical bundles rather than relabeling them.

Verification, release, source qualification and clinical review are in progress;
no clinical completion or investigator approval is asserted by these edits.

Pre-release review: all 33 separate source-boundary checks pass in the existing
Mini Python/R environment (`source-tests-20261020T165910-14582`). Pre-change
artificial primary registry values (excluding runtime), coefficients, covariance,
curves, PIFs and contributions agree within 1e-10. Review tightened the private
policy binding to include exact codes and all threshold values; the final source
suite was repeated after that change. No historical snapshot files changed.

The new S1 export is 190 mm wide, grayscale, 300 dpi with a 9-point minimum text
height; native export inspection and all 39 artificial scientific PDF pages were
completed. S1 is pixel-identical between the inspected preview and full render.
Both HTML outputs have complete local figure assets and alt text. Browser visual
inspection was unavailable because IAB could not attach to the local page; it is
not claimed. Complete-audit rendering and automated E2E are recorded separately.
Receipts are in ignored `artifacts/triangulation/same-day-abg-development/`.

All artificial E2E checks passed (`e2e-20261020T164859-4567`), including independent
supplemental model/interval oracles, missing/constant states, aggregate-only full
HTML/PDF rendering, complete-table accounting, printed numbers, privacy and
source/bundle/schema corruption. A subsequent text-only methods correction calls
the legacy calendar-day field recorded-result date, matching the export
dictionary; the numerical policy and stored policy identifier are unchanged.
The changed scientific report is rendered and checked separately.

The final methods-label HTML/PDF rerender succeeded after a missing
`BMI_REPO_ROOT` environment value was corrected (both attempts retained). Only
scientific PDF page 2 changed; it was reinspected. The complete 3,489-page
artificial audit passed automated bounds/glyph/collision checks; its S1 and new
evidence-table pages were inspected manually. This is scoped visual review, not
a manual-review claim for every audit page. All source tests and E2E checks pass.

## 2026-10-20 — Qualified recorded-day clinical supplement

PR #19 squash-merged at `b89d485`. Created an isolated, clean merged Mini checkout
under the task's fresh private release directory; preserved the unrelated dirty
research checkout and inspected active work before writes. Reused the existing
R/Python libraries and pinned upstream readers. The first enrichment attempt
stopped because R disallows spaces in TMPDIR; retained that attempt, used a fresh
no-space private temporary directory, and completed `enriched-02` without changing
original inputs or accepted products.

Source qualification passed: accepted database/input/manifest identities, reviewed
recorded-date/code/unit/threshold policies, unchanged source, exact original-field
and fixed-index equality, and query count agreement with the prior source audit.
Among 223,514 original indexes, 22,217 had a co-observed date; the primary complete
population contains 22,195. All queried ordinary arterial PCO₂ and arterial pH
records had parseable recorded dates and reviewed units. Source-row counts remain
541,828 candidate records, including 192,909 ordinary arterial PCO₂ and 145,993
arterial pH records; these are not patient or sample counts. No same-sample
identifiers were recovered. Source acceptance is an automated evidence review
under the owner-approved definition, not invented human scientific approval.

`make preflight` saved `curve-preflight-20261020T173259-15090` with zero models
fitted. One `make analyze` from clean merged `b89d485` saved
`curve-analyze-20261020T174425-15236`; analysis elapsed time was 606.152 seconds,
excluding input loading. All 28 estimable registered models succeeded, including
exactly two new supplemental models. The retained constant observation position
remains explicit. Both supplemental models have N=22,195 and the identical
primary basis/reference; events are 11,669 and 8,809. No supplemental PIF exists.
The supported saved grid has no fitted endpoint-curve crossings.

The four-stage audit is 29,639/15,541 patients/events → 22,195/11,690 →
22,195/11,669 → 22,195/8,809. An independent saved-bundle comparison verified
all original model sample/registry values (except runtime), coefficients,
covariance, curves, common fixed-contrast fields, PIF totals and signed
contributions/covariance within 1e-10. The aggregate review command passed all
134 checks. Source and review receipts are retained in ignored task storage;
only sanitized aggregate evidence is included in the separate reading snapshot.

The new S1 clinical preview was inspected at 190 mm in grayscale, with no bounds,
symbol or collision issues and approximately 9-point minimum text height.
PNG/JPG are 300 dpi; editable R and SVG/PDF masters are retained. The original
October 18 and pairing-feasibility snapshot manifests still verify byte for byte.
Regenerated F1-B PNG/JPG/SVG match the selected artifact. Regenerated F2 differs
only in its top title/subtitle (the already configured policy wording); every
pixel below that header is identical. The approved standalone B/F2 are preserved.
Full aggregate-only report rendering and assembled-page review continue below.

Final rendering completed in review `20261020T174538-23445`: 38 scientific pages,
3,080 complete audit pages, 1,282 figure exports and no clinical input reads or
model refits. All 92 independent full-table/covariance coverage checks passed in
HTML and PDF. HTML has complete image assets/alt text (10 scientific; 1,276 audit).
Browser visual inspection was blocked by the local-file URL policy; no workaround
was attempted or browser inspection claimed. PDF/native inspection is recorded
separately from HTML structure checks.

Automated page bounds, replacement-glyph and collision checks found no issues
across both complete PDFs and the captioned S1 page. Manual review covered all
38 scientific pages, enlarged supplemental pages 35–37, audit page 63, pages
137–143 and both complete supplemental model blocks 2993–3014. The separate
captioned S1 PDF had a missing subscript glyph in its first draft; it was repaired
and reinspected. Final S1 PNG matches the inspected preview byte for byte.
The public QC manifest records real dimensions, source, uncertainty and review
scope. No claim of manual review of every audit page or investigator approval.

The separate `results/2026-10-20-same-day-abg/` reading snapshot contains integrated
scientific HTML/PDF, complete audit PDF, captioned S1, vector/raster exports,
gallery, 54 aggregate CSV tables, saved configuration and sanitized review
receipts. Full audit HTML and execution bundles stay in ignored run storage.
The original reading snapshots remain immutable. New investigator interpretation
and S1 approval remain pending; no abstract was drafted. Documentation/results
release is separate from the estimation-source commit.
