# Render a CATLAS stimulus

Generic function for rendering stimuli into image objects.

## Usage

``` r
render_stimulus(x, ...)
```

## Arguments

- x:

  A stimulus object.

- ...:

  Additional arguments passed to methods.

## Value

A rendered image object (backend-dependent).

## See also

Other stimuli:
[`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
[`print.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/print.catlas_stimulus.md),
[`render_stimulus.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.catlas_stimulus.md),
[`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)

## Examples

``` r
if (FALSE) { # \dontrun{
stim <- catlas_stimulus("Xyline", "path/to/flask.jpg", "cue")
img  <- render_stimulus(stim)
} # }
```
