# Public-release review — 24 October 2026

The owner authorized publication after final audit, review and a squash-merged
release PR. This review refreshes the October 23 preparation against `main`
`10cc285` (schema 12/v7) and the release-documentation changes. GitHub records
live repository visibility. Scientific authority remains in the
[analysis guide](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md),
[source contract](SOURCE_CONTRACT.md) and [decision log](DECISIONS.md).

## Publication boundary

- Code, existing reports, figures, complete aggregate tables and historical
  material are included under the owner's public-disclosure authorization,
  including the existing small counts. This is the owner's confirmation under
  the source-data agreement, not an independent legal assessment.
- `reports/ATS Abstract 2027/` is private, local-only and ignored. Its current
  files and paths are absent from all fetched GitHub branch and PR histories.
  Private local Codex recovery refs are outside those publication refs; only
  the reviewed release branch is pushed. No mirror push is used.
- Raw/patient-level data and source-access secrets remain excluded. The review
  found no tracked raw database/model/input files. The existing aggregate-table
  header checks also passed. Bounded scanning is not independent authentication
  of every historical datum or all possible secret formats.
- Publication does not change the provisional primary scientific approval,
  selected B/F2 figures, or pending investigator interpretation/approval of S1
  and the ICD supplement. No submission approval is asserted.

## Disclosure audit and retained history

The final scan covered 32 fetched publication refs (remote branches and PR heads),
66 reachable commits, 798 text blobs, 31 unique PDF versions and metadata from
20 raster images. It checked PDF metadata, annotations, attachments and complete
native text. All 31 PDFs completed whole-document Poppler extraction without
recorded coverage gaps or parser errors. The earlier pinned `pdf-inspector`
backend remained unavailable; no backend was installed. This was a disclosure
scan, not new scientific or visual approval, and embedded images were not OCRed.

The known findings are retained under the owner's October 24 instruction that
historical material may be published: absolute local source paths in legacy HTML,
five current legacy PDFs and older source/work-log/PDF versions; and Finder
metadata in historical objects. Neither Finder file remains tracked on current
`main`. No accepted report, result snapshot or Git history is rewritten.

No matches were found for the configured private-key, GitHub-token or AWS-key
patterns. No PDF attachments or raster GPS findings were recorded. The separate
GitHub discussion scan covered 26 PR/issue bodies, one issue comment and no inline
review comments; no configured credential, draft-document or uploaded-attachment
indicators were found. No release assets were present. GitHub advertises wiki
capability, but the wiki Git endpoint returned not found; wiki content was not
verified. These are bounded findings, not universal disclosure clearance.

## Reproducibility and verification

| Check | Evidence |
|---|---|
| Schema-12 artificial analysis/report E2E | Existing receipt `e2e-20261024T044257-81340` passed all 13 groups; current estimation/test source hashes match; all 6,053 indexed artifact hashes verified |
| Fresh source boundaries | `source-tests-20261024T071956-55803`: all 35 passed, no unavailable/error/failure checks; isolated current-source copy on the Mini |
| Source/runtime integrity | All 54 copied source/configuration files unchanged during execution; existing Python 3.12.11, DuckDB 1.5.4, pandas 2.2.3 and activated R 4.6.1; no installation |
| Saved clinical snapshots | All six manifests / 441 file hashes verified; no saved result changed |
| Aggregate boundary | All 289 result-table headers checked for the existing prohibited individual-level fields |
| Documentation and release diff | Relative links, JSON and staged/unstaged diff checks are recorded in the work log and retained verification receipt |

The earlier schema-10 E2E and schema-11 source checks remain historical evidence.
The later schema-12 E2E, native-axis checks and clinical report inspection have
separate scopes documented in the work log and snapshot receipts. This release
changes documentation and an ignore rule, so full estimation/report rendering was
not repeated. Fresh source checks used artificial fixtures and did not read
clinical inputs, qualify a new source product or fit clinical models.

Source preparation still requires the exact installed upstream readers pinned
in [the mapping example](../config/common_index_mapping.example.json) and the
qualified evidence-bound private inputs described in the source contract.
Reading snapshots are not executable analysis bundles.

## Remaining maintenance decisions

- A project license and `CITATION.cff` remain absent. Code/output reuse terms,
  preferred authorship/citation and third-party attribution remain owner decisions;
  no terms, authors or identifiers are invented by publication.
- Synthetic CI and branch protection remain recommended. No GitHub Actions
  workflow or branch-protection rule is added by this release; local verified
  receipts must not be represented as hosted CI or investigator approval.
- A versioned/tagged scientific release remains separate from making the GitHub
  repository public. Preserve dated snapshots and their distinct review states.

Detailed final-audit evidence, runtime identities and source hashes are retained
under ignored `artifacts/triangulation/final-public-release-20261024/`. Earlier
preparation and source-resolution evidence remains in its original ignored
folders. See [WORKLOG.md](../WORKLOG.md) for commands, results and limitations.
