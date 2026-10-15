"""Exercise orchestration with artificial reader stand-ins, not private acceptance."""
from contextlib import contextmanager
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

try:
    import pandas as pd
except ImportError:
    pd = None

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("preparation",ROOT/"scripts/prepare_common_index_input.py")
prep=importlib.util.module_from_spec(spec);spec.loader.exec_module(prep)


@unittest.skipIf(pd is None,"Installed pandas is unavailable; run in the existing upstream Python environment")
class ArtificialAdapterFlow(unittest.TestCase):
    def test_preparation_to_R_manifest_and_coverage_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);evidence=root/"ARTIFICIAL-evidence";evidence.write_text("ARTIFICIAL only")
            entry=dict(path=str(evidence),sha256=prep.sha256(evidence))
            config=json.loads((ROOT/"config/common_index_preparation.example.json").read_text())
            config.update(source_identity="ARTIFICIAL adapter test",_config_sha256="0"*64,
                specimen_codes={"ART":"abg","VEN":"vbg"},diagnosis_capture_complete=True,
                diagnosis_code_systems=["ICD10CM"],encounter_type_codes={"EMER":"EMER","IMP":"IMP"},
                index_day_status="qualified",columns={name:name for name in prep.BASE_COLUMNS},
                source_evidence_files={name:entry for name in ("lineage","population","fields")})
            config["canonical_source"].update(database=entry,sidecar=entry)
            config["canonical_source"]["spill_root"]=str(root/"private-spill")
            config["encounter_bundle"].update(path=str(root/"accepted"),receipt_path=str(evidence),validation_report_path=str(evidence),expected_receipt_sha256=entry["sha256"])
            frames=pd.DataFrame([
                ["001","0001","2022-01-01",50,"EMER",30.2,"F","A","R"],
                ["002","0002","2022-01-02",60,"IMP",40,"M","A","R"],
                ["003","0003",None,60,"IMP",None,None,"A","R"]],columns=prep.BASE_COLUMNS)
            # Exact repeated source rows remain in the typed input for cohort accounting.
            features=pd.concat([frames,frames.iloc[[0]]],ignore_index=True)
            candidates=frames[["patient_id","encounter_id","encounter_type"]].copy()
            candidates["encounter_start_date"]=[pd.Timestamp("2022-01-01"),pd.Timestamp("2022-01-02"),pd.NaT]

            class Connection:
                def execute(self,sql,parameters):
                    if sql.startswith("SELECT count(DISTINCT"):
                        return SimpleNamespace(fetchone=lambda:(0,))
                    if sql.startswith("SELECT DISTINCT d.code_system"):
                        return SimpleNamespace(fetchall=lambda:[("ICD10CM",)])
                    if sql.startswith("SELECT patient_id,encounter_id,encounter_start_date"):
                        return SimpleNamespace(fetchdf=lambda:candidates.copy())
                    raise AssertionError("Unexpected adapter query")
                def register(self,name,frame):
                    assert name=="bmi30_study_keys" and len(frame)==3

            @contextmanager
            def opened(database,**kwargs):
                yield SimpleNamespace(connection=Connection())

            def accepted_features(path,**kwargs):
                assert kwargs["variant"]=="FULL_DATA"
                return features[kwargs["columns"]].copy()

            def stream(connection,*,encounter_relation,domain,code_selectors):
                assert encounter_relation=="bmi30_study_keys"
                for i in range(3):
                    row=None;state="zero_matches"
                    if domain=="lab" and i<2:
                        row=dict(source_record_id=f"ARTIFICIAL-{i}",numeric_value=45 if i==0 else 300,
                            code="2019-8",units_of_measure_raw="mm Hg",date="2022-01-01")
                        state="matched"
                    if domain=="diagnosis" and i==1:
                        row=dict(code="E66.2",source_record_id="ARTIFICIAL-D1");state="matched"
                    yield SimpleNamespace(patient_id=f"{i+1:03}",encounter_id=f"{i+1:04}",record=row,state=state)

            readers={"encounters.reader":SimpleNamespace(read_encounters=accepted_features,verify_accepted_bundle=lambda *a,**k:None),
                "combined_preprocessing.cohort_source":SimpleNamespace(open_cohort_source=opened),
                "combined_preprocessing.cohort_source_calendar_population":SimpleNamespace(
                    build_calendar_candidate_fields=lambda *a,**k:SimpleNamespace(invalid_encounter_key_rows=0)),
                "combined_preprocessing.cohort_source_calendar_transport":SimpleNamespace(iter_calendar_source_records=stream)}
            output=root/"output";output.mkdir()
            with patch.object(prep,"pinned_readers",return_value=readers):
                receipt=prep.prepare(config,output)
                self.assertEqual(receipt["candidate_encounter_keys"],3)
                self.assertEqual(receipt["input_rows"],4)
                self.assertEqual(receipt["unresolved_source_date_rows"],1)
                self.assertFalse(receipt["clinical_results_qualified"])
                manifest=json.loads((output/"triangulation_input.pending.json").read_text())
                self.assertTrue(all(x=="PENDING_REVIEW" for x in manifest["source_qualification"].values()))
                manifest.update(reviewed_by="ARTIFICIAL fixture only",reviewed_on="2026-10-15",evidence_reference="ARTIFICIAL, not clinical acceptance")
                manifest["source_qualification"]={name:"accepted" for name in manifest["source_qualification"]}
                path=output/"ARTIFICIAL-reviewed.json";path.write_text(json.dumps(manifest))
                code='for(f in c("bmi_hypercapnia_triangulation.R","triangulation_reporting.R","common_index_hypercapnia.R"))source(file.path("R",f));a<-commandArgs(TRUE);x<-load_common_input(a[1],a[2])$data;stopifnot(nrow(x)==4,x$patient_id[1]=="001",x$abg_pco2[1]==45,is.na(x$abg_pco2[2]),is.na(x$encounter_date[3]))'
                run=subprocess.run(["Rscript","--vanilla","-e",code,str(output/"study-input.rds"),str(path)],cwd=ROOT,capture_output=True,text=True)
                self.assertEqual(run.returncode,0,run.stderr)
                candidates.loc[2,"patient_id"]="999"
                failed=root/"failed";failed.mkdir()
                with self.assertRaisesRegex(prep.PreparationError,"lack legacy mappings"):
                    prep.prepare(config,failed)
                self.assertFalse((failed/"study-input.rds").exists())
                candidates.loc[2,"patient_id"]="003"
                candidates.drop(index=1,inplace=True)
                failed_reverse=root/"failed-reverse";failed_reverse.mkdir()
                with self.assertRaisesRegex(prep.PreparationError,"contradict captured scope"):
                    prep.prepare(config,failed_reverse)
                self.assertFalse((failed_reverse/"study-input.rds").exists())


if __name__=="__main__":unittest.main()
