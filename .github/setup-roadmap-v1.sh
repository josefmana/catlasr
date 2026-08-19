#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Roadmap for josefmana/catlasr, the R package carrying data import,
# preprocessing, models and visual identity for the CATLAS project.
#
# Renames one existing milestone, creates seven more (all undated, ordered by
# title), retrofits six existing issues and creates forty-one new ones.
#
# Run .github/setup-labels-v1.sh first: every label used below comes from there.
#
# THE BOUNDARY RULE, which decides what may be an issue in this repository:
#
#   {mathpsychr}  Engines. Generic estimation and measurement machinery.
#   CATLAS        Hub. Documentation, preregistrations, manuscripts. Ships
#                 *claims*. Contains no experiment and no model, ever.
#   {catlasr}     Import, preprocessing, models, visual identity. This repo.
#   catlaslab     Experiment code (jsPsych, Psychopy, ...).
#
# A capability belongs in {mathpsychr} if the study *after*
# `fba-allergy-online-02` would call it unmodified. Otherwise it belongs here.
#
# STUDY NAMING is `fba-<task>-<mode>-0X`. The authoritative source is the
# `Study` field on Project #6.
#
# MILESTONES ARE UNDATED BUT ORDERED. GitHub sorts undated milestones after
# dated ones and then alphabetically, so the order is carried twice: by a
# leading ordinal in the title, and by a `Follows` / `Precedes` line in the
# body. The ordinal reads at a glance and goes stale the moment something is
# inserted. The body line survives that and is the one to trust.
#
# THE DATES LIVE IN CATLAS, NOT HERE, and are recorded once for reference,
# because a provisional date on a board is read as a real one:
#
#   2026-08-14  `-02` scope lock          needs the milestone 1 naming migration
#   2026-09-10  `-01` pilot analysis      needs milestones 1, 2 and 3
#   2026-09-30  `-02` design analysis     needs milestone 4               (HARD)
#   2026-10-30  `-02` pre-registration
#   2026-12-15  `-02` data collection     needs milestone 5
#
# WHAT MILESTONE 2 IS. The existing milestone `v0.1.0:
# forward-blocking-online-replication support` is renamed rather than closed or
# duplicated. It holds four closed issues and three open ones (#2, #4, #7) and
# it is, in substance, the import-and-preprocess milestone. Two reasons for the
# rename: its ordinal position has to be visible beside the others, and `v0.1.0`
# should name the release, which milestone 6 does. Its closed history is
# untouched by the rename.
#
# Usage:
#   bash .github/setup-roadmap-v1.sh
#   DRY_RUN=1 bash .github/setup-roadmap-v1.sh   # print only
#
# Re-runs are no-ops: milestones matched by title and patched, issues deduped
# on exact title, retitles and relabels check before writing.
#
# RUN THE DRY RUN FIRST AND READ THE RETROFIT SECTION'S OUTPUT. It is the only
# part of this script that touches work that already exists.

set -uo pipefail

REPO="${REPO:-josefmana/catlasr}"
DRY_RUN="${DRY_RUN:-0}"

