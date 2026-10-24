"""Authenticated component extraction used by the single study preparation command.

These functions classify captured evidence, not eligibility or outcomes for a different encounter.
"""
from __future__ import annotations
import json
import math
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from original_encounter_population import RFS_COLUMNS, PreparationError

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

CooccurrenceError = PreparationError
POLICY_ID = 'same_day_arterial_cooccurrence_v1'
SAME_DAY_FIELDS = ('same_day_abg_state','same_day_abg_n_days','hypercapnia_coobserved',
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
        return dict(dict.fromkeys(SAME_DAY_FIELDS),same_day_abg_state='source_unavailable')
    out={field:0 for field in SAME_DAY_FIELDS}
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
    from prepare_common_index_input import verify_file
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

CODES=('J96.02','J96.12','J96.22','J96.92','E66.2')
FLAGS=tuple('icd_'+c.replace('.','') for c in CODES)
ICD_FIELDS=('icd_capture_state',*FLAGS)

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


def authenticate_rfs(config):
    from prepare_common_index_input import verify_file
    evidence=json.loads(verify_file(config['rfs_evidence']).read_text())
    if evidence.get('policy_id')!='historical_source_membership_v1' or evidence.get('membership_semantics')!='selected_source_file_membership':
        raise PreparationError('RFS source-membership semantics are not authenticated')
    if set(evidence.get('families',{}))!=set(RFS_COLUMNS):
        raise PreparationError('Incomplete RFS family evidence')
    required={'source_product','producer_revision','unit','anchor','allowed_values','zero_semantics','earliest_event_rule','relationship'}
    for definition in evidence['families'].values():
        if not required<=set(definition) or any(not isinstance(definition[k],str) or not definition[k].strip() or 'PENDING' in definition[k] for k in required):
            raise PreparationError('Incomplete RFS family semantics')
    if evidence.get('accepted_receipt_sha256')!=config['encounter_bundle']['expected_receipt_sha256']:
        raise PreparationError('RFS evidence belongs to another accepted product')
    if not evidence.get('evidence_files'):
        raise PreparationError('RFS evidence requires pinned source/receipts')
    for entry in evidence['evidence_files']:verify_file(entry)
    return evidence


def summarize_components(stream, classify):
    """Keep one encounter in memory and account for every requested transport key."""
    out={};audit=Counter();previous=None;records=[];unavailable=False
    def flush(key):
        if key in out:raise PreparationError('Noncontiguous repeated source key')
        out[key]=classify(key,records,unavailable)
    for item in stream:
        key=(item.patient_id,item.encounter_id)
        if previous is not None and key!=previous:
            flush(previous);records=[];unavailable=False
        previous=key
        unavailable |= item.state in ('unavailable_domain','unavailable_field')
        if item.state in ('unavailable_domain','unavailable_field'):audit[item.state]+=1
        if item.record is not None:
            r=item.record
            if (r.get('patient_id'),r.get('encounter_id'))!=key:
                raise PreparationError('Source record does not belong to its requested key')
            records.append(r);audit['candidate_records']+=1
            audit[str(r.get('code') or '')+'_records']+=1
            for field in ('date','specimen','source_record_id'):
                audit[field+'_populated']+=int(r.get(field) is not None and bool(str(r[field]).strip()))
            audit['date_only_records']+=int(r.get('timestamp_precision')=='date_only')
            code=str(r.get('code') or '').strip()
            if code in ('2019-8','2744-1'):
                label='pco2' if code=='2019-8' else 'ph'
                unit=str(r.get('units_of_measure_raw') or r.get('units_of_measure') or '').strip().lower()
                recognized=unit in (PRESSURE if label=='pco2' else ('ph','[ph]'))
                audit[label+'_reviewed_unit_records']+=int(recognized)
                audit[label+'_unreviewed_or_missing_unit_records']+=int(not recognized)
                audit[label+'_parseable_recorded_date_records']+=int(recorded_date(r.get('date')) is not None)
    if previous is not None:flush(previous)
    return out,dict(audit)
