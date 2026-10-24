#!/usr/bin/env python3
"""Fresh code-level enrichment from the accepted diagnosis capture; no model fitting."""
import argparse
import csv
import json
import subprocess
from pathlib import Path
from prepare_common_index_input import (PreparationError,pinned_readers,verify_file,
    verify_canonical_database,file_identity,sha256)
CODES=('J96.02','J96.12','J96.22','J96.92','E66.2')
FLAGS=tuple('icd_'+c.replace('.','') for c in CODES)
FIELDS=('icd_capture_state',*FLAGS)

def derive_codes(records,complete,systems,key,unavailable=False):
    result={f:0 if complete and not unavailable else None for f in FLAGS}
    result['icd_capture_state']='unavailable' if unavailable else 'complete' if complete else 'incomplete'
    seen={}
    for r in records:
        if (r.get('patient_id'),r.get('encounter_id'))!=key:
            raise PreparationError('Diagnosis record belongs to another original key')
        identity=r.get('source_record_id');signature=json.dumps(r,sort_keys=True,default=str)
        if not identity:raise PreparationError('Missing diagnosis source identity')
        if identity in seen and seen[identity]!=signature:raise PreparationError('Conflicting diagnosis source identity')
        seen[identity]=signature
        code=str(r.get('code') or '').strip().upper().replace('.','')
        if r.get('code_system') not in systems or 'icd_'+code not in FLAGS:
            raise PreparationError('Unexpected diagnosis code or code system')
        result['icd_'+code]=1
    return result

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ('input','manifest','source-config','output'):ap.add_argument('--'+k,required=True)
    args=ap.parse_args();out=Path(args.output).resolve()
    if out.exists():raise PreparationError('Output must be fresh')
    config=json.loads(Path(args.source_config).read_text());manifest=json.loads(Path(args.manifest).read_text())
    if sha256(args.input)!=manifest['input_sha256']:raise PreparationError('Original input hash mismatch')
    lineage=manifest['source_evidence_files']['lineage'].copy()
    if not Path(lineage['path']).is_absolute():lineage['path']=str(Path(args.manifest).resolve().parent/lineage['path'])
    source=config['canonical_source']
    if json.loads(verify_file(lineage).read_text())['canonical_database_sha256']!=source['database']['sha256']:
        raise PreparationError('ICD source differs from original lineage')
    systems=config.get('diagnosis_code_systems');complete=config.get('diagnosis_capture_complete')
    if not isinstance(systems,list) or not systems or not all(isinstance(s,str) and s.strip() for s in systems) or not isinstance(complete,bool):
        raise PreparationError('Reviewed diagnosis systems and explicit capture policy required')
    database=verify_canonical_database(source);verify_file(source['sidecar'])
    before=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config))
    code_files=('scripts/enrich_icd_acuity.py','scripts/enrich_icd_acuity.R')
    hashes={p:sha256(p) for p in code_files}
    readers=pinned_readers(config);out.mkdir(parents=True,mode=0o700)
    command=[config.get('rscript','Rscript'),'--vanilla','scripts/enrich_icd_acuity.R']
    subprocess.run(command+['export',args.input,args.manifest,str(out)],check=True)
    import pandas as pd
    keys=pd.read_csv(out/'keys.csv',dtype=str,keep_default_na=False)
    if keys.duplicated().any() or (keys=='').any().any():raise PreparationError('Invalid study keys')
    seen=set();n_records=0;expected=0
    with readers['combined_preprocessing.cohort_source'].open_cohort_source(database,
        expected_catalog_sha256=source['catalog_sha256'],spill_root=Path(source['spill_root']),memory_limit_mib=2816) as opened:
        c=opened.connection;c.register('icd_study_keys',keys)
        target=[x.replace('.','') for x in CODES]
        expected=c.execute("SELECT count(*) FROM source_diagnosis d JOIN icd_study_keys k USING(patient_id,encounter_id) WHERE replace(upper(trim(d.code)),'.','')=ANY(?)",[target]).fetchone()[0]
        source_systems={r[0] for r in c.execute("SELECT DISTINCT d.code_system FROM source_diagnosis d JOIN icd_study_keys k USING(patient_id,encounter_id) WHERE replace(upper(trim(d.code)),'.','')=ANY(?)",[target]).fetchall()}
        if not source_systems<=set(systems):raise PreparationError('Unreviewed target-like source code system')
        stream=readers['combined_preprocessing.cohort_source_calendar_transport'].iter_calendar_source_records(c,
            encounter_relation='icd_study_keys',domain='diagnosis',code_selectors=[(s,form) for s in systems for code in CODES for form in (code,code.replace('.',''))])
        with (out/'icd-acuity.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=['patient_id','encounter_id',*FIELDS]);writer.writeheader()
            previous=None;records=[];unavailable=False
            def flush(key,rows,missing):
                if key in seen:raise PreparationError('Noncontiguous repeated diagnosis key')
                seen.add(key)
                writer.writerow(dict(patient_id=key[0],encounter_id=key[1],**derive_codes(rows,complete,systems,key,missing)))
            for item in stream:
                key=(item.patient_id,item.encounter_id)
                if previous is not None and key!=previous:
                    flush(previous,records,unavailable);records=[];unavailable=False
                previous=key;unavailable |= item.state in ('unavailable_domain','unavailable_field')
                if item.record is not None:records.append(item.record);n_records+=1
            if previous is not None:flush(previous,records,unavailable)
    if seen!=set(map(tuple,keys.to_numpy())):raise PreparationError('ICD query did not account for every original key')
    if n_records!=expected:raise PreparationError('ICD transport/source count mismatch')
    if before!=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config)) or hashes!={p:sha256(p) for p in code_files}:
        raise PreparationError('ICD source/input/code changed during enrichment')
    evidence=dict(schema_version=1,policy_id='icd_acuity_v1',status='qualified' if complete else 'unavailable',
        base_input_sha256=before[1],base_manifest_sha256=before[2],source_config_sha256=before[3],
        canonical_database_sha256=source['database']['sha256'],source_unchanged=True,
        diagnosis_capture_complete=complete,diagnosis_code_systems=systems,target_codes=target,
        n_input_encounters=len(keys),source_target_records=expected,transported_records=n_records,
        adapter_sources=hashes,icd_summary_sha256=sha256(out/'icd-acuity.csv'),clinical_models_fitted=0,
        human_review='not asserted by automated extraction')
    (out/'icd-acuity-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
    subprocess.run(command+['enrich',args.input,args.manifest,str(out)],check=True)
    for p in out.iterdir():p.chmod(0o600)
    print('ICD acuity enrichment:',out,'status:',evidence['status'])
if __name__=='__main__':main()
