# Authenticated source and deterministic selection primitives. No historical analysis is dispatched.
# Extracted from the current source contract; scientific estimation lives in bmi_models.R.

triangulation_columns <- c(
  "patient_id", "encounter_id", "encounter_date", "age_at_encounter",
  "encounter_type", "bmi", "sex", "race_ethnicity", "location",
  "has_abg", "has_vbg", "abg_pco2", "vbg_pco2", "icd_hypercapnia"
)

triangulation_adjustment <- c("bmi", "age_at_encounter", "sex", "race_ethnicity", "location")

triangulation_index_day_columns <- c(
  "abg_pco2_index_day", "vbg_pco2_index_day",
  "abg_index_day_available", "vbg_index_day_available"
)

tri_encounter_key <- function(data) paste(nchar(data$patient_id), data$patient_id, data$encounter_id, sep = ":")

shift_bmi_above30 <- function(bmi) ifelse(bmi > 30, bmi - 1, bmi)

require_tri_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Missing packages (not installed automatically): ", paste(missing, collapse = ", "))
}

validate_triangulation_input <- function(data) {
  if (!is.data.frame(data)) stop("Input must be a data frame.")
  missing <- setdiff(triangulation_columns, names(data))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))
  day_present <- triangulation_index_day_columns %in% names(data)
  if (any(day_present) && !all(day_present)) stop("Incomplete index-calendar-day columns.")
  day <- if (all(day_present)) data[c("patient_id", "encounter_id", triangulation_index_day_columns)] else NULL
  original_metadata_keys <- data[c("patient_id", "encounter_id")]
  metadata <- data[intersect(bmi_metadata_fields, names(data))]
  bmi_state <- data$bmi_evidence_state
  data <- as.data.frame(data[triangulation_columns])
  if (!is.null(bmi_state)) {
    if (!is.character(bmi_state) || anyNA(bmi_state) ||
        any(!bmi_state %in% c("valid", "missing", "unresolved")) ||
        any((bmi_state == "valid") != !is.na(data$bmi))) stop("BMI evidence state contradicts its value or policy.")
    data$bmi_evidence_state <- bmi_state
  }
  for (name in c("patient_id", "encounter_id")) {
    if (!is.character(data[[name]]) || anyNA(data[[name]]) || any(!nzchar(trimws(data[[name]])))) {
      stop(name, " must contain verified, nonmissing character keys; no row-number fallback.")
    }
  }
  if (!inherits(data$encounter_date, "Date")) stop("encounter_date must be Date, with a reviewed source origin.")
  for (name in c("age_at_encounter", "bmi", "abg_pco2", "vbg_pco2")) {
    x <- data[[name]]
    if (!is.numeric(x) || is.factor(x) || any(!is.finite(x) & !is.na(x))) stop(name, " must be finite numeric or NA.")
  }
  for (name in c("bmi", "abg_pco2", "vbg_pco2")) {
    if (any(data[[name]] <= 0, na.rm = TRUE)) stop(name, " has nonpositive values; review units/source rather than exclude silently.")
  }
  for (name in c("has_abg", "has_vbg", "icd_hypercapnia")) {
    x <- data[[name]]
    if (!(is.numeric(x) || is.logical(x)) || is.factor(x) || any(!is.na(x) & !x %in% c(0, 1))) {
      stop(name, " must be explicitly mapped to 0/1/NA; factor level numbers are not codes.")
    }
  }
  for (name in c("encounter_type", "sex", "race_ethnicity", "location")) {
    if (!(is.character(data[[name]]) || is.factor(data[[name]]))) stop(name, " must have reviewed character/factor categories.")
    data[[name]] <- as.character(data[[name]])
    data[[name]][!is.na(data[[name]]) & !nzchar(trimws(data[[name]]))] <- NA_character_
  }
  for (gas in c("abg", "vbg")) {
    available <- !is.na(data[[paste0(gas, "_pco2")]])
    if (any(available & !(data[[paste0("has_", gas)]] %in% 1))) {
      stop(gas, " result exists without a confirmed draw flag; resolve the source mapping.")
    }
    if (!is.null(day)) {
      value <- day[[paste0(gas, "_pco2_index_day")]]
      availability <- day[[paste0(gas, "_index_day_available")]]
      if (!is.numeric(value) || is.factor(value) || any(!is.na(value) & (!is.finite(value) | value <= 0))) {
        stop(gas, " index-day result must be positive finite numeric or NA.")
      }
      if (!(is.numeric(availability) || is.logical(availability)) || is.factor(availability) ||
          any(!is.na(availability) & !availability %in% c(0, 1))) stop("Index-day availability must be 0/1/NA.")
      if (any((availability %in% 1) != !is.na(value))) stop("Index-day availability and maximum disagree.")
      if (any(!is.na(value) & (!available | !(data[[paste0("has_", gas)]] %in% 1)))) {
        stop("Index-day gas requires an encounter result and confirmed draw.")
      }
      if (any(value > data[[paste0(gas, "_pco2")]] + 1e-8, na.rm = TRUE)) stop("Index-day maximum exceeds encounter maximum.")
    }
  }
  n_input <- nrow(data)
  data <- unique(data)
  keys <- data[c("patient_id", "encounter_id")]
  data$.key_conflict <- duplicated(keys) | duplicated(keys, fromLast = TRUE)
  # Deduplication/index ambiguity use primary fields only. Discordant early
  # evidence cannot alter a primary index or promote another encounter.
  data$.index_day_conflict <- rep(FALSE, nrow(data))
  if (!is.null(day)) {
    day <- unique(day)
    day_keys <- tri_encounter_key(day)
    conflict <- duplicated(day_keys) | duplicated(day_keys, fromLast = TRUE)
    position <- match(tri_encounter_key(data), day_keys)
    data$.index_day_conflict <- day_keys[position] %in% day_keys[conflict]
    for (name in triangulation_index_day_columns) {
      data[[name]] <- day[[name]][position]
      data[[name]][data$.index_day_conflict] <- NA
    }
  } else {
    for (name in triangulation_index_day_columns) data[[name]] <- rep(NA_real_, nrow(data))
  }
  # Metadata conflicts cannot create a clinical-key conflict or change index selection.
  if (ncol(metadata)) {
    metadata_keys <- tri_encounter_key(original_metadata_keys)
    for (name in names(metadata)) {
      data[[name]] <- metadata[[name]][match(tri_encounter_key(data), metadata_keys)]
      for (key in unique(metadata_keys[duplicated(metadata_keys)])) {
        values <- unique(metadata[[name]][metadata_keys == key])
        if (length(values) > 1L) data[[name]][tri_encounter_key(data) == key] <- NA
      }
    }
  }
  attr(data, "exact_duplicates_removed") <- n_input - nrow(data)
  attr(data, "n_conflicting_keys") <- nrow(unique(keys[data$.key_conflict, , drop = FALSE]))
  attr(data, "index_day_source_status") <- if (is.null(day)) "pending" else "qualified"
  data
}

