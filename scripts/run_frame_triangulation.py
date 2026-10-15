#!/usr/bin/env python3
"""Run hash-verified frozen frame sources in an ignored workspace."""
from pathlib import Path
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def main():
    args = sys.argv[1:]
    if not args or args[0] not in {"fixture", "clinical", "review", "test"}:
        raise SystemExit("Usage: fixture [FORMAT] | clinical INPUT MANIFEST [FORMAT] | review RUN [FORMAT] | test")
    mode = args[0]
    required = {"fixture": 1, "clinical": 3, "review": 2, "test": 1}[mode]
    if len(args) not in {required, required + (mode != "test")}:
        raise SystemExit("Invalid frozen-workflow arguments")
    for i in range(1, required):
        args[i] = str(Path(args[i]).resolve(strict=True))
    archive = ROOT / "archive/2026-10-14-frame-specific"
    provenance = json.loads((archive / "provenance.json").read_text())
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S")
    workspace = ROOT / "artifacts/triangulation/frame-workspaces" / f"{mode}-{stamp}-{os.getpid()}"
    workspace.mkdir(parents=True, exist_ok=False)
    for name, digest in provenance["files"].items():
        source = archive / name
        if hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            raise SystemExit("Archived frame source hash mismatch: " + name)
        target = workspace / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    old = ROOT / "archive/2026-10-13-bmi-to-40"
    older = json.loads((old / "provenance.json").read_text())
    for name, digest in older["files"].items():
        if hashlib.sha256((old / name).read_bytes()).hexdigest() != digest:
            raise SystemExit("Archived BMI-to-40 source hash mismatch: " + name)
    shutil.copytree(old, workspace / "archive/2026-10-13-bmi-to-40")
    command = ["Rscript", "--vanilla", "tests/run_triangulation_tests.R"] if mode == "test" else ["Rscript", "--vanilla", "scripts/render_triangulation.R", *args]
    env = os.environ.copy()
    env["TRI_REPO_ROOT"] = str(workspace)
    completed = subprocess.run(command, cwd=workspace, env=env, capture_output=True, text=True)
    (workspace / "execution.log").write_text(completed.stdout + completed.stderr)
    (workspace / "execution-receipt.json").write_text(json.dumps({
        "mode": mode, "source_commit": provenance["source_commit"], "source_hashes_verified": True,
        "exit_status": completed.returncode, "clinical_execution_requested": mode == "clinical",
    }, indent=2) + "\n")
    print(completed.stdout, end="")
    print(completed.stderr, end="", file=sys.stderr)
    print("Frozen-workflow evidence:", workspace)
    return completed.returncode


if __name__ == "__main__":
    sys.exit(main())
