"""Original study membership must precede BMI indexing, using artificial rows."""
import importlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from types import SimpleNamespace

try:
    import duckdb
    import pandas as pd
except ImportError:
    duckdb = pd = None

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))


@unittest.skipIf(duckdb is None, "Use the existing upstream Python environment")
class OriginalPopulationChecks(unittest.TestCase):
    def setUp(self):
        self.population = importlib.import_module("original_encounter_population")
        self.original = pd.DataFrame({
            "patient_id": ["001", "001", "002"], "encounter_id": ["a", "b", "c"],
            "pat_enc_hash": ["001-a", "001-b", "002-c"],
            "encounter_date": [22646.0, 22647.0, 22646.0],
            "encounter_type": [1, 2, 3], "first_encounter": [1, 0, 1]})

    def test_original_first_flag_is_verified_not_used_as_bmi_eligibility(self):
        audit = self.population.verify_original_list(self.original)
        self.assertEqual(audit["original_encounters"], 3)
        self.assertEqual(audit["original_acute_encounters"], 2)
        # The first acute/BMI-eligible index can differ from an earlier AMB flag.
        self.assertEqual(audit["first_flag_disagreements"], 0)
        wrong = self.original.copy(); wrong.loc[1, "first_encounter"] = 1
        with self.assertRaisesRegex(ValueError, "first-encounter"):
            self.population.verify_original_list(wrong)
        duplicate = pd.concat([self.original, self.original.iloc[[0]]])
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.population.verify_original_list(duplicate)

    def test_captured_history_and_returns_cannot_expand_original_keys(self):
        c = duckdb.connect(); self.addCleanup(c.close)
        c.execute("CREATE TABLE source_encounter(patient_id VARCHAR,encounter_id VARCHAR,type VARCHAR)")
        c.execute("INSERT INTO source_encounter VALUES ('001','a','AMB'),('001','b','EMER'),"
                  "('002','c','IMP'),('001','history','UNKNOWN'),('001','lab','LAB'),"
                  "('001','return','IMP'),('001','b','UNKNOWN')")
        audit = self.population.stage_original_membership(c, self.original)
        self.assertEqual(audit["original_acute_encounters"], 2)
        self.assertEqual(c.execute("SELECT count(*) FROM original_source_encounters").fetchone()[0], 3)
        self.assertEqual(c.execute("SELECT count(*) FROM original_source_encounters WHERE encounter_id IN ('history','lab','return')").fetchone()[0], 0)
        self.assertEqual(c.execute("SELECT encounter_type FROM original_acute_keys WHERE encounter_id='b'").fetchone()[0], "EMER")

    def test_original_membership_requires_matching_captured_setting(self):
        c = duckdb.connect(); self.addCleanup(c.close)
        c.execute("CREATE TABLE source_encounter(patient_id VARCHAR,encounter_id VARCHAR,type VARCHAR)")
        c.execute("INSERT INTO source_encounter VALUES ('001','b','UNKNOWN'),('002','c','IMP')")
        with self.assertRaisesRegex(ValueError, "setting evidence"):
            self.population.stage_original_membership(c, self.original)

    def test_manifest_cannot_relabel_broader_mapping_as_original(self):
        with tempfile.TemporaryDirectory() as temp:
            p = Path(temp)/"manifest.json"
            p.write_text(json.dumps({"rows": 99}))
            with self.assertRaisesRegex(ValueError, "original encounter"):
                self.population.require_original_population({"population_scope_id": self.population.POPULATION_ID}, {})

    def test_independent_qualification_rejects_added_history_key(self):
        qa = importlib.import_module("qualify_common_index_source")
        c = duckdb.connect(); self.addCleanup(c.close)
        c.execute("CREATE TABLE source_encounter(patient_id VARCHAR,encounter_id VARCHAR,type VARCHAR,"
                  "start_date VARCHAR,start_timestamp_precision VARCHAR)")
        c.execute("INSERT INTO source_encounter VALUES ('001','b','EMER','20220102','date_only'),"
                  "('002','c','IMP','20220101','date_only'),('001','return','IMP','20220201','date_only')")
        c.execute("CREATE TABLE mapping(patient_id VARCHAR,encounter_id VARCHAR,encounter_type VARCHAR,encounter_date DATE)")
        c.execute("INSERT INTO mapping VALUES ('001','b','EMER','2022-01-02'),('002','c','IMP','2022-01-01'),"
                  "('001','return','IMP','2022-02-01')")
        prepared = pd.DataFrame({'patient_id':['001','002'], 'encounter_id':['b','c']})
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'ARTIFICIAL.parquet'
            c.execute('COPY mapping TO ? (FORMAT PARQUET)',[str(path)])
            checks,_=qa.check_original_population(c,path,self.original,prepared)
        self.assertEqual(checks['mapping_keys_outside_original_list'],1)
        self.assertEqual(checks['prepared_indexes_outside_original_list'],0)
        self.assertEqual(checks['original_first_flag_disagreements'],0)


if __name__ == "__main__":
    unittest.main()
