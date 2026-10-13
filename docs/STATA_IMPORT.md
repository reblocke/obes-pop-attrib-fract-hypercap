# Stata import, provenance, and commands

The runnable [Stage 36 duplicate](../stata/do/36_subpop_hazard.do) estimates
BMI-to-40 impact fractions in the obesity-source/BMI >=40 cohort. The original
TriNetX repository remains intact. The [comparison](ANALYSIS_COMPARISON.md)
explains why this and the R analyses answer different questions.

## Provenance and permitted adaptation

- Repository: `https://github.com/reblocke/trinetx-hypercapnia-code`.
- Commit: `d5d269168eafc7905c9238a5486fc03a62b55ec3`.
- Source path: `stata/do/36_subpop_hazard.do`.
- Historical name: `Hypercapnia subpop hazard.do`.
- Original SHA-256: `6e25200c421be03c7f05e6a93898cd7a7816eff015b0095bf4f5668606cf7482`.
- Exact snapshot: [archive/stata/36_subpop_hazard.source.do](../archive/stata/36_subpop_hazard.source.do).
- Machine-readable receipt: [stata_import_provenance.json](stata_import_provenance.json).

At initial import, only initialization/I/O changed and the analysis block was
byte-identical to the snapshot. On October 12 the user authorized the decimal
`xblc` repair described below. The runnable copy now replaces exactly four
profile plotting calls; reversing those declared substitutions restores the
original analysis block byte-for-byte. Cohort rules, fitted models, knot
selection, standardization, PIF calculations, and their uncertainty are unchanged.
The original snapshot and hash remain immutable. Header TODOs remain unresolved.

The standard-library [unattended runner](../scripts/stata_runner.py) was copied
from the personal `stata-core` skill and is pinned by digest in the receipt.
There is no execution dependency on the installed skill directory. The
[project driver](../scripts/run_stata.py) supplies the analysis arguments and
copies the executed sources into each run directory. Python is launcher support,
not a statistical port.

## Prerequisites and execution

Use Stata 18 or newer, a licensed executable, and these installed packages:
`table1_mc`, `mkspline2`, and the `cleanplots` scheme. The repaired profile
plots use the bundled helper and built-in `predictnl`. `xblc` is required only
for archived-reference regression tests. From the repository
root:

```bash
export STATA_EXE="/path/to/licensed/Stata"
make stata-check
make stata-test
```

`stata-check` opens no clinical input. It checks the Stata version, resolves the
two ado commands and scheme, and retains the log and native completion record.
If a package is missing, review its package documentation and install manually
in the intended environment. Use Stata's `search table1_mc`, `search mkspline2`,
and `search cleanplots` to locate and review the appropriate
distributions. These are lookup instructions, not commands executed by this
repository.

For an explicit, authorized clinical run:

```bash
STATA_DATA_PATH="/path/to/approved/full_db.dta" make stata
```

The input defaults to `data/raw/full_db.dta`; it must already contain the nine
variables listed in [DATA_MANAGEMENT.md](DATA_MANAGEMENT.md). No upstream
preprocessing is launched, no RDS conversion is performed, and no variable is
reconstructed. Missing columns fail before the inherited analysis loads the file.
The driver checks file existence, records its SHA-256, and rejects Stata macro
characters in paths. Spaces are supported.

Direct invocation permits a timeout or an external output root:

```bash
python3 scripts/run_stata.py run --timeout 3600 \
  --data "/path/to/approved/full_db.dta" \
  --output-root "/path/to/private/stata-runs"
```

An in-repository output root must be under ignored `artifacts/stata/`. Each
invocation creates a unique `check-...` or `run-...` directory. It contains
`source/`, an invocation receipt, and `execution/` with the wrapper, text log,
stdout/stderr, exact run-specific native return-code sidecar, and `result.json`.
Analysis runs also contain `logs/analysis.smcl`, `tables/`, `figures/`, and `data/`.
The inherited script does not export a standalone PIF table; its estimates are
in the logs. Older source or prior outputs are never overwritten by the driver.

