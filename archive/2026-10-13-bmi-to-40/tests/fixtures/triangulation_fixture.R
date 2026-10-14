# ARTIFICIAL DATA ONLY. No source dataset, real identifier, or clinical result is
# used here. This fixture is for executable checks and report-layout review.
make_triangulation_fixture <- function(n_patients = 1200L, seed = 20261012L) {
  stopifnot(length(n_patients) == 1L, is.finite(n_patients),
            n_patients >= 1L, n_patients == as.integer(n_patients))
  set.seed(seed)
  n_patients <- as.integer(n_patients)
  n <- 2L * n_patients
  patient <- rep(seq_len(n_patients), each = 2L)
  visit <- rep(1:2, n_patients)
  first_date <- as.Date("2022-01-01") + sample(0:230, n_patients, replace = TRUE)
  age <- runif(n_patients, 18, 88)
  bmi <- pmin(65, pmax(20, rnorm(n_patients, 38, 8)))
  sex <- sample(c("Female", "Male"), n_patients, replace = TRUE)
  race <- sample(c("Race group A", "Race group B", "Race group C"),
                 n_patients, replace = TRUE, prob = c(.45, .35, .20))
  draw_type <- sample(c("ABG", "VBG", "Both", "Neither"), n,
                      replace = TRUE, prob = c(.30, .30, .25, .15))
  result <- data.frame(
    patient_id = sprintf("ARTIFICIAL-P%05d", patient),
    encounter_id = sprintf("ARTIFICIAL-E%05d-%d", patient, visit),
    encounter_date = first_date[patient] + (visit - 1L) * sample(15:90, n, replace = TRUE),
    age_at_encounter = age[patient],
    encounter_type = sample(c("EMER", "IMP"), n, replace = TRUE),
    bmi = bmi[patient] + (visit - 1L) * rnorm(n, 0, 1.5),
    sex = sex[patient], race_ethnicity = race[patient],
    location = sample(c("ED", "Inpatient"), n, replace = TRUE),
    has_abg = as.integer(draw_type %in% c("ABG", "Both")),
    has_vbg = as.integer(draw_type %in% c("VBG", "Both")),
    stringsAsFactors = FALSE
  )
  latent_co2 <- 44 + .30 * (result$bmi - 40) +
    .035 * (result$age_at_encounter - 55) + rnorm(n, 0, 7)
  result$abg_pco2 <- ifelse(result$has_abg == 1L & runif(n) > .08,
                           pmax(15, latent_co2 + rnorm(n, 0, 2)), NA_real_)
  result$vbg_pco2 <- ifelse(result$has_vbg == 1L & runif(n) > .08,
                           pmax(15, latent_co2 + 4 + rnorm(n, 0, 3)), NA_real_)
  probability <- stats::plogis(-.6 + .045 * (result$bmi - 40) +
    .012 * (result$age_at_encounter - 55) + .20 * (result$sex == "Male"))
  result$icd_hypercapnia <- stats::rbinom(n, 1L, probability)
  result$bmi[runif(n) < .025] <- NA_real_
  result$sex[runif(n) < .008] <- NA_character_
  result$icd_hypercapnia[runif(n) < .025] <- NA_integer_
  attr(result, "data_status") <- "ARTIFICIAL FIXTURE - NOT CLINICAL RESULTS"
  result
}
