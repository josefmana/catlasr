# Print a CATLAS stimulus

Print a CATLAS stimulus

## Usage

``` r
# S3 method for class 'catlas_stimulus'
print(x, ...)
```

## Arguments

- x:

  A "catlas_stimulus" object.

- ...:

  Unused.

## Value

Invisibly returns `x`.

## See also

Other stimuli:
[`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
[`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md),
[`render_stimulus.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.catlas_stimulus.md),
[`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)

## Examples

``` r
if (FALSE) { # \dontrun{
stim <- catlas_stimulus("Xyline", "path/to/flask.jpg", "cue")
print(stim)
} # }
```
