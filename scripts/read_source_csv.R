# Source transport only: base R decimal scanning can change the last binary digit.
# Parse numeric tokens with the existing JSON reader, preserving float32-promoted
# BMI and threshold-adjacent gas values without rounding or adding tolerances.
read_source_csv <- function(path, classes) {
  data <- utils::read.csv(path, colClasses="character", na.strings="", check.names=FALSE)
  if(length(classes)!=ncol(data)||any(!classes %in% c("character","numeric")))stop("Invalid source column types")
  for(name in names(data)[classes=="numeric"]) {
    tokens<-data[[name]]
    if(any(!is.na(tokens) & !grepl("^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?$",tokens)))stop("Invalid numeric source token")
    tokens[is.na(tokens)]<-"null"
    data[[name]]<-as.numeric(jsonlite::fromJSON(paste0("[",paste(tokens,collapse=","),"]")))
  }
  data
}
