"""Source-preservation and launcher boundary checks; no clinical data."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import run_stata as driver
import stata_runner


class ImportTests(unittest.TestCase):
    def test_source_and_analysis_block_identity(self):
        receipt = json.loads((ROOT / "docs/stata_import_provenance.json").read_text())
        source = (ROOT / receipt["archive_path"]).read_bytes()
        self.assertEqual(hashlib.sha256(source).hexdigest(), receipt["source_sha256"])
        marker = receipt["analysis_marker"].encode()
        body = source.split(marker, 1)[1]
        live = (ROOT / receipt["runnable_path"]).read_bytes().split(marker, 1)[1]
        normalized = live.decode()
        for correction in receipt.get("corrections", []):
            helper = ROOT / correction["helper_path"]
            self.assertEqual(hashlib.sha256(helper.read_bytes()).hexdigest(), correction["helper_sha256"])
            for change in correction["analysis_replacements"]:
                self.assertEqual(normalized.count(change["replacement"]), change["occurrences"])
                normalized = normalized.replace(change["replacement"], change["original"])
        self.assertEqual(body, normalized.encode())
        self.assertEqual(hashlib.sha256(live).hexdigest(), receipt.get("runnable_analysis_block_sha256", receipt["analysis_block_sha256"]))
        self.assertEqual(hashlib.sha256(body).hexdigest(), receipt["analysis_block_sha256"])
        self.assertEqual(hashlib.sha256((ROOT / "scripts/stata_runner.py").read_bytes()).hexdigest(), receipt["runner_sha256"])

    def test_missing_executable_and_input_fail_before_run(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(driver.main(["check"]), 2)
            self.assertEqual(driver.main(["run", "--stata", sys.executable, "--data", "/nonexistent/obesity-fixture.dta"]), 2)

    def test_in_repository_outputs_must_be_ignored(self):
        with self.assertRaises(ValueError):
            driver.prepare_run("check", ROOT / "public-outputs", None)
        self.assertFalse((ROOT / "public-outputs").exists())

    def test_unique_runs_and_paths_with_spaces(self):
        with tempfile.TemporaryDirectory(prefix="obesity source spaces ") as temp:
            first = driver.prepare_run("check", Path(temp), None)
            second = driver.prepare_run("check", Path(temp), None)
            self.assertNotEqual(first, second)
            self.assertEqual((first / "source/check_prerequisites.do").read_bytes(), (ROOT / "stata/do/check_prerequisites.do").read_bytes())
            self.assertIn(str(first), (first / "entry.do").read_text())

    def test_stata_macro_characters_rejected(self):
        for bad in ("bad$path", "bad`path", 'bad"path', "bad\npath"):
            with self.assertRaises(ValueError):
                stata_runner._stata_path(Path(bad))

    def test_plotting_helper_is_snapshotted_and_loaded(self):
        with tempfile.TemporaryDirectory(prefix="profile snapshot spaces ") as temp:
            data = Path(temp) / "synthetic.dta"
            data.write_bytes(b"synthetic launcher fixture; never opened by Stata")
            run = driver.prepare_run("run", Path(temp), data)
            helper = run / "source/obesity_spline_profile.ado"
            self.assertEqual(helper.read_bytes(), (ROOT / "stata/ado/obesity_spline_profile.ado").read_bytes())
            entry = (run / "entry.do").read_text()
            self.assertLess(entry.index("obesity_spline_profile.ado"), entry.index("36_subpop_hazard.do"))

    def test_exact_fresh_completion_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "completion.txt"
            path.write_text("STATA_RUNNER::fresh::459\n")
            self.assertEqual(stata_runner._read_stata_rc(path, "fresh"), 459)
            with self.assertRaises(ValueError):
                stata_runner._read_stata_rc(path, "old")

    def test_native_failure_propagation(self):
        with tempfile.TemporaryDirectory() as temp:
            result = dict(success=False, natural_exit=True, timed_out=False,
                          os_returncode=0, stata_returncode=459, exit_code=1)
            with patch.object(driver, "prepare_run", return_value=Path(temp)), patch.object(driver, "run_stata", return_value=result):
                self.assertEqual(driver.main(["check", "--stata", sys.executable]), 255)

    def test_input_evidence_and_outputs_are_ignored(self):
        paths = ["data/raw/full_db.dta", "full_db.dta", "artifacts/stata/example/result.json", "artifacts/evidence/example/table.xlsx"]
        for path in paths:
            check = subprocess.run(["git", "check-ignore", "--quiet", path], cwd=ROOT)
            self.assertEqual(check.returncode, 0, path)


if __name__ == "__main__":
    unittest.main()
