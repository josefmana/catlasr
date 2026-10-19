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

  if (!is.character(file) || length(file) != 1L || is.na(file) ||
      !nzchar(file) || basename(file) != file) {
    cli::cli_abort(c(
            "`file` must be a bare file name.",
      "x" = "Received {.val {file}}.",
      "i" = "Choose the folder with `dir`, not as a part of `file`."
    ))
  }

  if (!is.character(dir) || length(dir) != 1L || is.na(dir) || !nzchar(dir)) {
    cli::cli_abort(c(
            "No private folder given.",
      "i" = "Set {.envvar CATLAS_PRIVATE_DIR} in {.file .Renviron} to a folder outside every repository, then restart R.",
      "i" = "{.code usethis::edit_r_environ()} opens the file."
    ))
  }

  if (!dir.exists(dir)) {
    cli::cli_abort(c(
            "The private folder does not exist.",
      "x" = "{.path {dir}}"
    ))
  }

  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  repo <- .find_git_root(dir)
  if (!is.null(repo)) {
    cli::cli_abort(c(
            "Refusing to write personal data inside a git repository.",
      "x" = "{.path {dir}} lies inside {.path {repo}}.",
      "i" = "Point `dir`, or {.envvar CATLAS_PRIVATE_DIR}, to a folder outside every repository."
    ))
  }

  path <- file.path(dir, file)
  if (file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
            "The file already exists.",
      "x" = "{.path {path}}",
      "i" = "Write {.code overwrite = TRUE} to replace it."
    ))
  }

  utils::write.csv(x, path, row.names = FALSE)
  invisible(path)
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
