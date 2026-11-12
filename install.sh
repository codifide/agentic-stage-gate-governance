#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness installer: copies a PINNED release of the harness into a repository.
#
#   bash install.sh [install|upgrade|uninstall] --target DIR [--host H]... [--apply] [--force]
#
# Rules this script keeps (each one has a test in tests/test-installer.sh):
#   - Dry run by default. Nothing is written unless you pass --apply.
#   - Refuses to run from anything but a tagged release (a clean git checkout of the tag that
#     matches VERSION, or an unpacked release tarball with a matching RELEASE file), unless you
#     pass --i-know-this-is-unpinned, which is recorded in .codifide/harness-version.
#   - Never uses the network, never commits, never pushes, never changes git configuration.
#   - Never overwrites a file you own: policy files (.codifide/immutable-paths, allowed-licenses,
#     the workflow, CLAUDE.md, AGENTS.md, the Copilot file) are created only when absent.
#     .claude/settings.json is never written; a merge snippet is printed instead.
#   - Harness-owned files are replaced only while they still match the hash recorded in
#     .codifide/harness-manifest. A locally edited one stops the run unless you pass --force.
#   - Every path is checked before anything is written: relative, from a fixed allow-list, and
#     no symbolic link anywhere on the way. A manifest is untrusted input and is validated the same way.
#   - All-or-nothing: if a write fails part way, everything written so far is rolled back.
# Needs bash (3.2 or newer), and shasum or sha256sum. The git command is used read-only, to check the pin.
set -euo pipefail
export LC_ALL=C
# The environment must not choose a repository for us (same rule as the enforcement scripts).
for v in $(compgen -e | grep '^GIT_' || true); do unset "$v"; done
unset v

die(){ echo "install.sh: $*" >&2; exit 1; }
usage_err(){ echo "install.sh: $*" >&2; echo "Run: bash install.sh --help" >&2; exit 2; }

usage(){ cat <<'EOF'
Codifide Harness installer

  bash install.sh [install] --target DIR --host HOST [--host HOST ...] [--apply]
  bash install.sh upgrade   --target DIR [--host HOST ...] [--apply] [--force]
  bash install.sh uninstall --target DIR [--apply]

  --target DIR   the repository root to install into (required; must contain .git)
  --host HOST    kiro | claude | cursor | copilot | codex (repeat, or comma-separate)
  --apply        write the changes. Without it this is a dry run: it prints the plan and writes nothing.
  --force        overwrite harness-owned files that you edited (install and upgrade only)
  --i-know-this-is-unpinned
                 allow running from something other than a tagged release (recorded as pinned=no)

Run it from a tagged release (a checkout of the tag, or the unpacked release tarball).
It never uses the network, never commits, and never pushes. Review the result with
git status and git diff, then commit it through a normal pull request.
EOF
}

# ---------- arguments ----------
CMD=install; TARGET=""; HOSTS=" "; APPLY=0; DRY=0; FORCE=0; UNPINNED=0
valid_host(){ case "$1" in kiro|claude|cursor|copilot|codex) return 0;; esac; return 1; }
add_hosts(){ local list="$1" h oldifs=$IFS
  IFS=,; for h in $list; do
    [[ -n "$h" ]] || usage_err "empty host name"
    valid_host "$h" || usage_err "unknown host: $h (use kiro, claude, cursor, copilot or codex)"
    case "$HOSTS" in *" $h "*) ;; *) HOSTS="$HOSTS$h ";; esac
  done; IFS=$oldifs; }
if [[ $# -gt 0 ]]; then case "$1" in install|upgrade|uninstall) CMD="$1"; shift;; esac; fi
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) [[ $# -ge 2 ]] || usage_err "--host needs a value"; add_hosts "$2"; shift 2;;
    --host=*) add_hosts "${1#--host=}"; shift;;
    --target) [[ $# -ge 2 ]] || usage_err "--target needs a value"; TARGET="$2"; shift 2;;
    --target=*) TARGET="${1#--target=}"; shift;;
    --apply) APPLY=1; shift;;
    --dry-run) DRY=1; shift;;
    --force) FORCE=1; shift;;
    --i-know-this-is-unpinned) UNPINNED=1; shift;;
    -h|--help) usage; exit 0;;
    *) usage_err "unknown argument: $1";;
  esac
