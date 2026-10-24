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
# 2026-10-20 — Joint same-day components: pre-edit plan

Owner approved a joint three-category spline supplement and full-range stacked S1.
Any eligible hypercapnia/acidemia day takes priority; the other hypercapnia category
requires no documented same-day co-occurrence. Preserve fixed indexes, primary
models/PIFs and historical snapshots. Reuse the accepted enrichment; no extraction.

Implementation: replace only supplemental estimation with an unpenalized
multinomial model and full joint-covariance standardization; update aggregate
schema/registry, reports and stacked/component/frequency figure. Record failure
scenarios and independent E2E oracles first. Verify with `make test`,
`make source-test`, source/hash guards, primary-value reconciliation and actual
native/PDF inspection. Release through review/PR/squash merge before one clinical
run on a clean Mini checkout. Scientific/figure approval remains separate.

Joint-model development: independent softmax/BFGS likelihood, numerical gradients
and Hessian checks agree with production coefficients, covariance, standardized
probabilities and signed component-change intervals. Original primary coefficients,
covariance, curves and PIF/contribution tables remain equal at 1e-10 (new all-NA
class metadata is normalized only for this comparison). The original 1,200-patient
artificial fixture correctly triggered multinomial separation; the public fixture
now uses 6,000 artificial patients and both hypercapnic classes for a successful
joint path, while absent-class/rank failure cases remain explicit.

Mini `nnet` 7.3-20 is already installed. Source checks from the unchanged adapter
files passed all 33 checks, no skips: source-tests-20261020T220705-18737. Earlier
source-tests-20261020T220559-18694 retained a failed R roundtrip because the initial
SSH shell lacked Rscript on PATH; rerun used the existing activation and safe TMPDIR.
Native artificial stacked preview inspected; label/axis alignment corrections made.
Full E2E report rendering and clinical execution are not yet claimed complete.

Initial analysis/report E2E passed at e2e-20261020T220558-99054. Manual PDF
inspection nevertheless found S1's long caption clipped at the page boundary;
the generic geometry check missed it. Reproduced with full-caption text matching,
then added an E2E check before repairing the layout. Shortened the caption and
reduced the native figure to 190 x 210 mm; color/grayscale preview inspected.
Extended the top-level render tripwire to include the joint fitter. These are
render-only changes; reuse the same saved artificial aggregates for verification.

Final saved-aggregate E2E passed: e2e-20261020T222425-5234, including complete
S1 caption recovery in both PDFs, all table/figure coverage, independent numerical
checks, privacy boundaries, old-schema/corruption rejection and stable hashes.
The full audit HTML completed after memory pressure on the 8-GB review Mac; no
checks were skipped and no estimation was repeated for the layout repair.
The repaired scientific S1 page was visually inspected with its entire caption.
Source review found no additional actionable defects. PR #21 is ready for merge;
clinical execution remains pending that merge and the clean Mini preflight.


PR #21 squash-merged at `21b8bdf`. Local main and the clean dedicated Mini
checkout were synchronized through a verified incremental Git bundle. No competing
R/source jobs were present. Fresh preflight `curve-preflight-20261020T225510-19821`
passed; one clinical run completed as `curve-analyze-20261020T230537-20006`.
The exact accepted input and manifest hashes match the earlier binary run.
The joint model succeeded on N=22,195: no hypercapnia 10,526, hypercapnia without
documented same-day acidemia 2,860, and with co-occurrence 8,809. Optimizer code 0;
maximum scaled score per patient 3.42e-9; information condition number 3,821.
All eight primary comparison tables passed at tolerance 1e-10, with unchanged
model samples, coefficients, covariance, curves, fixed contrasts and PIF/decomposition.
One pre-existing constant diagnosis-capture position remains explicit.

Clinical aggregate-only rendering is running. Native clinical S1 preview inspected;
full-range stacked and common-baseline curves retain intervals and sparse tails.
The new reading packet will be separate from every historical snapshot. No abstract
has been drafted and investigator interpretation/S1 approval is not asserted.

### Joint-component clinical reading packet and review

