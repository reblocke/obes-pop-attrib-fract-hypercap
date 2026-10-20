#!/usr/bin/env python3
"""Recorded-day arterial co-occurrence enrichment; never infer same-sample pairing."""
from __future__ import annotations
import argparse
import csv
import json
import math
import subprocess
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from prepare_common_index_input import (PreparationError, pinned_readers, verify_file,
    verify_canonical_database, file_identity, sha256)

CooccurrenceError = PreparationError
POLICY_ID = 'same_day_arterial_cooccurrence_v1'
FIELDS = ('same_day_abg_state','same_day_abg_n_days','hypercapnia_coobserved',
    'hypercapnia_acidemia_same_day','same_day_abg_noncoobserved_high',
    'same_day_abg_invalid_records','same_day_abg_undated_records','same_day_abg_excluded_records',
    'same_day_abg_duplicate_records','same_day_abg_usable_pco2','same_day_abg_coobserved_pco2',
    'same_day_abg_usable_ph','same_day_abg_coobserved_ph','same_day_abg_co2_only_days',
    'same_day_abg_ph_only_days','same_day_abg_multiple_result_days')
PRESSURE = json.loads((Path(__file__).resolve().parents[1]/'config/common_index_source_policy.json').read_text())['unit_factors_to_mmhg']

def finite(value):
    try:
        x=float(value)
        return x if not isinstance(value,bool) and math.isfinite(x) else None
    except (ValueError,TypeError):
        return None

def recorded_date(value):
    """Only authenticated day-resolution strings, never imputed collection time."""
    if isinstance(value,date) and not hasattr(value,'hour'):
        return value.isoformat()
    if not isinstance(value,str):return None
    value=value.strip()
    if len(value)==8 and value.isdigit():value=value[:4]+'-'+value[4:6]+'-'+value[6:]
    if len(value)!=10:return None
    try:return date.fromisoformat(value).isoformat()
    except ValueError:return None

def derive_days(records, policy):
    """One original patient/encounter in one authenticated source snapshot."""
    if policy is None:
        return dict(dict.fromkeys(FIELDS),same_day_abg_state='source_unavailable')
    out={field:0 for field in FIELDS}
    groups=defaultdict(lambda:{'co2':[],'ph':[]});seen={};keys=set();undated_high=0
    for r in records:
        key=(r.get('patient_id'),r.get('encounter_id'))
        if any(x is None or not str(x).strip() for x in key):raise CooccurrenceError('Missing original source keys')
        keys.add(key)
        if len(keys)>1:raise CooccurrenceError('Different encounters cannot share day evidence')
        identity=r.get('source_record_id')
        if not identity or not str(identity).strip():raise CooccurrenceError('Missing stable source record identity')
        signature=json.dumps(r,sort_keys=True,default=str)
        if identity in seen:
            if seen[identity]!=signature:raise CooccurrenceError('Conflicting contents under one source record identity')
            out['same_day_abg_duplicate_records']+=1
            continue
        seen[identity]=signature
        code=str(r.get('code') or '').strip()
        if str(r.get('code_system') or '').strip().upper()!='LOINC' or code not in ('2019-8','2744-1'):
            out['same_day_abg_excluded_records']+=1
            continue
        analyte='co2' if code=='2019-8' else 'ph'
        specimen=str(r.get('specimen') or '').strip().lower()
        value=finite(r.get('numeric_value'))
        unit=str(r.get('units_of_measure_raw') or r.get('units_of_measure') or '').strip().lower()
        if analyte=='co2':
            value=value*PRESSURE[unit] if value is not None and unit in PRESSURE else None
            valid=value is not None and 5<value<200
        else:
            valid=value is not None and unit in policy['ph_units'] and 6.5<value<7.8
        if specimen and specimen not in policy['arterial_specimen_values']:valid=False
        if not valid:
            out['same_day_abg_invalid_records']+=1
            continue
        out['same_day_abg_usable_pco2' if analyte=='co2' else 'same_day_abg_usable_ph']+=1
        day=recorded_date(r.get('date'))
        if day is None:
            out['same_day_abg_undated_records']+=1
            undated_high+=int(analyte=='co2' and value>=45)
            continue
        groups[day][analyte].append(value)
    observed=[g for g in groups.values() if g['co2'] and g['ph']]
    out['same_day_abg_n_days']=len(observed)
    out['same_day_abg_co2_only_days']=sum(bool(g['co2']) and not g['ph'] for g in groups.values())
    out['same_day_abg_ph_only_days']=sum(bool(g['ph']) and not g['co2'] for g in groups.values())
    out['same_day_abg_coobserved_pco2']=sum(len(g['co2']) for g in observed)
    out['same_day_abg_coobserved_ph']=sum(len(g['ph']) for g in observed)
    out['same_day_abg_multiple_result_days']=sum(len(g['co2'])>1 or len(g['ph'])>1 for g in observed)
    out['same_day_abg_noncoobserved_high']=undated_high+sum(v>=45 for g in groups.values() if not g['ph'] for v in g['co2'])
    out['same_day_abg_state']='coobserved_day' if observed else 'unresolved' if out['same_day_abg_undated_records'] else 'no_coobserved_day'
    out['hypercapnia_coobserved']=int(any(any(v>=45 for v in g['co2']) for g in observed)) if observed else None
    out['hypercapnia_acidemia_same_day']=int(any(any(v>=45 for v in g['co2']) and any(v<7.35 for v in g['ph']) for g in observed)) if observed else None
    return out

