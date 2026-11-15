# Test learning against chance per participant and stage

For every participant and learning stage, the function pools the scored
trials of the selected blocks across contingency types and tests the
number of correct responses against a chance performance with a
one-sided exact binomial test. Next to the test, it reports the cut-off:
the smallest number of correct responses that passes, given the number
of answered trials.

## Usage

``` r
test_learning(
  scores,
  blocks = NULL,
  alpha = 0.1,
  chance = 0.5,
  silence = FALSE
)
```

## Arguments

- scores:

  Per-participant learning scores, from
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md).

- blocks:

  `NULL` (default) to test every block of every stage, or a named list
  of block numbers per stage, e.g.
  `list(stage1 = 6:10, stage2 = 5:8, stage3 = 4:6)`. Stages absent from
  the list are tested across all their blocks.

- alpha:

  Numeric(1). One-sided significance level of each test. Defaults to
  `0.10`.

- chance:

  Numeric(1). Probability of a correct response by guessing. Defaults to
  `0.5`, as every trial of the three-stage designs offers two outcomes.

- silence:

  Logical(1). Suppress the message about the assumptions behind the
  tests. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant and stage, and columns:

- `id`, `stage`:

  Participant and learning stage.

- `first_block`, `last_block`, `n_blocks`:

  The blocks that entered the test for this participant.

- `n_responded`:

  Answered trials across blocks.

- `n_correct`:

  Correct responses among answers.

- `p_correct`:

  `n_correct / n_responded`.

- `k_crit`:

  Smallest `n_correct` that passes: the least \\k\\ with \\P(X \ge k)
  \le \alpha\\ for \\X \sim Binomial(n\_{responded}, chance)\\.

- `p_crit`:

  `k_crit` / `n_responded`. The proportion correct that passes the
  null-hypothesis significance test. It should not be confused with a
  p-value, compare it with `p_correct`.

- `p_value`:

  One-sided exact binomial p-value, \\P(X \ge n\_{correct})\\.

- `above_chance`:

  `n_correct >= k_crit`, equivalently `p_value <= alpha`.

A participant without any answered trial in a stage gets `NA` in the
test columns, including `above_chance`.

## Details

### Test assumptions

Under the null hypothesis, a participant's responses carry no
information about which outcome is correct, so every answered trial is
correct with `chance` probability, independently of the block. The null
distribution of `n_correct` is therefore exactly
\\Binomial(n\_{responded}, chance)\\ and it does not depend on how
accuracy would change across blocks for someone who learns. Learning
changes only the distribution under the alternative, i.e., the power of
the test, not its size (the rate at which participants without knowledge
succeed).

Two consequences follow from Hoeffding (1956), who compares the number
of successes in independent trials with unequal success probabilities to
the binomial distribution with the same mean:

- In the three-stage designs every block holds as many trials for one
  outcome as for the other. A participant who responds with a bias but
  without knowledge (e.g., always choosing the left option) is correct
  on half the tested trials on average, with less dispersion than the
  binomial, and so passes no more often than `alpha`. Only whole blocks
  enter the test, which keeps this balance.

- A participant whose accuracy rises across blocks passes at least as
  often as one with constant accuracy at the same mean, provided the
  expected number of correct responses exceeds `k_crit` by at least one.

Each stage is tested on its own, with no adjustment of the significance
test threshold for multiple comparisons across stages. The question
asked by the test is whether the participant learned every stage.

### Default alpha

At `alpha = 0.10` the cut-off on a 48-trial stage is 29 correct (60.4%),
similar to the 60% criterion that Le Pelley et al. (2005) applied to
both training stages of their two-stage design. On the 80- and 64-trial
stages of To our knowledge, no three-stage study tested Stage 3 against
chance, so its cut-off cannot be copied from the literature. At the
default, a participant who guesses throughout the three-stage
replication passes each stage with probability below `alpha`, and all
three with probability below 0.001.

### Messages

Every call states the test, the blocks per stage, and how many
participants failed the test in each stage, unless silenced
(`silence = TRUE`).

## References

Le Pelley, M. E., Oakeshott, S. M., & McLaren, I. P. L. (2005). Blocking
and unblocking in human causal learning. *Journal of Experimental
Psychology: Animal Behavior Processes, 31*(1), 56-70.
[doi:10.1037/0097-7403.31.1.56](https://doi.org/10.1037/0097-7403.31.1.56)

Hoeffding, W. (1956). On the distribution of the number of successes in
independent trials. *The Annals of Mathematical Statistics, 27*(3),
713-721.

## See also

[`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
[`screen_learning()`](https://josefmana.github.io/catlasr/reference/screen_learning.md)
