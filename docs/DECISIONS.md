# Decisions and remaining uncertainty

The [current guide](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md) defines executable
science; [source contract](SOURCE_CONTRACT.md) defines acceptance. This compact
ledger separates decisions from dated execution receipts. Full earlier wording
and implementations are recoverable through the [archive index](../archive/README.md).

## Settled decisions

| Date | Decision |
|---|---|
| 2026-10-13 | Secondary scenario: observed BMI >30 minus exactly one; BMI=30 unchanged, no floor or reselection. Supersedes both BMI-to-40 and unrestricted minus-one proposals. |
| 2026-10-14 | Select a common first BMI≥30 index before gas availability/adjustment completeness, replacing independently indexed sampling frames. |
| 2026-10-15 | Ordinary unadjusted PCO₂, authenticated specimen, explicit units, strict arterial/venous validity. Unspecified/adjusted records do not silently become primary gases. ICD captured absence requires complete available capture. |
| 2026-10-15–16 | Available current/prior reported BMI or observed height/weight calculation; no statistical imputation or recency cap. Preserve inherited mask screens, arithmetic and rounding. Completed missing differs from unresolved source. |
| 2026-10-16 | Restrict candidates to original selected FULL_DATA ED/inpatient keys. History supplies prior measurements, not additional index candidates. Historical first flags and new first BMI-eligible indexes are distinct. |
| 2026-10-16 | Curve-first primary scientific report plus complete cohort/model audit; fixed spline strategy and inherited adjustment. Named BMI policies are secondary, not the primary scientific organization. |
| 2026-10-16 | Standardize gases to outcome-observed populations and ICD to known capture. Remove full-cohort MAR/MNAR projection; IPW deferred. Retain timing, matched and same-sample linear sensitivities. |
| 2026-10-17 | Partition historical RFS membership after the fixed index. Any non-OBESITY positive enters primary, including overlaps. Unknown is not zero; all-zero discrepancies remain visible. |
| 2026-10-17 | Obesity-only becomes a descriptive source/evidence audit, with no adjusted model, curve, PIF or weighting analysis. This supersedes the initial two-group fitting proposal. |
| 2026-10-17 | Keep primary current-measurement models using the primary basis and overlapping all-OBESITY supporting models using their own basis. Current measurement never promotes a later index. |
| 2026-10-17 | Confine obesity-only to flow/audit, not scientific comparisons. ICD capture is a count separate from positivity; omit constant availability curves. Print CIs beside estimated percentages. |
| 2026-10-17 | Adopt upstream mapper `751d794` and exact corresponding module hash together. Previously accepted products keep their original producer/runtime identities. |
| 2026-10-17 | Remove obsolete compatibility layers and duplicate historical source trees. Git remains the historical source archive; preserve raw inputs, accepted products, clinical bundles/reports and immutable Stata original. E2E artifacts become the primary verification path. |
| 2026-10-18 | Owner reconfirmed November 4, 2026 as the ATS 2027 deadline and granted provisional scientific approval of the current analysis. Figure selection was still pending at that point (subsequent choice below). Do not draft abstract text yet; submission is not authorized by this approval. |
| 2026-10-18 | Owner subsequently selected **primary/F1-B and primary/F2** as the main figures for now, superseding the earlier F1-A recommendation. This is the working figure selection; final submission packaging remains separate. Provisional scientific approval and the instruction to defer abstract drafting remain in effect. |
| 2026-10-18 | Owner clarified that analysis outputs—reports, figures and aggregate result tables—may be included in Git. Raw and patient-level data remain excluded. This supersedes the earlier blanket instruction that all aggregates remain private; the current ignored-output location is a packaging issue. |
| 2026-10-18 | Owner authorized versioning the clinical reports, B/F2 figures, gallery and aggregate tables, with README/LLM navigation and email-ready PDFs, followed by review and PR release. `results/2026-10-18/` is a reading snapshot of the existing run, not a new analysis. Raw/patient data stay excluded; abstract drafting remains deferred. |

Current machine identities are input schema 4, aggregate schema 10 and
`bmi_hypercapnia_rfs_curve_audit_v5`. The original clinical snapshot retains
schema 7 / v2; older bundles are rejected by the current renderer. Numeric demographic categories remain
unchanged; retained Unknown categories are nonmissing, and the White reference
includes unknown ethnicity. No causal-prevention/incidence claim is authorized.

## Still requiring evidence or investigator interpretation

| Item | Present treatment; what would resolve it |
|---|---|
| Historical source triggers and residual gases | Keep extraction membership distinct from current outcome/acquisition evidence. Authenticate the actual historical query/trigger before explaining residual gases; do not recode from outcomes. |
| Prior BMI/component age | Retain the approved availability hierarchy without a recency cap and report aggregate lags/current-measurement sensitivity. A new cutoff is a scientific decision requiring dependent qualification. |
| Unresolved within-list eligibility/ties | Preserve explicit unresolved states, no later replacement. Any alternative tie/anchor rule needs approval and fresh reconciliation. |
| Cross-project count differences | Additional original-key decomposition and the historical diagram arithmetic question remain unassessed; aggregate counts alone cannot attribute differences to BMI. |
| Interpretation | Owner granted provisional scientific approval on 2026-10-18 for the current analysis. Selection assumptions, causal-language limits and lack of transport to untested patients remain unchanged. Submission approval remains separate. |
| Final presentation | F1-B and F2 selected by the owner for working main use on 2026-10-18; A/C remain alternatives. The saved scientific PDF still embeds A with the same estimates; use standalone B for the selected layout. Final venue-size/portal checks and submission packaging remain outstanding. |