- Saved-aggregate render `20261020T230613-20218` completed: scientific report
  41 pages; complete audit 3,546 pages. No clinical reread or refit.
- All 98 full-table coverage checks passed. Automated geometry checked every PDF
  page with no clipping/collision/replacement-symbol flags; the complete saved S1
  caption was recovered from both PDFs. An early coverage check during PDF
  generation failed on incomplete output, then passed after rendering completed.
- Visually inspected all scientific pages in contact sheets, enlarged S1/count
  tables, native color/grayscale S1 and the standalone captioned PDF. Targeted
  audit pages include S1 and joint coefficients/covariance/diagnostics. This is
  not a claim of manual inspection of every audit page; HTML checks were structural.
- New immutable reading packet `results/2026-10-20-same-day-components/` includes
  reports, S1, 57 complete aggregate tables, gallery, manifests and separate
  source/numerical/visual receipts. Historical manifests and selected B/F2 are
  unchanged. Snapshot hashes, navigation links and aggregate-only boundaries passed.
- Investigator interpretation and S1 approval remain pending. No abstract drafted.

### 2026-10-23 — PIF visualization alternatives

- Created ignored `artifacts/triangulation/pif-figure-alternatives-20261023/` with
  five designs for arterial, combined-gas and ICD outcomes: 15 views, editable R,
  SVG/PDF masters, 300-dpi PNG/JPG, captions, exact plotted values, HTML gallery
  and a 15-page email-ready PDF booklet. Existing B/F2 and snapshots are unchanged.
- Read only manifest-verified saved aggregates from the joint-component snapshot.
  No clinical input, refit, new scenario estimation, abstract or release operation.
  E is explicitly an incomplete preview with only identity/one-unit values.
- Reconciled counts, weighted means, signed contributions and cumulative intervals
  using full cross-band covariance. Separate band probability intervals remain
  unavailable and explicitly labeled; no uncertainty was invented.
- Commands: package `render.R SNAPSHOT OUTPUT`, `verify.py FRESH_DIRECTORY`, and
  `check_exports.py REVIEW`. Final artificial pipeline passed negative, empty,
  wide/zero-crossing and unavailable states plus rejection of a corrupted CSV.
  Fixed R absolute-path space encoding and a Python checker name collision found
  during verification; no dependencies installed.
- Figure QC: 15 individual color/grayscale views, all assembled booklet pages,
  190-mm dimensions, 300-dpi raster metadata, PDF bounds/symbols/collisions and
  gallery links inspected. Full receipts under `review/qc/`; SVG supplied but
  not independently browser-rasterized; no color-vision simulation/print proof.
- Recommend A for the substantive decomposition, B for compact accumulation,
  and D for absolute magnitude. Investigator selection remains pending.
  All 80 source snapshot files verified unchanged; package remains Git-ignored.

### 2026-10-23 — Public-release documentation and disclosure review

Owner request: implement the public-release preparation plan. The owner selected
code plus existing reports, figures and aggregate tables, and explicitly confirmed
public disclosure clearance for these exact outputs, including existing small
counts. Primary provisional approval, working B/F2 and pending S1 interpretation
remain distinct from public disclosure and submission approval.

Pre-edit plan: revise README reading/execution paths; align DECISIONS, SOURCE_CONTRACT
and LLM_GUIDE; remove only tracked Finder metadata; review history/metadata; correct
GitHub's description; verify links, JSON, immutable snapshots and the existing
artificial/source E2E entry points. Silent-failure risks were overstated approval,
stale snapshot navigation, treating unavailable tests as passes, and disclosures
surviving in historical objects. No analysis-code change was planned.

- Reworked README for external researchers and added `docs/PUBLIC_RELEASE_REVIEW.md`
  with evidence, observed environment versions, disclosure-review scope and pending
  release decisions. The prior uncommitted PIF-figure work-log entry is preserved.
- Removed `.DS_Store` and `Code/.DS_Store` from the Git index; ignored local copies
  remain. No historical result or commit was rewritten.
- Updated GitHub's description to the current descriptive BMI–hypercapnia study;
  read-back confirmed the exact description and unchanged private visibility.
