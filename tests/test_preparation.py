"""Artificial-only source-policy and preparation failure tests; standard library."""
import csv
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("preparation", ROOT/"scripts/prepare_common_index_input.py")
prep=importlib.util.module_from_spec(spec);spec.loader.exec_module(prep)
POLICY=json.loads((ROOT/"config/common_index_source_policy.json").read_text())
VOCAB={"ART":"abg","VEN":"vbg","CAP":"other"}


def record(code="2019-8", value=45, units="mm Hg", specimen=None, **extra):
    return dict(code=code,numeric_value=value,units_of_measure_raw=units,specimen=specimen,**extra)


def item(key="001", row=None, state="matched"):
    return SimpleNamespace(patient_id=key,encounter_id="0001",record=row,state=state)


class PreparationChecks(unittest.TestCase):
    def test_unadjusted_specimens_and_conflicts(self):
        self.assertEqual(prep.gas_record(record(),POLICY,VOCAB)[:3],("abg",45,True))
        self.assertEqual(prep.gas_record(record("2021-4",50),POLICY,VOCAB)[:2],("vbg",50))
        self.assertEqual(prep.gas_record(record("11557-6"),POLICY,VOCAB)[3],"unspecified_specimen")
        self.assertEqual(prep.gas_record(record("11557-6",specimen="VEN"),POLICY,VOCAB)[0],"vbg")
        self.assertEqual(prep.gas_record(record(specimen="VEN"),POLICY,VOCAB)[3],"specimen_conflict")
        self.assertIsNone(prep.gas_record(record("11557-6",specimen="CAP"),POLICY,VOCAB)[1])
        with self.assertRaisesRegex(prep.PreparationError,"unreviewed specimen"):
            prep.gas_record(record(specimen="UNREVIEWED"),POLICY,VOCAB)
        vocabulary={**VOCAB,"BLD":"unspecified"}
        self.assertEqual(prep.gas_record(record(specimen="BLD"),POLICY,vocabulary)[0],"abg")
        self.assertIsNone(prep.gas_record(record("11557-6",specimen="BLD"),POLICY,vocabulary)[1])

    def test_adjusted_and_total_co2_never_enter_primary(self):
        for code in POLICY["temperature_adjusted_codes"]:
            result=prep.gas_record(record(code,specimen="ART"),POLICY,VOCAB)
            self.assertIsNone(result[1]);self.assertEqual(result[3],"temperature_adjusted_excluded" if code!="40619-9" else "specimen_conflict")
        self.assertEqual(prep.gas_record(record("2026-3",specimen="ART"),POLICY,VOCAB)[3],"unreviewed_code")

    def test_explicit_units_and_numeric_missingness(self):
        self.assertAlmostEqual(prep.gas_record(record(value=6,units="kPa"),POLICY,VOCAB)[1],45.00372)
        for units in [None,"","mmol/L"]:
            self.assertEqual(prep.gas_record(record(units=units),POLICY,VOCAB)[3],"unusable_units")
        self.assertEqual(prep.gas_record(record(units=None),POLICY,VOCAB,"mmHg")[1],45)
        for value in [None,"cancelled",float("nan"),float("inf")]:
            self.assertEqual(prep.gas_record(record(value=value),POLICY,VOCAB)[3],"unusable_numeric")

    def test_strict_validity_bounds_and_inclusive_outcome_thresholds(self):
        for code,lower,upper in [("2019-8",5,200),("2021-4",10,250)]:
            for value in [lower-1,lower,upper,upper+1]:
                self.assertEqual(prep.gas_record(record(code,value),POLICY,VOCAB)[3],"outside_validity_limits")
            for value in [lower+.01,upper-.01,45 if code=="2019-8" else 50]:
                self.assertEqual(prep.gas_record(record(code,value),POLICY,VOCAB)[1],value)

    def test_maxima_testing_and_calendar_day_reconcile(self):
        rows=[item(row=record(value=45,date="2022-01-01",source_record_id="ARTIFICIAL-1")),
              item(row=record(value=60,date="20220103",source_record_id="ARTIFICIAL-2")),
              item(row=record("2021-4",50,date="2022-01-01",source_record_id="ARTIFICIAL-3")),
              item("002",record(value=300,source_record_id="ARTIFICIAL-4")),
              item("003",state="zero_matches"),item("004",state="unavailable_domain")]
        out,audit=prep.summarize_gases(rows,POLICY,VOCAB,start_dates={('001','0001'):prep.parsed_date("2022-01-01")})
        self.assertEqual(out['001','0001']['abg_pco2'],60)
        self.assertEqual(out['001','0001']['abg_pco2_index_day'],45)
        self.assertEqual(out['002','0001']['has_abg'],1)
        self.assertIsNone(out['002','0001']['abg_pco2'])
        self.assertEqual(out['003','0001']['has_abg'],0)
        self.assertIsNone(out['004','0001']['has_abg'])
        self.assertEqual(audit['outside_validity_limits'],1)

    def test_incomplete_or_duplicate_stream_cannot_be_accepted(self):
        def broken():
            yield item(row=record(source_record_id="ARTIFICIAL-1"))
            raise RuntimeError("ARTIFICIAL interrupted query")
        with self.assertRaises(RuntimeError):prep.summarize_gases(broken(),POLICY,VOCAB,start_dates={})
        rows=[item(row=record(source_record_id="ARTIFICIAL-1"))]*2
        with self.assertRaises(prep.PreparationError):prep.summarize_gases(rows,POLICY,VOCAB,start_dates={})

    def test_icd_captured_absence_and_incomplete_capture(self):
        rows=[item(state="zero_matches"),item("002",dict(code="E662",source_record_id="ARTIFICIAL-D1")),
              item("003",state="unavailable_domain")]
        result,_=prep.summarize_icd(rows,POLICY,True)
        self.assertEqual(result['001','0001'],0);self.assertEqual(result['002','0001'],1)
        self.assertIsNone(result['003','0001'])
        result,_=prep.summarize_icd(rows,POLICY,False)
        self.assertIsNone(result['001','0001']);self.assertEqual(result['002','0001'],1)
        with self.assertRaises(prep.PreparationError):prep.summarize_icd([item(row=dict(code="J96",source_record_id="ARTIFICIAL-D2"))],POLICY,True)

    def test_expanded_coverage_and_original_keys(self):
        prep.validate_key_coverage({("001","01")},{("001","01"),("002","01")})
        with self.assertRaises(prep.PreparationError):prep.validate_key_coverage({("001","01"),("003","01")},{("001","01")})
        prep.require_original_keys({'patient_id':["001"],'encounter_id':["0001"]})
        for key in [1,None,""]:
            with self.assertRaises(prep.PreparationError):prep.require_original_keys({'patient_id':[key],'encounter_id':["0001"]})

    def test_identity_and_failure_receipts(self):
        with tempfile.TemporaryDirectory() as path:
            root=Path(path);file=root/"ARTIFICIAL.txt";file.write_text("ARTIFICIAL")
            entry=dict(path=str(file),sha256=prep.sha256(file));self.assertEqual(prep.verify_file(entry),file)
            file.write_text("changed")
            with self.assertRaises(prep.PreparationError):prep.verify_file(entry)
            config=root/"config.json";config.write_text('{}');output=root/"output"
            result=subprocess.run(['python3',str(ROOT/'scripts/prepare_common_index_input.py'),'--config',str(config),'--output',str(output)],capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            receipt=json.loads((output/'preparation_failure.json').read_text())
            self.assertFalse(receipt['clinical_results_qualified']);self.assertEqual(receipt['clinical_models_fitted'],0)
            self.assertNotIn('ARTIFICIAL-PATIENT',result.stdout+result.stderr)

    def test_reader_pin_and_restricted_output_guard(self):
        config=json.loads((ROOT/'config/common_index_preparation.example.json').read_text())
        config['upstream_revision']='unreviewed'
        with self.assertRaisesRegex(prep.PreparationError,'reader pin'):
            prep.pinned_readers(config)
        path=ROOT/'reports/ARTIFICIAL_UNIGNORED_PREPARATION_OUTPUT'
        self.assertFalse(path.exists())
        run=subprocess.run(['python3',str(ROOT/'scripts/prepare_common_index_input.py'),'--config','missing.json','--output',str(path)],capture_output=True,text=True)
        self.assertNotEqual(run.returncode,0);self.assertFalse(path.exists())
        self.assertIn('must be ignored',run.stderr)

    def test_typed_R_roundtrip_preserves_keys_dates_missingness_and_precision(self):
        with tempfile.TemporaryDirectory() as path:
            root=Path(path);source=root/'ARTIFICIAL.csv';dest=root/'ARTIFICIAL.rds'
            data=dict(patient_id="0001",encounter_id="00001",encounter_date="2022-01-01",age_at_encounter=50,
                encounter_type="EMER",bmi=30.2,sex="",race_ethnicity="A",location="R",has_abg=1,has_vbg=0,
                abg_pco2=44.9999999,vbg_pco2="",icd_hypercapnia=0)
            with source.open('w',newline='') as file:
                writer=csv.DictWriter(file,fieldnames=prep.OUTPUT_COLUMNS);writer.writeheader();writer.writerow(data)
            run=subprocess.run(['Rscript','--vanilla',str(ROOT/'scripts/write_common_index_input.R'),str(source),str(dest)],cwd=ROOT,check=True,capture_output=True,text=True)
            self.assertNotIn('0001',run.stdout);self.assertNotIn('44.999',run.stdout)
            code='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(x$patient_id=="0001",x$encounter_id=="00001",inherits(x$encounter_date,"Date"),is.na(x$sex),is.na(x$vbg_pco2),x$abg_pco2<45,x$bmi==30.2)'
            subprocess.run(['Rscript','--vanilla','-e',code,str(dest)],check=True,capture_output=True)


if __name__=='__main__':unittest.main()
