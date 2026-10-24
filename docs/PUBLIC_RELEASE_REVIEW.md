# Public-release preparation — 23 October 2026

This is a dated review of `main` at `53ccfc87affe405fa48ec827e6b69fc18a31836a`
and the accompanying documentation changes. The repository remains private;
preparation is not a public release. Scientific authority remains in the
[analysis guide](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md),
[source contract](SOURCE_CONTRACT.md) and [decision log](DECISIONS.md).

## Confirmed scope and changes

- The owner selected code plus existing reports, figures and aggregate tables
  for public release, and confirmed disclosure clearance for these exact outputs,
  including their existing small counts. This is the owner's confirmation under
  the source-data agreement, not an independent legal assessment.
- Raw/patient-level data and source-access secrets remain excluded. Disclosure
  clearance does not change the provisional primary scientific approval, selected
  B/F2 figures, pending S1 interpretation/approval or separate submission status.
- The root README now provides public reading and synthetic-execution paths,
  identifies current versus historical snapshots and explains access/reuse limits.
  The decision log, source contract and LLM guide carry the same disclosure state.
- Both tracked Finder `.DS_Store` files have been removed from the Git index;
  local copies remain ignored. Historical objects are still present.
- GitHub's description now reads: “Descriptive analysis of BMI and documented
  hypercapnia in a selected emergency/inpatient cohort, with aggregate reports,
  figures, and a synthetic reproducibility workflow.” Private visibility was
  verified unchanged after the update.

## Historical disclosure review

At inspection, all six advertised remote branches were already available locally
and the remote had no tags. The bounded scan covered all 40 locally reachable commits across
local, remote and archive refs, 605 text blobs, 21 unique PDF versions and metadata
from 12 raster images. PDF metadata, annotations, attachments and whole-document
native text were inspected for the configured indicators. No PDF text coverage
gaps or parser errors were recorded.

The pinned `pdf-inspector` backend was unavailable in the installed runtime.
The review retained that failure receipt and used whole-document Poppler
extraction for every PDF; no backend was installed. This review did not perform
new visual/scientific review of the reports or inspect every embedded image.
GitHub issue/PR discussions, wiki content and external attachments were outside
this Git-object scan and remain unassessed by this review.

Findings requiring a retention decision:

- Absolute local source paths remain inside the legacy HTML report under `Code/`
  and five legacy PDFs under `Code/` and `Documents/`. Prior QMD source versions
  and older work-log versions also contain local paths.
- Finder metadata survives in historical objects and other branches. Removing
  files from the current index does not remove them from existing history.
- No matches were found for the bounded private-key, GitHub-token or AWS-access-key
  patterns. This does not establish absence of all credentials, identifiers or
  disclosure risks.

Review whether these historical local paths and Finder metadata can remain in the
public history. No accepted report, snapshot or Git history was rewritten. Any
sanitized release representation or history remediation needs a concrete separate
decision that preserves the original evidence.

## Reproducibility and verification

| Check | Current evidence |
|---|---|
| Artificial analysis-to-report E2E | **Passed** on isolated merged `53ccfc8`, resuming the fresh saved artificial run; scientific and audit HTML/PDF outputs completed (40 and 3,910 PDF pages), followed by all numerical/artifact assertions |
| Source-boundary checks | **Passed:** all 35 checks, no skips/errors/failures, on an isolated copy of the current schema-11 working source using the Mini's existing runtime; receipt `source-tests-20261024T015937-52794` |
| Source-test integrity | All 51 copied source/configuration files unchanged before/after execution; Python runner hashes stable; six transferred evidence files byte-verified; no dependencies installed |
| Saved clinical snapshots | All four manifests / 238 file sizes and hashes passed again after the documentation changes |
| Documentation | Local Markdown link targets resolve; LLM-guide JSON and staged/unstaged diff checks pass; final counts are recorded in the work log |

Earlier local/baseline source checks were incomplete because the bundled Python
lacked DuckDB. The fresh complete run used existing Mini Python 3.12.11, DuckDB
1.5.4 and pandas 2.2.3, with the documented R activation (R 4.6.1, haven 2.5.5,
jsonlite 2.0.0 and digest 0.6.39). Both `PREP_PYTHON` and subprocess `PATH` selected
that Python environment. Source preparation additionally requires the exact installed
upstream readers pinned in
[the mapping example](../config/common_index_mapping.example.json); this review
does not regenerate source products or qualify clinical inputs.

Concurrent ICD-acuity development changed analysis/configuration/report/test
sources in the shared checkout while the fresh artificial run was exporting
figures. The saved run is schema 10; later Quarto sessions loaded schema-11 code
and correctly rejected it. The first failure and immutable fixture are retained.
Those concurrent edits are preserved. Verification of the documented merged
release completed in a clean isolated checkout at `53ccfc8`; it does not validate
the unpublished schema-11 work or authorize migration/relabeling of saved bundles.
The source-matched figure-reuse interface completed reports without repeating
fixture estimation. The supported saved-run E2E entry point then passed; all
receipts and logs were copied with verified byte identities before checkout cleanup.

The local artificial run uses R 4.6.1, Quarto 1.10.18, existing TinyTeX/XeLaTeX
and Poppler 26.09.0. Installed R packages are ggplot2 4.0.3, jsonlite 2.0.0,
digest 0.6.39, lpSolve 5.6.23, nnet 7.3.20, knitr 1.51, rmarkdown 2.31 and haven
2.5.5. These are observed versions, not a lockfile or a claim of compatibility
with every operating system/version. The [README](../README.md) gives prerequisites,
commands, expected receipts and the separation between synthetic execution and
clinical reproduction.

## Remaining release decisions and recommended safeguards

1. **Licensing and attribution:** confirm code and output reuse terms and review
   third-party notices, including the libraries/fonts bundled with legacy HTML.
   No project license file is present; no license is selected or added by this change.
2. **Preferred citation:** confirm the author list, project title and release
   identity before adding `CITATION.cff`. No DOI or paper citation is invented.
3. **Historical retention:** adjudicate the local-path/Finder findings above;
   automated signature scanning is not comprehensive disclosure clearance.
4. **Retain source verification:** the current working-source copy passed
   `make source-test PREP_PYTHON=...` with no skips. Retain its source-bound receipt
   and repeat on the final release source if adapters, tests, R or configuration
   change. Artificial source checks do not qualify clinical inputs.
5. **Maintenance safeguards:** synthetic CI and branch protection are recommended;
   no GitHub Actions workflows or protection of `main` existed at review time.
   Reuse the current `make test` / `make source-test` entry points and retain
   commit-bound receipts and logs. Missing dependencies must fail or mark a run
   incomplete rather than produce a green scientific-validation claim.
6. **Dated release:** after the release checks and decisions are resolved, reconcile
   any newer analysis development with its own verification and documentation,
   review the final commit, select a version and publish a dated release with the
   snapshot manifests and clearly separated scientific review states.

Detailed local receipts are retained under the ignored
`artifacts/triangulation/public-release-20261023-0yy69ejb/`; commands, final
results and limitations are summarized in [WORKLOG.md](../WORKLOG.md).
The completed current-source check, source manifest, runtime versions and transfer
hashes are under `artifacts/triangulation/source-resolution-20261024/`.
