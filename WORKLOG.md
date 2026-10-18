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
