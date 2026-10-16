# Home-network handoff: qualify and run on the Mini

Updated 2026-10-15. Home-network access resumed using the Mini's saved `reblocke` account (`ssh -4 reblocke@Brians-Mac-mini.local`). The merged release was copied through a Git bundle because the Mini lacks working GitHub credentials. Private accepted-product checks have started; no clinical model has run. The original local `full_db.rds` remains a historical comparator. See the dated continuation in [the source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md).

**Current stop:** the bounded source check demonstrated candidate keys without approved legacy-field mappings. Follow [the source-gap handoff](COMMON_INDEX_SOURCE_GAP_HANDOFF.md) before attempting clinical preparation/estimation. No clinical manifest was accepted. This is not a request for a replacement raw export or a change in the agreed population.

Workflow release: [PR #5](https://github.com/reblocke/obes-pop-attrib-fract-hypercap/pull/5). Use its merged revision when synchronizing the Mini; exact local publication receipts remain in ignored evidence storage.

## 1. Open the clean merged checkout

From the Mini's existing repository, inspect `git status --short`. Preserve unrelated work; do not reset it. With a clean checkout:

```bash
git switch main
git pull --ff-only
git rev-parse HEAD
make triangulation-test
```

Use the merged release linked from this repository's PR history. Clinical execution requires a clean checkout and records its actual commit/tree plus analysis-source hashes. Private configuration and results belong in ignored or existing owner-only storage. No packages are installed automatically.

Check the actual R executable and libraries first. On this continuation, the Homebrew default lacked primary dependencies. The separately installed framework R supplied `jsonlite`, `digest` and `lpSolve`, but still lacked `haven`, `ggplot2`, `knitr` and `rmarkdown`. Dependency installation was requested separately; do not treat that request as approval. Select an installed compatible runtime or obtain authorization for an isolated library before estimation/rendering.

## 2. Bind existing products, without rebuilding them

Copy `config/common_index_preparation.example.json` to ignored `config/common_index_preparation.local.json`. Fill the paths and trusted identities from the existing private release records. Expected digests must come from the trusted record, not be obtained from a neighboring file and declared accepted. Keep the reviewed upstream revision and four reader hashes unchanged. Use the existing Python environment exposing those readers, DuckDB, pandas and PyArrow; Rscript must expose the documented R dependencies.

Use absolute source, receipt and spill paths in the preparation configuration. The output and Make command paths may be relative to the repository root. This keeps evidence references valid in the generated manifest's new directory.

Review every nonblank specimen label. Map generic blood labels to `unspecified`, established arterial/venous labels to `abg`/`vbg`, and established other specimens to `other`. Unreviewed labels stop preparation; an unspecified-blood code plus a generic blood label cannot establish an arterial specimen.

Required bindings are the accepted FULL_DATA bundle/receipt/validation report, canonical source database/sidecar/catalog, private spill location, source evidence references, original-key and nine legacy-field mappings, exhaustive source/legacy encounter-setting vocabulary, specimen vocabulary, diagnosis code systems and captured-extract completeness. The example uses explicit `accepted_stata_full_data_v1` decoding: dictionary-defined Stata days since 1960, coded settings/demographics and the inherited ordered race/ethnicity rule from separate `race`/`ethnicity`. Its `race_ethnicity` mapping names the derived output, not an existing FULL_DATA column. BMI and age are copied unchanged. Unexpected codes and missing raw race/ethnicity stop for review; no default category is imputed. Previously typed inputs retain `typed_v1` (also the compatibility default when that key is absent). The encoding is bound in configuration/field evidence and the preparation receipt. Review these mappings against the accepted dictionary; do not choose an encoding from value magnitudes.

A global pressure-unit default is allowed only when authenticated source metadata establishes it; otherwise leave it null. Select calendar-day `qualified` only when that source evidence is available; `pending` remains supported.

Use the existing source products in place. Canonical database hashing is potentially long; the recorded earlier full-database pass took about 15 minutes. The command uses one upstream source session, bounded upstream memory and the supplied private spill location. Verify free scratch capacity on that volume first: internal-disk spill exhausted its configured capacity during qualification. It does not copy the canonical database or rerun preprocessing. Preserve failed attempts; an execution resource failure is not a failed population-coverage test.

The bounded projection streams 16 disjoint patient-hash partitions, retaining every raw encounter row for each key before consensus and study selection. It retains only the agreed study scope after consensus and checks mapped-key coverage in SQL before Python materialization, rather than accumulating all historical candidate fields. It reconciles raw row totals and the bound on covered keys, keeping the 2,816-MiB RAM cap and at most 64 GiB of scratch. It prints completed projection partitions; that is substage progress, not overall preparation completion. A partition failure count is not a full-population total. Select private output storage with enough space for the new typed input too; the Mini's internal disk was nearly full.

The observed raw vocabulary includes `UNKNOWN`. Its explicit `NA` mapping retains uncertain eligibility and becomes a true missing setting in the typed input. Review every other source setting code; do not treat a named unknown as a confirmed nonacute encounter.

```bash
make triangulation-prepare \
  PREP_PYTHON="/existing/upstream-environment/bin/python" \
  SOURCE_CONFIG="config/common_index_preparation.local.json" \
  OUTPUT="artifacts/triangulation/source-qualification-YYYYMMDD-unique"
```

Replace the Python path and choose a fresh output directory. The owner-only output contains restricted `study-input.csv`/`study-input.rds`, `field-evidence.json`, `population-evidence.json`, `preparation_receipt.json` and **`triangulation_input.pending.json`**. A failure retains a separate receipt; it is not a qualified input. The original RDS and accepted upstream products are preserved.

The preparation uses raw exact-code transport, not syndrome-positive catalog filters. It includes potential adult 2022 acute-care candidates and unresolved dates/types before BMI, gas or model-completeness filtering. Every candidate must have a legacy mapping; otherwise it stops with an aggregate missing-key count. It preserves incomplete values and exact repeated base rows for downstream accounting. It rejects incompatible original keys, chronology/settings contradictions, unmapped settings, incomplete evidence queries, duplicate source records and unreviewed diagnosis systems. Do not resolve a failure by discarding candidates or relabeling numeric keys.

## 3. Review one source-qualification ledger

Use [the source assessment](TRIANGULATION_SOURCE_ASSESSMENT.md) and [input handoff](TRIANGULATION_INPUT_HANDOFF.md). For each of lineage, population scope, keys/chronology, BMI/adjustment, testing evidence, gas units/windows and ICD capture, record the actual check, evidence identity, result and reviewer. Distinguish automated checks from human review; neither a pending template nor an engineering receipt alone establishes this study's acceptance.

The field evidence must bind `unadjusted_pco2_v1` exactly: ordinary specimen-authenticated PCO₂; strict 5–200 arterial and 10–250 venous validity intervals; reviewed explicit unit conversion; five-code captured absence only with complete available diagnosis capture. Adjusted/unspecified/unusable records are audited. No captured gas evidence is not proof of no clinical testing. Record audits count source records, not necessarily independent specimens.

After the seven primary checks pass, make a separately named reviewed manifest from the pending copy. Preserve the pending original, fill actual review identity/date and evidence reference, set only verified gates to accepted, and retain hashes of the finalized evidence files. If evidence files change during review, update their hashes. Calendar-day evidence can stay pending. Source-level unsupported requirements remain explicit; request upstream work only for a demonstrated gap.

```bash
make triangulation-preflight \
  INPUT="artifacts/triangulation/source-qualification-YYYYMMDD-unique/study-input.rds" \
  MANIFEST="artifacts/triangulation/source-qualification-YYYYMMDD-unique/triangulation_input.reviewed.json"
```

Passing preflight verifies reviewed declarations, exact input/policy and evidence hashes. It does not independently repeat raw-source reconciliation. Keep the readiness determination separate from permitted output release and the later scientific review.

## 4. Estimate once and review aggregates

```bash
make triangulation-render \
  INPUT="artifacts/triangulation/source-qualification-YYYYMMDD-unique/study-input.rds" \
  MANIFEST="artifacts/triangulation/source-qualification-YYYYMMDD-unique/triangulation_input.reviewed.json"
```

Retain the exact fresh `clinical-*` directory printed by the launcher. Check `analysis_completed` and then `render_completed`; reconcile population/index/completeness, common-reference/model/event counts, observed evidence, paired coding comparisons and pending sensitivities. Review model failures, missingness, unseen categories and shifted BMI support without changing the estimator to obtain a result.

```bash
make render RUN="artifacts/triangulation/<exact-clinical-run>"
```

Presentation revisions read only that saved bundle. A render failure does not require refitting. A source or estimation correction requires a new immutable analysis run. Apply figure QC to A/B/C and every report page; retain numerical read-back and native-size/grayscale receipts. A remains preferred unless actual clinical display supports another choice.

Bind a separate closeout receipt to the input, manifest, merged code, aggregate bundle and reviewed exports. Record source acceptance, analysis completion, numerical review and scientific review separately. Clinical result qualification remains false until the required review is actually recorded; it does not turn true when rendering succeeds. Publish only a safe status/documentation follow-up through a PR; keep clinical artifacts private. Abstract/coauthor review remains separate.
