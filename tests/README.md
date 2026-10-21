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

## Same-day supplement: failure scenarios (before implementation)

An encounter-wide max/min can combine different recorded dates. Same-date values
from different samples are allowed co-occurrence but must never be labeled verified
pairing. Rounding near 7.35, mixing venous/adjusted records, invalid dates/units,
duplicate transport and reused source-record identities can corrupt endpoints or
counts. Missing evidence must not become negative. Other unusable records must not
erase valid co-observed days. Enrichment must preserve original keys, fields and
indexes. A generic model loop can add unwanted PIFs, recompute knots, alter reference
rows or drop failed positions. Reports can show plausible but wrong denominators.

Source-boundary fixtures below precede production code and independently specify
expected outcomes. The typed-input E2E independently refits both models, checks
identical rows/basis, all existing estimates, nesting and absence of new PIFs,
then renders the complete reports and figure. Source checks independently catch
cross-date joins, corruption and invalid evidence before the typed-input boundary.

## Joint component supplement: failure scenarios (before implementation)

The two nested outcomes can be mistaken for mutually exclusive components; mixed
days must instead enter the with-acidemia category. Subtracting independent fitted
probabilities can produce incoherent components and incorrect intervals if their
cross-model covariance is ignored. Multinomial coefficient ordering, reference
levels, Hessian scaling and softmax gradients can silently corrupt plausible
curves. A missing class, separation, singular information or optimizer failure
must not become a successful binary fallback. A stacked upper boundary can be
mistaken for the upper component's probability, and tail sparsity can disappear
when categories are combined.

Before replacing production estimation, the same-day E2E oracle is changed to an
independent softmax likelihood/optimizer, finite-difference probability/contrast
gradients and category partition checks. It verifies joint covariance, all three
probabilities and their sum, signed component contrasts, identical primary output,
missing-source and absent-class failures. Full report rendering and saved numeric
display tables verify the stack and component curves use the same aggregates.
The source boundary remains unchanged: its existing mixed-day and threshold
fixtures establish what the two authenticated flags mean.

A complete caption can overflow a PDF float even when text bounds appear clean.
The S1 E2E check compares its full saved caption with both assembled PDF texts;
it catches clipping without freezing the caption's wording. This failure was
reproduced in the initial joint-model report before shortening the caption.
