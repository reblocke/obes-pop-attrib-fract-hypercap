# Joint same-day hypercapnia components — 20 October 2026

One joint multinomial spline now separates **hypercapnia with same-day acidemia**
from **hypercapnia without documented same-day acidemia**, while retaining a
no-documented-hypercapnia category. S1 stacks the two hypercapnia components across
the full observed BMI range and also shows them on a common baseline with 95%
confidence intervals. BMI 40–45 is one numerical comparison, not the study range.

This is **same recorded-day co-occurrence; not verified same-sample pairing**.
Any qualifying day with both findings takes priority if a patient has mixed days.
All categories refer to eligible days within the existing index encounter. Values
may come from different samples or treatment periods. Neither category establishes
acute respiratory failure, chronic compensation, or a causal effect of BMI.

## Read or share

| File | Contents |
|---|---|
| [Scientific PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html) | 41-page integrated methods/results report, including unchanged primary analyses |
| [Captioned S1 PDF](supplement_figure.pdf) / [native figure](figures/S1-same-day-ABG.pdf) | Stacked probabilities, component intervals and shared BMI frequencies |
| [Offline gallery](gallery.html) | S1 with caption, download formats and numerical source links |
| [Complete audit PDF](bmi_hypercapnia_audit.pdf) | 3546 pages of full cohort profiles, coefficients, covariance, diagnostics and explicit unavailable states |
| [Aggregate tables](TABLES.md) / [machine-readable index](table_index.csv) | Complete saved CSV exports, including component contrasts and probability covariance |
| [Numerical review](review/numerical-review.json) / [visual review](review/clinical-visual-review.json) | Separate evidence and approval states |

For email review, start with the scientific PDF and captioned S1; the complete
audit is a larger reference file. The scientific HTML is self-contained. Keep the
folder intact for gallery links. Download HTML files from GitHub to view them.
Raw records, identifiers, individual dates/predictions and model objects are excluded.

The selected primary figures remain [B/F2](../2026-10-18/gallery.html). The
[original snapshot](../2026-10-18/README.md) and [earlier binary supplement](../2026-10-20-same-day-abg/README.md)
are unchanged. The latter retains its original two-model specification; it must
not be relabeled as the joint model. No abstract was drafted.

## Population and magnitude

The shared model/reference population contains **22,195 patients**: 8,809
with co-occurrence, 2,860 with hypercapnia without documented
same-day acidemia, and 10,526 without documented hypercapnia on
co-observed days. These are mutually exclusive patient counts, not day or sample
counts. The model retains the primary numerical spline basis and adjustment.

Selected coordinates below describe adjusted probabilities in the same empirical
reference population. Values in parentheses are pointwise model-based 95% intervals.
The full observed range is approximately BMI 30–85.9; the upper tail is sparse.

| BMI | With same-day acidemia | Without documented same-day acidemia | Total hypercapnia |
|---:|---:|---:|---:|
| 30 | 34.1% (32.5–35.8) | 11.5% (10.5–12.7) | 45.7% (43.9–47.4) |
| 40 | 41.8% (40.7–42.9) | 14.4% (13.7–15.3) | 56.3% (55.1–57.4) |
| 50 | 48.7% (47.2–50.3) | 18.5% (17.3–19.7) | 67.2% (65.7–68.7) |
| 60 | 55.5% (52.2–58.7) | 20.5% (17.9–23.3) | 76.0% (73.1–78.6) |
| 70 | 61.0% (55.6–66.2) | 22.0% (17.6–27.1) | 83.0% (79.2–86.3) |

Both component probabilities increase across much of the range, but their changes
are not uniform. The without-acidemia curve has a small initial dip near BMI 30–35.
The full set of five-unit comparisons below makes the magnitudes inspectable;
separate or overlapping curve intervals are not a test that changes are equal.

