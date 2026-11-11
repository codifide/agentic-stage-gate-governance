#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Convert the Codifide Harness steering files to Cursor rules (.mdc).
#
# Cursor ignores plain .md files in .cursor/rules. A rule needs the .mdc extension and
# front matter with `description` and `alwaysApply`. This maps the harness front matter:
#   inclusion: always  ->  alwaysApply: true   (only 00-welcome.md, the core)
#   inclusion: auto    ->  alwaysApply: false + description (Cursor decides when to attach it)
# The body is copied unchanged. Nothing is installed for you.
#
# Usage: to-mdc.sh <dest-dir> [steering-dir]
#   dest-dir      where to write the .mdc files, normally <your-project>/.cursor/rules
#   steering-dir  defaults to ../../steering relative to this script
# Never overwrites: if a destination file exists, the script stops and writes nothing more.
set -euo pipefail
DEST="${1:-}"; [[ -n "$DEST" ]] || { echo "usage: to-mdc.sh <dest-dir> [steering-dir]" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${2:-$HERE/../../steering}"
[[ -d "$SRC" ]] || { echo "no steering dir at $SRC" >&2; exit 2; }
mkdir -p "$DEST"
n=0
for f in "$SRC"/[0-9][0-9]-*.md; do
  base="$(basename "$f" .md)"; out="$DEST/$base.mdc"
  [[ -e "$out" ]] && { echo "refusing to overwrite $out" >&2; exit 1; }
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { infm=0; body=1
      always = (inc=="always") ? "true" : "false"
      if (desc=="") desc = (name!="") ? name : "Codifide Harness core rules (always on)"
      gsub(/"/, "\\\"", desc)
      print "---"; print "description: \"" desc "\""; print "alwaysApply: " always; print "---"; next }
    infm { if ($0 ~ /^inclusion:/) { inc=$2 } else if ($0 ~ /^name:/) { name=$0; sub(/^name:[ \t]*/,"",name) } else if ($0 ~ /^description:/) { desc=$0; sub(/^description:[ \t]*/,"",desc) } ; next }
    { print }
  ' "$f" > "$out"
  echo "wrote $out"; n=$((n+1))
done
echo "$n rule files written to $DEST. Review them before committing."
