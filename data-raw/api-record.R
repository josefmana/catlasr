# api-record.R
#
# Record the exported surface of {catlasr} at a release: every exported
# function and every registered S3 method, with its arguments and their
# defaults are written to `inst/api/v<version>.txt`.
#
# The pre-registration of `fba-allergy-online-02` names the functions of the
# preprocessing layer, so the record of `v0.0.1` is the reference against which
# later releases are compared. If earlier records exist, the script reports
# what changed since the latest one. Every such change needs an entry in
# `NEWS.md` stating whether it affects the registered analysis.

pkgload::load_all(export_all = FALSE, quiet = TRUE)

version <- as.character(utils::packageVersion("catlasr"))
if (length(unclass(package_version(version))[[1L]]) > 3L) {
  cli::cli_abort(c(
          "{.pkg catlasr} {version} is a development version.",
    "i" = "Set the release version in {.file DESCRIPTION} first."
  ))
}

ns <- asNamespace("catlasr")

# `name(arg, arg = default, ...)`, defaults deparsed on one line
signature <- function(name, fun) {
  args <- formals(fun)
  args <- vapply(names(args), \(a) {
    default <- paste(deparse(args[[a]], width.cutoff = 500L), collapse = " ")
    if (identical(default, "")) a else paste(a, "=", default)
  }, character(1L))
  sprintf("%s(%s)", name, paste(args, collapse = ", "))
}

exports <- sort(getNamespaceExports(ns))
exports <- exports[vapply(exports, \(e) is.function(get(e, envir = ns)), logical(1L))]

s3 <- getNamespaceInfo(ns, "S3methods")
s3 <- s3[order(s3[, 1L], s3[, 2L]), , drop = FALSE]
methods <- paste(s3[, 1L], s3[, 2L], sep = ".")

record <- c(
  sprintf("# {catlasr} %s: exported surface", version),
  "# Exported functions, then registered S3 methods, with their arguments and",
  "# defaults. Written by data-raw/api-record.R; do not edit by hand.",
  "",
  "## Functions",
  vapply(exports, \(e) signature(e, get(e, envir = ns)), character(1L)),
  "",
  "## S3 methods",
  vapply(methods, \(m) signature(m, get(m, envir = ns)), character(1L))
)

dir.create(file.path("inst", "api"), recursive = TRUE, showWarnings = FALSE)
path <- file.path("inst", "api", sprintf("v%s.txt", version))

# Compare with the latest earlier record, if any
esc <- \(x) gsub("}", "}}", gsub("{", "{{", x, fixed = TRUE), fixed = TRUE)

earlier <- list.files(
  file.path("inst", "api"),
  pattern = "^v.*[.]txt$"
)

versions <- package_version(sub("^v(.*)[.]txt$", "\\1", earlier))
earlier <- earlier[versions < package_version(version)]

if (length(earlier) > 0L) {
  versions <- package_version(sub("^v(.*)[.]txt$", "\\1", earlier))
  latest <- earlier[versions == max(versions)]
  old <- grep("^[^#]", readLines(file.path("inst", "api", latest)), value = TRUE)
  new <- grep("^[^#]", record, value = TRUE)
  removed <- setdiff(old, new)
  added <- setdiff(new, old)
  if (length(c(removed, added)) == 0L) {
    cli::cli_inform("Exported surface unchanged since {.file {latest}}.")
  } else {
    cli::cli_inform(c(
      "!" = "Exported surface changed since {.file {latest}}; record each change in {.file NEWS.md}.",
      setNames(paste("-", esc(removed)), rep(" ", length(removed))),
      setNames(paste("+", esc(added)), rep(" ", length(added)))
    ))
  }
}

writeLines(record, path)
cli::cli_alert_success(paste(
  "Wrote {length(exports)} function{?s} and {length(methods)} S3 method{?s}",
  "to {.path {path}}."
))
