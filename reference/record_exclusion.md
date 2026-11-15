# Drop participants and record why

This function is the one and only sanctioned way to exclude a
participant from a CATLAS raw-data bundle. It removes the identifiers
from all three components **and** appends the rule to
`provenance(x)$exclusions`, so the object can always answer who was
removed and why.

## Usage

``` r
record_exclusion(x, rule, description, ids)
```

## Arguments

- x:

  A `catlas_rawdata` object.

- rule:

  Character(1). Short machine-friendly rule name, e.g.
  `"incomplete_learning"`.

- description:

  Character(1). The rule in pre-registrable language.

- ids:

  Character. Identifiers to remove. May be empty, in which case the rule
  is still recorded.

## Value

`x` with the identifiers removed and the rule appended.

## Details

### Write `description` concrete

`description` is written in such a way that it can be pasted into a
pre-registration verbatim. Consequently, provide clear thresholds, not
vague adjectives. For instance, do not write
`"excluded for inattention"` but
`"fewere than 200 experiment trials recorded"`.

## See also

[`provenance()`](https://josefmana.github.io/catlasr/reference/provenance.md)