## Execution history, without compatibility promises

- `f18d383`: first curve/audit clinical release with full-reference gas projections.
- `ca24564`: observed-population analysis replacing MAR/MNAR projections.
- `4fdf4eb`: initial RFS partition and metadata-qualified input.
- `043fea6`: current descriptive-only obesity hierarchy and schema-7 clinical run.
- `0e5641f`: committed record of that run and review; the later presentation
  refinement used the same immutable aggregates and changed no clinical estimate.

Actual source/run/render receipts bind hashes, code, scope and failures privately.
The cleanup does not issue new source acceptance or scientific approval and does
not rerun clinical estimation. `WORKLOG.md` records recent execution and links the preserved earlier log.

## 2026-10-20 — Paired-ABG acidemia supplement

Approved two nested same-sample arterial endpoints on identical primary patients:
PCO₂ ≥45, and PCO₂ ≥45 with pH <7.35. Both use the existing index, primary
numeric spline basis and adjustment. No new PIF or automatic timing/population
duplicates. The [supplement specification](PAIRED_ABG_SUPPLEMENT.md) controls the
source gate. Date-only co-occurrence is not pairing. If sample linkage is absent,
retain unavailable secondary positions and report feasibility; do not force a
clinical result. Authorized review/commit/push/PR/squash merge and clinical
execution only after pairing qualifies. New scientific interpretation remains
pending; original provisional approval and B/F2 selection are unchanged.


### 2026-10-20 accepted-source feasibility

The actual accepted-source query covered 223,514 study-input encounter keys and
541,828 selected gas records: 192,909 ordinary arterial PCO₂ and 145,993 arterial
pH records. All queried records had date-only precision. Specimen, panel,
accession, collection-time and dedicated result_status/result_version fields had no
populated values. Generic status/order_status columns exist but do not have
authenticated correction semantics. Record counts are not distinct patient or draw counts.
Same-sample linkage is therefore unavailable, not an assessed zero-pair result.
No clinical supplemental models are fitted; no approximate pairing is adopted.
The existing clinical snapshot and B/F2 remain unchanged. See the
[separate feasibility report](../results/2026-10-20-paired-abg/README.md).

## 2026-10-20 — Recorded-day co-occurrence replaces unavailable pairing

The owner selected any co-observed recorded date within the existing index
encounter and retained 6.5<pH<7.8 with acidemia pH<7.35. Hypercapnia is ≥45 mm Hg
on co-observed days; the narrower endpoint requires a low pH on the same date,
potentially from another sample. Different dates cannot be combined. No index
reselection, primary model/PIF change, supplemental PIF or abstract drafting.
The two optional positions use the same primary patients/reference and numeric
spline basis. The new module is `same_day_arterial_cooccurrence_v1`, aggregate
schema 9 / analysis v4. Historical pairing reports and the primary B/F2 snapshot
remain immutable. Source qualification, estimation, numerical/visual review and
investigator approval will be recorded separately after release.

### Recorded-day clinical execution

PR #19 merged the software at `b89d485`. Source qualification and preflight passed
on the Mini; the fresh run `curve-analyze-20261020T174425-15236` completed once from
that clean merged revision. Enrichment preserved every original field and index.
Both new models succeeded on the same 22,195 primary patients, with 11,669
co-observed-day hypercapnia events and 8,809 same-day hypercapnia–acidemia events.
The supported saved BMI grid has no fitted curve crossings. No supplemental PIF
was added. Original samples, coefficients, covariance, curves, fixed contrasts,
PIFs and contribution quantities agree with the prior run within 1e-10.

The [new snapshot](../results/2026-10-20-same-day-abg/README.md) is separate from the
unchanged original and pairing-feasibility snapshots. Source acceptance and
numerical reconciliation do not confer investigator interpretation or S1 approval;
those remain pending. B/F2 remain the selected main figures, and abstract drafting
remains deferred.

## 2026-10-20 — Joint same-day components replace nested binary comparison

Owner approved a single three-category multinomial spline and stacked full-range
S1. Any eligible hypercapnia–acidemia day takes priority over days without acidemia.
The other hypercapnic category means without *documented same-day* acidemia, not
physiological absence or chronic compensation. Same input, fixed indexes, primary
basis/covariates and supplemental reference; no new extraction or PIF. Primary
analyses and selected B/F2 remain unchanged.

Schema 10 / `bmi_hypercapnia_rfs_curve_audit_v5` replaces schema 9's two binary
supplemental models without relabeling historical bundles. Full joint covariance
supports coherent probabilities and direct signed comparisons of component
changes. BMI 40–45 remains only a descriptive summary; the full observed range
and every supported five-unit interval are reported with local-sparsity flags.
The stacked upper band is its thickness, not its boundary; common-baseline curves
retain component intervals. Source, numerical, visual and scientific review are
separate. Clinical execution and the new S1 approval remain pending.
