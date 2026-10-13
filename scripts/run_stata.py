#!/usr/bin/env python3
"""Check prerequisites or run the preserved Stata analysis explicitly."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sys
import uuid

from stata_runner import _stata_path, run_stata


ROOT = Path(__file__).resolve().parents[1]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def prepare_run(mode: str, output_root: Path, data_path: Path | None) -> Path:
    """Allocate an isolated directory and execute the captured source, not a later edit."""
    output_root = output_root.expanduser().resolve()
    if output_root.is_relative_to(ROOT) and not output_root.is_relative_to(ROOT / "artifacts/stata"):
        raise ValueError("In-repository Stata outputs must be under artifacts/stata (ignored).")
    _stata_path(output_root)
    output_root.mkdir(parents=True, exist_ok=True)
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:10]
    destination = output_root / f"{mode}-{run_id}"
    destination.mkdir(mode=0o700)
    snapshots = destination / "source"
    snapshots.mkdir()
    names = ["stata/do/check_prerequisites.do"]
    if mode == "run":
        names += ["stata/do/36_subpop_hazard.do", "archive/stata/36_subpop_hazard.source.do", "stata/ado/obesity_spline_profile.ado"]
    identities = {}
    for name in names:
        content = (ROOT / name).read_bytes()
        (snapshots / Path(name).name).write_bytes(content)
        identities[name] = hashlib.sha256(content).hexdigest()
    entry = [f"do {_stata_path(snapshots / 'check_prerequisites.do')}"]
    if mode == "run":
        for subdir in ("logs", "tables", "figures", "data"):
            (destination / subdir).mkdir()
        entry.append(f"do {_stata_path(snapshots / 'obesity_spline_profile.ado')}")
        entry.append(
            f"do {_stata_path(snapshots / '36_subpop_hazard.do')} "
            f"{_stata_path(data_path)} {_stata_path(destination)}"
        )
        entry.append("capture log close obesity_analysis")
    (destination / "entry.do").write_text("\n".join(entry) + "\n")
    # This receipt stays ignored: input paths can reveal restricted storage details.
    receipt = {
        "mode": mode, "source_sha256": identities,
        "data_path": str(data_path) if data_path else None,
        "data_sha256": sha256_file(data_path) if data_path else None,
    }
    (destination / "invocation.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return destination


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("check", "run"))
    parser.add_argument("--stata", default=os.environ.get("STATA_EXE"))
    parser.add_argument("--data", type=Path, default=Path(os.environ.get("STATA_DATA_PATH", "data/raw/full_db.dta")))
    parser.add_argument("--output-root", type=Path, default=ROOT / "artifacts/stata")
    parser.add_argument("--timeout", type=float, default=3600)
    args = parser.parse_args(argv)
    if not args.stata:
        print("ERROR: Set STATA_EXE to the licensed Stata executable.", file=sys.stderr)
        return 2
    try:
        executable = Path(args.stata).expanduser().resolve(strict=True)
        if not executable.is_file() or not os.access(executable, os.X_OK):
            raise ValueError("STATA_EXE must name an executable file.")
        data = None
        if args.mode == "run":
            data = args.data.expanduser().resolve(strict=True)
            if not data.is_file():
                raise ValueError("STATA_DATA_PATH must name the approved full_db.dta file.")
            _stata_path(data)
        destination = prepare_run(args.mode, args.output_root, data)
        result = run_stata(
            executable, destination / "entry.do", destination / "execution",
            cwd=ROOT, timeout_seconds=args.timeout,
        )
        print(f"Evidence directory: {destination}")
        print(json.dumps({key: result[key] for key in (
            "success", "natural_exit", "timed_out", "os_returncode", "stata_returncode"
        )}, sort_keys=True))
        if result["success"]:
            return 0
        print("Execution failed; inspect execution/stata.log and result.json in the evidence directory.", file=sys.stderr)
        if args.mode == "check" and result["stata_returncode"] in (9, 499):
            print("Require Stata 18+ and installed table1_mc, mkspline2, and cleanplots. Use Stata search to review missing distributions; no installation was attempted.", file=sys.stderr)
        if result["timed_out"]:
            return 124
        # Native codes are preserved exactly in result.json; shell statuses have an 8-bit limit.
        native = result["stata_returncode"]
        return min(int(native), 255) if native else int(result["exit_code"])
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
