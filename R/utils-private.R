#' Write a table of personal data outside all repositories
#'
#' Some files exist for administration only, e-mail addresses for contacting
#' participants being the typical case, and must never sit next to the data
#' or inside a repository. `write_private_csv()` writes such a table to a
#' private folder and refuses whenever that folder lies inside a git work
#' tree, where one careless `git add` would publish it.
#'
#' @param x A data frame.
#' @param file Character(1). Path of the file within the private folder. It is
#'   a file name, optionally preceded by subfolders separated by `/`, e.g.
#'   `"fba-allergy-online-02/naive.rds"`. Absolute paths and `..` are refused.
#' @param dir Character(1). The private folder. Defaults to the environment
#'   variable `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.
#' @param overwrite Logical(1). Replace an existing file? Defaults to `FALSE`.
#'
#' @returns The path of the written file, invisibly.
#'
#' @details
#' ## Repositories
#'
#' A folder counts as inside a repository when it, or any folder above it,
#' contains a `.git` entry. Checking for the entry rather than calling `git`
#' works without git installed and also recognises worktrees and submodules,
#' whose `.git` is a file.
#'
#' ## Study folders
#'
#' Keep the files of each study in a subfolder of the private folder named by
#' its study identifier, e.g. `"fba-allergy-online-02/naive.rds"`. Missing
#' subfolders are created when writing. The folder to which the file is saved
#' must lie inside the private folder and outside every repository.
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
#' @seealso [write_private_csv()], [read_private_rds()]
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


#' Read a data bundle from the private folder
#'
#' This function is a counterpart of [write_private_rds()]. It reads an `.rds`
#' file, typically a `catlas_rawdata` bundle saved by an import vignette, from
#' the private folder, so that analysis code never spells out where personal
#' data live.
#'
#' @inheritParams write_private_csv
#'
#' @returns The R object stored in the file.
#'
#' @details
#' The private folder is checked in the same way as in [write_private_csv()],
#' i.e., `dir` must be given, exist, and lie outside every git work tree. A
#' folder inside a repository is refused for writing as well as reading, because
#' personal data found there are one `git add` away from being published and
#' should thus be moved first.
#'
#' A missing file yields an error that lists the `.rds` files the folder (or
#' study folder) really does contain.
#'
#' @seealso [write_private_rds()]
#'
#' @export
read_private_rds <- function(file, dir = Sys.getenv("CATLAS_PRIVATE_DIR")) {
  path <- .private_path(file, dir, read = TRUE)
  readRDS(path)
}


