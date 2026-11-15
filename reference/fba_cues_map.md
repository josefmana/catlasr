# Map recorded cue labels to canonical cue pairs

The experiment records the cues of each trial as one string, `cues`,
made by concatenating the cue labels in the order they were shown, left
to right. This function returns the table that turns that string into
the canonical pair `cue1`, `cue2`, plus `cues_reversed` variable, which
records whether the pair was shown in the reverse of its canonical
order.

## Usage

``` r
fba_cues_map(design = "three-stage-replication")
```

## Arguments

- design:

  Character(1). A recognised study design, as stored in
  `provenance(x)$design`.

## Value

A tibble with columns `label`, `cue1`, `cue2` and `cues_reversed`,
containing one row per single cue and two rows per cue pair, one for
each counterbalancing order.

## Details

The table is derived from the cue sets defined by the design in the
internal `.catlas_design_specs` list.

## The canonicalisation invariant

`cue1` and `cue2` are always in the canonical order the design defines,
whichever side of the screen each cue appeared on. `"DQ"` and `"QD"`
both resolve to `cue1 = "D", cue2 = "Q"`, with only `cues_reversed`
telling them apart. Any join on `c("cue1", "cue2")` therefore matches
both presentation orders. Single-cue trials have `cue2 = NA` and
`cues_reversed = NA`.

## Examples

``` r
fba_cues_map("three-stage-replication")
#> # A tibble: 56 × 4
#>    label cue1  cue2  cues_reversed
#>    <chr> <chr> <chr> <lgl>        
#>  1 A     A     NA    NA           
#>  2 C     C     NA    NA           
#>  3 E     E     NA    NA           
#>  4 G     G     NA    NA           
#>  5 I     I     NA    NA           
#>  6 L     L     NA    NA           
#>  7 O     O     NA    NA           
#>  8 R     R     NA    NA           
#>  9 AB    A     B     FALSE        
#> 10 BA    A     B     TRUE         
#> # ℹ 46 more rows
```
