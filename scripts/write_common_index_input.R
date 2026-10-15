#!/usr/bin/env Rscript
# Private typed input only. No selection, fitting, or source acceptance.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || file.exists(args[2])) stop("Use private CSV and fresh RDS output paths.")
source("R/bmi_hypercapnia_triangulation.R")
header <- names(utils::read.csv(args[1], nrows = 0, check.names = FALSE))
expected <- c(triangulation_columns, triangulation_index_day_columns)
if (!setequal(header, triangulation_columns) && !setequal(header, expected)) stop("Unexpected prepared fields.")
character_fields <- c("patient_id", "encounter_id", "encounter_date", "encounter_type", "sex", "race_ethnicity", "location")
classes <- ifelse(header %in% character_fields, "character", "numeric")
data <- utils::read.csv(args[1], colClasses = classes, na.strings = "", check.names = FALSE)
raw_date <- data$encounter_date
data$encounter_date <- as.Date(raw_date, format = "%Y-%m-%d")
if (any(!is.na(raw_date) & (is.na(data$encounter_date) | format(data$encounter_date, "%Y-%m-%d") != raw_date))) stop("Invalid prepared date.")
invisible(validate_triangulation_input(data))
saveRDS(data, args[2])
Sys.chmod(args[2], mode = "0600")
cat("Typed private input written; no clinical models fitted.\n")
