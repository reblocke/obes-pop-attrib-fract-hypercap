# Verification

## Encounter-setting update: failures recorded before estimation edits

See `docs/ENCOUNTER_SETTING_UPDATE.md`. The E2E fixture deliberately correlates
setting with BMI, gas availability and outcomes. Independent binary and joint
likelihood oracles explicitly include EMER/IMP; they do not import the production
adjustment list or formula. A reduced-model comparison must detect omission.
Single-setting and absent-reference cases must retain explicit failures. Saved
setting-by-BMI counts/intervals must reproduce independent fixed-index aggregation.
The real reports must contain the factor/reference, its full covariance and the
new display label. Input/schema guards and aggregate-only rendering remain required.

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

## All-valid-BMI integration (2026-10-24; recorded before implementation)

Observable failures: the preparation selector can retain BMI >=30 while the R
cohort changes; a lower-BMI first encounter can be replaced by a later obese or
more complete encounter; RFS metadata can be carried from the old index; and
subgroup construction can silently reselect. Unshifted patients can disappear
from the PIF denominator or contribute a nonzero difference. The BMI >=30
secondary can borrow the wrong basis or reference. Joint-family tables can mix
populations when keyed only by BMI, and an absent source family can suppress the
base analysis. Consolidated preparation can lose code/capture evidence or accept
an old policy under new labels. Rendering can omit secondary populations or use
old labels while displaying plausible numbers.

Before production edits, extend the existing artificial fixture and independent
index/model/prediction oracles to cover lower BMI, 30 and 30.2, an earlier lower-BMI
index, nested secondary membership, both joint families in both populations, and
zero contributions below the shift threshold. Keep independent likelihood,
finite-difference covariance and source-corruption checks. Require real HTML/PDF
renders, complete table coverage, exact registry membership and aggregate-only
rerender receipts. A small pre-change fixture snapshot is retained privately to
verify unchanged numerical kernels on identical data; changed cohorts are not
expected to reproduce historical clinical estimates.

Qualification regression scenario: prepared inputs now retain BMI provenance. Joining the full prepared shape to the mapper must not make shared `bmi_method` names ambiguous; the independent source check retains that field, unlike the earlier reduced fixture. This catches a clinical qualification execution failure before any model runs.

The source boundary also exercises the actual prepared-CSV reader with an exactly promoted float32 BMI below 30. Pandas default parsing can change the last binary digit even when the typed RDS and mapper agree. The independent parquet oracle requires exact transport; a numerical tolerance is not a substitute.

Typed transport failures also include base R decimal parsing at lower float32 BMI values. The existing Python-to-R boundary writes independent binary-double oracles for 10.1 and 15.9 as stored float32 values, then checks the actual RDS byte-level numeric values, keys, dates, missingness and gas-threshold precision. Both selection and final typing must use the same exact numeric reader.

## Primary gas-flow revision (2026-10-25, before implementation)

A nested flow can accidentally use arterial-only patients, filter on positive
hypercapnia/acidemia, treat missing adjustment as absent gas, show an unavailable
recorded-day module as zero, or imply that departure removes a patient from an
already eligible broader analysis. These errors can survive otherwise correct
models and plausible report pages. The existing E2E is extended before renderer
changes: independent fixture indexes/measurements determine stage/departure Ns,
real exported tables/PDFs must agree, and the completed report must contain the
new figure/caption while the audit preserves detailed source-entry accounting.
Explicit missing-module and nesting-corruption checks exercise the same figure
entrypoint. No new unit-test framework or clinical execution is introduced.

Audit render failure observed during this change: whole-table UTF-8 token
processing rescans large strings at every punctuation boundary, making complete
PDF assembly disproportionately slow. Before the focused fix, the E2E records a
Unicode long-table fixture, compares the complete report formatter output with
independent line-wise formatting, and retains both text and timing evidence.
Equality protects every table character; a size-scaling check catches the actual
rendering failure without fixing an arbitrary wall-clock limit.

## F1-main composition: pre-implementation failure scenarios

The A/B order can be reversed without breaking a render; an arterial subset can
incorrectly exclude dual-specimen patients. Observation curves can be mistaken
for hypercapnia probabilities, and D can repeat C's smaller frequency sample.
Landmarks can silently retain BMI 50 or lose their exact intervals. Stacked
components can use mismatched grids, failed models can disappear, and a second
ATS implementation can drift from the scientific report. The E2E checks the
exported panel/model ledger, exact saved BMI 30/40 values, frequency sums and
component partition, explicit unavailable-model export, and both assembled PDFs.
Underlying estimates retain the independent regression oracles.

### Reproduced Quarto intermediate collision

Concurrent artificial and clinical report jobs in the same checkout collided on
shared report intermediates: the clinical audit HTML could not reopen its QMD,
and the artificial report job failed. Each render must stage its own exact QMD
and CSS inputs inside its fresh review directory before invoking Quarto. The
E2E checks source-copy hashes and private staging paths; the clinical and
artificial full-report runs also exercise this concurrently. This is render
isolation only, with unchanged scientific methods and aggregate values.
