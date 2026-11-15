# Render a CATLAS stimulus using magick

Binds a text label to a source image, allowing control over layout and
typography.

## Usage

``` r
# S3 method for class 'catlas_stimulus'
render_stimulus(
  x,
  ...,
  width = 200,
  height = 200,
  font_size = 32,
  font_family = NULL,
  label_colour = "black",
  label_position = c("bottom", "top"),
  label_shift = c(0, 0),
  background = "#c1c1c1"
)
```

## Arguments

- x:

  A `catlas_stimulus` object.

- ...:

  Currently unused; reserved for future expansion.

- width, height:

  `numeric(1)`. Output dimensions in pixels.

- font_size:

  `numeric(1)`. Label font size in points.

- font_family:

  `character(1)` or `NULL`. Font family name (NULL = auto-detect by
  platform).

- label_colour:

  `character(1)`. Text colour.

- label_position:

  `character(1)`. Vertical label placement, `"bottom"` (default) or
  `"top"`. Partial matching supported.

- label_shift:

  `numeric(2)`. Horizontal and vertical offset of the label.

- background:

  `character(1)`. Background colour.

## Value

A magick-image object (i.e., S3 class from magick).

## Details

The label is vertically aligned to prevent overlap. When placed at the
bottom, the text baseline sits just above the canvas edge; when placed
at the top, the text top sits just below the canvas edge. Image scaling
preserves aspect ratio while fitting the available space.

## See also

Other stimuli:
[`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
[`print.catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/print.catlas_stimulus.md),
[`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md),
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

# Default: label below the image
img_bottom  <- render_stimulus(stim)

# Label above image
img_top <- render_stimulus(stim, label_position = "top")
} # }
```
