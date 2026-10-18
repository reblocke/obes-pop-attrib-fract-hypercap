# Retired source index

Only the [immutable original Stata program](stata/36_subpop_hazard.source.do)
remains as a physical source archive. Its SHA-256 is
`6e25200c421be03c7f05e6a93898cd7a7816eff015b0095bf4f5668606cf7482`;
origin: `reblocke/trinetx-hypercapnia-code`, commit
`d5d269168eafc7905c9238a5486fc03a62b55ec3`, path
`stata/do/36_subpop_hazard.do`. It is historical evidence, not an active entrypoint.

Duplicated source snapshots, legacy runners/reports and superseded planning/test
machinery were removed from the working tree. Every removed archived/document
file was compared with Git before removal. The CRLF working copy and two tests
with pre-existing uncommitted edits are explicitly distinguished. The machine-readable
[recovery index](retired_sources.csv) records exact commit, path and Git-blob SHA-256, plus working-copy hash/encoding.
To inspect a retired file without restoring an obsolete workflow:

```bash
git show '<git_commit>:<path>'
# Both values come from retired_sources.csv; sha256 verifies committed bytes.
```

| Historical design | Source reference |
|---|---|
| BMI-to-40 / original R reports | `1e78e3c2ece8771a189b910b415959d3f3734647` |
| Independently indexed BMI/ABG/combined-gas frames | `d8909df` |
| Curve-first full-reference/MAR–MNAR analysis | `1626a6db8ac5d347df7f5c0444b5bcac755ea457` (clinical release `f18d383`) |
| Observed-population curve analysis | `ca24564` |
| Initial two-group RFS model hierarchy | `4fdf4eb` |
| Current descriptive-only obesity hierarchy | `043fea6`; recorded at `0e5641f9579b4c8f20d90ed22732a0ebcf0ed2d6` |

The recovery index's full commit/path identifies the exact committed bytes even
when the table above names an earlier originating design. Historical commands
and bundle replay are no longer supported by the active code. Current authority
is the [scientific/interface guide](../docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md).

For rows marked `pre_refactor_patch`, `git show` alone does not recover the
uncommitted working copy. Exact copies of `tests/check_rfs_render.R` and
`tests/run_rfs_tests.R` are preserved privately under
`artifacts/triangulation/repository-refactor-20261017T210721/pre-refactor-worktree/`.
They were reconstructed from the baseline commit plus `pre-refactor.patch` in
that same cleanup directory and checked against the index's `worktree_sha256`.
The CRLF row requires LF-to-CRLF conversion to reproduce its working-copy hash.

No raw input, accepted product, clinical bundle, generated report or Git history
was removed. Existing `Code/`/`Documents/` rendered historical artifacts and ignored
private results retain their original labels. Uncommitted documentation preceding
this cleanup was snapshotted under the ignored cleanup receipt directory before
editing. Historical result identities do not transfer to the current specification.
