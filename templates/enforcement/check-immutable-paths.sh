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
# Matching is case-insensitive (case-insensitive checkouts) and Unicode-alias aware (a non-ASCII
# path is also matched in its NFC and NFD forms; without python3 such a path is reported, fail closed), directory patterns match
# the directory entry itself, and a symlink added or changed in the diff whose target
# resolves into a protected path is reported. The target is followed through the HEAD
# tree across any number of symlink hops (a loop or more than 40 hops is a violation).
# Any change under the enforcement paths listed above is reported even when the list does
# not name it, so an enforcer edit can never ride on a verifier-only approval. File names
# are read NUL-delimited, so newlines and spaces in names cannot hide a path.
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

# Split $1 on "/" into the array SP (newlines and spaces stay inside a component).
SP=()
split_path() {
  local oldifs="$IFS"
  IFS='/'; set -f
  # shellcheck disable=SC2206
  SP=( $1 )
  set +f; IFS="$oldifs"
}
# Resolve a repo-relative path inside the HEAD tree, one component at a time, following
# every symlink (any number of hops, directory symlinks included) and applying ".." to
# the real parent. Prints the resolved path; prints nothing when the path leaves the
# repository (absolute target or too many ".."). Returns 1 on a loop or more than 40
# expansions, which the caller reports as a violation (fail closed).
tree_resolve() {
  local cur="" hops=0 i comp next line m rest sha t j spec real ent en
  local q=() nq=()
  split_path "$1"; q=( ${SP[@]+"${SP[@]}"} )
  i=0
  while (( i < ${#q[@]} )); do
    comp="${q[i]}"
    case "$comp" in
      ''|'.') i=$((i+1)); continue ;;
      '..') [[ -z "$cur" ]] && return 0
            if [[ "$cur" == */* ]]; then cur="${cur%/*}"; else cur=""; fi
            i=$((i+1)); continue ;;
    esac
    # Look the component up among the entries of the (already resolved) parent tree,
    # case-insensitively: on a case-insensitive checkout "SRC/bridge" IS "src/bridge".
    # If both cases exist, a symlink wins (fail closed).
    if [[ -z "$cur" ]]; then spec="HEAD"; else spec="HEAD:$cur"; fi
    line=""; real="$comp"
    while IFS= read -r -d '' ent; do
      en="${ent#*$'\t'}"
      if [[ "$en" == "$comp" ]]; then
        if [[ -z "$line" || "${ent%% *}" == "120000" ]]; then line="$ent"; real="$en"; fi
      fi
    done < <(git ls-tree -z "$spec" 2>/dev/null)
    next="${cur:+$cur/}$real"
    m="${line%% *}"
    if [[ "$m" == "120000" ]]; then
      hops=$((hops+1)); (( hops > 40 )) && return 1
      rest="${line#* }"; rest="${rest#* }"; sha="${rest%%$'\t'*}"
      t="$(git cat-file blob "$sha" 2>/dev/null; printf x)"; t="${t%x}"
      [[ "$t" == /* ]] && return 0
      split_path "$t"; nq=( ${SP[@]+"${SP[@]}"} )
      for ((j=i+1; j<${#q[@]}; j++)); do nq+=("${q[j]}"); done
      q=( ${nq[@]+"${nq[@]}"} ); i=0
      continue
    fi
    cur="$next"; i=$((i+1))
  done
  printf '%s' "$cur"
}
# Unicode aliases: APFS/HFS+ and Windows treat the NFC and NFD spellings of a name as one file,
# and git on Linux stores whichever bytes it is given. A non-ASCII path is therefore also
# matched in both normalisation forms. Needs python3 (without it a non-ASCII path fails closed).
uni_forms() { # $1 = path; prints the NFC and NFD forms, NUL-delimited
  command -v python3 >/dev/null 2>&1 || return 1
  python3 -c '
import sys, unicodedata
s = sys.argv[1].encode("utf-8", "surrogateescape").decode("utf-8", "surrogateescape")
for f in ("NFC", "NFD"):
    sys.stdout.buffer.write(unicodedata.normalize(f, s).encode("utf-8", "surrogateescape") + b"\0")
' "$1"
}
pattern_for() { # $1 = path; echoes the matching pattern, also trying its NFC/NFD forms
  local f="$1" r form
  r="$(pattern_for_one "$f")"
  if [[ -n "$r" ]]; then printf '%s' "$r"; return 0; fi
  if [[ -n "$f" && "$(printf '%s' "$f" | LC_ALL=C tr -d '\000-\177')" != "" ]]; then
    if ! command -v python3 >/dev/null 2>&1; then printf '%s' "(non-ASCII path, python3 missing: Unicode aliases cannot be ruled out)"; return 0; fi
    while IFS= read -r -d '' form; do
      [[ "$form" == "$f" ]] && continue
      r="$(pattern_for_one "$form")"
      if [[ -n "$r" ]]; then printf '%s' "$r"; return 0; fi
    done < <(uni_forms "$f")
  fi
  return 0
}
pattern_for_one() { # $1 = repo-relative path; echoes the matching pattern (nothing if none or excepted)
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
add_violation() { # $1 = path, $2 = pattern, $3 = note, $4 = path that decides the class (default $1)
  local line="$1  (pattern: $2)${3:+ $3}"
  if is_enforcer "${4:-$1}" || is_enforcer "$1"; then ENF+=("$line"); else VER+=("$line"); fi
}
while IFS= read -r -d '' meta && IFS= read -r -d '' f; do
  [[ -z "$f" ]] && continue
  pat="$(pattern_for "$f")"
  if [[ -n "$pat" ]]; then add_violation "$f" "$pat" ""
  elif is_enforcer "$f"; then ENF+=("$f  (enforcement mechanism; not named in the list)"); fi
  # Symlink added or changed: does its target, followed through the HEAD tree, land in a protected path?
  read -r _om nm _os ns _st <<< "${meta#:}"
  if [[ "$nm" == "120000" ]]; then
    target="$(git cat-file blob "$ns" 2>/dev/null; printf x)"; target="${target%x}"
    case "$target" in
      /*) tn=""; rc=0 ;;
      *)  d="$f"; if [[ "$d" == */* ]]; then d="${d%/*}"; else d=""; fi
          tn="$(tree_resolve "${d:+$d/}$target")"; rc=$? ;;
    esac
    if (( rc != 0 )); then
      add_violation "$f" "(symlink chain)" "[symlink loop or more than 40 hops; cannot prove it avoids protected paths]"
    elif [[ -n "$tn" ]]; then
      tpat="$(pattern_for "$tn")"
      if [[ -n "$tpat" ]]; then add_violation "$f" "$tpat" "[symlink into protected path '$tn']" "$tn"
      elif is_enforcer "$tn"; then ENF+=("$f  [symlink into enforcement mechanism '$tn']"); fi
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
