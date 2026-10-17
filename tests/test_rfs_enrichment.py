"""Read-only metadata join tests; artificial original keys only."""
import importlib
import sys
from pathlib import Path
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
try:
    import pandas as pd
except ImportError:
    pd=None

@unittest.skipIf(pd is None,'pandas is required by the existing preparation environment')
class RfsMetadataTests(unittest.TestCase):
    def setUp(self):
        self.module=importlib.import_module('enrich_rfs_input')
        self.keys=pd.DataFrame({'patient_id':['001','002'],'encounter_id':['a','b'],'bmi':[40.,45.]})
        self.original=self.keys[['patient_id','encounter_id']].copy()
        for f in self.module.RFS_COLUMNS:self.original[f]=[1.,0.]
        self.original['race']=[0,1];self.original['ethnicity']=[2,0]
    def test_flags_follow_exact_encounter_not_patient(self):
        result=self.module.join_metadata(self.keys.iloc[::-1],self.original)
        self.assertEqual(list(result.OBESITY_rfs),[0.,1.])
        self.assertEqual(list(result.patient_id),['002','001'])
    def test_unknown_not_zero(self):
        self.original.loc[0,'ABG_rfs']=float('nan')
        self.assertTrue(pd.isna(self.module.join_metadata(self.keys,self.original).ABG_rfs[0]))
    def test_duplicate_rejected(self):
        with self.assertRaisesRegex(ValueError,'duplicate'):
            self.module.join_metadata(self.keys,pd.concat([self.original,self.original.iloc[:1]]))
    def test_uncovered_rejected(self):
        with self.assertRaisesRegex(ValueError,'uncovered'):
            self.module.join_metadata(self.keys,self.original.iloc[:1])
    def test_dictionary_rejected(self):
        self.original.loc[0,'ABG_rfs']=2
        with self.assertRaisesRegex(ValueError,'dictionary'):
            self.module.join_metadata(self.keys,self.original)
if __name__=='__main__':unittest.main()
