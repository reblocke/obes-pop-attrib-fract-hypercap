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
try:
    import duckdb
    from trinetx_preprocessing.combined_preprocessing.cohort_source_calendar_population import build_calendar_candidate_fields
except ImportError:
    duckdb = None

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("preparation",ROOT/"scripts/prepare_common_index_input.py")
prep=importlib.util.module_from_spec(spec);spec.loader.exec_module(prep)


@unittest.skipIf(pd is None,"Installed pandas is unavailable; run in the existing upstream Python environment")
class ArtificialAdapterFlow(unittest.TestCase):
    @unittest.skipIf(duckdb is None,"Run the SQL projection check in the existing pinned upstream environment")
    def test_bounded_projection_retains_raw_consensus_and_all_partitions(self):
        c=duckdb.connect()
        self.addCleanup(c.close)
        c.execute('CREATE TABLE source_patient(patient_id VARCHAR,year_of_birth VARCHAR)')
        c.executemany('INSERT INTO source_patient VALUES (?,?)',[("p1","1980"),("p2","1970"),("p3",None)])
        c.execute('CREATE TABLE source_encounter(patient_id VARCHAR,encounter_id VARCHAR,start_date VARCHAR,start_timestamp_precision VARCHAR,type VARCHAR)')
        c.executemany('INSERT INTO source_encounter VALUES (?,?,?,?,?)',[
            ("p1","e1","20220101","date_only","EMER"),("p1","e1","20220101","date_only","EMER"),
            ("p1","e2","20220102","date_only","IMP"),("p1","e2","20220103","date_only","IMP"),
            ("p2","e3","invalid","date_only",None),("p2","e4","20230101","date_only","AMB"),
            ("p3","e5",None,None,"UNKNOWN"),(None,"e6","20220101","date_only","EMER")])
        expected=build_calendar_candidate_fields(c,output_relation="expected")
        keys=pd.DataFrame([(r[0],r[1]) for r in c.execute('SELECT patient_id,encounter_id FROM expected').fetchall()],columns=['patient_id','encounter_id'])
        actual,scoped=prep.build_bounded_candidate_fields(c,build_calendar_candidate_fields,keys,["AMB","EMER","IMP","UNKNOWN"],["EMER","IMP","UNKNOWN"])
        self.assertEqual(vars(actual),vars(expected))
        wanted=c.execute("SELECT patient_id,encounter_id,encounter_start_date,encounter_type FROM expected "
            "WHERE (encounter_start_date IS NULL OR year(encounter_start_date)=2022) "
            "AND (encounter_type IS NULL OR encounter_type IN ('EMER','IMP','UNKNOWN')) "
            "AND (year_of_birth IS NULL OR 2022-year_of_birth>=18)").fetchdf()
        order=lambda x:x.sort_values(['patient_id','encounter_id']).reset_index(drop=True)
        pd.testing.assert_frame_equal(order(scoped),order(wanted))
        self.assertEqual(actual.invalid_encounter_key_rows,1)
        self.assertEqual(actual.conflicting_start_keys,1)
        self.assertEqual(actual.exact_encounter_keys,5)
        with self.assertRaisesRegex(prep.PreparationError,'lack legacy mappings: .*source partition'):
            prep.build_bounded_candidate_fields(c,build_calendar_candidate_fields,
                keys.loc[(keys.patient_id=="p1") & (keys.encounter_id=="e1")],["AMB","EMER","IMP","UNKNOWN"],["EMER","IMP","UNKNOWN"])
        with self.assertRaisesRegex(prep.PreparationError,'unmapped source setting'):
            prep.build_bounded_candidate_fields(c,build_calendar_candidate_fields,keys,["IMP"],["IMP"])

    def test_accepted_stata_full_data_decoding(self):
        # Independent Stata dictionary/rule expectations; not clinical validation.
        rows=[]
        for i,(race,ethnicity) in enumerate([(0,0),(2,0),(2,1),(1,1),(3,1),(4,0),(5,1)]):
            rows.append(dict(patient_id=f"{i:03}",encounter_id=f"{i:04}",encounter_date=22646.,
                age_at_encounter=50.,encounter_type=2,bmi=30.2,sex=0.,race=race,
                ethnicity=ethnicity,location=3.))
        raw=pd.DataFrame(rows);raw.loc[6,"encounter_date"]=float("nan")
        raw.loc[6,"sex"]=float("nan")
        mapping={name:name for name in prep.BASE_COLUMNS}
        out=prep.decode_base_fields(raw,mapping,"accepted_stata_full_data_v1")
        self.assertEqual(out.race_ethnicity.tolist(),["0","6","2","1","3","4","5"])
        self.assertEqual(out.encounter_date.iloc[0],prep.parsed_date("2022-01-01"))
        self.assertTrue(pd.isna(out.encounter_date.iloc[6]))
        self.assertTrue(pd.isna(out.sex.iloc[6]))
        self.assertEqual(out.encounter_type.tolist(),["2"]*7)
        self.assertEqual(out.patient_id.iloc[0],"000")
        self.assertEqual(out.bmi.tolist(),[30.2]*7)
        for column,value in [("encounter_date",22646.5),("encounter_type",4),("race",9),("race",float("nan"))]:
            broken=raw.copy();broken.loc[0,column]=value
            with self.subTest(column=column,value=value),self.assertRaises(prep.PreparationError):
                prep.decode_base_fields(broken,mapping,"accepted_stata_full_data_v1")
        with self.assertRaises(prep.PreparationError):prep.decode_base_fields(raw,mapping,"unreviewed")

    def test_preparation_to_R_manifest_and_coverage_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);evidence=root/"ARTIFICIAL-evidence";evidence.write_text("ARTIFICIAL only")
            entry=dict(path=str(evidence),sha256=prep.sha256(evidence))
            config=json.loads((ROOT/"config/common_index_preparation.example.json").read_text())
            config.update(source_identity="ARTIFICIAL adapter test",_config_sha256="0"*64,base_field_encoding="typed_v1",
                specimen_codes={"ART":"abg","VEN":"vbg"},diagnosis_capture_complete=True,
                diagnosis_code_systems=["ICD10CM"],encounter_type_codes={"EMER":"EMER","IMP":"IMP","UNKNOWN":"NA"},
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
            candidates.loc[2,"encounter_type"]="UNKNOWN"
            candidates["encounter_start_date"]=[pd.Timestamp("2022-01-01"),pd.Timestamp("2022-01-02"),pd.NaT]

            class Connection:
                def execute(self,sql,parameters=None):
                    if sql.startswith("CREATE TEMP TABLE bmi30_scoped_candidates"):
                        return None
                    if sql.startswith("SELECT count(*) FROM bmi30_scoped_candidates"):
                        candidate_keys=set(zip(candidates.patient_id,candidates.encounter_id))
                        feature_keys=set(zip(features.patient_id,features.encounter_id))
                        return SimpleNamespace(fetchone=lambda:(len(candidate_keys-feature_keys),))
                    if sql.startswith("SELECT count(DISTINCT"):
                        return SimpleNamespace(fetchone=lambda:(0,))
                    if sql.startswith("SELECT DISTINCT d.code_system"):
                        return SimpleNamespace(fetchall=lambda:[("ICD10CM",)])
                    if sql.startswith("SELECT patient_id,encounter_id,encounter_start_date"):
                        return SimpleNamespace(fetchdf=lambda:candidates.copy())
                    raise AssertionError("Unexpected adapter query")
                def register(self,name,frame):
                    assert (name=="bmi30_study_keys" and len(frame)==3) or (name=="bmi30_legacy_keys" and len(frame)==4)

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
            def artificial_projection(connection,build,features,raw_types,acute_types):
                return build(connection),prep.scoped_candidate_frame(connection,features,acute_types)

            with patch.object(prep,"pinned_readers",return_value=readers),patch.object(prep,"build_bounded_candidate_fields",side_effect=artificial_projection):
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
                code='for(f in c("bmi_hypercapnia_triangulation.R","triangulation_reporting.R","common_index_hypercapnia.R"))source(file.path("R",f));a<-commandArgs(TRUE);x<-load_common_input(a[1],a[2])$data;stopifnot(nrow(x)==4,x$patient_id[1]=="001",x$abg_pco2[1]==45,is.na(x$abg_pco2[2]),is.na(x$encounter_date[3]),is.na(x$encounter_type[3]))'
                run=subprocess.run(["Rscript","--vanilla","-e",code,str(output/"study-input.rds"),str(path)],cwd=ROOT,capture_output=True,text=True)
                self.assertEqual(run.returncode,0,run.stderr)
                # A reviewed unknown legacy setting does not contradict known raw evidence.
                features.loc[features.encounter_id=="0001","encounter_type"]="UNKNOWN"
                unknown_output=root/"unknown-legacy-output";unknown_output.mkdir()
                prep.prepare(config,unknown_output)
                unknown_code='x<-readRDS(commandArgs(TRUE)[1]);stopifnot(x$encounter_type[1]=="EMER",is.na(x$encounter_type[3]))'
                run=subprocess.run(["Rscript","--vanilla","-e",unknown_code,str(unknown_output/"study-input.rds")],cwd=ROOT,capture_output=True,text=True)
                self.assertEqual(run.returncode,0,run.stderr)
                features.loc[features.encounter_id=="0001","encounter_type"]="EMER"
                # Real FULL_DATA layout has coded factors, Stata days and separate race/ethnicity.
                features["race"]=0.;features["ethnicity"]=0.;features.drop(columns="race_ethnicity",inplace=True)
                features["sex"]=features.sex.map({"F":0.,"M":1.})
                features["location"]=0.
                features["encounter_date"]=[22646.,22647.,float("nan"),22646.]
                features["encounter_type"]=features.encounter_type.map({"EMER":2,"IMP":3})
                config["base_field_encoding"]="accepted_stata_full_data_v1"
                config["encounter_type_codes"].update({"1":"OTHER","2":"EMER","3":"IMP"})
                legacy_output=root/"legacy-output";legacy_output.mkdir()
                legacy_receipt=prep.prepare(config,legacy_output)
                self.assertEqual(legacy_receipt["base_field_encoding"],"accepted_stata_full_data_v1")
                legacy_code='a<-commandArgs(TRUE);x<-readRDS(a[1]);stopifnot(nrow(x)==4,x$patient_id[1]=="001",as.character(x$encounter_date[1])=="2022-01-01",x$race_ethnicity[1]=="0",is.na(x$sex[3]),is.na(x$bmi[3]))'
                run=subprocess.run(["Rscript","--vanilla","-e",legacy_code,str(legacy_output/"study-input.rds")],cwd=ROOT,capture_output=True,text=True)
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
