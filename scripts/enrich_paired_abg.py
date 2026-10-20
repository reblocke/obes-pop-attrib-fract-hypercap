#!/usr/bin/env python3
"""Narrow, read-only arterial pair extraction. No estimation or upstream rebuild."""
from __future__ import annotations
import argparse
import csv
import json
import math
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from prepare_common_index_input import (PreparationError, pinned_readers, verify_file,
    verify_canonical_database, file_identity, sha256)

PairingError = PreparationError
FIELDS = ('paired_abg_state','paired_abg_n_pairs','hypercapnia_paired','hypercapnia_acidemic',
          'paired_abg_unpaired_high','paired_abg_conflicts','paired_abg_invalid',
          'paired_abg_usable_pco2','paired_abg_paired_pco2')
PRESSURE = {'mmhg':1.,'mm hg':1.,'mm[hg]':1.,'kpa':7.50062}

def finite(value):
    try:
        x=float(value)
        return x if not isinstance(value,bool) and math.isfinite(x) else None
    except (ValueError,TypeError):
        return None

def derive_pairs(records, policy):
    """One original patient/encounter only; caller must authenticate policy and keys."""
    empty=dict.fromkeys(FIELDS)
    if policy is None:
        return dict(empty,paired_abg_state='source_unavailable')
    groups=defaultdict(lambda:defaultdict(list));dates=defaultdict(set);unlinked=[];invalid=0
    for ordinal,r in enumerate(records):
        code=str(r.get('code','')).strip().upper()
        if str(r.get('code_system','')).strip().upper()!='LOINC' or code not in ('2019-8','2744-1'):
            invalid+=1;continue
        specimen=str(r.get('specimen') or '').strip().lower()
        if specimen and specimen not in policy.get('arterial_specimen_values',[]):
            invalid+=1;continue
        analyte='co2' if code=='2019-8' else 'ph'
        value=finite(r.get('numeric_value'))
        unit=str(r.get('units_of_measure') or '').strip().lower()
        if not unit: unit=str(policy.get('metadata_'+analyte+'_unit') or '').strip().lower()
        if analyte=='co2':
            value=value*PRESSURE[unit] if value is not None and unit in PRESSURE else None
            valid=value is not None and 5<value<200
        else:
            valid=value is not None and unit in ('ph','[ph]') and policy['ph_lower_exclusive']<value<policy['ph_upper_exclusive']
        if not valid:
            invalid+=1
            value=None
        link=r.get(policy['link_field']);namespace=r.get(policy['namespace_field'])
        if link is None or namespace is None or not str(link).strip() or not str(namespace).strip():
            if analyte=='co2' and valid: unlinked.append((r.get('source_record_id',ordinal),value))
            continue
        version=r.get(policy.get('authoritative_version_field',''))
        group_key=(str(namespace),str(link))
        groups[group_key][analyte].append((value,version))
        if r.get('date'):dates[group_key].add(str(r['date']).replace('-',''))
    pairs=[];conflicts=0;unpaired_high=sum(v>=45 for _,v in set(unlinked));usable=len(set(unlinked))
    for group_key,group in groups.items():
        resolved={};bad=len(dates[group_key])>1
        for analyte,values in group.items():
            values=list(set(values))
            distinct={v for v,_ in values}
            if len(distinct)>1 and policy.get('authoritative_version_field'):
                versions=[finite(v) for _,v in values]
                if all(v is not None for v in versions):
                    latest=max(versions);distinct={x for (x,_),v in zip(values,versions) if v==latest}
            if analyte=='co2':usable+=sum(v is not None for v in distinct)
            if len(distinct)!=1:
                bad=True
            elif None not in distinct:resolved[analyte]=next(iter(distinct))
        if bad:conflicts+=1
        if not bad and set(resolved)=={'co2','ph'}:pairs.append((resolved['co2'],resolved['ph']))
        elif 'co2' in resolved:unpaired_high+=int(resolved['co2']>=45)
    state='valid_pair' if pairs else 'unresolved' if conflicts else 'no_valid_pair'
    return dict(paired_abg_state=state,paired_abg_n_pairs=len(pairs),
        hypercapnia_paired=int(any(c>=45 for c,p in pairs)) if pairs else None,
        hypercapnia_acidemic=int(any(c>=45 and p<7.35 for c,p in pairs)) if pairs else None,
        paired_abg_unpaired_high=unpaired_high,paired_abg_conflicts=conflicts,
        paired_abg_invalid=invalid,paired_abg_usable_pco2=usable,paired_abg_paired_pco2=len(pairs))

