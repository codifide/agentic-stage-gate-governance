#!/usr/bin/env bash
# SGL Harness — immutable-path CI check (backstop for the write guard). Fails closed.
#
# Fails if the branch's diff against BASE touches any path listed in
# .sgl/immutable-paths (as of BASE, so a branch cannot loosen its own list).
#
# Run it on EVERY pull request. A legitimate verifier/fixture/baseline change
# passes only when a human-controlled workflow sets
#   SGL_VERIFIER_CHANGE_APPROVED_BY="<Human Steward name>"
# (e.g., from a PR label that only the Steward can apply, backed by CODEOWNERS
# on the protected paths). The approval is printed into the CI log.
#
# Set SGL_REQUIRE_IMMUTABLE_LIST=1 once the repo has adopted a list, so a missing
# list on the base branch fails closed instead of passing.
#
# Usage:  check-immutable-paths.sh [BASE_REF]      (default: origin/main)
# Exit 0 = clean or approved, 1 = immutable path touched, 2 = setup/git error.

set -uo pipefail

die() { echo "SGL immutable-paths: ERROR: $*" >&2; exit 2; }

BASE="${1:-${SGL_BASE:-origin/main}}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo"
cd "$ROOT" || die "cannot cd to repo root"
git rev-parse --verify --quiet "$BASE" >/dev/null || die "base ref '$BASE' not found"

# Read the list from BASE, not from the branch under test.
if ! git cat-file -e "$BASE:.sgl/immutable-paths" 2>/dev/null; then
  if [[ "${SGL_REQUIRE_IMMUTABLE_LIST:-0}" == "1" ]]; then
    die "no .sgl/immutable-paths on $BASE but SGL_REQUIRE_IMMUTABLE_LIST=1 (fail closed)"
  fi
  echo "SGL immutable-paths: WARNING: no .sgl/immutable-paths on $BASE; nothing is protected yet."
  exit 0
fi
LIST_CONTENT="$(git show "$BASE:.sgl/immutable-paths")" || die "cannot read .sgl/immutable-paths from $BASE"

PATTERNS=(".sgl/immutable-paths")
EXCEPTIONS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ "$line" == !* ]]; then EXCEPTIONS+=("${line#!}"); elif [[ -n "$line" ]]; then PATTERNS+=("$line"); fi
done <<< "$LIST_CONTENT"

matches() {
  local rel="$1" pat="$2"
  if [[ "$pat" == */ ]]; then
    [[ "$rel" == "$pat"* ]] && return 0
  fi
  # shellcheck disable=SC2053
  [[ "$rel" == $pat ]] && return 0
  return 1
}

# --no-renames lists both sides of a rename, so moving a verifier is caught.
CHANGED="$(git diff --name-only --no-renames "$BASE"...HEAD)" || die "git diff failed"

VIOLATIONS=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  excepted=0
  for ex in "${EXCEPTIONS[@]+"${EXCEPTIONS[@]}"}"; do
    if [[ "$f" != ".sgl/immutable-paths" ]] && matches "$f" "$ex"; then excepted=1; break; fi
  done
  (( excepted )) && continue
  for pat in "${PATTERNS[@]}"; do
    if matches "$f" "$pat"; then
      VIOLATIONS+=("$f  (pattern: $pat)")
      break
    fi
  done
done <<< "$CHANGED"

if (( ${#VIOLATIONS[@]} == 0 )); then
  echo "SGL immutable-paths: PASS. No immutable paths touched relative to $BASE."
  exit 0
fi

if [[ -n "${SGL_VERIFIER_CHANGE_APPROVED_BY:-}" ]]; then
  echo "SGL immutable-paths: APPROVED verifier change by Human Steward '${SGL_VERIFIER_CHANGE_APPROVED_BY}':"
  printf '  - %s\n' "${VIOLATIONS[@]}"
  exit 0
fi

echo "SGL immutable-paths: FAIL. This branch modifies immutable paths:"
printf '  - %s\n' "${VIOLATIONS[@]}"
echo "Verifier, fixture, and baseline changes must be separate, Human Steward-approved changes."
exit 1
