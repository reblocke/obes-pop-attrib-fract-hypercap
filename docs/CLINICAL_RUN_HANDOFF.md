# Observed-population report revision — 2026-10-16

The approved version-5 workflow retains the accepted original-list input,
pre-index companion, BMI derivation, outcome definitions, fitted models and
source qualification. Gas curves, contrasts and secondary scenarios now
standardize to their outcome-observed populations; ICD uses known diagnosis
capture. Full-C MAR/MNAR projections are historical only. IPW is deferred.

PR #9 merged as `ca24564` after 73 artificial acceptance checks, 24 adapter
checks, complete artificial renders and recorded visual review. A fresh source
preflight and clinical estimation completed from a clean matching Mini checkout.
All 103 aggregate numerical checks passed, including unchanged cohorts, models,
covariance and observed scenarios versus the historical run. Input, manifest and
all bound evidence hashes remain unchanged. Both clinical HTML/PDF reports
and all figure exports passed recorded layout QC.
No additional source export or upstream rebuild was needed. Investigator
scientific review remains a separate, unasserted state.

The earlier release below is preserved as history. Its successful exports and
recorded QC did not detect all presentation defects: this revision repairs
crossed flow connectors, compressed panels, detached captions and incomplete
symbol rendering, and requires a new visual-review receipt.

## Historical version-4 release record

## Completed release and estimation — 2026-10-16

PR #7 merged as `f18d383`, with the exact tested candidate tree. The owner
accepted the checked source/companion and authorized clinical execution.
A separate clean Mini worktree passed fresh clinical preflight and completed one
analysis; its version-4 bundle passes 48 additional aggregate numerical checks.
Twenty fits succeeded; the ICD capture-availability position is constant and
retains its explicit status/raw proportions. Both HTML/PDF reports and all 153
figure exports pass recorded QC. Investigator numerical/scientific interpretation
remains pending.

The private release packet records exact input/manifest, source/evidence hashes,
commit/tree, runtime activation and saved-run paths. For presentation changes,
use `make render RUN="<exact saved clinical run>"`; do not repeat estimation.
The clean external worktree reuses the existing isolated R library; its runtime
activation path and SSH PATH are in the private execution scripts. Existing Mini
working changes, accepted products and upstream work remain untouched.

The sections below preserve the earlier operational handoff. Statements that
clinical execution is unrun or that release is pending describe that earlier
checkpoint and are superseded by this closeout.

**Current workflow amendment — 2026-10-16 curve/audit refactor:** the original
selected encounter scope is retained. Prior passing original-list source checks
remain evidence for that scope; the earlier outside-list mapping gap is historical.
The new analysis additionally requires a hash-bound pre-index cohort-audit companion
from the existing mapped candidate covariates. The earlier selected-index input
alone cannot establish those stage distributions. New companion reconciliation and identity-bound preflight now pass on the Mini,
using the unchanged accepted input and a fresh private manifest. The independent
field comparison and current qualification-function hashes agree. Clinical model
execution remains unrun; human/scientific review is not asserted. Current commands are
`make prepare`, `make qualify`, `make preflight`, `make cohort-audit`, `make analyze`
and `make render RUN=...`; dated commands below describe superseded workflows.
The active plan and README define the current interface. Preserve existing inputs,
accepted products and human-review status.

