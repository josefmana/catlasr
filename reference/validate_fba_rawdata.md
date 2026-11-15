# Validate a forward-blocking-attention raw-data bundle

Runs every check that
[`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md)
runs when it builds a bundle, so that a bundle can be validated again,
e.g. after it was read from disk, after exclusions were recorded or
before any analysis.

## Usage

``` r
validate_fba_rawdata(x, silence = FALSE)
```

## Arguments

- x:

  A `catlas_fba_rawdata` object, from
  [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md).

- silence:

  Logical(1). Suppress the message confirming that the bundle passed.
  Defaults to `FALSE` (recommended).

## Value

`x` invisibly if no check aborts, otherwise an informative error.

## Details

### Checks shared by every `catlas_rawdata` bundle

The provenance record, the three components (`meta`, `stimuli`,
`trials`) and their required columns, identifiers aligned across the
components, no participant-identifying columns such as e-mail addresses,
platform metadata, batches aligned with the provenance, participant
metadata, response times and the uniqueness of stimulus mappings.

### Checks of the forward-blocking-attention design

- The study belongs to the `fba` family and every stage of the design is
  present (abort).

- Trial counts lie within the bounds derived from the provenance (warn).

- Every participant saw every cue and used every outcome option (warn).

- Compound cues are counterbalanced left and right (abort for complete
  runs of a design whose stages all have an even number of blocks, warn
  otherwise).

- Test trials present only the test pairs of the design, and
  `is_correct` agrees with the blocking expectations recorded in the
  design registry (abort).

- Confidence ratings lie on the scale of the design (abort), and every
  answered test trial carries one (warn).

Warnings do not stop the validation, so read them. The message
confirming that the bundle passed refers to the checks that abort only.

## See also

[`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md),
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
