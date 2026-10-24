# ICD acuity supplement — 24 October 2026

The existing five-code ICD composite is now separated into **chronic/OHS**,
**acute-on-chronic or concurrent acute/chronic coding**, **acute**, and
**unspecified acuity**, with no target diagnosis as the fifth model category.
The analysis uses the same fixed primary indexes and complete encounter diagnosis
capture; gas testing is not required. The planned joint multinomial spline was
**nonestimable because of separation**. Descriptive category counts are available;
adjusted acuity curves and contrasts are not. S2 explicitly displays that status.

This is a decomposition of documented coding, not a physiological classification.
OHS is grouped analytically with chronic coding; this does not establish chronic
respiratory failure. Source-entry selection, coding practices and the obesity
criterion in OHS limit interpretation. No new PIF, imputation or weighting model
was added. Investigator interpretation and S2 approval remain pending.

## Read or share

| File | Contents |
|---|---|
| [Scientific PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html) | 43-page integrated scientific report, including unchanged primary and S1 results |
| [Captioned S2 PDF](supplement_figure.pdf) / [native figure](figures/S2-ICD-acuity.pdf) | Explicit nonestimable-model display; no adjusted curves or intervals are available |
| [Offline gallery](gallery.html) | S2 caption, downloads and numerical sources; links to selected B/F2 and S1 |
| [Complete audit PDF](bmi_hypercapnia_audit.pdf) | 3,762 pages of full profiles, coefficients, covariance, diagnostics and unavailable states |
| [Aggregate tables](TABLES.md) / [table index](table_index.csv) | Complete CSV exports, including all code patterns and explicit unavailable contrast status |
| [Numerical review](review/numerical-review.json) / [visual review](review/clinical-visual-review.json) | Separate verification scopes; neither confers investigator approval |

For email, start with the scientific PDF and captioned S2. The audit is a larger
reference document. Download HTML from GitHub or open the gallery in a local clone.
This is an aggregate reading snapshot, not a `make render` run directory. Raw data,
identifiers, individual dates/predictions and model objects are excluded.

## Population and estimates

The eligible common reference population is **176,922 patients**.
The model status is **separation**. Counts below are mutually exclusive,
using the full diagnosis-capture denominator; proportions have Wilson 95% intervals.

| Category | Patients | Raw proportion (95% CI) |
|---|---:|---:|
| No target diagnosis documented | 168,288 | 95.12% (95.02–95.22) |
| Chronic coding / OHS | 1,769 | 1.00% (0.95–1.05) |
| Acute-on-chronic or concurrent coding | 3,443 | 1.95% (1.88–2.01) |
| Acute coding | 3,294 | 1.86% (1.80–1.93) |
| Unspecified acuity | 128 | 0.07% (0.06–0.09) |

The planned fit is unavailable because of complete or quasi-complete multinomial
separation. No alternative estimator was substituted. The unspecified category
has no observations in the inherited Asian (N=995), American Indian/Alaska Native
(N=1,475), or Native Hawaiian/Pacific Islander (N=339) strata. These are sampling
zeros, not evidence of physiological absence. See the
[aggregate diagnostic](review/zero-category-adjustment-cells.csv).

The [ICD contrast table](tables/icd_acuity_contrasts.csv) retains an explicit
nonestimable status. No adjusted ICD-acuity probabilities, intervals or contrasts
were produced. The [curve table](tables/probability_curves.csv) still contains the
unchanged primary and S1 results; filter by model ID rather than confusing the
original binary ICD curve with a new acuity curve. Obtaining adjusted acuity
curves requires an explicit modeling decision that has not been adopted here.

## Classification and verification

J96.22, or J96.02 together with J96.12/E66.2, takes acute/chronic precedence.
Remaining J96.02 is acute; remaining J96.12/E66.2 is chronic/OHS; remaining J96.92
is unspecified. No target code is negative only with complete capture. All five
flags, explicit/concurrent-code provenance and OHS-only patterns remain in
[the code-pattern table](tables/icd_acuity_patterns.csv).

The run is `curve-analyze-20261024T022943-53435`, aggregate schema 11 /
`bmi_hypercapnia_rfs_curve_audit_v6`, estimated once on the clean merged Mini
checkout at `c0970484db8708845c023712d8e5204aad368d91` (PR #23).

- **Source qualification passed:** existing accepted source/readers and capture
  policy reused; original fields/indexes and composite union reconciled.
- **Numerical review passed:** all 11 original primary/S1 comparison tables agree
  within 1e-10, excluding runtime metadata. ICD category counts and the original composite
  reconcile. ICD probability/covariance checks are not assessed because the model
  is nonestimable. Original PIFs are unchanged.
- **Rendering:** saved aggregates only, zero clinical-input reads or model refits.
- **Visual review:** exact native/color/grayscale, assembled-page and automated
  geometry coverage is recorded in the [receipt](review/clinical-visual-review.json).
- **Investigator interpretation and S2 approval remain pending.** S1 approval also
  remains separate; earlier provisional approval does not automatically extend.

The selected [B/F2](../2026-10-18/gallery.html),
[joint S1 snapshot](../2026-10-20-same-day-components/README.md), and all historical
reading packets are unchanged. No abstract was drafted. Editable figure source
is [R/rfs_reporting.R](../../R/rfs_reporting.R); SVG/PDF masters and 300-dpi PNG/JPG
exports are included. See the [specification](../../docs/ICD_ACUITY_SUPPLEMENT.md),
[decisions](../../docs/DECISIONS.md) and [LLM guide](../../docs/LLM_GUIDE.json).

Verify snapshot bytes from the repository root:

```bash
python3 - <<'VERIFY'
import hashlib, json
from pathlib import Path
root = Path('results/2026-10-24-icd-acuity')
for relative, item in json.loads((root / 'manifest.json').read_text())['files'].items():
    path = root / relative
    assert path.stat().st_size == item['bytes'], relative
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], relative
print('All files match the recorded snapshot.')
VERIFY
```
