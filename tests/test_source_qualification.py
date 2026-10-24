"""Independent qualification expectations on artificial records only."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
import json

try:
    import duckdb
    import pandas as pd
except ImportError:
    duckdb = pd = None

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
spec = importlib.util.spec_from_file_location('source_qualification', ROOT / 'scripts/qualify_common_index_source.py')
qa = importlib.util.module_from_spec(spec); spec.loader.exec_module(qa)


@unittest.skipIf(duckdb is None, 'Use the existing upstream Python environment')
class IndependentSourceChecks(unittest.TestCase):
    def test_qualification_cannot_rebind_another_preparation_config(self):
        with tempfile.TemporaryDirectory() as temp:
            prepared=Path(temp)/'prepared';prepared.mkdir()
            (prepared/'preparation_receipt.json').write_text(json.dumps({'source_config_sha256':'original'}))
            with self.assertRaisesRegex(ValueError,'configuration does not match'):
                qa.run({'_config_sha256':'different'},prepared,Path(temp)/'checks')

    def test_gas_specimens_later_day_and_captured_absence(self):
        c=duckdb.connect();self.addCleanup(c.close)
        c.execute('CREATE TABLE source_lab_measurement(patient_id VARCHAR,encounter_id VARCHAR,code_system VARCHAR,code VARCHAR,'
                  'numeric_value DOUBLE,lab_result_text_val VARCHAR,units_of_measure_raw VARCHAR,units_of_measure VARCHAR,'
                  'timestamp_precision VARCHAR,event_datetime TIMESTAMP)')
        c.execute("INSERT INTO source_lab_measurement VALUES "
                  "('p','a','LOINC','2019-8',42,NULL,'mm[hg]','mm[hg]','date_only','2022-01-01'),"
                  "('p','a','LOINC','2021-4',55,NULL,'mm[hg]','mm[hg]','date_only','2022-01-01'),"
                  "('q','b','LOINC','2021-4',45,NULL,'mm[hg]','mm[hg]','date_only','2022-01-01'),"
                  "('r','c','LOINC','2019-8',70,NULL,'mm[hg]','mm[hg]','date_only','2022-01-02')")
        c.execute('CREATE TABLE source_diagnosis(patient_id VARCHAR,encounter_id VARCHAR,code_system VARCHAR,code VARCHAR)')
        c.execute("INSERT INTO source_diagnosis VALUES ('p','a','ICD10CM','J96.02')")
        p=pd.DataFrame({'patient_id':['p','q','r'],'encounter_id':['a','b','c'],
            'encounter_date':pd.to_datetime(['2022-01-01']*3),'abg_pco2':[42,None,70],
            'vbg_pco2':[55,45,None],'abg_pco2_index_day':[42,None,None],
            'vbg_pco2_index_day':[55,45,None],'icd_hypercapnia':[1,0,0],
            'has_abg':[1,0,1],'has_vbg':[1,1,0],
            'abg_index_day_available':[1,0,0],'vbg_index_day_available':[1,1,0]})
        checks,_=qa.check_fields(c,p,True);self.assertTrue(all(v==0 for v in checks.values()))
        for table in ('expected_gases','expected_icd'):
            c.execute('DROP TABLE '+table)
        c.execute('DROP VIEW valid_gases');c.execute('DROP TABLE raw_gases')
        p.loc[0,'abg_pco2']=43;p.loc[0,'icd_hypercapnia']=0;p.loc[0,'has_abg']=0
        checks,_=qa.check_fields(c,p,True)
        self.assertEqual(checks['abg_pco2_disagreements'],1)
        self.assertEqual(checks['icd_disagreements'],1)
        self.assertEqual(checks['has_abg_disagreements'],1)

    def test_components_reconcile_independently_and_detect_corruption(self):
        c=duckdb.connect();self.addCleanup(c.close)
        c.execute("CREATE TABLE source_diagnosis(patient_id VARCHAR,encounter_id VARCHAR,code_system VARCHAR,code VARCHAR)")
        c.execute("INSERT INTO source_diagnosis VALUES ('p','a','ICD10CM','E66.2')")
        c.execute("CREATE TABLE source_lab_measurement(patient_id VARCHAR,encounter_id VARCHAR,code_system VARCHAR,code VARCHAR,numeric_value DOUBLE,units_of_measure_raw VARCHAR,units_of_measure VARCHAR,timestamp_precision VARCHAR,event_datetime TIMESTAMP)")
        c.execute("INSERT INTO source_lab_measurement VALUES ('p','a','LOINC','2019-8',50,'mm[hg]','mm[hg]','date_only','2022-01-01'),('p','a','LOINC','2744-1',7.30,'[pH]','[pH]','date_only','2022-01-01'),('p','a','LOINC','2744-1',7.20,'[pH]','[pH]','date_only','2022-01-02')")
        c.execute("ALTER TABLE source_lab_measurement ADD COLUMN lab_result_text_val VARCHAR")
        c.execute("INSERT INTO source_lab_measurement VALUES ('p','a','LOINC','2019-8',50,'mm[hg]','mm[hg]','date_only','2022-01-02','>50')")
        original=pd.DataFrame(dict(patient_id=['p'],encounter_id=['a'],race=[0],ethnicity=[1],**{name:[1 if name=='ABG_rfs' else 0] for name in qa.RFS_COLUMNS}))
        prepared=original.drop(columns=['race','ethnicity']).assign(raw_race=0,raw_ethnicity=1,icd_capture_state='complete',same_day_abg_state='coobserved_day',same_day_abg_n_days=1,hypercapnia_coobserved=1,hypercapnia_acidemia_same_day=1)
        for code in ('J9602','J9612','J9622','J9692','E662'):prepared['icd_'+code]=int(code=='E662')
        self.assertTrue(all(n==0 for n in qa.check_components(c,prepared,original,True,True).values()))
        prepared.loc[0,'ABG_rfs']=0;prepared.loc[0,'icd_E662']=0;prepared.loc[0,'hypercapnia_acidemia_same_day']=0
        errors=qa.check_components(c,prepared,original,True,True)
        self.assertEqual(errors['ABG_rfs_disagreements'],1)
        self.assertEqual(errors['icd_E662_disagreements'],1)
        self.assertEqual(errors['hypercapnia_acidemia_same_day_disagreements'],1)

    def test_known_missing_bmi_uncertain_setting_and_index_ties(self):
        c=duckdb.connect();self.addCleanup(c.close)
        c.execute("CREATE TABLE mapping(patient_id VARCHAR,encounter_id VARCHAR,encounter_date DATE,age_at_encounter INTEGER,"
                  "encounter_type VARCHAR,bmi DOUBLE,bmi_evidence_state VARCHAR,bmi_method VARCHAR,reported_date DATE,"
                  "height_inches DOUBLE,weight_pounds DOUBLE,reported_bmi FLOAT)")
        c.execute("INSERT INTO mapping VALUES "
                  "('p','a','2022-01-01',40,'EMER',NULL,'missing','none',NULL,NULL,NULL,NULL),"
                  "('p','b','2022-01-02',40,'EMER',35,'valid','prior','2022-01-01',NULL,NULL,35),"
                  "('q','c','2022-01-01',40,NULL,31,'valid','current','2022-01-01',NULL,NULL,31),"
                  "('q','d','2022-01-02',40,'EMER',33,'valid','current','2022-01-02',NULL,NULL,33),"
                  "('r','e','2022-01-01',40,'EMER',31,'valid','current','2022-01-01',NULL,NULL,31),"
                  "('r','f','2022-01-01',40,'IMP',32,'valid','current','2022-01-01',NULL,NULL,32),"
                  "('s','g','2022-01-01',40,'EMER',24,'valid','current','2022-01-01',NULL,NULL,24)")
        with tempfile.TemporaryDirectory() as temp:
            file=Path(temp)/'ARTIFICIAL.parquet'
            c.execute('COPY mapping TO ? (FORMAT PARQUET)',[str(file)])
            prepared=pd.DataFrame({'patient_id':['p','s'],'encounter_id':['b','g'],'bmi':[35,24]})
            census={'counts':{'n_frame_patients':4,'n_index_unresolved':2,'n_earliest_ties':1,'n_earlier_uncertainty':1}}
            checks,_=qa.check_indexes(c,file,prepared,census)
            self.assertTrue(all(v==0 for v in checks.values()),checks)
            for table in ('expected_indexes','index_status','first_known'):
                c.execute('DROP TABLE '+table)
            c.execute('DROP VIEW membership');c.execute('DROP VIEW source_mapping')
            c.execute("UPDATE mapping SET reported_date='2022-01-02' WHERE encounter_id='b'")
            invalid=Path(temp)/'INVALID-PRIOR.parquet'
            c.execute('COPY mapping TO ? (FORMAT PARQUET)',[str(invalid)])
            wrong=pd.concat([prepared,pd.DataFrame({'patient_id':['q'],'encounter_id':['d'],'bmi':[33]})])
            wrong.loc[wrong.patient_id=='p','bmi']=36
            checks,_=qa.check_indexes(c,invalid,wrong,census)
            self.assertEqual(checks['index_key_disagreements'],1)
            self.assertEqual(checks['invalid_prior_dates'],1)
            self.assertEqual(checks['prepared_bmi_disagreements'],1)


if __name__=='__main__':unittest.main()