derive_triangulation_variables <- function(data) {
  setting <- ifelse(is.na(data$encounter_type), NA, data$encounter_type %in% c("EMER", "IMP"))
  data$in_scope <- data$age_at_encounter >= 18 & setting &
    data$encounter_date >= as.Date("2022-01-01") & data$encounter_date < as.Date("2023-01-01")
  data$severe_obesity <- data$bmi >= 40
  data$abg_drawn <- data$has_abg == 1
  data$any_gas_drawn <- data$has_abg == 1 | data$has_vbg == 1
  data$icd <- data$icd_hypercapnia
  data$abg <- ifelse(is.na(data$abg_pco2), NA_integer_, as.integer(data$abg_pco2 >= 45))
  has_result <- !is.na(data$abg_pco2) | !is.na(data$vbg_pco2)
  positive <- data$abg_pco2 >= 45 | data$vbg_pco2 >= 50
  data$any_gas <- ifelse(positive %in% TRUE, 1L, ifelse(has_result, 0L, NA_integer_))
  data$abg_index_calendar_day <- ifelse(is.na(data$abg_pco2_index_day), NA_integer_, as.integer(data$abg_pco2_index_day >= 45))
  day_result <- !is.na(data$abg_pco2_index_day) | !is.na(data$vbg_pco2_index_day)
  day_positive <- data$abg_pco2_index_day >= 45 | data$vbg_pco2_index_day >= 50
  data$any_gas_index_calendar_day <- ifelse(day_positive %in% TRUE, 1L, ifelse(day_result, 0L, NA_integer_))
  data
}

