#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness — immutable-path write guard (PreToolUse command hook).
#
# Blocks agent file-write tools from touching any path listed in
# .codifide/immutable-paths (verifiers, golden fixtures, baselines, eval harness).
#
# Contract (Kiro command hooks): the tool call arrives as JSON on stdin.
#   exit 0  -> allow
#   exit 2  -> block; stderr is shown to the agent
#
# The guard does not depend on a specific tool-input schema: it inspects every
# string value in the JSON and treats it as a candidate path. Leading and trailing
# whitespace (including newlines) is trimmed before the check, because tools trim
# too. A string with an interior newline is treated as file content, not a path.
# There is NO length cutoff: a long path built from "a/../" segments is resolved
# and checked like any other. A rare false positive (a string that equals a
# protected path) blocks with a clear message; that is the intended direction.
#
# Matching is case-insensitive (default macOS and Windows filesystems treat
# Verifiers/ and verifiers/ as the same directory). On a case-sensitive
# filesystem this can over-block; that is the fail-closed direction.
#
# Hard links: a write to a file that is hard-linked to a protected file is blocked.
# This is checked with `find -samefile` under the repo root only when the target has
# more than one link.
#
# Fail closed: any unexpected non-zero exit from this script is converted to exit 2
# by the EXIT trap below. Register it as `bash <script> || exit 2` so a missing
# bash or a crash outside the script also blocks (see templates/hooks/).
#
# LIMIT (documented, not fixable in a file-write hook): shell commands are NOT
# inspected, so `printf x >> verifiers/check.py` from a shell tool is not seen.
# The CI check (check-immutable-paths.sh) is the backstop, and it only protects you
# if it is a REQUIRED status check on the protected branch. Where you can, also deny
# shell redirection into protected paths in your agent's own permission settings.
#
# Install: copy to <repo>/.codifide/guard-immutable-paths.sh, chmod +x, and register
# it as a PreToolUse hook matching your agent's write tools (see
# templates/HOOKS-SESSION-STATE.md, Hook 4).

set -uo pipefail
shopt -s nocasematch

# Any exit other than 0 (allow) or 2 (block) is an internal failure: block.
trap 'rc=$?; if [[ $rc -ne 0 && $rc -ne 2 ]]; then echo "Codifide guard: internal error (exit $rc); failing closed." >&2; exit 2; fi' EXIT

ROOT="${CODIFIDE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LIST="$ROOT/.codifide/immutable-paths"

# Nothing declared -> nothing to protect, unless the repo requires a list.
if [[ ! -f "$LIST" ]]; then
  if [[ "${CODIFIDE_REQUIRE_IMMUTABLE_LIST:-0}" == "1" ]]; then
    echo "Codifide guard: $LIST is missing but CODIFIDE_REQUIRE_IMMUTABLE_LIST=1. Blocking writes until the Human Steward restores it." >&2
    exit 2
  fi
  echo "Codifide guard: WARNING: no $LIST; nothing is protected. Create it, and set CODIFIDE_REQUIRE_IMMUTABLE_LIST=1 once adopted." >&2
  exit 0
fi

if [[ ! -r "$LIST" ]]; then
  echo "Codifide guard: $LIST exists but is not readable. Blocking writes (fail closed)." >&2
  exit 2
fi

INPUT="$(cat)"
if [[ -z "${INPUT//[[:space:]]/}" ]]; then
  echo "Codifide guard: empty tool input. Blocking write while $LIST exists (fail closed)." >&2
  exit 2
fi

if command -v jq >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s' "$INPUT" | jq -r '.. | strings | gsub("^\\s+|\\s+$"; "") | select(test("\n") | not)' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
def walk(v):
    if isinstance(v, str):
        v = v.strip()
        if "\n" not in v:
            print(v)
    elif isinstance(v, dict):
        for x in v.values(): walk(x)
    elif isinstance(v, list):
        for x in v: walk(x)
try:
    walk(json.load(sys.stdin))
except Exception:
    sys.exit(3)
')"
else
  # Security controls fail closed (00-welcome.md section 6).
  echo "Codifide guard: cannot inspect tool input (install jq or python3). Blocking write while $LIST exists." >&2
  exit 2
fi

# Unparseable input also fails closed.
if [[ $? -ne 0 ]]; then
  echo "Codifide guard: tool input was not valid JSON. Blocking write while $LIST exists." >&2
  exit 2
fi

