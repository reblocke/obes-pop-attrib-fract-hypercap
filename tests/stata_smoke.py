#!/usr/bin/env python3
"""Explicit licensed-runtime qualification using generated data only."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from stata_runner import _stata_path, run_stata


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stata", type=Path, required=True)
    parser.add_argument("--decimal-bmi", action="store_true", help="Verify the repaired decimal plotting path against the archived failure.")
    args = parser.parse_args()
    area = ROOT / "artifacts/stata" / ("synthetic spaces " + uuid.uuid4().hex[:10])
    area.mkdir(parents=True)
    results = {}

    def job(name, content, timeout=120):
        target = area / (name + ".do")
        target.write_text(content)
        result = run_stata(args.stata, target, area / name, cwd=ROOT, timeout_seconds=timeout)
        results[name] = result
        return result

    assert job("success", "version 18.0\ndisplay 2+2\n")["success"]
    deliberate = job("deliberate-failure", "version 18.0\nexit 459\n")
    assert deliberate["natural_exit"] and deliberate["stata_returncode"] == 459 and not deliberate["success"]
    missing_packages = job("missing-packages", f"adopath - PLUS\nadopath - PERSONAL\nadopath - SITE\ndo {_stata_path(ROOT / 'stata/do/check_prerequisites.do')}\n")
    assert missing_packages["stata_returncode"] == 499 and not missing_packages["success"]
    timeout = job("timeout", "version 18.0\nsleep 60000\n", timeout=2)
    assert timeout["timed_out"] and timeout["cleanup_succeeded"] and not timeout["success"]
    assert job("profile-precision", f"do {_stata_path(ROOT / 'tests/stata_profile_test.do')} {_stata_path(ROOT)}\n")["success"]

    data = area / "synthetic full_db.dta"
    bmi_expression = "round(40 + 20*runiform(), 0.1)" if args.decimal_bmi else "40 + floor(20*runiform())"
    fixture = f'''version 18.0
clear
set seed 20261012
set obs 600
gen byte OBESITY_rfs = (_n <= 590)
gen double bmi = {bmi_expression}
gen double age_at_encounter = round(18 + 65*runiform())
gen byte sex = mod(_n, 2)
gen byte race_ethnicity = mod(_n, 3)
gen byte location = mod(_n, 2)
gen byte has_abg = (_n <= 450)
gen byte hypercap_resp_failure = (runiform() < invlogit(-3 + 0.04*(bmi-40) + 0.005*(age_at_encounter-50)))
gen byte hypercap_on_abg = (runiform() < invlogit(-2 + 0.05*(bmi-40)))
save {_stata_path(data)}
'''
    assert job("create-fixture", fixture)["success"]
    command = [sys.executable, str(ROOT / "scripts/run_stata.py"), "run", "--stata", str(args.stata), "--data", str(data), "--output-root", str(area / "imported"), "--timeout", "180"]
    completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    (area / "imported-cli.txt").write_text(completed.stdout + completed.stderr)
    imported_runs = list((area / "imported").glob("run-*"))
    assert len(imported_runs) == 1
    imported = json.loads((imported_runs[0] / "execution/result.json").read_text())
    results["imported-analysis"] = imported

    # Reproduce the original initialization in an isolated synthetic-only tree.
    original_root = area / "original project spaces"
    original_source = original_root / "stata/do/36_subpop_hazard.do"
    original_source.parent.mkdir(parents=True)
    shutil.copyfile(ROOT / "archive/stata/36_subpop_hazard.source.do", original_source)
    (original_root / "config").mkdir()
    (original_root / "config/paths.do.example").touch()
    for path in ("data/derived/hypercapnia/preprocessing", "reports/stata-logs/hypercapnia", "reports/figures/hypercapnia", "reports/tables/hypercapnia", "reports/diagnostics/hypercapnia"):
        (original_root / path).mkdir(parents=True, exist_ok=True)
    shutil.copyfile(data, original_root / "data/derived/hypercapnia/preprocessing/full_db.dta")
    original = job("original-analysis", f"do {_stata_path(original_source)} {_stata_path(original_root)} \"synthetic\"\n", timeout=180)
    assert imported["success"] and imported["stata_returncode"] == 0
    assert imported["natural_exit"] and original["natural_exit"]
    if args.decimal_bmi:
        assert original["stata_returncode"] == 198 and not original["success"]
    else:
        assert original["success"], "Integer-BMI archived reference did not complete."
    imported_log = (imported_runs[0] / "execution/stata.log").read_text(errors="replace")
    original_log = (area / "original-analysis/stata.log").read_text(errors="replace")
    pattern = r"^(?:Observed risk \(mean pred\)|Counterfactual risk at BMI=40|PIF \(risk reduction proportion\)):\s+([-+0-9.e]+)"
    imported_values = re.findall(pattern, imported_log, flags=re.MULTILINE)
    original_values = re.findall(pattern, original_log, flags=re.MULTILINE)
    assert len(imported_values) == 12 and len(original_values) >= 9
    assert imported_values[:len(original_values)] == original_values, "Displayed synthetic estimates changed."
    summary = {name: {key: result.get(key) for key in ("success", "natural_exit", "stata_returncode", "timed_out")} for name, result in results.items()}
    summary["synthetic_input_sha256"] = hashlib.sha256(data.read_bytes()).hexdigest()
    summary["repaired_analysis_completed"] = True
    summary["archived_decimal_failure_reproduced"] = args.decimal_bmi
    summary["displayed_synthetic_estimates_match"] = True
    summary["displayed_values_compared"] = len(original_values)
    summary["fixture"] = "decimal_bmi" if args.decimal_bmi else "integer_bmi"
    summary["clinical_data_read"] = False
    (area / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({"evidence": str(area), "summary": summary}, indent=2))


if __name__ == "__main__":
    main()