select_frame_indexes <- function(data, frame) {
  eligible <- data$in_scope & data[[frame]]
  # Conflicting versions may establish membership by consensus, but never
  # supply a resolved index. Disagreement/unknown eligibility remains unknown.
  conflict_rows <- which(data$.key_conflict)
  key <- paste(nchar(data$patient_id), data$patient_id, data$encounter_id, sep = ":")
  for (rows in split(conflict_rows, key[conflict_rows])) {
    states <- eligible[rows]
    eligible[rows] <- if (all(states %in% TRUE)) TRUE else if (all(states %in% FALSE)) FALSE else NA
  }
  confirmed <- data[eligible %in% TRUE, , drop = FALSE]
  possible <- data[is.na(eligible), , drop = FALSE]
  groups <- split(seq_len(nrow(confirmed)), confirmed$patient_id)
  possible_groups <- split(possible$encounter_date, possible$patient_id)
  patient_ids <- names(groups)
  possible_positions <- match(patient_ids, names(possible_groups))
  audits <- lapply(seq_along(groups), function(group_index) {
    id <- patient_ids[group_index]
    rows <- groups[[group_index]]
    first_date <- min(confirmed$encounter_date[rows])
    earliest <- rows[confirmed$encounter_date[rows] == first_date]
    possible_index <- possible_positions[group_index]
    uncertain_dates <- if (is.na(possible_index)) NULL else possible_groups[[possible_index]]
    earlier_uncertainty <- length(uncertain_dates) && any(is.na(uncertain_dates) | uncertain_dates <= first_date)
    status <- if (earlier_uncertainty) "uncertain_earlier_membership" else if (any(confirmed$.key_conflict[earliest])) "conflicting_index_evidence" else if (length(earliest) > 1L) "earliest_date_tie" else "resolved"
    data.frame(patient_id = id, frame = frame, index_date = first_date, status = status,
               selected_row = if (status == "resolved") earliest else NA_integer_)
  })
  # Index audits contain identifiers: keep in memory, never export from the report.
  audit <- if (length(audits)) do.call(rbind, audits) else data.frame(
    patient_id = character(), frame = character(), index_date = as.Date(character()), status = character(), selected_row = integer())
  selected <- audit$selected_row[!is.na(audit$selected_row)]
  indexes <- confirmed[selected, , drop = FALSE]
  rownames(indexes) <- NULL
  counts <- data.frame(
    frame = frame, n_frame_patients = length(groups), n_index_resolved = nrow(indexes),
    n_index_unresolved = sum(audit$status != "resolved"),
    n_membership_uncertain = length(setdiff(unique(possible$patient_id), names(groups))),
    n_earliest_ties = sum(audit$status == "earliest_date_tie"),
    n_earlier_uncertainty = sum(audit$status == "uncertain_earlier_membership"),
    n_conflicting_indexes = sum(audit$status == "conflicting_index_evidence")
  )
  list(indexes = indexes, audit = audit, counts = counts)
}

detect_tri_separation <- function(x, y) {
  # A separating direction has signed X*b >= 0, with at least one strict
  # inequality. An L1 bound makes the linear program finite; split b into
  # nonnegative positive/negative parts. This detects complete AND quasi separation.
  require_tri_packages("lpSolve")
  scale <- apply(abs(x), 2L, max)
  scale[scale == 0] <- 1
  z <- sweep(x, 2L, scale, "/") * (2 * y - 1)
  z <- unique(z)
  a <- cbind(z, -z)
  solution <- lpSolve::lp("max", colSums(a), rbind(a, rep(1, ncol(a))),
                          c(rep(">=", nrow(a)), "<="), c(rep(0, nrow(a)), 1))
  if (solution$status != 0) stop("Separation diagnostic could not be solved.")
  solution$objval > 1e-7
}