done
[[ $APPLY -eq 1 && $DRY -eq 1 ]] && usage_err "--apply and --dry-run contradict each other"
[[ -n "$TARGET" ]] || usage_err "--target DIR is required"
if [[ "$CMD" == install && "$HOSTS" == " " ]]; then usage_err "install needs at least one --host"; fi
if [[ "$CMD" == uninstall ]]; then
  [[ "$HOSTS" == " " ]] || usage_err "uninstall takes no --host (the manifest decides what to remove)"
  [[ $FORCE -eq 0 ]] || usage_err "uninstall never removes edited files, so --force does not apply"
fi

# ---------- locations ----------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
case "$SRC" in *[[:cntrl:]]*) die "the source path contains a control character";; esac
[[ -d "$TARGET" ]] || die "target is not a directory: $TARGET"
T="$(cd "$TARGET" && pwd -P)"
case "$T" in *[[:cntrl:]]*) die "the target path contains a control character";; esac
[[ "$T" != "$SRC" ]] || die "the target is the harness source itself"
[[ -e "$T/.git" ]] || die "$T is not a repository root (no .git). Run this against the top level of the repository."

W="$(mktemp -d "${TMPDIR:-/tmp}/codifide-install.XXXXXX")" || die "cannot create a temporary directory"
JOURNAL="$W/journal"; : > "$JOURNAL"; mkdir "$W/bk"
APPLYING=0; TMPFILE=""
rev(){ awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}' "$1"; }
rollback(){
  local op a b
  [[ -z "$TMPFILE" ]] || rm -f "$TMPFILE"
  rev "$JOURNAL" > "$W/journal.rev"
  while IFS='|' read -r op a b; do
    case "$op" in
      C) rm -f "$T/$a";;
      R|D) cp -p "$W/bk/$b" "$T/$a";;
      M) rmdir "$T/$a" 2>/dev/null || true;;
    esac
  done < "$W/journal.rev"
}
on_exit(){ local rc=$?
  trap - EXIT
  if [[ $APPLYING -eq 1 && $rc -ne 0 ]]; then
    echo "install.sh: failed part way; rolling back every change made by this run" >&2
    rollback || echo "install.sh: ROLLBACK ALSO FAILED; check git status in $T" >&2
  fi
  rm -rf "$W"
  exit $rc; }
trap on_exit EXIT
trap 'exit 130' INT TERM HUP

# ---------- helpers ----------
hash_file(){ if command -v shasum >/dev/null 2>&1; then shasum -a 256 < "$1" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d' ' -f1
  else die "need shasum or sha256sum"; fi; }

# A relative path made of safe characters, with no . or .. component, inside a fixed allow-list.
path_ok(){ local p="$1" c oldifs
  [[ "$p" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$ ]] || return 1
  oldifs=$IFS; IFS=/
  for c in $p; do if [[ "$c" == "." || "$c" == ".." ]]; then IFS=$oldifs; return 1; fi; done
  IFS=$oldifs
  case "$p" in
    .codifide/*|.kiro/steering/*|.kiro/hooks/*|.cursor/rules/*|.github/workflows/*) return 0;;
    .github/copilot-instructions.md|CLAUDE.md|AGENTS.md) return 0;;
  esac
  return 1; }

# No component below BASE is a symbolic link, every directory on the way is a directory, and the leaf,
# when it exists, is a regular file.
walk_clean(){ local base="$1" p="$2" cur c oldifs; cur="$base"; oldifs=$IFS; IFS=/
  for c in $p; do
    cur="$cur/$c"
    if [[ -L "$cur" ]]; then IFS=$oldifs; return 1; fi
    if [[ "$cur" != "$base/$p" && -e "$cur" && ! -d "$cur" ]]; then IFS=$oldifs; return 1; fi
  done
  IFS=$oldifs
  if [[ -e "$cur" && ! -f "$cur" ]]; then return 1; fi
  return 0; }
dest_ok(){ walk_clean "$T" "$1"; }
# Only files this release actually ships as harness-owned may be recorded as owned. Policy files and the
# CLAUDE.md / AGENTS.md / Copilot stubs are seed-only: a manifest line cannot make them deletable.
owned_ok(){ local d="${1%/*}" b="${1##*/}"
  case "$1" in
    .codifide/guard-immutable-paths.sh|.codifide/check-immutable-paths.sh|.codifide/check-review-level.sh|.codifide/check-licenses.sh) return 0;;
    .kiro/hooks/guard-immutable-paths.json) return 0;;
  esac
  case "$d" in
    .kiro/steering|.codifide/steering) case "$b" in [0-9][0-9]-*.md) return 0;; esac;;
    .cursor/rules) case "$b" in [0-9][0-9]-*.mdc) return 0;; esac;;
  esac
  return 1; }