Success requires natural process exit, OS status zero, native Stata status zero,
and a fresh matching completion sidecar and log. A timeout remains failed even
if a completion marker appears; cleanup targets the owned process group only.
The exact native code is retained in `execution/result.json`. The shell receives
that code capped at 255, or 124 for timeout. OS status zero by itself is not
success. Automated execution supports macOS/Linux; Windows needs a separately
qualified launcher.

## Verification performed for this import

The prerequisite check passed on the local Stata/BE 18 installation. Eight unit
tests cover source/body identity, runner digest, missing prerequisites/input,
unsafe paths, spaces, fresh completion evidence, output isolation, ignore rules,
and native failure propagation. The licensed-runtime smoke uses generated
observations only:

```bash
python3 tests/stata_smoke.py --stata "$STATA_EXE"
python3 tests/stata_smoke.py --stata "$STATA_EXE" --decimal-bmi
```

The integer-BMI fixture completed both the imported and unchanged original
analysis with native status zero. All 12 displayed observed/counterfactual/PIF
values matched at the script's printed precision. The original import
analysis block matched byte-for-byte. Success, intentional failure, and timeout cleanup
were tested in directories containing spaces. This establishes the tested
import behavior, not clinical-data or universal numerical equivalence.

Additional native boundary checks returned `r(499)` for unavailable community
packages in an isolated session search path and `r(111)` for a synthetic DTA
missing a required column. The project CLI propagated the latter as status111.

The pre-fix double-precision decimal-BMI fixture produced the same inherited
`r(198)` in both implementations. The installed `xblc` compares the covariate
with `float(at_value)`; a double-precision decimal need not equal that value.
Those failed receipts remain intact. The corrected script now completes the
same fixture with native status zero; the archived reference still fails at
the first ICD BMI plot. All nine risk/PIF values printed before that archived
failure match the repaired script, which completes all four model/PIF sections.

The plot-building `ds s_bmi*` also includes the counterfactual `s_bmi40*`
variables during an ICD refit. Its scientific implications require separate
review. The `xblc, pr eform` curves fix other covariates at zero and are not
cohort-standardized risk curves. The precision repair retains this profile interpretation and leaves the
varlist concern for separate review.

No clinical input was opened, no clinical models/reports were rerun, and no
packages were installed. Runtime receipts and synthetic fixtures remain ignored.

## Historical evidence

The ignored bundle at `artifacts/evidence/stata-historical/` contains byte-for-byte
copies of the March 16 and 17 baseline workbooks, ABG BMI/age spline TIFFs,
and a March 14 source design note. `inventory.json` records their source repository,
commit, relative paths, dates, and hashes. `search-receipt.json` records the bounded
search for retained PIF logs. The public comparison and structured audits retain
portable evidence identities; output files themselves remain local.


## Authorized plotting precision repair (2026-10-12)

The four former `xblc, pr eform` calls now use
[obesity_spline_profile.ado](../stata/ado/obesity_spline_profile.ado). It selects
one actual observation per distinct nonmissing covariate value and evaluates
the intercept plus the supplied fitted spline terms with built-in
[`predictnl`](https://www.stata.com/manuals/rpredictnl.pdf). It constructs the
normal confidence limits on the log-odds scale, then exponentiates them for the
existing odds-to-probability plotting code. Other modeled terms remain fixed at
zero, as in the former calls. It does not round the predictor, match against a
single-precision value, refit a model, or change any PIF calculation.

The driver snapshots and loads the helper into each isolated Stata session.
For manual interactive use from the repository root, load it first with
`do stata/ado/obesity_spline_profile.ado`. No installed ado package is patched.
The source archive, earlier evidence, and original TriNetX checkout are intact.

The unit tests reverse only the four recorded substitutions and require exact
original-body identity. Native tests in `tests/stata_profile_test.do` compare
integer grids with legacy xblc outputs (relative tolerance 1e-6, allowing its
float output precision), verify decimal/nearly adjacent grid retention and
unchanged input/coefficient/covariance values, and independently check the
profile estimates and normal intervals against `lincom` (1e-10/1e-8 relative
tolerances). Integer full-run PIF displays match all 12 reference values;
decimal runs match all nine values available before the archived failure.
The repair has synthetic verification only; empirical curves were not rerun.
