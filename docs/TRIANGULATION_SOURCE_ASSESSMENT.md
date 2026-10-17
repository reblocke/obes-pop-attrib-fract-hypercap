# Observed-population report revision — 2026-10-16

The approved version-5 workflow retains the accepted original-list input,
pre-index companion, BMI derivation, outcome definitions, fitted models and
source qualification. Gas curves, contrasts and secondary scenarios now
standardize to their outcome-observed populations; ICD uses known diagnosis
capture. Full-C MAR/MNAR projections are historical only. IPW is deferred.

PR #9 merged as `ca24564` after 73 artificial acceptance checks, 24 adapter
checks, complete artificial renders and recorded visual review. A fresh source
preflight and clinical estimation completed from a clean matching Mini checkout.
All 103 aggregate numerical checks passed, including unchanged cohorts, models,
covariance and observed scenarios versus the historical run. Input, manifest and
all bound evidence hashes remain unchanged. Both clinical HTML/PDF reports
and all figure exports passed recorded layout QC.
No additional source export or upstream rebuild was needed. Investigator
scientific review remains a separate, unasserted state.

The earlier release below is preserved as history. Its successful exports and
recorded QC did not detect all presentation defects: this revision repairs
crossed flow connectors, compressed panels, detached captions and incomplete
symbol rendering, and requires a new visual-review receipt.

## Historical version-4 release record

## Current source acceptance and execution — 2026-10-16

The owner explicitly accepted the checked original-selected-encounter source,
pre-index companion and mappings and authorized release and clinical estimation.
Twelve post-run input/evidence hashes match; existing independent field and
30-check original-population evidence is retained. This accepts the
documented-evidence source for the agreed use, not MAR/MNAR assumptions or
causal claims.

PR #7 merged as `f18d383`; its tree exactly matches the candidate tested on the
Mini (65 artificial acceptance checks, 24 adapter tests, both complete HTML/PDF
reports and recorded figure/page QC). A separate clean external-drive worktree
preserves the pre-existing Mini edits and upstream checkout. Fresh clinical
preflight and one estimation completed from the merged revision. All 21 model
positions remain visible: 20 fits succeed; ICD capture availability is constant
and its raw proportions remain available. No source, covariate or estimator rule
was changed for execution.

The private `clinical-release-20261016/` packet binds source acceptance, reviewed
manifest, merged commit/tree, clinical bundle and 48 aggregate numerical checks.
Both clinical HTML/PDF reports and all 153 figure exports pass recorded QC.
Investigator numerical/scientific review remains pending. No clinical artifacts
or effect estimates are included here.
The dated pre-run assessments below remain historical evidence, not the current
execution status.

**Final refactor verification — 2026-10-16:** the fresh pre-index companion,
independent selected-field comparison and model-free preflight pass in the
isolated Mini snapshot. All 13 qualification-function identities and all
estimation-file hashes match the tested local implementation. All 24 source
adapter tests pass there without skips. This is automated source/ledger evidence;
clinical model execution and investigator scientific review remain unrun.
The accepted input/products and existing Mini working checkout are unchanged.

**Current workflow amendment — 2026-10-16 curve/audit refactor:** the original
selected encounter scope is retained. Prior passing original-list source checks
remain evidence for that scope; the earlier outside-list mapping gap is historical.
The new analysis additionally requires a hash-bound pre-index cohort-audit companion
from the existing mapped candidate covariates. The earlier selected-index input
alone cannot establish those stage distributions. New companion reconciliation and identity-bound preflight now pass on the Mini,
using the unchanged accepted input and a fresh private manifest. The independent
field comparison and current qualification-function hashes agree. Clinical model
execution remains unrun; human/scientific review is not asserted. Current commands are
`make prepare`, `make qualify`, `make preflight`, `make cohort-audit`, `make analyze`
and `make render RUN=...`; dated commands below describe superseded workflows.
The active plan and README define the current interface. Preserve existing inputs,
accepted products and human-review status.

