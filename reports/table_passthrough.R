# Add optional line breaks without changing text, numbers or TeX commands.
bmi_softwrap_table_line <- function(line) {
  line <- gsub("([0-9.]+)([eE][+-]?[0-9]+)", "\\1\\\\allowbreak{}\\2", line, perl = TRUE)
  tokens <- gregexpr("\\\\[A-Za-z]+|[A-Za-z0-9]{9,}", line, perl = TRUE)
  regmatches(line, tokens) <- lapply(regmatches(line, tokens), function(values)
    vapply(values, function(value) {
      if (startsWith(value, "\\")) return(value)
      starts <- seq(1, nchar(value), by = 7)
      paste(substring(value, starts, pmin(starts + 6, nchar(value))), collapse = "\\allowbreak{}")
    }, character(1)))
  line
}

# Preserve complete generated tables as opaque Pandoc raw blocks. Parsing millions
# of already-escaped table cells as Markdown is slow and can alter their contents.
bmi_raw_table_writer <- function(writer) {
  force(writer)
  function(...) {
    lines <- capture.output(writer(...))
    kind <- ""
    for (line in lines) {
      if (!nzchar(kind)) {
        if (grepl("^\\\\begingroup", line)) kind <- "latex"
        if (grepl("^[[:space:]]*<table[ >]", line)) kind <- "html"
        if (nzchar(kind)) cat("\n```{=", kind, "}\n", sep = "")
      }
      if (kind == "latex" && grepl("&", line, fixed = TRUE)) line <- bmi_softwrap_table_line(line)
      cat(line, "\n", sep = "")
      if ((kind == "latex" && grepl("^\\\\endgroup", line)) ||
          (kind == "html" && grepl("^[[:space:]]*</table>", line))) {
        cat("```\n\n")
        kind <- ""
      }
    }
    if (nzchar(kind)) stop("Unclosed generated raw table block")
    invisible(NULL)
  }
}
