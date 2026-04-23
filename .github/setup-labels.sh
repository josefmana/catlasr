#!/usr/bin/env bash
REPO="josefmana/catlasr"

# ── Scope labels ─────────────────────────────────────────────────
gh label create "scope: stimuli"    --color "0075ca" --description "Stimulus generation and rendering" --repo $REPO
gh label create "scope: formatting" --color "0075ca" --description "Visual identity" --repo $REPO
gh label create "scope: data"       --color "0075ca" --description "Bundled experimental design datasets" --repo $REPO
gh label create "scope: models"     --color "0075ca" --description "Theory-dependent model code" --repo $REPO

# ── Type labels ──────────────────────────────────────────────────
gh label create "type: bug"         --color "d73a4a" --description "Something broken" --repo $REPO
gh label create "type: feature"     --color "a2eeef" --description "New capability" --repo $REPO
gh label create "type: docs"        --color "cfd3d7" --description "Roxygen, README, vignettes" --repo $REPO
gh label create "type: question"    --color "d876e3" --description "Unresolved design decision" --repo $REPO
gh label create "type: refactor"    --color "e4e669" --description "Internal restructuring, no behaviour change" --repo $REPO

# ── Status labels ────────────────────────────────────────────────
gh label create "status: blocked"        --color "b60205" --description "Waiting on external dependency" --repo $REPO
gh label create "status: cmd-check"      --color "f9d0c4" --description "R CMD CHECK issue" --repo $REPO
gh label create "status: needs-example" --color "f9d0c4" --description "Missing @examples in roxygen" --repo $REPO

# ── Milestones ───────────────────────────────────────────────────
# Package lifecycle
gh api repos/$REPO/milestones --method POST -f title="v0.1.0: forward-blocking-online-replication support"
gh api repos/$REPO/milestones --method POST -f title="v0.2.0: forward-blocking-extension support"

# Functional milestones (cross-cutting)
gh api repos/$REPO/milestones --method POST -f title="stimuli: class and renderers complete"
gh api repos/$REPO/milestones --method POST -f title="formatting: visual identity complete"

# ── Remove GitHub defaults ───────────────────────────────────────
for label in "bug" "documentation" "duplicate" "enhancement" "good first issue" "help wanted" "invalid" "question" "wontfix"; do
  gh label delete "$label" --repo $REPO --yes 2>/dev/null
done

echo "Done."
