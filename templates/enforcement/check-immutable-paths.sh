#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness — immutable-path CI check (backstop for the write guard). Fails closed.
#
# Fails if the branch's diff against BASE touches any path listed in
# .codifide/immutable-paths (as of BASE, so a branch cannot loosen its own list).
#
# Run it on EVERY pull request. A legitimate verifier/fixture/baseline change
# passes only when a human-controlled workflow sets
#   CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="<Human Steward name>"
# (e.g., from a PR label that only the Steward can apply, backed by CODEOWNERS
# on the protected paths). The approval is printed into the CI log.
#
# The approval is SCOPED. It does not waive changes to the enforcement mechanism
# itself: .codifide/ (scripts and the list), .github/workflows/, CODEOWNERS,
# .kiro/hooks/, .claude/settings.json. Those need a separate approval,
#   CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="<Human Steward name>"
# which the example workflow sets from a different label, so that "this PR edits a
# verifier" and "this PR edits the checks themselves" are two deliberate decisions.
# Both variables are only as strong as who can set them (label permissions,
# CODEOWNERS, branch protection); this script cannot verify that.
#
# Matching is case-insensitive (case-insensitive checkouts), directory patterns match
# the directory entry itself, and a symlink added or changed in the diff whose target
# resolves into a protected path is reported. File names are read NUL-delimited, so
# newlines and spaces in names cannot hide a path.
#
# Set CODIFIDE_REQUIRE_IMMUTABLE_LIST=1 once the repo has adopted a list, so a missing
# list on the base branch fails closed instead of passing.
#
# Usage:  check-immutable-paths.sh [BASE_REF]      (default: origin/main)
# Exit 0 = clean or approved, 1 = immutable path touched, 2 = setup/git error.

set -uo pipefail
shopt -s nocasematch

die() { echo "Codifide immutable-paths: ERROR: $*" >&2; exit 2; }

BASE="${1:-${CODIFIDE_BASE:-origin/main}}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repo"
cd "$ROOT" || die "cannot cd to repo root"
git rev-parse --verify --quiet "$BASE" >/dev/null || die "base ref '$BASE' not found"

# Read the list from BASE, not from the branch under test.
if ! git cat-file -e "$BASE:.codifide/immutable-paths" 2>/dev/null; then
  if [[ "${CODIFIDE_REQUIRE_IMMUTABLE_LIST:-0}" == "1" ]]; then
    die "no .codifide/immutable-paths on $BASE but CODIFIDE_REQUIRE_IMMUTABLE_LIST=1 (fail closed)"
  fi
  echo "Codifide immutable-paths: WARNING: no .codifide/immutable-paths on $BASE; nothing is protected yet."
  exit 0
fi
LIST_CONTENT="$(git show "$BASE:.codifide/immutable-paths")" || die "cannot read .codifide/immutable-paths from $BASE"

PATTERNS=(".codifide/immutable-paths")
EXCEPTIONS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ "$line" == !* ]]; then EXCEPTIONS+=("${line#!}"); elif [[ -n "$line" ]]; then PATTERNS+=("$line"); fi
done <<< "$LIST_CONTENT"

matches() {
  local rel="$1" pat="$2"
  if [[ "$pat" == */ ]]; then
    [[ "$rel" == "$pat"* || "$rel/" == "$pat" ]] && return 0
  fi
  # shellcheck disable=SC2053
  [[ "$rel" == $pat ]] && return 0
  return 1
}

# The enforcement mechanism itself. Changes here need the separate ENFORCER approval.
ENFORCER_PATHS=(".codifide/" ".github/workflows/" "CODEOWNERS" ".github/CODEOWNERS" ".kiro/hooks/" ".claude/settings.json")
is_enforcer() {
  local rel="$1" e
  for e in "${ENFORCER_PATHS[@]}"; do matches "$rel" "$e" && return 0; done
  return 1
}

