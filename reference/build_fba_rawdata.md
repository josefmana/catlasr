# Build a forward-blocking-attention raw-data bundle

User-facing constructor for the `catlas_fba_rawdata` class. Takes the
three components produced by import plus the provenance of the pull,
constructs the object and validates it.

## Usage

``` r
build_fba_rawdata(meta, stimuli, trials, provenance)
```

## Arguments

- meta:

  Data frame. One row per participant.

- stimuli:

  Data frame. One row per participant, concrete-to-abstract stimulus
  mappings.

- trials:

  Data frame. One row per trial.

- provenance:

  A `catlas_provenance` object, from
  [`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md).

## Value

A validated object of class `c("catlas_fba_rawdata", "catlas_rawdata")`.

## See also

[`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md),
[`provenance()`](https://josefmana.github.io/catlasr/reference/provenance.md),
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