| BMI interval | With acidemia: change pp (95% CI) | Without: change pp (95% CI) | With minus without: change difference pp (95% CI) | Support |
|---|---:|---:|---:|---|
| 30–35 | 4.50 (2.24–6.75) | -0.45 (-1.95–1.04) | 4.95 (1.94–7.96) | Within observed range |
| 35–40 | 3.18 (1.72–4.64) | 3.35 (2.40–4.30) | -0.17 (-2.12–1.77) | Within observed range |
| 40–45 | 3.28 (2.54–4.02) | 2.63 (2.03–3.23) | 0.65 (-0.49–1.79) | Within observed range |
| 45–50 | 3.64 (2.58–4.71) | 1.39 (0.60–2.18) | 2.25 (0.72–3.79) | Within observed range |
| 50–55 | 3.51 (2.34–4.69) | 1.08 (0.12–2.04) | 2.44 (0.55–4.32) | Within observed range |
| 55–60 | 3.24 (2.07–4.40) | 0.95 (-0.08–1.97) | 2.29 (0.25–4.34) | Within observed range |
| 60–65 | 2.94 (1.77–4.10) | 0.81 (-0.28–1.89) | 2.13 (-0.04–4.30) | Within observed range |
| 65–70 | 2.62 (1.45–3.79) | 0.67 (-0.46–1.80) | 1.95 (-0.31–4.22) | Within observed range |
| 70–75 | 2.32 (1.13–3.50) | 0.54 (-0.62–1.70) | 1.78 (-0.56–4.11) | Sparse endpoint |
| 75–80 | 2.03 (0.83–3.22) | 0.42 (-0.76–1.60) | 1.61 (-0.77–3.99) | Sparse endpoint |
| 80–85 | 1.76 (0.55–2.97) | 0.31 (-0.88–1.51) | 1.45 (-0.95–3.84) | Sparse endpoint |

These signed contrasts use full cross-category covariance. They are pointwise,
not multiplicity-adjusted, and do not remove selection or measurement bias.
Local counts and marginal covariate coverage cannot establish joint support.
Use [all curve coordinates](tables/probability_curves.csv), [contrasts](tables/same_day_contrasts.csv),
[category counts](tables/cooccurrence_categories.csv), [probability covariance](tables/same_day_probability_covariance.csv)
and [four-stage reconciliation](tables/cooccurrence_reconciliation.csv) for exact values.
No supplemental PIF, timing duplicate, observation regression or weighting analysis was added.

## Provenance and review

This is a reading snapshot of `curve-analyze-20261020T230537-20006`, `bmi_hypercapnia_rfs_curve_audit_v5`,
aggregate schema 10. Estimation ran once on the clean merged Mini checkout at
`21b8bdf`. The exact previously qualified enrichment and manifest
were reused and passed fresh preflight. The input, original fields and indexes
were not changed. This folder is not an executable bundle: do not pass it to
`make render`.

- **Source qualification:** existing acceptance evidence retained; current input,
  manifest/evidence identities and cohort reconciliation passed.
- **Estimation:** one joint supplemental model completed successfully.
- **Numerical review:** all eight primary-result comparison tables agree with the
  authenticated prior run within 1e-10; probability and count partitions reconcile.
- **Visual review:** native-size/color/grayscale and assembled-page inspection
  scope is recorded in the receipt. Automated checks are separate from visual review.
- **Investigator interpretation and S1 approval remain pending.** Earlier B/F2
  selection and provisional scientific approval are not extended automatically.

The complete audit records the unchanged constant diagnosis-capture model position
and unavailable multinomial case-deletion influence diagnostic explicitly.
Rendering used saved aggregates only, without clinical input reads or refitting.
Editable plotting source is [R/rfs_reporting.R](../../R/rfs_reporting.R); SVG/PDF
masters and 300-dpi PNG/JPG exports are included. See the [specification](../../docs/SAME_DAY_ABG_SUPPLEMENT.md),
[decision log](../../docs/DECISIONS.md) and [LLM guide](../../docs/LLM_GUIDE.json).

Verify snapshot bytes from the repository root:

```bash
python3 - <<'VERIFY'
import hashlib, json
from pathlib import Path
root = Path('results/2026-10-20-same-day-components')
manifest = json.loads((root / 'manifest.json').read_text())
for relative, item in manifest['files'].items():
    path = root / relative
    assert path.stat().st_size == item['bytes'], relative
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], relative
print('All files match the recorded snapshot.')
VERIFY
```
