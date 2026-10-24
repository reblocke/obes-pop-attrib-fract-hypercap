"""Source-boundary oracle: code transport corruption is not exercised by typed R E2E."""
import sys
from pathlib import Path
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from enrich_icd_acuity import derive_codes, CODES, PreparationError

class AcuitySourceBoundary(unittest.TestCase):
    def record(self,code,identity='r1',patient='p'):
        return dict(patient_id=patient,encounter_id='e',source_record_id=identity,code=code,code_system='ICD-10-CM')
    def test_transport_to_flags(self):
        rows=[self.record(c,str(i)) for i,c in enumerate(CODES)]
        result=derive_codes(rows,True,['ICD-10-CM'],('p','e'))
        self.assertEqual(result['icd_capture_state'],'complete')
        self.assertEqual([result['icd_'+c.replace('.','')] for c in CODES],[1]*5)
        self.assertEqual(result,derive_codes(rows+rows,True,['ICD-10-CM'],('p','e')))
        self.assertTrue(all(v==0 for k,v in derive_codes([],True,['ICD-10-CM'],('p','e')).items() if k.startswith('icd_J') or k=='icd_E662'))
        unknown=derive_codes(rows[:1],False,['ICD-10-CM'],('p','e'))
        self.assertEqual(unknown['icd_capture_state'],'incomplete')
        self.assertEqual(unknown['icd_J9602'],1)
        self.assertIsNone(unknown['icd_J9612'])
    def test_corrupt_records_fail(self):
        for rows in ([self.record('J96.02'),self.record('J96.12')],
                     [self.record('J96.02',patient='other')],
                     [self.record('J96.01')],
                     [dict(self.record('J96.02'),code_system='unreviewed')]):
            with self.assertRaises(PreparationError):derive_codes(rows,True,['ICD-10-CM'],('p','e'))
