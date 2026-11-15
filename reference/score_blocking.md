# Score the test stage for blocking

Records, for every test trial of every participant, whether the response
is consistent with blocking and the confidence rating signed
accordingly. The result is the per-trial table from which
[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
computes the blocking indices of each participant.

## Usage

``` r
score_blocking(x, silence = FALSE)
```

## Arguments

- x:

  A `catlas_rawdata` object.

- silence:

  Logical(1). Suppress the message summarising what was scored and how.
  Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant/test trial combination, i.e., per
participant, test block and test pair, and columns:

- `id`:

  Participant identifier.

- `block`:

  Test block.

- `cue1`, `cue2`:

  The test pair, in canonical order.

- `blocked`, `control`:

  The cue of the pair blocked in Stage 2 and its control cue.

- `expected`:

  The outcome blocking predicts: the Stage 3 outcome associated with the
  control as opposed to the blocked cue.

- `timed_out`:

  Whether the trial ended without a response.

- `response`:

  The chosen outcome, `NA` when timed out.

- `consistent`:

  `response == expected`, i.e., whether the response is consistent with
  blocking; `NA` when timed out.

- `confidence`:

  The confidence rating; `NA` when timed out, and throughout in a design
  that collects no confidence ratings.

- `signed_confidence`:

  `confidence` when `consistent`, `-confidence` otherwise; `NA` when
  either is missing.

## Details

### Consistency with blocking

Every test pair combines a cue blocked in Stage 2 with a control cue
that was paired with the other outcome in Stage 3. If participants
learned less about the blocked cues than about the control cues during
Stage 3, they ought to choose the Stage 3 outcome of the control cue
(Beesley & Le Pelley, 2011). The design registry records which outcome
was paired with the control and which with the blocked cue for every
test pair, and `consistent` is derived from it and the response.

The jsPsych column `is_correct` contains the same comparison as made by
the experiment build. The function aborts if any answered test trial
disagrees with the registry, or if a test trial presents a pair the
design does not list. An experiment build whose expectations differed
from the registry would otherwise flip the sign of the indices on the
pairs concerned. Data bundles built with the current version of
[`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md)
are checked when they are built as well.

### Blocking test

The function scores a *compound negation test* (Don & Livesey, 2018),
known in older literature as a *conflict test* (Gluck & Bower, 1988). In
it, every test trial presents two cues that were paired with different
outcomes during training, here a cue blocked in Stage 2 and a control
cue paired with the other outcome in Stage 3, and asks which outcome
follows the compound. The answer is a discrete choice among the outcomes
of the test, i.e., an N-alternative forced choice (N-AFC, with N the
number of outcomes), optionally followed by a confidence rating.

Currently, only the three-stage forward blocking designs with a context
change between Stages 2 and 3 record such test pairs in the design
registry. For any other design, the function aborts. Single-cue tests,
in which the association of each cue with an outcome is rated or chosen
separately, are not scored. Other designs and tests will be added once
the need arises, e.g., when the `CATLAS` project runs a different kind
of experiment.

### Confidence ratings

The design registry records the scale of the confidence ratings (1 to 10
in the three-stage designs, as in Beesley & Le Pelley, 2011). In a
design that collects no confidence ratings, `confidence` and
`signed_confidence` are `NA` throughout, so that the table keeps the
same columns in every design, and the confidence-weighted index of
[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
is `NA` too.

### Messages

Every call states what was scored, how the sign is defined, the
confidence scale, and how many trials timed out, unless silenced
(`silence = TRUE`).

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on
overt attention and associability in human learning. *Journal of
Experimental Psychology: Animal Behavior Processes, 37*(1), 114-120.
[doi:10.1037/a0019526](https://doi.org/10.1037/a0019526)

Don, H. J., & Livesey, E. J. (2018). Is the blocking effect sensitive to
causal model? It depends how you ask. In *Proceedings of the 40th Annual
Meeting of the Cognitive Science Society* (pp. 1633-1638).

Gluck, M. A., & Bower, G. H. (1988). From conditioning to category
learning: An adaptive network model. *Journal of Experimental
Psychology: General, 117*(3), 227-247.
[doi:10.1037/0096-3445.117.3.227](https://doi.org/10.1037/0096-3445.117.3.227)

## See also

[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md),
[`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md),
[`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md)