- Confirmed all six advertised remote heads are available locally and no remote
  tags exist. Scanned all 40 locally reachable commits, 605 text blobs, 21 unique
  PDF versions and 12 raster metadata records. PDF metadata/annotations/attachments
  and complete native text were checked for bounded private-path/credential
  indicators. Legacy HTML, five current legacy PDFs, older QMD/log versions and
  historical Finder objects need a retention decision. No supported credential
  signatures were found; this is not exhaustive privacy or secret clearance.
- The installed runtime lacks pinned `pdf-inspector`; retained its failure receipt
  and used whole-document Poppler fallback for all PDFs. No PDF parser/text-coverage
  failures remained; embedded images and semantic disclosure judgments were not
  independently cleared. No dependency was installed.
- `make source-test PREP_PYTHON=<existing bundled Python>` completed **incomplete**:
  24 passed, 9 unavailable because DuckDB is absent (runner exit 78; Make exit 2).
  Receipt: `source-tests-20261023T214628-57018/receipt.json`. Adapter/test hashes
  were stable. This is neither full source-test success nor clinical qualification.
  The isolated merged-baseline rerun returned the same 24 passed / 9 unavailable
  with stable source hashes; its complete receipt/log are copied to the public-
  release evidence directory's `isolated-source-tests/`.
- Fresh `make test` used artificial input only. E2E job:
  `e2e-20261023T214313-54782`; saved fixture:
  `curve-fixture-20261023T214456-55038`. The first attempt failed at rendering:
  concurrent ICD-acuity edits changed the shared checkout from schema 10/v5 to
  schema 11/v6 after fixture estimation. Quarto sessions correctly rejected the
  schema-10 bundle, and the renderer recorded changed source hashes. All 1,689
  exported figure PDFs and the failed receipt are retained. Preserve the concurrent
  work; resume verification in an isolated checkout of merged `53ccfc8` using the
  existing immutable artificial run and source-matched figure-reuse interface.
- All four snapshot manifests (238 files) passed size/hash verification; all
  saved result files match the pre-edit baseline. Before the concurrent edits,
  analysis/configuration/report sources also matched; later drift is recorded in
  `concurrent-source-drift.json` rather than attributed to this documentation task.
  The LLM guide's clinical/numerical/scientific sections are unchanged by this task.
  Initial post-edit link, JSON and staged/unstaged diff checks passed.

Isolated recovery and terminal verification:

- Created a clean managed verification checkout at merged `53ccfc8`, preserving
  all concurrent schema-11 edits in the shared checkout. No study source was
  reverted and no historical bundle/schema label was changed.
- `make render-reports RUN=<fresh saved artificial run> FIGURES_FROM=<initial review>`
  completed review `20261023T220020-59588`. All four scientific/audit HTML/PDFs
  completed; PDFs have 40 and 3,910 pages. Source and bundle hashes were stable,
  clinical input reads/model refits were zero, and existing figure exports were
  reused through the supported source/hash guards.
- `Rscript --vanilla tests/run_e2e.R <fresh saved artificial run>` then **passed**
  all 11 E2E check groups at `e2e-20261023T221236-61628`: independent numerical
  reconciliation, adverse cases, aggregate privacy, complete tables/figures,
  captions/intervals and public stale/corrupt-input/figure rejection. These are
  artificial software checks, not current schema-11 or clinical qualification.
- Copied all 76 E2E evidence files to `isolated-e2e/` and verified every copied
  file's hash. Original receipts/logs remain byte-identical; the saved artificial
  run and full report review remain in the shared ignored artifact directory.
  `isolated-checkout.json` binds the clean checkout to the exact merged commit.
- Final documentation verification passed: 335 local Markdown link targets, valid
  LLM-guide JSON, scoped/staged diff checks and all four clinical manifests / 238
  size/hash identities. The prior PIF work-log entry remains byte-preserved, and
  both Finder files are untracked while local copies remain. Concurrent ICD-acuity
  source/documentation additions were retained; the README qualifies the tested
  merged release and retains the new supplement's pending clinical state.
