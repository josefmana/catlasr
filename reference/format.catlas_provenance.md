# Format a `catlas_provenance` record

Format a `catlas_provenance` record

## Usage

``` r
# S3 method for class 'catlas_provenance'
format(
  x,
  exclusions = c("short", "long"),
  width = min(getOption("width", 80L), 80L),
  ...
)
```

## Arguments

- x:

  A `catlas_provenance` object.

- exclusions:

  Character(1). How to show the exclusion rules: `"short"` (default)
  lists each rule by name with its participant count, `"long"` adds the
  rule's description.

- width:

  Integer(1). Width at which notes and exclusion rules are wrapped.
  Defaults to the console width, at most 80 characters.

- ...:

  Currently unused.

## Value

A character vector, one element per line: the header fields, then any
notes, the exclusion rules in the order they were applied, and any
deferred exclusion rules, each with its participant count and, if
`exclusions = "long"`, its description wrapped at `width`.
