#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness — dependency license-policy check (CI). Fails closed.
#
# A swarm installs dependencies fast; one copyleft package can create an obligation
# to open-source a proprietary repo. This check enforces .codifide/allowed-licenses:
# any resolved dependency license that is not allowed (or cannot be determined)
# FAILS the build.
#
# Input: an SBOM / license report on stdin, OR a file path. Supported formats
# (auto-detected): CycloneDX JSON, SPDX JSON/tag-value, or a plain two-column
# "name<TAB or ,>license" list (e.g. `pip-licenses`, `license-checker --csv`).
# This script does NOT resolve the dependency tree itself — feed it your tool's output:
#   npx license-checker --json        | bash .codifide/check-licenses.sh --base origin/main
#   pip-licenses --format=csv         | bash .codifide/check-licenses.sh --base origin/main
#   syft <img> -o spdx-json           | bash .codifide/check-licenses.sh --base origin/main
#
# Usage: check-licenses.sh [--base REF] [FILE]
#
# WHERE THE POLICY COMES FROM (so a change cannot approve its own dependency):
#   --base REF / CODIFIDE_BASE   read .codifide/allowed-licenses from REF (git show), not
#                                from the working tree. Missing on REF = exit 2.
#   (neither given)              REF defaults to origin/main. If that ref exists, the policy
#                                is read from it. If it does not exist, the working-tree
#                                policy is used and a WARNING says it is unverified (local
#                                use). CODIFIDE_REQUIRE_BASE_POLICY=1 makes that case exit 2, and so does running
#                                under GitHub Actions (GITHUB_ACTIONS=true).
#   CODIFIDE_BOOTSTRAP=1         adoption PR only: if REF has no policy file yet, use the
#                                working-tree policy and say so loudly.
#   CODIFIDE_LICENSE_POLICY=/p   explicit file override (tests, local experiments). Not
#                                verified against any base; do not use it in CI.
#
# License expressions use SPDX semantics: "A OR B" passes if EITHER side is allowed,
# "A AND B" needs BOTH, AND binds tighter than OR, parentheses group, and "X WITH exc"
# checks X (the exception id is not evaluated). Anything that does not parse fails.
# A small alias table maps common SBOM names (for example "MIT License", "Apache Software
# License") to SPDX ids. A name that is not in the table or on the allow-list fails.
# CycloneDX entries with several licenses are treated as AND (the conservative reading).
#
# Policy file: .codifide/allowed-licenses (allow list; "!" lines are explicit denies).
# An allow line that is only wildcards (for example "*") is rejected: it would allow everything.
#
# Exit 0 = every dependency license is allowed; 1 = a disallowed/unknown license; 2 = setup error.

set -uo pipefail
set -f   # no pathname expansion: a license token like "*" must never expand to file names

die() { echo "Codifide licenses: ERROR: $*" >&2; exit 2; }

