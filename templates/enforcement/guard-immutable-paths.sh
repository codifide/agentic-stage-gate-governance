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
# too; the untrimmed string, and the part before any NUL byte, are checked as well.
# A string with an interior newline is ALSO checked as a path (a file name can
# contain a newline); file content that merely mentions a protected path in a later
# line does not match, because the whole string is matched from its start.
# Object keys are checked too. There is NO length cutoff: a long path built from "a/../" segments is resolved
# and checked like any other. A rare false positive (a string that equals a
# protected path) blocks with a clear message; that is the intended direction.
#
# Matching is case-insensitive (default macOS and Windows filesystems treat
# Verifiers/ and verifiers/ as the same directory). On a case-sensitive
# filesystem this can over-block; that is the fail-closed direction.
#
# Symlinks are resolved component by component, left to right, so a path like
# src/link/../check.py is judged by where the filesystem sends it, not by its text.
# Each candidate is checked three ways: lexically normalised, with the parents
# resolved but the final name left alone (deleting or replacing a symlink that sits
# in a protected directory), and fully resolved.
#
# Ancestors: a candidate that is a directory CONTAINING a protected path (for example
# "tests" when tests/golden/ is protected, or the repo root ".") is blocked, because a
# recursive delete or move of it would remove the protected files. This also blocks a
# harmless string such as "." in a tool argument; that is the fail-closed direction.
#
# Hard links: a write to a file that is hard-linked to a protected file is blocked,
# wherever the other name lives (inside or outside the repo). This is checked with
# `find -samefile` under the repo root only when the target has more than one link.
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
# SCANF holds the output of the directory/hard-link scans (a file, so that a failing `find` is seen).
SCANF=""
trap 'rc=$?; [[ -n "$SCANF" ]] && rm -f "$SCANF"; if [[ $rc -ne 0 && $rc -ne 2 ]]; then echo "Codifide guard: internal error (exit $rc); failing closed." >&2; exit 2; fi' EXIT

# Git environment overrides (GIT_DIR, GIT_WORK_TREE, GIT_COMMON_DIR, GIT_CEILING_DIRECTORIES ...)
# would let a caller point `git rev-parse` at a decoy work tree and so choose which list is read.
# Every GIT_* variable is dropped before the root is derived.
for _v in $(compgen -e | grep -E '^GIT_'); do unset "$_v"; done
unset _v
SCANF="$(mktemp)" || { echo "Codifide guard: cannot create a temporary file; failing closed." >&2; exit 2; }

# The repository root is the git top level of the hook's own working directory. There is no
# override: a CODIFIDE_ROOT that points anywhere else would let a caller aim the guard at a
# decoy list, so a CODIFIDE_ROOT that differs from the real top level BLOCKS (checked below).
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
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

b64d() { printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 -D 2>/dev/null; }
if command -v jq >/dev/null 2>&1; then
  # Every string value and every object key, as base64 lines, in four forms: as is,
  # trimmed, cut at the first NUL, and both. Base64 keeps newlines inside a value.
  CANDIDATES="$(printf '%s' "$INPUT" | jq -r '
    def v: ., gsub("^\\s+|\\s+$";""), (split("\u0000")[0]), (split("\u0000")[0] | gsub("^\\s+|\\s+$";""));
    (if type == "object" and (.cwd | type) == "string" then del(.cwd) else . end)
    | ((.. | strings), (.. | objects | keys_unsorted[])) | v | @base64' 2>/dev/null)"
  PAYLOAD_CWD="$(printf '%s' "$INPUT" | jq -r 'if type == "object" and (.cwd | type) == "string" then .cwd else empty end' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s' "$INPUT" | python3 -c '
import base64, json, sys
def emit(v):
    c = v.split("\x00")[0]
    for x in (v, v.strip(), c, c.strip()):
        print(base64.b64encode(x.encode("utf-8", "surrogatepass")).decode())
def walk(v):
    if isinstance(v, str):
        emit(v)
    elif isinstance(v, dict):
        for k, x in v.items():
            emit(k); walk(x)
    elif isinstance(v, list):
        for x in v: walk(x)
try:
    d = json.load(sys.stdin)
    if isinstance(d, dict) and isinstance(d.get("cwd"), str):
        d.pop("cwd")
    walk(d)
except Exception:
    sys.exit(3)
')"
  PAYLOAD_CWD="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
d = json.load(sys.stdin)
if isinstance(d, dict) and isinstance(d.get("cwd"), str):
    print(d["cwd"])
' 2>/dev/null)"
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
# Unicode aliases: APFS/HFS+ treat NFC and NFD spellings of a name as one file, so every
# candidate is also checked in both normalisation forms. Needs python3; without it the
# inode comparison against literal list entries (below) still covers existing files.
if command -v python3 >/dev/null 2>&1; then
  CANDIDATES="$(printf '%s\n' "$CANDIDATES" | python3 -c '