**2026-10-16 correction:** use authenticated original FULL_DATA selected encounter membership, bound as `original_selected_encounters_v1`. Broader-history candidate qualification is superseded. Retain available current/prior/calculated BMI and the first BMI-eligible index within the original list; verify historical first flags separately. Fresh original-list mapping, preparation and all 30 independent source checks pass; identity-bound preflight passes with zero models fitted. See [the governing decision](DECISIONS.md#original-encounter-list-correction--confirmed-2026-10-16). No clinical models have run.

# Home-network handoff: qualify and run on the Mini

Updated 2026-10-16. The Mini is reachable. The separate upstream branch
`codex/broader-bmi-mapping` supplies the unchanged reviewed available-BMI mapper
at `72c91a2`; shared upstream code and canonical source remain read-only. The
consumer `codex/available-bmi-mapping` now restricts candidates to authenticated
original FULL_DATA selected ED/inpatient keys. Historical first flags reproduce,
exact membership and captured setting support pass, and fresh dependent
qualification and preflight pass. No clinical model has run.

**Current boundary:** broader-source qualification is superseded. Outside-list
UNKNOWN/LAB/history/return keys cannot enter or block the new indexes. Retain
within-list unresolved chronology/BMI and same-day ties; no later replacement.
Release and synchronize reviewed clean code before clinical estimation. The
original RDS and accepted source products remain unchanged. Keep the approved
uncapped measurement-recency rule and disclose its limitations.

The released baseline is PR #6 (`8735505`); the new mapping/consumer branches are
not a merged clinical release. Synchronize the eventual reviewed revisions and
record actual commit/tree/source hashes before fitting models. Git bundles can
be used while the Mini lacks GitHub credentials; do not copy credentials.

## 1. Open the clean merged checkout

From the Mini's existing repository, inspect `git status --short`. Preserve unrelated work; do not reset it. With a clean checkout:

```bash
git switch main
git pull --ff-only
git rev-parse HEAD
```

Use the merged release linked from this repository's PR history. Clinical execution requires a clean checkout and records its actual commit/tree plus analysis-source hashes. Private configuration and results belong in ignored or existing owner-only storage. No packages are installed automatically.

The owner authorized isolated dependency installation on 2026-10-15. The Mini's framework R 4.6.1 now loads `haven` 2.5.5, `ggplot2` 4.0.3, `knitr` 1.52 and `rmarkdown` 2.32 from `artifacts/triangulation/runtime/r-4.6-aarch64/library/`, alongside its existing `jsonlite`, `digest` and `lpSolve`. Compatible macOS binaries were used. Before/after file hashes confirm that the system libraries were unchanged; all 24 shared and 14 common-index artificial check groups passed.

On this configured Mini, activate the ignored local environment from the repository root before running the commands below:

```bash
. artifacts/triangulation/runtime/activate.sh
Rscript --vanilla -e 'cat(R.version.string, "\n"); print(.libPaths())'
make fixture
make test BMI_TEST_REVIEW="artifacts/triangulation/<fresh-fixture>/reviews/<completed-review>" \
  PREP_PYTHON="/existing/upstream/environment/bin/python"
```

The activation file selects the framework runtime and project library for this shell, including Quarto's R selection. It is a local setup artifact, not a file supplied by a fresh clone. Installation, package inventory, session information, unchanged-library evidence and the two R test logs are retained in the ignored runtime setup directory. No renv project or lockfile was created. This verifies R dependencies and artificial checks, not a full Mini report render or clinical source acceptance.

## 2. Map the authenticated original selected encounters

Use `config/common_index_mapping.example.json` for the primary route. It binds the
five reviewed upstream modules and `available_encounter_or_prior_bmi_v1`. The
historical `common_index_preparation.example.json` remains for its original
FULL_DATA route; it does not bind the corrected available-BMI/original-list policy. Follow the
[map/prepare/qualify commands](../README.md#restricted-data-execution).

On the Mini the completed mapping, source hash, trusted historical receipts,
source inventories and typed preparation live in the existing owner-only external
qualification packet. Exact paths/digests remain private. No replacement export,
source-schema change or upstream rebuild is needed. Use a fresh output directory
for every preparation or qualification attempt and retain failures.

Preparation streams whole-patient partitions through the same R first-index
selector before gas extraction. Every candidate has a mapped row; genuine absent
BMI is `missing`, while unresolved timing/capture/value conflicts remain
`unresolved`. The typed input contains only resolved indexes, with the original
cohort/exclusion/index counts bound in `selection-evidence.json`. Reload BMI from
the upstream product after selection to preserve exact float32 values.

The source mapping preserves explicit units, inherited numeric precision and
adjustment coding. Its prior measurement date is relative to each candidate;
age uses encounter-start year minus captured birth year. These are intentional
anchor differences from the historical qualifying-event product, not unexplained
Stata/Python disagreement. The source inventory contains no recorded BMI above
50.1, so the conditional high-BMI ceiling was not activated. No statistical BMI
imputation is used.

The gas/ICD preparation uses raw exact-code transport at those fixed keys. Review
specimen vocabulary and units, ordinary versus adjusted gases, invalid/censored
values, captured diagnosis completeness and fixed start-calendar-day maxima.
Unknown or incompatible evidence must not become normal measurements. A completed
canonical hash receipt is reusable only with its expected digest and unchanged
source identity. External scratch is required on this Mini.

## 3. Review one source-qualification ledger

Use [the source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [input handoff](TRIANGULATION_INPUT_HANDOFF.md). For each of lineage, population scope, keys/chronology, BMI/adjustment, testing evidence, gas units/windows and ICD capture, record the actual check, evidence identity, result and reviewer. Distinguish automated checks from human review; neither a pending template nor an engineering receipt alone establishes this study's acceptance.

The field evidence must bind `unadjusted_pco2_v1` exactly: ordinary specimen-authenticated PCO₂; strict 5–200 arterial and 10–250 venous validity intervals; reviewed explicit unit conversion; five-code captured absence only with complete available diagnosis capture. Adjusted/unspecified/unusable records are audited. No captured gas evidence is not proof of no clinical testing. Record audits count source records, not necessarily independent specimens.

After the seven primary checks pass, make a separately named reviewed manifest from the pending copy. Preserve the pending original, fill actual review identity/date and evidence reference, set only verified gates to accepted, and retain hashes of the finalized evidence files. If evidence files change during review, update their hashes. Calendar-day evidence can stay pending. Source-level unsupported requirements remain explicit; request upstream work only for a demonstrated gap.

```bash
make preflight \
  INPUT="artifacts/triangulation/source-qualification-YYYYMMDD-unique/study-input.rds" \
  MANIFEST="artifacts/triangulation/source-qualification-YYYYMMDD-unique/triangulation_input.reviewed.json"
```

Passing preflight verifies reviewed declarations, exact input/policy and evidence hashes. It does not independently repeat raw-source reconciliation. Keep the readiness determination separate from permitted output release and the later scientific review.

## 4. Estimate once and review aggregates

```bash
make analyze \
  INPUT="artifacts/triangulation/source-qualification-YYYYMMDD-unique/study-input.rds" \
  MANIFEST="artifacts/triangulation/source-qualification-YYYYMMDD-unique/triangulation_input.reviewed.json"
```

Retain the exact fresh `clinical-*` directory printed by the launcher. Check `analysis_completed` and then `render_completed`; reconcile population/index/completeness, common-reference/model/event counts, observed evidence, paired coding comparisons and pending sensitivities. Review model failures, missingness, unseen categories and shifted BMI support without changing the estimator to obtain a result.

```bash
make render RUN="artifacts/triangulation/<exact-clinical-run>"
```

Presentation revisions read only that saved bundle. A render failure does not require refitting. A source or estimation correction requires a new immutable analysis run. Apply figure QC to A/B/C and every report page; retain numerical read-back and native-size/grayscale receipts. A remains preferred unless actual clinical display supports another choice.

Bind a separate closeout receipt to the input, manifest, merged code, aggregate bundle and reviewed exports. Record source acceptance, analysis completion, numerical review and scientific review separately. Clinical result qualification remains false until the required review is actually recorded; it does not turn true when rendering succeeds. Publish only a safe status/documentation follow-up through a PR; keep clinical artifacts private. Abstract/coauthor review remains separate.
