# Write a table of personal data outside all repositories

Some files exist for administration only, e-mail addresses for
contacting participants being the typical case, and must never sit next
to the data or inside a repository. `write_private_csv()` writes such a
table to a private folder and refuses whenever that folder lies inside a
git work tree, where one careless `git add` would publish it.

## Usage

``` r
write_private_csv(
  x,
  file,
  dir = Sys.getenv("CATLAS_PRIVATE_DIR"),
  overwrite = FALSE
)
```

## Arguments

- x:

  A data frame.

- file:

  Character(1). Path of the file within the private folder. It is a file
  name, optionally preceded by subfolders separated by `/`, e.g.
  `"fba-allergy-online-02/naive.rds"`. Absolute paths and `..` are
  refused.

- dir:

  Character(1). The private folder. Defaults to the environment variable
  `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.

- overwrite:

  Logical(1). Replace an existing file? Defaults to `FALSE`.

## Value

The path of the written file, invisibly.

## Details

### Repositories

A folder counts as inside a repository when it, or any folder above it,
contains a `.git` entry. Checking for the entry rather than calling
`git` works without git installed and also recognises worktrees and
submodules, whose `.git` is a file.

### Study folders

Keep the files of each study in a subfolder of the private folder named
by its study identifier, e.g. `"fba-allergy-online-02/naive.rds"`.
Missing subfolders are created when writing. The folder to which the
file is saved must lie inside the private folder and outside every
repository.
