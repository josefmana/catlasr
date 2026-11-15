# Constructor for CATLAS stimulus object

Constructs a validated `catlas_stimulus` object representing a single
composited stimulus: a source image (e.g., a flask or a cartoon of
allergic reaction icon) paired with a text label.

## Usage

``` r
catlas_stimulus(label, image_path, type = c("cue", "outcome"), meta = list())
```

## Arguments

- label:

  `character(1)`. Text label paired with the image.

- image_path:

  `character(1)`. Path to the source image file (PNG, JPEG, or any
  format supported by magick). The file must exist at construction time.

- type:

  `character(1)`. Stimulus role in the experimental paradigm. One of
  `"cue"` or `"outcome"`. Partial matching supported.

- meta:

  `list`. Optional named list for additional metadata (e.g., trial
  assignment, counterbalancing codes). Not used by the rendering
  pipeline.

## Value

An object of class `"catlas_stimulus"` (a named list with fields
`label`, `image_path`, `type`, and `meta`)

## Details

`catlas_stimulus` stores only plain R scalars. No magick objects are
embedded, so the rendering backend used by
[`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md)
is fully swappable without modifying the class.

## See also

- [`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md)
  to produce the composited image

- [`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)
  to save the result to disk

Other stimuli:
[`print.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/print.catlas_stimulus.md),
[`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md),
[`render_stimulus.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.catlas_stimulus.md),
[`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)

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
} # }
```