load_triangulation_input <- function(input_path, manifest_path, schema_version = 2L, study_design = NULL) {
  require_tri_packages(c("jsonlite", "digest", "haven"))
  if (!nzchar(input_path) || !nzchar(manifest_path)) stop("Clinical mode requires explicit input and reviewed manifest paths.")
  if (!file.exists(input_path) || !file.exists(manifest_path)) stop("Input or manifest does not exist.")
  manifest_hash <- digest::digest(file = manifest_path, algo = "sha256")
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
  required <- c("schema_version", "input_sha256", "source_identity", "reviewed_by", "reviewed_on", "evidence_reference", "columns", "binary_codes", "encounter_type_codes", "category_values", "semantics", "source_qualification", "source_evidence_files", "index_day")
  if (length(setdiff(required, names(manifest))) || !identical(manifest$schema_version, schema_version)) stop("Invalid manifest schema; estimation requires version ", schema_version, ".")
  if (schema_version %in% c(3L, 4L) && (!identical(manifest$study_design, study_design) ||
      !identical(manifest$population_policy, "first_2022_adult_ED_inpatient_BMI_ge30_before_gas_and_completeness"))) {
    stop("Manifest does not qualify the common-index BMI >=30 study population.")
  }
  for (name in c("source_identity", "reviewed_by", "reviewed_on", "evidence_reference")) {
    if (!is.character(manifest[[name]]) || length(manifest[[name]]) != 1 || !nzchar(trimws(manifest[[name]])) || grepl("pending", manifest[[name]], ignore.case = TRUE)) stop("Manifest review metadata incomplete: ", name)
  }
  expected <- c(
    keys = "original_patient_and_encounter", date = "encounter_start_Date",
    bmi = "legacy_derived_kg_m2", gases = "selected_encounter_max_valid_PCO2_mmHg_specimen_verified",
    draws = "selected_encounter_draw_not_result", icd = "J96.02|J96.12|J96.22|J96.92|E66.2",
    icd_negative = "documented_composite_absent_with_capture", adjustment = "legacy_stata_codes_and_missingness"
  )
  for (name in names(expected)) if (!identical(manifest$semantics[[name]], unname(expected[[name]]))) stop("Unreviewed semantics: ", name)
  gates <- c("lineage", "population_scope", "keys_chronology", "bmi_adjustment", "gas_draws", "gas_units_windows", "icd_capture")
  if (!setequal(names(manifest$source_qualification), gates) ||
      !all(vapply(gates, function(name) identical(manifest$source_qualification[[name]], "accepted"), logical(1)))) {
    stop("Primary source qualification incomplete; authenticate the specific unresolved requirement.")
  }
  evidence <- manifest$source_evidence_files
  if (!all(c("lineage", "population", "fields") %in% names(evidence))) stop("Missing identity-bound source evidence files.")
  for (name in names(evidence)) {
    entry <- evidence[[name]]
    if (!is.character(entry$path) || length(entry$path) != 1L || grepl("PENDING", entry$path, fixed = TRUE) ||
        !is.character(entry$sha256) || length(entry$sha256) != 1L || !grepl("^[a-fA-F0-9]{64}$", entry$sha256)) stop("Invalid source evidence reference: ", name)
    path <- entry$path
    if (!grepl("^(/|[A-Za-z]:)", path)) path <- file.path(dirname(manifest_path), path)
    if (!file.exists(path) || !identical(digest::digest(file = path, algo = "sha256"), tolower(entry$sha256))) stop("Source evidence file hash mismatch: ", name)
  }
  day_status <- manifest$index_day$status
  if (length(day_status) != 1L || !day_status %in% c("pending", "qualified")) stop("Index-day source status must be pending or qualified.")
  if (day_status == "qualified" && (!"index_day" %in% names(evidence) ||
      !identical(manifest$index_day$semantics, "max_valid_specimen_PCO2_on_encounter_start_calendar_date"))) stop("Unreviewed index-calendar-day evidence.")
  if (day_status == "pending" && length(manifest$index_day$columns)) stop("Pending index-day source cannot supply mapped columns.")
  hash <- digest::digest(file = input_path, algo = "sha256")
  if (!identical(hash, tolower(manifest$input_sha256))) stop("Input SHA-256 does not match the reviewed manifest.")
  ext <- tolower(tools::file_ext(input_path))
  raw <- switch(ext, rds = readRDS(input_path), dta = haven::read_dta(input_path), stop("Only explicitly supplied RDS or DTA inputs are supported."))
  mapping <- unlist(manifest$columns, use.names = TRUE)
  if (!setequal(names(mapping), triangulation_columns) || anyDuplicated(mapping) || !all(mapping %in% names(raw))) stop("Incomplete, duplicate, or unavailable source column mapping.")
  data <- as.data.frame(raw[unname(mapping[triangulation_columns])])
  names(data) <- triangulation_columns
  if (schema_version == 4L) {
    if (!identical(manifest$rfs_policy_id, "historical_source_membership_v1") ||
        !"rfs" %in% names(evidence)) stop("Missing authenticated RFS metadata evidence")
    mapped_metadata <- unlist(manifest$metadata_columns, use.names = TRUE)
    if (!all(bmi_rfs_fields %in% names(mapped_metadata)) || anyDuplicated(mapped_metadata) ||
        !all(names(mapped_metadata) %in% bmi_metadata_fields) || !all(mapped_metadata %in% names(raw))) stop("Invalid metadata mapping")
    for (name in names(mapped_metadata)) data[[name]] <- raw[[mapped_metadata[[name]]]]
    bmi_validate_metadata(data)
  }
  if (!is.null(manifest$bmi_policy_id)) {
    if (!identical(manifest$bmi_policy_id, "available_encounter_or_prior_bmi_v1") ||
        !is.character(manifest$bmi_evidence_column) || length(manifest$bmi_evidence_column) != 1L ||
        !manifest$bmi_evidence_column %in% names(raw)) stop("Unreviewed available-BMI evidence mapping.")
    data$bmi_evidence_state <- as.character(raw[[manifest$bmi_evidence_column]])
  }
  if (day_status == "qualified") {
    day_mapping <- unlist(manifest$index_day$columns, use.names = TRUE)
    if (!setequal(names(day_mapping), triangulation_index_day_columns) || anyDuplicated(day_mapping) ||
        any(day_mapping %in% mapping) || !all(day_mapping %in% names(raw))) stop("Incomplete or duplicate index-day source mapping.")
    data[triangulation_index_day_columns] <- raw[unname(day_mapping[triangulation_index_day_columns])]
  }
  # Decode reviewed values explicitly, never factor-level integers.
  source_values <- function(x) if (inherits(x, "haven_labelled")) as.character(haven::zap_labels(x)) else as.character(x)
  decode <- function(x, codes, name) {
    x <- source_values(x)
    codes <- unlist(codes, use.names = TRUE)
    if (!length(codes) || anyDuplicated(names(codes)) || any(!is.na(x) & !x %in% names(codes))) stop("Unmapped source coding: ", name)
    unname(codes[x])
  }
  for (name in c("has_abg", "has_vbg", "icd_hypercapnia")) {
    codes <- unlist(manifest$binary_codes[[name]], use.names = TRUE)
    if (!length(codes) || any(!codes %in% c("0", "1", "NA"))) stop("Invalid binary mapping for ", name)
    x <- decode(data[[name]], codes, name)
    x[x %in% "NA"] <- NA_character_
    data[[name]] <- as.integer(x)
  }
  if (day_status == "qualified") for (name in c("abg_index_day_available", "vbg_index_day_available")) {
    codes <- unlist(manifest$index_day$binary_codes[[name]], use.names = TRUE)
    if (!length(codes) || any(!codes %in% c("0", "1", "NA"))) stop("Invalid index-day binary mapping.")
    x <- decode(data[[name]], codes, name)
    x[x %in% "NA"] <- NA_character_
    data[[name]] <- as.integer(x)
  }
  setting_codes <- unlist(manifest$encounter_type_codes, use.names = TRUE)
  if (!length(setting_codes) || any(!setting_codes %in% c("EMER", "IMP", "OTHER", "NA"))) stop("Invalid encounter_type_codes target; use EMER/IMP/OTHER/NA.")
  data$encounter_type <- decode(data$encounter_type, setting_codes, "encounter_type")
  data$encounter_type[data$encounter_type == "NA"] <- NA_character_
  for (name in c("sex", "race_ethnicity", "location")) {
    data[[name]] <- source_values(data[[name]])
    allowed <- manifest$category_values[[name]]
    if (!length(allowed) || any(!is.na(data[[name]]) & !data[[name]] %in% allowed)) stop("Unreviewed categories in ", name)
  }
  validate_triangulation_input(data)
  if (!identical(hash, digest::digest(file = input_path, algo = "sha256")) ||
      !identical(manifest_hash, digest::digest(file = manifest_path, algo = "sha256"))) stop("Input or manifest changed during loading.")
  # Preserve exact duplicates until the analysis records their removal count.
  list(data = data, manifest = manifest, input_sha256 = hash, manifest_sha256 = manifest_hash)
}

