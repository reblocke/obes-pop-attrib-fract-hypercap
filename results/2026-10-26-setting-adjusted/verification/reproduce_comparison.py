"""Bounded aggregate-only reconciliation for the approved setting update."""
from pathlib import Path
import csv, hashlib, json, math, sys
run, prior, out = map(Path, sys.argv[1:4]);out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text())
nm=read(run/'bundle_manifest.json');pm=read(prior/'manifest.json');receipt=read(run/'input_receipt.json')
assert nm['schema_version']==14 and nm['analysis_id']=='bmi_hypercapnia_rfs_curve_audit_v9' and nm['mode']=='clinical'
for name,h in nm['files'].items():assert sha(run/name)==h,name
for name,entry in pm['files'].items():assert sha(prior/name)==entry['sha256'],name
assert receipt['input_sha256']==pm['source_input_sha256']
assert receipt['manifest_sha256']==pm['source_input_manifest_sha256']
assert receipt['code_identity']['working_tree_clean']
def table(root,name,old=False):
 with (root/('tables' if old else '')/(name+'.csv')).open() as f:return list(csv.DictReader(f))
def write(name,rows):
 if not rows:return
 with (out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
checks=[]
def equal(x,y):
 try:return math.isclose(float(x),float(y),rel_tol=1e-11,abs_tol=1e-10)
 except (TypeError,ValueError):return x==y
specs={
 'cohort_nodes':(['population_id'],['n','n_records','n_patients','grain','status']),
 'rfs_summary':(['population_id'],['n','complete','incomplete']),
 'model_registry':(['model_id'],['n_model','n_events','n_nonevents','n_eligible','training_population_id','basis_id']),
 'bmi_basis':(['analysis_population_id','knot_probability'],['knot','basis_id','reference_id']),
 'cooccurrence_categories':(['analysis_population_id','category_id'],['n','N']),
 'icd_acuity_categories':(['analysis_population_id','category_id'],['n','N']),
 'evidence_by_bmi':(['population_id','outcome_id','window','bin_low'],['N','M','H','observation']),
 'observation_patterns':(['population_id','window','pattern'],['n','n_reference']),
 'policy_totals':(['model_id','policy_id','method'],['n_model','n_reference','n_shifted','pct_shifted'])}
for name,(keys,fields) in specs.items():
 old={tuple(r[k] for k in keys):r for r in table(prior,name,True)}
 new={tuple(r[k] for k in keys):r for r in table(run,name)}
 assert len(new)==len(table(run,name)),name
 missing=set(old)-set(new)
 for key in sorted(missing):checks.append(dict(table=name,key='|'.join(key),field='membership',prior='present',current='missing',passed=False))
 for key in sorted(set(old)&set(new)):
  for field in fields:
   if name=='policy_totals' and field in ['n_shifted','pct_shifted'] and (old[key].get('status')!='estimated' or new[key].get('status')!='estimated'):continue
   checks.append(dict(table=name,key='|'.join(key),field=field,prior=old[key].get(field,''),current=new[key].get(field,''),passed=equal(old[key].get(field,''),new[key].get(field,''))))
 for key in sorted(set(new)-set(old)):
  row=new[key]
  # Only new explicit zero-count missing-setting ledger positions are expected.
  checks.append(dict(table=name,key='|'.join(key),field='new_position',prior='absent',current=row.get('n','present'),passed=name=='cohort_nodes' and key[0].endswith('missing_encounter_type') and equal(row['n'],'0')))
write('unchanged-samples-and-basis.csv',checks)
newmodels=table(run,'model_registry');oldmodels={r['model_id']:r for r in table(prior,'model_registry',True)}
write('model-status-comparison.csv',[dict(model_id=r['model_id'],prior_status=oldmodels[r['model_id']]['status'],current_status=r['status'],n_model=r['n_model'],failure_reason=r['failure_reason']) for r in newmodels])
landmarks=[]
for name in ['probability_curves','observation_curves']:
 keys=['model_id','outcome_id','window','bmi'];old={tuple(r[k] for k in keys):r for r in table(prior,name,True)}
 for r in table(run,name):
  if r['analysis_population_id'] not in ['primary','primary_bmi_ge30'] or r['bmi'] not in ['30','40','50']:continue
  key=tuple(r[k] for k in keys);prev=old.get(key,{})
  entry={k:r[k] for k in ['analysis_population_id','model_id','outcome_id','window','bmi','n_model','n_reference']}
  for label,z in [('prior',prev),('current',r)]:
   for field in ['probability','conf_low','conf_high']:entry[label+'_'+field]=z.get(field,'')
  try:entry['change_percentage_points']=100*(float(r['probability'])-float(prev['probability']))
  except (ValueError,KeyError):entry['change_percentage_points']=''
  entry['status']=r['status'];landmarks.append(entry)
write('curve-landmark-comparison.csv',landmarks)
full_curves=[]
for name in ['probability_curves','observation_curves']:
 keys=['model_id','outcome_id','window','bmi']
 old={tuple(r[k] for k in keys):r for r in table(prior,name,True)}
 for r in table(run,name):
  if r['analysis_population_id'] not in ['primary','primary_bmi_ge30']:continue
  prev=old.get(tuple(r[k] for k in keys),{})
  entry={k:r[k] for k in ['analysis_population_id','model_id','outcome_id','window','bmi','n_model','n_reference']}
  for label,z in [('prior',prev),('current',r)]:
   for field in ['probability','conf_low','conf_high']:entry[label+'_'+field]=z.get(field,'')
  entry['status']=r['status'];full_curves.append(entry)
write('curve-comparison.csv',full_curves)

old={tuple(r[k] for k in ['model_id','policy_id','method']):r for r in table(prior,'policy_totals',True)}
policies=[]
for r in table(run,'policy_totals'):
 prev=old[tuple(r[k] for k in ['model_id','policy_id','method'])]
 entry={k:r[k] for k in ['analysis_population_id','model_id','policy_id','n_model','n_reference','n_shifted','pct_shifted','status']}
 for label,z in [('prior',prev),('current',r)]:
  for field in ['p_observed','p_shifted','difference_per1000','difference_low_per1000','difference_high_per1000','PIF','PIF_low','PIF_high']:entry[label+'_'+field]=z[field]
 policies.append(entry)
write('policy-comparison.csv',policies)
refresh=[]
for r in landmarks:
 if r['window']!='encounter' or r['model_id'].split('::')[1] not in ['abg/encounter/spline','any_gas/encounter/spline','icd/encounter/spline','same_day_abg/encounter/multinomial_spline','observation/abg/encounter','observation/vbg/encounter']:continue
 refresh.append(dict(kind='probability',population=r['analysis_population_id'],model_id=r['model_id'],outcome_id=r['outcome_id'],bmi=r['bmi'],estimate=r['current_probability'],conf_low=r['current_conf_low'],conf_high=r['current_conf_high'],unit='probability; multiply by 100 for percent',n=r['n_reference'],status=r['status']))
for r in policies:
 if r['analysis_population_id'] not in ['primary','primary_bmi_ge30'] or r['model_id'].split('::')[1] not in ['abg/encounter/spline','any_gas/encounter/spline','icd/encounter/spline']:continue
 refresh.append(dict(kind='PIF',population=r['analysis_population_id'],model_id=r['model_id'],outcome_id=r['model_id'].split('::')[1].split('/')[0],bmi='',estimate=r['current_PIF'],conf_low=r['current_PIF_low'],conf_high=r['current_PIF_high'],unit='fraction; multiply by 100 for percent',n=r['n_reference'],status=r['status']))
write('abstract-values-to-refresh.csv',refresh)
summary={'status':'passed' if all(r['passed'] for r in checks) else 'failed','checks':len(checks),'failures':sum(not r['passed'] for r in checks),'source_input_unchanged':True,'source_manifest_unchanged':True,'new_bundle_manifest_sha256':sha(run/'bundle_manifest.json'),'prior_snapshot_manifest_sha256':sha(prior/'manifest.json'),'new_code_identity':receipt['code_identity'],'clinical_input_reads':0,'model_refits':0,'comparison_source_sha256':sha(Path(__file__)),'comparison_uncertainty':'Old/new differences are descriptive; no cross-model difference interval is inferred','investigator_review':'pending'}
(out/'comparison-receipt.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
if summary['failures']:raise SystemExit(3)
