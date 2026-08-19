#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Labels for josefmana/catlasr, the R package carrying data import,
# preprocessing, models and visual identity for the CATLAS project.
#
# Run this before .github/setup-roadmap-v1.sh: every label used there comes
# from here, and `gh issue create --label` fails on a label that does not
# exist yet.
#
# PREFIX AXES, and the rule for using them:
#
#   scope:      exactly one per issue. Which subsystem breaks if this is wrong.
#   type:       exactly one per issue. What kind of work it is.
#   status:     zero or one. Why it is not moving. Mutable.
#   priority:   zero or one. Only two values exist.
#
# COLOURS. Per the CATLAS identity note, discriminability beats brand inside a
# label set exactly as it does inside a figure legend, so the brand green
# `#3FB950` appears on no label in this file. Colour carries the axis, not the
# value:
#
#   scope:     saturated, one hue each, mutually distinguishable
#   type:      pale, a single washed family, so type never competes with scope
#   status:    warm, the only alarming colours in the set
#   priority:  black and near-white, the loudest and the quietest labels
#
# Usage:
#   bash .github/setup-labels-v1.sh
#   DRY_RUN=1 bash .github/setup-labels-v1.sh   # print only
#
# Re-runs are no-ops: labels are matched by name and patched.

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

# Fetch the current label list once. Every helper below reads this variable
# rather than calling gh again, so the script makes one read and N writes.
EXISTING="$(gh label list --repo "${REPO}" --limit 300 --json name --jq '.[].name' 2>/dev/null)"

has_label() { printf '%s\n' "${EXISTING}" | grep -Fxq "$1"; }

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

# lbl <name> <hex colour, no #> <description>
# Creates the label, or patches its colour and description if it exists.
# Never deletes and never reassigns: `gh label edit` preserves every issue
# the label is already on, which `create`-after-`delete` does not.
lbl() {
  local name="$1" color="$2" desc="$3"
  if has_label "${name}"; then
    run gh label edit "${name}" --repo "${REPO}" \
      --color "${color}" --description "${desc}" >/dev/null \
      && echo "  = ${name}"
  else
    run gh label create "${name}" --repo "${REPO}" \
      --color "${color}" --description "${desc}" >/dev/null \
      && echo "  + ${name}"
  fi
}

# ren <old name> <new name>
# Renames in place, which carries every existing assignment across. Skips if
# the old name is absent, and refuses if the new name already exists, because
# GitHub has no merge and the result would be two labels where one was meant.
ren() {
  local old="$1" new="$2"
  if ! has_label "${old}"; then
    return 0
  fi
  if has_label "${new}"; then
    echo "  ! cannot rename ${old} -> ${new}: both exist. Merge by hand." >&2
    return 0
  fi
  run gh label edit "${old}" --repo "${REPO}" --new-name "${new}" >/dev/null \
    && echo "  ~ ${old} -> ${new}"
}

# ------------------------------------------------------------------------------
# 0 · Migration of whatever is already there
# ------------------------------------------------------------------------------
#
# THIS SECTION IS EMPTY ON PURPOSE, having been checked against the repository
# rather than left unwritten.
#
# The twelve labels already on josefmana/catlasr are:
#
#   scope: data          scope: formatting    scope: models      scope: stimuli
#   status: blocked      status: cmd-check    status: needs-example
#   type: bug            type: docs           type: feature
#   type: question       type: refactor
#
# Every one of them is kept. None is renamed. The taxonomy below adds seven and
# changes nothing, because the existing vocabulary is missing labels rather than
# carrying wrong ones.

echo "0 · Migration"
echo "  . nothing to migrate: twelve existing labels are kept unchanged"
echo

# ------------------------------------------------------------------------------
# 1 · scope: which subsystem breaks if this is wrong
# ------------------------------------------------------------------------------

echo "1 · scope:"

lbl "scope:data"           "1F6FEB" \
  "Rawdata containers, constructors, validators, JATOS import"
lbl "scope:preprocessing"  "8957E5" \
  "Blocking indices, meta-d', exclusions, learning summaries"
lbl "scope:stims"          "DB61A2" \
  "Stimulus construction and rendering"
lbl "scope:caphe"          "BF8700" \
  "CATLAS phenomena library: the JSON corpus and its logic layer"
lbl "scope:models"         "1B7C83" \
  "Learning-model interfaces, design analysis, implication tests"
lbl "scope:viz"            "7C4A21" \
  "ggplot theme, figures, pkgdown, CATLAS visual identity"
lbl "scope:pkg"            "57606A" \
  "DESCRIPTION, NAMESPACE, tests, CI, releases"

echo

# ------------------------------------------------------------------------------
# 2 · type: what kind of work this is
# ------------------------------------------------------------------------------

echo "2 · type:"

lbl "type: feature"   "C2D5E8" "New capability"
lbl "type: bug"       "E8C2C2" "Something broken"
lbl "type: refactor"  "D6D3E8" "Internal restructuring, no behaviour change"
lbl "type: docs"      "D8E8C2" "Roxygen, README, vignettes"
lbl "type: test"      "C2E8E4" "Fixtures, testthat, verification against real data"
lbl "type: question"  "E8DFC2" "Unresolved design decision"
lbl "type: chore"     "DCDCDC" "Migration, hygiene, release mechanics"

echo

# ------------------------------------------------------------------------------
# 3 · status: why this is not moving
# ------------------------------------------------------------------------------

echo "3 · status:"

lbl "status: blocked"        "D93F0B" \
  "Waiting on external dependency"
lbl "status: cmd-check"      "6E7781" \
  "R CMD CHECK issue"
lbl "status: needs-code"     "6E7781" \
  "Code to resolve this issue is yet to be written"
lbl "status: needs-example"  "6E7781" \
  "Missing @examples in roxygen"
lbl "status: needs-tests"    "6E7781" \
  "Unit tests absent or insufficient"
lbl "status: needs-vignette" "6E7781" \
  "Methodology warrants a long-form vignette"

echo

# ------------------------------------------------------------------------------
# 4 · priority: the two things the milestone ordinal cannot say
# ------------------------------------------------------------------------------

echo "4 · priority:"

lbl "priority: critical-path" "111111" \
  "Something downstream of this repository is idle until it closes"
lbl "priority: long-lead"     "EEEEEE" \
  "Do not start. Present so the strand is visible rather than forgotten"

echo

# If more than about eight open issues carry `priority:critical-path` it has
# stopped discriminating and should be pruned back to the ones where a named
# person in a named repository is genuinely waiting.

echo "Done."
echo
echo "Labels:"
gh label list --repo "${REPO}" --limit 300 2>/dev/null
