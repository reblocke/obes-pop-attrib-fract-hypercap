# Current RFS amendment — 2026-10-17

The approved RFS plan supersedes the combined-cohort primary population below.
Use schema-6 `bmi_hypercapnia_rfs_curve_audit_v1` and schema-4 metadata-qualified
inputs. Select the common clinical index first, then partition source membership.
Primary includes any non-OBESITY positive, including overlaps; obesity-only requires
OBESITY=1 plus five authenticated zeros. Unknown is not zero. Combined results
are an audit reference; no new combined primary fit. Each main group gets its
own fixed spline basis. Current-measurement supporting models reuse the parent
basis; all-OBESITY supporting models use their own. Generate model positions from
saved configuration, never a fixed total. No clinical-field or index change is
implicit in metadata enrichment. Preserve source products and previous bundles.
Run data-free tests, full render integration and human review as distinct checks.
The owner approved the implementation plan's review/release/qualified clinical-run
sequence; submission and investigator scientific approval remain separate.

# AGENTS.md

## Current authority and deliverables

The 2026-10-16 curve/audit refactor supersedes the single-linear-BMI coefficient,
PIF-first 140-position registry and historical-version replay. The current plan
is `docs/BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md`; its 73 acceptance requirements
are in `docs/CURVE_AUDIT_ACCEPTANCE.csv`. The user additionally confirmed the
original selected encounter population and known-capture ICD reference.

Primary deliverables are `reports/bmi_hypercapnia.qmd` and
`reports/bmi_hypercapnia_audit.qmd`, generated from one version-6 aggregate bundle.
The scientific report centers BMI probability curves, observation and BMI
frequencies. The audit contains every applicable stage/variable and every planned
model, including full coefficients, covariance, failures and diagnostics. Do not
substitute previews for complete tables. Raw coordinate tables are exported in
full and represented by full-range plots in the PDF.

Existing raw inputs, private artifacts and Git history are immutable. Earlier
source files and reports are superseded references, not a compatibility service.
Do not source historical analysis files in the current pipeline. Old analysis
bundles must fail clearly; no automatic relabeling/migration is authorized.

## Scientific specification

- Restrict candidates to authenticated original FULL_DATA selected ED/inpatient
  keys (`original_selected_encounters_v1`). History supplies prior measurements,
  not additional candidate visits. The former outside-list mapping gap is historical.
- Adults >=18 under the approved birth-year age proxy, encounter starts in 2022,
  EMER/IMP, first qualifying BMI >=30 before gas and adjustment completeness.
  Earlier unresolved membership, conflicts and earliest ties remain unresolved;
  never select a later more complete index. Reliable exclusion overrides unrelated NA.
- Bind `available_encounter_or_prior_bmi_v1`: current/prior reported BMI then
  observed height/weight calculation, inherited transport/rounding, no statistical
  imputation. Completed-missing BMI does not qualify; unresolved source differs.
  Do not change the hierarchy or masking screens without an explicit decision.
- Q is resolved eligible indexes; C is Q complete for inherited BMI/age/sex/
  race-ethnicity/region; C40 subsets original C. No new adjustment or imputation.
- Primary gas outcomes: ordinary authenticated ABG >=45 and ABG >=45 or VBG >=50.
  Strict validity: 5<arterial<200 and 10<venous<250 mm Hg; explicit units;
  `unadjusted_pco2_v1`. Unspecified/adjusted values require their reviewed handling.
  Available-evidence negatives do not establish an unmeasured specimen normal.
- ICD composite J96.02/J96.12/J96.22/J96.92/E66.2, with captured absence negative
  only when encounter diagnosis capture is complete. ICD curves/scenarios use
  C_icd with known capture, including positives/negatives. Do not project unknown
  diagnosis capture into the full reference. Label E66.2 ascertainment.
- Calendar-day sensitivities retain indexes and use collection=start calendar
  date, not elapsed 24 hours. Pending source is distinct from individual unknowns.
- Primary logistic BMI natural spline: C quantiles .05/.35/.65/.95, type 7;
  middle knots interior, outer boundary, three basis columns. Reuse numeric basis
  across models/predictions. Age linear; explicit inherited factor references.
  Linear-form sensitivity uses identical samples, without automatic selection.
