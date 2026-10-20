# Verification

`make test` runs the shipped artificial fixture launcher, saves the current
aggregate bundle, and renders both scientific and audit reports as HTML and PDF.
It checks the persisted output against independently reconstructed indexes,
outcome samples, base-R regressions, paired predictions and finite-difference
uncertainty calculations. Every declared figure and complete audit table must
survive the real render. A fresh receipt, logs and artifact hashes are written
under `artifacts/triangulation/e2e-<time>-<pid>/`.

To resume verification after an interrupted render without repeating estimation,
run `Rscript --vanilla tests/run_e2e.R <saved-artificial-run>`. The bundle must
match the current analysis sources. This command rerenders if no complete
source-matched review exists. It does not accept a clinical run.

The fixture starts **after source transport**. Run
`make source-test PREP_PYTHON=/path/to/existing/python` separately in the accepted
source-reader environment. Its receipt records failures and unavailable tests;
skipped dependencies do not count as passed. No test installs packages, reads
clinical inputs, or asserts human/scientific approval.

## Why the remaining checks exist

| Failure not established by a successful render | Independent check |
|---|---|
| Plausible curves with wrong samples, paired predictions or covariance | `e2e_oracles.R` reconstructs fixture indexes and refits with base R; numerical derivatives check saved intervals and signed contributions. |
| Unknown RFS treated as zero, a later complete encounter promoted, or BMI shift incorrectly floored | Explicit adverse inputs in `e2e_oracles.R`; these cases are not guaranteed by random fixture draws. |
| Incompatible or tampered output silently accepted | Public renderer rejection runs against isolated copies of the saved bundle. |
| A configured scenario is plotted under a hard-coded scientific label | The exported scenario PDF must include the policy label from the saved run. |
| Accepted source values corrupted before the typed fixture boundary | Python source tests exercise specimen/unit/capture rules, original-key restrictions, qualification disagreement and RFS joins. |

Historical Stata replay, predecessor projection/grid suites, fixed acceptance-ID
checklists, prose assertions, source-text assertions and synthetic human-review
gates have been removed. The complete reports and their aggregate tables are the
repeatable end-to-end artifacts; visual and investigator review remain separate.

## Paired-ABG supplement: failure scenarios (before implementation)

An encounter/date join can invent acidemic hypercapnia; maximum CO2/minimum pH
can combine different draws; max-CO2-only selection can miss a qualifying pair.
Rounding near 7.35, mixing venous/adjusted records, conflicting corrections,
duplicate records and reused identifiers can misclassify endpoints or double draws.
Missing linkage must not become negative evidence. Partial pairing must preserve
original positives. Enrichment can corrupt keys or silently alter first indexes.
A generic model loop can add unwanted PIFs, recompute knots, change reference rows,
or omit unavailable positions. Reports can show plausible but different denominators.

Source-boundary fixtures below precede production code and independently specify
expected outcomes. The typed-input E2E independently refits both models, checks
identical rows/basis, all existing estimates, nesting and absence of new PIFs,
then renders the complete reports and figure. These source checks are necessary
because the existing typed-input E2E cannot detect invented specimen linkage.
