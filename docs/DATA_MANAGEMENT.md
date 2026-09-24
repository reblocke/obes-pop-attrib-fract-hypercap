# Data management and analysis input

The canonical report loads an R serialized `full_db.rds` from
`data/raw/full_db.rds`, falling back to root `full_db.rds`. Both paths are
local/ignored. Restricted TriNetX data, row-level derivatives, render outputs
and machine-specific paths must stay out of Git and be handled under approved
access and release rules.

## Lineage boundary

`trinetx-preprocessing` is named in earlier instructions as the expected
upstream source. The inspected upstream tracked `src/` and `docs/` contained no
`full_db.rds` or `saveRDS` producer. This repository does not provide a
producer commit, exact input snapshot, DTA/other-format conversion command,
RDS serialization version, schema hash, or authorization receipt for the local
analysis-ready file. A prior [worklog](../WORKLOG.md) records a successful local
read/render, but not these identities. Obtain the source and conversion chain
from the data steward; do not infer it from a matching filename or row count.

## Fields used by the maintained report

The [canonical QMD](../reports/obesity_hrf_paf_analysis.qmd) requires
`curr_bmi`, `niv_proc`, `imv_proc`, `highest_paco2`, `abg_ph`, `vbg_co2`,
`vbg_ph`, `age_at_encounter`, `sex`, `ethnicity`, and `has_j9612`, `has_j9622`,
`has_j9692`, `has_j9602`. It parses BMI as numeric kg/m²; PaCO₂ and VBG CO₂
are interpreted as mmHg, pH is unitless, age is years, and NIV/IMV labels
are converted to binary with unrecognized values left missing. Sex and
ethnicity become factors with explicit unknown levels. Gas-pair availability,
BMI availability and missingness enter attrition; missing gases are not a
negative HRF classification. The QMD does not require an identifier column or
assert unique encounters, and the source collection window is not established.
Refer to [analysis decisions](DECISIONS.md) for report-specific outcomes,
cutoffs and counterfactuals rather than replacing them with an upstream rule.

## Handoff

Before reproducing, verify the authorized file identity and schema against
the report's requirements, establish the permitted environment/storage and
output-release review, and use the README's render routes. The `renv-init`
target is a separate environment-construction step; routine rendering does not
snapshot packages. No data or environment reconstruction is certified by this
note.