- Archived the clean temporary verification worktree after preserving needed
  ignored evidence. Final GitHub read-back confirms the corrected description,
  private visibility, no release and no project license metadata. GitHub issue/PR
  discussions, wiki and external attachments were outside the Git-object scan.

Local commands, baseline hashes, scan script/receipts, runtime identities and logs
are retained under ignored `artifacts/triangulation/public-release-20261023-0yy69ejb/`.
Licensing/preferred authorship/citation, historical-path retention, complete source
checks, recommended synthetic CI/branch protection and the final dated public
release remain open. No clinical refit, upstream rebuild, raw-data access,
installation, commit/push/merge, visibility change, abstract or submission occurred.

## 2026-10-23 — ICD acuity supplement implementation

- Added the owner-approved five-category coding decomposition, including OHS in
  chronic coding and explicit/concurrent acute-chronic precedence. Preserved
  individual flags, unknown capture and original-key enrichment invariance.
- Recorded failure scenarios before code in `docs/ICD_ACUITY_SUPPLEMENT.md` and
  added independent likelihood/finite-difference E2E evidence plus raw-record
  source-boundary checks. Source tests do not substitute for clinical qualification.
- Reused the existing multinomial computation for both S1 and the new ICD model;
  added S2, full contrasts, code-pattern provenance and complete audit outputs.
  New optional input extension is `icd_acuity_v1`; aggregate schema is 11/v6.
- Saved pre-change artificial output in
  `artifacts/triangulation/icd-acuity-development/before.rds`. Initial numerical
  comparison found primary/S1 curves, full covariance and PIF tables unchanged;
  restored the original S1 coefficient description after finding a text-only drift.
- Existing documentation edits and staged `.DS_Store` deletions were present on
  entry and are preserved. No clinical source opened, clinical estimation, abstract
  drafting, commit, push or merge performed in this implementation phase.
- Initial `make source-test` was incomplete due local dependency skips; repeated
  using the existing bundled Python: 26 passed (including new ICD boundaries),
  nine unavailable because DuckDB is absent. No packages installed.
- Full `make test`, final visual QC and review receipts are recorded below when
  complete. Clinical enrichment/source qualification and S2 investigator approval
  remain pending; published clinical snapshots are unchanged.

- Final analysis/report E2E passed all 12 groups at
  `artifacts/triangulation/e2e-20261023T222313-62975/receipt.json`, resuming the
  verified artificial saved run `curve-fixture-20261023T220637-60929`. The initial
  launcher run exposed an artificial-only source-status gate mismatch; corrected
  it and repeated the independent checks. A superseded render was stopped after
  identifying PDF sparse-overlay seams; the fresh final render incorporates the fix.
- Final HTML/PDF reports and S2 SVG/PDF/300-dpi PNG/JPG exports are in that E2E
  directory's `aggregate-only/reviews/20261023T222815-63310/`. Rendering read no
  clinical input and performed no model refits. All source/hash identities stayed
  stable; corrupt/stale bundles and unrelated figures were rejected.
- Figure QC receipt: `artifacts/triangulation/icd-acuity-development/figure-qc-final.json`.
  Inspected native color/grayscale, vector export, scientific PDF pages 39–45 and
  audit pages 63, 137, 141, 4740, 4741, 4743 and 4785. This is targeted inspection,
  not visual review of every audit page; automated complete-table coverage passed.
  Dense audit tables retain full coefficients/covariance and wrapped strings.
- Pre-change invariance passed for coefficients, full covariance, probability
  curves and PIF total/contribution/covariance tables. Historical snapshot hash
  verification passed for all 68 original-reading and 80 joint-component files.
- Source boundaries: 26 passed, nine unavailable without existing DuckDB runtime;
  both new ICD source checks passed. Full source qualification remains pending.
  No clinical results, investigator approval or release operations are claimed.

## 2026-10-24 — Complete current-source boundary verification

- Resolved the nine DuckDB-related unavailable checks without changing analysis,
  adapter or test code. Read the current scientific/source contracts; inspected
  Mini jobs/worktrees before creating a separate owner-only source directory.
  Existing dirty historical checkouts and accepted source products were preserved.
