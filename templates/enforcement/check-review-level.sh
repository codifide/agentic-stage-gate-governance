#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness — Review Level + provenance check (CI). Fails closed.
#
# For EVERY commit on the branch (BASE..HEAD):
#   - requires a valid `Generated-By:` trailer (human | ai-agent | ai-assisted | ai-paired)
#   - requires a `Review-Level: R1|R2|R3` trailer
#   - computes that commit's floor from the files it touches and its provenance,
#     and fails if the commit declares a lower level
#   - fails if a non-human commit ADDS a human-approval marker
#     (SILENT-CATCH-APPROVED, COVERAGE-EXCEPTION ... approved)
# For the branch as a whole:
#   - applies the size rule (> 500 changed lines across > 5 files = R3) against
#     the highest level declared on the branch (the PR is reviewed as a unit)
#
# Floors (steering/11-tiered-adversarial-review.md):
#   Governance files (the harness itself, hooks, .codifide/, CI workflows, CODEOWNERS)
#   are R3: editing the rules is the highest-risk change there is.
#   R1 is allowed ONLY for files on the R1 allowlist (tests, docs, styles).
#   Any other file is at least R2 ("anything not clearly covered -> R2"), which
#   covers auth/data-access/API changes that live outside conventional folders.
#   R3 paths, and any non-human change to auth/crypto/permissions paths, are R3.
#   NOT computed here (the agent and reviewers apply them and can only RAISE):
#   rule 2 outside conventional auth/crypto paths, 3 (new architecture),
#   5 (compliance), 6 (AI-infrastructure dependencies), 7 (behavior outside an
#   approved design), 14 (failed an automated check before passing).
#   Merge commits are checked on their conflict resolutions (git diff-tree --cc); a root commit
#   (an orphan history merged in) is checked against the empty tree (--root).
#   If the PR as a whole trips the size rule, EVERY commit must declare the size floor.
#
# What this does NOT prove (documented limits, see templates/enforcement/README.md):
#   - Generated-By is SELF-ASSERTED. An agent can write "human". Compensating controls
#     live outside this script: signed commits, a separate bot identity for agents,
#     required CODEOWNERS review on sensitive paths.
#   - A Review-Level of R3 is a declaration, not evidence that a review happened. No
#     script reads a review artifact or checks reviewer independence.
#   - Floors come from path globs, which are a convention. Files named *.test.* or
#     under tests/ are treated as tests whatever they contain.
#   Matching is case-insensitive. File names are read NUL-delimited (newlines in names
#   cannot hide a path). Binary files cannot be line-counted, so each counts as 100
#   changed lines toward the size rule.
#
# Waiver (the only one): rule 8's mechanical-refactor exception. With
#   CODIFIDE_WAIVE=size  and  CODIFIDE_STEWARD="<name>"  (set by a human-controlled
#   workflow, e.g. a label only the Human Steward can apply), the size rule
#   contributes R2 instead of R3. All other floors cannot be lowered here.
#
# Usage:  check-review-level.sh [BASE_REF]      (default: origin/main)
# Exit 0 = pass, 1 = policy failure, 2 = setup/git error (fail closed).

set -uo pipefail

die() { echo "Codifide review-level: ERROR: $*" >&2; exit 2; }

BASE="${1:-${CODIFIDE_BASE:-origin/main}}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo"
cd "$ROOT" || die "cannot cd to repo root"
git rev-parse --verify --quiet "$BASE" >/dev/null || die "base ref '$BASE' not found"

if [[ -n "${CODIFIDE_WAIVE:-}" ]]; then
  [[ "$CODIFIDE_WAIVE" == "size" ]] || die "CODIFIDE_WAIVE supports only 'size' (rule 8 mechanical refactor)"
  [[ -n "${CODIFIDE_STEWARD:-}" ]] || die "CODIFIDE_WAIVE requires CODIFIDE_STEWARD (the approving human)"
fi

