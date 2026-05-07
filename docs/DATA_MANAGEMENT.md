# Data Management

## Source

The analysis expects a TriNetX-derived dataset created upstream by:

```text
https://github.com/reblocke/trinetx-preprocessing
```

The expected local filename is:

```text
data/raw/full_db.rds
```

## Git Policy

- `data/raw/` is ignored except for `.gitkeep`.
- `data_derived/` is ignored.
- Rendered report outputs under `reports/` are ignored by default.
- Do not commit raw TriNetX extracts, PHI, restricted data, large local databases, generated raw extracts, or machine-specific absolute paths.

## Handoff Notes

To reproduce the analysis on another machine:

1. Restore or regenerate `full_db.rds` from the upstream preprocessing workflow.
2. Place it at `data/raw/full_db.rds`.
3. Confirm required R packages are available.
4. Run `make render` from the repository root.

If a future maintainer wants a locked package environment, initialize `renv` explicitly after approval:

```bash
make renv-init
```

This manual target installs `renv` if it is missing, then runs `renv::init()` and `renv::snapshot()`.

Do not run `renv::snapshot()` automatically as part of routine rendering.
