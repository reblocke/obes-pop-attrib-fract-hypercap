"""Authenticate original study membership without importing raw-history visits."""
from __future__ import annotations

from pathlib import Path

from prepare_common_index_input import PreparationError, require_original_keys

POPULATION_ID = "original_selected_encounters_v1"
ORIGINAL_COLUMNS = ("patient_id", "encounter_id", "pat_enc_hash", "encounter_date",
                    "encounter_type", "first_encounter")


def verify_original_list(frame):
    require_original_keys(frame)
    if frame.duplicated(["patient_id", "encounter_id"]).any():
        raise PreparationError("Original encounter list has duplicate keys")
    if (frame["pat_enc_hash"].isna().any() or frame["pat_enc_hash"].eq("").any()
            or frame.duplicated(["patient_id", "encounter_date", "pat_enc_hash"]).any()):
        raise PreparationError("Original first-encounter ordering is not unique")
    if (not frame.encounter_type.isin([1, 2, 3]).all()
            or not frame.first_encounter.isin([0, 1]).all()):
        raise PreparationError("Original encounter dictionary is outside its accepted codes")
    ordered = frame.sort_values(["patient_id", "encounter_date", "pat_enc_hash"],
                                kind="mergesort", na_position="last")
    expected = (~ordered.patient_id.duplicated()).astype(int)
    bad = int((ordered.first_encounter != expected).sum())
    if bad:
        raise PreparationError(f"Original first-encounter flags disagree with frozen ordering: {bad}")
    return {"population_scope_id": POPULATION_ID, "original_encounters": len(frame),
            "original_patients": int(frame.patient_id.nunique()),
            "original_acute_encounters": int(frame.encounter_type.isin([2, 3]).sum()),
            "first_flag_disagreements": bad,
            "first_flag_order": "patient_id, original encounter_date, pat_enc_hash; missing dates last",
            "index_policy": "first eligible adult 2022 BMI>=30 ED/inpatient within original selected keys; before gases",
            "original_first_flag_is_prefilter": False}


def read_original_list(config, readers):
    if config.get("population_scope_id") != POPULATION_ID:
        raise PreparationError("New mapping requires the original encounter population policy")
    bundle = config["encounter_bundle"]
    if bundle["variant"] != "FULL_DATA":
        raise PreparationError("Original membership requires FULL_DATA; no AFTER_EXCLUSION imputation")
    frame = readers["encounters.reader"].read_encounters(
        Path(bundle["path"]), variant="FULL_DATA", receipt_path=Path(bundle["receipt_path"]),
        expected_receipt_sha256=bundle["expected_receipt_sha256"],
        validation_report_path=Path(bundle["validation_report_path"]), columns=list(ORIGINAL_COLUMNS))
    return frame, verify_original_list(frame)


def stage_original_membership(connection, original):
    audit = verify_original_list(original)
    connection.register("original_list_rows", original)
    connection.execute("CREATE TEMP TABLE original_acute_keys AS SELECT patient_id,encounter_id,"
                       "CASE encounter_type WHEN 2 THEN 'EMER' WHEN 3 THEN 'IMP' END AS encounter_type "
                       "FROM original_list_rows WHERE encounter_type IN (2,3)")
    connection.execute("CREATE TEMP VIEW original_source_encounters AS SELECT e.* FROM source_encounter e "
                       "SEMI JOIN original_acute_keys k USING(patient_id,encounter_id)")
    missing = connection.execute("SELECT count(*) FROM original_acute_keys k ANTI JOIN "
                                 "original_source_encounters e USING(patient_id,encounter_id)").fetchone()[0]
    unsupported = connection.execute("SELECT count(*) FROM original_acute_keys k WHERE NOT EXISTS "
        "(SELECT 1 FROM original_source_encounters e WHERE e.patient_id=k.patient_id "
        "AND e.encounter_id=k.encounter_id AND upper(trim(e.type))=k.encounter_type)").fetchone()[0]
    if missing or unsupported:
        raise PreparationError(f"Original encounter keys/setting evidence unsupported: {missing}/{unsupported}")
    audit.update(missing_original_source_keys=missing, unsupported_original_setting_keys=unsupported)
    return audit


def require_original_population(config, manifest):
    if (config.get("population_scope_id") != POPULATION_ID
            or manifest.get("population_scope_id") != POPULATION_ID
            or manifest.get("original_encounter_list", {}).get("variant") != "FULL_DATA"
            or manifest["original_encounter_list"].get("receipt_sha256")
            != config["encounter_bundle"]["expected_receipt_sha256"]):
        raise PreparationError("Mapping does not bind the authenticated original encounter population")