**Current use — 2026-10-16 correction:** candidate membership is restricted to the authenticated original FULL_DATA selected encounter list. The earlier broader-population readiness determination below is superseded for this use. Fresh original-list mapping/preparation and all 30 independent source checks pass; identity-bound preflight passes with zero models fitted. See [the decision](DECISIONS.md#original-encounter-list-correction--confirmed-2026-10-16). No clinical model has run.

**Earlier broader-scope use (superseded):** common first BMI ≥30 indexing and separate arterial/combined projections, with the valid-BMI clarification and [2026-10-16 mapping/qualification update](#expanded-source-qualification--2026-10-16) below. Dated assessments remain history. No clinical model has run.

# Bounded source assessment for the primary BMI-shift analysis

Assessment date: 2026-10-13. Intended use: the patient-level, fifteen-cell one-unit BMI shift above 30, with nine encounter-wide primary and six index-calendar-day sensitivity positions. **Clinical input acceptance is not established on this machine. Existing accepted source products are not declared unsuitable.**

## What was checked

- Read current upstream `main` at `787fba64319c0285244e2e17a9e303c739f31a14`, including delivery state, encounter interface, population proposal, exact-code transport and legacy/base source.
- Compared those records with the older local preprocessing checkout and September handoff. The older failed-build status is superseded by the current upstream acceptance record.
- Located the local RDS and previous schema audit; performed one bounded schema/code/gas-category inspection without exporting identifiers, selecting indexes or fitting models.
- Checked locally available manifest/receipt locations and product-volume availability. The current source products are not mounted here; the read-only Mini connection could not resolve its host. The available handoff receipt predates acceptance and cannot substitute for it.

Detailed input identity, aggregate categories, pinned source snapshots and access evidence remain in ignored `artifacts/triangulation/primary-shift-implementation-20261013/`. No patient-level output or clinical model was generated.

## Requirements and smallest next actions

| Requirement | Evidence / status | Next action |
| --- | --- | --- |
| Upstream encounter engineering acceptance | Current state records passing original-key linkage, independent FULL_DATA/AFTER_EXCLUSION transformations, coverage and retained-reference validation. Satisfied for that documented contract; private receipt bytes were not rechecked here. | Reuse the existing accepted bundle and trusted receipt/configuration; do not reopen the old build-failure task. |
| Input lineage and conversion | The local RDS has no reviewed study manifest. The historical conversion candidate and filenames do not bind it to the accepted product. Not locally verified. | Bind the existing input to its producer, variant, conversion and accepted identities, or produce a typed study input from the accepted product using existing readers. |
| Original patient/encounter keys | Accepted upstream bases restore original string keys and retain encoded legacy aliases. The local RDS's numeric patient encoding is not an authenticated original-key mapping. Requires downstream mapping. | Carry original keys from the accepted product/crosswalk; do not convert encoded numbers to strings and declare them original. |
| Complete intended frame coverage / chronology | Compatibility-backed products inherit the accepted historical 36-file population. The canonical captured source has broader exact-key access; its independent population interface has separately scoped acceptance questions. Normal gas records are present locally, which is necessary but not a completeness proof. | Reconcile intended 2022 acute-care candidate keys/chronology with the captured source, including normal/boundary/positive/unusable gases and BMI/adjustment coverage. Preserve unresolved starts; do not require agreement between the intentionally different frames. |
| Testing membership | Legacy `has_abg`/`has_vbg` are nonmissing-result flags. Raw exact-code transport retains unusable records. Requires reviewed downstream evidence mapping. | Examine existing lab/collection provenance and capture states, distinguishing confirmed testing from numeric availability and unknown capture. |
| Specimen-specific PCO₂ and units | Exact code-system/code selectors are available without rebuilding source or changing catalog membership. Catalog syndrome filters can select on elevated values. Requires mapping. | Select raw arterial/venous evidence without the syndrome-positive predicate; verify code lineage, units, valid-value and encounter attribution policies. Keep arterial and temperature-adjusted concepts distinguishable. |
| Calendar-day window | Accepted snapshot has calendar-date precision; date-based transport is available. Satisfied for choosing calendar-day rather than elapsed-hour timing. Summaries are not mapped in the local input. | Derive/authenticate separate encounter-start-day maxima and availability from existing dated records. No timestamp acquisition is needed for this approved sensitivity. |
| Derived BMI, age and regional adjustment | Accepted legacy transformations preserve their existing derivations/aliases. Coverage outside compatibility membership still needs reconciliation. Requires mapping. | Carry the approved derived values unchanged and verify coverage/code dictionaries in the intended population. |
| ICD negative/unknown coding | Existing legacy composite construction can conflate missing flags with zero. Raw diagnosis evidence and domain/capture states are available. Requires mapping. | Bind the five-code composite and reviewed absence-versus-unknown rule to encounter-specific source evidence/capture. |
| pH pairing, sample-link IDs, medication activity | These are not requirements for this PCO₂-only analysis. | Do not carry unrelated GLP-1 pairing/medication blockers into this study. |

No demonstrated need for a replacement export was found by this bounded repository/local-input assessment. No claim is made that the uninspected private source has passed every study-specific check. The smallest next step is to authenticate and map the existing accepted source on its available host; request additional source work only if that check demonstrates an unsupported required field.

## Authority and verification boundary

- [Current delivery state](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/CURRENT_STATE.md).
- [Accepted encounter interface and receipt boundary](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/ENCOUNTER_PREPROCESSING.md).
- [Population-interface scope and remaining questions](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/GLP1_POPULATION_INTERFACE_PROPOSAL.md).
- [Exact-code calendar source transport](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/CALENDAR_SOURCE_TRANSPORT.md).

The ignored `readiness-assessment.json` implements the research-data-readiness v1 receipt contract and passes its consistency validator with determination **not_evaluated**. Repository capabilities and acceptance scope were inspected; binding of this exact analysis input and the mandatory private population/field checks remain unverified. The receipt records those checks as unrun, rather than asserting that accepted source products failed them. Internal draft implementation and artificial-data verification are authorized by the implementation request; publication/submission is separate. No message or upstream request was sent.

## Status after the calendar-day model repair

Reviewed 2026-10-13. A live, read-only check of upstream `main` still returned `787fba64319c0285244e2e17a9e303c739f31a14`. The model variation check now uses the selected ascertainment window; artificial regression checks cover both varying and constant calendar-day outcomes. That correction does not authenticate source fields or change any scientific definition.

**The earlier concerns are partly resolved, not all closed.** The remaining work is to bind and reconcile existing accepted evidence for this study. There is no demonstrated need to replace the source or obtain timestamps.

| Earlier concern | Current disposition |
| --- | --- |
| Failed encounter build / unavailable original-key product | Superseded by current upstream engineering acceptance. Reuse those products and receipts. |
| Elapsed-hour timestamps, pH/specimen pairing or medication evidence | Not requirements of the approved PCO₂-only, calendar-day analysis. Date precision is sufficient; no new acquisition is required for this window. |
| Different obesity and gas-testing sampling frames | Intentional distinct estimands, not a source defect. Each frame still needs its own coverage and first-index checks. |
| Downstream missingness, ICD factor decoding, attrition and timing/model checks | Software repairs and artificial checks are implemented. They do not prove that upstream captured absence was distinguished from unknown evidence. |
| Local RDS lineage, original-key mapping and source variant | Still unverified against the accepted product/private receipts. A reviewed version-2 local input manifest has not been completed. |
| Full intended population and chronology | Still needs source reconciliation. Accepted compatibility-backed bundles cover the historical 36-file population; normal gases present locally do not prove complete coverage of all intended testing encounters. |
| Actual testing, gas definitions and units/windows | Still needs reviewed raw-record mapping. Upstream legacy `has_abg` and `has_vbg` are result-derived; they cannot establish testing when results are unusable. Authenticate exact-code specimen designation, valid values, units, maxima and encounter attribution. |
| Derived BMI/adjustment coverage and ICD negative-versus-unknown | Existing derivations are available, but their coverage and capture rules for this study remain unverified. Retain approved derived values and validate against source evidence. |
| Calendar-day summaries | Date precision exists; the separate start-day maxima/availability are not yet authenticated in the local input. Qualified primary cells may proceed with explicitly pending sensitivity cells. |

No private clinical comparison or clinical estimation was performed during this repair. The earlier readiness receipt retains its original code identity and unrun private checks; the focused follow-up receipt records the new source-code identity without rewriting that history. Remaining causal interpretation, selection/missingness and linear-model assumptions are scientific limitations even after source qualification, not automatically remediable data defects.

## Common-index use — 2026-10-14 update

The intended use is now first BMI ≥30 indexing before gas availability, with separate arterial/combined MAR/MNAR projections to a common covariate-complete reference. BMI ≥40 sensitivity restricts those indexes and reuses primary models. The prior frame-specific assessment is retained as dated evidence; it does not qualify this expanded use.

The local host still has no accepted product volume mounted and only the pending example manifest is present. Current upstream main remains `787fba64319c0285244e2e17a9e303c739f31a14`. No private source reconciliation or clinical model has run. The new determination remains **not_evaluated**, not a declaration that accepted products are unsuitable.

| Qualification item | Recommendation / needed evidence |
| --- | --- |
| Exact input and variant | Prefer accepted FULL_DATA/pre-screen evidence; authenticate the actual RDS producer, conversion and original-key mapping. |
| Expanded population | Reconcile BMI ≥30 candidates, especially untested patients and uncertain earlier BMI/chronology, against existing captured source. Compatibility membership alone is insufficient. |
| Keys, dates/settings | Use original keys/crosswalk and reviewed start dates/ED-inpatient coding; preserve conflicts and unresolved first indexes. |
| BMI/adjustment | Retain approved legacy derived values; verify units, timing, dictionaries and coverage. Do not invent a different baseline BMI. |
| Testing/missingness | Distinguish usable evidence, confirmed testing with unusable results, no captured evidence and unknown capture where supported. Testing no longer selects the primary population, but result-derived names still cannot establish performed testing. |
| Gas mapping | Exact raw specimen selectors, normal/boundary/positive/unusable records, units/valid maxima and encounter attribution; temperature-adjusted concepts distinct. |
| ICD negative/unknown | Review captured absence of the five-code composite versus incomplete evidence; required for matched coding comparisons. |
| Calendar-day/frequency | Existing dated records can support start-day summaries. Retain pending sensitivities if unbound; no timestamp/pH pairing requirement. Source-record counts must not be called independent measurements without evidence. |
| Support/interpretation | Report observation patterns and BMI/covariate coverage, unseen levels and shifted-range extrapolation. Demographics-only MAR and MNAR ranges remain assumptions after technical source acceptance. |
| Reviewer evidence | Actual source-custodian binding/mapping review and study-lead interpretation approval; do not fill accepted gates from schema/hash success alone. |

The smallest next clinical action is the expanded study-specific binding on the host with the existing accepted products and private receipts. No replacement export, upstream message or source-definition substitution is presumed necessary. Version-3 manifests explicitly bind the new use; old versions remain for their original runnable workflows. Software/artificial completion is separate from this source determination.

## Source-policy release — 2026-10-15

The owner confirmed ordinary unadjusted PCO₂, authenticated specimen assignment, strict arterial 5–200 and venous 10–250 mm Hg validity intervals, and captured-absence ICD negatives without another-diagnosis requirement. New clinical manifests require `unadjusted_pco2_v1` and matching hashed field evidence. Validity intervals and inclusive outcome thresholds are distinct. Existing bundles retain their recorded source policy.

One concrete mapping concern is demonstrated in the pinned upstream legacy producer: `paco2` pools 2019-8, unspecified-blood 11557-6 and adjusted arterial 32771-8; `highest_paco2` maximizes across that family. Those names alone cannot supply the new ordinary specimen-specific maximum. The adapter uses accepted original-key/legacy BMI/covariate products plus raw exact-code transport to create fresh maxima. Historical producer behavior and its compatibility acceptance are preserved.

The adapter reconciles potential captured-source candidates before gas/BMI/completeness filtering and stops if legacy coverage is incomplete. It preserves unresolved date/type information, verifies source/reader identities and rejects incompatible mappings or interrupted queries. Source-record audits describe preparation scope before index selection; they are not independent specimens or patient prevalence.

The Mini connection again failed hostname resolution. The owner will resume on the home network. No accepted private products/receipts were opened, no study-source acceptance was issued and no clinical model was fitted. Clinical readiness remains **not_evaluated**. The [home-network handoff](CLINICAL_RUN_HANDOFF.md) gives commands and required evidence. Code is released first; actual clinical review is recorded separately.

## 2026-10-15 home-network continuation

Mini access now succeeds through its saved account. A clean checkout of the merged workflow was transferred without copying GitHub credentials. Primary source files match the released bytes; an untouched older report differs only in CRLF/LF representation across hosts. The existing dirty upstream checkout was preserved; four reader modules were exported from the pinned Git revision and their hashes verified.

The saved trusted configuration's accepted receipt digest matches the actual receipt. The installed pinned reader authenticated FULL_DATA and its original string keys; no duplicate original encounter keys were found. Its dictionary stores Stata day-number dates, coded demographic/settings variables and separate race/ethnicity. The preparation adapter now has an explicit decoder for that layout, preserving legacy BMI/age and applying the inherited race/ethnicity precedence. An aggregate-only check reproduced the retained AFTER_EXCLUSION combined categories at every matched key, with unchanged BMI/age values and missingness. Exact receipts and counts remain private. This is field-decoding evidence, not expanded-population acceptance or a clinical result.

The broad candidate audit exceeded internal scratch capacity; a retry with external scratch reached the RAM cap. Accumulating all historical consensus rows then exhausted the bounded scratch cap. These are execution failures, not coverage evidence. The preparation path now streams disjoint patient-hash partitions, applies the same study scope only after consensus, checks coverage in SQL and retains only covered candidates. Its pinned-upstream artificial parity check preserves duplicate/conflicting/unresolved records. Named unknown settings mapped to `NA` are retained and written as true missing values.

A separate bounded check completed on one prespecified patient-hash partition, using every raw encounter row for those patients before consensus. It demonstrated captured keys with **known 2022 start, EMER/IMP setting and an adult birth-year proxy** that have no accepted legacy FULL_DATA mapping. The proxy identifies potential adult eligibility, not exact age at encounter. This proves a mapping gap before exact age/BMI eligibility; it does not establish that those patients have BMI ≥30. Exact counts, file identities and query receipts remain private. The audit subset excluded unadjudicated named-unknown settings; its counts are not full-population totals or a complete candidate inventory. The existence of uncovered potential candidate keys does not depend on resolving that additional vocabulary.

Clinical use is **blocked by unavailable approved legacy fields for broader candidates**. Existing raw source access and historical product acceptance remain useful; neither has been rejected wholesale. A separately named study mapping using existing source records is the smallest corrective action. Do not rebuild/overwrite accepted products, request a replacement export by default, exclude uncovered candidates or reinterpret them as BMI <30. See [the field-specific handoff](COMMON_INDEX_SOURCE_GAP_HANDOFF.md).

The Mini also lacks several required R dependencies. Existing framework R passes the common-index nonfigure/nonloader checks; missing `haven` and `ggplot2` prevent the other groups and full preparation verification there. No dependency was installed. Local checks pass 24 shared and 14 common-index groups, 13 preparation cases (one additional SQL case requires the upstream environment), 9 Stata source/launcher cases and historical R checks. The additional SQL case passes on the Mini. Current full-database hashing, gas/specimen/unit/ICD/window qualification and clinical estimation remain unrun; no acceptance manifest or clinical bundle was issued.

### 2026-10-15 isolated R setup completed

The owner subsequently authorized installation into an isolated project library. Framework R 4.6.1 now loads all seven primary dependencies; `haven`, `ggplot2`, `knitr`, `rmarkdown` and required dependencies were installed as compatible macOS binaries under ignored `artifacts/triangulation/runtime/`. Existing system-library file hashes are unchanged. The Mini passed all 24 shared and 14 common-index artificial check groups. The installation receipt, package versions, session information and test logs are retained privately; the clinical handoff records activation. No clinical input was opened or model run, and no full Mini report render is claimed. This resolves the R dependency gap only; the broader mapping and other source gates above remain open.

## BMI source clarification — 2026-10-15

A focused read-only source comparison on the Mini supports the owner's interpretation of the legacy cutoff. In the preserved original Stata `stata/do/10_preprocessing.do` at `5ada7194d40f6006e5563c3592727861336ce2c8`, line 504 recodes recorded BMI ≥50.1 to missing with the explicit comment `BMI data is truncated at 50 from TriNetX`. Lines 512 and 536–546 apply the prior-BMI screen and current → prior → height/weight-calculated hierarchy. This is direct evidence of the original rule's stated purpose.

At accepted upstream `787fba64319c0285244e2e17a9e303c739f31a14`, [the Python legacy cleaner](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/src/trinetx_preprocessing/encounters/legacy/per_file_cleaning.py#L977) reproduces the recorded/prior cutoffs and hierarchy. The final height/weight-derived BMI is not subject to the same 50.1 cutoff. This establishes matching source logic; it is not a new patient-level parity check and does not show a BMI port defect.

There is also a distinct earlier [normalized-vitals layer](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/src/trinetx_preprocessing/transform/vitals.py#L120) with a BMI range of 10–100. The generic [raw source transport](https://github.com/reblocke/trinetx-preprocessing/blob/787fba64319c0285244e2e17a9e303c739f31a14/docs/CALENDAR_SOURCE_TRANSPORT.md) retains captured values, text, units and provenance. The broader mapping must state which layer it consumes rather than treating normalized values, legacy-derived BMI and raw records as interchangeable.

TriNetX's [published de-identification summary](https://trinetx.com/wp-content/uploads/2022/04/TriNetX-Empirical-Summary-by-Brad-Malin-2020_branded.pdf) describes truncating extreme physical-characteristic distributions. Its indexed text was retrieved; direct PDF retrieval returned 404 during this check. This general description does not specify the BMI cutoff or sentinel encoding in the present snapshot. The source sidecar records product/schema identities, not an exact BMI masking rule. No new raw-vital distribution or snapshot-specific masking audit was run here. Do not infer that all numeric values above 50 are genuine, or that every value equal to 50 is censored, solely from this documentation.

**Revised interpretation of the mapping gap:** available records still need to be mapped for keys outside historical compatibility membership. After that search, absent usable BMI is accepted missingness, not failed source acceptance by itself. The source cohort requires valid BMI from the encounter or earlier, with height/weight calculation permitted and statistical imputation prohibited. Retain BMI ≥30 for study inclusion. Masked/censored or unusable records remain distinguished from exact values. The owner's proposed upper limit of about 120 applies conditionally to authenticated noncensored high values in a separately identified mapping; it is not a silent repair to the accepted historical product.

The current downstream selector also needs an explicit missingness distinction: earlier genuine BMI absence should not block a later first valid-BMI encounter, whereas incomplete source mapping or unresolved relevant chronology still can. This code change and expanded mapping have **not** been implemented during this read-only investigation. [The revised plan](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md#valid-bmi-mapping-revision--2026-10-15) identifies the changes and checks. No clinical source acceptance or estimates are asserted.

## Expanded source qualification — 2026-10-16

The broader mapping is implemented in a separate Mini worktree/branch at upstream
`72c91a21d4ff65aadca970cf60a168971a8c4a6e`. It uses captured source records,
original keys and the approved current/prior/calculated hierarchy, without
syndrome, gas, BMI-completeness or adjustment-completeness filtering. Every
scoped candidate has a mapped row. Genuine missing BMI and unresolved evidence
are distinct. Products, source hashes, queries and receipts remain in owner-only
external storage, with historical products/RDS preserved.

Actual unit/specimen and demographic vocabularies, captured-file inventory,
target diagnosis systems and full source identity were reviewed. A full
canonical hash completed with unchanged file identity. The same R selector is
used in whole-patient batches before gas extraction, retaining the original
aggregate census with the resolved-index input. Independent SQL reproduces the
first indexes, unresolved cases and ties, and reports zero BMI state, prior-date,
reported-rounding or calculation disagreements.

The historical overlap audit caught a draft mapper precision defect. Inherited
float16/CSV transport alone was insufficient: float32 input/intermediate storage
must precede Stata rounding. The fractional failing case was retained and the
ordering repaired before qualification or model fitting. In the corrected
mapping, identical selected source components reproduce historical BMI exactly.
Sex, combined race/ethnicity and region agree at all overlapping keys. Age
differences are fully explained by start-year versus historical qualifying-year
anchoring. Remaining current-BMI differences have different measurement dates;
per-candidate prior availability intentionally differs from the old anchor.
These are declared timing changes, not a historical producer defect.

No recorded source BMI exceeds 50.1. The conditional ceiling near 120 is not
activated. The distribution does not prove whether the observed value 50 is
top-coded; the approved legacy screen is retained without inventing exact masked
values. Calculated BMI remains outside that recorded-BMI cap. No statistical BMI
or covariate imputation was introduced.

**Automated qualification completed:** fresh typed preparation, primary raw-source
checks and the prepared-field extension all pass. Independent ordinary gas
maxima, testing states, calendar-day maxima/availability and the five-code
captured-absence composite have zero disagreements. All prepared base fields
match the mapped source, and every CSV/RDS field matches exactly. The earlier
native qualifier source is retained with its hash; the prepared-field extension
was checked separately without repeating unchanged raw-gas queries.

The identity-bound preflight reports
`reviewed_primary_input_identity_and_mapping_passed`, with no models fitted.
The seven primary gates and calendar-day module have passing automated evidence.
The source-freeze readiness receipt validates as **ready_with_limitations** under
the current conservative rules. Its scope is the authenticated typed source for
the approved documented-evidence analysis, not clinical results or human
scientific approval. The original pending manifest remains unchanged; a
separately named automated-reviewed manifest binds the completed evidence.

The actual expanded source has material unresolved-index attrition, especially
from earlier unknown encounter settings and same-day earliest encounter ties.
Counts and overlapping reasons are retained privately. The current conservative
rule is unchanged; switching to first **documented** ED/inpatient would alter the
selection target and requires an explicit decision. Missing BMI alone does not
cause that block after completed mapping. Causal interpretation, MAR and MNAR
credibility remain scientific limitations after source acceptance.

Actual measurement-age checks also show that some prior BMIs and calculation
components are old. Current-encounter measurements can occur after admission.
The agreed availability rule imposes no recency cap and permits within-encounter
evidence, so these are recorded limitations rather than failed extraction or
permission to impute. Keep component dates and decide whether to add a
prespecified one-year sensitivity before fitting. No new recency rule was
silently adopted. See [the decision ledger](DECISIONS.md#remaining-source-related-choices--2026-10-16).

The new code remains on implementation branches. Publish/review/synchronize the
final code before clinical estimation; if scientific definitions or source
derivations change, repeat dependent qualification and preserve these receipts.
No clinical model, clinical exhibit or scientific approval is claimed here.

## Original-list qualification correction — 2026-10-16

The raw captured source includes history and several care-setting values. `LAB`
was never a candidate setting in the broader mapping; `UNKNOWN` was admitted as
potential membership and could block indexes. This was not an absent-type-column
problem in the original cohort and is not a follow-up-specific designation.

The corrected source universe is original accepted FULL_DATA ED/inpatient keys.
Verify the historical first-encounter flags independently and select the first
BMI-eligible acute encounter within that list. Raw records outside it cannot add
candidates or cause index attrition. Prior BMI/components can still come from
broader captured history under the approved availability policy. Preserve raw
conflicts within original keys as audit evidence and require captured support
for their original setting. No AFTER_EXCLUSION imputation is imported.

Fresh evidence must bind the original acceptance receipt, source/policy/input
hashes, first-flag comparison, exact mapped/original key equality, selected indexes
and gas/ICD/calendar-day checks. The earlier broader receipts remain immutable
and do not transfer source acceptance to this corrected population.

Current status: fresh original-list mapping/preparation and all 30 independent source checks pass. Automated source review, human scientific review and clinical result qualification remain separate.

### Corrected source closeout

Original-list mapping, fresh preparation, all thirty independent checks and
identity-bound preflight pass. The nineteen-field CSV/RDS comparison is exact.
The independent source ledger reproduces original first flags, mapped-original
key equality, captured setting support, raw chronology and selected-index census.
Historical/new first-index differences are fully explained by ambulatory/BMI
eligibility or the qualifying-date versus captured-start ordering. Outside-list
unknown-setting blockers are absent; within-list uncertainty remains explicit.

The private `original-automated-source-review.json`,
`original-readiness-assessment.json`, reviewed manifest and original-scope closeout
bind the actual input, config, source, policies, code and supporting checks.
Readiness is **ready_with_limitations** for this selected-cohort source use.
Preflight `preflight-20261016T173924-11359` verifies identity/mappings without models.
Human scientific review, clean merged release and clinical estimation are not
claimed. No additional export is indicated by these checks.

## 2026-10-17 — Historical RFS metadata extension

Read-only inspection authenticated the six FULL_DATA family indicators and raw
race/ethnicity dictionaries. The accepted producer revision is recorded in the
private integrated acceptance receipt; its cleaner creates family membership and
its merger converts nonmembership to zero. These flags establish source-file
representation, not exhaustive clinical criterion satisfaction. No separate
obesity-only indicator exists in the inspected accepted product schema.

A fresh schema-4 input preserves exact clinical keys/indexes, BMI, covariates and
outcomes from the hash-bound prior version-5 run. Metadata join tests and source
preflight pass; no replacement export or preprocessing rebuild was required.
BMI provenance comes from the existing accepted mapper. The new RFS evidence and
pre-index companion have their own hashes. An initially selected stale broader
mapping was rejected by the exact-key check; the intended original-list mapping
was then bound to the prior run. This was configuration correction, not a change
to the accepted source population.

Remaining evidence limits: historical exact extraction thresholds/windows and
individual obesity triggers are not inferred from current producer defaults or
final BMI. Outcome-incorporation/depletion is audited from the fixed indexes.
Clinical estimation, numerical review, layout QC and investigator scientific
approval retain separate states. Other-project keyed decomposition and the
unidentified historical diagram discrepancy remain explicitly unassessed.

### Released RFS source and execution checkpoint — 2026-10-17

Final preflight and one clinical estimation completed on the clean Mini checkout
at merged revision `4fdf4eb`. Exact prior clinical fields and indexes remain
unchanged. All bound source-evidence and input hashes still match after execution;
all 162 saved-aggregate numerical checks pass. Source acceptance is for documented
historical membership and the approved observed-outcome analysis, not exhaustive
clinical criterion ascertainment or causal interpretation.

Obesity-only outcome evaluability is severely depleted. Separation and rank
deficiency remain explicit model statuses, with descriptive counts preserved;
nonestimability is not evidence of no BMI association. The prespecified
all-OBESITY supporting population overlaps primary and does not replace that
sensitivity. Historical exact-query/trigger limits, external-project keyed
decomposition and investigator scientific review remain unresolved as described
above. No replacement export is indicated by the completed checks.

### Obesity-only selection interpretation — 2026-10-17

Obesity-only is now a descriptive evidence audit. Removing gas-related entry
pathways selects against gas evaluability; it does not create an independent
physiological comparison population. Historical source-file membership and raw
current-encounter gas capture are distinct. Sparse residual gases remain in the
counts; their exact historical extraction explanation is unadjudicated. Do not
force these counts to zero or reconstruct entry flags from outcomes.

The qualified schema-4 input, accepted original-key linkage, clinical fields and
indexes remain unchanged. No new export or mapping rule is required for this
hierarchy change. New schema-7 estimation must verify input/evidence hashes and
primary-estimate invariance; previous execution receipts retain their old scope.
