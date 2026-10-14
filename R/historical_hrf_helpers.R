# Focused repairs for the archived R track; no inputs are read on sourcing.
decode_historical_icd <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) x <- as.integer(x)
  if (is.character(x)) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
    if (any(!is.na(x) & !x %in% c("0", "1"))) stop("Unmapped historical ICD codes; require reviewed 0/1 labels.")
    x <- as.integer(x)
  }
  if (!is.numeric(x) || any(!is.na(x) & !x %in% c(0, 1))) stop("Historical ICD flags must be reviewed 0/1/NA.")
  as.integer(x)
}

historical_icd_union <- function(data) {
  values <- as.data.frame(lapply(data, decode_historical_icd))
  if (!ncol(values)) stop("ICD composite requires its defined components.")
  positive <- rowSums(values == 1, na.rm = TRUE) > 0
  all_negative <- rowSums(values == 0, na.rm = TRUE) == ncol(values)
  ifelse(positive, 1L, ifelse(all_negative, 0L, NA_integer_))
}

historical_hrf_status <- function(ventilation, lab_acidosis, has_gas_pair) {
  ifelse(ventilation %in% TRUE & lab_acidosis %in% TRUE, 1L,
    ifelse(has_gas_pair & (ventilation %in% FALSE | lab_acidosis %in% FALSE), 0L, NA_integer_))
}

historical_attrition_counts <- function(n_source, n_bmi, n_gas_pair, n_primary, n_strict, n_hypercapnia) {
  n <- c(n_source, n_bmi, n_gas_pair, n_primary, n_strict, n_hypercapnia)
  parent_n <- c(NA, n_source, n_bmi, n_gas_pair, n_gas_pair, n_gas_pair)
  if (any(n < 0) || any(n > parent_n, na.rm = TRUE)) stop("Historical cohort is not contained in its declared parent.")
  data.frame(
    cohort = c("Source dataset", "BMI recorded", "BMI + classifiable gas pair", "Primary HRF v1 cohort", "Strict sensitivity branch", "Hypercapnia branch"),
    parent = c("None", "Source dataset", "BMI recorded", rep("BMI + classifiable gas pair", 3)),
    n = n, parent_n = parent_n, n_excluded_from_parent = parent_n - n,
    pct_of_source = if (n_source) 100 * n / n_source else NA_real_, stringsAsFactors = FALSE
  )
}
