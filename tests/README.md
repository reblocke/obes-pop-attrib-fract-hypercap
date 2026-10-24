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

Use an existing Python environment with both `duckdb` and `pandas`. Put that
environment's `bin` directory on `PATH` as well as setting `PREP_PYTHON`, because
some boundary checks launch `python3` subprocesses. Activate the existing project
R environment so `Rscript` and its libraries resolve correctly; the typed-input
roundtrip sources the current R workflow. Set `TMPDIR` to an existing writable
directory without spaces. Nothing in these commands installs dependencies.

A complete run exits zero and records `status: passed`, no unavailable/failed/error
checks, and `sources_unchanged: true` in its `receipt.json`, beside `run.log`.
The runner hashes Python adapter/test files. When testing an isolated source copy,
also verify the copied R/configuration files before and after execution and retain
the source identity and runtime versions with the receipt.

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

## ICD acuity supplement

Failure scenarios were recorded in `docs/ICD_ACUITY_SUPPLEMENT.md` before coding.
The E2E oracle independently fits the five-class likelihood and finite-difference
contrasts, verifies original outputs, and renders S2 and both complete reports.
The isolated Python source boundary is justified because typed-input E2E cannot
observe original-key/code-system transport corruption or record identity conflicts.

## ICD separation repair (2026-10-24, before implementation)

Observable failures: a separated class can be silently dropped, regularization
can alter primary/S1 fitting, a four-category sensitivity can retain excluded
patients in standardization, and a scaled Hessian or category ordering error can
produce plausible but incorrect intervals. A Poisson expansion can exhaust memory
at the clinical cohort size. Sparse regions must remain visible after finite
estimates become available. Unsupported inputs and absent classes must retain
explicit failure positions.

The ICD E2E oracle will optimize the multinomial log likelihood plus one half of
the log determinant of its information independently, with numerical derivatives;
it will compare coefficients, information covariance, predictions and signed
contrasts. A separated fixture is optimized independently; a published brglm2 AS_mean
five-category example supplies externally recorded coefficients and SEs. A numerical derivative check
of the penalized score and an intercept-only analytic solution independently
cover optimizer errors the report render cannot detect. The four-category
sensitivity is unpenalized, has its own filtered reference, and remains failed
if separation persists. All original primary/S1/PIF numerical tables must remain
unchanged. New tables and figure exports must match their shared aggregates.

Reference fixture `fixtures/icd_firth_reference.csv` contains the public
alligator example used by the package author, not study patients. Source data:
https://github.com/ikosmidis/brglm2/blob/main/data/alligators.rda . Expected
coefficients/SEs are transcribed from the converged AS_mean example in
https://stat.ethz.ch/CRAN/web/packages/brglm2/vignettes/multinomial.html .
The separated numerical oracle is independent of that nonseparated reference.
No brglm2 runtime dependency or live network access is needed for tests.