# Handoff file is written every session; it is data, not rules (00-welcome.md section 7).
HANDOFF_EXEMPT=('*/.kiro/steering/next-session-prompt.md')
GOVERNANCE_GLOBS=('*/.kiro/*' '*/.codifide/*' '*/steering/*' '*/.github/workflows/*' '*/CODEOWNERS' '*/templates/enforcement/*'
                  '*/templates/B-TEAM-REVIEW-PACKAGE.md' '*/templates/CODE-REVIEW-PROMPT-*' '*/templates/GATE-EVIDENCE-CHECKLIST.md'
                  '*/templates/HOOKS-SESSION-STATE.md' '*/templates/INTENT-CONTRACT.md' '*/templates/NFR-TEMPLATE.md'
                  '*/templates/EXISTING-PROJECT-ASSESSMENT.md')
# Docs are allowed at R1 only by DOCUMENT extension: docs/login.ts is code, not documentation.
R1_ALLOW=('*/tests/*' '*/test/*' '*/__tests__/*' '*.test.*' '*.spec.*' '*.md' '*.css' '*.scss' '*/styles/*'
          '*/docs/*.md' '*/docs/*.txt' '*/docs/*.rst' '*/docs/*.adoc' '*/docs/*.png' '*/docs/*.jpg' '*/docs/*.gif' '*/docs/*.svg')
R3_GLOBS=('*/crypto/*' '*/encryption/*' '*/keys/*' '*/certs/*' '*/certificates/*' '*/tls/*' '*/secrets/*'
          '*.pem' '*.key' '*.crt' '*.p12' '*/infrastructure/prod*' '*/terraform/*prod*'
          '*/migrations/*' '*/migrate/*' '*/db/migrate*' '*.iac.*' '*/docker-compose.prod.yml'
          '*/alembic/*' '*/prisma/*' '*/flyway/*' '*/liquibase/*' '*/db/schema*' '*/schema.sql' '*/terraform/*' '*.tf' '*.tfvars')
SENSITIVE_GLOBS=('*/auth/*' '*/authz/*' '*/permissions/*' '*/crypto/*' '*/encryption/*' '*/keys/*'
                 '*/middleware/*' '*/middleware.*' '*/session*' '*/oauth*' '*/jwt*' '*/password*' '*/login*'
                 '*/rbac/*' '*/acl/*' '*/iam/*' '*/policies/*' '*/security/*')

glob_any() { # $1 = path with leading slash; rest = globs
  local p="$1"; shift
  local g rc=1
  shopt -s nocasematch   # case-insensitive checkouts: Src/Auth/x.ts is src/auth/x.ts
  for g in "$@"; do
    # shellcheck disable=SC2053
    if [[ "$p" == $g ]]; then rc=0; break; fi
  done
  shopt -u nocasematch
  return $rc
}

COMMITS="$(git rev-list --reverse "$BASE"..HEAD)" || die "git rev-list failed"
[[ -z "$COMMITS" ]] && { echo "Codifide review-level: no commits on branch."; exit 0; }

# Branch-level size rule, computed first so every commit can be held to it.
NUMSTAT="$(git diff --numstat --no-renames "$BASE"...HEAD)" || die "git diff failed"
NFILES=$(printf '%s\n' "$NUMSTAT" | grep -c .)
# Binary files show "-" in numstat; count each as 100 lines so they cannot dodge the size rule.
LINES=$(printf '%s\n' "$NUMSTAT" | awk '$1 ~ /^[0-9]+$/ {a+=$1; d+=$2} $1 == "-" {b+=100} END {print a+d+b+0}')
SIZE_FLOOR=1
if (( LINES > 500 && NFILES > 5 )); then
  SIZE_FLOOR=3
  if [[ "${CODIFIDE_WAIVE:-}" == "size" ]]; then
    SIZE_FLOOR=2
    echo "  size: mechanical-refactor waiver recorded for Human Steward '${CODIFIDE_STEWARD}' (size floor R2)"
  fi
  echo "  size: PR changes $LINES lines across $NFILES files; every commit must declare at least R$SIZE_FLOOR"
fi

