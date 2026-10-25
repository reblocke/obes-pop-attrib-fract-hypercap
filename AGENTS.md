# Working on BMI–hypercapnia

## Scope and change discipline

The current analysis is schema 13 (`bmi_hypercapnia_rfs_curve_audit_v8`; input schema 5). Read
`docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md` and `docs/SOURCE_CONTRACT.md` before
substantive work. Configuration and the variable dictionary live in `config/`;
the cohort ledger is the sole count authority.

Before non-trivial edits, state assumptions, the smallest plan, silent-failure
risks and verifiable success criteria. Reproduce bugs before fixing them when
feasible. Preserve unrelated edits. Do not build compatibility layers, alternate
launchers, generic frameworks or tests merely to retain obsolete versions.
Historical source is recoverable through Git and `archive/README.md`.

For collaborator or LLM-assisted reading, use `docs/LLM_GUIDE.json` for the dated
approval state, selected figure identities and result-table navigation. It is a
documentation companion, not a second analysis configuration. Keep it aligned
with `docs/DECISIONS.md`; do not treat access to the repository as permission to
draft, rerun, share or submit beyond the owner's current request.
The current all-valid-BMI reading packet is `results/2026-10-24-all-bmi/`.
Verify its manifest before numerical claims; use its tables for the current
primary and nested-secondary results. Source qualification, clinical execution,
numerical review and scoped visual review are complete. Investigator interpretation
and new figure approval remain pending. The snapshot is not a runnable bundle.
Historical BMI-restricted, pairing-feasibility, same-day and ICD snapshots remain
unchanged; their identities and limitations are indexed in `docs/LLM_GUIDE.json`.
Never relabel them or transfer historical B/F2 approval to the new results.

## Scientific invariants

- Use authenticated original FULL_DATA ED/inpatient encounter keys. History
  supplies prior measurements, not additional candidate encounters.
- Select the first 2022 adult EMER/IMP encounter with any valid available BMI before gas
  availability, adjustment completeness or RFS classification. Do not promote a
  later encounter when earlier eligibility, chronology or ties are unresolved.
  Completed-missing BMI differs from unresolved evidence; reliable exclusions
  override unrelated missing fields.
- Derive the BMI >=30 secondary at that same new index; do not promote a later obese encounter. Repeat all three endpoint families with the secondary population’s own fixed basis. Current-BMI models reuse primary knots; all-OBESITY models remain overlapping sensitivity.
- Preserve the approved current/prior reported BMI then observed height/weight
  hierarchy, transport, rounding and masking screens. No statistical imputation.
- Partition the fixed indexes by authenticated historical source membership:
  any positive non-OBESITY flag enters primary (including overlaps); obesity-only
  requires OBESITY=1 and five known zeros. Unknown is not zero. Combined and
  obesity-only populations are audit-only, with no adjusted obesity-only models,
  curves, PIFs or weighting comparison. Do not recode flags from current outcomes.
- Ordinary specimen-authenticated ABG >=45 or combined ABG >=45/VBG >=50 use
  explicit mm Hg units and strict validity 5<ABG<200, 10<VBG<250.
  Missing/unusable values remain unknown. Available-specimen negativity does not
  establish an unmeasured specimen normal.
- ICD is J96.02/J96.12/J96.22/J96.92/E66.2. Captured absence is negative only when
  encounter diagnosis capture is complete. Capture is not ICD positivity.
  Calendar-day gas sensitivities keep indexes and use recorded-result date=start date.
- Within each RFS group, resolve the three-degree-of-freedom natural BMI spline
  from its covariate-complete reference's type-7 .05/.35/.65/.95 quantiles.
  Reuse that numeric basis across outcomes and predictions; current-measurement
  primary models reuse the primary basis. Age is linear; inherited sex,
  race/ethnicity and region coding/references remain unchanged.
