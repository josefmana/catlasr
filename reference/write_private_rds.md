# Write a data bundle with personal data outside all repositories

A `catlas_rawdata` bundle can hold personal data, such as age and sex,
and must not be saved inside a repository. `write_private_rds()` saves
any R object as `.rds` to a private folder, with the same guards as
[`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md).

## Usage

``` r
write_private_rds(
  x,
  file,
  dir = Sys.getenv("CATLAS_PRIVATE_DIR"),
  overwrite = FALSE
)
```

## Arguments

- x:

  Any R object, typically a `catlas_rawdata` bundle.

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

## See also

[`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md),
[`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md)