- Froze 51 current working-tree files from R, scripts, tests and configuration,
  plus Makefile/Git ignore rules, including untracked ICD-acuity additions.
  Base commit: `53ccfc87affe405fa48ec827e6b69fc18a31836a` with working changes;
  this was not a test of the base commit alone. Retained file hashes, Git status,
  tracked-source patch and the complete source archive (including untracked files).
- Used existing Mini Python 3.12.11, DuckDB 1.5.4 and pandas 2.2.3. The default R
  resolved to a different installation; the documented activation selected the
  existing framework R 4.6.1 with haven 2.5.5, jsonlite 2.0.0 and digest 0.6.39.
  Selected the same Python for `PREP_PYTHON` and subprocess `PATH`; used a fresh
  writable `/tmp` directory without spaces. No dependencies installed.
- `make source-test PREP_PYTHON=<verified existing Mini interpreter>` exited zero:
  **35 passed, zero unavailable, zero failures, zero errors**, including all nine
  previously unavailable checks and both ICD-acuity boundaries. Receipt:
  `source-tests-20261024T015937-52794/receipt.json`. Python runner hashes and all
  51 copied files matched before/after execution; local source matched at transfer
  verification. Later edits in this task only document that result.
- Evidence retained locally in
  `artifacts/triangulation/source-resolution-20261024/`: `snapshot.json`,
  `working-tree.patch`, `source.tar.gz`, `runtime.json`, `verification.json`,
  `make-source-test.log`, runner receipt/log and `remote-sha256.txt`.
  Six transferred evidence files were independently byte-verified against Mini
  SHA-256 values. The separate Mini source copy/evidence is retained for replay.
- Updated test runtime guidance and the public-release checklist. No clinical
  input read, clinical qualification, estimation, upstream rebuild, commit, push
  or publication performed. Full analysis/report E2E was not rerun for these
  documentation-only changes; the separately recorded schema-11 E2E remains
  distinct from this source-boundary result and from investigator approval.
- Final checks passed: all four saved-result manifests / 238 file hashes,
  335 local Markdown link targets, relevant JSON parsing, and staged/unstaged
  `git diff --check`. The first ad hoc manifest verifier assumed uniform entry
  structure; corrected it to support the existing paired-ABG digest-only manifest
  and reran successfully without editing any manifest. Evidence:
  `artifacts/triangulation/source-resolution-20261024/final-verification.json`.

## 2026-10-24 — ICD release and clinical execution

- README source-check task completed before this work. Reused its 35/35 passing
  Mini receipt; all executable/configuration sources match. Only tests/README.md
  changed afterward to document the runtime. The 12-group schema-11 E2E receipt
  also matches all estimation/test sources. No duplicate source run was needed.
- Reviewed staged, unstaged and untracked changes, including source joins, code
  precedence, multinomial covariance, reports, privacy boundaries and docs. No
  additional actionable code issue found. Corrected stale source-check/version
  descriptions. Review evidence: artifacts/triangulation/icd-acuity-release-20261024/.
- Existing source/code-level ICD data are being reused; transport verification is
  separate from requalifying unchanged clinical definitions. No upstream rebuild
  or replacement export is planned. Clinical run and investigator review are pending.

- PR #23 squash-merged the reviewed implementation at
  `c0970484db8708845c023712d8e5204aad368d91`. Local main and a fresh clean Mini
  checkout matched that revision before execution. Existing dirty historical
  checkouts and prior runs were preserved; no competing analysis job was active.
- Reused the accepted canonical source, pinned readers and complete diagnosis
  capture policy. A fresh `enrich-icd-acuity` product preserved all 223,514 original
  input rows, fields and fixed indexes. All 18,030 target source diagnosis records
  reconciled; the five-code union exactly reproduced the existing composite.
  This exposed no upstream change or new ICD reliability discrepancy.
- The first enrichment attempt stopped before input loading because R rejected a
  temporary directory containing a space. Preserved that attempt; used a fresh
  output and the existing external-volume temporary directory without spaces.
  The second enrichment passed without source, estimator or dependency changes.
