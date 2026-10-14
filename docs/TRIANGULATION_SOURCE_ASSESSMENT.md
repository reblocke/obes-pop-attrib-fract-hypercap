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
