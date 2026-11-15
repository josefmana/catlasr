# Compute blocking indices per participant

Turns the per-trial blocking scores from
[`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md)
into two blocking indices per participant over the test blocks selected:
the confidence-weighted choice score of Beesley and Le Pelley (2011) and
the choice-proportion score of Paskewitz and Jones (2020). See details
for their definitions.

## Usage

``` r
index_blocking(scores, blocks = 1L, by_block = FALSE, silence = FALSE)
```

## Arguments

- scores:

  Per-trial blocking scores; the result from
  [`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md).

- blocks:

  Integer. Test blocks that enter the indices. Defaults to `1L`, the
  first test block. `NULL` selects every block present in `scores`.

- by_block:

  Logical(1). `FALSE` (default) pools the selected blocks into one row
  per participant; `TRUE` gives one row per participant and selected
  block, which allows following the indices across the test stage.

- silence:

  Logical(1). Suppress the message about the definitions and the data
  that entered. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant (and selected block, with
`by_block = TRUE`) and columns:

- `id`:

  Participant identifier.

- `blocks`:

  The selected blocks as a label, e.g. `"1"` or `"1-6"`; with
  `by_block = TRUE`, the block of the row.

- `first_block`, `last_block`, `n_blocks`:

  The selected blocks the participant has trials in.

- `n_trials`:

  Number of test trials in selected blocks.

- `n_timed_out`:

  Number of trials that ended without a response.

- `n_answered`:

  Number of trials with a response.

- `complete`:

  Logical `TRUE` iff every selected block is present and every trial in
  it answered.

- `p_blocking_consistent`:

  Proportion of answered trials consistent with blocking.

- `bi_confidence`:

  Confidence-weighted choice score: mean signed confidence over answered
  trials. `NA` in a design without confidence ratings.

- `bi_choice`:

  Choice-proportion score: sum over test pairs of the proportion of
  answers consistent with blocking, minus one half per pair. `NA` when a
  pair has no answered trial in the selected blocks.

Participants without any trial in the selected blocks keep a row, with
zero counts and `NA` indices.

## Details

### Confidence-weighted choice score (`bi_confidence`)

\$\$\mathbb{E}\[Conf \times (I\_{\\o_c\\} - I\_{\\o_b\\})\]\$\$

where \\o_c\\ is the Stage 3 outcome paired with the control cue,
\\o_b\\ outcome paired with the blocked cue, and `Conf` is the
confidence rating. The index is thus essentially the mean of
`signed_confidence`. Positive values indicate blocking. The confidence
scale bounds the index (-10 to 10 on the 1-to-10 scale of Beesley & Le
Pelley, 2011). On the first test block (`blocks = 1L`), it is the index
that Beesley and Le Pelley (2011) reported.

### Choice-proportion score (`bi_choice`)

Paskewitz and Jones (2020, Eq. 24) defined

\$\$\sum\_{p \in P_3} P(o_3 \| p) - \sum\_{p \in P_4} P(o_3 \| p)\$\$

where \\P_3\\ are the test pairs on which blocking predicts \\o_3\\ and
\\P_4\\ those on which it predicts \\o_4\\. In other words, \\P_3\\
contains those cue compounds, in which the putatively blocked cue was
associated with `o4` during Stage 3 (i.e., blocking-consistent response
on those trials is `o3`) and vice versa for \\P_4\\.

Since \\P(o_3\|p)\\ is the proportion of consistent answers on the pairs
of \\P_3\\ and one minus it on the pairs of \\P_4\\, and the two sets
are equally large, the index equals the sum over all pairs of the
proportion of consistent answers minus one half, which is what is
computed here. It ranges from -4 to 4 with eight pairs; positive values
indicating blocking. Every pair weighs the same, however many of its
trials were answered.

### Dropped trials

Timed-out trials have no response and do not enter either index; they
are counted in `n_timed_out`. Both indices therefore average over the
answered trials only, and a participant with timed-out trials can have
more answers expecting one outcome than the other. `complete` marks the
participants without such an imbalance.

### Messages

Every call states the blocks that entered, the definitions and sign of
the indices, and the participants with timed-out trials or missing
blocks, unless silenced (`silence = TRUE`).

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on
overt attention and associability in human learning. *Journal of
Experimental Psychology: Animal Behavior Processes, 37*(1), 114-120.
[doi:10.1037/a0019526](https://doi.org/10.1037/a0019526)

Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. *Journal of
Mathematical Psychology, 97*, 102371.
[doi:10.1016/j.jmp.2020.102371](https://doi.org/10.1016/j.jmp.2020.102371)

## See also

[`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md),
[`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md),
[`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md)
