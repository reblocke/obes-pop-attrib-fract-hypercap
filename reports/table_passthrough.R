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
