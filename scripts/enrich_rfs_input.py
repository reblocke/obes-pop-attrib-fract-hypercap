#!/usr/bin/env python3
"""Enrich a qualified study input from accepted metadata; never extract new gases or fit models."""
from __future__ import annotations
import argparse
import json
import subprocess
from pathlib import Path
from prepare_common_index_input import pinned_readers, sha256, verify_file, PreparationError
from original_encounter_population import read_original_list, RFS_COLUMNS, require_original_population

PROVENANCE = ['bmi_method','reported_bmi','reported_date','height_date','weight_date','height_inches','weight_pounds','bmi_reason']

def join_metadata(candidates, original):
    """Only original patient/encounter keys identify pathway membership."""
    import pandas as pd
    keys=['patient_id','encounter_id']
    if candidates.duplicated(keys).any() or original.duplicated(keys).any():
        raise PreparationError('Metadata join has duplicate original keys')
    wanted=keys+list(RFS_COLUMNS)+['race','ethnicity']
    out=candidates.merge(original[wanted],on=keys,how='left',validate='one_to_one',indicator=True)
    if len(out)!=len(candidates) or not out['_merge'].eq('both').all():
        raise PreparationError('Metadata join has uncovered candidate keys')
    for field in RFS_COLUMNS:
        if not out[field].dropna().isin([0,1]).all():
            raise PreparationError('RFS dictionary outside authenticated 0/1/NA')
    return out.drop(columns='_merge').rename(columns={'race':'raw_race','ethnicity':'raw_ethnicity'})

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-config',required=True);parser.add_argument('--input',required=True)
    parser.add_argument('--manifest',required=True);parser.add_argument('--rfs-evidence',required=True)
    parser.add_argument('--output',required=True);parser.add_argument('--prior-run',required=True)
    args=parser.parse_args(); output=Path(args.output)
    if output.exists():raise PreparationError('Output must be fresh')
    config=json.loads(Path(args.source_config).read_text());base=json.loads(Path(args.manifest).read_text())
    if sha256(args.input)!=base['input_sha256']:raise PreparationError('Prior input hash mismatch')
    fields_entry=base['source_evidence_files']['fields']
    fields_path=Path(fields_entry['path'])
    if not fields_path.is_absolute():fields_path=Path(args.manifest).parent/fields_path
    verify_file({'path':str(fields_path),'sha256':fields_entry['sha256']})
    prior_fields=json.loads(fields_path.read_text())
    if prior_fields.get('original_encounter_list',{}).get('receipt_sha256')!=config['encounter_bundle']['expected_receipt_sha256']:
        raise PreparationError('RFS metadata and prior clinical input have different accepted source identities')
    evidence_path=Path(args.rfs_evidence);evidence=json.loads(evidence_path.read_text())
    if evidence.get('policy_id')!='historical_source_membership_v1' or evidence.get('membership_semantics')!='selected_source_file_membership':
        raise PreparationError('RFS semantics must be authenticated before enrichment')
    if set(evidence.get('families',{}))!=set(RFS_COLUMNS):raise PreparationError('Incomplete RFS family evidence')
    required={'source_product','producer_revision','unit','anchor','allowed_values','zero_semantics','earliest_event_rule','relationship'}
    for family,definition in evidence['families'].items():
        if not required<=set(definition) or any(not isinstance(definition[k],str) or not definition[k].strip() or 'PENDING' in definition[k] for k in required):
            raise PreparationError('Incomplete authenticated family semantics: '+family)
    if evidence.get('accepted_receipt_sha256')!=config['encounter_bundle']['expected_receipt_sha256']:
        raise PreparationError('RFS evidence belongs to another accepted product')
    for entry in evidence.get('evidence_files',[]):verify_file(entry)
    if not evidence.get('evidence_files'):raise PreparationError('RFS evidence requires pinned producing source/receipts')
    mapping_path=verify_file(config['covariate_mapping']['manifest']);mapping=json.loads(mapping_path.read_text())
    require_original_population(config,mapping)
    readers=pinned_readers(config); original,audit=read_original_list(config,readers,include_metadata=True)
    product=verify_file({'path':str(mapping_path.parent/'covariates.parquet'),'sha256':mapping['files']['covariates.parquet']})
    import pandas as pd
    candidates=pd.read_parquet(product)
    if set(PROVENANCE)-set(candidates):raise PreparationError('Accepted mapping lacks BMI provenance')
    enriched=join_metadata(candidates,original)
    # Trigger records in later source-element windows do not authenticate the historical entry trigger.
    enriched['obesity_trigger']='trigger_unresolved'
    # Preserve float32 transport exactly when CSV is consumed by R.
    for name in enriched.select_dtypes(include=['float32']).columns:
        enriched[name]=enriched[name].astype('float64')
    output.mkdir(mode=0o700,parents=True)
    enriched.to_csv(output/'candidate-metadata.csv',index=False)
    evidence_out=dict(evidence,automated_checks={'candidate_keys':len(enriched),'original_keys':len(original),'join_uncovered':0,'join_duplicates':0},original_list_audit=audit,metadata_review='automated source binding; no new human approval asserted')
    (output/'rfs-evidence.json').write_text(json.dumps(evidence_out,indent=2)+'\n')
    subprocess.run([config.get('rscript','Rscript'),'--vanilla','scripts/enrich_rfs_input.R',args.input,args.manifest,str(output),args.prior_run],check=True)
    print('Fresh metadata-enriched input; no clinical models fitted:',output)

if __name__=='__main__':main()