#' Resolve and guard a path in the private folder
#'
#' Checks that `file` is a relative path within the private folder, i.e., a
#' file name optionally preceded by subfolders, and that `dir` is provided,
#' exists and lies outside every git work tree. When writing, missing
#' subfolders are created and an existing file is replaced only on request;
#' when reading, the file must exist. In both cases, the folder containing the
#' file must still lie inside `dir`, and outside every git work tree, once
#' symbolic links are followed, so that a subfolder linking elsewhere cannot
#' lead personal data out of the private folder or into a repository. When
#' writing, this is checked before any missing subfolder is created.
#'
#' @inheritParams write_private_csv
#' @param read Logical(1). Should the function resolve the path for reading
#'   rather than writing?
#' @param call Environment for error reporting.
#'
#' @returns The full path, as a character string.
#'
#' @noRd
.private_path <- function(
    file,
    dir,
    overwrite = FALSE,
    read = FALSE,
    call = rlang::caller_env()
) {
  parts <- .private_file_parts(file, call = call)

  if (!rlang::is_string(dir) || !nzchar(dir)) {
    cli::cli_abort(c(
            "No private folder given.",
      "i" = paste(
        "Set {.envvar CATLAS_PRIVATE_DIR} in {.file .Renviron} to a folder",
        "outside every repository, then restart R."
      ),
      "i" = "Use {.code usethis::edit_r_environ()} to open the file."
    ), call = call)
  }

  if (!dir.exists(dir)) {
    cli::cli_abort(c(
            "The private folder does not exist.",
      "x" = "{.path {dir}}"
    ), call = call)
  }

  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  .refuse_git_folder(dir, read = read, call = call)

  path <- paste(c(dir, parts), collapse = "/")
  folder <- dirname(path)

  if (read) {
    if (!file.exists(path)) {
      present <- if (dir.exists(folder)) {
        list.files(folder, pattern = "[.]rds$")
      } else {
        character()
      }
      cli::cli_abort(c(
              "The file was not found in the private folder.",
        "x" = "{.path {path}}",
        "i" = if (!dir.exists(folder)) {
          "The folder {.path {folder}} does not exist."
        } else if (length(present) > 0L) {
          "{.file .rds} files in {.path {folder}}: {.file {present}}."
        } else {
          "The folder {.path {folder}} contains no {.file .rds} file."
        }
      ), call = call)
    }
  }

  # Follow symbolic links from the deepest folder that exists, before creating
  # any missing subfolder, so that nothing is created through a link either
  existing <- folder
  while (!dir.exists(existing)) {
    existing <- dirname(existing)
  }
  real <- normalizePath(existing, winslash = "/", mustWork = TRUE)
  if (!identical(real, dir) && !startsWith(real, paste0(dir, "/"))) {
    cli::cli_abort(c(
            "The file must stay inside the private folder.",
      "x" = paste(
        "{.path {existing}} is a symbolic link to {.path {real}}, or lies in",
        "one."
      ),
      "i" = paste(
        "Keep the study folders as ordinary folders inside the private folder,",
        "not as links to folders elsewhere."
      )
    ), call = call)
  }
  .refuse_git_folder(real, read = read, call = call)

  if (!read && !dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
  }

  if (!read && file.exists(path) && !isTRUE(overwrite)) {
    cli::cli_abort(c(
            "The file already exists.",
      "x" = "{.path {path}}",
      "i" = "Write {.code overwrite = TRUE} to replace it."
    ), call = call)
  }

  path
}


#' Split and check a path within the private folder
#'
#' @param file Object to check: a file name, optionally preceded by subfolders
#'   separated by `/`.
#' @param call Environment for error reporting.
#'
#' @returns Character. The components of `file`, e.g.
#'   `c("fba-allergy-online-02", "naive.rds")`.
#'
#' @noRd
.private_file_parts <- function(file, call = rlang::caller_env()) {
  valid <- rlang::is_string(file) && nzchar(file)

  parts <- if (valid) {
    strsplit(file, "/", fixed = TRUE)[[1L]]
  } else {
    character()
  }

  valid <- valid &&
    !startsWith(file, "/") &&
    !endsWith(file, "/") &&
    !startsWith(file, "~") &&
    !grepl("\\", file, fixed = TRUE) &&
    !grepl("^[A-Za-z]:", file) &&
    !any(parts %in% c("", ".", ".."))

  if (!valid) {
    cli::cli_abort(c(
      paste(
        "`file` must be a file name, optionally preceded by subfolders of the",
        "private folder."
      ),
      "x" = "Received {.val {file}}.",
      "i" = paste(
        "Separate subfolders with {.code /} and do not use {.code ..},",
        "e.g. {.file fba-allergy-online-02/naive.rds} is a valid `file` input."
      ),
      "i" = "Choose the private folder itself with `dir`."
    ), call = call)
  }

  parts
}


#' Refuse a folder inside a git work tree
#'
#' @param folder Character(1). A normalised, existing folder.
#' @param read Logical(1). Whether the caller reads (`TRUE`) or writes.
#' @param call Environment for error reporting.
#'
#' @returns `folder` invisibly, if it lies outside every git work tree;
#'   otherwise an informative error.
#'
#' @noRd
.refuse_git_folder <- function(folder, read, call = rlang::caller_env()) {
  repo <- .find_git_root(folder)

  if (!is.null(repo)) {
    cli::cli_abort(c(
      if (read) {
        "Refusing to read personal data from inside a git repository."
      } else {
        "Refusing to write personal data inside a git repository."
      },
      "x" = "{.path {folder}} lies inside {.path {repo}}.",
      "i" = paste(
        "Point `dir`, or {.envvar CATLAS_PRIVATE_DIR}, to a folder outside",
        "every repository."
      )
    ), call = call)
  }

  invisible(folder)
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