command -v gh >/dev/null 2>&1 || { echo "gh CLI not found" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated" >&2; exit 1; }

run() {
  if [ "${DRY_RUN}" = "1" ]; then
  printf '    DRY: %s\n' "$1 $2 $3 ..." >&2
  else
    "$@"
  fi
}

echo "Repository: ${REPO}"
[ "${DRY_RUN}" = "1" ] && echo "*** DRY RUN, nothing will be written ***"
echo

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

# ms <title> <due YYYY-MM-DD | ""> <description>
# Creates or updates a milestone. Every call passes an empty due date.
# Sets the global M, which mk() attaches to every issue until M is reassigned.
ms() {
  local title="$1" due="$2" desc="$3" num
  local -a args=(-f title="${title}" -f state=open -f description="${desc}")
  [ -n "${due}" ] && args+=(-f due_on="${due}T23:59:59Z")
  num=$(gh api "repos/${REPO}/milestones?state=all&per_page=100" \
        --jq ".[] | select(.title == \"${title}\") | .number" 2>/dev/null | head -n1)
  if [ -n "${num}" ]; then
  run gh api -X PATCH "repos/${REPO}/milestones/${num}" "${args[@]}" >/dev/null \
  && echo "  = milestone: ${title}"
  else
    run gh api -X POST "repos/${REPO}/milestones" "${args[@]}" >/dev/null \
  && echo "  + milestone: ${title}"
  fi
  M="${title}"
}

# msrename <old title> <new title>
# Renames a milestone in place, which carries its issues and its closed history
# across. No-op if the old title is absent or the new one already exists.
msrename() {
  local old="$1" new="$2" num newnum
  num=$(gh api "repos/${REPO}/milestones?state=all&per_page=100" \
        --jq ".[] | select(.title == \"${old}\") | .number" 2>/dev/null | head -n1)
  newnum=$(gh api "repos/${REPO}/milestones?state=all&per_page=100" \
           --jq ".[] | select(.title == \"${new}\") | .number" 2>/dev/null | head -n1)
  if [ -z "${num}" ]; then
  echo "  . no milestone titled: ${old}"
  return 0
  fi
  if [ -n "${newnum}" ]; then
  echo "  ! both titles exist; merge by hand: ${old} / ${new}" >&2
  return 0
  fi
  run gh api -X PATCH "repos/${REPO}/milestones/${num}" -f title="${new}" >/dev/null \
  && echo "  ~ milestone: ${old} -> ${new}"
}

# mk <title> <labels csv> <body>
# Title-deduped: an issue with this exact title, open or closed, is left alone.
mk() {
  local title="$1" labels="$2" body="$3"
  if gh issue list --repo "${REPO}" --state all --limit 500 --json title \
  --jq '.[].title' 2>/dev/null | grep -Fxq "${title}"; then
  echo "  . exists: ${title}"
  return 0
  fi
  run gh issue create --repo "${REPO}" \
  --title "${title}" --body "${body}" \
  --label "${labels}" --milestone "${M}" >/dev/null \
  && echo "  + ${title}"
}

# ret <number> <new title>
# Retitles only if the title differs, so re-runs write nothing.
ret() {
  local num="$1" new="$2" cur
  cur=$(gh issue view "${num}" --repo "${REPO}" --json title --jq '.title' 2>/dev/null)
  if [ -z "${cur}" ]; then
  echo "  ! no such issue: #${num}" >&2
  return 0
  fi
  if [ "${cur}" = "${new}" ]; then
  echo "  . #${num} title already correct"
  return 0
  fi
  run gh issue edit "${num}" --repo "${REPO}" --title "${new}" >/dev/null \
  && echo "  ~ #${num}: ${cur}"
}

# fix <number> <add labels csv> <remove labels csv | ""> <milestone | "">
# Adding a label an issue already has is a no-op at the API, so this is
# idempotent without a read.
fix() {
  local num="$1" add="$2" del="$3" mil="$4"
  local -a args=(--repo "${REPO}")
  [ -n "${add}" ] && args+=(--add-label "${add}")
  [ -n "${del}" ] && args+=(--remove-label "${del}")
  [ -n "${mil}" ] && args+=(--milestone "${mil}")
  run gh issue edit "${num}" "${args[@]}" >/dev/null \
  && echo "  * #${num} labels/milestone set"
}

# ------------------------------------------------------------------------------
# 0 · Milestones
# ------------------------------------------------------------------------------
#
# Created before the retrofit, because the retrofit assigns issues to them.

echo "0 · Milestones"

msrename "v0.1.0: forward-blocking-online-replication support" \
"2 · \`{catlasr}\` imports \`fba-allergy-online-01\`"

# Only fires if an earlier run of this script created the narrower title. A
# no-op otherwise.
msrename "Placeholder: unscheduled tasks" \
"8 · Placeholder: unscheduled strands"

ms "1 · \`{catlasr}\` installs and can be called" "" \
"**Must contain**

* \`metaSDT\` out of \`Imports:\`, because it is what currently makes this package uninstallable
* A public API: the import and preprocessing layer exported, so a CATLAS notebook can call it without \`:::\`
* The four error paths that would themselves error, fixed
* The duplicate \`is_catlas_rawdata()\` definition resolved
* \`R CMD check\` run, its result recorded, and a CI workflow that keeps it run
* The \`fba-\` naming migration completed on this repository's side

**Follows**: nothing. First milestone in the programme.
**Precedes**: everything. The pilot analysis in milestone 3 is what CATLAS is waiting for and it cannot be run by anyone who cannot install the package."

# Called after msrename, deliberately not instead of it. If the rename succeeded
# this patches the description onto the milestone that already holds #2, #4 and
# four closed issues. If the old title did not match exactly, the rename is a
# no-op and this creates the milestone instead, so the four issues below still
# have somewhere to go rather than failing one at a time on an unknown
# milestone.
ms "2 · \`{catlasr}\` imports \`fba-allergy-online-01\`" "" \
"**Must contain**

* \`.cues_map\` inside the package, with its canonicalisation invariant documented
* \`raw2json()\` given a home, in writing
* One end-to-end test from JATOS export to validated bundle
* Participant e-mail addresses demonstrably outside the repository

**Follows**: milestone 1.
**Precedes**: milestone 3.

This is the renamed \`v0.1.0: forward-blocking-online-replication support\` milestone and it keeps its closed history. It already holds #2 and #4, which are the import work itself. The issues below add everything the import path depends on that currently lives in a loose script rather than in the package."

ms "3 · \`{catlasr}\` reproduces the \`fba-allergy-online-01\` analysis" "" \
"**Must contain**

* The primary index (BI2 on the first test block) named in the manuscript's vocabulary and documented so the block/trial identity is not re-reported as a bug
* The calibration variant, BI2 across all test blocks
* BI3 checked against the pilot by hand
* Participant exclusion rules
* The learning curves packaged as functions
* A synthetic \`catlas_rawdata\` fixture generated from known truth

**Follows**: milestone 2.
**Precedes**: milestone 4, and CATLAS's pilot analysis.

The estimation strategy is fixed and is not this milestone's to reopen. BI2 on the first test block is the only confirmatory number; BI2 across all blocks is calibration and pilot data-mining; BI3 is the alternative. The GLMM work is diagnostics and lives in milestone 4.

Most of what is listed here exists already, as a loose script that imports the pilot, plots it, computes both indices and runs the t-tests. This milestone is mostly the work of turning that script into functions that CATLAS can call, and of writing down the decisions the script made implicitly."

ms "4 · \`{catlasr}\` supports the \`fba-allergy-online-02\` pre-registration" "" \
"**Must contain**

* A home for the design analysis's power calculation decided
* The GLMM learning checks, which indicate how much credibility the averaged indices deserve
* The preprocessing API frozen, so later changes are logged deviations

**Follows**: milestone 3. The design analysis takes its effect sizes from the pilot analysis.
**Precedes**: milestone 5.

Two things are deliberately absent. **Simulation-based design analysis.** A simulator written before the Python-to-R translation of the associative models would be theory-blind data generation in a repository whose whole point is that theory-informed generators are planned and it would be thrown away when they arrive. **Implication-test and DAG machinery.** Its removal is a programme-level decision reflecting the fact that \`forward-blocking-attention-01\` has its causal path already paved out."

ms "5 · \`{catlasr}\` ingests \`fba-allergy-online-02\`" "" \
"**Must contain**

* \`.fb_trial_count_range\` parameterised, and the pilot-only halving deleted
* \`validate_fba_rawdata()\` passing on the full \`-02\` bundle
* \`catlas_jatos_rawdata()\` renamed for the data type it constructs

**Follows**: milestone 4, and \`josefmana/catlaslab\`, since the data cannot exist before the task is deployed.
**Precedes**: milestone 6.

IMPORTANT: Both structural items are scheduled to land *before* the first participant of \`fba-allergy-online-02\`."

ms "6 · \`{catlasr}\` cleanup, identity and v0.1.0" "" \
"**Must contain**

* The stimuli vignette precomputed, so the package can be built by anybody
* \`theme_catlas()\` in green and black, applied first to the literature-replication figure
* \`apa_style.R\` retired
* pkgdown configured and published
* \`R CMD check\` clean, \`NEWS.md\` written, \`v0.1.0\` tagged

**Follows**: milestone 5.
**Precedes**: nothing. The two placeholders sit outside the sequence.

The release is tied to a manuscript that will include at minimum two other pre-registered experiments, so this milestone has no natural date and should not acquire one. It does have a natural gate though: \`v0.1.0\`, a citable release."

ms "7 · Placeholder: \`caphe\`, the CATLAS phenomena library" "" \
"**Must contain**

* Nothing on the critical path. This milestone runs in parallel with all the others and is not allowed to block any of them.

**Follows**: nothing. It sits outside the sequence deliberately.
**Precedes**: milestone 6 only in the weak sense that \`caphe\` should be presentable by \`v0.1.0\`. It does not need to be publishable.

\`caphe\` is the catlas-phenomena bibliography: a corpus of per-study JSON on OSF, versioned and DOI-minted, with \`{catlasr}\` holding the logic layer (constructors, validators, I/O) and a small in-package stub for offline testing.

It replaces \`fb_designs\` and \`fb_effects\`, which are bundled data and are ineffective for a growing literature database."

ms "Placeholder: unscheduled tasks" "" \
"**Must contain**

* Nothing. This milestone is a marker, not a plan. It holds two unrelated tasks, kept together only because both are unscheduled and neither should be started by accident.

**Follows**: nothing.
**Precedes**: nothing.

The attention-model strand is the Python-to-R translation of the derived-attention models and everything downstream: EXIT, Paskewitz & Jones (2023)'s Bayesian Derived Attention model, and possibly latent-state models of Stage 3 learning quality predicting test-phase decision tendency, and decision and confidence as correlated latents."

echo

# ------------------------------------------------------------------------------
# 0b · Retrofit of the six existing open issues
# ------------------------------------------------------------------------------
#
# READ THE DRY-RUN OUTPUT OF THIS SECTION BEFORE RUNNING IT FOR REAL. Everything
# else in this file only creates.
#
# #2  jsPsych/JATOS data import                          -> milestone 2, unchanged labels
# #4  `forward-blocking-jatos` data pre-processing       -> retitled, scope: preprocessing, milestone 2
# #7  Pre-processing functions for forward-blocking data -> retitled, scope: preprocessing, milestone 3
# #8  Prepare learning checks for training trials        -> scope: preprocessing, milestone 3
# #10 Bibliography management                            -> scope: caphe, milestone 7
# #11 Data architecture for literature databases         -> scope: caphe, milestone 7
#
# #2 and #4 carry sub-issues (1/2 each). Sub-issue links survive a retitle and a
# relabel; nothing here touches them.

echo "0b · Retrofit"

ret 4 "\`fba-allergy-online-01\` data pre-processing"
ret 7 "Pre-processing functions for \`fba-allergy-online-01\` data"

fix 2  "scope: data"          ""             "2 · \`{catlasr}\` imports \`fba-allergy-online-01\`"
fix 4  "scope: preprocessing" "scope: data"  "2 · \`{catlasr}\` imports \`fba-allergy-online-01\`"
fix 7  "scope: preprocessing" "scope: data"  "3 · \`{catlasr}\` reproduces the \`fba-allergy-online-01\` analysis"
fix 8  "scope: preprocessing" "scope: data"  "3 · \`{catlasr}\` reproduces the \`fba-allergy-online-01\` analysis"
fix 10 "scope: caphe"         "scope: data"  "7 · Placeholder: \`caphe\`, the CATLAS phenomena library"
fix 11 "scope: caphe"         "scope: data"  "7 · Placeholder: \`caphe\`, the CATLAS phenomena library"

echo

# ------------------------------------------------------------------------------
# 1 · {catlasr} installs and can be called
# ------------------------------------------------------------------------------

echo "1 · \`{catlasr}\` installs and can be called"
M="1 · \`{catlasr}\` installs and can be called"

mk "Remove \`metaSDT\` from \`Imports:\` — the package does not install" "scope: pkg,type: bug,status: cmd-check,priority: critical-path" \
"**Do this first. Nothing else in this repository can be verified until it is done.**

To do:

- [ ] Drop \`metaSDT\` from \`Imports:\`
- [ ] Guard \`score_meta_d()\` with \`rlang::check_installed()\` as a stopgap only. Whether meta-d' has a home at all is milestone 8's question, and the expected answer there is deletion
- [ ] Run \`R CMD check\`
- [ ] The replacement is milestone 3's \`stats::optim()\` issue"

mk "Define and export the public API" "scope: pkg,type: feature,priority: critical-path" \
"Six \`@export\` tags exist in the whole package. Five are in \`R/stims-*.R\`; the sixth is \`print.catlas_rawdata\`. Every constructor, validator, generic and blocking index is \`@noRd\`.

To do:

- [ ] Export the constructors and validators: \`catlas_rawdata()\`, the JATOS constructor, \`validate_catlas_rawdata()\`, the FBA validator
- [ ] Export the generics: \`extract_meta()\`, \`extract_stimuli()\`, \`extract_trials()\`. Methods are registered by \`S3method()\` and are not exported separately
- [ ] Export the blocking indices. **Do not export \`score_meta_d()\`**,it is dead until milestone 8 decides otherwise
- [ ] Export the \`is_*()\` predicates
- [ ] Keep internal: the \`.fb_*\` constants, \`.resolve_stimulus_values()\`, \`.tag_stage1_type()\`, \`.make_rating_counts()\`
- [ ] Rewrite the pilot script to use exported names, and confirm \`extract_trials(x)\` dispatches. Every surviving \`:::\` afterwards is a function that should have been exported and was not
- [ ] Draft the pkgdown reference grouping while the grouping is fresh, even though pkgdown itself is milestone 6"

mk "Fix the four error paths that would themselves error" "scope: preprocessing,type: bug,status: needs-tests" \
"Four \`cli\` calls interpolate names that do not exist:

| File · line | What it says | What exists |
|---|---|---|
| \`forward-blocking-preprocessing.R:337\` | \`{missing_blocking}\` | \`missing_minuend\` (line 331) |
| \`forward-blocking-preprocessing.R:338\` | \`{missing_control}\` | \`missing_subtrahend\` (line 332) |
| \`forward-blocking-validators.R:106\` | \`\`{\`.fb_min_out_types\`}\`\` | \`.fb_min_outcome_types\` (line 20) |
| \`forward-blocking-validators.R:92\` | \`\`{\`.fb_min_cue_types\`}\`\` | right name, but backticks inside \`{}\` are not glue syntax |

A fifth, different in kind and in the same family of never-executed code: \`forward-blocking-preprocessing.R:121\` calls \`subset(trials, .data\$stage == \"stage1\")\`. \`.data\` is an rlang pronoun and is not available inside base \`subset()\`, which does its own non-standard evaluation. This one is in the *main* path of \`.tag_stage1_type()\`.

To do:

- [ ] Correct the four interpolations,
- [ ] Replace the \`subset()\` call with \`dplyr::filter()\` or plain \`[\` indexing,
- [ ] Write a test per branch that forces the condition and asserts on the **message text**,
- [ ] Grep for every other \`cli_abort\` / \`cli_warn\` interpolation and check each name against a defined object."

mk "Resolve the duplicate \`is_catlas_rawdata()\` definition" "scope: data,type: bug,status: needs-tests" \
"\`is_catlas_rawdata()\` is defined twice: \`data-validators.R:472\` and \`rawdata-methods.R:47\`.

To do:

- [ ] Compare the two bodies,
- [ ] Keep the one in \`rawdata-methods.R\`, beside \`is_catlas_jatos_rawdata()\`, which has no duplicate,
- [ ] Delete the other,
- [ ] Grep for the same pattern across all files."

mk "Audit \`Imports:\` against what the code actually calls" "scope: pkg,type: chore,status: cmd-check" \
"\`DESCRIPTION\` and the code disagree in both directions.

Declared but unused: \`gt\` is in \`Imports:\` and appears nowhere in \`R/\` — it belongs to the vignette. \`metaSDT\`, per the install issue.

Used but undeclared: \`stats::sd()\` at \`forward-blocking-preprocessing.R:211\`; and the pilot script additionally reaches for \`ggplot2\`, \`scales\`, \`Rmisc\`, \`rstatix\`, \`here\` and \`glue\`.

To do:

- [ ] Move \`gt\` to \`Suggests:\`
- [ ] Declare \`stats\` in \`Imports:\` with the \`@importFrom\` in \`R/catlasr-package.R\`
- [ ] Add \`ggplot2\` and \`scales\` when the plotting functions land
- [ ] Decide \`Rmisc\` and \`rstatix\` in milestone 3, where the functions that need them are written
- [ ] Walk \`Suggests:\` (\`here\`, \`readr\`, \`tidyverse\`, \`jatosR\`, \`jsonlite\`, \`knitr\`, \`rmarkdown\`, \`osfr\`) and check each is genuinely optional or guarded by \`rlang::check_installed()\`. \`tidyverse\` as a dependency of a package is worth questioning on its own
- [ ] Reconsider \`Depends: R (>= 4.5)\`. The native pipe and lambda syntax need 4.1. 4.5 is a strong requirement for a package collaborators must install on machines you do not control. If there is a reason, comment it; if not, lower it"

mk "Migrate naming to \`fba-<task>-<mode>-0X\` in \`{catlasr}\`" "scope: pkg,type: chore" \
"Four vocabularies are in circulation for one study.

| Vocabulary | Where |
|---|---|
| \`forward-blocking-\` | \`R/\` and \`data-raw/\` filenames, function names, issue titles #4 and #7 |
| \`fb_\` / \`fb-\` | \`.fb_*\` constants, \`fb_designs\`, \`fb_effects\`, \`fb_replication_online\` |
| \`catlas_[01]\` | \`study_id\` in the JATOS import script |
| \`fba-allergy-online-0X\` | the \`Study\` field on Project #6, which is authoritative |

This issue covers **this repository only**. \`josefmana/CATLAS\` and \`josefmana/catlaslab\` have their own. Do all three in one sitting.

- [ ] Issue titles #4 and #7 — handled by the roadmap script's retrofit section
- [ ] Roxygen \`@description\` and \`@examples\` text naming the study
- [ ] \`R/\` and \`data-raw/\` filenames, per the file-scheme decision issue
- [ ] \`validate_forward_blocking_rawdata()\` becomes \`validate_fba_rawdata()\`
- [ ] \`study_id\` and the \`fb_replication_online\` object name in the import script
- [ ] \`README\`, the \`Description:\` field, any OSF node comment
- [ ] Leave the \`.fb_\` **internal constant** prefix and \`fb_designs\` / \`fb_effects\` alone: both datasets are being deleted outright by \`caphe\`. Note the exception when closing, so the surviving \`fb_\` is a decision and not a miss"

mk "Settle the \`R/\` file-naming scheme" "scope: pkg,type: question" \
"Three schemes are in use. \`stims-\`, \`rawdata-\` and \`data-\` are subsystem-first; \`forward-blocking-\` is study-first; \`catlasr-package.R\` is neither. The naming migration forces the study-first files to change anyway, so the question is whether the same commit normalises the rest.

The proposal:

| Now | Proposed | Why |
|---|---|---|
| \`data-constructors.R\` | \`rawdata-constructors.R\` | \`data-\` names nothing; contents are rawdata and literature constructors |
| \`data-validators.R\` | \`rawdata-validators.R\` | as above, and it puts the duplicate predicate beside its twin |
| \`forward-blocking-preprocessing.R\` | \`preprocessing-fba.R\` | subsystem first, study second |
| \`forward-blocking-validators.R\` | \`rawdata-validators-fba.R\` | it validates rawdata under FBA constraints |
| \`datasets-forward-blocking.R\` | *deleted* | it documents \`fb_designs\` and \`fb_effects\`, which \`caphe\` removes |
| \`stims-*.R\`, \`rawdata-*.R\` | unchanged | already correct |"

mk "testthat scaffold and a GitHub Actions \`R CMD check\`" "scope: pkg,type: test,status: cmd-check" \
"There is no \`tests/\` directory, and \`R CMD check\` has never run to completion because the package does not install.

Order matters: this cannot start until the \`metaSDT\` issue closes, and every bug issue in this milestone wants a regression test that has nowhere to live until this one does.

To do:

- [ ] \`usethis::use_testthat(3)\`
- [ ] \`usethis::use_github_action(\"check-standard\")\`, on push and pull request
- [ ] Pin the first tests against the bugs fixed in this milestone.
- [ ] Decide whether the check runs on more than one R version. Given \`Depends: R (>= 4.5)\` one runner is defensible; if that drops, this widens with it
- [ ] The check will fail on the vignette until it is precomputed (milestone 6). Until then run \`--no-build-vignettes\` and say so in a workflow comment, so the exclusion is a decision rather than something later assumed to be an oversight
- [ ] \`status: cmd-check\` is the label to watch. Once CI is green, that label's open count is the standing answer to \"is the package healthy\""

echo

# ------------------------------------------------------------------------------
# 2 · {catlasr} imports fba-allergy-online-01   (renamed from v0.1.0)
# ------------------------------------------------------------------------------

echo "2 · \`{catlasr}\` imports \`fba-allergy-online-01\`"
M="2 · \`{catlasr}\` imports \`fba-allergy-online-01\`"

mk "Move \`.cues_map\` into the package as data" "scope: data,type: refactor,status: needs-code" \
"The import script defines a 56-row \`tribble\` mapping every jsPsych \`cues\` label to \`cue1\`, \`cue2\` and \`cues_reversed\`. It is the single most load-bearing object in the import path and it lives in a loose script.

It is also **the reason \`compute_pj_blocking()\` is correct**, which is not obvious and is worth recording somewhere durable. The map canonicalises presentation order (\`\"DQ\"\` and \`\"QD\"\` both resolve to \`cue1 = \"D\", cue2 = \"Q\"\`), with the order carried separately in \`cues_reversed\`, so the blocking-score join on \`c(\"cue1\", \"cue2\")\` matches both orders and drops nothing. Anybody reading that join without knowing about the map will conclude it silently discards half the test trials, which it does not.

To do:

- [ ] Move it into \`R/\` as internal package data, or into \`data-raw/\` with \`usethis::use_data(internal = TRUE)\`
- [ ] Document the canonicalisation invariant explicitly: \`cue1\` and \`cue2\` are in fixed order and \`cues_reversed\` carries presentation. Reference it from \`compute_pj_blocking()\`
- [ ] Validate it on load: every label unique, every pair present in both orders, \`cues_reversed\` never \`NA\` for a two-cue label
- [ ] Decide whether it is study-specific or paradigm-general. It contains \`alpha\`/\`beta\` and the full alphabet, which suggests general; if \`-02\` changes the cue set, this needs to be a parameter rather than a constant"

mk "Decide where \`raw2json()\` lives" "scope: data,type: question" \
"\`raw2json()\` is defined in the import script, not in \`R/\`. It repairs JATOS output, which arrives as \"json-like\" text missing the enclosing brackets and the commas between records. Two lines of \`gsub\` and \`paste0\`, and the whole import path depends on them.

The cleanest available test of the boundary rule, which is why it is worth an issue.

* **\`{mathpsychr}\`.** Repairing malformed JATOS output is platform knowledge, not CATLAS knowledge, and the study after \`-02\` would call it unmodified, meeting the boundary rule's own criterion
* **Here, in \`R/\`, exported.** It is import machinery and this is the import repository. \`-02\` collection depends on it, and depending on an upstream release schedule during data collection is risk with no upside
* **Here, in \`data-raw/\`, unchanged.** Defensible only if nothing but \`data-raw/\` will ever call it, which stops being true the moment CATLAS re-imports

Most likely winner is the second option with an upstream note: build it here, flag it as a promotion candidate, let \`{mathpsychr}\` take it later. Decide."

mk "End-to-end import test: JATOS export to validated bundle" "scope: data,type: test,status: needs-tests" \
"Every piece of the import path has been run by hand. The path as a whole has been run once, by its author, in a session that no longer exists.

To do:

- [ ] Save one small real JATOS export as a fixture, de-identified  (see the e-mail issue before assuming it can be shipped)
- [ ] Include at least one malformed runner, so the \`valid = FALSE\` branch is exercised
- [ ] Test from the fixture through \`raw2json()\`, the constructor and the validator, asserting on shape at each boundary rather than only at the end
- [ ] Check the \`mutate(response = as.character(response))\` workaround, commented in the script as being \"for people who rejected to participate\"
- [ ] Re-work the data import script to a thin caller of tested functions"

mk "Keep participant e-mail addresses out of the repository" "scope: data,type: bug" \
"The import script has a \`save_emails\` flag that writes ID/e-mail pairs to \`data-raw/{study_id}_emails.csv\`. It defaults to \`FALSE\`, which is right, but the file lands inside the repository, which is not.

The risk is that \`data-raw/\` is a directory somebody commits from without reading, and a single \`git add -A\` on a day the flag was \`TRUE\` puts participant e-mail addresses into a public history that cannot be rewritten quietly.

To do:

- [ ] Write the file outside the repository via \`tempdir()\`, or a path from an environment variable, or somewhere explicitly outside the project
- [ ] If it must stay in \`data-raw/\`, add the exact filename pattern to \`.gitignore\` **and** verify with \`git check-ignore\` rather than assuming
- [ ] Check \`git log\` for whether such a file has ever been committed. Do this before anything else, because the answer changes what this issue is
- [ ] Same question for the \`meta_data\` bundle, which carries \`sex\`, \`age\`, \`browser\` and \`os\` alongside the JATOS ID
- [ ] Record what the ethics approval and the consent text actually say about retention"

echo

# ------------------------------------------------------------------------------
# 3 · {catlasr} reproduces the fba-allergy-online-01 analysis
# ------------------------------------------------------------------------------

echo "3 · \`{catlasr}\` reproduces the \`fba-allergy-online-01\` analysis"
M="3 · \`{catlasr}\` reproduces the \`fba-allergy-online-01\` analysis"

mk "Adopt the BI vocabulary in roxygen, and record why block 1 is trial 1" "scope: preprocessing,type: docs,status: needs-vignette,priority: critical-path" \
"The manuscript says BI1, BI2, BI3. The package says \`compute_cw_blocking\` and \`compute_pj_blocking\` and never uses the numbered vocabulary at all. Two names for one quantity across a manuscript and its analysis package is how a reviewer finds a discrepancy that does not exist, and how an author later fails to find one that does.

**The thing most worth writing down.** \`compute_cw_blocking()\` filters \`stage == \"test\", block == 1L\` — the first test **block**. The manuscript's primary endpoint is the first test **trial**. Those read as different quantities and are not: \`trial\` is meant type-wise, and each test trial type appears exactly once per block, so the first block *is* the first presentation of every trial type. The function is correct as written, but sound ambiguous wehn read together with the manuscript text. Make sure it is unambigoused everywhere.

To do:

- [ ] State the block/trial-type identity in \`@details\` of the primary index, in one sentence, with the trial-type count read off the \`catlaslab\` jsPsych timeline rather than reconstructed from the manuscript draft
- [ ] Name the functions in the manuscript's vocabulary, e.g., \`compute_bi2()\`, \`compute_bi3()\`, with the descriptive names as \`@aliases\`, or the reverse
- [ ] Add an \`@section\` to the package documentation recording that BI1 is not implemented, is not implementable under 2AFC, and is reported from the literature only. This is a place where absent code needs documenting
- [ ] Cross-check every BI reference in the CATLAS manuscript against the resulting names"

mk "Fix \`@returns\` in the confidence-weighted score" "scope: preprocessing,type: docs,status: needs-example" \
"\`compute_cw_blocking()\` documents that it returns \`cb_m\` and \`cb_sd\` (lines 155–156). It returns \`cw_score\` and \`cw_sd\` (lines 210–211), which is also what the pilot script's \`rstatix::t_test(cw, cw_score ~ 1, ...)\` relies on.

The file header has the same drift: line 8 announces \`compute_cb_blocking()\`, and no such function exists.

To do:

- [ ] Correct \`@returns\` and the file header
- [ ] Do it in the same commit as the BI renaming issue, so the names change once rather than twice
- [ ] Add an \`@examples\` block against the synthetic fixture
- [ ] The header also announces \`summarise_learning()\`, \`aggregate_learning()\` and \`plot_learning()\`. Those have their own issue; do not silently delete the lines"

mk "Implement the BI2 calibration variant across all test blocks" "scope: preprocessing,type: feature,status: needs-code" \
"The confirmatory number is BI2 on the first test block. The calibration number is the same index across *all* test blocks. Compared against the first, it is what tells us whether the block-1 restriction costs precision without buying validity, and it informs how \`-02\` is registered.

No function computes it yet. \`compute_cw_blocking()\` hardcodes \`block == 1L\`.

To do:

- [ ] Add a \`blocks\` argument rather than a second function. \`blocks = 1L\` is the confirmatory call and stays the default; \`blocks = NULL\` is all blocks
- [ ] Return the per-block breakdown alongside the aggregate, since the calibration question is about how the index moves across blocks
- [ ] **Do not make the default anything other than the first block.** A default that silently computes the calibration number is a route by which the exploratory quantity ends up reported as the confirmatory one
- [ ] Report the comparison on the pilot here"

mk "Replace the hardcoded \`keep\` vector with exclusion rules" "scope: preprocessing,type: feature,status: blocked,status: needs-vignette,priority: critical-path" \
"The pilot analysis begins with sixteen participant IDs in a literal vector:

\`\`\`r
keep <- c(\"1161643\", \"1161743\", \"1161969\", ...)
\`\`\`

and every downstream object is filtered on it. Nothing in the script says how those sixteen were chosen, and no rule anywhere in the package produces that set.

**Blocked on \`josefmana/CATLAS\`**, which owes the thresholds in pre-registrable language. CATLAS defines, \`{catlasr}\` computes.

To do:

- [ ] Write down why each excluded participant was excluded. Do this first, before CATLAS writes anything
- [ ] Implement each rule as a separate predicate returning one logical column per participant, not a single \`keep\` flag. The composite is derived; the components get reported
- [ ] **Check whether the rules reproduce the sixteen**"

mk "Make \`.tag_stage1_type()\` cue sets data-driven" "scope: preprocessing,type: refactor,status: needs-tests" \
"\`.tag_stage1_type()\` maps Stage 1 trials to blocking or control by hardcoded cue letters: \`A, C, E, G\` blocking, \`I, L, O, R\` control (\`forward-blocking-preprocessing.R:28–32\`).

That works for \`fba-allergy-online-01\`. If \`-02\` counterbalances the abstract-to-role assignment differently, the function does not fail, instead it silently mislabels every Stage 1 trial, and the index computed on top is wrong in a way that produces plausible numbers.

To do:

- [ ] Derive the mapping from the design specification or the participant's \`stimuli\` table, not from a constant
- [ ] If a constant genuinely is right, because the abstract labels are fixed by design across the paradigm, then validate loudly: assert the observed Stage 1 cue set equals the expected one and abort if not, rather than warning and returning \`NA\`
- [ ] Decide whether the unrecognised-cue branch should warn or abort. For a labelling function feeding a confirmatory index, aborting is defensible
- [ ] Document the five-level \`type\` vocabulary somewhere. It is assumed by the plotting code's \`scale_*_manual()\` value vectors, which are positional and will silently mis-map if a level is added
- [ ] Settle before \`-02\` data arrive"

mk "A synthetic \`catlas_rawdata\` fixture generated from known truth" "scope: data,type: test,status: needs-code" \
"Every function is currently testable only against \`fba-allergy-online-01\`, which makes every test a regression test against one dataset. Three separate pieces of work need something else:

* **the error paths fixed in milestone 1** need data that is broken in specific, chosen ways, which real pilot data is not
* **\`@examples\`** must run on a clean machine and on CI, where pilot data does not exist and OSF needs a token
* **the exclusion rules** need a dataset where the answer is known, so that a rule can be checked for doing what it says rather than merely for running

This is a **fixture, not a simulator.** It generates data with chosen properties so that functions can be tested; it does not generate data from a model of how participants learn. The latter option waits for the Python-to-R translation of the associative models.

To do:

- [ ] A generator taking participant count, trial structure, a blocking-effect size and a confidence model, returning a valid \`catlas_rawdata\`
- [ ] It must pass \`validate_fba_rawdata()\` unmodified. A fixture that needs the validator relaxed is testing the wrong thing
- [ ] It must produce \`cues\` labels that resolve through \`.cues_map\`, including reversed pairs. That is the invariant most likely to be got wrong by a generator written from the column names alone
- [ ] Include the pathological cases the error paths need: a participant at ceiling, one missing a cue pair, one with unrecognised Stage 1 cues, one with unbalanced left-right presentation
- [ ] Export it, so anyone reproducing the manuscript can build the same test objects
- [ ] Deterministic under a seed, and record the seed wherever a result depends on it"

mk "Verify \`compute_pj_blocking()\` against the pilot by hand" "scope: preprocessing,type: test,status: needs-tests" \
"What is worth checking:

- [ ] \`rowSums(..., na.rm = FALSE)\` means one missing pair propagates \`NA\` to the whole score. Documented behaviour, easy to lose track of at the point where participants are dropped. Count how many pilot participants it affects and confirm the warning reports that number
- [ ] Compute BI3 by hand for two or three participants via spreadsheet or a plain \`table()\` and compare pair by pair
- [ ] Include a participant with reversed-order presentations, to pin the canonicalisation invariant as a test rather than as a paragraph
- [ ] Confirm the \`n_unmatched_pairs\` message fires on real data and reports a sensible count. It is an \`inform\`, not a warning, so it is easy to scroll past"

mk "Package the pilot learning curves as functions" "scope: preprocessing,type: feature,status: needs-code" \
"\`forward-blocking-preprocessing.R\` opens by announcing six functions and contains three. \`summarise_learning()\`, \`aggregate_learning()\` and \`plot_learning()\` are named at lines 13–18 and defined nowhere.

They do exist — as \`part_plot\`, \`aves\` and \`agg_plot\` in the pilot analysis script. So this is packaging, not writing, and the script is the specification. Sibling of the learning-checks issue, which is the *diagnostic question*; this one is the *machinery*.

Four things the script settles, and one it gets wrong:

- [ ] \`summarise_learning()\` is the \`group_by(id, stage, type, block) |> summarise(p_correct = mean(is_correct))\` step. Straightforward
- [ ] \`aggregate_learning()\` is \`Rmisc::summarySEwithin()\`. **Decide what it returns.** The file header promises SEM; \`summarySEwithin\` gives Morey-corrected within-subject confidence intervals, which are a different quantity with a different interpretation, and the plot draws \`is_correct ± ci\`. Both are defensible; publishing one while the documentation names the other is not. Decide, and decide whether \`Rmisc\` is worth an \`Imports:\` line for one function or whether the correction is worth implementing directly
- [ ] \`plot_learning()\` covers both plots — the per-participant facet grid and the group-level curve. One function with a \`by\` argument, or two; the per-participant version is a diagnostic and the group version is a figure, so two is defensible
- [ ] The \`scale_*_manual()\` calls are positional against the five \`type\` levels. Make them named vectors, as \`cb\` already is for colour, so adding a level cannot silently shift shapes and linetypes
- [ ] **\`facet_wrap(~stage, nrow = 1, scales = \"free_x\", space = \"free_x\")\` is wrong.** \`space\` is a \`facet_grid\` argument; \`facet_wrap\` does not take it. Either it is being silently ignored through \`...\` or it errors, and either way the panels are not sized as intended. \`facet_grid(~ stage, scales = \"free_x\", space = \"free_x\")\` is what that line wants
- [ ] The \`cb\` palette is Okabe-Ito and is already colourblind-safe. **\`theme_catlas()\` in milestone 6 must not replace it with a green ramp** — this is the concrete case the identity note's \"do not green-ify semantic scales\" rule is about"

mk "Package the pilot analysis as a function" "scope: preprocessing,type: feature,status: needs-code" \
"The pilot analysis ends with four \`rstatix\` calls bound into one table: one-sample t-tests of \`pj_score\` and \`cw_score\` against \`mu = 0\`, each with a Cohen's d and CI.

That is the analysis. It is six lines and it is the thing CATLAS's notebook needs to call. Left as script, CATLAS will reimplement it, and the registered analysis and the pilot analysis will differ by whatever the reimplementation changes.

To do:

- [ ] One function taking a \`catlas_rawdata\` and returning the index estimates with their tests, in a tidy table
- [ ] Decide \`rstatix\` versus \`stats::t.test()\` plus a d calculation. \`rstatix\` is a convenience wrapper and adds a dependency for tidy output that four lines of \`broom\`-style tidying would also give. Not obviously wrong, but it is a dependency in the confirmatory path and deserves a sentence
- [ ] The one-sample test against \`mu = 0\` is the right test for BI3, whose null is a zero difference. Confirm it is also right for \`cw_score\`, whose scale is signed confidence and whose null under guessing may not be exactly zero — this is worth a line in the manuscript either way
- [ ] This function is what the API freeze in milestone 4 freezes. Get its signature right before then"

echo

# ------------------------------------------------------------------------------
# 4 · pre-registration support
# ------------------------------------------------------------------------------

echo "4 · \`{catlasr}\` supports the \`fba-allergy-online-02\` pre-registration"
M="4 · \`{catlasr}\` supports the \`fba-allergy-online-02\` pre-registration"

mk "Decide the \`{pwrss}\` fallback home" "scope: models,type: question" \
"The design analysis needs power machinery. \`{mathpsychr}\` was the intended home and is leaning against providing it; CATLAS has been told to plan for that support never arriving; CATLAS itself may not contain a model.

* **A \`{pwrss}\` wrapper here.** Cheap, but a wrapper around someone else's power functions is precisely what the boundary rule sends upstream
* **A direct \`{pwrss}\` call in the CATLAS analysis, no wrapper anywhere.** Honest that this is one calculation for one study

A third option, simulation-based power, is **ruled out rather than unconsidered**. Writing a data generator now means writing a theory-blind one. Instead, postpone untile the theory-informed associative models are written during the Python-to-R translation. A simulator built ahead of them would be discarded when they land.

Record the reason as well as the answer. This is the third boundary-rule case and the reasoning will become a precedent."

mk "GLMM learning checks: random slopes, and the intercept against the block-1 result" "scope: preprocessing,type: feature,status: needs-code,status: needs-vignette" \
"These are **diagnostics for the averaged indices, not a modelling programme**, and the issue closes when two questions have answers, not when the model is elegant:

1. **Are random slopes needed?** If not, the averaged indices gain credibility, because averaging assumes what the absence of slopes asserts
2. **Does the random intercept sit near the block-1 result?** If not, Beesley & Le Pelley's BI2, i.e., our primary endpoint, may be biased, and the manuscript has to say so out loud

Lightweight means lightweight: random intercepts and slopes over participants, a binomial link, nothing hierarchical beyond that.

To do:

- [ ] Fit the check models on the pilot
- [ ] Answer both questions here in plain language, with the numbers
- [ ] If the answer to (2) is bad, that is a finding and belongs in the CATLAS manuscript, not buried in a package issue. Open the CATLAS issue before closing this one
- [ ] Resist scope creep. Latent-state models of Stage 3 learning quality predicting test-phase decision tendency, decision and confidence as correlated latents, and integration with EXIT or Paskewitz & Jones (2023) are **explicitly out of scope for this manuscript**"

mk "Record that GLMMs live in \`{catlasr}\`" "scope: models,type: question" \
"A boundary-rule case inherited unresolved. \`{mathpsychr}\` is leaning against wrapping \`{lme4}\` and \`{brms}\`, and CATLAS has been told to plan for that support never arriving.

The working assumption is that GLMM code lives here and upstream help, if it comes, is a bonus.

- [ ] Write it down with the reasoning, and close
- [ ] Note the condition under which it would change: if \`{mathpsychr}\` ever does provide the wrapper, what moves and what stays"

mk "Freeze the preprocessing API at pre-registration" "scope: pkg,type: chore" \
"After the pre-registration is submitted, a change to a preprocessing function is a **deviation from the registered analysis** and has to be reported as one. Before it, the same change is ordinary development.

To do:

- [ ] Tag the commit at submission, with a tag name that says what it is
- [ ] \`NEWS.md\` entry naming the registered functions and the registration DOI or OSF link
- [ ] Decide and record what counts as a deviation
- [ ] From here, any change touching a registered function needs a \`NEWS.md\` line saying whether it changes a number"

echo

# ------------------------------------------------------------------------------
# 5 · ingests fba-allergy-online-02
# ------------------------------------------------------------------------------

echo "5 · \`{catlasr}\` ingests \`fba-allergy-online-02\`"
M="5 · \`{catlasr}\` ingests \`fba-allergy-online-02\`"

mk "Parameterise \`.fb_trial_count_range\` and delete the pilot-only halving" "scope: data,type: bug,status: needs-tests,priority: critical-path" \
"\`forward-blocking-validators.R\` lines 12–13:

\`\`\`r
.fb_trial_count_range <- c(193L, 224L)
.fb_trial_count_range <- ceiling(.fb_trial_count_range / 2) # For pilot only, change when the real run commends!
\`\`\`

is already invalid.

To do:

- [ ] Make the range an argument of \`validate_fba_rawdata()\` with the full-run value as default, so the pilot becomes the case that has to be asked for
- [ ] Delete the overwrite line
- [ ] Confirm 193–224 is right for \`-02\` against the frozen \`catlaslab\` timeline, not against the pilot. If the task changed, this changed with it
- [ ] Test both: a full-length session passes at the default, a pilot-length one fails at the default and passes with the pilot argument
- [ ] Walk the other \`.fb_*\` constants — \`.fb_min_cue_types\`, \`.fb_min_outcome_types\`, \`.fb_stage1_*_cues\`, and ask of each whether it is a fact about the paradigm or a fact about one run"

mk "\`validate_fba_rawdata()\` on the full \`-02\` bundle" "scope: data,type: feature" \
"The validator has been run at pilot scale by its author on sixteen retained participants. \`-02\` is larger, still collected through JATOS, and will contain failure modes the pilot did not: withdrawals mid-stage, browser crashes, duplicate submissions, participants who ran the task twice.

To do:

- [ ] Run as data arrive, not once at the end
- [ ] The counterbalancing check currently warns, with a note that discrepancies are expected in a pilot with an odd number of trials per stage and should not happen in the experiment proper. In \`-02\` that warning is a real signal and should probably be an error
- [ ] Confirm the stimulus-duplication check scales. It pivots the whole stimuli table long
- [ ] Report the yield of every warning branch here. A warning that fires for every participant is noise and will be ignored by the third batch
- [ ] The \`valid = FALSE\` runner path from the import script belongs in the same report: how many runners produced unparseable jsPsych data, and whether that rate differs from the pilot's"

mk "Rename \`catlas_jatos_rawdata()\` for the data type, not the platform" "scope: data,type: refactor" \
"The constructor builds a \`catlas_trials\` subclass but is named for where the bytes came from. Platform is provenance, and provenance belongs in an attribute rather than a class name. The next import route, e.g., DataPipe, a re-export, an OSF-frozen bundle, would need a parallel constructor for identical data.

To do:

- [ ] Rename the class and the constructor
- [ ] Keep provenance as an attribute, so \"did this come through JATOS\" stays answerable
- [ ] Update the import script, the predicates, and the \`print\` method
- [ ] **Timing.** This is a breaking change to a class. It lands either before the milestone-4 API freeze or after collection ends, never during
- [ ] If pulled forward, add a deprecated alias rather than a hard break"

echo

# ------------------------------------------------------------------------------
# 6 · cleanup, identity and v0.1.0
# ------------------------------------------------------------------------------

echo "6 · \`{catlasr}\` cleanup, identity and v0.1.0"
M="6 · \`{catlasr}\` cleanup, identity and v0.1.0"

mk "Precompute the stimuli vignette (it cannot build without an OSF token)" "scope: pkg,type: bug,status: cmd-check" \
"\`vignettes/stimuli-allergy-task.Rmd\` is a real vignette with a \`VignetteIndexEntry\`. Its \`data-download\` chunk retrieves stimulus images from OSF node \`2shuc\`, which is **private**, using an \`{osfr}\` PAT. Every subsequent chunk depends on that download.

To do:

- [ ] Convert to the \`.Rmd.orig\` precompute pattern: the \`.orig\` holds the live code and is knitted by hand when stimuli change; the committed \`.Rmd\` holds the output
- [ ] Commit the figures
- [ ] Record in the \`.orig\` header what must be true to re-knit: OSF contributor status, a PAT in \`.Renviron\`, the node ID
- [ ] The vignette already documents the PAT setup for readers, which is good and should stay. The point is that reading about it should not be a prerequisite for building the package
- [ ] Once closed, drop \`--no-build-vignettes\` from the CI workflow"

mk "\`theme_catlas()\` in green and black" "scope: formatting,type: feature" \
"The CATLAS identity moves from the poster's orange and black to **green and black**, with green as the cat's eyes (the gaze, which is one of the programme measures).

- Brand green is \`#3FB950\` on dark and \`#2EA043\` where the same green must also work on white. **Not** \`#00FF00\`, which reads as terminal and fails on light backgrounds
- **Do not green-ify semantic scales.** Discriminability beats brand inside a figure legend exactly as inside a label set. Brand green belongs to pkgdown chrome, the README, slides and single-series plots

**The concrete case is already in the repository.** The pilot script's learning-curve plot uses an Okabe-Ito palette — \`#D55E00\`, \`#0072B2\`, \`#CC79A7\`, \`#009E73\`, \`#000000\` named to the five contingency types. That palette is colourblind-safe and was chosen deliberately. \`theme_catlas()\` should leave it alone.

To do:

- [ ] \`theme_catlas()\`, plus a single-series colour and a discriminable discrete scale that is explicitly *not* a green ramp
- [ ] Apply it first to the literature-replication figure with the SEM ribbons. Natural first application, and the figure most likely to reach the manuscript, which makes it the right place to find out the theme does not survive a two-panel layout
- [ ] Check every colour on white and on the pkgdown dark background
- [ ] Check the discrete scale for common colour-vision deficiencies"

mk "Retire \`apa_style.R\`" "scope: formatting,type: refactor" \
"\`R/apa_style.R\` is unused APA formatting, superseded by the CATLAS visual identity.

- [ ] Read it and split it. APA *statistical reporting* helper are worth keeping and are arguably \`{mathpsychr}\`'s. APA *visual* styling is superseded by \`theme_catlas()\`
- [ ] The reporting half has a live caller waiting: the pilot analysis function's output table has to be formatted for the manuscript by something
- [ ] Delete the visual half once \`theme_catlas()\` lands
- [ ] Find a home for the reporting half or delete it and say so. \`git\` remembers
- [ ] Do not leave it as-is with a comment saying it is unused"

mk "Configure pkgdown" "scope: formatting,type: docs" \
"- [ ] \`usethis::use_pkgdown()\`, \`_pkgdown.yml\` committed
- [ ] Reference index organised by subsystem: rawdata, preprocessing, stimuli, \`caphe\`
- [ ] The vignette precompute closes first. pkgdown cannot render an article whose source needs a private OSF token
- [ ] Green and black chrome. This is where brand green is unambiguously correct, unlike inside a figure
- [ ] GitHub Pages, or not
- [ ] Every \`\\link{}\` resolving"

mk "Record the orange-to-green identity change, dated" "scope: formatting,type: docs" \
"The OSF poster stays public in orange and black. Everything from here is green and black.

- [ ] One line, with a date, in \`NEWS.md\` or the README
- [ ] Note the poster explicitly, so the discrepancy is pre-explained rather than discovered cold"

mk "Clear the \`status: needs-*\` backlog before \`v0.1.0\`" "scope: pkg,type: docs,status: needs-example,status: needs-vignette" \
"Four \`status: needs-*\` labels exist because each names a gap that recurs rather than a task that happened once. This is the issue that empties them before the release.

\`status: needs-example\` — every exported function gets \`@examples\`.

- [ ] The export list is settled in milestone 1, so the scope is known
- [ ] Examples run against the synthetic fixture, not against pilot data. Pilot data cannot ship and OSF-backed examples cannot run on CI
- [ ] \`\\dontrun{}\` only where the example genuinely cannot run. An example wrapped in \`\\dontrun{}\` is not checked and will rot

\`status: needs-vignette\`: three pieces of methodology in this roadmap are load-bearing for the manuscript: the blocking-index definitions and the block/trial-type identity, the exclusion rules and their yield on the pilot, and what the GLMM checks concluded.

- [ ] Decide whether that is one vignette or three
- [ ] It must build without an OSF token, per the vignette-precompute issue in this milestone
- [ ] Whatever CATLAS's methods section says and this vignette says must not diverge

\`status: needs-tests\` and \`status: cmd-check\` are cleared by the issues that carry them, not here.

- [ ] Close every open issue carrying a \`needs-*\` label as part of this, or say in the issue why it stays open past the release"

mk "\`R CMD check\` clean, \`NEWS.md\`, and the \`v0.1.0\` tag" "scope: pkg,type: chore,status: cmd-check" \
"- [ ] \`R CMD check\` with zero errors, zero warnings and zero notes, on a clean machine, with vignettes built
- [ ] \`NEWS.md\` from the first commit forward. It need not be complete, but it must be honest about what changed between the registration freeze and the release, because that interval is where deviations live
- [ ] The version number from the ladder decision in milestone 1
- [ ] A release checklist covering what must be true, not what must be typed: exports stable, pre-registration link present, deviation log reconciled against \`NEWS.md\`
- [ ] Tag, release, and archive on OSF or Zenodo so the manuscript cites a DOI rather than a branch"

echo

# ------------------------------------------------------------------------------
# 7 · Placeholder: caphe
# ------------------------------------------------------------------------------

echo "7 · Placeholder: \`caphe\`, the CATLAS phenomena library"
M="7 · Placeholder: \`caphe\`, the CATLAS phenomena library"

mk "\`catlas_phenomena.csv\` as the manifest over the JSON corpus" "scope: caphe,type: feature" \
"X studies × Y phenomenon flags. Read alongside the JSON architecture in #11, this file's role is the **manifest**: the coverage index over the corpus, cheap to grep, regenerable from the JSONs, and the thing that answers \"which studies show highlighting?\" without downloading anything.

To do:

- [ ] Decide whether the manifest is authored or generated. Generated from the JSONs is the only version that cannot drift, and it makes the CSV a build artefact rather than a source
- [ ] Separate study *type* from phenomenon *coverage*
- [ ] Decide whether a flag means \"demonstrated\", \"tested\", \"simulated\" or \"discussed\". Four claims currently share one \`TRUE\`
- [ ] Validate that every \`bibtex\` key resolves in \`catlas.bib\` and every JSON has a manifest row"

mk "Encode \`vandorpe2006.json\` and harmonise with \`bott2007.json\`" "scope: caphe,type: chore" \
"A hand-prepared draft exists alongside the PDFs.

To do:

- [ ] Encode from the draft and the PDF together
- [ ] Harmonise the two schemas. Where they disagree?
- [ ] Every statistic checked against the paper
- [ ] Where the two force a schema change, apply it to \`bott2007.json\` in the same sitting"

mk "Delete \`fb_designs\` and \`fb_effects\`" "scope: caphe,type: refactor" \
"\`R/datasets-forward-blocking.R\` documents two bundled datasets built by \`data-raw/forward-blocking-literature.R\` from two semicolon-delimited CSVs. Superseded by the JSON corpus.

To do:

- [ ] Delete \`R/datasets-forward-blocking.R\`, \`data-raw/forward-blocking-literature.R\`, the two \`.rda\` files under \`data/\`, the two source CSVs under \`data-raw/\`, and \`LazyData: true\` from \`DESCRIPTION\` if nothing else needs it
- [ ] One commit, with the file list in the message, so \`git log\` answers \"where did \`fb_effects\` go\" without archaeology
- [ ] Check whether \`{lifecycle}\` is still used anywhere after this. \`R/catlasr-package.R\` carries \`@importFrom lifecycle deprecated\`; if nothing else needs it, it leaves \`Imports:\` with them"

mk "An in-package JSON stub for offline testing" "scope: caphe,type: test,status: needs-code" \
"The corpus lives on OSF, so every test of the \`caphe\` logic layer would otherwise need a network and a token. To overcome this, include small stub as data to directly.

To do:

- [ ] One small, complete, valid study record in \`inst/extdata/\`
- [ ] It must exercise the awkward parts: the \`factors\` object, a \`null\` wildcard, a hierarchical \`values\` nesting, an array-typed \`effect_sizes\`. A stub covering only the simple path tests nothing worth testing
- [ ] Every constructor and validator test runs against it, with the OSF path tested separately and skipped on CI
- [ ] Derive it from \`bott2007.json\` rather than inventing it, so it stays honest about the shape of a real record"

echo

# ------------------------------------------------------------------------------
# Placeholder: unscheduled tasks
# ------------------------------------------------------------------------------

echo "Placeholder: unscheduled tasks"
M="Placeholder: unscheduled tasks"

mk "Placeholder: the attention-model strand is not scheduled" "scope: models,type: feature,priority: long-lead" \
"**Do not start.** This issue exists so the milestone is visible in issue lists rather than sitting at zero items.

What is true today:

* The models exist in Python and the translation to R lands here, by the boundary rule: they are theory-dependent and catlas-specific, which is what this repository is for
* It is **explicitly out of scope for the \`fba-allergy-online-02\` manuscript**
* The GLMM checks in milestone 4 are *diagnostics*, not the first instalment of this strand
* \`fba-[alt]-eye-01\`, the eye-tracking study, is a second planned manuscript and is also not here

Close this and replace it with real issues when that decision is taken."

mk "Optional: decide whether meta-d' has a home at all" "scope: preprocessing,type: question,priority: long-lead" \
"\`score_meta_d()\` calls \`metaSDT::fit_meta_d_MLE()\`. \`metaSDT\` is GitHub-only, does not install on current R and is being removed from \`Imports:\` in milestone 1. The pilot analysis never calls it.

Three outcomes, in order of preference:

* **A maintained implementation already on CRAN.** Look before deciding anything else. If one exists, wire it in behind \`Suggests:\` and \`rlang::check_installed()\`
* **Drop it.** Delete \`score_meta_d()\` and \`.make_rating_counts()\`, note it in \`NEWS.md\` and stop carrying a function that looks available and is not
* **\`{mathpsychr}\`.** A meta-d' MLE is something the study after \`-02\` could call unmodified, which is the boundary rule's criterion

To do:

- [ ] Search CRAN. \`psycho\`, \`metaSDT\` forks, and the Fleming toolbox ports are the places to start
- [ ] If nothing maintained exists, take the second option and close this as a deletion
- [ ] Whichever way it goes, remove the dead \`metaSDT\` roxygen from \`forward-blocking-preprocessing.R\`
- [ ] Do not open this before milestone 5 closes"

echo
echo "Done."
echo
echo "Milestones:"
gh api "repos/${REPO}/milestones?state=all&per_page=100" \
--jq '.[] | "  \(.state == "open" | if . then "o" else "x" end)  \(.due_on[0:10] // "no date")  \(.title)  [\(.open_issues) open, \(.closed_issues) closed]"' \
2>/dev/null | sort -k3
