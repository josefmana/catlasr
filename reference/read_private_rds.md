# Read a data bundle from the private folder

This function is a counterpart of
[`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md).
It reads an `.rds` file, typically a `catlas_rawdata` bundle saved by an
import vignette, from the private folder, so that analysis code never
spells out where personal data live.

## Usage

``` r
read_private_rds(file, dir = Sys.getenv("CATLAS_PRIVATE_DIR"))
```

## Arguments

- file:

  Character(1). Path of the file within the private folder. It is a file
  name, optionally preceded by subfolders separated by `/`, e.g.
  `"fba-allergy-online-02/naive.rds"`. Absolute paths and `..` are
  refused.

- dir:

  Character(1). The private folder. Defaults to the environment variable
  `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.

## Value

The R object stored in the file.

## Details

The private folder is checked in the same way as in
[`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md),
i.e., `dir` must be given, exist, and lie outside every git work tree. A
folder inside a repository is refused for writing as well as reading,
because personal data found there are one `git add` away from being
published and should thus be moved first.

A missing file yields an error that lists the `.rds` files the folder
(or study folder) really does contain.

## See also

[`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md)
