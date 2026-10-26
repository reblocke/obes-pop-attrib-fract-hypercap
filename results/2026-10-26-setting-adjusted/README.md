# Encounter-setting-adjusted clinical analysis — 2026-10-26

This aggregate reading snapshot adds categorical index encounter setting to every
registered model: **EMER (emergency) reference; IMP (inpatient)**. It includes no
BMI-by-setting interaction, weighting, new selection or new source export. Input
schema 5 is unchanged; results use schema 14 / `bmi_hypercapnia_rfs_curve_audit_v9`.
The October 24 snapshot remains immutable and retains its earlier adjustment.

## Read and share

- [Scientific mini-paper PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html).
- [Complete audit PDF](bmi_hypercapnia_audit.pdf) / [HTML](bmi_hypercapnia_audit.html).
- [Nine key figures with full captions](key_figures.pdf) / [gallery](gallery.html).
- [Aggregate table navigation](TABLES.md), [table index](table_index.csv),
  [captions and alt text](captions.csv).
- [Review states](review_status.json), [visual review](verification/visual-review.json),
  [setting coverage](verification/setting-coverage-review.json),
  [old/new reconciliation](verification/comparison-receipt.json).

For email, start with the scientific PDF and figure booklet. The exhaustive audit
is much larger; its complete HTML and CSVs offer searchable alternatives. Download
the whole directory for local HTML assets. There are no raw inputs, patient rows,
original keys, patient dates, predictions, model frames or fitted objects here.
This is a reading snapshot, not a runnable clinical bundle. Investigator
interpretation and approval of the new figures remain pending. Abstract files are
unchanged; no submission has been performed.

## Population and adjustment

The cohort, indexes, outcome counts, model/reference Ns and numeric spline bases
match the authenticated October 24 run: **380,206 primary patients**, including
**71,318 arterial-evaluable**, **126,074 combined-gas-evaluable**, and **53,607
recorded-day arterial PCO₂/pH-co-observed** patients. The same-index BMI≥30 secondary
contains **175,271** patients. The primary reference contains 156,509 EMER and
223,697 IMP encounters, with no missing setting. Gas populations overlap.

Models retain linear age, inherited sex, race/ethnicity and geographic region,
and add observed setting. Each population keeps its fixed three-degree-of-freedom
BMI spline. Standardization and the BMI scenario retain each patient's setting.
All 35 fitted positions contain setting coefficients and EMER reference coding;
the 36th position is constant ICD *capture*, not constant ICD positivity.

## Modeled burden

Observed BMI>30 decreases by exactly one unit; BMI≤30 is unchanged. No floor or
reselection is applied. Each entire model reference remains in its denominator.
Intervals are model-based 95% intervals conditional on the empirical reference
and fixed basis.

| Outcome | Model/reference N | Observed, % (95% CI) | Shifted, % (95% CI) | Difference/1,000 (95% CI) | PIF, % (95% CI) |
|---|---:|---:|---:|---:|---:|
| Arterial | 71,318 | 46.258 (45.897–46.619) | 45.790 (45.428–46.153) | 4.675 (4.407–4.943) | 1.011 (0.952–1.069) |
| Arterial or venous | 126,074 | 41.008 (40.740–41.276) | 40.666 (40.398–40.935) | 3.418 (3.217–3.619) | 0.833 (0.784–0.883) |
| ICD composite | 380,206 | 4.225 (4.162–4.288) | 4.104 (4.043–4.166) | 1.207 (1.152–1.262) | 2.858 (2.733–2.982) |

The BMI≥30 secondary PIFs are 2.029% (1.639–2.418%) for arterial, 1.932%
(1.606–2.256%) for combined gas and 5.715% (5.169–6.259%) for ICD. These
population-specific estimates are not formal tests of differences between groups.

Setting adjustment changes the principal estimates little. The primary arterial
PIF remains approximately 1.01%; combined gas changes from 0.84% to 0.83% and
ICD from 2.90% to 2.86%. Full old/new curves, BMI-30/40/50 landmarks, component
estimates and PIFs are in `verification/curve-comparison.csv`,
`curve-landmark-comparison.csv` and `policy-comparison.csv`.

## Figures and interpretation

**F1-main** is the preferred relationship display: A combined-gas hypercapnia;
B nested arterial hypercapnia; C stacked recorded-day components; D separate
ABG/VBG ascertainment. F1 A–C alternatives, F2 burden/contributions and component
figures are retained, with nested-secondary and supporting displays.

“Portion with blood gas obtained” means a **captured, usable PCO₂ result**; tests
without usable captured results are not identified. These are encounter-wide
endpoints, including later recorded results. Ascertainment remains lower at BMI
40 and 50 than 30 in the adjusted primary models; the new adjustment does not
support a claim of uniformly increasing sampling across that range. The raw
setting-by-BMI Wilson proportions are separate descriptive evidence in
`tables/encounter_setting_audit.csv`.

Same recorded-day co-occurrence is not verified same-sample pairing. Components
may reflect different samples or treatment periods. No documented same-day
acidemia does not establish compensation; ICD categories describe coding rather
than physiological acuity. Gas models do not estimate outcomes among untested
patients. Sparse BMI tails, source entry and residual confounding remain limits.
PIF describes this modeled BMI scenario, not preventable cases or a weight-loss
treatment effect. Component-specific PIFs are not calculated.

## Verification and reproduction

One clinical estimation completed from clean merged code `a978145b84857d99fcfd280f67d83a04d9c9325c`
in about 60 minutes. The exact accepted input/manifest and all 15 evidence files
were reauthenticated; fresh preflight reproduced all 160 shared cohort nodes.
The numerical reviewer passed 167 checks, and independent aggregate comparison
passed 15,558 checks with zero sample/basis discrepancies. All six joint component
fits succeeded. Software E2E and 35 source-boundary checks have separate scopes;
artificial success is not source qualification or investigator approval.

See `review_status.json` for complete-table and visual-review evidence. The saved
bundle's creation-time approval flags are immutable; later receipts record review
without rewriting that bundle. Automated all-page audit checks and sampled visual
inspection are distinguished from inspection of every scientific page.

From the protected saved run:

```bash
make render RUN="artifacts/triangulation/curve-analyze-20261026T001917-75549"
```

The preferred figure can also be regenerated from five authenticated CSVs in this
packet with the matching repository source and existing R dependencies:

```bash
Rscript figure-source/render_main.R /path/to/repository /path/to/this-snapshot /fresh/output
```

Both routes read saved aggregates and do not refit models. The booklet can be
rebuilt with `reproduce_caption_booklet.py SNAPSHOT FONT_REGULAR FONT_BOLD FRESH_PDF`
using existing pypdf/reportlab. The recorded build uses installed Arial Unicode
for captions and Arial Bold for headings; the script rejects missing glyphs.
 Verify every packet
file from the repository root before quoting results:

```bash
python3 - <<'VERIFY'
from pathlib import Path
import hashlib, json
p = Path('results/2026-10-26-setting-adjusted')
m = json.loads((p / 'manifest.json').read_text())
for name, entry in m['files'].items():
    assert hashlib.sha256((p / name).read_bytes()).hexdigest() == entry['sha256'], name
print('All snapshot hashes match')
VERIFY
```

`verification/abstract-values-to-refresh.csv` is a numerical ledger for any later
authorized draft revision; it is not revised abstract prose. Historical snapshots,
private source inputs and existing Word/text drafts remain unchanged.

In the inherited dictionary, wording about “collected” index-day gases means
**recorded result date equal to encounter-start date**. Collection timestamps are
not authenticated. The source contract and Methods define this sensitivity.