# Load patterns (ignore blanks and comments). The list always protects itself.
PATTERNS=(".codifide/immutable-paths")
EXCEPTIONS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ "$line" == !* ]]; then EXCEPTIONS+=("${line#!}"); elif [[ -n "$line" ]]; then PATTERNS+=("$line"); fi
done < "$LIST"

matches() {
  # $1 = repo-relative path, $2 = pattern (glob, or directory ending in /)
  local rel="$1" pat="$2"
  if [[ "$pat" == */ ]]; then
    [[ "$rel" == "$pat"* || "$rel/" == "$pat" ]] && return 0
  fi
  # shellcheck disable=SC2053  # intentional glob match
  [[ "$rel" == $pat ]] && return 0
  return 1
}

# Lexically normalize an absolute path: collapse //, ".", and ".." segments.
normpath() {
  local IFS='/' part out=()
  read -ra parts <<< "$1"
  for part in "${parts[@]}"; do
    case "$part" in
      ''|'.') ;;
      '..') (( ${#out[@]} > 0 )) && unset 'out[${#out[@]}-1]' ;;
      *) out+=("$part") ;;
    esac
  done
  local joined
  joined="$(printf '/%s' "${out[@]}")"
  printf '%s' "${joined:-/}"
}

# Resolve symlinks so /var/... and /private/var/... (or any symlinked checkout)
# compare equal. Walks up to the nearest existing ancestor for new files.
canon() {
  local p suffix="" hops=0 t
  p="$(normpath "$1")"
  # Resolve a symlinked leaf (e.g., src/alias -> ../verifiers/check.py).
  while [[ -L "$p" && $hops -lt 40 ]]; do
    t="$(readlink "$p")"
    case "$t" in
      /*) p="$(normpath "$t")" ;;
      *)  p="$(normpath "$(dirname "$p")/$t")" ;;
    esac
    hops=$((hops + 1))
  done
  while [[ ! -d "$p" && "$p" != "/" && -n "$p" ]]; do
    suffix="/$(basename "$p")$suffix"
    p="$(dirname "$p")"
  done
  local base
  base="$(cd "$p" 2>/dev/null && pwd -P)"
  normpath "${base}${suffix}"
}
ROOT="$(canon "$ROOT")"

# Echo the pattern that protects repo-relative path $1 (nothing if unprotected).
protected_pattern() {
  local rel="$1" ex pat
  for ex in "${EXCEPTIONS[@]+"${EXCEPTIONS[@]}"}"; do
    if [[ "$rel" != ".codifide/immutable-paths" ]] && matches "$rel" "$ex"; then return 0; fi
  done
  for pat in "${PATTERNS[@]}"; do
    if matches "$rel" "$pat"; then printf '%s' "$pat"; return 0; fi
  done
  return 0
}

block() { # $1 = path, $2 = pattern, $3 = optional reason
  {
    echo "Codifide guard: BLOCKED write to immutable path '$1'${3:+ ($3)} (pattern '$2' in .codifide/immutable-paths)."
    echo "Verifiers, fixtures, and baselines may be read but never modified by the agent."
    echo "If this change is genuinely needed, stop and ask the Human Steward; it must be made as its own human-approved change."
  } >&2
  exit 2
}

while IFS= read -r cand; do
  [[ -z "$cand" ]] && continue
  # Every candidate is resolved: relative paths against the repo root, then
  # lexical normalization (handles foo/../verifiers/x), then symlink resolution.
  if [[ "$cand" == /* ]]; then
    abs="$(canon "$cand")"
  else
    abs="$(canon "$ROOT/$cand")"
  fi
  rel="${abs#"$ROOT"/}"
  pat="$(protected_pattern "$rel")"
  [[ -n "$pat" ]] && block "$rel" "$pat"

  # Hard links: a different name for the same inode as a protected file.
  if [[ -f "$abs" && "$abs" == "$ROOT"/* && -n "$(find "$abs" -maxdepth 0 -links +1 2>/dev/null)" ]]; then
    while IFS= read -r other; do
      [[ -z "$other" || "$other" == "$abs" ]] && continue
      orel="${other#"$ROOT"/}"
      opat="$(protected_pattern "$orel")"
      [[ -n "$opat" ]] && block "$rel" "$opat" "hard link to protected file '$orel'"
    done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -samefile "$abs" -print 2>/dev/null)
  fi
done <<< "$CANDIDATES"

exit 0
