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

Current machine identities are input schema 4, aggregate schema 7 and
`bmi_hypercapnia_rfs_curve_audit_v2`. Older results keep their original labels and
are rejected by the current renderer. Numeric demographic categories remain
unchanged; retained Unknown categories are nonmissing, and the White reference
includes unknown ethnicity. No causal-prevention/incidence claim is authorized.

## Still requiring evidence or investigator interpretation

| Item | Present treatment; what would resolve it |
|---|---|
| Historical source triggers and residual gases | Keep extraction membership distinct from current outcome/acquisition evidence. Authenticate the actual historical query/trigger before explaining residual gases; do not recode from outcomes. |
| Prior BMI/component age | Retain the approved availability hierarchy without a recency cap and report aggregate lags/current-measurement sensitivity. A new cutoff is a scientific decision requiring dependent qualification. |
| Unresolved within-list eligibility/ties | Preserve explicit unresolved states, no later replacement. Any alternative tie/anchor rule needs approval and fresh reconciliation. |
| Cross-project count differences | Additional original-key decomposition and the historical diagram arithmetic question remain unassessed; aggregate counts alone cannot attribute differences to BMI. |
| Interpretation | Source acceptance/numerical agreement do not validate selection assumptions, causal language or transport to untested patients. Investigator interpretation and submission approval remain separate. |
| Final presentation | F1-A preferred, B/C retained. Existing scoped QC is recorded; final venue-size/portal checks and investigator figure approval remain outstanding. |

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
