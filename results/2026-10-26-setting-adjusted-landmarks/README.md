# Setting-adjusted BMI 30–40 contrasts

This aggregate addendum records the requested BMI 30-to-40 comparisons from the
[October 26 setting-adjusted analysis](../2026-10-26-setting-adjusted/README.md).
It uses that exact saved run, coefficients, full covariance, numeric BMI spline
basis and original reference populations. No model was fitted. The parent
snapshot, figures and abstract files are unchanged.

## Read the numbers

[landmark-estimands.csv](landmark-estimands.csv) contains 14 estimates and their
conditional model-based 95% intervals. Values are already scaled by 100:
probabilities and shares are percentages; differences are percentage points.

| Quantity | Estimate (95% CI) | Reference patients |
|---|---:|---:|
| Combined-gas probability increase, BMI 30→40 | 8.5035 percentage points (7.9600–9.0470) | 126,074 |
| Arterial probability increase, BMI 30→40 | 12.0408 percentage points (11.3088–12.7728) | 71,318 |
| With-acidemia component of the joint total probability increase | 71.3913% (66.6168–76.1658) | 53,607 |

The acidemia fraction is the increase in the with-acidemia component divided by
the increase in total hypercapnia probability, using the same joint model and
reference population. It is not the fraction of hypercapnia with acidemia at a
single BMI; those separate shares are also in the CSV. Component differences
sum to the joint total, which is distinct from the separately fitted binary
arterial model. No component-specific PIF is introduced.

The parent packet's [PIF comparison ledger](../2026-10-26-setting-adjusted/verification/policy-comparison.csv)
remains authoritative for the one-unit BMI>30 scenario. Do not use the historical
October 24 contrast intervals with these setting-adjusted probabilities.

The 53,607 denominator counts patients with a co-observed recorded day, not the
number of PCO₂ measurements. Same recorded-day co-occurrence is not verified
same-sample pairing; different samples or treatment periods may contribute.
Usable gas evidence does not identify every test ordered or drawn. These
comparisons are descriptive and do not establish a treatment effect or causal
attribution. Intervals condition on the fixed empirical reference population and
basis and exclude selection, measurement and unmeasured-confounding uncertainty.
Investigator interpretation remains separate from numerical verification.

## Evidence and reproduction

- [Manifest](manifest.json): parent run/input/bundle identities and payload hashes.
- [Clinical receipt](postestimation-receipt.json): authenticated source, no refits,
  unchanged inputs/sources/bundle and exact saved prediction reproduction.
- [Prediction reproduction](prediction-reproduction.csv): saved point estimates
  and intervals reproduced exactly at BMI 30, 35, 40 and 45.
- [Gradient checks](finite-difference-checks.csv): independent finite differences
  for both binary contrasts and the joint acidemia-share change.
- [Artificial verification](verification/artificial/postestimation-receipt.json):
  the same workflow on the existing E2E fixture; not a clinical result.
- [Release review](verification/release-review.json): payload, numerical, privacy
  and historical-immutability checks.

The frozen [prediction source](source/postestimate.R) reuses the current R
implementation and blocks fitting entrypoints. It requires R and the existing
project dependencies, the matching schema-14 saved bundle, and authorized access
to the exact accepted input/manifest to reconstruct reference covariates. Neither
private input nor patient-level data is included here. From the repository root:

```bash
Rscript --vanilla results/2026-10-26-setting-adjusted-landmarks/source/postestimate.R \
  "/path/to/exact/saved-run" \
  "/path/to/accepted/study-input.rds" \
  "/path/to/accepted/reviewed-manifest.json" \
  "/path/to/fresh/private-output"
```

Those paths must be replaced with authorized existing files; the output directory
must not already exist. The published reading snapshot is not a runnable bundle.
Successful replay writes the four aggregate CSV/JSON files shown above and a
`numerically_verified` receipt; any source/input/bundle or prediction mismatch
stops execution. The clinical calculation ran on the clean merged Mini checkout
at `d6b911bf0e00b9e7c0a5c17eaffe4308fa834904`; the original estimation remains
bound to its recorded `a978145` revision. No dependency installation, clinical
model rerun, figure change or abstract revision was performed.
