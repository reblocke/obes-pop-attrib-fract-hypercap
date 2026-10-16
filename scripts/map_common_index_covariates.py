#!/usr/bin/env python3
"""Map the study's original selected encounter keys through upstream covariate derivation.

Restricted products and scratch must be outside repositories. No model fitting
or source acceptance is performed. Completed missing BMI remains in the product.
"""

from __future__ import annotations

import argparse
import json
import os
import time
from pathlib import Path

from prepare_common_index_input import file_identity, pinned_readers, sha256, verify_file, verify_canonical_database
from original_encounter_population import POPULATION_ID, read_original_list, stage_original_membership


def run(config, output):
    from trinetx_preprocessing.combined_preprocessing.builder import require_safe_output_location
    from trinetx_preprocessing.combined_preprocessing.cohort_source import open_cohort_source
    from trinetx_preprocessing.combined_preprocessing.cohort_source_calendar_population import build_calendar_candidate_fields
    from trinetx_preprocessing.encounters import calendar_covariates as mapper
    from trinetx_preprocessing.encounters.compatibility import no_symlinks

    readers = pinned_readers(config)
    original, original_audit = read_original_list(config, readers)
    output = no_symlinks(output)
    require_safe_output_location(output, artifact_label="broader BMI mapping")
    output.mkdir(mode=0o700, parents=True, exist_ok=False)
    start = time.time()

    def progress(stage, **counts):
        receipt = dict(stage=stage, elapsed_seconds=time.time()-start,
                       clinical_models_fitted=0, **counts)
        (output/'progress.json').write_text(json.dumps(receipt, indent=2)+'\n')
        print(stage, counts, flush=True)

    database = verify_canonical_database(config['canonical_source'])
    before = file_identity(database)
    spill = output/'spill'; spill.mkdir(mode=0o700)
    source = config['canonical_source']
    if sha256(source['sidecar']['path']) != source['sidecar']['sha256']:
        raise ValueError('Canonical sidecar hash mismatch')
    if sha256(mapper.__file__) != config['upstream_reader_sha256']['encounters.calendar_covariates']:
        raise ValueError('Covariate mapper differs from reviewed source pin')
    with open_cohort_source(database, expected_catalog_sha256=source['catalog_sha256'],
                            spill_root=spill, memory_limit_mib=2816) as opened:
        c = opened.connection
        c.execute('SET threads=1')
        c.execute('SET preserve_insertion_order=false')
        c.execute("SET max_temp_directory_size='64GiB'")
        def quote(path): return "'"+str(path).replace("'", "''")+"'"
        def copy(query, path, partition=False):
            opts=', PARTITION_BY(part)' if partition else ''
            c.execute(f'COPY ({query}) TO {quote(path)} (FORMAT PARQUET, COMPRESSION SNAPPY, ROW_GROUP_SIZE 2048{opts})')
        original.to_parquet(output/'original-encounters.parquet', index=False)
        original_audit = stage_original_membership(c, original)
        progress('stage_original_selected_encounter_rows', original_keys=original_audit['original_acute_encounters'])
        copy('SELECT patient_id,encounter_id,start_date,start_timestamp_precision,type,'
             'end_date,end_timestamp_precision,hash(patient_id)%16 AS part FROM original_source_encounters',
             output/'encounter-cache', partition=True)
        audit = {}; expected_rows = 0; candidate_files = []
        for part in range(16):
            files=list((output/'encounter-cache'/f'part={part}').glob('*.parquet'))
            if not files: continue
            c.execute('CREATE OR REPLACE TEMP VIEW raw_partition AS SELECT * FROM read_parquet(['+','.join(quote(f) for f in files)+'])')
            result = build_calendar_candidate_fields(c, output_relation='candidate_consensus',
                                                     source_encounter_relation='raw_partition')
            for key, val in vars(result).items(): audit[key] = audit.get(key,0)+val
            n = c.execute('SELECT count(*) FROM candidate_consensus').fetchone()[0]
            expected_rows += n
            # Accepted original membership supplies setting. Preserve raw conflicts
            # for audit; unrelated source-history keys never enter this relation.
            path=output/f'candidates-{part:02}.parquet'
            copy("SELECT k.* EXCLUDE(encounter_type), k.encounter_type AS raw_encounter_type,"
                 "o.encounter_type,e.encounter_end_date FROM candidate_consensus k "
                 "JOIN original_acute_keys o USING(patient_id,encounter_id) LEFT JOIN "
                 "(SELECT patient_id,encounter_id,CASE WHEN count(*) FILTER(WHERE "
                 "end_timestamp_precision IS DISTINCT FROM 'date_only' OR "
                 "try_strptime(end_date,['%Y%m%d','%Y-%m-%d']) IS NULL)=0 "
                 "AND min(end_date)=max(end_date) THEN "
                 "cast(min(try_strptime(end_date,['%Y%m%d','%Y-%m-%d'])) AS DATE) END AS encounter_end_date "
                 "FROM raw_partition GROUP BY 1,2) e USING(patient_id,encounter_id)", path)
            candidate_files.append(path)
            progress('original_candidate_partition_completed', partition=part+1, candidate_keys=n)
            c.execute('DROP TABLE candidate_consensus')
        if audit['invalid_encounter_key_rows'] or expected_rows != original_audit['original_acute_encounters']:
            raise ValueError('Original encounter key accounting failed')
        c.execute('CREATE TEMP VIEW all_candidates AS SELECT * FROM read_parquet(['+','.join(quote(p) for p in candidate_files)+'])')
        cached = config.get('staged_source_cache')
        if cached:
            staging = json.loads(verify_file(cached).read_text())
            if (staging['source_file_identity'] != list(before) or staging['canonical_sidecar_sha256'] != source['sidecar']['sha256'] or staging['source_database_sha256'] != source['database'].get('sha256')):
                raise ValueError('Staged vital source belongs to another canonical snapshot')
            for path, digest in staging['files'].items(): verify_file({'path':path,'sha256':digest})
            coverage = c.execute('SELECT count(*) FROM (SELECT DISTINCT patient_id FROM all_candidates) a '
                'ANTI JOIN (SELECT DISTINCT patient_id FROM read_parquet(['+','.join(quote(p) for p in staging['candidates'])+'])) b USING(patient_id)').fetchone()[0]
            if coverage:
                cached = None  # Re-extract actual source; never declare unexamined BMI missing.
            original_audit['patients_outside_completed_vital_cache'] = coverage
        if not cached:
            progress('stage_relevant_raw_vital_history')
            codes = [code for values in mapper.CODES.values() for code in values]
            code_sql = ','.join(quote(code) for code in codes)
            copy('SELECT v.source_record_id,v.patient_id,v.encounter_id,v.code_system,v.code,'
                 'v.event_datetime,v.timestamp_precision,v.value,v.numeric_value,v.text_value,v.units_of_measure,'
                 'hash(v.patient_id)%16 AS part FROM source_vital_measurement v '
                 'SEMI JOIN (SELECT DISTINCT patient_id FROM all_candidates) k USING(patient_id) '
                 f"WHERE v.code_system='LOINC' AND v.code IN ({code_sql})",
                 output/'vital-cache', partition=True)
        captured = c.execute("SELECT count(*) FROM source_file_inventory WHERE domain='vitals'").fetchone()[0]>0
        for part in range(16):
            if not (output/f'candidates-{part:02}.parquet').exists(): continue
            c.execute('CREATE OR REPLACE TEMP VIEW candidate_keys AS SELECT * FROM read_parquet('+quote(output/f'candidates-{part:02}.parquet')+')')
            vital_files = ([Path(p) for p in staging['vitals'][str(part)]] if cached else list((output/'vital-cache'/f'part={part}').glob('*.parquet')))
            if vital_files:
                c.execute('CREATE OR REPLACE TEMP VIEW raw_vitals AS SELECT * FROM read_parquet(['+','.join(quote(path) for path in vital_files)+'])')
            else:
                c.execute('CREATE OR REPLACE TEMP VIEW raw_vitals AS SELECT * FROM source_vital_measurement WHERE false')
            mapped = mapper.build_calendar_covariates(c, candidate_relation='candidate_keys',
                vital_relation='raw_vitals', vital_capture_available=captured,
                unit_defaults=config.get('vital_unit_defaults'))
            copy(f'SELECT * FROM {mapped}', output/f'mapped-{part:02}.parquet')
            c.execute('DROP TABLE '+mapped)
            progress('mapped_partition_completed', partition=part+1)
        c.execute('CREATE TEMP VIEW mapped_all AS SELECT * FROM read_parquet('+quote(output/'mapped-*.parquet')+')')
        if c.execute('SELECT count(*) FROM mapped_all').fetchone()[0] != expected_rows:
            raise ValueError('Mapped candidate rows do not reconcile')
        if c.execute('SELECT count(*) FROM (SELECT patient_id,encounter_id FROM mapped_all GROUP BY 1,2 HAVING count(*)>1)').fetchone()[0]:
            raise ValueError('Mapped duplicate original keys')
        progress('write_covariate_product')
        mapper.write_calendar_covariates(c, 'mapped_all', output/'product',
            source_identity=dict(canonical_sidecar_sha256=source['sidecar']['sha256'],
                                 catalog_sha256=source['catalog_sha256'],
                                 database_file_identity=list(before),
                                 upstream_revision=config['upstream_revision'],
                                 staged_source_cache_sha256=(cached['sha256'] if cached else None),
                                 original_encounter_receipt_sha256=config['encounter_bundle']['expected_receipt_sha256'],
                                 mapping_controller_sha256=sha256(__file__),
                                 population_helper_sha256=sha256(Path(__file__).with_name('original_encounter_population.py'))))
        path=output/'product'/'manifest.json'; manifest=json.loads(path.read_text())
        manifest['source_candidate_audit']=audit
        manifest['population_scope_id']=POPULATION_ID
        manifest['original_encounter_list']={'variant':'FULL_DATA','receipt_sha256':config['encounter_bundle']['expected_receipt_sha256'],
            'path':str(output/'original-encounters.parquet'),'sha256':sha256(output/'original-encounters.parquet'),'audit':original_audit}
        manifest['candidate_scope']='authenticated original selected ED/inpatient encounter keys; before available-BMI eligibility, gas or completeness'
        (output/'original-population-audit.json').write_text(json.dumps(original_audit,indent=2)+'\n')
        manifest['bmi_audit']={str(k):int(v) for k,v in c.execute('SELECT bmi_evidence_state,count(*) FROM mapped_all GROUP BY 1').fetchall()}
        manifest['bmi_methods']={str(k):int(v) for k,v in c.execute('SELECT bmi_method,count(*) FROM mapped_all GROUP BY 1').fetchall()}
        manifest['bmi_gt120']=c.execute('SELECT count(*) FROM mapped_all WHERE bmi>120').fetchone()[0]
        path.write_text(json.dumps(manifest,indent=2)+'\n')
    if before != file_identity(database): raise ValueError('Source identity changed during mapping')
    progress('mapping_completed_not_qualified', candidate_keys=expected_rows,
             mapping_manifest_sha256=sha256(output/'product'/'manifest.json'))
    return output/'product'


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(); os.umask(0o077)
    run(json.loads(args.config.read_text()),args.output)
