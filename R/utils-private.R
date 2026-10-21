#' Write a table of personal data outside all repositories
#'
#' Some files exist for administration only, e-mail addresses for contacting
#' participants being the typical case, and must never sit next to the data
#' or inside a repository. `write_private_csv()` writes such a table to a
#' private folder and refuses whenever that folder lies inside a git work
#' tree, where one careless `git add` would publish it.
#'
#' @param x A data frame.
#' @param file Character(1). A file name, without any directory part.
#' @param dir Character(1). The private folder. Defaults to the environment
#'   variable `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.
#' @param overwrite Logical(1). Replace an existing file? Defaults to `FALSE`.
#'
#' @returns The path of the written file, invisibly.
#'
#' @details
#' A folder counts as inside a repository when it, or any folder above it,
#' contains a `.git` entry. Checking for the entry rather than calling `git`
#' works without git installed and also recognises worktrees and submodules,
#' whose `.git` is a file.
#'
#' @export
write_private_csv <- function(
    x,
    file,
    dir = Sys.getenv("CATLAS_PRIVATE_DIR"),
    overwrite = FALSE
) {
  if (!is.data.frame(x)) {
    cli::cli_abort("`x` must be a data frame.")
  }

  path <- .private_path(file, dir, overwrite)

  utils::write.csv(x, path, row.names = FALSE)
  invisible(path)
}


#' Write a data bundle with personal data outside all repositories
#'
#' A `catlas_rawdata` bundle can hold personal data, such as age and sex, and
#' must not be saved inside a repository. `write_private_rds()` saves any R
#' object as `.rds` to a private folder, with the same guards as
#' [write_private_csv()].
#'
#' @param x Any R object, typically a `catlas_rawdata` bundle.
#' @inheritParams write_private_csv
#'
#' @returns The path of the written file, invisibly.
#'
#' @inherit write_private_csv details
#'
#' @seealso [write_private_csv()]
#'
#' @export
write_private_rds <- function(
    x,
    file,
    dir = Sys.getenv("CATLAS_PRIVATE_DIR"),
    overwrite = FALSE
) {
  path <- .private_path(file, dir, overwrite)
  saveRDS(x, path)
  invisible(path)
}


#' Resolve and guard a path in the private folder
#'
#' Checks that `file` is a bare file name, that `dir` is provided, exists and
#' lies outside every git work tree, and that an existing file is replaced only
#' on request.
#'
#' @inheritParams write_private_csv
#' @param call Environment for error reporting.
#'
#' @returns The full path, as a character string.
#'
#' @noRd
.private_path <- function(file, dir, overwrite, call = rlang::caller_env()) {
  if (!is.character(file) || length(file) != 1L || is.na(file) ||
      !nzchar(file) || basename(file) != file) {
    cli::cli_abort(c(
            "`file` must be a bare file name.",
      "x" = "Received {.val {file}}.",
      "i" = "Choose the folder with `dir`, not as a part of `file`."
    ), call = call)
  }

  if (!is.character(dir) || length(dir) != 1L || is.na(dir) || !nzchar(dir)) {
    cli::cli_abort(c(
            "No private folder given.",
      "i" = "Set {.envvar CATLAS_PRIVATE_DIR} in {.file .Renviron} to a folder outside every repository, then restart R.",
      "i" = "{.code usethis::edit_r_environ()} opens the file."
    ), call = call)
  }

  if (!dir.exists(dir)) {
    cli::cli_abort(c(
            "The private folder does not exist.",
      "x" = "{.path {dir}}"
    ), call = call)
  }

  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  repo <- .find_git_root(dir)
  if (!is.null(repo)) {
    cli::cli_abort(c(
            "Refusing to write personal data inside a git repository.",
      "x" = "{.path {dir}} lies inside {.path {repo}}.",
      "i" = "Point `dir`, or {.envvar CATLAS_PRIVATE_DIR}, to a folder outside every repository."
    ), call = call)
  }

  path <- file.path(dir, file)
  if (file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
            "The file already exists.",
      "x" = "{.path {path}}",
      "i" = "Write {.code overwrite = TRUE} to replace it."
    ), call = call)
  }

  path
}


#' Find the git work tree a folder belongs to
#'
#' @param path Character(1). A normalised, existing folder.
#'
#' @returns The top folder of the enclosing work tree, or `NULL` if there is
#'   none.
#'
#' @noRd
.find_git_root <- function(path) {
  repeat {
    if (file.exists(file.path(path, ".git"))) {
      return(path)
    }
    parent <- dirname(path)
    if (identical(parent, path)) {
      return(NULL)
    }
    path <- parent
  }
}
