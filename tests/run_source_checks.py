#!/usr/bin/env python3
"""Source-boundary checks only; persist failures/skips instead of hiding them."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
OUT = ROOT / "artifacts/triangulation" / (
    "source-tests-" + datetime.datetime.now().strftime("%Y%m%dT%H%M%S") + f"-{os.getpid()}"
)
OUT.mkdir(parents=True, exist_ok=False)


class ReceiptResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.records = []

    def addSuccess(self, test):
        super().addSuccess(test)
        self.records.append({"test": test.id(), "status": "passed"})

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.records.append({"test": test.id(), "status": "unavailable", "reason": reason})

    def addFailure(self, test, error):
        super().addFailure(test, error)
        self.records.append({"test": test.id(), "status": "failed", "reason": str(error[1])})

    def addError(self, test, error):
        super().addError(test, error)
        self.records.append({"test": test.id(), "status": "error", "reason": str(error[1])})


sources = sorted(list((ROOT / "tests").glob("*.py")) + list((ROOT / "scripts").glob("*.py")) + list((ROOT / "scripts").glob("*.R")))
def source_hashes():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}

before = source_hashes()
suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"), pattern="test_*.py")
with (OUT / "run.log").open("w") as log:
    result = unittest.TextTestRunner(stream=log, verbosity=2, resultclass=ReceiptResult).run(suite)
status = "failed" if not result.wasSuccessful() else "incomplete" if result.skipped else "passed"
stable = before == source_hashes()
if not stable:
    status = "failed"
receipt = {
    "status": status,
    "scope": "Artificial source boundaries; no clinical source qualification or human review",
    "python": sys.executable,
    "tests": result.records,
    "sources_unchanged": stable,
    "source_snapshot_scope": "Repository Python tests/adapters and R launchers/readers; not a claim that every file was imported",
    "sources": before,
}
(OUT / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(f"Source boundary checks: {status}; receipt: {OUT / 'receipt.json'}")
sys.exit(1 if status == "failed" else 78 if result.skipped else 0)
