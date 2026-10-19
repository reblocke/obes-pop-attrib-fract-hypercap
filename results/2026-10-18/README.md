# Collaborator review snapshot — 18 October 2026

This folder contains the completed clinical analysis for collaborator reading.
It includes reports, selected figures and complete aggregate tables. No raw data,
patient-level records, individual predictions or source-access credentials are
included. Nothing needs to be installed or executed to read the results.

## Start here

| File | Use |
|---|---|
| [Scientific report](bmi_hypercapnia.pdf) | 34-page mini-paper: rationale, detailed methods, results, verification details and interpretation |
| [Selected figures](selected_figures.pdf) | Two-page PDF of B and F2 with full captions, ready to attach to an email |
| [Offline gallery](gallery.html) | Open locally in a browser to inspect selected figures and download individual formats |
| [Complete audit](bmi_hypercapnia_audit.pdf) | 2,970-page reference PDF with full variable profiles, model output, covariance and diagnostics |
| [Aggregate table index](TABLES.md) | Find the exact counts, curve coordinates, scenario estimates and audit evidence behind a claim |
| [Machine-readable table index](table_index.csv) | All 49 files, row counts, field names, purposes and SHA-256 hashes |

The scientific PDF and selected-figure PDF are the email starting set. The complete
audit is approximately 30.4 MB; it is available separately for detailed checking.
Download PDFs using GitHub's **Download raw file** control if the preview is limited.
To use the gallery offline, keep this folder and its `figures/` and `tables/`
subfolders together. GitHub displays HTML source; download/clone the folder and
open `gallery.html` in a browser.

## Figure selection and interpretation

The owner selected **primary/F1-B and primary/F2** as the working main figures on
18 October 2026. [F1-B](figures/F1-B.pdf) shows adjusted BMI–hypercapnia curves,
evidence availability and BMI frequency. [F2](figures/F2.pdf) shows the paired
one-unit BMI scenario and signed contributions by original BMI band. Individual
PDF/SVG masters and PNG/JPG exports are in `figures/`; full definitions and
uncertainty descriptions are in [captions](captions.md) and [caption data](captions.csv).

The immutable scientific PDF still embeds F1-A; B displays the same estimates in
a different layout. Use standalone B for the selected presentation. Unselected
layouts and supporting figures remain in the complete audit and original local
review; this compact gallery includes only B/F2.

The primary population has a non-OBESITY historical source-entry pathway, including
OBESITY overlaps. Obesity-only entry is descriptive audit material, without an
adjusted comparison or weighting analysis. Gas results describe outcome-evaluable
patients; ICD results use known diagnosis capture. Outcome samples overlap.
Known capture is not ICD positivity; unavailable evidence is not a negative result.
The secondary PIF describes a modeled one-unit reduction when observed BMI >30,
without a floor or reselection. It does not estimate a causal weight-loss effect.

## For a collaborator using an LLM

Start with the [repository README](../../README.md), then provide
[LLM_GUIDE.json](../../docs/LLM_GUIDE.json), this folder's README and the relevant
aggregate CSVs. The guide identifies authoritative methods, primary-result filters,
units, uncertainty, population keys and remaining limitations. Prefer the CSVs for
exact numerical retrieval; do not ask an LLM to infer values from image pixels or
summarize all audit pages indiscriminately.

For a traceable numerical answer, ask it to cite the table filename, model/population,
outcome, time window, reference denominator and interval type. Blank and unavailable
results must stay distinct from zero. Do not use a historical report, artificial
fixture or remembered count as a current clinical finding.

## Provenance and review state

Source run: `curve-analyze-20261017T175520-51541`, clinical mode,
`bmi_hypercapnia_rfs_curve_audit_v2`, aggregate schema 7.
Source review: `20261017T205353-20587`. The analysis was run from merged `043fea6`;
later reporting-only revisions did not refit models. The
[saved configuration](analysis_config.json) belongs to that run; current source
configuration is not a license to relabel historical results.

[manifest.json](manifest.json) binds every included file to a hash and identifies
the original bundle/review receipts. Reports, figure exports, configuration and
49 CSVs are byte-identical copies; the two-page PDF, gallery and indexes are new
presentation/navigation files. This is a reading snapshot, **not** an executable
saved run: the binary aggregate object and private input receipts are omitted.
`make render RUN=results/2026-10-18` is therefore not a supported command.

Automated numerical reconciliation and scoped agent figure/report review were
completed; their scope is recorded in [review_status.json](review_status.json).
Owner scientific approval is **provisional**, with B/F2 selected for now. Older
report/table statements that scientific approval is pending retain their original
dated state; the October 18 owner decision is recorded separately rather than
editing saved evidence. The audit has automated full-page checks and sampled
visual inspection, not a claim that a person inspected each of its 2,970 pages.
Final submission packaging and approval remain separate. Abstract drafting is
deferred; this package adds no abstract text.

To check the downloaded package with standard Python (no analysis dependencies):

```bash
python3 - <<'PY'
import hashlib, json
from pathlib import Path
root = Path('results/2026-10-18')  # run from the repository root
manifest = json.loads((root / 'manifest.json').read_text())
for relative, record in manifest['files'].items():
    path = root / relative
    assert path.stat().st_size == record['bytes'], relative
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'], relative
print('All packaged files match the recorded snapshot.')
PY
```

Hashes verify file integrity, not scientific validity. Full clinical reproduction
requires separately authorized source access and the qualified execution workflow.
