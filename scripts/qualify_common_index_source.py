#!/usr/bin/env python3
"""Independent aggregate source checks for the prepared common-index input.

No models, predictions or row-level audit exports. Outputs remain private and
do not establish human scientific approval.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from original_encounter_population import RFS_COLUMNS
from prepare_common_index_input import (
    PreparationError, file_identity, pinned_readers, sha256, verify_canonical_database, verify_file,
)


def read_prepared_rows(path):
    """Preserve exact decimal round trips when checking typed source transport."""
    import pandas as pd
    prepared=pd.read_csv(path,dtype={'patient_id':'string','encounter_id':'string'},
        keep_default_na=False,na_values=[''],float_precision='round_trip')
    prepared['encounter_date']=pd.to_datetime(prepared.encounter_date)
    return prepared


def check_indexes(c, product, prepared, census):
    quote = lambda x: "'"+str(x).replace("'", "''")+"'"
    c.register('prepared_rows', prepared)
    c.execute('CREATE TEMP VIEW source_mapping AS SELECT * FROM read_parquet('+quote(product)+')')
    c.execute("CREATE TEMP VIEW membership AS SELECT patient_id,encounter_id,encounter_date,encounter_type,bmi_evidence_state,age_at_encounter,"
              "((age_at_encounter>=18 AND encounter_type IN ('EMER','IMP') "
              "AND encounter_date>='2022-01-01' AND encounter_date<'2023-01-01') "
              "AND CASE WHEN bmi_evidence_state='missing' THEN false ELSE isfinite(bmi) END) AS eligible "
              "FROM source_mapping")
    c.execute('CREATE TEMP TABLE first_known AS SELECT patient_id,min(encounter_date) AS first_date '
              'FROM membership WHERE eligible IS TRUE GROUP BY 1')
    c.execute('CREATE TEMP TABLE index_status AS SELECT f.patient_id,f.first_date,'
              'count(*) FILTER(WHERE m.eligible IS TRUE AND m.encounter_date=f.first_date) AS n_first,'
              'bool_or(m.eligible IS NULL AND (m.encounter_date IS NULL OR m.encounter_date<=f.first_date)) AS uncertain '
              'FROM first_known f JOIN membership m USING(patient_id) GROUP BY 1,2')
    c.execute('CREATE TEMP TABLE expected_indexes AS SELECT m.patient_id,m.encounter_id FROM membership m '
              'JOIN index_status s USING(patient_id) WHERE m.eligible IS TRUE '
              'AND m.encounter_date=s.first_date AND s.n_first=1 AND NOT s.uncertain')
    mismatch=c.execute('SELECT count(*) FROM expected_indexes e FULL OUTER JOIN prepared_rows p '
                       'USING(patient_id,encounter_id) WHERE e.patient_id IS NULL OR p.patient_id IS NULL').fetchone()[0]
    n_total,n_unresolved,n_ties,n_earlier=c.execute('SELECT count(*),count(*) FILTER(WHERE uncertain OR n_first>1),'
        'count(*) FILTER(WHERE NOT uncertain AND n_first>1),count(*) FILTER(WHERE uncertain) FROM index_status').fetchone()
    expected={'n_frame_patients':n_total,'n_index_unresolved':n_unresolved,'n_earliest_ties':n_ties,'n_earlier_uncertainty':n_earlier}
    count_mismatch=sum(int(census['counts'][k]!=v) for k,v in expected.items())
    state_bad=c.execute("SELECT count(*) FROM source_mapping WHERE bmi_evidence_state NOT IN ('valid','missing','unresolved') "
                        "OR (bmi_evidence_state='valid') IS DISTINCT FROM (bmi IS NOT NULL)").fetchone()[0]
    prior_bad=c.execute("SELECT count(*) FROM source_mapping WHERE bmi_method='prior' AND "
                        "(reported_date IS NULL OR encounter_date IS NULL OR reported_date>=encounter_date)").fetchone()[0]
    # Independent Stata rounding expression, rather than the mapper's round().
    calc_bad=c.execute("SELECT count(*) FROM source_mapping WHERE bmi_method='calculated' AND bmi IS DISTINCT FROM "
        "cast(floor(((floor(cast(weight_pounds AS DOUBLE)+0.5)*0.453592)/"
        "pow(floor(cast(height_inches AS DOUBLE)+0.5)*0.0254,2))/0.1+0.5)*0.1 AS FLOAT)").fetchone()[0]
    reported_bad=c.execute("SELECT count(*) FROM source_mapping WHERE bmi_method IN ('current','prior') "
        "AND bmi IS DISTINCT FROM cast(floor(cast(reported_bmi AS DOUBLE)/0.1+0.5)*0.1 AS FLOAT)").fetchone()[0]
    field_disagreements={}
    for name in ('bmi','age_at_encounter','sex','race_ethnicity','location','encounter_date','encounter_type','bmi_evidence_state'):
        if name in prepared:
            field_disagreements['prepared_'+name+'_disagreements']=c.execute(
                f'SELECT count(*) FROM prepared_rows p JOIN source_mapping m USING(patient_id,encounter_id) '
                f'WHERE p.{name} IS DISTINCT FROM m.{name}').fetchone()[0]
    methods=c.execute('SELECT s.bmi_method,count(*) FROM source_mapping s JOIN prepared_rows p USING(patient_id,encounter_id) GROUP BY 1').fetchall()
    blockers=c.execute('SELECT count(DISTINCT CASE WHEN m.encounter_type IS NULL THEN m.patient_id END),'
        "count(DISTINCT CASE WHEN m.bmi_evidence_state='unresolved' THEN m.patient_id END),"
        'count(DISTINCT CASE WHEN m.age_at_encounter IS NULL THEN m.patient_id END),'
        'count(DISTINCT CASE WHEN m.encounter_date IS NULL THEN m.patient_id END) '
        'FROM membership m JOIN index_status s USING(patient_id) WHERE s.uncertain AND m.eligible IS NULL '
        'AND (m.encounter_date IS NULL OR m.encounter_date<=s.first_date)').fetchone()
    return {'index_key_disagreements':mismatch,'index_census_disagreements':count_mismatch,
            'invalid_bmi_states':state_bad,'invalid_prior_dates':prior_bad,'calculated_bmi_disagreements':calc_bad,
            'reported_bmi_rounding_disagreements':reported_bad,**field_disagreements}, {
            'independent_index_counts':expected,'index_bmi_methods':dict(methods),
            'earlier_uncertainty_patients_overlapping_reasons':dict(zip(['unknown_setting','unresolved_BMI','unknown_age','unknown_date'],blockers))}


def check_original_population(c, product, original, prepared):
    """Independent SQL membership, original first flags and raw-start checks."""
    c.register('accepted_original_rows', original)
    c.register('prepared_original_indexes', prepared)
    c.execute('CREATE TEMP VIEW original_mapped_rows AS SELECT * FROM read_parquet(?)'.replace(
        '?', "'"+str(product).replace("'", "''")+"'"))
    c.execute("CREATE TEMP TABLE accepted_acute_keys AS SELECT patient_id,encounter_id,"
              "CASE encounter_type WHEN 2 THEN 'EMER' WHEN 3 THEN 'IMP' END AS expected_type "
              "FROM accepted_original_rows WHERE encounter_type IN (2,3)")
    outside=c.execute('SELECT count(*) FROM original_mapped_rows m ANTI JOIN accepted_acute_keys k USING(patient_id,encounter_id)').fetchone()[0]
    missing=c.execute('SELECT count(*) FROM accepted_acute_keys k ANTI JOIN original_mapped_rows m USING(patient_id,encounter_id)').fetchone()[0]
    type_bad=c.execute('SELECT count(*) FROM original_mapped_rows m JOIN accepted_acute_keys k '
                       'USING(patient_id,encounter_id) WHERE m.encounter_type IS DISTINCT FROM k.expected_type').fetchone()[0]
    first_bad=c.execute('SELECT count(*) FROM (SELECT first_encounter,row_number() OVER '
        '(PARTITION BY patient_id ORDER BY encounter_date NULLS LAST,pat_enc_hash) AS rn '
        'FROM accepted_original_rows) WHERE first_encounter IS DISTINCT FROM cast(rn=1 AS INTEGER)').fetchone()[0]
    c.execute("CREATE TEMP TABLE original_raw_starts AS SELECT e.patient_id,e.encounter_id,"
        "CASE WHEN count(*) FILTER(WHERE e.start_timestamp_precision IS DISTINCT FROM 'date_only' "
        "OR try_strptime(e.start_date,['%Y%m%d','%Y-%m-%d']) IS NULL)>0 "
        "OR min(try_strptime(e.start_date,['%Y%m%d','%Y-%m-%d']))<>max(try_strptime(e.start_date,['%Y%m%d','%Y-%m-%d'])) "
        "THEN NULL ELSE cast(min(try_strptime(e.start_date,['%Y%m%d','%Y-%m-%d'])) AS DATE) END AS expected_start,"
        "count(*) FILTER(WHERE upper(trim(e.type))=k.expected_type)>0 AS setting_supported "
        "FROM source_encounter e JOIN accepted_acute_keys k USING(patient_id,encounter_id) GROUP BY 1,2")
    start_bad=c.execute('SELECT count(*) FROM original_mapped_rows m LEFT JOIN original_raw_starts e '
        'USING(patient_id,encounter_id) WHERE e.patient_id IS NULL OR m.encounter_date IS DISTINCT FROM e.expected_start').fetchone()[0]
    unsupported=c.execute('SELECT count(*) FROM accepted_acute_keys k LEFT JOIN original_raw_starts e '
        'USING(patient_id,encounter_id) WHERE e.patient_id IS NULL OR NOT e.setting_supported').fetchone()[0]
    selected_outside=c.execute('SELECT count(*) FROM prepared_original_indexes p ANTI JOIN accepted_acute_keys k USING(patient_id,encounter_id)').fetchone()[0]
    flags=c.execute('SELECT o.first_encounter,count(*) FROM prepared_original_indexes p '
        'JOIN accepted_original_rows o USING(patient_id,encounter_id) GROUP BY 1').fetchall()
    return dict(mapping_keys_outside_original_list=outside, original_acute_keys_missing_from_mapping=missing,
        original_setting_disagreements=type_bad, original_first_flag_disagreements=first_bad,
        raw_encounter_start_disagreements=start_bad, unsupported_original_setting_keys=unsupported,
        prepared_indexes_outside_original_list=selected_outside), {'selected_indexes_by_historical_first_flag':dict(flags)}


def check_components(c, prepared, original, capture_complete, day_qualified):
    """Independent SQL checks; no production classifier or scientific model."""
    c.register('component_rows',prepared);c.register('component_original',original)
    failures={}
    for name,source in [(x,x) for x in RFS_COLUMNS]+[('raw_race','race'),('raw_ethnicity','ethnicity')]:
        failures[name+'_disagreements']=c.execute(f'SELECT count(*) FROM component_rows p JOIN component_original o USING(patient_id,encounter_id) WHERE try_cast(p.{name} AS DOUBLE) IS DISTINCT FROM try_cast(o.{source} AS DOUBLE)').fetchone()[0]
    for code in ('J9602','J9612','J9622','J9692','E662'):
        # Captured positives remain positive; absent flags require complete capture.
        failures['icd_'+code+'_disagreements']=c.execute(f"SELECT count(*) FROM component_rows p WHERE p.icd_{code} IS DISTINCT FROM CASE WHEN EXISTS (SELECT 1 FROM source_diagnosis d WHERE d.patient_id=p.patient_id AND d.encounter_id=p.encounter_id AND replace(upper(trim(d.code)),'.','')='{code}') THEN 1 WHEN p.icd_capture_state='complete' THEN 0 ELSE NULL END").fetchone()[0]
    if not capture_complete:
        failures['unexpected_complete_diagnosis_capture']=int((prepared.icd_capture_state=='complete').sum())
    if not day_qualified:
        failures['unexpected_assessed_cooccurrence']=int((prepared.same_day_abg_state!='source_unavailable').sum())
        return failures
    c.execute("CREATE OR REPLACE TEMP TABLE component_days AS WITH values AS (SELECT l.patient_id,l.encounter_id,code,cast(event_datetime AS DATE) AS day,CASE WHEN lower(coalesce(nullif(trim(units_of_measure_raw),''),units_of_measure)) IN ('mmhg','mm hg','mm[hg]') THEN numeric_value WHEN lower(coalesce(nullif(trim(units_of_measure_raw),''),units_of_measure))='kpa' THEN numeric_value*7.50062 END AS pressure, CASE WHEN lower(coalesce(nullif(trim(units_of_measure_raw),''),units_of_measure)) IN ('ph','[ph]') THEN numeric_value END AS ph FROM source_lab_measurement l JOIN component_rows p USING(patient_id,encounter_id) WHERE code_system='LOINC' AND code IN ('2019-8','2744-1') AND NOT regexp_matches(coalesce(lab_result_text_val,''),'[<>≤≥]') AND timestamp_precision='date_only'), daily AS (SELECT patient_id,encounter_id,day,max(pressure) FILTER(WHERE code='2019-8' AND pressure>5 AND pressure<200) AS pco2,min(ph) FILTER(WHERE code='2744-1' AND ph>6.5 AND ph<7.8) AS ph FROM values WHERE day IS NOT NULL GROUP BY 1,2,3) SELECT patient_id,encounter_id,count(*) AS n_days,cast(bool_or(pco2>=45) AS INTEGER) AS hypercapnia,cast(bool_or(pco2>=45 AND ph<7.35) AS INTEGER) AS acidemia FROM daily WHERE pco2 IS NOT NULL AND ph IS NOT NULL GROUP BY 1,2")
    for name,expected in [('same_day_abg_n_days','coalesce(d.n_days,0)'),('hypercapnia_coobserved','d.hypercapnia'),('hypercapnia_acidemia_same_day','d.acidemia')]:
        failures[name+'_disagreements']=c.execute(f'SELECT count(*) FROM component_rows p LEFT JOIN component_days d USING(patient_id,encounter_id) WHERE p.same_day_abg_state<>\'source_unavailable\' AND p.{name} IS DISTINCT FROM {expected}').fetchone()[0]
    return failures


def check_fields(c, prepared, capture_complete):
    c.register('prepared_rows',prepared)
    c.execute("CREATE TEMP TABLE raw_gases AS SELECT l.*,cast(p.encounter_date AS DATE) AS index_date "
              "FROM source_lab_measurement l JOIN prepared_rows p USING(patient_id,encounter_id) "
              "WHERE l.code_system='LOINC' AND l.code IN ('2019-8','2021-4','11557-6','32771-8','40619-9','34705-4')")
    c.execute("CREATE TEMP VIEW valid_gases AS SELECT *,CASE "
              "WHEN regexp_matches(coalesce(lab_result_text_val,''),'[<>≤≥]') THEN NULL "
              "WHEN lower(coalesce(nullif(trim(units_of_measure_raw),''),units_of_measure)) "
              "IN ('mmhg','mm hg','mm[hg]') THEN numeric_value "
              "WHEN lower(coalesce(nullif(trim(units_of_measure_raw),''),units_of_measure))='kpa' "
              "THEN numeric_value*7.50062 END AS pressure FROM raw_gases")
    parts=[]
    for gas,code,lo,hi in [('abg','2019-8',5,200),('vbg','2021-4',10,250)]:
        condition=f"code='{code}' AND isfinite(pressure) AND pressure>{lo} AND pressure<{hi}"
        adjusted='32771-8' if gas=='abg' else '40619-9'
        specific=f"code IN ('{code}','{adjusted}')"
        parts += [f"max(pressure) FILTER(WHERE {condition}) AS {gas}_pco2",
                  f"max(pressure) FILTER(WHERE {condition} AND timestamp_precision='date_only' AND cast(event_datetime AS DATE)=index_date) AS {gas}_pco2_index_day",
                  f"CASE WHEN count(*) FILTER(WHERE {specific} AND isfinite(numeric_value))>0 THEN 1 "
                  f"WHEN count(*) FILTER(WHERE {specific} OR code IN ('11557-6','34705-4'))>0 THEN NULL ELSE 0 END AS has_{gas}"]
    c.execute('CREATE TEMP TABLE expected_gases AS SELECT patient_id,encounter_id,'+','.join(parts)+' FROM valid_gases GROUP BY 1,2')
    failures={}
    for name in ['abg_pco2','vbg_pco2','abg_pco2_index_day','vbg_pco2_index_day']:
        if name not in prepared: continue
        failures[name+'_disagreements']=c.execute(f'SELECT count(*) FROM prepared_rows p LEFT JOIN expected_gases e '
            f'USING(patient_id,encounter_id) WHERE p.{name} IS DISTINCT FROM e.{name}').fetchone()[0]
    for gas in ('abg','vbg'):
        if 'has_'+gas in prepared:
            failures['has_'+gas+'_disagreements']=c.execute(f'SELECT count(*) FROM prepared_rows p LEFT JOIN expected_gases e '
                f'USING(patient_id,encounter_id) WHERE p.has_{gas} IS DISTINCT FROM CASE WHEN e.encounter_id IS NULL '
                f'THEN 0 ELSE e.has_{gas} END').fetchone()[0]
        if gas+'_index_day_available' in prepared:
            failures[gas+'_day_availability_disagreements']=c.execute(f'SELECT count(*) FROM prepared_rows p LEFT JOIN expected_gases e '
                f'USING(patient_id,encounter_id) WHERE p.{gas}_index_day_available IS DISTINCT FROM '
                f'cast(e.{gas}_pco2_index_day IS NOT NULL AS INTEGER)').fetchone()[0]
    c.execute("CREATE TEMP TABLE expected_icd AS SELECT DISTINCT d.patient_id,d.encounter_id FROM source_diagnosis d "
              "JOIN prepared_rows p USING(patient_id,encounter_id) WHERE d.code_system='ICD10CM' "
              "AND replace(upper(trim(d.code)),'.','') IN ('J9602','J9612','J9622','J9692','E662')")
    negative='0' if capture_complete else 'NULL'
    failures['icd_disagreements']=c.execute('SELECT count(*) FROM prepared_rows p LEFT JOIN expected_icd e '
        'USING(patient_id,encounter_id) WHERE p.icd_hypercapnia IS DISTINCT FROM '
        f'CASE WHEN e.patient_id IS NOT NULL THEN 1 ELSE {negative} END').fetchone()[0]
    details={'censored_numeric_gas_records':c.execute("SELECT count(*) FROM raw_gases WHERE numeric_value IS NOT NULL "
              "AND regexp_matches(coalesce(lab_result_text_val,''),'[<>≤≥]')").fetchone()[0]}
    return failures,details


def run(config, prepared_dir, output):
    os.umask(0o077); output.mkdir(mode=0o700,parents=True,exist_ok=False)
    prep=json.loads((prepared_dir/'preparation_receipt.json').read_text())
    if prep['source_config_sha256'] != config['_config_sha256']:
        raise ValueError('Qualification configuration does not match preparation')
    verify_file({'path':str(prepared_dir/'study-input.rds'),'sha256':prep['input_sha256']})
    verify_file({'path':str(prepared_dir/'study-input.csv'),'sha256':prep['input_csv_sha256']})
    for name in ('field','population'):
        verify_file({'path':str(prepared_dir/(name+'-evidence.json')),
                     'sha256':prep[name+'_evidence_sha256']})
    pending=json.loads((prepared_dir/'triangulation_input.pending.json').read_text())
    verify_file({'path':str(prepared_dir/'selection-evidence.json'),
                 'sha256':pending['source_evidence_files']['selection']['sha256']})
    readers=pinned_readers(config)
    database=verify_canonical_database(config['canonical_source']);before=file_identity(database)
    entry=config['covariate_mapping']['manifest'];path=verify_file(entry);mapping=json.loads(path.read_text())
    from original_encounter_population import read_original_list, require_original_population
    require_original_population(config, mapping)
    original, original_audit = read_original_list(config, readers, include_metadata=True)
    verify_file(mapping['original_encounter_list'])
    product=verify_file({'path':str(path.parent/'covariates.parquet'),'sha256':mapping['files']['covariates.parquet']})
    census=json.loads((prepared_dir/'selection-evidence.json').read_text())
    prepared=read_prepared_rows(prepared_dir/'study-input.csv')
    (output/'spill').mkdir(mode=0o700)
    with readers['combined_preprocessing.cohort_source'].open_cohort_source(database,
        expected_catalog_sha256=config['canonical_source']['catalog_sha256'],spill_root=output/'spill',memory_limit_mib=2816) as source:
        c=source.connection;c.execute('SET threads=1');c.execute("SET max_temp_directory_size='64GiB'")
        print('Independent full-mapping index and BMI checks started',flush=True)
        failures,details=check_indexes(c,product,prepared,census)
        scope_checks,scope_details=check_original_population(c,product,original,prepared)
        failures.update(scope_checks);details.update(scope_details)
        details['original_population_audit']=original_audit
        (output/'index-checks.json').write_text(json.dumps(dict(failures=failures,details=details),indent=2)+'\n')
        print('Independent gas, diagnosis and calendar-day checks started',flush=True)
        fields,field_details=check_fields(c,prepared,config['diagnosis_capture_complete']);failures.update(fields);details.update(field_details)
        failures.update(check_components(c,prepared,original,config['diagnosis_capture_complete'],bool(config.get('same_day_abg_policy'))))
    if before!=file_identity(database): raise ValueError('Source changed during qualification')
    result={'status':'automated_checks_passed' if not any(failures.values()) else 'discrepancies_require_resolution',
        'failures':failures,'details':details,'input_sha256':prep['input_sha256'],
        'mapping_manifest_sha256':entry['sha256'],'config_sha256':config['_config_sha256'],
        'preparation_receipt_sha256':sha256(prepared_dir/'preparation_receipt.json'),
        'selection_evidence_sha256':sha256(prepared_dir/'selection-evidence.json'),
        'qualification_source_sha256':sha256(__file__),'clinical_models_fitted':0,
        'population_scope_id':mapping['population_scope_id'],
        'original_encounter_receipt_sha256':config['encounter_bundle']['expected_receipt_sha256'],
        'human_scientific_review':'pending','clinical_results_qualified':False}
    (output/'qualification.json').write_text(json.dumps(result,indent=2)+'\n')
    print(result['status'],flush=True)
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,required=True)
    parser.add_argument('--prepared',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();config=json.loads(args.config.read_text());config['_config_sha256']=sha256(args.config)
    if args.output.exists():parser.error('Qualification output must be a fresh directory')
    try:
        result=run(config,args.prepared,args.output)
    except Exception as exc:
        if args.output.is_dir():
            reason=str(exc) if isinstance(exc,PreparationError) else type(exc).__name__
            (args.output/'qualification_failure.json').write_text(json.dumps({
                'status':'qualification_execution_failed','reason':reason,
                'clinical_models_fitted':0,'clinical_results_qualified':False},indent=2)+'\n')
        print('Qualification could not complete; private failure receipt retained. No models fitted.')
        raise SystemExit(1)
    raise SystemExit(0 if result['status']=='automated_checks_passed' else 1)
