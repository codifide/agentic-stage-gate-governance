#!/usr/bin/env bash
# SGL Harness — immutable-path write guard (PreToolUse command hook).
#
# Blocks agent file-write tools from touching any path listed in
# .sgl/immutable-paths (verifiers, golden fixtures, baselines, eval harness).
#
# Contract (Kiro command hooks): the tool call arrives as JSON on stdin.
#   exit 0  -> allow
#   exit 2  -> block; stderr is shown to the agent
#
# The guard does not depend on a specific tool-input schema: it inspects every
# single-line string value in the JSON and treats it as a candidate path.
# A rare false positive (a short single-line string that equals a protected
# path) blocks with a clear message; that is the intended failure direction.
#
# Shell commands are NOT inspected (reads like `cat verifiers/x` would be
# blocked too). The CI check (check-immutable-paths.sh) is the backstop for
# writes made through a shell.
#
# Install: copy to <repo>/.sgl/guard-immutable-paths.sh, chmod +x, and register
# it as a PreToolUse hook matching your agent's write tools (see
# templates/HOOKS-SESSION-STATE.md, Hook 4).

set -uo pipefail

ROOT="${SGL_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LIST="$ROOT/.sgl/immutable-paths"

# Nothing declared -> nothing to protect, unless the repo requires a list.
if [[ ! -f "$LIST" ]]; then
  if [[ "${SGL_REQUIRE_IMMUTABLE_LIST:-0}" == "1" ]]; then
    echo "SGL guard: $LIST is missing but SGL_REQUIRE_IMMUTABLE_LIST=1. Blocking writes until the Human Steward restores it." >&2
    exit 2
  fi
  exit 0
fi

INPUT="$(cat)"

if command -v jq >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s' "$INPUT" | jq -r '.. | strings | select((test("\n") | not) and (length < 1024))' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
def walk(v):
    if isinstance(v, str):
        if "\n" not in v and len(v) < 1024:
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
  echo "SGL guard: cannot inspect tool input (install jq or python3). Blocking write while $LIST exists." >&2
  exit 2
fi

# Unparseable input also fails closed.
if [[ $? -ne 0 ]]; then
  echo "SGL guard: tool input was not valid JSON. Blocking write while $LIST exists." >&2
  exit 2
fi

# Load patterns (ignore blanks and comments). The list always protects itself.
PATTERNS=(".sgl/immutable-paths")
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

while IFS= read -r cand; do
  [[ -z "$cand" ]] && continue
  # Every candidate is resolved: relative paths against the repo root, then
  # lexical normalization (handles foo/../verifiers/x), then symlink resolution.
  if [[ "$cand" == /* ]]; then
    rel="$(canon "$cand")"
  else
    rel="$(canon "$ROOT/$cand")"
  fi
  rel="${rel#"$ROOT"/}"
  excepted=0
  for ex in "${EXCEPTIONS[@]+"${EXCEPTIONS[@]}"}"; do
    if [[ "$rel" != ".sgl/immutable-paths" ]] && matches "$rel" "$ex"; then excepted=1; break; fi
  done
  (( excepted )) && continue
  for pat in "${PATTERNS[@]}"; do
    if matches "$rel" "$pat"; then
      {
        echo "SGL guard: BLOCKED write to immutable path '$rel' (pattern '$pat' in .sgl/immutable-paths)."
        echo "Verifiers, fixtures, and baselines may be read but never modified by the agent."
        echo "If this change is genuinely needed, stop and ask the Human Steward; it must be made as its own human-approved change."
      } >&2
      exit 2
    fi
  done
done <<< "$CANDIDATES"

exit 0
