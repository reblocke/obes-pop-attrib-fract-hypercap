#!/usr/bin/env python3
"""Prepare one study input through pinned upstream readers; never fit models.

Use a reviewed private configuration. Preparation produces evidence for review,
not an accepted clinical manifest. Restricted rows remain in owner-only output.
No dependency installation or upstream pipeline execution is performed.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
import math
import os
import subprocess
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "config/common_index_source_policy.json"
BASE_COLUMNS = ("patient_id", "encounter_id", "encounter_date", "age_at_encounter",
                "encounter_type", "bmi", "sex", "race_ethnicity", "location")
OUTPUT_COLUMNS = BASE_COLUMNS + ("has_abg", "has_vbg", "abg_pco2", "vbg_pco2", "icd_hypercapnia")
DAY_COLUMNS = ("abg_pco2_index_day", "vbg_pco2_index_day", "abg_index_day_available", "vbg_index_day_available")
UPSTREAM_MODULES = ("encounters.reader", "combined_preprocessing.cohort_source",
                    "combined_preprocessing.cohort_source_calendar_population",
                    "combined_preprocessing.cohort_source_calendar_transport")


from source_components import (PreparationError, PROVENANCE, RFS_COLUMNS, SAME_DAY_FIELDS, ICD_FIELDS,
    authenticate_rfs, authenticate_policy, derive_days, derive_codes, summarize_components, join_metadata)
METADATA_COLUMNS = tuple(RFS_COLUMNS) + ('raw_race','raw_ethnicity','obesity_trigger') + tuple(PROVENANCE)


def file_identity(path):
    value = Path(path).stat()
    return value.st_dev, value.st_ino, value.st_size, value.st_mtime_ns


def sha256(path):
    before = file_identity(path)
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            digest.update(block)
    if before != file_identity(path):
        raise PreparationError("Input changed during hashing")
    return digest.hexdigest()


def verify_file(entry):
    path = Path(entry["path"])
    if not path.is_absolute():
        raise PreparationError("Source and evidence paths must be absolute")
    if path.is_symlink() or not path.is_file() or sha256(path) != entry["sha256"].lower():
        raise PreparationError("Trusted input/evidence identity mismatch")
    return path


def verify_canonical_database(source):
    """Reuse this qualification's completed full hash only at unchanged identity.

    The expected receipt digest is caller-trusted and retained in configuration.
    Immutable-source and before/after identity checks still apply during reads.
    Without an explicit receipt, compute and compare the full database hash.
    """
    entry = source.get("full_hash_receipt")
    if entry is None:
        return verify_file(source["database"])
    receipt = json.loads(verify_file(entry).read_text())
    database = Path(source["database"]["path"])
    if (not database.is_absolute() or database.is_symlink() or not database.is_file() or
        receipt.get("sha256") != source["database"]["sha256"].lower() or
        receipt.get("file_identity") != list(file_identity(database)) or
        receipt.get("identity_stable") is not True):
        raise PreparationError("Completed canonical hash receipt does not match this source identity/digest")
    return database


def parsed_date(value):
    if isinstance(value, date):
        try:
            return date.fromisoformat(value.isoformat().split("T")[0])
        except ValueError:
            return None
    if not isinstance(value, str):
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def number(value):
    if value is None or isinstance(value, bool):
        return None
    try:
        value = float(value)
    except (TypeError, ValueError):
        return None
    return value if math.isfinite(value) else None


def gas_record(record, policy, specimen_codes, metadata_units=None):
    """Return specimen, valid value, testing evidence and a single audit reason."""
    code = str(record.get("code") or "").strip()
    inferred = ("abg" if code in policy["arterial_codes"] or code == "32771-8" else
                "vbg" if code in policy["venous_codes"] or code == "40619-9" else None)
    raw_specimen = str(record.get("specimen") or "").strip()
    if raw_specimen and raw_specimen not in specimen_codes:
        raise PreparationError("Captured gas has an unreviewed specimen label")
    specimen = specimen_codes.get(raw_specimen)
    if specimen == "unspecified":
        specimen = None
    if inferred and specimen and inferred != specimen:
        return None, None, False, "specimen_conflict"
    specimen = inferred or specimen
    if specimen not in ("abg", "vbg"):
        return None, None, False, "unspecified_specimen"
    value = number(record.get("numeric_value"))
    tested = value is not None
    if code in policy["temperature_adjusted_codes"]:
        return specimen, None, tested, "temperature_adjusted_excluded"
    if code not in policy["arterial_codes"] + policy["venous_codes"] + policy["unspecified_codes"]:
        return specimen, None, tested, "unreviewed_code"
    if value is None:
        return specimen, None, False, "unusable_numeric"
    unit = record.get("units_of_measure_raw") or record.get("units_of_measure") or metadata_units
    factor = policy["unit_factors_to_mmhg"].get(str(unit or "").strip().lower())
    if factor is None:
        return specimen, None, tested, "unusable_units"
    value *= factor
    limits = policy["arterial_validity" if specimen == "abg" else "venous_validity"]
    if not limits["lower_exclusive"] < value < limits["upper_exclusive"]:
        return specimen, None, tested, "outside_validity_limits"
    return specimen, value, tested, "valid_unadjusted"


def summarize_gases(stream, policy, specimen_codes, *, start_dates, metadata_units=None):
    """Consume every transport row before interpreting zero matches as absence."""
    summaries = {}; audit = Counter(); seen_records = set(); adjusted_keys = set()
    for item in stream:
        key = (item.patient_id, item.encounter_id)
        row = summaries.setdefault(key, {"has_abg": 0, "has_vbg": 0, "abg_pco2": None,
            "vbg_pco2": None, "abg_pco2_index_day": None, "vbg_pco2_index_day": None})
        if item.state in ("unavailable_domain", "unavailable_field"):
            row["has_abg"] = row["has_vbg"] = None
            audit[item.state] += 1
        elif item.record is not None:
            record = item.record
            identity = record.get("source_record_id")
            if not identity or identity in seen_records:
                raise PreparationError("Missing or duplicate gas source-record identity")
            seen_records.add(identity)
            if record.get("code") in policy["temperature_adjusted_codes"]:
                audit["temperature_adjusted_source_records"] += 1
                adjusted_keys.add(key)
            specimen, value, tested, reason = gas_record(record, policy, specimen_codes, metadata_units)
            audit[reason] += 1
            if reason in ("specimen_conflict", "unspecified_specimen"):
                for gas in ("abg", "vbg"):
                    if row["has_" + gas] != 1:
                        row["has_" + gas] = None
            elif specimen:
                if tested:
                    row["has_" + specimen] = 1
                elif row["has_" + specimen] != 1:
                    row["has_" + specimen] = None
            if value is not None:
                cutoff = 45 if specimen == "abg" else 50
                category = "below" if value < cutoff else "at" if value == cutoff else "above"
                audit[specimen + "_" + category + "_threshold_records"] += 1
                name = specimen + "_pco2"
                row[name] = value if row[name] is None else max(row[name], value)
                day = parsed_date(record.get("date"))
                if day is not None and day == start_dates.get(key):
                    day_name = name + "_index_day"
                    row[day_name] = value if row[day_name] is None else max(row[day_name], value)
                elif day is None:
                    audit["valid_value_unknown_collection_date"] += 1
    for row in summaries.values():
        for gas in ("abg", "vbg"):
            row[gas + "_index_day_available"] = int(row[gas + "_pco2_index_day"] is not None)
    audit["encounters_with_temperature_adjusted_records"] = len(adjusted_keys)
    return summaries, dict(audit)


def require_original_keys(frame):
    for name in ("patient_id", "encounter_id"):
        if any(not isinstance(x, str) or not x.strip() for x in frame[name]):
            raise PreparationError("Original keys must be nonblank strings; numeric aliases cannot be relabeled")


def validate_key_coverage(candidate_keys, feature_keys):
    missing = candidate_keys - feature_keys
    if missing:
        raise PreparationError(f"Expanded-population candidates lack legacy mappings: {len(missing)} encounter keys")


def pinned_readers(config):
    if config.get("schema_version") != 2:
        raise PreparationError("Retired preparation schema; use the original-list mapped schema 2")
    pin = json.loads((ROOT / "config" / "common_index_mapping.example.json").read_text())
    if config["upstream_revision"] != pin["upstream_revision"] or config["upstream_reader_sha256"] != pin["upstream_reader_sha256"]:
        raise PreparationError("Upstream reader pin differs from the reviewed adapter")
    readers = {}
    for suffix in UPSTREAM_MODULES + ("encounters.calendar_covariates",):
        module = importlib.import_module("trinetx_preprocessing." + suffix)
        if sha256(module.__file__) != config["upstream_reader_sha256"][suffix]:
            raise PreparationError("Installed upstream reader does not match the reviewed pin")
        readers[suffix] = module
    return readers


def mapping_csv_fields(fields):
    """Promote stored floats before CSV serialization, preserving their exact value."""
    return ["CAST("+name+" AS DOUBLE) AS "+name if name in ("bmi", "age_at_encounter", "reported_bmi", "height_inches", "weight_pounds") else name for name in fields]


def load_mapped_indexes(config, mapper, output, readers):
    """Verify upstream product, then select before gases in whole-patient batches."""
    import duckdb
    import pandas as pd
    path = verify_file(config["covariate_mapping"]["manifest"])
    manifest = json.loads(path.read_text())
    from original_encounter_population import read_original_list, require_original_population
    require_original_population(config, manifest)
    original, _ = read_original_list(config, readers, include_metadata=True)
    verify_file(manifest["original_encounter_list"])
    if manifest.get("product") != "calendar_encounter_covariates_v1" or manifest.get("policy") != mapper.POLICY:
        raise PreparationError("Unreviewed upstream covariate product/policy")
    if set(manifest["files"]) != {"covariates.parquet"}:
        raise PreparationError("Unexpected covariate mapping files")
    product = verify_file({"path":str(path.parent/"covariates.parquet"),"sha256":manifest["files"]["covariates.parquet"]})
    parts = output/"index-partitions"; parts.mkdir(mode=0o700)
    cache = output/"index-cache"
    fields = list(BASE_COLUMNS) + ["bmi_evidence_state"] + list(METADATA_COLUMNS)
    quote = lambda value: "'"+str(value).replace("'","''")+"'"
    with duckdb.connect() as c:
        c.execute("SET memory_limit='2816MiB'"); c.execute("SET threads=1")
        c.execute('SET temp_directory='+quote(output/'selection-spill'))
        c.register('authenticated_original_keys', original.loc[original.encounter_type.isin([2,3]), ['patient_id','encounter_id']])
        outside = c.execute('SELECT count(*) FROM read_parquet(?) m ANTI JOIN authenticated_original_keys o USING(patient_id,encounter_id)', [str(product)]).fetchone()[0]
        missing = c.execute('SELECT count(*) FROM authenticated_original_keys o ANTI JOIN read_parquet(?) m USING(patient_id,encounter_id)', [str(product)]).fetchone()[0]
        if outside or missing:
            raise PreparationError('Mapped keys differ from authenticated original acute encounter list')
        keys=c.execute('SELECT patient_id,encounter_id FROM read_parquet(?)',[str(product)]).fetchdf()
        metadata=join_metadata(keys,original)
        c.register('original_metadata',metadata)
        select_base=','.join('p.'+name for name in list(BASE_COLUMNS)+['bmi_evidence_state']+PROVENANCE)
        select_rfs=','.join('o.'+name for name in list(RFS_COLUMNS)+['raw_race','raw_ethnicity'])
        joined='SELECT '+select_base+','+select_rfs+",'trigger_unresolved' AS obesity_trigger FROM read_parquet("+quote(product)+') p JOIN original_metadata o USING(patient_id,encounter_id)'
        if c.execute('SELECT count(*) FROM ('+joined+')').fetchone()[0]!=manifest['rows']:
            raise PreparationError('Metadata join changed candidate population')
        c.execute("COPY (SELECT *,hash(patient_id)%64 AS part FROM ("+joined+")) TO "+quote(cache)+" (FORMAT PARQUET,PARTITION_BY(part),COMPRESSION ZSTD)")
        for part in range(64):
            files=list((cache/f'part={part}').glob('*.parquet'))
            if not files: continue
            csv_fields = mapping_csv_fields(fields)
            c.execute("COPY (SELECT "+','.join(csv_fields)+" FROM read_parquet(["+','.join(quote(f) for f in files)+"])) TO "+quote(parts/f'{part:02}.csv')+" (FORMAT CSV, HEADER)")
    subprocess.run([config.get("rscript","Rscript"),"--vanilla",str(ROOT/"scripts/select_common_index_mapping.R"),
                    str(parts),str(output/"selected-indexes.csv"),str(output/"selection-evidence.json")],check=True)
    selection=json.loads((output/"selection-evidence.json").read_text())
    selection["population_scope_id"]=manifest["population_scope_id"]
    (output/"selection-evidence.json").write_text(json.dumps(selection,indent=2)+"\n")
    if selection["scope"]["input_encounters"] != manifest["rows"] or selection["bmi_policy_id"] != mapper.POLICY_ID:
        raise PreparationError("Bounded selection does not reconcile to upstream mapping")
    selected_keys=pd.read_csv(output/"selected-indexes.csv",usecols=["patient_id","encounter_id"],
                              dtype="string",keep_default_na=False)
    with duckdb.connect() as c:
        c.execute("SET memory_limit='2816MiB'"); c.execute("SET threads=1")
        c.register('selected_original_keys',selected_keys)
        features=c.execute('SELECT '+','.join('p.'+n for n in fields)+' FROM read_parquet(?,hive_partitioning=false) p '
            'JOIN selected_original_keys k USING(patient_id,encounter_id)',[str(cache/'part=*'/'*.parquet')]).fetchdf()
    # Promote stored Stata float32 exactly; avoid a shortened CSV representation.
    for name in features.select_dtypes(include=["float32"]).columns:
        features[name]=features[name].astype("float64")
    if len(features)!=selection["counts"]["n_index_resolved"] or features.patient_id.duplicated().any():
        raise PreparationError("Prepared common indexes do not reconcile")
    return features, manifest, selection


def prepare(config, output):
    policy = json.loads(POLICY_PATH.read_text())
    if config["source_policy_id"] != policy["source_policy_id"] or config["schema_version"] != 2:
        raise PreparationError("Unreviewed preparation policy or configuration version")
    if set(config["columns"]) != set(BASE_COLUMNS) or len(set(config["columns"].values())) != len(BASE_COLUMNS):
        raise PreparationError("Preparation requires distinct mappings for all nine base fields")
    encoding=config.get("base_field_encoding","typed_v1")
    if encoding != "typed_v1":
        raise PreparationError("New mapped covariates require explicit typed encoding")
    source_columns = list(BASE_COLUMNS) + ["bmi_evidence_state"] + list(METADATA_COLUMNS)
    rfs_evidence = authenticate_rfs(config)
    day_policy = authenticate_policy(config)
    if not config["specimen_codes"] or any(v not in ("abg", "vbg", "other", "unspecified") for v in config["specimen_codes"].values()):
        raise PreparationError("Explicit reviewed specimen vocabulary is required")
    if type(config["diagnosis_capture_complete"]) is not bool:
        raise PreparationError("Diagnosis capture must be explicitly reviewed")
    if config["index_day_status"] not in ("pending", "qualified"):
        raise PreparationError("Invalid calendar-day source status")
    systems = config["diagnosis_code_systems"]
    if not isinstance(systems, list) or not systems or any(not isinstance(x,str) or not x.strip() for x in systems) or len(set(systems))!=len(systems):
        raise PreparationError("Distinct reviewed diagnosis code systems are required")
    metadata_unit = config.get("source_metadata_pressure_unit")
    if metadata_unit is not None and str(metadata_unit).strip().lower() not in policy["unit_factors_to_mmhg"]:
        raise PreparationError("Invalid source-metadata pressure unit")
    if not {"lineage", "population", "fields"} <= set(config["source_evidence_files"]):
        raise PreparationError("Reviewed lineage, population and field evidence references are required")
    for entry in config["source_evidence_files"].values():
        verify_file(entry)
    database = verify_canonical_database(config["canonical_source"])
    verify_file(config["canonical_source"]["sidecar"])
    before = (file_identity(database), file_identity(config["canonical_source"]["sidecar"]["path"]))
    readers = pinned_readers(config)
    import pandas as pd
    bundle = config.get("encounter_bundle", {})
    mapping_path = verify_file(config["covariate_mapping"]["manifest"])
    mapping_manifest = json.loads(mapping_path.read_text())
    identity = mapping_manifest["source_identity"]
    if (identity["canonical_sidecar_sha256"] != config["canonical_source"]["sidecar"]["sha256"] or
        identity["catalog_sha256"] != config["canonical_source"]["catalog_sha256"] or
        identity["database_file_identity"] != list(file_identity(database))):
        raise PreparationError("Covariate mapping belongs to another canonical input")
    features, mapping_manifest, prepared_selection = load_mapped_indexes(config, readers["encounters.calendar_covariates"], output, readers)
    if not set(BASE_COLUMNS + ("bmi_evidence_state",)) <= set(features):
        raise PreparationError("Mapped covariate product lacks required fields")
    require_original_keys(features)
    source = config["canonical_source"]
    if not Path(source["spill_root"]).is_absolute():
        raise PreparationError("Spill location must be absolute")
    # This generic source API is metadata/schema validation. Study acceptance is
    # separately bound by the caller's reviewed lineage/population evidence.
    with readers["combined_preprocessing.cohort_source"].open_cohort_source(
        database, expected_catalog_sha256=source["catalog_sha256"],
        spill_root=Path(source["spill_root"]), memory_limit_mib=2816) as opened:
        connection = opened.connection
        candidates = features[["patient_id", "encounter_id", "encounter_date", "encounter_type"]].rename(columns={"encounter_date":"encounter_start_date"}).copy()
        candidate_audit = SimpleNamespace(**mapping_manifest["source_candidate_audit"])
        if len(candidates) != prepared_selection["counts"]["n_index_resolved"] or candidates.duplicated(["patient_id", "encounter_id"]).any():
            raise PreparationError("Mapped candidate key accounting failed")
        if not config["encounter_type_codes"] or any(v not in ("EMER", "IMP", "OTHER", "NA") for v in config["encounter_type_codes"].values()):
            raise PreparationError("Invalid reviewed encounter-type vocabulary")
        if candidate_audit.invalid_encounter_key_rows:
            raise PreparationError("Captured encounters contain invalid original keys; source scope needs review")
        candidate_keys = set(zip(candidates.patient_id, candidates.encounter_id))
        validate_key_coverage(candidate_keys, set(zip(features.patient_id, features.encounter_id)))
        legacy_confirmed = set()
        for row in features.itertuples(index=False):
            legacy_day = parsed_date(row.encounter_date)
            legacy_age = number(row.age_at_encounter)
            legacy_type = None if pd.isna(row.encounter_type) else str(row.encounter_type).strip().upper()
            if legacy_type is not None and legacy_type not in config["encounter_type_codes"]:
                raise PreparationError("Legacy encounter setting code lacks a reviewed mapping")
            if legacy_day is not None and legacy_day.year==2022 and legacy_age is not None and legacy_age>=18 and config["encounter_type_codes"].get(legacy_type) in ("EMER","IMP"):
                legacy_confirmed.add((row.patient_id,row.encounter_id))
        if legacy_confirmed-candidate_keys:
            raise PreparationError(f"Legacy acute-care candidates are missing or contradict captured scope: {len(legacy_confirmed-candidate_keys)} encounter keys")
        # Preserve all base versions, including unresolved chronology/completeness.
        selected = features.merge(candidates, on=["patient_id", "encounter_id"], how="inner", validate="many_to_one", suffixes=("", "_source"))
        if not len(selected):
            raise PreparationError("No candidate encounters in the authenticated study scope")
        starts = dict(zip(zip(candidates.patient_id,candidates.encounter_id), [parsed_date(x) for x in candidates.encounter_start_date]))
        unknown_dates = 0
        # Explicit Date objects are written below; avoid implicit datetime64
        # coercion when the typed upstream mapping came through pandas/Arrow.
        selected["encounter_date"] = selected["encounter_date"].astype(object)
        for i in selected.index:
            key = (selected.at[i,"patient_id"],selected.at[i,"encounter_id"])
            legacy_date = parsed_date(selected.at[i,"encounter_date"])
            day = starts[key]
            if day is not None and legacy_date is not None and day != legacy_date:
                raise PreparationError("Legacy and captured encounter chronology disagree")
            selected.at[i,"encounter_date"] = day
            unknown_dates += day is None
            raw_type = selected.at[i,"encounter_type_source"]
            source_type = config["encounter_type_codes"].get(raw_type)
            if source_type == "NA":source_type=None
            legacy_type = selected.at[i,"encounter_type"]
            if not pd.isna(legacy_type):
                legacy_type = str(legacy_type).strip().upper()
                if legacy_type not in config["encounter_type_codes"]:
                    raise PreparationError("Legacy encounter setting code lacks a reviewed mapping")
                legacy_mapped=config["encounter_type_codes"][legacy_type]
                if source_type is not None and legacy_mapped!="NA" and legacy_mapped != source_type:
                    raise PreparationError("Legacy and captured encounter settings disagree")
            selected.at[i,"encounter_type"] = source_type
        connection.register("study_keys", candidates[["patient_id", "encounter_id"]])
        target_codes = [code.replace(".","") for code in policy["icd_codes"]]
        expected_icd_records = connection.execute(
            "SELECT count(*) FROM source_diagnosis d JOIN study_keys k USING(patient_id,encounter_id) "
            "WHERE replace(upper(trim(d.code)),'.','')=ANY(?)", [target_codes]).fetchone()[0]
        source_systems = {row[0] for row in connection.execute(
            "SELECT DISTINCT d.code_system FROM source_diagnosis d JOIN study_keys k "
            "USING(patient_id,encounter_id) WHERE replace(upper(trim(d.code)),'.','')=ANY(?)", [target_codes]).fetchall()}
        if not source_systems <= set(systems):
            raise PreparationError("Target-like diagnosis records have unreviewed code systems")
        transport = readers["combined_preprocessing.cohort_source_calendar_transport"].iter_calendar_source_records
        codes = sum((policy[name] for name in ("arterial_codes","venous_codes","unspecified_codes","temperature_adjusted_codes")), [])
        print("Extracting exact-code gas evidence at fixed indexes", flush=True)
        gas, gas_audit = summarize_gases(transport(connection,encounter_relation="study_keys",domain="lab",
            code_selectors=[("LOINC",c) for c in codes]), policy, config["specimen_codes"], start_dates=starts,
            metadata_units=config.get("source_metadata_pressure_unit"))
        print("Gas evidence complete; extracting diagnosis evidence", flush=True)
        selectors = [(system, code) for system in config["diagnosis_code_systems"]
                     for target in policy["icd_codes"] for code in (target,target.replace(".",""))]
        if not selectors:
            raise PreparationError("Reviewed diagnosis code systems are required")
        code_flags, code_audit = summarize_components(transport(connection,encounter_relation="study_keys",domain="diagnosis",
            code_selectors=selectors), lambda key,rows,unavailable: derive_codes(rows,config["diagnosis_capture_complete"],systems,key,unavailable))
        icd_audit={name:code_audit[name] for name in ("unavailable_domain","unavailable_field") if name in code_audit}
        icd_audit["target_records"]=code_audit.get("candidate_records",0)
        icd={key:1 if any(row[f]==1 for f in ICD_FIELDS[1:]) else 0 if row["icd_capture_state"]=="complete" else None for key,row in code_flags.items()}
        days, day_audit = summarize_components(transport(connection,encounter_relation="study_keys",domain="lab",
            code_selectors=[("LOINC",c) for c in ("2019-8","2744-1","32771-8","2021-4","2746-6","11558-4")]),
            lambda key,rows,unavailable: derive_days(rows,None if unavailable else day_policy))
        print("Diagnosis evidence complete; validating typed output", flush=True)
        if icd_audit.get("target_records", 0) != expected_icd_records:
            raise PreparationError("Transported ICD target records disagree with independent captured-source count")
        if set(gas) != candidate_keys or set(icd) != candidate_keys or set(days) != candidate_keys:
            raise PreparationError("Evidence streams do not reconcile to candidate keys")
        row_columns = BASE_COLUMNS + ("bmi_evidence_state",) + METADATA_COLUMNS
        columns = OUTPUT_COLUMNS + ("bmi_evidence_state",) + METADATA_COLUMNS + SAME_DAY_FIELDS + ICD_FIELDS + (DAY_COLUMNS if config["index_day_status"] == "qualified" else ())
        csv_path = output / "study-input.csv"
        with csv_path.open("x",newline="") as file:
            writer = csv.DictWriter(file, fieldnames=columns); writer.writeheader()
            for values in selected[list(row_columns)].itertuples(index=False,name=None):
                row = dict(zip(row_columns,values)); key=(row["patient_id"],row["encounter_id"])
                row.update({k:v for k,v in gas[key].items() if k in columns});row["icd_hypercapnia"]=icd[key]
                row.update(days[key]);row.update(code_flags[key])
                for name in ("encounter_date","reported_date","height_date","weight_date"):
                    row[name]=None if pd.isna(row[name]) else parsed_date(row[name])
                # pandas NaN/NA/NaT must remain true missing values, not categories.
                row={k:(None if pd.isna(v) else v) for k,v in row.items()}
                writer.writerow(row)
    if before != (file_identity(database),file_identity(source["sidecar"]["path"])):
        raise PreparationError("Canonical source identity changed during preparation")
    for entry in config["source_evidence_files"].values():
        verify_file(entry)
    verify_file(config["covariate_mapping"]["manifest"])
    for filename, digest in mapping_manifest["files"].items():
        verify_file({"path": str(mapping_path.parent / filename), "sha256": digest})
    subprocess.run([config.get("rscript","Rscript"),"--vanilla",str(ROOT/"scripts/write_common_index_input.R"),
                    str(csv_path),str(output/"study-input.rds")],check=True)
    fields={"source_policy":policy,"gas_audit":gas_audit,"icd_audit":icd_audit,
        "base_field_encoding":encoding,"base_source_columns":source_columns,
        "specimen_codes":config["specimen_codes"],"metadata_pressure_unit":config.get("source_metadata_pressure_unit"),
        "diagnosis_code_systems":config["diagnosis_code_systems"],"diagnosis_capture_complete":config["diagnosis_capture_complete"],
        "testing_evidence_definition":"numeric captured PCO2 result, including adjusted or unusable numeric results, establishes specimen-specific testing; absent selected-code evidence is not proof of no gas draw; nonnumeric/ambiguous evidence remains unknown",
        "source_config_sha256":config["_config_sha256"],
        "base_missingness":{name:int(selected[name].isna().sum()) for name in BASE_COLUMNS if name not in ("patient_id","encounter_id")},
        "index_day_status":config["index_day_status"],"automated_verification":True,
        "human_review":"pending","clinical_results_qualified":False}
    fields.update(independent_icd_record_count=expected_icd_records, bmi_policy=mapping_manifest["policy"],
        bmi_audit=mapping_manifest["bmi_audit"], bmi_methods=mapping_manifest["bmi_methods"],
        bmi_mapping_manifest_sha256=config["covariate_mapping"]["manifest"]["sha256"],
        population_scope_id=mapping_manifest["population_scope_id"],
        original_encounter_list=mapping_manifest["original_encounter_list"])
    (output/"field-evidence.json").write_text(json.dumps(fields,indent=2)+"\n")
    population={"source_policy_id":policy["source_policy_id"],
        "canonical_database_sha256":source["database"]["sha256"],"canonical_sidecar_sha256":source["sidecar"]["sha256"],
        "accepted_bundle_receipt_sha256":bundle.get("expected_receipt_sha256"),"source_audit":vars(candidate_audit),
        "candidate_projection":"all_raw_rows_consensus_then_study_scope_patient_hash_16_v1",
        "source_scope":"captured encounters: 2022 or unresolved date; acute-care or unresolved type; adult birth-year proxy or unresolved age; no gas/BMI/completeness prefilter",
        "candidate_encounter_keys":len(candidate_keys),"missing_legacy_mapping_keys":0,"input_rows":len(selected),
        "legacy_confirmed_scope_keys":len(legacy_confirmed),"legacy_scope_keys_missing_or_contradictory":0,
        "automated_verification":True,"human_review":"pending","clinical_results_qualified":False}
    population.pop("missing_legacy_mapping_keys", None)
    population["missing_covariate_mapping_keys"] = 0
    population["mapped_confirmed_scope_keys"] = population.pop("legacy_confirmed_scope_keys")
    population.update(bmi_policy_id=mapping_manifest["policy"]["id"],
        source_candidate_encounter_keys=mapping_manifest["rows"],
        selected_common_index_rows=len(selected),
        candidate_projection="original_selected_encounters_patient_hash_16_v1",
        source_scope="authenticated original selected ED/inpatient keys only; broader history supplies prior evidence only",
        population_scope_id=mapping_manifest["population_scope_id"],
        original_encounter_list=mapping_manifest["original_encounter_list"],
        bmi_mapping_manifest_sha256=config["covariate_mapping"]["manifest"]["sha256"])
    (output/"population-evidence.json").write_text(json.dumps(population,indent=2)+"\n")
    receipt={"status":"prepared_not_qualified","source_policy_id":policy["source_policy_id"],
        "base_field_encoding":encoding,
        "input_sha256":sha256(output/"study-input.rds"),"input_csv_sha256":sha256(output/"study-input.csv"),"candidate_encounter_keys":len(candidate_keys),
        "input_rows":len(selected),"unresolved_source_date_rows":unknown_dates,
        "coverage":"all scoped candidate keys have source-mapped covariates; missing BMI retained",
        "source_config_sha256":config["_config_sha256"],"upstream_reader_sha256":config["upstream_reader_sha256"],
        "source_policy_sha256":sha256(POLICY_PATH),"preparation_source_sha256":sha256(__file__),
        "population_helper_sha256":sha256(ROOT/"scripts/original_encounter_population.py"),
        "writer_source_sha256":sha256(ROOT/"scripts/write_common_index_input.R"),
        "field_evidence_sha256":sha256(output/"field-evidence.json"),
        "population_evidence_sha256":sha256(output/"population-evidence.json"),
        "clinical_models_fitted":0,"human_review":"pending","clinical_results_qualified":False}
    selection_hash=sha256(output/"selection-evidence.json")
    shared=dict(schema_version=1,input_sha256=receipt["input_sha256"],selection_sha256=selection_hash,
        source_config_sha256=config["_config_sha256"],canonical_database_sha256=source["database"]["sha256"],
        source_unchanged=True,n_input_encounters=len(selected),clinical_models_fitted=0,
        adapter_sources={name:sha256(ROOT/name) for name in ("scripts/source_components.py","scripts/prepare_common_index_input.py","scripts/write_common_index_input.R","scripts/read_source_csv.R","scripts/select_common_index_mapping.R")},
        human_review="Automated extraction; no new investigator approval asserted")
    day_evidence=dict(shared,policy_id="same_day_arterial_cooccurrence_v1",status="qualified" if day_policy else "unavailable",
        reason="" if day_policy else "No authenticated recorded-day arterial policy supplied",policy=day_policy,
        aggregate_counts=day_audit,patient_states=dict(Counter(x['same_day_abg_state'] for x in days.values())))
    icd_evidence=dict(shared,policy_id="icd_acuity_v1",status="qualified" if config["diagnosis_capture_complete"] else "unavailable",
        diagnosis_capture_complete=config["diagnosis_capture_complete"],diagnosis_code_systems=systems,target_codes=target_codes,
        source_target_records=expected_icd_records,transported_records=icd_audit["target_records"],aggregate_counts=code_audit)
    for filename,evidence in (("cooccurrence-evidence.json",day_evidence),("icd-acuity-evidence.json",icd_evidence),("rfs-evidence.json",rfs_evidence)):
        (output/filename).write_text(json.dumps(evidence,indent=2)+"\n")
    (output/"preparation_receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
    manifest=json.loads((ROOT/"config/triangulation_input.example.json").read_text())
    manifest.update(input_sha256=receipt["input_sha256"],source_policy_id=policy["source_policy_id"],
        source_identity=config["source_identity"],columns={name:name for name in OUTPUT_COLUMNS},
        encounter_type_codes={"EMER":"EMER","IMP":"IMP","OTHER":"OTHER"},
        source_evidence_files={"lineage":config["source_evidence_files"]["lineage"]})
    manifest["source_evidence_files"]["fields"]={"path":"field-evidence.json","sha256":receipt["field_evidence_sha256"]}
    manifest["source_evidence_files"]["population"]={"path":"population-evidence.json","sha256":receipt["population_evidence_sha256"]}
    for name in ("sex","race_ethnicity","location"):
        manifest["category_values"][name]=sorted({str(x) for x in selected[name] if not pd.isna(x)})
    manifest["index_day"]={"status":config["index_day_status"],"columns":{},"binary_codes":{},
        "semantics":"max_valid_specimen_PCO2_on_encounter_start_calendar_date"}
    if config["index_day_status"]=="qualified":
        manifest["index_day"]["columns"]={name:name for name in DAY_COLUMNS}
        manifest["index_day"]["binary_codes"]={name:{"0":"0","1":"1"} for name in DAY_COLUMNS if name.endswith("available")}
        manifest["source_evidence_files"]["index_day"]=manifest["source_evidence_files"]["fields"]
    manifest.update(population_scope_id=mapping_manifest["population_scope_id"], bmi_policy_id=mapping_manifest["policy"]["id"], bmi_evidence_column="bmi_evidence_state")
    manifest["source_evidence_files"]["selection"]={"path":"selection-evidence.json","sha256":sha256(output/"selection-evidence.json")}
    manifest.update(schema_version=5,study_design="common_index_valid_bmi_v1",
        population_policy="first_2022_adult_ED_inpatient_valid_BMI_before_gas_and_completeness",
        rfs_policy_id="historical_source_membership_v1",
        metadata_columns={name:name for name in METADATA_COLUMNS+SAME_DAY_FIELDS+ICD_FIELDS})
    for name,filename in (("rfs","rfs-evidence.json"),("same_day_abg","cooccurrence-evidence.json"),("icd_acuity","icd-acuity-evidence.json")):
        manifest["source_evidence_files"][name]={"path":filename,"sha256":sha256(output/filename)}
    manifest["index_preselected"]=True
    manifest["source_evidence_files"]["cohort_audit"]={"path":"cohort-audit-companion.rds","sha256":sha256(output/"cohort-audit-companion.rds")}
    (output/"triangulation_input.pending.json").write_text(json.dumps(manifest,indent=2)+"\n")
    return receipt


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path,help="Fresh owner-only private/ignored directory")
    args=parser.parse_args();os.umask(0o077)
    destination=args.output.resolve()
    if destination==ROOT or ROOT in destination.parents:
        check=subprocess.run(["git","check-ignore","--stdin"],input=str(destination/"study-input.csv")+"\n",
                             text=True,cwd=ROOT,capture_output=True)
        if check.returncode!=0:parser.error("Restricted preparation output inside the repository must be ignored by Git")
    if args.output.exists():parser.error("Output must be a fresh directory")
    args.output.mkdir(parents=True,mode=0o700)
    try:
        config=json.loads(args.config.read_text());config["_config_sha256"]=sha256(args.config)
        receipt=prepare(config,args.output)
        if config["_config_sha256"]!=sha256(args.config):raise PreparationError("Preparation configuration changed during execution")
    except Exception as exc:
        # No patient keys, values or arbitrary third-party exception text in stdout.
        message=str(exc) if isinstance(exc,PreparationError) else type(exc).__name__
        (args.output/"preparation_failure.json").write_text(json.dumps({"status":"preparation_failed","reason":message,
            "clinical_models_fitted":0,"clinical_results_qualified":False},indent=2)+"\n")
        print("Preparation failed; private failure receipt retained. No clinical models fitted.",file=sys.stderr)
        return 1
    print("Preparation completed; source qualification and human review remain pending.")
    print("Candidate encounter keys:",receipt["candidate_encounter_keys"],"; clinical models fitted: 0")
    return 0


if __name__=="__main__":
    sys.exit(main())
