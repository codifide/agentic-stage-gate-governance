#!/usr/bin/env bash
# Codifide Harness — dependency license-policy check (CI). Fails closed.
#
# A swarm installs dependencies fast; one copyleft package can create an obligation
# to open-source a proprietary repo. This check enforces .sgl/allowed-licenses:
# any resolved dependency license that is not allowed (or cannot be determined)
# FAILS the build.
#
# Input: an SBOM / license report on stdin, OR a file path as $1. Supported formats
# (auto-detected): CycloneDX JSON, SPDX JSON/tag-value, or a plain two-column
# "name<TAB or ,>license" list (e.g. `pip-licenses`, `license-checker --csv`).
# This script does NOT resolve the dependency tree itself — feed it your tool's output:
#   npx license-checker --json        | bash .sgl/check-licenses.sh
#   pip-licenses --format=csv         | bash .sgl/check-licenses.sh
#   syft <img> -o spdx-json           | bash .sgl/check-licenses.sh
#
# Policy file: .sgl/allowed-licenses (allow list; "!" lines are explicit denies).
#   SGL_LICENSE_POLICY=/path overrides the location.
#
# Exit 0 = every dependency license is allowed; 1 = a disallowed/unknown license; 2 = setup error.

set -uo pipefail

die() { echo "SGL licenses: ERROR: $*" >&2; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
POLICY="${SGL_LICENSE_POLICY:-$ROOT/.sgl/allowed-licenses}"
[[ -f "$POLICY" ]] || die "no license policy at $POLICY (copy allowed-licenses.example to .sgl/allowed-licenses)"

# ---- load policy ----
ALLOWS=(); DENIES=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue
  if [[ "$line" == !* ]]; then DENIES+=("$(printf '%s' "${line#!}" | tr '[:upper:]' '[:lower:]')")
  else ALLOWS+=("$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"); fi
done < "$POLICY"
(( ${#ALLOWS[@]} > 0 )) || die "policy $POLICY has no allowed licenses"

INPUT="$(cat "${1:-/dev/stdin}")" || die "could not read input"
[[ -n "${INPUT//[[:space:]]/}" ]] || die "empty license input (feed an SBOM or a name,license list)"

# ---- extract (name, license) pairs into a TAB-separated stream ----
pairs() {
  if command -v jq >/dev/null 2>&1 && printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
    # CycloneDX: .components[].licenses[].license.id/.name ; SPDX: .packages[].licenseConcluded/Declared ;
    # license-checker --json: { "pkg@ver": { "licenses": "MIT" } }
    printf '%s' "$INPUT" | jq -r '
      if .components then .components[] | [ (.name // "?"), ((.licenses // []) | map(.license.id // .license.name // .expression // "UNKNOWN") | join(" OR ")) ] | @tsv
      elif .packages then .packages[] | [ (.name // "?"), (.licenseConcluded // .licenseDeclared // "UNKNOWN") ] | @tsv
      else to_entries[] | [ .key, ( (.value.licenses // .value.license // "UNKNOWN") | if type=="array" then join(" OR ") else . end ) ] | @tsv
      end' 2>/dev/null
  else
    # plain list: "name,license" or "name<TAB>license" or SPDX tag-value lines
    printf '%s' "$INPUT" | awk '
      /^PackageName:/ { n=$2; for(i=3;i<=NF;i++) n=n" "$i }
      /^PackageLicenseConcluded:|^PackageLicenseDeclared:/ { if(n!=""){ print n"\t"$2; n="" } ; next }
      /[,\t]/ && !/^PackageName:/ {
        line=$0; sub(/\r$/,"",line);
        sep=(index(line,"\t")>0)?"\t":",";
        p=index(line,sep); if(p>0){ nm=substr(line,1,p-1); lic=substr(line,p+1);
          gsub(/^[ \t"]+|[ \t"]+$/,"",nm); gsub(/^[ \t"]+|[ \t"]+$/,"",lic);
          low=tolower(lic); if(low=="license"||low=="licenses"||low=="license name") next;
          if(nm!="") print nm"\t"lic } }
    '
  fi
}

STREAM="$(pairs)"
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

VIOLATIONS=()
while IFS=$'\t' read -r name lic; do
  [[ -z "$name" ]] && continue
  lic_norm="$(printf '%s' "$lic" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  # Split an expression like "MIT OR Apache-2.0" / "(MIT AND BSD-3-Clause)" into tokens;
  # every token must be allowed (conservative: AND-of-all).
  tokens="$(printf '%s' "$lic_norm" | tr '()' '  ' | sed -E 's/ (or|and) / /g')"
  if [[ -z "${tokens//[[:space:]]/}" || "$lic_norm" == "unknown" || "$lic_norm" == "noassertion" || "$lic_norm" == "?" ]]; then
    VIOLATIONS+=("$name → UNKNOWN license (treated as disallowed)"); continue
  fi
  bad=""
  for tok in $tokens; do
    if matches_list "$tok" "${DENIES[@]:-}"; then bad="$tok (explicit deny)"; break; fi
    if ! matches_list "$tok" "${ALLOWS[@]}"; then bad="$tok (not on allow-list)"; break; fi
  done
  [[ -n "$bad" ]] && VIOLATIONS+=("$name → $bad")
done <<< "$STREAM"

TOTAL=$(printf '%s\n' "$STREAM" | grep -c .)
if (( ${#VIOLATIONS[@]} > 0 )); then
  echo "SGL licenses: FAIL ($TOTAL deps scanned, ${#VIOLATIONS[@]} disallowed):"
  printf '  - %s\n' "${VIOLATIONS[@]}"
  echo "Allowed: ${ALLOWS[*]}"
  (( ${#DENIES[@]} > 0 )) && echo "Explicit denies: ${DENIES[*]}"
  echo "Fix: remove the dependency, or (proprietary repo) get a Human-Steward + legal exception recorded in $POLICY."
  exit 1
fi
echo "SGL licenses: PASS ($TOTAL dependencies, all licenses allowed)."
exit 0