# ---------- the pin ----------
walk_clean "$SRC" VERSION && [[ -f "$SRC/VERSION" ]] || die "VERSION is missing or is reachable through a link"
VERSION="$(cat "$SRC/VERSION" 2>/dev/null | head -n 1 || true)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "VERSION is missing or not MAJOR.MINOR.PATCH"
SOURCE_KIND="unpinned"; PINNED="no"
check_pin(){
  local tag
  # A git checkout is judged by git alone: a RELEASE file written by hand must not vouch for a dirty tree.
  if [[ -e "$SRC/.git" ]]; then
    tag="$(git -C "$SRC" describe --exact-match --tags HEAD 2>/dev/null || true)"
    if [[ "$tag" == "v$VERSION" ]]; then
      if [[ -z "$(git -C "$SRC" status --porcelain 2>/dev/null)" ]]; then SOURCE_KIND="tag"; PINNED="yes"; return 0; fi
      echo "install.sh: the checkout of v$VERSION has uncommitted changes" >&2
    else
      echo "install.sh: HEAD is not the tag v$VERSION (found: ${tag:-no tag})" >&2
    fi
  elif [[ -f "$SRC/RELEASE" && ! -L "$SRC/RELEASE" ]]; then
    if [[ "$(head -n 1 "$SRC/RELEASE")" == "tag=v$VERSION" ]]; then SOURCE_KIND="release"; PINNED="yes"; return 0; fi
    echo "install.sh: RELEASE does not say tag=v$VERSION, so this tree is not release v$VERSION" >&2
  else
    echo "install.sh: this is neither a checkout of a release tag nor an unpacked release tarball" >&2
  fi
  if [[ $UNPINNED -eq 1 ]]; then
    echo "WARNING: running unpinned (--i-know-this-is-unpinned). Nothing proves which bytes these are." >&2
    return 0
  fi
  die "refusing to run unpinned. Use a tagged release, or pass --i-know-this-is-unpinned."
}
if [[ "$CMD" != uninstall ]]; then check_pin; fi

# ---------- recorded state ----------
VERFILE=".codifide/harness-version"; MANFILE=".codifide/harness-manifest"
: > "$W/old"
OLD_VERSION=""; OLD_HOSTS=""; HAVE_MANIFEST=0
load_state(){
  local line n=0 re sha kind path first v hosts h oldifs
  if [[ -e "$T/$MANFILE" || -L "$T/$MANFILE" || -e "$T/$VERFILE" || -L "$T/$VERFILE" ]]; then
    dest_ok "$MANFILE" || die "refusing: $MANFILE is a link or not a regular file"
    dest_ok "$VERFILE" || die "refusing: $VERFILE is a link or not a regular file"
    [[ -f "$T/$MANFILE" && -f "$T/$VERFILE" ]] || die "found only one of $MANFILE and $VERFILE; remove both by hand or restore the missing one"
    first="$(head -n 1 "$T/$MANFILE")"
    [[ "$first" == "# codifide-harness-manifest 1" ]] || die "$MANFILE does not start with the expected header"
    re='^([0-9a-f]{64}) (owned|seed) (.+)$'
    while IFS= read -r line || [[ -n "$line" ]]; do
      n=$((n+1)); [[ $n -eq 1 ]] && continue
      case "$line" in "#"*) continue;; esac
      [[ "$line" =~ $re ]] || die "$MANFILE line $n is malformed; nothing was changed"
      sha="${BASH_REMATCH[1]}"; kind="${BASH_REMATCH[2]}"; path="${BASH_REMATCH[3]}"
      path_ok "$path" || die "$MANFILE line $n names an unsafe or unknown path; nothing was changed"
      if [[ "$kind" == owned ]] && ! owned_ok "$path"; then die "$MANFILE line $n marks $path as harness-owned, which this release never does; nothing was changed"; fi
      if awk -v p="$path" '$3==p{f=1} END{exit !f}' "$W/old"; then die "$MANFILE line $n repeats a path; nothing was changed"; fi
      printf '%s %s %s\n' "$sha" "$kind" "$path" >> "$W/old"
    done < "$T/$MANFILE"
    HAVE_MANIFEST=1
    v=""; hosts=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        version=*) v="${line#version=}";;
        hosts=*) hosts="${line#hosts=}";;
      esac
    done < "$T/$VERFILE"
    [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "$VERFILE has no valid version line"
    OLD_VERSION="$v"
    oldifs=$IFS; IFS=,
    for h in $hosts; do valid_host "$h" || { IFS=$oldifs; die "$VERFILE lists an unknown host"; }; OLD_HOSTS="$OLD_HOSTS $h"; done
    IFS=$oldifs
  fi
}
load_state