BASE_ARG=""; FILE_ARG=""
while (( $# > 0 )); do
  case "$1" in
    --base)   [[ $# -ge 2 ]] || die "--base needs a ref"; BASE_ARG="$2"; shift 2 ;;
    --base=*) BASE_ARG="${1#--base=}"; shift ;;
    --)       shift; [[ $# -gt 0 ]] && FILE_ARG="$1"; break ;;
    -*)       die "unknown option '$1'" ;;
    *)        FILE_ARG="$1"; shift ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASE_EXPLICIT=0
if [[ -n "$BASE_ARG" ]]; then BASE="$BASE_ARG"; BASE_EXPLICIT=1
elif [[ -n "${CODIFIDE_BASE:-}" ]]; then BASE="$CODIFIDE_BASE"; BASE_EXPLICIT=1
else BASE="origin/main"; fi

POLICY_REL=".codifide/allowed-licenses"
if [[ -n "${CODIFIDE_LICENSE_POLICY:-}" ]]; then
  [[ -f "$CODIFIDE_LICENSE_POLICY" ]] || die "no license policy at $CODIFIDE_LICENSE_POLICY (copy allowed-licenses.example to $POLICY_REL)"
  POLICY_TEXT="$(cat "$CODIFIDE_LICENSE_POLICY")"; POLICY_SRC="$CODIFIDE_LICENSE_POLICY (explicit override, not verified against a base branch)"
elif git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null 2>&1; then
  if git cat-file -e "$BASE:$POLICY_REL" 2>/dev/null; then
    POLICY_TEXT="$(git show "$BASE:$POLICY_REL")" || die "cannot read $POLICY_REL from $BASE"
    POLICY_SRC="$BASE:$POLICY_REL"
  elif [[ "${CODIFIDE_BOOTSTRAP:-0}" == "1" && -f "$ROOT/$POLICY_REL" ]]; then
    echo "Codifide licenses: BOOTSTRAP: $BASE has no $POLICY_REL; using this branch's policy. The adoption change needs Human Steward review." >&2
    POLICY_TEXT="$(cat "$ROOT/$POLICY_REL")"; POLICY_SRC="$POLICY_REL (bootstrap, unverified)"
  else
    die "no $POLICY_REL on $BASE (the policy must come from the base branch; commit it there first, or set CODIFIDE_BOOTSTRAP=1 for the adoption change)"
  fi
else
  if (( BASE_EXPLICIT )) || [[ "${CODIFIDE_REQUIRE_BASE_POLICY:-0}" == "1" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
    die "base ref '$BASE' not found; refusing to trust the working-tree policy"
  fi
  [[ -f "$ROOT/$POLICY_REL" ]] || die "no license policy at $ROOT/$POLICY_REL (copy allowed-licenses.example to $POLICY_REL)"
  echo "Codifide licenses: WARNING: base ref '$BASE' not found; using the working-tree policy, which a change can edit. Pass --base in CI." >&2
  POLICY_TEXT="$(cat "$ROOT/$POLICY_REL")"; POLICY_SRC="$POLICY_REL (working tree, unverified)"
fi

# ---- load policy ----
ALLOWS=(); DENIES=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue
  if [[ "$line" == !* ]]; then DENIES+=("$(printf '%s' "${line#!}" | tr '[:upper:]' '[:lower:]')")
  else
    low="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
    [[ -z "${low//[*?]/}" ]] && die "policy allow line '$line' is only wildcards and would allow every license"
    ALLOWS+=("$low")
  fi
done <<< "$POLICY_TEXT"
(( ${#ALLOWS[@]} > 0 )) || die "policy ($POLICY_SRC) has no allowed licenses"

INPUT="$(cat "${FILE_ARG:-/dev/stdin}")" || die "could not read input"
[[ -n "${INPUT//[[:space:]]/}" ]] || die "empty license input (feed an SBOM or a name,license list)"

# ---- extract (name, license) pairs into a TAB-separated stream ----
pairs() {
  if command -v jq >/dev/null 2>&1 && printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
    # CycloneDX: .components[].licenses[].license.id/.name ; SPDX: .packages[].licenseConcluded/Declared ;
    # license-checker --json: { "pkg@ver": { "licenses": "MIT" } }
    printf '%s' "$INPUT" | jq -r '
      def paren: if type == "string" and test("(?i)\\s(or|and|with)\\s") then "(" + . + ")" else . end;
      def joined: if type=="array" then map(paren) | join(" AND ") else paren end;
      def spdx: (.licenseConcluded // "") as $c
        | if ($c | ascii_upcase) == "" or ($c | ascii_upcase) == "NOASSERTION" then (.licenseDeclared // "UNKNOWN") else $c end;
      def comps: .[]? | ., (.components | comps);
      if .components then (.components | comps) | [ (.name // "?"), ((.licenses // []) | map(.license.id // .license.name // .expression // "UNKNOWN") | if length == 0 then "UNKNOWN" else joined end) ] | @tsv
      elif .packages then .packages[] | [ (.name // "?"), (spdx | paren) ] | @tsv
      else to_entries[] | [ .key, ( (.value.licenses // .value.license // "UNKNOWN") | joined ) ] | @tsv
      end'
  else
    # plain list: "name,license" or "name<TAB>license" or SPDX tag-value lines
    printf '%s' "$INPUT" | awk '
      function flush() { if (n != "") { lic = (c != "" && toupper(c) != "NOASSERTION") ? c : (d != "" ? d : "UNKNOWN"); print n "\t" lic } n=""; c=""; d="" }
      /^PackageName:/ { flush(); n=$0; sub(/^PackageName:[ \t]*/,"",n); next }
      /^PackageLicenseConcluded:/ { c=$0; sub(/^[^:]*:[ \t]*/,"",c); next }
      /^PackageLicenseDeclared:/ { d=$0; sub(/^[^:]*:[ \t]*/,"",d); next }
      /[,\t]/ {
        line=$0; sub(/\r$/,"",line);
        sep=(index(line,"\t")>0)?"\t":",";
        p=index(line,sep); if(p>0){ nm=substr(line,1,p-1); lic=substr(line,p+1);
          gsub(/^[ \t"]+|[ \t"]+$/,"",nm); gsub(/^[ \t"]+|[ \t"]+$/,"",lic);
          low=tolower(lic); if(NR==1 && (low=="license"||low=="licenses"||low=="license name")) next;
          if(nm!="") print nm"\t"lic } }
      END { flush() }
    '
  fi
}

STREAM="$(pairs)"; PAIRS_RC=$?
(( PAIRS_RC == 0 )) || die "could not parse the license input completely (parser exit $PAIRS_RC); refusing to pass on partial output"
[[ -n "${STREAM//[[:space:]]/}" ]] || die "could not parse any (package, license) pairs from input — unsupported format?"

matches_list() { # $1 = lowercased license token, rest = patterns (globs ok)
  local lic="$1"; shift
  local p
  for p in "$@"; do
    # shellcheck disable=SC2053
    [[ "$lic" == $p ]] && return 0
  done
  return 1
}

# Common SBOM license names -> SPDX ids (input is already lowercased and trimmed).
# Deliberately short. "bsd license" is ambiguous (2- or 3-clause) and is NOT mapped.
alias_norm() {
  case "$1" in
    "mit license"|"the mit license"|"mit license (mit)") echo "mit" ;;
    "apache software license"|"apache license 2.0"|"apache license, version 2.0"|"apache 2.0"|"apache-2.0 license"|"the apache software license, version 2.0") echo "apache-2.0" ;;
    "bsd-3-clause license"|"3-clause bsd license"|"new bsd license"|"bsd 3-clause"|"bsd 3-clause license"|"modified bsd license") echo "bsd-3-clause" ;;
    "bsd-2-clause license"|"2-clause bsd license"|"simplified bsd license"|"bsd 2-clause"|"bsd 2-clause license"|"freebsd license") echo "bsd-2-clause" ;;
    "isc license"|"isc license (iscl)"|"isc license (isc)") echo "isc" ;;
    *) echo "$1" ;;
  esac
}

# ---- SPDX expression evaluator: or < and < atom; 0 = allowed ----
TOK=(); TI=0; PARSE_ERR=0; BADS=""
note_bad() { BADS="${BADS:+$BADS, }$1"; }
term_ok() { # $1 = lowercased id
  local t="$1"
  case "$t" in or|and|with|"("|")") PARSE_ERR=1; note_bad "unexpected '$t'"; return 1 ;; esac
  if matches_list "$t" ${DENIES[@]+"${DENIES[@]}"}; then note_bad "$t (explicit deny)"; return 1; fi
  if matches_list "$t" "${ALLOWS[@]}"; then return 0; fi
  note_bad "$t (not on allow-list)"; return 1
}
lic_atom() {
  local t="${TOK[TI]:-}" r
  if [[ -z "$t" ]]; then PARSE_ERR=1; note_bad "incomplete expression"; return 1; fi
  if [[ "$t" == "(" ]]; then
    TI=$((TI+1)); lic_or; r=$?
    if [[ "${TOK[TI]:-}" == ")" ]]; then TI=$((TI+1)); else PARSE_ERR=1; note_bad "unbalanced parenthesis"; r=1; fi
    return $r
  fi
  TI=$((TI+1))
  term_ok "$t"; r=$?
  if [[ "${TOK[TI]:-}" == "with" ]]; then
    local ex="${TOK[TI+1]:-}"
    case "$ex" in
      ""|or|and|with|"("|")") PARSE_ERR=1; note_bad "malformed WITH (no exception id)"; r=1 ;;
    esac
    TI=$((TI+2))
  fi
  return $r
}
lic_and() {
  local r r2
  lic_atom; r=$?
  while [[ "${TOK[TI]:-}" == "and" ]]; do
    TI=$((TI+1)); lic_atom; r2=$?
    if (( r == 0 && r2 == 0 )); then r=0; else r=1; fi
  done
  return $r
}
lic_or() {
  local r r2
  lic_and; r=$?
  while [[ "${TOK[TI]:-}" == "or" ]]; do
    TI=$((TI+1)); lic_and; r2=$?
    if (( r == 0 || r2 == 0 )); then r=0; else r=1; fi
  done
  return $r
}
eval_license() { # $1 = raw license string; sets BADS; returns 0 if allowed
  local norm toks
  norm="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  BADS=""; PARSE_ERR=0; TI=0; TOK=()
  if [[ -z "$norm" || "$norm" == "unknown" || "$norm" == "noassertion" || "$norm" == "none" || "$norm" == "?" ]]; then
    BADS="UNKNOWN license (treated as disallowed)"; return 1
  fi
  norm="$(alias_norm "$norm")"
  toks="$(printf '%s' "$norm" | sed -e 's/(/ ( /g' -e 's/)/ ) /g')"
  read -ra TOK <<< "$toks"
  lic_or; local r=$?
  if (( TI < ${#TOK[@]} )); then PARSE_ERR=1; note_bad "unparsed text near '${TOK[TI]}'"; r=1; fi
  (( PARSE_ERR )) && r=1
  return $r
}

VIOLATIONS=()
while IFS=$'\t' read -r name lic; do
  [[ -z "$name" ]] && continue
  if ! eval_license "$lic"; then
    VIOLATIONS+=("$name → $BADS")
  fi
done <<< "$STREAM"

TOTAL=$(printf '%s\n' "$STREAM" | grep -c .)
if (( ${#VIOLATIONS[@]} > 0 )); then
  echo "Codifide licenses: FAIL ($TOTAL deps scanned, ${#VIOLATIONS[@]} disallowed; policy from $POLICY_SRC):"
  printf '  - %s\n' "${VIOLATIONS[@]}"
  echo "Allowed: ${ALLOWS[*]}"
  (( ${#DENIES[@]} > 0 )) && echo "Explicit denies: ${DENIES[*]}"
  echo "Fix: remove the dependency, or (proprietary repo) get a Human-Steward + legal exception recorded in $POLICY_REL on the base branch."
  exit 1
fi
echo "Codifide licenses: PASS ($TOTAL dependencies, all licenses allowed; policy from $POLICY_SRC)."
exit 0