def authenticate_policy(config):
    entry=config.get('same_day_abg_policy')
    if not entry:return None
    p=json.loads(verify_file(entry).read_text())
    required=dict(policy_id=POLICY_ID,date_field='date',date_semantics='recorded_result_calendar_date',
        day_selection='any_coobserved_day_within_index_encounter',ph_lower_exclusive=6.5,
        ph_upper_exclusive=7.8,source_policy_id='unadjusted_pco2_v1',
        arterial_pco2_code='2019-8',arterial_ph_code='2744-1',
        pco2_lower_exclusive=5,pco2_upper_exclusive=200,
        hypercapnia_threshold_inclusive=45,acidemia_threshold_exclusive=7.35,
        correction_policy='captured_records_without_inferred_corrections')
    if any(p.get(k)!=v for k,v in required.items()) or p.get('canonical_database_sha256')!=config['canonical_source']['database']['sha256']:
        raise CooccurrenceError('Unqualified recorded-day co-occurrence policy')
    if p.get('ph_units')!=['ph','[ph]'] or not isinstance(p.get('arterial_specimen_values'),list):
        raise CooccurrenceError('Unreviewed arterial pH units/specimen mapping')
    for field in ('clinical_policy_authorization','date_evidence','ph_evidence'):
        if not isinstance(p.get(field),str) or not p[field].strip() or 'PENDING' in p[field].upper():
            raise CooccurrenceError('Incomplete co-occurrence source evidence: '+field)
    if not p.get('evidence_files'):raise CooccurrenceError('Missing source evidence files')
    for item in p['evidence_files']:verify_file(item)
    return p

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ('input','manifest','source-config','output'):ap.add_argument('--'+k,required=True)
    args=ap.parse_args();out=Path(args.output).resolve()
    if out.exists():raise CooccurrenceError('Output must be fresh')
    config=json.loads(Path(args.source_config).read_text());manifest=json.loads(Path(args.manifest).read_text())
    if sha256(args.input)!=manifest['input_sha256']:raise CooccurrenceError('Original input hash mismatch')
    # The study lineage receipt binds this exact canonical source. A different source
    # cannot be used merely because it has convenient column names.
    lineage=manifest['source_evidence_files']['lineage'].copy()
    if not Path(lineage['path']).is_absolute():lineage['path']=str(Path(args.manifest).resolve().parent/lineage['path'])
    source_lineage=json.loads(verify_file(lineage).read_text())
    if source_lineage.get('canonical_database_sha256')!=config['canonical_source']['database']['sha256']:
        raise CooccurrenceError('Co-occurrence source differs from original study lineage')
    policy=authenticate_policy(config)
    database=verify_canonical_database(config['canonical_source']);verify_file(config['canonical_source']['sidecar'])
    before=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config))
    code_files=('scripts/enrich_same_day_abg.py','scripts/enrich_same_day_abg.R','config/common_index_source_policy.json')
    code_hashes={p:sha256(p) for p in code_files}
    readers=pinned_readers(config);out.mkdir(parents=True,mode=0o700)
    rscript=config.get('rscript','Rscript')
    command=[rscript,'--vanilla','scripts/enrich_same_day_abg.R']
    subprocess.run(command+['export',args.input,args.manifest,str(out)],check=True)
    import pandas as pd
    keys=pd.read_csv(out/'keys.csv',dtype=str)
    if keys.duplicated().any():raise CooccurrenceError('Duplicate study keys')
    audit=Counter();states=Counter();seen=set();source=config['canonical_source']
    print('Reading exact-code arterial evidence from the accepted source',flush=True)
    with readers['combined_preprocessing.cohort_source'].open_cohort_source(database,
        expected_catalog_sha256=source['catalog_sha256'],spill_root=Path(source['spill_root']),memory_limit_mib=2816) as opened:
        c=opened.connection;c.register('same_day_study_keys',keys)
        stream=readers['combined_preprocessing.cohort_source_calendar_transport'].iter_calendar_source_records(
            c,encounter_relation='same_day_study_keys',domain='lab',
            code_selectors=[('LOINC',code) for code in ('2019-8','2744-1','32771-8','2021-4','2746-6','11558-4')])
        with (out/'cooccurrence.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=['patient_id','encounter_id',*FIELDS]);writer.writeheader()
            previous=None;records=[];capture_missing=False
            def flush(key,rows,unavailable):
                if key in seen:raise CooccurrenceError('Noncontiguous repeated source key')
                seen.add(key)
                summary=derive_days(rows,None if unavailable else policy)
                writer.writerow(dict(patient_id=key[0],encounter_id=key[1],**summary));states[summary['same_day_abg_state']]+=1
            for item in stream:
                key=(item.patient_id,item.encounter_id)
                if previous is not None and key!=previous:
                    flush(previous,records,capture_missing);records=[];capture_missing=False
                previous=key
                capture_missing |= item.state in ('unavailable_domain','unavailable_field')
                if item.record is None:continue
                r=item.record
                if (str(r.get('patient_id')),str(r.get('encounter_id'))) != key:
                    raise CooccurrenceError('Source record does not belong to its requested key')
                records.append(r);audit['candidate_records']+=1
                for field in ('date','specimen','source_record_id'):
                    audit[field+'_populated']+=int(r.get(field) is not None and bool(str(r[field]).strip()))
                audit['date_only_records']+=int(r.get('timestamp_precision')=='date_only')
                code=str(r.get('code','')).strip()
                audit['ordinary_arterial_pco2_records']+=int(code=='2019-8')
                audit['arterial_ph_records']+=int(code=='2744-1')
                if code in ('2019-8','2744-1'):
                    unit=str(r.get('units_of_measure_raw') or r.get('units_of_measure') or '').strip().lower()
                    recognized=unit in (PRESSURE if code=='2019-8' else ('ph','[ph]'))
                    label='pco2' if code=='2019-8' else 'ph'
                    audit[label+'_reviewed_unit_records']+=int(recognized)
                    audit[label+'_unreviewed_or_missing_unit_records']+=int(not recognized)
                    audit[label+'_parseable_recorded_date_records']+=int(recorded_date(r.get('date')) is not None)
            if previous is not None:flush(previous,records,capture_missing)
    if seen!=set(map(tuple,keys.to_numpy())):raise CooccurrenceError('Source query did not account for every study key')
    if before!=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config)) or code_hashes!={p:sha256(p) for p in code_files}:
        raise CooccurrenceError('Source/input/configuration changed during cooccurrence audit')
    status='qualified' if policy is not None else 'unavailable'
    reason='' if policy else 'No authenticated recorded-day arterial co-occurrence policy supplied.'
    evidence=dict(schema_version=1,policy_id=POLICY_ID,status=status,reason=reason,
        base_input_sha256=before[1],base_manifest_sha256=before[2],source_config_sha256=before[3],
        canonical_database_sha256=source['database']['sha256'],source_unchanged=True,
        aggregate_counts=dict(audit),patient_states=dict(states),n_input_encounters=len(keys),
        policy=policy,adapter_sources=code_hashes,cooccurrence_summary_sha256=sha256(out/'cooccurrence.csv'),
        clinical_models_fitted=0,human_review='not asserted by automated extraction')
    (out/'cooccurrence-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
    subprocess.run(command+['enrich',args.input,args.manifest,str(out)],check=True)
    for p in out.iterdir():p.chmod(0o600)
    print('Co-occurrence status:',status,'; fresh enrichment:',out)

if __name__=='__main__':main()