def authenticate_policy(config):
    entry=config.get('paired_abg_policy')
    if not entry:return None
    p=json.loads(verify_file(entry).read_text())
    if (p.get('policy_id')!='paired_abg_acidemia_v1' or p.get('link_semantics')!='one_arterial_collection' or
        p.get('canonical_database_sha256')!=config['canonical_source']['database']['sha256'] or
        p.get('link_field') not in ('specimen_id','accession_id','panel_id') or
        not isinstance(p.get('namespace_field'),str) or not p['namespace_field'].strip()):
        raise PairingError('Unqualified same-sample linkage policy')
    for field in ('reviewed_by','reviewed_on','linkage_evidence','ph_validity_evidence','version_semantics'):
        if not isinstance(p.get(field),str) or not p[field].strip() or 'PENDING' in p[field].upper():
            raise PairingError('Incomplete pairing policy review: '+field)
    lo=finite(p.get('ph_lower_exclusive'));hi=finite(p.get('ph_upper_exclusive'))
    if lo is None or hi is None or not lo<7.35<hi:raise PairingError('Unreviewed pH validity range')
    if not p.get('evidence_files'):raise PairingError('Missing pairing policy source evidence')
    for item in p['evidence_files']:verify_file(item)
    return p

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ('input','manifest','source-config','output'):ap.add_argument('--'+k,required=True)
    args=ap.parse_args();out=Path(args.output).resolve()
    if out.exists():raise PairingError('Output must be fresh')
    config=json.loads(Path(args.source_config).read_text());manifest=json.loads(Path(args.manifest).read_text())
    if sha256(args.input)!=manifest['input_sha256']:raise PairingError('Original input hash mismatch')
    # The study lineage receipt binds this exact canonical source. A different source
    # cannot be used merely because it has convenient column names.
    lineage=manifest['source_evidence_files']['lineage'].copy()
    if not Path(lineage['path']).is_absolute():lineage['path']=str(Path(args.manifest).resolve().parent/lineage['path'])
    source_lineage=json.loads(verify_file(lineage).read_text())
    if source_lineage.get('canonical_database_sha256')!=config['canonical_source']['database']['sha256']:
        raise PairingError('Pairing source differs from original study lineage')
    policy=authenticate_policy(config)
    database=verify_canonical_database(config['canonical_source']);verify_file(config['canonical_source']['sidecar'])
    before=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config))
    code_files=('scripts/enrich_paired_abg.py','scripts/enrich_paired_abg.R')
    code_hashes={p:sha256(p) for p in code_files}
    readers=pinned_readers(config);out.mkdir(parents=True,mode=0o700)
    rscript=config.get('rscript','Rscript')
    command=[rscript,'--vanilla','scripts/enrich_paired_abg.R']
    subprocess.run(command+['export',args.input,args.manifest,str(out)],check=True)
    import pandas as pd
    keys=pd.read_csv(out/'keys.csv',dtype=str)
    if keys.duplicated().any():raise PairingError('Duplicate study keys')
    audit=Counter();states=Counter();seen=set();source=config['canonical_source']
    with readers['combined_preprocessing.cohort_source'].open_cohort_source(database,
        expected_catalog_sha256=source['catalog_sha256'],spill_root=Path(source['spill_root']),memory_limit_mib=2816) as opened:
        c=opened.connection;c.register('paired_study_keys',keys)
        stream=readers['combined_preprocessing.cohort_source_calendar_transport'].iter_calendar_source_records(
            c,encounter_relation='paired_study_keys',domain='lab',
            code_selectors=[('LOINC',code) for code in ('2019-8','2744-1','32771-8','2021-4','2746-6','11558-4')])
        with (out/'pairing.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=['patient_id','encounter_id',*FIELDS]);writer.writeheader()
            previous=None;records=[];capture_missing=False
            def flush(key,rows,unavailable):
                if key in seen:raise PairingError('Noncontiguous repeated source key')
                seen.add(key)
                summary=derive_pairs(rows,None if unavailable else policy)
                writer.writerow(dict(patient_id=key[0],encounter_id=key[1],**summary));states[summary['paired_abg_state']]+=1
            for item in stream:
                key=(item.patient_id,item.encounter_id)
                if previous is not None and key!=previous:
                    flush(previous,records,capture_missing);records=[];capture_missing=False
                previous=key
                capture_missing |= item.state in ('unavailable_domain','unavailable_field')
                if item.record is None:continue
                r=item.record;records.append(r);audit['candidate_records']+=1
                for field in ('specimen_id','panel_id','accession_id','collection_time','result_status','result_version'):
                    audit[field+'_populated']+=int(r.get(field) is not None and bool(str(r[field]).strip()))
                audit['date_only_records']+=int(r.get('timestamp_precision')=='date_only')
                code=str(r.get('code','')).strip()
                audit['ordinary_arterial_pco2_records']+=int(code=='2019-8')
                audit['arterial_ph_records']+=int(code=='2744-1')
            if previous is not None:flush(previous,records,capture_missing)
    if seen!=set(map(tuple,keys.to_numpy())):raise PairingError('Source query did not account for every study key')
    if before!=(file_identity(database),sha256(args.input),sha256(args.manifest),sha256(args.source_config)) or code_hashes!={p:sha256(p) for p in code_files}:
        raise PairingError('Source/input/configuration changed during pairing audit')
    status='qualified' if policy is not None else 'unavailable'
    reason='' if policy else 'No authenticated same-sample policy; date/encounter co-occurrence cannot establish pairing.'
    if not audit['specimen_id_populated'] and not audit['panel_id_populated'] and not audit['accession_id_populated']:
        reason='No captured specimen, panel or accession linkage in queried gas records; date-only co-occurrence is not a same-sample pair.'
        status='unavailable'
    if status=='unavailable':
        # Capability unavailable is not an assessed zero-pair population.
        rows=[]
        with (out/'pairing.csv').open() as f:
            for row in csv.DictReader(f):
                rows.append(dict(patient_id=row['patient_id'],encounter_id=row['encounter_id'],**derive_pairs([],None)))
        with (out/'pairing.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=['patient_id','encounter_id',*FIELDS]);writer.writeheader();writer.writerows(rows)
        states=Counter(source_unavailable=len(keys))
    evidence=dict(schema_version=1,policy_id='paired_abg_acidemia_v1',status=status,reason=reason,
        base_input_sha256=before[1],base_manifest_sha256=before[2],source_config_sha256=before[3],
        canonical_database_sha256=source['database']['sha256'],source_unchanged=True,
        aggregate_counts=dict(audit),patient_states=dict(states),n_input_encounters=len(keys),
        policy=policy,adapter_sources=code_hashes,pairing_summary_sha256=sha256(out/'pairing.csv'),
        clinical_models_fitted=0,human_review='not asserted by automated extraction')
    (out/'pairing-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
    subprocess.run(command+['enrich',args.input,args.manifest,str(out)],check=True)
    for p in out.iterdir():p.chmod(0o600)
    print('Pairing status:',status,'; fresh enrichment:',out)

if __name__=='__main__':main()