- Fresh schema-11 preflight passed. The primary complete-capture population is
  176,922; its 8,634 positive diagnoses partition into chronic/OHS 1,769,
  acute-on-chronic/concurrent 3,443, acute 3,294 and unspecified 128. The unchanged
  recorded-day reference contains 22,195 patients. These are cohort counts,
  not evidence of a modeled BMI association.
- The clinical run completed once; all 133 saved-result numerical checks passed.
  The new ICD position is nonestimable (`separation`), with a full-rank 60-parameter
  planned design. A protected, non-estimation diagnostic confirms no unspecified
  diagnoses in inherited race/ethnicity strata 3/4/5 (Asian N=995, American
  Indian/Alaska Native N=1,475, Native Hawaiian/Pacific Islander N=339). No category
  pooling, adjustment change or penalized fallback was introduced.
- The first original-result comparison stopped only because an all-empty CSV
  `reason` field inferred logical versus character type after adding the failed
  ICD position. Preserved that receipt; normalized only empty explanatory text
  in a second aggregate-only comparison. All 11 original primary/S1 tables then
  agreed within 1e-10, with no numerical columns relaxed or changed.
- Presentation failure scenario recorded before repair: a source-qualified but
  nonestimable ICD model must not receive a caption describing displayed curves
  or appear to have successful adjusted results. The existing renderer has an
  unavailable-panel path but an unconditional curve caption. Small repair scope:
  `R/rfs_reporting.R` and the scientific QMD only. Verification will render the
  saved clinical bundle with its separation state, inspect the caption/status and
  assembled reports, and recheck aggregate hashes; no clinical refit is needed.
- Mini estimation used the clean merged `c0970484` checkout and finished as
  `curve-analyze-20261024T022943-53435`. Mini report rendering could not locate
  Quarto in its runtime; that failed attempt is preserved. Transferred only the
  saved aggregate bundle, verified all 68 bundle-file hashes, and rendered locally
  from saved aggregates with zero clinical-input reads or model refits. The first
  local launch used the wrong working directory and stopped before input reads;
  its log is retained. The corrected fresh render completed.
- Final clinical review is `20261024T024233-75942`: 43-page scientific PDF and
  3,762-page complete audit PDF. All 114 HTML/PDF complete-table checks passed;
  automated text geometry found no out-of-page text, replacement symbols or
  overlapping text boxes. Agent visual review covered all scientific pages in
  contact sheets, enlarged scientific pages 41–42, audit pages 10/61/67/3695–3697,
  and native-size, grayscale, vector and captioned S2 exports. Remaining audit
  pages received automated checks, not individual visual review. No HTML browser
  visual review or investigator approval is claimed.
- Fresh artificial E2E completed successfully at
  `artifacts/triangulation/e2e-20261024T023649-75555/receipt.json`, including the
  new caption/status presentation and complete report tables. Reused the exact
  source-matched 35/35 Mini boundary receipt; no source-code changes occurred
  after those checks. All clinical numerical quantities remain from the single
  estimation run.
- Published the separately hashed aggregate reading snapshot at
  `results/2026-10-24-icd-acuity/`: scientific PDF/HTML, complete audit PDF, all 64
  aggregate CSVs, S2 masters/review exports, gallery, captions and scoped review
  receipts. S2 is explicitly nonestimable, not a publication-ready adjusted curve.
  B and S1 native PNGs reproduce prior bytes. Current F2 has later title/spacing
  changes but identical printed quantities; selected original B/F2 are untouched.
- Final verification checked all 333 files across five snapshot manifests,
  including the 238 unchanged historical files; exact aggregate copies, JSON,
  169 local Markdown links, HTML assets/alt text and source/documentation diff
  checks passed. The staged byte-bound output files retain renderer whitespace
  and CSV line endings; these generated-file warnings are recorded separately
  rather than altering authenticated export bytes.
  No raw input, individual identifiers/predictions, local source-access paths or
  credentials were added to the publication packet. Evidence and commands are in
  `artifacts/triangulation/icd-acuity-release-20261024/`.
- Remaining scientific choice: a revised model would be required to obtain
  adjusted acuity curves despite the rare-category separation. No such change,
  supplementary PIF, investigator interpretation or abstract draft was made.