ver_cmp(){ # prints -1, 0 or 1
  local a="$1" b="$2" i x y
  for i in 1 2 3; do
    x="$(echo "$a" | cut -d. -f$i)"; y="$(echo "$b" | cut -d. -f$i)"
    if [[ $x -lt $y ]]; then echo -1; return; fi
    if [[ $x -gt $y ]]; then echo 1; return; fi
  done; echo 0; }

# ---------- what the release wants installed ----------
: > "$W/want"; mkdir "$W/gen"; GENN=0; : > "$W/snips"
src_ok(){ walk_clean "$SRC" "$1" && [[ -f "$SRC/$1" ]]; }
add_want(){ # kind dest srcfile
  local kind="$1" dest="$2" src="$3"
  path_ok "$dest" || die "internal error: bad destination $dest"
  [[ -f "$src" && ! -L "$src" ]] || die "release file is missing or is not a regular file: ${src#$SRC/}"
  if awk -F'\t' -v p="$dest" '$2==p{f=1} END{exit !f}' "$W/want"; then return 0; fi
  printf '%s\t%s\t%s\n' "$kind" "$dest" "$src" >> "$W/want"; }
add_rel(){ # kind dest relative-source
  src_ok "$3" || die "release file is missing or reachable through a link: $3"
  add_want "$1" "$2" "$SRC/$3"; }
gen_file(){ GENN=$((GENN+1)); echo "$W/gen/$GENN"; }
core_body(){ awk 'f{print} /^---$/{c++; if(c==2)f=1}' "$SRC/steering/00-welcome.md"; }

want_common(){ local s
  for s in guard-immutable-paths check-immutable-paths check-review-level check-licenses; do
    add_rel owned ".codifide/$s.sh" "templates/enforcement/$s.sh"; done
  add_rel seed ".codifide/immutable-paths" "templates/enforcement/immutable-paths.example"
  add_rel seed ".codifide/allowed-licenses" "templates/enforcement/allowed-licenses.example"
  add_rel seed ".github/workflows/codifide-enforcement.yml" "templates/enforcement/workflow.example.yml"; }
want_steering(){ # destination directory
  local f b; for f in "$SRC"/steering/[0-9][0-9]-*.md; do
    b="$(basename "$f")"; add_rel owned "$1/$b" "steering/$b"; done; }
want_stub(){ # dest, content
  local g; g="$(gen_file)"; printf '%s' "$2" > "$g"; add_want stub "$1" "$g"; }
want_host(){
  local h="$1" d g f b
  case "$h" in
    kiro)
      want_steering ".kiro/steering"
      add_rel owned ".kiro/hooks/guard-immutable-paths.json" "templates/hooks/kiro/guard-immutable-paths.json";;
    claude)
      src_ok "templates/hooks/claude-code/settings.example.json" || die "release file is missing or reachable through a link: templates/hooks/claude-code/settings.example.json"
      want_steering ".codifide/steering"
      want_stub "CLAUDE.md" "# Codifide Harness