- Every planned primary/timing/observation/matched/linear fit has a registry entry.
  No substituted estimators, pooled categories or hidden na.omit exclusions.
- Gas curves standardize over their outcome-observed model population; ICD over C_icd; observation over C; matched pairs
  use identical within-pair rows. Do not project physiological outcomes to untested
  patients. Do not describe documented index occurrence as incidence/prevention.
- Secondary default: observed BMI >30 minus exactly one, no floor/reselection;
  BMI=30 unchanged. Named caps are disabled by default. Pair actual patient
  covariates and index; original-BMI-band contributions and covariance reconcile
  exactly to total difference/PIF. Never integrate a marginal risk curve*density.
- C40 retains descriptive profiles only. Full-cohort MAR/MNAR projections are
  historical; IPW is deferred. Observed-data timing/matched/linear checks remain.
  Assumptions are separate from model-based pointwise intervals. No weights or facility clustering
  inferred from geographic region; no new missingness reconstruction by stealth.

## Workflow and source readiness

- Use `make fixture`, `make test`, `make preflight INPUT=... MANIFEST=...`,
  `make cohort-audit INPUT=... MANIFEST=...`, `make analyze INPUT=... MANIFEST=...`.
- Use `make render RUN=...`, `render-html`, `render-pdf` for both reports from
  explicit saved aggregates. Rendering never reads clinical data or refits.
- `make prepare/map/qualify` retain the study-specific source adapter and existing
  pinned upstream readers. No upstream rebuild or replacement export is presumed.
- Preselected clinical inputs require a hash-bound pre-index cohort-audit
  companion, generated from existing mapped candidate covariates before selection.
  A selected-index input alone cannot establish earlier-stage distributions.
- Reuse the existing original-list qualification evidence, but authenticate the
  new input/companion and reconcile its index fields. Uncovered candidates within
  the original population block inference. Partial audit totals remain null.
- Clinical analysis requires a clean merged Mini checkout matching origin/main.
  Before remote writes, inspect active work/leases and avoid overlapping changes.
  Do not modify accepted source products or invent human-review approval.
- Keep software complete, source qualified, execution complete, numerically
  reviewed and scientifically reviewed as separate receipt states.

## Implementation, tests and figures

Prefer focused modules and existing installed R>=4.3/Quarto dependencies; no
framework, automatic package installation, renv bootstrap or new clinical pulls.
Use explicit namespaces, descriptive names, local state, fixed seeds for fixtures,
and no interactive calls, setwd/attach or covariate imputation.

The cohort ledger is the sole count authority. Record grain and edge relation;
never add overlapping samples as partitions. Register all imported/derived fields.
Identifier values, individual predictions/diagnostics, exact dates, model objects
and model frames stay out of bundles. Exact aggregate clinical audits remain
private; aggregate does not automatically mean safe to publish.

Use ggplot2/grid/vector for data-bearing figures. Apply
figure-and-medical-illustration-qc: informative captions/alt text, 190-mm review
width, >=9-point data labels, explicit reference/window/intervals, full ranges and
support warnings, signed contributions, grayscale and native-size inspection.
Export source, SVG/PDF, 300-dpi PNG/JPG and retain three F1 alternatives. Never
claim completed visual inspection or numerical review from export success alone.

Run independent artificial checks, adverse cases and actual full HTML/PDF renders.
All 73 checks need evidence; F render/visual checks require the actual review
receipt. Preserve failures and repair safely. Log substantive changes, commands,
outputs, failures and next steps in WORKLOG.md. No commit/push/submission or
external communication follows automatically from this refactor ticket.

## Current report/release amendment — 2026-10-16

Expanded mini-paper: detailed Methods, primary coefficients and diagnostic Results,
observed-data sensitivities and example conclusions. Complete audit retains all
values with explicit verified identical-summary aliases. Required figures must
fail rendering when missing; captions remain with vector figures. Use version 6
`bmi_hypercapnia_rfs_curve_audit_v1`; reject old bundles, never relabel them.
The owner explicitly authorized review/commit/push/PR/merge and a fresh Mini
clinical run for this revision. That approval does not extend to submission.
