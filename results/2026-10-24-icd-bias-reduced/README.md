# ICD acuity curves — bias-reduced update, 24 October 2026

This supplement uses the **same qualified source and fixed primary indexes** as
the earlier ICD run. The full model retains all five diagnosis categories and
uses Firth mean bias reduction to address the previously demonstrated separation.
An unpenalized sensitivity excludes only the final unspecified-only category and
standardizes over its own reduced population. Neither changes the primary
analyses, same-day S1 or original PIFs. No supplemental PIF was added.

## Read or share

- [Scientific PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html): 56 pages, integrated methods and results.
- [Captioned figure booklet](supplement_figures.pdf): the three ICD views for email review.
- [Offline gallery](gallery.html): full-size figures, captions and downloads.
- [Complete audit PDF](bmi_hypercapnia_audit.pdf): 5,654 pages; complete tables and diagnostics, without previews.
- [Aggregate tables](TABLES.md) / [machine-readable table index](table_index.csv).
- [Numerical verification](review/numerical-review.json), [prior-result comparison](review/prior-primary-S1-comparison.csv), and [visual-review scope](review/clinical-visual-review.json).

The three views are **S2-ICD-acuity** (five-category bias-reduced curves),
**S2-ICD-specified** (four-category sensitivity), and **S2-ICD-observed**
(unadjusted within-BMI-band proportions with Wilson intervals).
They retain the full observed BMI range and identify sparse evidence.
Original [B/F2](../2026-10-18/gallery.html) and
[S1](../2026-10-20-same-day-components/gallery.html) remain unchanged.

## Models and observed counts

| Model | Model/reference N | Status |
|---|---:|---|
| Full five-category Firth model | 176,922 | successful |
| Four-category maximum-likelihood sensitivity | 176,794 | successful |

The sensitivity removes the final unspecified-only category, not every encounter
carrying J96.92 alongside another code. Its denominator differs from the full
model; this is not a same-denominator estimator comparison.

| Mutually exclusive category | Patients | Raw proportion (95% Wilson CI) |
|---|---:|---:|
| No target diagnosis documented | 168,288 | 95.120% (95.019–95.219) |
| Chronic coding / OHS | 1,769 | 1.000% (0.955–1.047) |
| Acute-on-chronic or concurrent coding | 3,443 | 1.946% (1.883–2.011) |
| Acute coding | 3,294 | 1.862% (1.800–1.926) |
| Unspecified acuity | 128 | 0.072% (0.061–0.086) |

Model-based pointwise intervals use the full multinomial information covariance
at the fitted estimate, conditional on the empirical reference and fixed spline
basis. They are not posterior or profile-likelihood intervals. A finite curve
does not resolve sparse local support, selective source entry or coding bias.
OHS is grouped analytically with chronic coding; it does not establish chronic
respiratory failure. This is a descriptive coding analysis, not a physiological
or causal classification. The joint composite need not equal the unchanged
primary binary ICD model's predictions.

## Provenance and review

Run: `curve-analyze-20261024T053607-55109`; schema 12 / `bmi_hypercapnia_rfs_curve_audit_v7`.
Estimated once on the clean merged Mini checkout at
`29687c9d6461a11aee9b19b622375d2860f3bd4e` (PR #25). Existing qualified input and
manifest identities were reused after fresh preflight. Rendering reads saved
aggregates only, with zero clinical-input reads and zero model refits.

All 11 original primary/S1/PIF table comparisons passed within 1e-10, excluding
runtime metadata. Complete report tables and new category/probability/covariance
reconciliation passed. See the separate review receipts for numerical, automated
geometry and actual manual-inspection scope. **Investigator interpretation and
figure approval remain pending.** Prior provisional B/F2 approval does not approve
these supplemental figures. No abstract was drafted.

The [earlier nonestimable ICD snapshot](../2026-10-24-icd-acuity/README.md) is
immutable historical evidence. This reading snapshot contains only reports,
figures and aggregate tables; it is not a runnable bundle. Raw inputs, patient
identifiers, dates, individual predictions and model objects are excluded.
Editable plotting source: [R/rfs_reporting.R](../../R/rfs_reporting.R).
Methods: [ICD specification](../../docs/ICD_ACUITY_SUPPLEMENT.md).

Verify snapshot bytes from the repository root:

```bash
python3 - <<'VERIFY'
import hashlib, json
from pathlib import Path
root = Path('results/2026-10-24-icd-bias-reduced')
for relative, item in json.loads((root / 'manifest.json').read_text())['files'].items():
    path = root / relative
    assert path.stat().st_size == item['bytes'], relative
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], relative
print('All snapshot files verified.')
VERIFY
```