common_design_id <- "common_index_bmi_ge30_v1"
tri_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
tri_repo_root <- function() normalizePath(Sys.getenv("BMI_REPO_ROOT", unset = getwd()), mustWork = TRUE)

common_source_policy <- function() jsonlite::read_json(
  file.path(tri_repo_root(), "config", "common_index_source_policy.json"), simplifyVector = FALSE)

load_common_input <- function(input_path, manifest_path) {
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  policy <- common_source_policy()
  if (!identical(manifest$source_policy_id, policy$source_policy_id)) stop("New clinical input requires unadjusted_pco2_v1 source policy.")
  loaded <- load_triangulation_input(input_path, manifest_path, schema_version = if (identical(manifest$schema_version, 4L)) 4L else 3L, study_design = common_design_id)
  entry <- loaded$manifest$source_evidence_files$fields
  field_path <- entry$path
  if (!grepl("^(/|[A-Za-z]:)", field_path)) field_path <- file.path(dirname(manifest_path), field_path)
  fields <- jsonlite::read_json(field_path, simplifyVector = FALSE)
  if (!isTRUE(all.equal(fields$source_policy, policy, check.attributes = FALSE))) stop("Field evidence does not bind the exact unadjusted gas/ICD policy.")
  if (!is.null(loaded$manifest$bmi_policy_id)) {
    bmi_policy <- jsonlite::read_json(file.path(tri_repo_root(), "config", "common_index_bmi_policy.json"), simplifyVector = FALSE)
    if (!identical(loaded$manifest$bmi_policy_id, bmi_policy$id) ||
        !isTRUE(all.equal(fields$bmi_policy, bmi_policy, check.attributes = FALSE))) stop("Field evidence does not bind the exact available-BMI policy.")
    attr(loaded$data, "population_scope_id") <- loaded$manifest$population_scope_id
    if (!identical(loaded$manifest$population_scope_id, "original_selected_encounters_v1") ||
        !identical(fields$population_scope_id, loaded$manifest$population_scope_id) ||
        !identical(fields$original_encounter_list$variant, "FULL_DATA")) stop("New available-BMI input requires authenticated original encounter membership; broader mappings are superseded.")
  }
  if (isTRUE(loaded$manifest$index_preselected)) {
    selection_entry <- loaded$manifest$source_evidence_files$selection
    if (is.null(selection_entry) || is.null(loaded$manifest$bmi_policy_id)) stop("Missing prepared index evidence.")
    path <- selection_entry$path
    if (!grepl("^(/|[A-Za-z]:)", path)) path <- file.path(dirname(manifest_path), path)
    census <- jsonlite::read_json(path, simplifyVector = TRUE)
    if (!identical(census$bmi_policy_id, loaded$manifest$bmi_policy_id) ||
        !identical(census$population_scope_id, loaded$manifest$population_scope_id) ||
        census$counts$n_index_resolved != nrow(loaded$data) || census$clinical_models_fitted != 0L) stop("Invalid prepared index census.")
    attr(loaded$data, "source_selection") <- census
  }
  for (gas in c("abg", "vbg")) {
    bounds <- policy[[if (gas == "abg") "arterial_validity" else "venous_validity"]]
    names <- c(paste0(gas, "_pco2"), paste0(gas, "_pco2_index_day"))
    for (name in intersect(names, colnames(loaded$data))) {
      value <- loaded$data[[name]]
      if (any(value <= bounds$lower_exclusive | value >= bounds$upper_exclusive, na.rm = TRUE)) stop("Gas outside the bound source validity policy: ", name)
    }
  }
  if (!identical(tri_sha256(field_path), tolower(entry$sha256))) stop("Field evidence changed during loading.")
  allowed_audits <- list(gas_audit = c("unavailable_domain", "unavailable_field", "specimen_conflict", "unspecified_specimen",
    "temperature_adjusted_excluded", "unreviewed_code", "unusable_numeric", "unusable_units", "outside_validity_limits",
    "valid_unadjusted", "valid_value_unknown_collection_date", "temperature_adjusted_source_records",
    "encounters_with_temperature_adjusted_records", paste0(rep(c("abg", "vbg"), each = 3), "_", rep(c("below", "at", "above"), 2), "_threshold_records")),
    icd_audit = c("target_records", "unavailable_domain", "unavailable_field"),
    bmi_audit = c("valid", "missing", "unresolved"))
  loaded$source_audit <- list()
  for (name in names(allowed_audits)) {
    values <- fields[[name]]
    if (length(setdiff(names(values), allowed_audits[[name]]))) stop("Unexpected source audit fields.")
    for (value in values) if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value < 0 || value != round(value)) stop("Invalid aggregate source audit count.")
    loaded$source_audit[[name]] <- values
  }
  loaded
}