import base64, sys, unicodedata
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    print(line)
    try:
        s = base64.b64decode(line).decode("utf-8", "surrogatepass")
    except Exception:
        continue
    for form in ("NFC", "NFD"):
        n = unicodedata.normalize(form, s)
        if n != s:
            print(base64.b64encode(n.encode("utf-8", "surrogatepass")).decode())
')" || { echo "Codifide guard: Unicode normalisation step failed; failing closed." >&2; exit 2; }
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
# Split $1 on "/" into the array SP (newlines and spaces stay inside a component).
SP=()
split_path() {
  local oldifs="$IFS"
  IFS='/'; set -f
  # shellcheck disable=SC2206
  SP=( $1 )
  set +f; IFS="$oldifs"
}
# Lexically normalize an absolute path: collapse //, ".", and ".." segments. Result in NP.
NP=""
normpath() {
  local part out=() joined
  split_path "$1"
  for part in ${SP[@]+"${SP[@]}"}; do
    case "$part" in
      ''|'.') ;;
      '..') (( ${#out[@]} > 0 )) && unset 'out[${#out[@]}-1]' ;;
      *) out+=("$part") ;;
    esac
  done
  joined="$(printf '/%s' ${out[@]+"${out[@]}"}; printf x)"
  joined="${joined%x}"
  NP="${joined:-/}"   # result in a variable: $(...) would strip a trailing newline from a file name
}
# Physical resolution of an absolute path, one component at a time, left to right:
# a symlink is expanded where it stands, and ".." then applies to the REAL parent.
# $2 = 1 leaves the final name unresolved (the path of the link itself).
# Returns 1 on a symlink loop or more than 40 expansions (the caller blocks). Result in PR
# (a variable, not stdout: $(...) would strip a trailing newline, which a file name may end in).
PR=""
physres() {
  PR=""
  local cur="/" hops=0 nof="${2:-0}" i comp next t last=-1 n j
  local q=() nq=()
  split_path "$1"; q=( ${SP[@]+"${SP[@]}"} )
  n=${#q[@]}
  for ((j=0; j<n; j++)); do [[ -n "${q[j]}" && "${q[j]}" != "." ]] && last=$j; done
  i=0
  while (( i < ${#q[@]} )); do
    comp="${q[i]}"
    case "$comp" in
      ''|'.') i=$((i+1)); continue ;;
      '..') cur="${cur%/*}"; [[ -z "$cur" ]] && cur="/"; i=$((i+1)); continue ;;
    esac
    next="${cur%/}/$comp"
    if [[ -L "$next" ]] && ! { (( nof )) && (( i == last )); }; then
      hops=$((hops+1)); (( hops > 40 )) && return 1
      # readlink -n: no trailing newline of its own (BSD readlink drops the target's final newline otherwise)
      t="$(readlink -n "$next"; printf x)"; t="${t%x}"
      [[ "$t" == /* ]] && cur="/"
      split_path "$t"; nq=( ${SP[@]+"${SP[@]}"} )
      for ((j=i+1; j<${#q[@]}; j++)); do nq+=("${q[j]}"); done
      # last must follow the rebuilt queue
      last=-1
      for ((j=0; j<${#nq[@]}; j++)); do [[ -n "${nq[j]}" && "${nq[j]}" != "." ]] && last=$j; done
      q=( ${nq[@]+"${nq[@]}"} ); i=0
      continue
    fi
    cur="$next"; i=$((i+1))
  done
  PR="$cur"
}
physres "$ROOT" 0 && ROOT="$PR" || { echo "Codifide guard: cannot resolve the repository root; failing closed." >&2; exit 2; }
if [[ -n "${CODIFIDE_ROOT:-}" ]]; then
  normpath "$CODIFIDE_ROOT"
  if physres "$NP" 0; then alt="$PR"; else alt=""; fi
  if [[ "$alt" != "$ROOT" ]]; then
    echo "Codifide guard: CODIFIDE_ROOT ('$CODIFIDE_ROOT') is not this repository's top level ('$ROOT'); refusing to use a different root. Blocking (fail closed)." >&2
    exit 2
  fi
fi
# Relative paths: the tool decides what they are relative to, and the guard cannot know, so a
# relative candidate is judged against EVERY plausible base: the repository root, the hook's
# working directory, and the working directory the payload reports (if any).
BASES=("$ROOT")
add_base() { # $1 = absolute directory
  local b
  [[ "$1" == /* ]] || return 0
  # physres resolves symlinks BEFORE applying ".." (normpath first would apply ".." to the link text).
  physres "$1" 0 || { echo "Codifide guard: cannot resolve working directory '$1'; failing closed." >&2; exit 2; }
  b="$PR"
  [[ "$b" == "$ROOT" ]] && return 0
  local x; for x in "${BASES[@]}"; do [[ "$x" == "$b" ]] && return 0; done
  BASES+=("$b")
}
add_base "$PWD"
[[ -n "${PAYLOAD_CWD:-}" ]] && add_base "$PAYLOAD_CWD"
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
# Check one resolved absolute path: protected itself, or an ancestor of something protected.
check_path() {
  local x="$1" rel pat lit dir f count=0
  if [[ "$x" == "$ROOT" ]]; then
    block "." "${PATTERNS[0]}" "the repository root contains protected paths"
  elif [[ "$x" == "$ROOT"/* ]]; then
    rel="${x#"$ROOT"/}"
  else
    # Outside the repo: only an ancestor of the repo root matters (a recursive delete of it).
    if [[ "$ROOT" == "$x"/* || "$x" == "/" ]]; then block "$x" "${PATTERNS[0]}" "contains the repository"; fi
    return 0
  fi
  pat="$(protected_pattern "$rel")"
  [[ -n "$pat" ]] && block "$rel" "$pat"
  # Ancestor of a literal protected prefix (tests when tests/golden/ is protected).
  for pat in "${PATTERNS[@]}"; do
    lit="${pat%%[*?[]*}"
    dir=""; [[ "$lit" == */* ]] && dir="${lit%/*}"
    if [[ -n "$dir" && ( "$dir" == "$rel" || "$dir" == "$rel"/* ) ]]; then
      block "$rel" "$pat" "directory containing a protected path"
    fi
  done
  # Ancestor of a protected file matched by a glob: look inside an existing directory.
  if [[ -d "$x" ]]; then
    # A find that cannot read part of the tree has not proved the directory is free of protected files.
    find "$x" -path "$ROOT/.git" -prune -o \( -type f -o -type l \) -print0 > "$SCANF" 2>/dev/null \
      || block "$rel" "${PATTERNS[0]}" "directory could not be fully scanned; failing closed"
    while IFS= read -r -d '' f; do
      count=$((count+1))
      if (( count > 20000 )); then block "$rel" "${PATTERNS[0]}" "directory too large to verify; failing closed"; fi
      pat="$(protected_pattern "${f#"$ROOT"/}")"
      [[ -n "$pat" ]] && block "$rel" "$pat" "directory containing protected '${f#"$ROOT"/}'"
    done < "$SCANF"
  fi
  return 0
}
while IFS= read -r b64; do
  [[ -z "$b64" ]] && continue
  # Sentinel x: keeps a trailing newline that $(...) would otherwise strip from the decoded value.
  cand="$(b64d "$b64" && printf x)" || { echo "Codifide guard: could not decode a tool-input value; failing closed." >&2; exit 2; }
  cand="${cand%x}"
  [[ -z "$cand" ]] && continue
  if [[ "$cand" == /* ]]; then INS=("$cand"); else INS=(); for b in "${BASES[@]}"; do INS+=("$b/$cand"); done; fi
  for in in "${INS[@]}"; do
    normpath "$in"; lex="$NP"
    { physres "$in" 1 && nol="$PR" && physres "$in" 0 && full="$PR"; } || { echo "Codifide guard: symlink loop or too many links in a tool-input path; failing closed." >&2; exit 2; }
    check_path "$lex"; check_path "$nol"; check_path "$full"
    # Same inode as a literal list entry (covers filesystem-level aliases such as Unicode
    # normalisation that the text comparison cannot see).
    if [[ -e "$full" ]]; then
      for pat in "${PATTERNS[@]}"; do
        [[ "$pat" == *[*?[]* || "$pat" == */ ]] && continue
        if [[ "$full" -ef "$ROOT/$pat" ]]; then block "${full#"$ROOT"/}" "$pat" "same file as protected '$pat'"; fi
      done
    fi
    # Hard links: a different name for the same inode as a protected file, anywhere.
    if [[ -f "$full" && -n "$(find "$full" -maxdepth 0 -links +1 2>/dev/null)" ]]; then
      # If find cannot traverse part of the tree it cannot rule out a protected name for this inode: block.
      find "$ROOT" -path "$ROOT/.git" -prune -o -samefile "$full" -print0 > "$SCANF" 2>/dev/null \
        || block "${full#"$ROOT"/}" "${PATTERNS[0]}" "hard-link scan could not read the whole repository; failing closed"
      while IFS= read -r -d '' other; do
        [[ -z "$other" || "$other" == "$full" ]] && continue
        orel="${other#"$ROOT"/}"
        opat="$(protected_pattern "$orel")"
        [[ -n "$opat" ]] && block "${full#"$ROOT"/}" "$opat" "hard link to protected file '$orel'"
      done < "$SCANF"
    fi
  done
done <<< "$CANDIDATES"
exit 0
