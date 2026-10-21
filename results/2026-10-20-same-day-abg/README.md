# Same-day arterial supplement — 20 October 2026

The clinical supplement is complete and numerically reconciled. It adds two
adjusted BMI probability curves for **same recorded-day co-occurrence; not
verified same-sample pairing**. Findings may come from different samples or
treatment periods. They do not establish simultaneous hypercapnic acidemia,
acute respiratory failure or compensation.

## Read or share

| File | Contents |
|---|---|
| [Scientific PDF](bmi_hypercapnia.pdf) / [HTML](bmi_hypercapnia.html) | 38-page expanded report integrating the supplement with the unchanged primary analysis |
| [Captioned S1 PDF](supplement_figure.pdf) / [vector master](figures/S1-same-day-ABG.pdf) | Two supplemental curves and shared BMI frequencies; [caption](captions.md) |
| [Offline figure gallery](gallery.html) | Full-size S1, captions, download formats and numerical source links |
| [Complete audit PDF](bmi_hypercapnia_audit.pdf) | 3,080 pages, with complete profiles, model coefficients/covariance and diagnostics |
| [Aggregate tables](TABLES.md) / [machine-readable index](table_index.csv) | All saved aggregate CSV tables, including the four-stage reconciliation and supplemental contrasts |
| [Review state](review/clinical-visual-review.json) | Source, numerical, visual and investigator-review states remain separate |

Start with the scientific PDF and S1 for email review; the full audit is a separate
reference. The scientific HTML is self-contained. Keep this folder intact for the
gallery links. On GitHub, download HTML files to view them; the repository page
shows source. No raw data, patient-level records, model objects, individual
predictions, individual dates or source-access credentials are included.

The selected main figures remain [B/F2 in the original snapshot](../2026-10-18/gallery.html).
This supplement does not replace their approval or selection. The unchanged
[original snapshot](../2026-10-18/README.md) and [pairing-feasibility report](../2026-10-20-paired-abg/README.md)
remain historical evidence. No abstract was drafted.

## What changed in the analyzable evidence

The following counts refer to covariate-complete primary patients at their fixed
indexes. Raw proportions use Wilson 95% confidence intervals and differ from the
adjusted curve probabilities. Stages 2–4 contain exactly the same patients.

| Stage | Patients | Positive | Observed percentage (95% CI) |
|---|---:|---:|---|
| Original arterial-evaluable | 29,639 | 15,541 | 52.43% (51.87–53.00) |
| Co-observed patients: original arterial outcome | 22,195 | 11,690 | 52.67% (52.01–53.33) |
| Same patients: hypercapnia on co-observed days | 22,195 | 11,669 | 52.57% (51.92–53.23) |
| Same patients: same-day hypercapnia and acidemia | 22,195 | 8,809 | 39.69% (39.05–40.33) |

The accepted source yielded 22,217 co-observed indexes across the entire fixed-index
cohort; 22,195 belong to the covariate-complete primary population used here. These
counts have different denominators and must not be substituted for each other.
Use [measurement counts](tables/cooccurrence_measurements.csv) for source rows and
days, and [availability profiles](tables/cooccurrence_availability.csv) for BMI,
demographic and setting strata. Day/record counts are not patient counts.

Both supplemental models completed on the same 22,195 patients, with the original
primary numeric spline basis and adjustment variables. They retain pointwise
model-based 95% intervals and supported BMI 45-versus-40 contrasts, including
intervals for each component probability. Editable plotting source remains in
[R/rfs_reporting.R](../../R/rfs_reporting.R); use the recorded release to reproduce
this snapshot. SVG/PDF masters and 300-dpi PNG/JPG exports are in `figures/`.
No supplemental PIF, observation model,
timing duplicate or new supporting population was added. See the saved
[model registry](tables/model_registry.csv), [curve coordinates](tables/probability_curves.csv),
[contrasts](tables/fixed_bmi_contrasts.csv) and [curve-order check](tables/same_day_curve_crossings.csv).

## Provenance and review

This is a separate reading snapshot of `curve-analyze-20261020T174425-15236`, clinical mode,
`bmi_hypercapnia_rfs_curve_audit_v4`, aggregate schema 9. Estimation ran once on the Mini from
merged `b89d485`. The original input is unchanged; the optional enrichment is
`same_day_arterial_cooccurrence_v1`. The new aggregate bundle was rendered without
clinical-input access or model refitting. This folder is not an executable run:
do not pass it to `make render`.

- **Source qualification passed:** code/unit/date policies, accepted-source identity,
  source count reconciliation, and exact original-field/index invariance.
- **Estimation completed:** exactly two supplemental positions, both successful.
- **Numerical review passed:** original model samples, coefficients, covariance,
  curves, fixed contrasts, PIFs and contributions match the authenticated prior
  run within 1e-10; the four-stage patient/event counts reconcile.
- **Visual review:** scope and limitations are recorded in
  [the review receipt](review/clinical-visual-review.json). Automated checks cover
  both complete PDFs; manual inspection is scoped and is not investigator approval.
- **Investigator interpretation and S1 approval remain pending.** The October 18
  provisional scientific approval covers the earlier analysis, not these new endpoints.

The source review receipt retains its state at qualification time, before
estimation; later numerical and visual receipts document the subsequent stages.
Hashes authenticate bytes and provenance, not scientific validity. The
[scientific specification](../../docs/SAME_DAY_ABG_SUPPLEMENT.md),
[LLM guide](../../docs/LLM_GUIDE.json) and [decision log](../../docs/DECISIONS.md)
provide context and current authority.

To verify this package from the repository root with standard Python:

```bash
python3 - <<'VERIFY'
import hashlib, json
from pathlib import Path
root = Path('results/2026-10-20-same-day-abg')
manifest = json.loads((root / 'manifest.json').read_text())
for relative, item in manifest['files'].items():
    path = root / relative
    assert path.stat().st_size == item['bytes'], relative
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], relative
print('All files match the recorded snapshot.')
VERIFY
```
