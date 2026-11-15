# Write a rendered stimulus to disk

A thin wrapper of
[`magick::image_write()`](https://docs.ropensci.org/magick/reference/editing.html)
function.

## Usage

``` r
write_stimulus(image, path, ...)
```

## Arguments

- image:

  A magick image object.

- path:

  Output file path.

- ...:

  Additional parameters passed to
  [`magick::image_write()`](https://docs.ropensci.org/magick/reference/editing.html).

## Value

Invisibly returns `path`.

## See also

Other stimuli:
[`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
[`print.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/print.catlas_stimulus.md),
[`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md),
[`render_stimulus.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.catlas_stimulus.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# A minimal white PNG to satisfy the file-existence check
tmp <- tempfile(fileext = ".png")
magick::image_write(magick::image_blank(1L, 1L, "white"), tmp)

stim <- catlas_stimulus(
  label      = "Xyline",
  image_path = tmp,
  type       = "cue"
)
print(stim)
write_stimulus(img, "output.png")
} # }
```