FILELIST="$(mktemp)" || die "mktemp failed"
trap 'rm -f "$FILELIST"' EXIT
FAILS=0
while IFS= read -r sha; do
  [[ -z "$sha" ]] && continue
  short="${sha:0:9}"
  MSG="$(git log -1 --format=%B "$sha")" || die "git log failed for $sha"
  GEN="$(printf '%s\n' "$MSG" | sed -nE 's/^Generated-By:[[:space:]]*([a-z-]+)[[:space:]]*$/\1/p' | tail -1)"
  LVL="$(printf '%s\n' "$MSG" | sed -nE 's/^Review-Level:[[:space:]]*R([123])[[:space:]]*$/\1/p' | tail -1)"

  case "$GEN" in
    human|ai-agent|ai-assisted|ai-paired) ;;
    "") echo "  $short FAIL: missing Generated-By trailer"; FAILS=$((FAILS+1)) ;;
    *)  echo "  $short FAIL: invalid Generated-By '$GEN'"; FAILS=$((FAILS+1)) ;;
  esac
  [[ -z "$LVL" ]] && { echo "  $short FAIL: missing Review-Level trailer"; FAILS=$((FAILS+1)); LVL=0; }

  # --cc: normal diff for ordinary commits; conflict resolutions / evil-merge content for merges.
  git -c core.quotepath=off diff-tree --root --cc --no-commit-id --name-only -r --no-renames -z "$sha" > "$FILELIST" || die "git diff-tree failed for $sha"
  FLOOR=1; WHY="R1 allowlist only"
  while IFS= read -r -d '' f; do
    [[ -z "$f" ]] && continue
    p="/$f"
    if glob_any "$p" "${HANDOFF_EXEMPT[@]}"; then
      continue
    elif glob_any "$p" "${GOVERNANCE_GLOBS[@]}"; then
      FLOOR=3; WHY="governance file $f"
    elif glob_any "$p" "${R3_GLOBS[@]}"; then
      FLOOR=3; WHY="R3 path $f"
    elif glob_any "$p" "${SENSITIVE_GLOBS[@]}"; then
      # Sensitive paths are never R1, whatever the file name (e.g. src/auth/login.test.ts).
      if [[ "$GEN" != "human" ]]; then FLOOR=3; WHY="non-human (${GEN:-unknown}) change to sensitive path $f"
      else (( FLOOR < 2 )) && { FLOOR=2; WHY="human change to sensitive path $f"; }; fi
    elif ! glob_any "$p" "${R1_ALLOW[@]}"; then
      (( FLOOR < 2 )) && { FLOOR=2; WHY="$f is outside the R1 allowlist"; }
    fi
  done < "$FILELIST"
  if (( SIZE_FLOOR > FLOOR )); then FLOOR=$SIZE_FLOOR; WHY="PR size rule"; fi

  # Human-approval markers may only be added by human commits.
  if [[ "$GEN" != "human" ]]; then
    # The enforcement tooling must name the markers to detect them, so its own files are
    # excluded from this scan (exact paths only, no globs). Narrow on purpose: these files are
    # on the immutable-paths list and are R3 governance files, so changing them needs the
    # Steward's approval anyway. Every other file, including product code, is still scanned.
    ADDED="$(git show --format= --unified=0 "$sha" -- . \
      ':(top,exclude).codifide/check-review-level.sh' ':(top,exclude).codifide/test-enforcement.sh' ':(top,exclude).codifide/README.md' \
      ':(top,exclude)templates/enforcement/check-review-level.sh' ':(top,exclude)templates/enforcement/test-enforcement.sh' \
      ':(top,exclude)templates/enforcement/README.md' \
      | grep -E '^\+' | grep -vE '^\+\+\+')" || true
    if printf '%s\n' "$ADDED" | grep -Eq 'SILENT-CATCH-APPROVED|COVERAGE-EXCEPTION.*[Aa]pproved'; then
      echo "  $short FAIL: non-human commit adds a human-approval marker"
      FAILS=$((FAILS+1))
    fi
  fi

  if (( LVL == 0 )); then
    echo "  $short (no level declared; floor would be R$FLOOR: $WHY)"
  elif (( LVL < FLOOR )); then
    echo "  $short FAIL: declares R$LVL, floor is R$FLOOR ($WHY)"
    FAILS=$((FAILS+1))
  else
    echo "  $short ok: declares R${LVL}, floor R$FLOOR ($WHY)"
  fi
done <<< "$COMMITS"

if (( FAILS > 0 )); then
  echo "Codifide review-level: FAIL ($FAILS problem(s)). Raise the declared level and run that review, or ask the Human Steward."
  exit 1
fi
echo "Codifide review-level: PASS."
exit 0
