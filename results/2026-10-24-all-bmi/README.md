# All-valid-BMI integrated clinical analysis — 2026-10-24

This is the current **aggregate reading snapshot**, not a runnable bundle or a
clinical input. It joins overall hypercapnia, same recorded-day physiological
components and ICD acuity components in one scientific report. All three families
repeat in the nested BMI≥30 secondary population.

## Read and share

- [Scientific mini-paper PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html).
- [Complete audit PDF](bmi_hypercapnia_audit.pdf) / [HTML](bmi_hypercapnia_audit.html).
- [Eight key figures with full captions](key_figures.pdf) / [comparison gallery](gallery.html).
- [All 63 aggregate tables](TABLES.md), [table index](table_index.csv), [captions and alt text](captions.csv).
- [Review states](review_status.json), [visual inspection scope](verification/visual-review.json),
  [source qualification](verification/qualification.json), [numerical review](verification/numerical-review.json),
  [prior-run reconciliation](verification/prior-run-reconciliation-annotated.csv).

The complete audit is intentionally exhaustive; use the scientific report and
figure booklet for first reading. Download the entire directory for local HTML
assets. There are no patient rows, original keys, patient dates, model frames, predictions
or model objects in this packet. Aggregate output publication is owner-authorized.
New interpretation and figure approval remain pending. No abstract was drafted.

## Population and scenario

Of 427,079 resolved all-valid-BMI indexes, 380,206 have authenticated non-OBESITY
source support and form the primary analysis. The 46,873 obesity-only indexes
remain audit-only; no RFS membership is unresolved. There are 7,152 unresolved
first indexes before partitioning, including 4,300 earliest-date ties. The BMI≥30
secondary contains 175,271 primary patients at their same new index.

Observed BMI>30 decreases by exactly one; BMI≤30 is unchanged. The whole model
reference remains in the denominator. Below-30 baseline burden is retained, while
its paired scenario difference and variance contribution are exactly zero.
Gas models use outcome-evaluable patients; ICD uses complete capture. These are
selected source-entry populations, not all acute-care patients or untested patients.

## Primary modeled burden

The table uses the encounter-wide binary spline models. Intervals are model-based
95% intervals conditional on the empirical reference and fixed basis. Full
probability intervals and shift-eligible shares are in `tables/policy_totals.csv`.

| Outcome | Model/reference N | Observed (95% CI) | Shifted (95% CI) | Difference per 1,000 (95% CI) | PIF (95% CI) |
|---|---:|---:|---:|---:|---:|
| Arterial | 71,318 | 46.258% (45.897–46.619%) | 45.790% (45.428–46.153%) | 4.675 (4.406–4.943) | 1.011% (0.952–1.069%) |
| Arterial or venous | 126,074 | 41.008% (40.739–41.277%) | 40.663% (40.394–40.932%) | 3.447 (3.246–3.649) | 0.841% (0.791–0.890%) |
| ICD composite | 380,206 | 4.225% (4.162–4.289%) | 4.102% (4.041–4.165%) | 1.226 (1.170–1.282) | 2.902% (2.775–3.028%) |

PIF is the relative change in modeled probability under this scenario, not a
causal treatment effect. No component-specific PIFs are added. Same recorded-day
co-occurrence is not verified same-sample pairing; without documented acidemia
does not establish compensation. ICD categories describe codes, not physiological
severity. Sparse BMI tails and source/measurement selection remain important.

## Verification and historical comparison

The source passed all 46 discrepancy checks; clinical estimation ran once from
merged code `75e55eee42979904a04cdb5a3a529ed15bfb6025`. Thirty-five model positions
fitted successfully. One ICD-*capture* observation position is constant because
capture is 100%; ICD positivity is 4.225% in the primary population.
All six joint component fits succeeded. The numerical receipts contain 167
registered checks plus 3,472 independent aggregate arithmetic checks.

Broader eligibility changes selection, not merely cohort size. Relative to the
authenticated prior input there are 203,784 new patients, 219 prior-only patients
(all newly unresolved earliest ties), 1,601 changed indexes and 177 changed-index
RFS assignments. Analysis BMI, adjustment and outcome fields agree on common keys.
Exact decimal transport corrects final-bit differences only in raw reported BMI
and weight provenance; the original comparison receipt and separate explanation
are retained. No historical result or input was rewritten.

Source acceptance, automated numerical review, scoped visual review and
investigator scientific approval are distinct. See `review_status.json` for the
PDF page counts and exact review state; automated geometry covered every page,
while the visual receipt identifies the pages/templates actually inspected.

The reports preserve the immutable bundle's creation-time review flags, which
remain false. The later numerical and visual receipts provide the current review
state without mutating that bundle. Identical descriptive profiles are printed
once with explicit stage-to-summary mappings; the full CSVs and independent
reconstruction in `verification/summary-coverage-review.json` retain every value.
In the inherited dictionary, index-day gas wording referring to "collected" values
must be read as **recorded result date equal to encounter-start date**, as specified
in Methods and the source contract; collection timestamps are not authenticated.

## Reproduce and verify

The analysis/report sources are at the recorded code revision in `R/`, `scripts/`
and `reports/`. Preparation and qualification use the private accepted source as
documented in the repository README. From the protected saved run:

```bash
make render RUN="artifacts/triangulation/curve-analyze-20261024T123452-59248"
```

Rendering reads aggregates and does not refit. The public packet cannot replace
that protected bundle. The caption booklet can be reconstructed from its unchanged
figure PDFs with `reproduce_caption_booklet.py <this-directory>` using installed
pypdf/reportlab and the recorded macOS Unicode font. No automatic installation.

Verify all packet files from the repository root:

```bash
python3 - <<'PYVERIFY'
from pathlib import Path
import hashlib, json
p = Path('results/2026-10-24-all-bmi')
m = json.loads((p / 'manifest.json').read_text())
for name, entry in m['files'].items():
    assert hashlib.sha256((p / name).read_bytes()).hexdigest() == entry['sha256'], name
print('All snapshot hashes match')
PYVERIFY
```

The source bundle has schema 13 / `bmi_hypercapnia_rfs_curve_audit_v8`; input schema 5.
Historical runtime bundles are rejected, not migrated. Earlier published snapshots
remain unchanged and retain their original BMI-restricted design and approval state.