- Standardize gas curves over their outcome-evaluable populations and ICD over
  known-capture patients. Matched models use identical paired samples. Preserve
  every configured model position, including failure/nonestimable/pending states.
  No fallback estimators, hidden na.omit, pooled categories or new adjustment.
- The secondary scenario subtracts exactly one unit from observed BMI >30,
  with no floor, reselection or covariate/RFS change. Paired predictions and signed
  original-BMI-band contributions/covariance reconcile to total difference and PIF.
  Never multiply a marginal adjusted curve by marginal BMI density.
- No full-cohort gas projections, MAR/MNAR, IPW, incident-disease or causal-prevention
  claims. Model-based pointwise intervals do not cover selection/measurement bias.

## Testing policy

- Never write unit tests after you write code.
- Highly prefer E2E tests as the sole testing mechanism. Use them to verify complex features work. At the end of E2E tests, produce a verifiable and repeatable artifact.
- If you must test a system in isolation, first write down all the ways it could fail, then write the code.

Before changing a complex feature, describe its observable failure scenarios and
E2E evidence. An isolated check must name a real failure E2E does not independently
catch; otherwise remove it. Do not freeze prose, function names, historical test
counts or internal implementation details. Independent numerical oracles and
source-corruption boundaries may justify isolated checks; keep their rationale
in `tests/README.md`.

Run `make test` for artificial analysis-to-report E2E and
`make source-test PREP_PYTHON=...` for separate source boundary checks.
Missing dependencies/skips are not passes. Automated testing, visual inspection,
numerical review and investigator scientific approval are separate states.

## Execution, outputs and figures

- Current commands are in Makefile/README. Clinical estimation requires a clean
  merged Mini checkout matching origin/main and qualified evidence-bound input.
  Inspect active remote work/leases before any remote writes.
- Rendering takes an explicit saved run and must not read clinical inputs or
  refit. Preserve source/hash/manifest guards. Reject incompatible historical
  bundles clearly rather than relabeling or migrating them.
- Raw inputs, accepted source products, prior bundles/results and Git history are
  immutable. Never export identifiers, exact dates, patient predictions, model
  frames or model objects in aggregate bundles. The owner permits reports, figures
  and aggregate result tables in Git and collaborator review material. Do not
  confuse the ignored local run directory with a ban on versioning these outputs;
  keep raw/patient-level data and source-access secrets excluded.
- Preserve the scientific mini-paper and complete audit: all applicable variables,
  coefficients, covariance matrices, diagnostics and failures; no table previews.
  Required missing figures must fail the render.
- Apply `figure-and-medical-illustration-qc`: clear substantive comparison,
  self-contained captions/alt text, 190-mm review width, >=9-point data labels,
  explicit denominators/windows/intervals, grayscale readability and full ranges.
  Print CIs beside estimated percentages; preserve signed contributions and
  support warnings. Keep editable R, SVG/PDF, 300-dpi PNG/JPG and F1 A–C alternatives.
  Record actual native-size and assembled-page inspection, never export-only claims.
- Use existing installed dependencies; no automatic installations, upstream
  rebuilds or fresh clinical pulls. Log changes, commands, failures, artifacts
  and remaining limitations in WORKLOG.md.
- Refactoring alone does not authorize clinical reruns, commit/push/merge,
  external communication or submission.

The same-day and ICD component models are integrated endpoint families in the
main scientific report and repeat in the nested BMI >=30 secondary. Their source
qualification statuses remain independent. See the scientific specification for
exact definitions. Do not add component-specific PIFs. Same recorded-day evidence
is co-occurrence, not verified sample pairing; ICD acuity is coding, not physiology.

Use one `make prepare` for covariates/RFS/gases/recorded-day evidence/code flags.
Authenticate new selection/source identities; old-run comparison is a separate
reconciliation, not an input-acceptance prerequisite. Future runs must repeat
qualification and review; the current verified reading packet does not confer
scientific or submission approval.
