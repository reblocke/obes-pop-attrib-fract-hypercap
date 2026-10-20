"""Independent raw-record oracle: no clinical data or source approval."""
import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from enrich_paired_abg import derive_pairs, PairingError

POLICY = dict(policy_id="paired_abg_acidemia_v1", link_field="specimen_id",
    namespace_field="namespace", ph_lower_exclusive=6.5, ph_upper_exclusive=7.8,
    authoritative_version_field="version")
def record(sample, code, value, **extra):
    return dict(specimen_id=sample, namespace="site", code=code, code_system="LOINC",
                numeric_value=value, units_of_measure="[pH]" if code=="2744-1" else "mm[Hg]", **extra)
def pair(sample, co2, ph):
    return [record(sample,"2019-8",co2),record(sample,"2744-1",ph)]

class PairingBoundary(unittest.TestCase):
    def test_thresholds_and_multiple_samples(self):
        cases=[(pair("a",45,7.34),(1,1)),(pair("a",45,7.35),(1,0)),
            (pair("a",44.9,7.20),(0,0)),(pair("a",45,7.3499),(1,1)),
            (pair("a",60,7.4)+pair("b",40,7.2),(1,0)),
            (pair("a",65,7.4)+pair("b",55,7.3),(1,1))]
        for rows,expected in cases:
            with self.subTest(expected=expected):
                out=derive_pairs(rows,POLICY)
                self.assertEqual((out["hypercapnia_paired"],out["hypercapnia_acidemic"]),expected)
    def test_partial_unlinked_and_namespace(self):
        rows=pair("a",40,7.4)+[record("b","2019-8",60)]
        out=derive_pairs(rows,POLICY)
        self.assertEqual(out["hypercapnia_paired"],0)
        self.assertEqual(out["paired_abg_unpaired_high"],1)
        for rows in ([record(None,"2019-8",60,date="2022-01-01"),record(None,"2744-1",7.2,date="2022-01-01")],
                     [record("a","2019-8",60),dict(record("a","2744-1",7.2),namespace="other")]):
            out=derive_pairs(rows,POLICY)
            self.assertIsNone(out["hypercapnia_paired"])
            self.assertIsNone(out["hypercapnia_acidemic"])
    def test_duplicates_versions_conflicts_and_units(self):
        rows=pair("a",50,7.3)
        self.assertEqual(derive_pairs(rows+rows,POLICY)["paired_abg_n_pairs"],1)
        self.assertIsNone(derive_pairs(rows+[record("a","2744-1",7.4)],POLICY)["hypercapnia_acidemic"])
        corrected=[record("a","2019-8",50),record("a","2744-1",7.4,version=1),record("a","2744-1",7.3,version=2)]
        self.assertEqual(derive_pairs(corrected,POLICY)["hypercapnia_acidemic"],1)
        for code in ("2021-4","11557-6","32771-8"):
            self.assertIsNone(derive_pairs([record("a",code,60),record("a","2744-1",7.2)],POLICY)["hypercapnia_acidemic"])
        for value in (5,200):
            self.assertIsNone(derive_pairs(pair("a",value,7.2),POLICY)["hypercapnia_paired"])
        rows=[dict(record("a","2019-8",6),units_of_measure="kPa"),record("a","2744-1",7.3)]
        self.assertEqual(derive_pairs(rows,POLICY)["hypercapnia_acidemic"],1)
        self.assertIsNone(derive_pairs([dict(rows[0],units_of_measure=""),rows[1]],POLICY)["hypercapnia_paired"])
    def test_missing_policy_and_conflict_with_valid_pair(self):
        out=derive_pairs(pair("a",50,7.2),None)
        self.assertEqual(out["paired_abg_state"],"source_unavailable")
        self.assertIsNone(out["paired_abg_n_pairs"])
        rows=pair("a",50,7.2)+pair("b",50,7.4)+[record("b","2744-1",7.3)]
        out=derive_pairs(rows,POLICY)
        self.assertEqual(out["paired_abg_n_pairs"],1)
        self.assertEqual(out["paired_abg_conflicts"],1)
        self.assertEqual(out["hypercapnia_acidemic"],1)
