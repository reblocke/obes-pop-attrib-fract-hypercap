"""Raw-record boundaries not visible to the typed-input E2E; no clinical data."""
import copy
import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from enrich_same_day_abg import derive_days, CooccurrenceError

POLICY = dict(policy_id="same_day_arterial_cooccurrence_v1",
    ph_lower_exclusive=6.5, ph_upper_exclusive=7.8,
    arterial_specimen_values=[], ph_units=["ph", "[ph]"])

def record(identity, code, value, date="20220101", **extra):
    return dict(source_record_id=identity, patient_id="p", encounter_id="e",
        code=code, code_system="LOINC", numeric_value=value, date=date,
        units_of_measure="[pH]" if code=="2744-1" else "mm[Hg]", **extra)

def day(co2, ph, date="20220101", prefix="a"):
    return [record(prefix+"c","2019-8",co2,date),record(prefix+"p","2744-1",ph,date)]

class CooccurrenceBoundary(unittest.TestCase):
    def test_thresholds_and_multiple_values(self):
        cases=[(day(45,7.3499),(1,1)),(day(45,7.35),(1,0)),
            (day(44.999,7.2),(0,0)),
            (day(65,7.4)+day(40,7.2,prefix="b"),(1,1)),
            (day(65,7.4)+day(40,7.2,date="20220102",prefix="b"),(1,0)),
            (day(40,7.4)+day(50,7.2,date="20220102",prefix="b"),(1,1))]
        for rows,expected in cases:
            with self.subTest(expected=expected):
                out=derive_days(rows,POLICY)
                self.assertEqual((out["hypercapnia_coobserved"],out["hypercapnia_acidemia_same_day"]),expected)
    def test_no_cross_date_or_cross_key_linkage(self):
        rows=[record("c","2019-8",60),record("p","2744-1",7.2,"20220102")]
        out=derive_days(rows,POLICY)
        self.assertEqual(out["same_day_abg_state"],"no_coobserved_day")
        self.assertIsNone(out["hypercapnia_coobserved"])
        for field in ("patient_id","encounter_id"):
            wrong=day(60,7.2);wrong[1][field]="other"
            with self.assertRaises(CooccurrenceError):derive_days(wrong,POLICY)
    def test_record_identity_duplicates_and_conflicts(self):
        rows=day(60,7.2)
        out=derive_days(rows+copy.deepcopy(rows),POLICY)
        self.assertEqual(out["same_day_abg_n_days"],1)
        self.assertEqual(out["same_day_abg_usable_pco2"],1)
        self.assertEqual(out["same_day_abg_duplicate_records"],2)
        wrong=dict(rows[0],numeric_value=40)
        with self.assertRaises(CooccurrenceError):derive_days(rows+[wrong],POLICY)
        with self.assertRaises(CooccurrenceError):derive_days([dict(rows[0],source_record_id=None),rows[1]],POLICY)
        self.assertEqual(derive_days(list(reversed(rows)),POLICY),derive_days(rows,POLICY))
    def test_partial_dates_and_measurements(self):
        rows=day(40,7.4)+[record("later","2019-8",60,"20220102")]
        out=derive_days(rows,POLICY)
        self.assertEqual(out["hypercapnia_coobserved"],0)
        self.assertEqual(out["same_day_abg_noncoobserved_high"],1)
        self.assertEqual(out["same_day_abg_co2_only_days"],1)
        for date in (None,"20220230","not a date","2022-01-01 12:00"):
            invalid=[record("c","2019-8",60,date),record("p","2744-1",7.2,date)]
            out=derive_days(invalid,POLICY)
            self.assertEqual(out["same_day_abg_state"],"unresolved")
            self.assertIsNone(out["hypercapnia_acidemia_same_day"])
            self.assertEqual(derive_days(day(60,7.2,prefix="valid")+invalid,POLICY)["hypercapnia_acidemia_same_day"],1)
        self.assertEqual(derive_days(day(45,7.2,date="2022-01-01"),POLICY)["hypercapnia_acidemia_same_day"],1)
    def test_specimen_units_and_validity(self):
        for code in ("2021-4","11557-6","32771-8"):
            rows=[record("c",code,60),record("p","2744-1",7.2)]
            self.assertIsNone(derive_days(rows,POLICY)["hypercapnia_coobserved"])
        for co2,ph in ((5,7.2),(200,7.2),(45,6.5),(45,7.8),(float('nan'),7.2)):
            self.assertIsNone(derive_days(day(co2,ph),POLICY)["hypercapnia_coobserved"])
        rows=day(6,7.2);rows[0]["units_of_measure"]="kPa"
        self.assertEqual(derive_days(rows,POLICY)["hypercapnia_acidemia_same_day"],1)
        for field,value in (("units_of_measure",""),("units_of_measure","mg/dL"),("specimen","venous")):
            rows=day(60,7.2);rows[0][field]=value
            self.assertIsNone(derive_days(rows,POLICY)["hypercapnia_coobserved"])
    def test_unavailable_is_not_assessed_zero(self):
        out=derive_days(day(60,7.2),None)
        self.assertEqual(out["same_day_abg_state"],"source_unavailable")
        self.assertIsNone(out["same_day_abg_n_days"])
        out=derive_days([],POLICY)
        self.assertEqual(out["same_day_abg_state"],"no_coobserved_day")
        self.assertEqual(out["same_day_abg_n_days"],0)
        self.assertIsNone(out["hypercapnia_coobserved"])
