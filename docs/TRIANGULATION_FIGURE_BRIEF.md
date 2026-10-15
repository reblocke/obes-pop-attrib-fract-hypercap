# Common-index figure brief and QC

Approved design: 2026-10-14. Audience: clinical collaborators and abstract/manuscript reviewers. Purpose: compare absolute and relative BMI-shift contrasts, then show the sensitivity to assumptions about unobserved gases. Unit: one resolved first BMI ≥30 index per adult patient, with a common covariate-complete reference.

Title: **Hypercapnia probability under a one-unit BMI reduction above 30**. No causal prevention or incidence claim. Arterial and combined criteria remain separate; model N and reference N differ.

| Candidate | Main comparison | Included rows |
| --- | --- | --- |
| A — preferred paired forest/table | Retrieve absolute/PIF, confidence limits and denominators | Four primary encounter BMI ≥30 observed/MAR benchmarks |
| B — outcome-first panels | Compare benchmark versus projection within evidence criterion | Exact same four rows and numerical values as A |
| C — assumption maps | How unobserved risk/BMI gradient changes conclusions | Separate arterial/combined 5×3 grids on absolute/PIF scales; MAR anchor outlined |

C is not a confidence-interval display or an independent replication. It shows fixed assumption scenarios, not clinically validated bounds. A is preferred for the main result; C supports interpretation. BMI ≥40, timing and matched ICD details remain in report/supporting ledgers.

Preserve paired probabilities, difference per 1,000, PIF and conditional model-based 95% intervals where shown. Axes include zero and every finite endpoint, retaining negative values. Unknown evidence stays unknown; pending/nonestimable positions have no invented glyphs. Available combined negatives do not establish unmeasured-specimen negativity. Ordering is arterial, combined; observed, MAR. Never sort on significance or apparent agreement.

Export editable R sources, SVG/PDF masters, 300-dpi PNG/JPG at 190-mm width, with at least 9-point data/caption labels. Explicit candidate heights are recorded in figure_receipt.json. Use grayscale-safe open/filled markers and direct labels. Numeric columns lie outside quantitative axes; small values use sufficient precision.

Apply figure-and-medical-illustration-qc with the existing manifest columns. Inspect every vector/raster export and report page at intended size and grayscale. Check symbols, tick collisions, long counts, nonestimable text, interval visibility, exact numerical agreement and caption/alt text. Record actual coverage and retained failures separately from planned checks. Source/clinical acceptance and submission remain separate; artificial numbers must be prominently labeled.