@.codifide/steering/00-welcome.md
"
      ;;
    cursor)
      d="$W/mdc"; mkdir -p "$d"
      src_ok "templates/cursor/to-mdc.sh" || die "templates/cursor/to-mdc.sh is missing"
      for f in "$SRC"/steering/[0-9][0-9]-*.md; do src_ok "steering/$(basename "$f")" || die "release file is reachable through a link: steering/$(basename "$f")"; done
      bash "$SRC/templates/cursor/to-mdc.sh" "$d" "$SRC/steering" >/dev/null || die "the Cursor converter failed"
      for f in "$d"/*.mdc; do b="$(basename "$f")"; add_want owned ".cursor/rules/$b" "$f"; done;;
    copilot)
      src_ok "steering/00-welcome.md" || die "release file is missing or reachable through a link: steering/00-welcome.md"
      want_steering ".codifide/steering"
      g="$(gen_file)"
      { echo "<!-- Installed by Codifide Harness $VERSION. Source: steering/00-welcome.md. Other rules: .codifide/steering/ -->"; core_body; } > "$g"
      add_want stub ".github/copilot-instructions.md" "$g";;
    codex)
      want_steering ".codifide/steering"
      want_stub "AGENTS.md" "# Codifide Harness
Before any task, read .codifide/steering/00-welcome.md and follow it.
Load the other files in .codifide/steering/ when their topic applies (the core lists them).
"
      ;;
  esac; }

ALLHOSTS="$HOSTS"
if [[ "$CMD" != uninstall ]]; then
  for h in $OLD_HOSTS; do case "$ALLHOSTS" in *" $h "*) ;; *) ALLHOSTS="$ALLHOSTS$h ";; esac; done
  if [[ "$CMD" == upgrade ]]; then
    [[ $HAVE_MANIFEST -eq 1 ]] || die "nothing to upgrade: no $MANFILE in $T. Use install."
    [[ "$(ver_cmp "$VERSION" "$OLD_VERSION")" != "-1" || $FORCE -eq 1 ]] || die "this is v$VERSION and v$OLD_VERSION is installed. Downgrades need --force."
  else
    if [[ $HAVE_MANIFEST -eq 1 && "$OLD_VERSION" != "$VERSION" ]]; then
      die "v$OLD_VERSION is already installed; run upgrade to move to v$VERSION"
    fi
  fi
  [[ "$ALLHOSTS" != " " ]] || die "no host to install (pass --host)"
  want_common
  for h in $ALLHOSTS; do want_host "$h"; done
fi

# ---------- plan ----------
: > "$W/plan"; : > "$W/newent"; CONFLICTS=0; CHANGES=0
# State of every destination at plan time; rechecked just before each write (see check_state).
: > "$W/expect"
rec(){ local dest="$1" h
  if [[ -e "$T/$dest" || -L "$T/$dest" ]]; then
    if [[ -f "$T/$dest" && ! -L "$T/$dest" ]]; then h="$(hash_file "$T/$dest")"; else h="NOTFILE"; fi
  else h="ABSENT"; fi
  printf '%s\t%s\n' "$dest" "$h" >> "$W/expect"; }
expected_of(){ awk -F'\t' -v p="$1" '$1==p{print $2; exit}' "$W/expect"; }
check_state(){ local dest="$1" want have
  want="$(expected_of "$dest")"
  if [[ -e "$T/$dest" || -L "$T/$dest" ]]; then
    if [[ -f "$T/$dest" && ! -L "$T/$dest" ]]; then have="$(hash_file "$T/$dest")"; else have="NOTFILE"; fi
  else have="ABSENT"; fi
  if [[ -z "$want" || "$have" != "$want" ]]; then die "$dest changed while the installer was running; stopping and rolling back what this run wrote"; fi
  dest_ok "$dest" || die "$dest, or a directory above it, became a link while the installer was running"; }
old_sha(){ awk -v p="$1" '$3==p{print $1; exit}' "$W/old"; }
old_kind(){ awk -v p="$1" '$3==p{print $2; exit}' "$W/old"; }
in_want(){ awk -F'\t' -v p="$1" '$2==p{f=1} END{exit !f}' "$W/want"; }
plan(){ printf '%s\t%s\t%s\t%s\n' "$1" "$2" "${3:--}" "${4:--}" >> "$W/plan"; }
ent(){ printf '%s %s %s\n' "$1" "$2" "$3" >> "$W/newent"; }

if [[ "$CMD" != uninstall ]]; then
  while IFS=$'\t' read -r kind dest src; do
    dest_ok "$dest" || die "refusing: $dest is, or sits below, a symbolic link or a non-file. Nothing was written."
    rec "$dest"
    newsha="$(hash_file "$src")"; osha="$(old_sha "$dest")"; okind="$(old_kind "$dest")"
    if [[ ! -e "$T/$dest" ]]; then
      if [[ "$kind" == seed && -n "$okind" ]]; then plan keep "$dest" "$src" "you deleted it; not recreated"
      else plan create "$dest" "$src" "$kind"; CHANGES=$((CHANGES+1))
        if [[ "$kind" == owned ]]; then ent "$newsha" owned "$dest"; else ent "$newsha" seed "$dest"; fi
      fi
      continue
    fi
    cur="$(hash_file "$T/$dest")"
    case "$kind" in
      owned)
        if [[ "$cur" == "$newsha" ]]; then plan same "$dest" "$src"; ent "$newsha" owned "$dest"
        elif [[ -n "$osha" && "$osha" == "$cur" ]]; then plan update "$dest" "$src"; CHANGES=$((CHANGES+1)); ent "$newsha" owned "$dest"
        elif [[ $FORCE -eq 1 ]]; then plan overwrite "$dest" "$src" "edited locally"; CHANGES=$((CHANGES+1)); ent "$newsha" owned "$dest"
        else plan conflict "$dest" "$src" "edited locally, or not installed by this tool"; CONFLICTS=$((CONFLICTS+1)); fi;;
      seed)
        if [[ -n "$okind" ]]; then ent "$osha" seed "$dest"; fi
        if [[ "$cur" == "$newsha" ]]; then plan same "$dest" "$src"; else plan keep "$dest" "$src" "yours; differs from this release's template"; fi;;
      stub)
        if [[ -n "$okind" ]]; then
          ent "$osha" seed "$dest"
          if [[ "$cur" == "$newsha" ]]; then plan same "$dest" "$src"; else plan keep "$dest" "$src" "yours"; fi
        else plan snippet "$dest" "$src" "exists; not touched"; fi;;
    esac
  done < "$W/want"
  # entries the new release no longer ships
  while IFS=' ' read -r osha okind opath; do
    [[ -n "$opath" ]] || continue
    in_want "$opath" && continue
    dest_ok "$opath" || die "refusing: $opath is, or sits below, a symbolic link or a non-file. Nothing was written."
    rec "$opath"
    if [[ "$okind" == seed ]]; then plan forget "$opath" "" "no longer shipped; your file is left alone"
    elif [[ ! -e "$T/$opath" ]]; then plan gone "$opath" "" "already absent"
    elif [[ "$(hash_file "$T/$opath")" == "$osha" ]]; then plan remove "$opath" "" "no longer shipped"; CHANGES=$((CHANGES+1))
    else plan leftover "$opath" "" "no longer shipped, but edited; left in place"; fi
  done < "$W/old"
fi

# ---------- metadata ----------
mk_meta(){
  local hosts_csv="" h
  for h in $(echo $ALLHOSTS | tr ' ' '\n' | sort); do hosts_csv="${hosts_csv:+$hosts_csv,}$h"; done
  { echo "version=$VERSION"; echo "pinned=$PINNED"; echo "source=$SOURCE_KIND"; echo "hosts=$hosts_csv"; } > "$W/newver"
  { echo "# codifide-harness-manifest 1"; echo "# version $VERSION"; LC_ALL=C sort -k3 "$W/newent"; } > "$W/newman"; }

describe_plan(){ local act kind path src note
  while IFS=$'\t' read -r act path src note; do
    case "$act" in
      create|update|overwrite|remove) printf '  %-9s %s\n' "$act" "$path";;
      same) printf '  %-9s %s\n' "same" "$path";;
      keep|snippet|forget|gone|leftover|conflict) printf '  %-9s %s  (%s)\n' "$act" "$path" "$note";;
    esac
  done < "$W/plan"; }
show_diffs(){ local act path src
  while IFS=$'\t' read -r act path src _; do
    case "$act" in update|overwrite|conflict)
      echo; diff -u -L "installed/$path" -L "v$VERSION/$path" "$T/$path" "$src" | sed -n '1,120p' || true;; esac
  done < "$W/plan"; }
show_snippets(){ local act path src printed=0
  while IFS=$'\t' read -r act path src _; do
    if [[ "$act" == snippet ]]; then
      if [[ $printed -eq 0 ]]; then echo; echo "Merge by hand (these files exist and were not touched):"; printed=1; fi
      echo "--- $path: add the following ---"; sed -n '1,40p' "$src"; echo "---"
    fi
  done < "$W/plan"
  case "$ALLHOSTS" in *" claude "*)
    echo; echo "Claude Code: .claude/settings.json is never written by this installer. Merge this into it:"
    echo "--- .claude/settings.json: merge ---"; cat "$SRC/templates/hooks/claude-code/settings.example.json"; echo "---";; esac; }

# ---------- applying (all-or-nothing) ----------
journal(){ printf '%s|%s|%s\n' "$1" "$2" "${3:-}" >> "$JOURNAL"; }
backup(){ # called inside $(...), so the counter lives on disk. Fails loudly, and checks the copy is what was planned.
  local dest="$1" n want got
  want="$(expected_of "$dest")"
  n=$(( $(ls "$W/bk" | wc -l | tr -d ' ') + 1 ))
  if ! cp -p "$T/$dest" "$W/bk/$n"; then rm -f "$W/bk/$n"; echo "install.sh: could not back up $dest" >&2; return 1; fi
  got="$(hash_file "$W/bk/$n")"
  if [[ -z "$want" || "$got" != "$want" ]]; then rm -f "$W/bk/$n"; echo "install.sh: $dest changed while the installer was running" >&2; return 1; fi
  echo "$n"; }
ensure_dirs(){ local p="$1" cur="$T" c oldifs=$IFS parts rest
  rest="${p%/*}"; [[ "$rest" != "$p" ]] || return 0
  IFS=/; for c in $rest; do
    cur="$cur/$c"
    if [[ ! -d "$cur" ]]; then mkdir "$cur"; journal M "${cur#$T/}"; fi
  done; IFS=$oldifs; }
put(){ # src dest   (create or replace, atomically, journaled)
  local src="$1" dest="$2" n parent want
  check_state "$dest"
  ensure_dirs "$dest"
  parent="$(dirname "$T/$dest")"
  if [[ -e "$T/$dest" ]]; then n="$(backup "$dest")" || die "stopping: $dest was not backed up"; journal R "$dest" "$n"; else journal C "$dest"; fi
  want="$(hash_file "$src")"
  TMPFILE="$(mktemp "$parent/.codifide-tmp.XXXXXX")" || die "cannot create a temporary file in $parent"
  cp "$src" "$TMPFILE"
  if [[ -L "$TMPFILE" || ! -f "$TMPFILE" || "$(hash_file "$TMPFILE")" != "$want" ]]; then die "the temporary file for $dest was replaced or damaged; stopping"; fi
  case "$dest" in *.sh) chmod 755 "$TMPFILE";; *) chmod 644 "$TMPFILE";; esac
  mv -f "$TMPFILE" "$T/$dest"; TMPFILE=""; }
drop(){ local dest="$1" n; check_state "$dest"; n="$(backup "$dest")" || die "stopping: $dest was not backed up"; journal D "$dest" "$n"; rm -f "$T/$dest"; }
prune_dirs(){ local p="$1" d
  d="${p%/*}"
  while [[ "$d" != "$p" && -n "$d" && "$d" != "." ]]; do
    rmdir "$T/$d" 2>/dev/null || break
    p="$d"; d="${p%/*}"; [[ "$d" != "$p" ]] || break
  done; }

finish_notes(){
  echo
  echo "Nothing was committed or pushed. Review with git status and git diff, then commit through a normal pull request."
  case "$ALLHOSTS" in *" kiro "*) echo "Kiro: whether the host honours exit code 2 from the guard hook is unverified by us. Run the check in templates/enforcement/README.md.";; esac
  echo "Next: edit .codifide/immutable-paths and .codifide/allowed-licenses, and set the repository variable CODIFIDE_LICENSE_REPORT_CMD."; }

if [[ "$CMD" == uninstall ]]; then
  [[ $HAVE_MANIFEST -eq 1 ]] || die "nothing to uninstall: no $MANFILE in $T"
  : > "$W/keepent"; RM=0
  while IFS=' ' read -r osha okind opath; do
    [[ -n "$opath" ]] || continue
    dest_ok "$opath" || die "refusing: $opath is, or sits below, a symbolic link or a non-file. Nothing was removed."
    rec "$opath"
    if [[ ! -e "$T/$opath" ]]; then plan gone "$opath" "" "already absent"
    elif [[ "$(hash_file "$T/$opath")" == "$osha" ]]; then plan remove "$opath" "" "unmodified"; RM=$((RM+1))
    else plan keep "$opath" "" "edited since install; left in place"; printf '%s %s %s\n' "$osha" "$okind" "$opath" >> "$W/keepent"; fi
  done < "$W/old"
  rec "$MANFILE"; rec "$VERFILE"
  echo "codifide-harness uninstall of v$OLD_VERSION from $T$([[ $APPLY -eq 1 ]] || echo ' (DRY RUN)')"
  describe_plan
  if [[ $APPLY -ne 1 ]]; then echo; echo "Dry run: nothing was written. Re-run with --apply to remove the $RM unmodified file(s) above."; exit 0; fi
  APPLYING=1
  while IFS=$'\t' read -r act path _; do
    if [[ "$act" == remove ]]; then drop "$path"; fi
  done < "$W/plan"
  if [[ -s "$W/keepent" ]]; then
    { echo "# codifide-harness-manifest 1"; echo "# version $OLD_VERSION"; LC_ALL=C sort -k3 "$W/keepent"; } > "$W/newman"
    put "$W/newman" "$MANFILE"
  else
    drop "$MANFILE"; drop "$VERFILE"
  fi
  while IFS=$'\t' read -r act path _; do
    if [[ "$act" == remove ]]; then prune_dirs "$path"; fi
  done < "$W/plan"
  prune_dirs "$MANFILE"
  APPLYING=0
  echo; echo "Removed $RM file(s). Nothing was committed."
  [[ ! -s "$W/keepent" ]] || echo "Files you edited were left in place and stay listed in $MANFILE; run uninstall again after you restore or delete them."
  exit 0
fi

mk_meta
rec "$MANFILE"; rec "$VERFILE"
META_CHANGED=0
if [[ ! -f "$T/$MANFILE" ]] || ! cmp -s "$W/newman" "$T/$MANFILE"; then META_CHANGED=1; fi
if [[ ! -f "$T/$VERFILE" ]] || ! cmp -s "$W/newver" "$T/$VERFILE"; then META_CHANGED=1; fi

echo "codifide-harness $VERSION $CMD (pinned=$PINNED, source=$SOURCE_KIND) into $T$([[ $APPLY -eq 1 ]] || echo ' (DRY RUN)')"
echo "hosts:$ALLHOSTS"
describe_plan
show_diffs
show_snippets
if [[ $CONFLICTS -gt 0 ]]; then
  echo
  die "$CONFLICTS harness-owned file(s) were edited locally or were not installed by this tool. Nothing was written. Review the diffs above, then re-run with --force to overwrite them."
fi
if [[ $CHANGES -eq 0 && $META_CHANGED -eq 0 ]]; then
  echo; echo "Nothing to change."; exit 0
fi
if [[ $APPLY -ne 1 ]]; then
  echo; echo "Dry run: nothing was written. Re-run with --apply to write $CHANGES file(s)."; exit 0
fi

APPLYING=1
while IFS=$'\t' read -r act path src _; do
  case "$act" in
    create|update|overwrite) put "$src" "$path";;
    remove) drop "$path";;
  esac
done < "$W/plan"
put "$W/newman" "$MANFILE"
put "$W/newver" "$VERFILE"
while IFS=$'\t' read -r act path _; do
  if [[ "$act" == remove ]]; then prune_dirs "$path"; fi
done < "$W/plan"
APPLYING=0
echo; echo "Wrote $CHANGES file(s) and the manifest."
finish_notes