# Lexical normalization of a repo-relative path. Prints nothing if it escapes the root.
normrel() {
  local IFS='/' part out=() parts
  read -ra parts <<< "$1"
  for part in "${parts[@]}"; do
    case "$part" in
      ''|'.') ;;
      '..') (( ${#out[@]} == 0 )) && return 0; unset 'out[${#out[@]}-1]' ;;
      *) out+=("$part") ;;
    esac
  done
  (( ${#out[@]} == 0 )) && return 0
  printf '%s' "${out[0]}"; local i; for ((i=1; i<${#out[@]}; i++)); do printf '/%s' "${out[i]}"; done
}

pattern_for() { # $1 = repo-relative path; echoes the matching pattern (nothing if none or excepted)
  local f="$1" ex pat
  for ex in "${EXCEPTIONS[@]+"${EXCEPTIONS[@]}"}"; do
    if [[ "$f" != ".codifide/immutable-paths" ]] && matches "$f" "$ex"; then return 0; fi
  done
  for pat in "${PATTERNS[@]}"; do
    if matches "$f" "$pat"; then printf '%s' "$pat"; return 0; fi
  done
}

# --raw -z: ":<mode> <mode> <sha> <sha> <status>\0<path>\0" per entry.
# --no-renames lists both sides of a rename, so moving a verifier is caught.
RAW="$(mktemp)" || die "mktemp failed"
trap 'rm -f "$RAW"' EXIT
git diff --raw -z --no-renames "$BASE"...HEAD > "$RAW" || die "git diff failed"

VER=(); ENF=()
add_violation() { # $1 = path, $2 = pattern, $3 = note
  local line="$1  (pattern: $2)${3:+ $3}"
  if is_enforcer "$1"; then ENF+=("$line"); else VER+=("$line"); fi
}
while IFS= read -r -d '' meta && IFS= read -r -d '' f; do
  [[ -z "$f" ]] && continue
  pat="$(pattern_for "$f")"
  if [[ -n "$pat" ]]; then add_violation "$f" "$pat" ""; fi
  # Symlink added or changed: does its target resolve into a protected path?
  read -r _om nm _os ns _st <<< "${meta#:}"
  if [[ "$nm" == "120000" ]]; then
    target="$(git cat-file blob "$ns" 2>/dev/null)" || target=""
    case "$target" in
      /*) tn="" ;;
      *)  d="$(dirname "$f")"; [[ "$d" == "." ]] && d=""; tn="$(normrel "${d:+$d/}$target")" ;;
    esac
    if [[ -n "$tn" ]]; then
      tpat="$(pattern_for "$tn")"
      [[ -n "$tpat" ]] && add_violation "$f" "$tpat" "[symlink into protected path '$tn']"
    fi
  fi
done < "$RAW"

if (( ${#VER[@]} + ${#ENF[@]} == 0 )); then
  echo "Codifide immutable-paths: PASS. No immutable paths touched relative to $BASE."
  exit 0
fi

FAILED=0
if (( ${#ENF[@]} > 0 )); then
  if [[ -n "${CODIFIDE_ENFORCER_CHANGE_APPROVED_BY:-}" ]]; then
    echo "Codifide immutable-paths: APPROVED enforcement-mechanism change by Human Steward '${CODIFIDE_ENFORCER_CHANGE_APPROVED_BY}':"
    printf '  - %s\n' "${ENF[@]}"
  else
    echo "Codifide immutable-paths: FAIL. This branch modifies the enforcement mechanism (needs CODIFIDE_ENFORCER_CHANGE_APPROVED_BY, not the verifier approval):"
    printf '  - %s\n' "${ENF[@]}"
    FAILED=1
  fi
fi
if (( ${#VER[@]} > 0 )); then
  if [[ -n "${CODIFIDE_VERIFIER_CHANGE_APPROVED_BY:-}" ]]; then
    echo "Codifide immutable-paths: APPROVED verifier change by Human Steward '${CODIFIDE_VERIFIER_CHANGE_APPROVED_BY}':"
    printf '  - %s\n' "${VER[@]}"
  else
    echo "Codifide immutable-paths: FAIL. This branch modifies immutable paths:"
    printf '  - %s\n' "${VER[@]}"
    FAILED=1
  fi
fi
if (( FAILED )); then
  echo "Verifier, fixture, baseline, and enforcement changes must be separate, Human Steward-approved changes."
  exit 1
fi
exit 0
