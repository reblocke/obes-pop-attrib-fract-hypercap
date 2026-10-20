# Paired-ABG acidemia supplement — 20 October 2026

**Same-sample pairing is unavailable in the accepted source. No new clinical
models were fitted.** Arterial PCO₂ and pH are recorded, but all queried records
are date-only and lack specimen/panel/accession linkage. The two analyte counts
cannot recover pairs, and same-date co-occurrence does not establish a pair.

- [Feasibility PDF](feasibility.pdf) — concise source finding and unavailable secondary section.
- [Feasibility HTML](feasibility.html) — the same report for browser reading.
- [Aggregate evidence](feasibility.json) — counts, source/input hashes, unavailable quantities and review distinctions.
- [S1 PDF](figures/S1-paired-ABG.pdf), [PNG](figures/S1-paired-ABG.png), [JPG](figures/S1-paired-ABG.jpg), [SVG](figures/S1-paired-ABG.svg) — labeled unavailable positions, without numerical curves.
- [Editable Quarto report](feasibility.qmd); figure source is [R/rfs_reporting.R](../../R/rfs_reporting.R).
- [QC/review receipt](review.json) and [file manifest](manifest.json).

The [original clinical reading snapshot](../2026-10-18/README.md), its scientific
and audit PDFs, primary estimates, PIFs and selected B/F2 figures are unchanged.
The software adds exactly two secondary positions and integrates their source
status, tables, figure and complete model audit in future schema-8 reports.
The unavailable-source supplement is published separately so the old clinical
bundle is neither migrated nor relabeled. Artificial examples are not clinical
estimates. No abstract is drafted.

This directory contains no patient identifiers, raw measurements, dates,
patient-level predictions, model frames or source-access paths. Record counts
are not distinct patient prevalences. Unique blood samples, paired events and
paired model denominators remain **unavailable**, not zero.

From the repository root, with the existing R/Quarto dependencies, rerender only
this aggregate report:

```sh
quarto render results/2026-10-20-paired-abg/feasibility.qmd --to all
```

This does not read clinical data or estimate models. A rerender changes output
file hashes; preserve the reviewed snapshot or regenerate its manifest after
review. To verify the delivered files without R:

```sh
python3 - <<'PY'
import hashlib, json
from pathlib import Path
root=Path('results/2026-10-20-paired-abg')
manifest=json.loads((root/'manifest.json').read_text())
for name, digest in manifest['files'].items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest, name
print('All supplement files match the reviewed manifest')
PY
```
