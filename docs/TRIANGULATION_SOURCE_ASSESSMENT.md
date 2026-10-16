**Current use, 2026-10-14:** common first BMI ≥30 indexing and separate arterial/combined projections. The dated October 13 assessment below is preserved; the October 14 qualification ledger at the end governs the expanded use. No clinical input acceptance has been established.

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
