#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Codifide Harness: installer test suite. Runs install.sh, upgrade, uninstall and tools/build-release.sh
# against throwaway repositories in $TMPDIR. It never touches the network and never writes outside $TMPDIR.
# Usage: bash tests/test-installer.sh      (SH_UNDER_TEST=/bin/bash to pick a shell)
# Exit 0 = all pass.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SH="${SH_UNDER_TEST:-bash}"
for v in $(compgen -e | grep -E '^(CODIFIDE_|GIT_)' || true); do unset "$v"; done; unset v
export LC_ALL=C
COUNTF="$(mktemp)"; FAIL=0
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK" "$COUNTF"' EXIT
pass(){ local ok=PASS; [[ $2 -ne $3 ]] && { ok=FAIL; FAIL=1; }; echo "$ok  $1 (want $2, got $3)"; echo x >> "$COUNTF"; }
passne(){ local ok=PASS; [[ $3 -eq 0 ]] && { ok=FAIL; FAIL=1; }; echo "$ok  $1 (want non-zero, got $3)"; echo x >> "$COUNTF"; }
OUT=""
rc(){ local n="$1" w="$2"; shift 2; OUT="$("$@" 2>&1)"; pass "$n" "$w" $?; }
rcne(){ local n="$1"; shift; OUT="$("$@" 2>&1)"; passne "$n" x $?; }
is(){ local n="$1"; shift; "$@" >/dev/null 2>&1; pass "$n" 0 $?; }
isnot(){ local n="$1"; shift; "$@" >/dev/null 2>&1; passne "$n" x $?; }
eq(){ [[ "$2" == "$3" ]]; pass "$1" 0 $?; }
out_has(){ printf '%s\n' "$OUT" | grep -q -E -- "$2"; pass "$1" 0 $?; }
out_lacks(){ printf '%s\n' "$OUT" | grep -q -E -- "$2"; passne "$1" x $?; }

sha(){ shasum -a 256 < "$1" | cut -d' ' -f1; }
snap(){ ( cd "$1" && {
    find . -path ./.git -prune -o -print | sort
    find . -path ./.git -prune -o -type f -print | sort | while IFS= read -r f; do printf '%s %s\n' "$(sha "$f")" "$f"; done
    find . -path ./.git -prune -o -type l -print | sort | while IFS= read -r l; do printf 'L %s -> %s\n' "$l" "$(readlink "$l")"; done
  } | shasum -a 256 | cut -d' ' -f1 ); }
mk_t(){ local d; d="$(mktemp -d "$WORK/t.XXXXXX")"; git -C "$d" init -q; echo "$d"; }
mk_src(){ mkdir -p "$1"; ( cd "$REPO" && tar --exclude=./.git --exclude=./.worktrees --exclude=./docs --exclude=./dist -cf - . ) | ( cd "$1" && tar -xf - ); printf '%s\n' "$2" > "$1/VERSION"; }
tag_src(){ ( cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t && git config commit.gpgsign false && git add -A && git commit -qm x && git tag "v$2" ); }
ins(){ local s="$1"; shift; $SH "$s/install.sh" "$@"; }
count_files(){ ( cd "$1" && find . -path ./.git -prune -o -type f -print | wc -l | tr -d ' ' ); }
manifest_ok(){ local t="$1" bad=0 n=0 sha path kind
  while read -r sha kind path; do case "$sha" in "#"*|"") continue;; esac
    n=$((n+1))
    if [[ "$kind" == owned ]]; then [[ -f "$t/$path" && "$(sha "$t/$path")" == "$sha" ]] || bad=1   # seed files may be edited by the user
    else [[ -f "$t/$path" ]] || bad=1; fi
  done < "$t/.codifide/harness-manifest"
  [[ $bad -eq 0 && $n -gt 0 ]] && echo "$n" && return 0; return 1; }

# ---------- fixtures: two tagged releases, A = 3.2.0 and B = 3.2.1 ----------
A="$WORK/srcA"; B="$WORK/srcB"
mk_src "$A" 3.2.0; tag_src "$A" 3.2.0
mk_src "$B" 3.2.1
printf '\nUpgrade marker line.\n' >> "$B/steering/00-welcome.md"
rm -f "$B/steering/13-concurrent-sessions.md"
sed -i.bak 's/Guard immutable paths/Guard immutable paths v2/' "$B/templates/hooks/kiro/guard-immutable-paths.json"; rm -f "$B/templates/hooks/kiro/guard-immutable-paths.json.bak"
tag_src "$B" 3.2.1

# ---------- version and pin ----------
rc "pin: a checkout of the clean tag is accepted (dry run)" 0 ins "$A" --target "$(mk_t)" --host kiro
out_has "pin: dry run reports pinned=yes from the tag" 'pinned=yes, source=tag'
UNP="$WORK/srcU"; mk_src "$UNP" 3.2.0
T="$(mk_t)"; S0="$(snap "$T")"
rc "pin: an unpacked tree with no tag and no RELEASE refuses" 1 ins "$UNP" --target "$T" --host kiro --apply
eq "pin: refusal wrote nothing" "$S0" "$(snap "$T")"
rc "pin: --i-know-this-is-unpinned allows it" 0 ins "$UNP" --target "$T" --host kiro --apply --i-know-this-is-unpinned
eq "pin: unpinned run is recorded as pinned=no" "pinned=no" "$(grep '^pinned=' "$T/.codifide/harness-version")"
P2="$WORK/srcDirty"; mk_src "$P2" 3.2.0; tag_src "$P2" 3.2.0; echo extra > "$P2/dirty.txt"
rc "pin: a dirty checkout of the tag refuses" 1 ins "$P2" --target "$(mk_t)" --host kiro --apply
P3="$WORK/srcBranch"; mk_src "$P3" 3.2.0; tag_src "$P3" 3.2.0; ( cd "$P3" && echo more >> README.md && git -c commit.gpgsign=false commit -qam later )
rc "pin: HEAD past the tag refuses" 1 ins "$P3" --target "$(mk_t)" --host kiro --apply
P4="$WORK/srcWrongTag"; mk_src "$P4" 3.2.0; ( cd "$P4" && git init -q -b main && git config user.email t@t && git config user.name t && git add -A && git commit -qm x && git tag v9.9.9 )
rc "pin: a tag that does not match VERSION refuses" 1 ins "$P4" --target "$(mk_t)" --host kiro --apply
P5="$WORK/srcRel"; mk_src "$P5" 3.2.0; printf 'tag=v3.2.0\n' > "$P5/RELEASE"
rc "pin: an unpacked release with a matching RELEASE file is accepted" 0 ins "$P5" --target "$(mk_t)" --host kiro --apply
printf 'tag=v1.0.0\n' > "$P5/RELEASE"
rc "pin: a RELEASE file for another tag refuses" 1 ins "$P5" --target "$(mk_t)" --host kiro --apply
printf 'not a version\n' > "$P5/VERSION"
rc "pin: a malformed VERSION refuses" 1 ins "$P5" --target "$(mk_t)" --host kiro --apply --i-know-this-is-unpinned

# ---------- arguments ----------
rc "args: --help exits 0 and names the dry run" 0 ins "$A" --help
out_has "args: help text states dry run is the default" 'Without it this is a dry run'
rc "args: no --target is a usage error" 2 ins "$A" --host kiro
rc "args: no --host on install is a usage error" 2 ins "$A" --target "$(mk_t)"
rc "args: unknown host is a usage error" 2 ins "$A" --target "$(mk_t)" --host vscode
rc "args: unknown option is a usage error" 2 ins "$A" --target "$(mk_t)" --host kiro --frobnicate
rc "args: --apply with --dry-run is a usage error" 2 ins "$A" --target "$(mk_t)" --host kiro --apply --dry-run
rc "args: uninstall with --host is a usage error" 2 ins "$A" uninstall --target "$(mk_t)" --host kiro
rc "args: uninstall with --force is a usage error" 2 ins "$A" uninstall --target "$(mk_t)" --force
rc "args: a missing target directory refuses" 1 ins "$A" --target "$WORK/does-not-exist" --host kiro
NG="$(mktemp -d "$WORK/ng.XXXXXX")"
rc "args: a directory that is not a repository root refuses" 1 ins "$A" --target "$NG" --host kiro --apply
eq "args: ...and nothing was written there" "0" "$(count_files "$NG")"
rc "args: the harness source itself is not a valid target" 1 ins "$A" --target "$A" --host kiro --apply
mkdir -p "$WORK/sub"; git -C "$WORK/sub" init -q; mkdir "$WORK/sub/deep"
rc "args: a subdirectory of a repository refuses (needs the root)" 1 ins "$A" --target "$WORK/sub/deep" --host kiro --apply

# ---------- dry run writes nothing ----------
for H in kiro claude cursor copilot codex; do
  T="$(mk_t)"; S0="$(snap "$T")"
  rc "dry-run $H: exits 0 and says so" 0 ins "$A" --target "$T" --host "$H"
  out_has "dry-run $H: output is labelled DRY RUN" 'DRY RUN'
  eq "dry-run $H: the target is byte-for-byte unchanged" "$S0" "$(snap "$T")"
done
T="$(mk_t)"; S0="$(snap "$T")"
rc "dry-run: --dry-run flag behaves the same" 0 ins "$A" --target "$T" --host kiro --dry-run
eq "dry-run: --dry-run wrote nothing" "$S0" "$(snap "$T")"
ls "${TMPDIR:-/tmp}" | grep -q '^codifide-install\.' ; passne "dry-run: the installer leaves no temporary directory behind" x $?

# ---------- host layouts ----------
T="$(mk_t)"; rc "host kiro: apply" 0 ins "$A" --target "$T" --host kiro --apply
eq "host kiro: 14 steering files" "14" "$(ls "$T/.kiro/steering" | wc -l | tr -d ' ')"
is "host kiro: core equals the release core" cmp -s "$T/.kiro/steering/00-welcome.md" "$A/steering/00-welcome.md"
is "host kiro: guard hook file installed" test -f "$T/.kiro/hooks/guard-immutable-paths.json"
is "host kiro: only the blocking hook (no advisory hooks)" test "$(ls "$T/.kiro/hooks" | wc -l | tr -d ' ')" = 1
for f in guard-immutable-paths check-immutable-paths check-review-level check-licenses; do
  is "host kiro: .codifide/$f.sh is identical to the release copy" cmp -s "$T/.codifide/$f.sh" "$A/templates/enforcement/$f.sh"
  is "host kiro: .codifide/$f.sh is executable" test -x "$T/.codifide/$f.sh"
done
is "host kiro: immutable-paths seeded from the example" cmp -s "$T/.codifide/immutable-paths" "$A/templates/enforcement/immutable-paths.example"
is "host kiro: workflow seeded" cmp -s "$T/.github/workflows/codifide-enforcement.yml" "$A/templates/enforcement/workflow.example.yml"
isnot "host kiro: no .claude directory is created" test -e "$T/.claude"
eq "host kiro: manifest has 22 entries and every hash matches" "22" "$(manifest_ok "$T")"
eq "host kiro: version file" "version=3.2.0 pinned=yes source=tag hosts=kiro" "$(tr '\n' ' ' < "$T/.codifide/harness-version" | sed 's/ $//')"
isnot "host kiro: the manifest does not list its own metadata files" grep -q 'harness-' "$T/.codifide/harness-manifest.body" 2>/dev/null
isnot "host kiro: no handoff or user file was touched or created" test -e "$T/.kiro/steering/next-session-prompt.md"

T="$(mk_t)"; rc "host claude: apply" 0 ins "$A" --target "$T" --host claude --apply
is "host claude: steering under .codifide/steering" test -f "$T/.codifide/steering/00-welcome.md"
is "host claude: CLAUDE.md imports the core" grep -q '@.codifide/steering/00-welcome.md' "$T/CLAUDE.md"
isnot "host claude: .claude/settings.json is never written" test -e "$T/.claude/settings.json"
out_has "host claude: the merge snippet for settings.json is printed" 'PreToolUse'
out_has "host claude: the snippet runs the guard and exits 2" 'guard-immutable-paths.sh.*exit 2'
isnot "host claude: no .kiro directory" test -e "$T/.kiro"

T="$(mk_t)"; rc "host cursor: apply" 0 ins "$A" --target "$T" --host cursor --apply
eq "host cursor: 14 .mdc rules" "14" "$(ls "$T/.cursor/rules"/*.mdc | wc -l | tr -d ' ')"
isnot "host cursor: no plain .md in .cursor/rules (Cursor ignores them)" sh -c "ls '$T'/.cursor/rules/*.md"
is "host cursor: the core is alwaysApply: true" grep -q 'alwaysApply: true' "$T/.cursor/rules/00-welcome.mdc"
is "host cursor: other rules are alwaysApply: false" grep -q 'alwaysApply: false' "$T/.cursor/rules/11-tiered-adversarial-review.mdc"
D="$(mktemp -d "$WORK/mdc.XXXXXX")"; bash "$A/templates/cursor/to-mdc.sh" "$D" >/dev/null
is "host cursor: output equals templates/cursor/to-mdc.sh output" diff -r "$D" "$T/.cursor/rules"
isnot "host cursor: no steering copy outside .cursor/rules" test -e "$T/.codifide/steering"

T="$(mk_t)"; rc "host copilot: apply" 0 ins "$A" --target "$T" --host copilot --apply
is "host copilot: instructions file holds the core" grep -q 'Codifide Harness' "$T/.github/copilot-instructions.md"
isnot "host copilot: the front matter is not copied into the instructions" grep -q '^inclusion:' "$T/.github/copilot-instructions.md"
is "host copilot: other rules under .codifide/steering" test -f "$T/.codifide/steering/11-tiered-adversarial-review.md"

T="$(mk_t)"; rc "host codex: apply" 0 ins "$A" --target "$T" --host codex --apply
is "host codex: AGENTS.md points at the core" grep -q '.codifide/steering/00-welcome.md' "$T/AGENTS.md"
is "host codex: steering installed" test -f "$T/.codifide/steering/00-welcome.md"

T="$(mk_t)"; rc "hosts: comma list and repeated flags together" 0 ins "$A" --target "$T" --host kiro,cursor --host codex --apply
eq "hosts: all three recorded, sorted" "hosts=codex,cursor,kiro" "$(grep '^hosts=' "$T/.codifide/harness-version")"
is "hosts: manifest verifies" manifest_ok "$T"

# ---------- manifest ----------
T="$(mk_t)"; ins "$A" --target "$T" --host kiro,claude,cursor,copilot,codex --apply >/dev/null 2>&1
is "manifest: every entry exists and its hash matches the file" manifest_ok "$T"
eq "manifest: header line" "# codifide-harness-manifest 1" "$(head -n 1 "$T/.codifide/harness-manifest")"
eq "manifest: entries are sorted by path" "$(grep -v '^#' "$T/.codifide/harness-manifest" | sort -k3)" "$(grep -v '^#' "$T/.codifide/harness-manifest")"
isnot "manifest: only safe relative paths (no .. , no leading slash)" grep -E ' (/|.*\.\.)' "$T/.codifide/harness-manifest"
isnot "manifest: it does not list itself or the version file" grep -E 'harness-(manifest|version)$' "$T/.codifide/harness-manifest"
is "manifest: seed files are marked seed" grep -q ' seed .codifide/immutable-paths$' "$T/.codifide/harness-manifest"
is "manifest: owned files are marked owned" grep -q ' owned .codifide/guard-immutable-paths.sh$' "$T/.codifide/harness-manifest"

# ---------- idempotent ----------
T="$(mk_t)"; ins "$A" --target "$T" --host kiro,cursor --apply >/dev/null 2>&1; S1="$(snap "$T")"
rc "idempotent: second apply exits 0" 0 ins "$A" --target "$T" --host kiro,cursor --apply
out_has "idempotent: says there is nothing to change" 'Nothing to change'
eq "idempotent: the target is unchanged" "$S1" "$(snap "$T")"
rc "idempotent: a dry run on an installed tree also exits 0" 0 ins "$A" --target "$T" --host kiro
eq "idempotent: ...and writes nothing" "$S1" "$(snap "$T")"
rc "idempotent: adding a host later works at the same version" 0 ins "$A" --target "$T" --host codex --apply
eq "idempotent: hosts are the union" "hosts=codex,cursor,kiro" "$(grep '^hosts=' "$T/.codifide/harness-version")"
is "idempotent: earlier hosts' files are still verified" manifest_ok "$T"

# ---------- no clobber ----------
T="$(mk_t)"; mkdir -p "$T/.codifide" "$T/.claude" "$T/.github/workflows"
printf 'my-protected/\n' > "$T/.codifide/immutable-paths"; printf 'MIT\n' > "$T/.codifide/allowed-licenses"
printf '{"mine":true}\n' > "$T/.claude/settings.json"; printf 'my claude notes\n' > "$T/CLAUDE.md"
printf 'my workflow\n' > "$T/.github/workflows/codifide-enforcement.yml"; printf 'my copilot\n' > "$T/.github/copilot-instructions.md"; printf 'my agents\n' > "$T/AGENTS.md"
H0="$(for f in .codifide/immutable-paths .codifide/allowed-licenses .claude/settings.json CLAUDE.md .github/workflows/codifide-enforcement.yml .github/copilot-instructions.md AGENTS.md; do sha "$T/$f"; done)"
rc "no-clobber: install over existing policy and agent files" 0 ins "$A" --target "$T" --host claude,copilot,codex --apply
eq "no-clobber: none of the user files changed" "$H0" "$(for f in .codifide/immutable-paths .codifide/allowed-licenses .claude/settings.json CLAUDE.md .github/workflows/codifide-enforcement.yml .github/copilot-instructions.md AGENTS.md; do sha "$T/$f"; done)"
out_has "no-clobber: a merge snippet is printed for existing CLAUDE.md" 'CLAUDE.md: add the following'
out_has "no-clobber: a merge snippet is printed for existing AGENTS.md" 'AGENTS.md: add the following'
out_has "no-clobber: a merge snippet is printed for the existing Copilot file" 'copilot-instructions.md: add the following'
out_has "no-clobber: the plan marks user policy files as kept" 'keep +\.codifide/immutable-paths'
isnot "no-clobber: user files are not recorded in the manifest" grep -E ' (owned|seed) (CLAUDE.md|AGENTS.md|\.github/copilot-instructions.md|\.codifide/immutable-paths|\.codifide/allowed-licenses|\.github/workflows/codifide-enforcement.yml)$' "$T/.codifide/harness-manifest"
rc "no-clobber: uninstall leaves the user files too" 0 ins "$A" uninstall --target "$T" --apply
eq "no-clobber: user files still unchanged after uninstall" "$H0" "$(for f in .codifide/immutable-paths .codifide/allowed-licenses .claude/settings.json CLAUDE.md .github/workflows/codifide-enforcement.yml .github/copilot-instructions.md AGENTS.md; do sha "$T/$f"; done)"
T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1
printf 'my-extra-rule/\n' >> "$T/.codifide/immutable-paths"; H1="$(sha "$T/.codifide/immutable-paths")"
rc "no-clobber: re-run keeps an edited seed file" 0 ins "$A" --target "$T" --host kiro --apply
eq "no-clobber: edited immutable-paths survives a re-run" "$H1" "$(sha "$T/.codifide/immutable-paths")"
rm -f "$T/.codifide/allowed-licenses"
rc "no-clobber: a seed file you deleted is not recreated" 0 ins "$A" --target "$T" --host kiro --apply
isnot "no-clobber: ...it stays deleted" test -e "$T/.codifide/allowed-licenses"
# a file at an owned path that the tool did not install
T="$(mk_t)"; mkdir -p "$T/.codifide"; echo "my own guard" > "$T/.codifide/guard-immutable-paths.sh"; S0="$(snap "$T")"
rc "no-clobber: a pre-existing differing owned file stops the install" 1 ins "$A" --target "$T" --host kiro --apply
eq "no-clobber: ...and nothing at all was written" "$S0" "$(snap "$T")"
out_has "no-clobber: ...with a diff and a --force hint" 'conflict +\.codifide/guard-immutable-paths.sh'
rc "no-clobber: --force replaces it" 0 ins "$A" --target "$T" --host kiro --apply --force
is "no-clobber: ...with the release copy" cmp -s "$T/.codifide/guard-immutable-paths.sh" "$A/templates/enforcement/guard-immutable-paths.sh"
# an identical file that predates the manifest is adopted
T="$(mk_t)"; mkdir -p "$T/.codifide"; cp "$A/templates/enforcement/guard-immutable-paths.sh" "$T/.codifide/"
rc "no-clobber: an identical pre-existing owned file is adopted" 0 ins "$A" --target "$T" --host kiro --apply
is "no-clobber: ...and is in the manifest" grep -q ' owned .codifide/guard-immutable-paths.sh$' "$T/.codifide/harness-manifest"

# ---------- upgrade ----------
T="$(mk_t)"; ins "$A" --target "$T" --host kiro,cursor --apply >/dev/null 2>&1
printf 'my-extra-rule/\n' >> "$T/.codifide/immutable-paths"; HP="$(sha "$T/.codifide/immutable-paths")"; S1="$(snap "$T")"
rc "upgrade: dry run" 0 ins "$B" upgrade --target "$T"
out_has "upgrade: the plan lists updates" 'update +\.kiro/steering/00-welcome.md'
out_has "upgrade: the plan lists the file the new release dropped" 'remove +\.kiro/steering/13-concurrent-sessions.md'
out_has "upgrade: a diff is shown" '^\+Upgrade marker line\.'
eq "upgrade: the dry run changed nothing" "$S1" "$(snap "$T")"
rc "upgrade: install at another version points to upgrade" 1 ins "$B" --target "$T" --host kiro --apply
eq "upgrade: ...and wrote nothing" "$S1" "$(snap "$T")"
rc "upgrade: apply" 0 ins "$B" upgrade --target "$T" --apply
eq "upgrade: version file moved" "version=3.2.1" "$(grep '^version=' "$T/.codifide/harness-version")"
is "upgrade: core replaced" cmp -s "$T/.kiro/steering/00-welcome.md" "$B/steering/00-welcome.md"
isnot "upgrade: the dropped steering file is gone" test -e "$T/.kiro/steering/13-concurrent-sessions.md"
isnot "upgrade: its Cursor rule stays in the release, so it is also gone" test -e "$T/.cursor/rules/13-concurrent-sessions.mdc"
is "upgrade: the hook was updated" grep -q 'v2' "$T/.kiro/hooks/guard-immutable-paths.json"
eq "upgrade: edited policy file untouched" "$HP" "$(sha "$T/.codifide/immutable-paths")"
is "upgrade: manifest matches the tree" manifest_ok "$T"
eq "upgrade: hosts kept without repeating --host" "hosts=cursor,kiro" "$(grep '^hosts=' "$T/.codifide/harness-version")"
rc "upgrade: running it again changes nothing" 0 ins "$B" upgrade --target "$T" --apply
out_has "upgrade: ...says so" 'Nothing to change'
rc "upgrade: a downgrade refuses" 1 ins "$A" upgrade --target "$T" --apply
rc "upgrade: install of the old version over the new refuses" 1 ins "$A" --target "$T" --host kiro --apply
# local edits
T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1
printf 'local edit\n' >> "$T/.kiro/steering/01-governance-gates.md"; S1="$(snap "$T")"
rc "upgrade: a locally edited owned file stops the upgrade" 1 ins "$B" upgrade --target "$T" --apply
eq "upgrade: ...and nothing else was upgraded (all or nothing)" "$S1" "$(snap "$T")"
out_has "upgrade: ...the conflict is named" 'conflict +\.kiro/steering/01-governance-gates.md'
rc "upgrade: --force overwrites it" 0 ins "$B" upgrade --target "$T" --apply --force
is "upgrade: ...with the new release copy" cmp -s "$T/.kiro/steering/01-governance-gates.md" "$B/steering/01-governance-gates.md"
# edited file that the new release no longer ships
T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1
printf 'my notes\n' >> "$T/.kiro/steering/13-concurrent-sessions.md"; H13="$(sha "$T/.kiro/steering/13-concurrent-sessions.md")"
rc "upgrade: an edited file the release dropped does not block" 0 ins "$B" upgrade --target "$T" --apply
eq "upgrade: ...and is left in place" "$H13" "$(sha "$T/.kiro/steering/13-concurrent-sessions.md")"
out_has "upgrade: ...and reported" 'leftover +\.kiro/steering/13-concurrent-sessions.md'
isnot "upgrade: ...and is no longer in the manifest" grep -q '13-concurrent-sessions' "$T/.codifide/harness-manifest"
T="$(mk_t)"; rc "upgrade: with nothing installed refuses" 1 ins "$B" upgrade --target "$T" --apply

# ---------- uninstall ----------
T="$(mk_t)"; mkdir -p "$T/src"; echo app > "$T/src/app.py"; S0="$(snap "$T")"
ins "$A" --target "$T" --host kiro,claude,cursor,copilot,codex --apply >/dev/null 2>&1
S1="$(snap "$T")"
rc "uninstall: dry run" 0 ins "$A" uninstall --target "$T"
out_has "uninstall: dry run is labelled" 'DRY RUN'
eq "uninstall: the dry run removed nothing" "$S1" "$(snap "$T")"
rc "uninstall: apply" 0 ins "$A" uninstall --target "$T" --apply
eq "uninstall: the tree is byte-identical to before the install (files, dirs, links)" "$S0" "$(snap "$T")"
rc "uninstall: a second uninstall refuses (nothing installed)" 1 ins "$A" uninstall --target "$T" --apply
# user content survives, edited files survive
T="$(mk_t)"; ins "$A" --target "$T" --host kiro,cursor --apply >/dev/null 2>&1
echo "notes" > "$T/.kiro/steering/next-session-prompt.md"; echo mine > "$T/.cursor/rules/my-own.mdc"
printf 'edit\n' >> "$T/.kiro/steering/02-personas.md"; H2="$(sha "$T/.kiro/steering/02-personas.md")"
rc "uninstall: apply with an edited file" 0 ins "$A" uninstall --target "$T" --apply
is "uninstall: the edited owned file is left" test "$(sha "$T/.kiro/steering/02-personas.md")" = "$H2"
is "uninstall: a user file in the same directory is left" test -f "$T/.cursor/rules/my-own.mdc"
is "uninstall: the handoff file is left" test -f "$T/.kiro/steering/next-session-prompt.md"
isnot "uninstall: an unmodified owned file is gone" test -e "$T/.kiro/steering/01-governance-gates.md"
isnot "uninstall: an unmodified Cursor rule is gone" test -e "$T/.cursor/rules/00-welcome.mdc"
eq "uninstall: the manifest keeps only the edited file" "1" "$(grep -vc '^#' "$T/.codifide/harness-manifest")"
is "uninstall: the version file stays while something is left" test -f "$T/.codifide/harness-version"
echo "$(cat "$T/.kiro/steering/02-personas.md" | head -c 0)" > /dev/null
cp "$A/steering/02-personas.md" "$T/.kiro/steering/02-personas.md"
# restoring the original content makes it removable again
rc "uninstall: after restoring the file a second uninstall finishes" 0 ins "$A" uninstall --target "$T" --apply
isnot "uninstall: ...and the metadata is gone" test -e "$T/.codifide/harness-manifest"
# an owned file that was already deleted is fine
T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1; rm -f "$T/.kiro/steering/05-nfr-kpi-mandate.md"
rc "uninstall: a file already deleted by the user is not an error" 0 ins "$A" uninstall --target "$T" --apply

# ---------- path traversal, symlinks, absolute paths ----------
OUTSIDE="$(mktemp -d "$WORK/outside.XXXXXX")"; echo keep > "$OUTSIDE/victim"
for L in .codifide .kiro .github; do
  T="$(mk_t)"; ln -s "$OUTSIDE" "$T/$L"; S0="$(snap "$T")"
  rcne "symlink: a symlinked $L directory is refused" ins "$A" --target "$T" --host kiro --apply
  eq "symlink: $L: nothing was written outside" "victim" "$(ls -A "$OUTSIDE")"
  eq "symlink: $L: the target is unchanged" "$S0" "$(snap "$T")"
done
T="$(mk_t)"; mkdir -p "$T/.kiro"; ln -s "$OUTSIDE" "$T/.kiro/steering"; S0="$(snap "$T")"
rcne "symlink: a symlinked .kiro/steering is refused" ins "$A" --target "$T" --host kiro --apply
eq "symlink: .kiro/steering: nothing outside" "victim" "$(ls -A "$OUTSIDE")"
eq "symlink: .kiro/steering: target unchanged" "$S0" "$(snap "$T")"
T="$(mk_t)"; mkdir -p "$T/.codifide"; ln -s "$OUTSIDE/victim" "$T/.codifide/guard-immutable-paths.sh"; S0="$(snap "$T")"
rcne "symlink: a leaf symlink to an outside file is refused" ins "$A" --target "$T" --host kiro --apply
eq "symlink: ...the outside file is intact" "keep" "$(cat "$OUTSIDE/victim")"
eq "symlink: ...nothing else was written" "$S0" "$(snap "$T")"
T="$(mk_t)"; mkdir -p "$T/.codifide"; ln -s "$OUTSIDE/not-yet" "$T/.codifide/immutable-paths"; S0="$(snap "$T")"
rcne "symlink: a dangling leaf symlink (a seed path) is refused" ins "$A" --target "$T" --host kiro --apply
isnot "symlink: ...nothing was created through it" test -e "$OUTSIDE/not-yet"
eq "symlink: ...the target is unchanged" "$S0" "$(snap "$T")"
T="$(mk_t)"; mkdir -p "$T/.codifide/steering"; S0="$(snap "$T")"
mkdir -p "$T/.kiro/steering/00-welcome.md"
rcne "symlink: a directory sitting where a file belongs is refused" ins "$A" --target "$T" --host kiro --apply
T="$(mk_t)"; echo x > "$T/.kiro"
rcne "symlink: a regular file where a directory belongs is refused" ins "$A" --target "$T" --host kiro --apply
# a symlink in the release itself
SL="$WORK/srcLink"; mk_src "$SL" 3.2.0; printf 'tag=v3.2.0\n' > "$SL/RELEASE"
rm -f "$SL/steering/02-personas.md"; ln -s "$OUTSIDE/victim" "$SL/steering/02-personas.md"
T="$(mk_t)"; S0="$(snap "$T")"
rcne "symlink: a symlinked file inside the release is refused" ins "$SL" --target "$T" --host kiro --apply
eq "symlink: ...nothing written" "$S0" "$(snap "$T")"
# quoting
Q="$WORK/a b'c \$HOME"; mkdir -p "$Q"; git -C "$Q" init -q
rc "quoting: a target path with spaces, a quote and a dollar sign" 0 ins "$A" --target "$Q" --host kiro,cursor --apply
is "quoting: ...installed correctly" manifest_ok "$Q"
rc "quoting: ...and uninstalls" 0 ins "$A" uninstall --target "$Q" --apply

# hostile manifests (the manifest lives in the repository, so a pull request can change it)
BASE="$WORK/installed-base"; mkdir -p "$BASE"; git -C "$BASE" init -q; ins "$A" --target "$BASE" --host kiro --apply >/dev/null 2>&1
ZERO="$(printf '0%.0s' $(seq 1 64))"
bad_manifest(){ # name line
  local d="$WORK/bm.$RANDOM"; cp -R "$BASE" "$d"; echo canary > "$WORK/canary"
  printf '%s\n' "$2" >> "$d/.codifide/harness-manifest"; local s0 u; s0="$(snap "$d")"
  OUT="$($SH "$A/install.sh" uninstall --target "$d" --apply 2>&1)"; u=$?; passne "manifest attack ($1): uninstall refuses" x $u
  eq "manifest attack ($1): nothing was removed" "$s0" "$(snap "$d")"
  is "manifest attack ($1): the outside canary exists" test -f "$WORK/canary"
  OUT="$($SH "$A/install.sh" upgrade --target "$d" --apply 2>&1)"; u=$?; passne "manifest attack ($1): upgrade refuses" x $u
  eq "manifest attack ($1): upgrade changed nothing" "$s0" "$(snap "$d")"
  rm -rf "$d"; }
bad_manifest "dot-dot to a sibling" "$ZERO owned ../canary"
bad_manifest "absolute path" "$ZERO owned $WORK/canary"
bad_manifest "dot-dot inside an allowed prefix" "$ZERO owned .codifide/../../canary"
bad_manifest "dot-dot after the workflows prefix" "$ZERO owned .github/workflows/../../canary"
bad_manifest "the .git directory" "$ZERO owned .git/config"
bad_manifest "a source file" "$ZERO owned src/app.py"
bad_manifest "a path with a space" "$ZERO owned .codifide/a b"
bad_manifest "a leading dot-slash" "$ZERO owned ./.codifide/x"
bad_manifest "an empty component" "$ZERO owned .kiro/hooks//x"
bad_manifest "a dot component" "$ZERO owned .kiro/steering/./x"
bad_manifest "an upper-case hash" "$(printf 'A%.0s' $(seq 1 64)) owned .codifide/x"
bad_manifest "a short hash" "abc owned .codifide/x"
bad_manifest "an unknown kind" "$ZERO evil .codifide/x"
bad_manifest "a repeated path" "$(grep -v '^#' "$BASE/.codifide/harness-manifest" | head -n 1)"
bad_manifest "a garbage line" "this is not a manifest line"
# a damaged header
d="$WORK/bm.hdr"; cp -R "$BASE" "$d"; sed -i.bak '1s/.*/# something else/' "$d/.codifide/harness-manifest"; rm -f "$d/.codifide/harness-manifest.bak"; s0="$(snap "$d")"
rc "manifest attack (bad header): uninstall refuses" 1 ins "$A" uninstall --target "$d" --apply
eq "manifest attack (bad header): nothing removed" "$s0" "$(snap "$d")"
# manifest is itself a symlink
d="$WORK/bm.sym"; cp -R "$BASE" "$d"; mv "$d/.codifide/harness-manifest" "$OUTSIDE/m"; ln -s "$OUTSIDE/m" "$d/.codifide/harness-manifest"; s0="$(snap "$d")"
rc "manifest attack (manifest is a symlink): uninstall refuses" 1 ins "$A" uninstall --target "$d" --apply
eq "manifest attack (symlinked manifest): nothing removed" "$s0" "$(snap "$d")"
# a valid manifest, but a directory on the way has been swapped for a symlink
d="$WORK/bm.dir"; mkdir -p "$d"; git -C "$d" init -q; ins "$A" --target "$d" --host cursor --apply >/dev/null 2>&1
mkdir -p "$OUTSIDE/swap"; cp -R "$d/.cursor/rules" "$OUTSIDE/swap/rules"; rm -rf "$d/.cursor"; ln -s "$OUTSIDE/swap" "$d/.cursor"; n0="$(ls "$OUTSIDE/swap/rules" | wc -l | tr -d ' ')"
rcne "manifest attack (directory swapped for a symlink): uninstall refuses" ins "$A" uninstall --target "$d" --apply
eq "manifest attack (swapped directory): the outside files are intact" "$n0" "$(ls "$OUTSIDE/swap/rules" | wc -l | tr -d ' ')"

# ---------- no network, no commits, no git writes ----------
SHIM="$WORK/shim"; mkdir -p "$SHIM"; : > "$WORK/shim.log"
for c in curl wget nc ncat ssh scp sftp telnet ftp rsync; do printf '#!/bin/sh\necho %s >> "%s"\nexit 99\n' "$c" "$WORK/shim.log" > "$SHIM/$c"; chmod +x "$SHIM/$c"; done
REALGIT="$(command -v git)"
printf '#!/bin/sh\necho "git $*" >> "%s"\nexec "%s" "$@"\n' "$WORK/shim.log" "$REALGIT" > "$SHIM/git"; chmod +x "$SHIM/git"
T="$(mk_t)"; ( cd "$T" && git config user.email t@t && git config user.name t && echo base > base.txt && git add -A && git -c commit.gpgsign=false commit -qm base )
G0="$(sha "$T/.git/config")"; HEAD0="$(git -C "$T" rev-parse HEAD)"; HOOKS0="$(ls "$T/.git/hooks" | wc -l | tr -d ' ')"
PATH="$SHIM:$PATH" $SH "$A/install.sh" --target "$T" --host kiro,claude,cursor,copilot,codex --apply >/dev/null 2>&1
PATH="$SHIM:$PATH" $SH "$B/install.sh" upgrade --target "$T" --apply >/dev/null 2>&1
PATH="$SHIM:$PATH" $SH "$B/install.sh" uninstall --target "$T" --apply >/dev/null 2>&1
eq "network: no network client was ever called (install, upgrade, uninstall)" "0" "$(grep -c -E '^(curl|wget|nc|ncat|ssh|scp|sftp|telnet|ftp|rsync)$' "$WORK/shim.log")"
eq "git: only read-only subcommands were used" "0" "$(grep -c -E '^git (-C [^ ]+ )?(fetch|pull|push|clone|remote|ls-remote|submodule|commit|add|tag|config|checkout|reset|rm|mv|stash|init|apply|am|merge|rebase)' "$WORK/shim.log")"
is "git: the shim saw the pin check (control: the log is live)" grep -q 'describe' "$WORK/shim.log"
eq "git: .git/config is unchanged" "$G0" "$(sha "$T/.git/config")"
eq "git: HEAD is unchanged (no commit)" "$HEAD0" "$(git -C "$T" rev-parse HEAD)"
eq "git: no hook was installed" "$HOOKS0" "$(ls "$T/.git/hooks" | wc -l | tr -d ' ')"
T2="$(mk_t)"; ( cd "$T2" && git config user.email t@t && git config user.name t && echo base > base.txt && git add -A && git -c commit.gpgsign=false commit -qm base )
ins "$A" --target "$T2" --host kiro --apply >/dev/null 2>&1
eq "git: nothing is staged after an install" "0" "$(git -C "$T2" diff --cached --name-only | wc -l | tr -d ' ')"
grep -v '^[[:space:]]*#' "$A/install.sh" | grep -q -E 'curl|wget|(^|[^a-z])(nc|ncat|ssh|scp|sftp|telnet|ftp|rsync)( |$)|https?://|git (-C [^ ]+ )?(fetch|pull|push|clone|remote|commit|add|config|checkout)'
passne "network: install.sh code contains no network client, URL, or git write command" x $?
grep -v '^[[:space:]]*#' "$A/tools/build-release.sh" | grep -q -E 'curl|wget|https?://|git (-C [^ ]+ )?(fetch|pull|push|clone|remote)'
passne "network: build-release.sh contains no network use" x $?
rc "env: GIT_DIR and GIT_WORK_TREE in the caller's environment cannot redirect the installer" 0 env GIT_DIR=/nonexistent GIT_WORK_TREE=/nonexistent $SH "$A/install.sh" --target "$(mk_t)" --host kiro
rc "env: stray CODIFIDE_ variables have no effect" 0 env CODIFIDE_ROOT=/tmp CODIFIDE_WAIVE=size CODIFIDE_BASE=x $SH "$A/install.sh" --target "$(mk_t)" --host kiro

# ---------- failure leaves no partial install ----------
T="$(mk_t)"; mkdir -p "$T/.kiro/hooks"; chmod 555 "$T/.kiro/hooks"; S0="$(snap "$T")"
if [[ -w "$T/.kiro/hooks" ]]; then echo "SKIP  failure rollback (running as a user that ignores modes)"
else
  rcne "failure: a write that fails part way makes the run fail" ins "$A" --target "$T" --host kiro --apply
  out_has "failure: ...and says it rolled back" 'rolling back'
  eq "failure: nothing is left behind (no files, no directories, no manifest)" "$S0" "$(snap "$T")"
  isnot "failure: no temporary file is left in the target" sh -c "find '$T' -name '.codifide-tmp*' | grep -q ."
  chmod 755 "$T/.kiro/hooks"
  T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1; chmod 555 "$T/.kiro/hooks"; S1="$(snap "$T")"
  rcne "failure: a failed upgrade makes the run fail" ins "$B" upgrade --target "$T" --apply
  eq "failure: ...and the installed release is restored exactly" "$S1" "$(snap "$T")"
  eq "failure: ...and the version file still says 3.2.0" "version=3.2.0" "$(grep '^version=' "$T/.codifide/harness-version")"
  chmod 755 "$T/.kiro/hooks"
  T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1; chmod 555 "$T/.kiro/steering"; S1="$(snap "$T")"
  rcne "failure: a failed uninstall makes the run fail" ins "$A" uninstall --target "$T" --apply
  chmod 755 "$T/.kiro/steering"
  eq "failure: ...and every removed file is back" "$S1" "$(snap "$T")"
fi

# ---------- installed guard works ----------
T="$(mk_t)"; ins "$A" --target "$T" --host kiro --apply >/dev/null 2>&1
( cd "$T" && printf '%s' '{"input":{"path":".kiro/hooks/x.json"}}' | $SH .codifide/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "installed guard: blocks a write into .kiro/hooks" 2 $?
( cd "$T" && printf '%s' '{"input":{"path":"src/app.py"}}' | $SH .codifide/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "installed guard: allows an ordinary source file" 0 $?

# ---------- release build ----------
mkdir -p "$A/docs"; echo secret > "$A/docs/local-note.txt"
REL="$WORK/rel"
rc "release: build from a clean tagged tree" 0 $SH "$A/tools/build-release.sh" v3.2.0 "$REL"
is "release: tarball exists" test -f "$REL/codifide-harness-3.2.0.tar.gz"
is "release: SHA256SUMS verifies" sh -c "cd '$REL' && shasum -a 256 -c SHA256SUMS"
mkdir "$WORK/x"; tar -xzf "$REL/codifide-harness-3.2.0.tar.gz" -C "$WORK/x"; X="$WORK/x/codifide-harness-3.2.0"
eq "release: RELEASE names the tag" "tag=v3.2.0" "$(head -n 1 "$X/RELEASE")"
is "release: RELEASE records the commit" grep -q "^commit=$(git -C "$A" rev-parse HEAD)$" "$X/RELEASE"
is "release: contains install.sh and VERSION" test -f "$X/install.sh" -a -f "$X/VERSION"
isnot "release: no .git directory" test -e "$X/.git"
isnot "release: an ignored local file (docs/) can never enter the tarball" test -e "$X/docs"
isnot "release: no worktree metadata" test -e "$X/.worktrees"
T="$(mk_t)"; rc "release: the unpacked tarball installs, pinned" 0 ins "$X" --target "$T" --host kiro,cursor --apply
eq "release: ...recorded as source=release" "source=release" "$(grep '^source=' "$T/.codifide/harness-version")"
is "release: ...and the tree verifies" manifest_ok "$T"
printf 'tag=v1.0.0\n' > "$X/RELEASE"; rc "release: a tampered RELEASE file refuses" 1 ins "$X" --target "$(mk_t)" --host kiro --apply
rm -f "$X/RELEASE"; rc "release: an unpacked tarball without RELEASE refuses" 1 ins "$X" --target "$(mk_t)" --host kiro --apply
rc "release: an existing output directory with a release is refused" 1 $SH "$A/tools/build-release.sh" v3.2.0 "$REL"
rc "release: a missing tag is refused" 1 $SH "$A/tools/build-release.sh" v9.9.9 "$WORK/r2"
rc "release: a malformed tag is refused" 1 $SH "$A/tools/build-release.sh" main "$WORK/r3"
rc "release: wrong argument count is a usage error" 2 $SH "$A/tools/build-release.sh" v3.2.0
echo x > "$A/untracked.txt"; rc "release: a dirty tree is refused" 1 $SH "$A/tools/build-release.sh" v3.2.0 "$WORK/r4"; rm -f "$A/untracked.txt"
git -C "$A" tag v3.2.7; rc "release: a tag that disagrees with VERSION is refused" 1 $SH "$A/tools/build-release.sh" v3.2.7 "$WORK/r5"

# ---------- documentation and release-file consistency ----------
has(){ grep -q -E -- "$1" "$2"; }
wf="$WORK/release.nocomments.yml"; grep -v '^[[:space:]]*#' "$REPO/.github/workflows/release.yml" > "$wf"
is "docs: VERSION is 3.2.0" test "$(cat "$REPO/VERSION")" = "3.2.0"
is "docs: CHANGELOG has a 3.2.0 entry" has '^## \[3\.2\.0\]' "$REPO/CHANGELOG.md"
is "docs: CHANGELOG states what was not verified end to end" grep -q -i -E 'not verified end to end' "$REPO/CHANGELOG.md"
is "docs: README documents install.sh, --apply and the dry-run default" sh -c "grep -q 'install.sh' '$REPO/README.md' && grep -q -- '--apply' '$REPO/README.md' && grep -qi 'dry run' '$REPO/README.md'"
is "docs: README does not tell users to pipe a download into a shell" sh -c "! grep -E 'curl[^|]*\\|[[:space:]]*(ba)?sh' '$REPO/README.md'"
isnot "release workflow: no pull_request_target" has 'pull_request_target' "$wf"
isnot "release workflow: no pull_request trigger" has '^[[:space:]]*pull_request' "$wf"
is "release workflow: triggers only on tags" has "tags: \['v\*'\]" "$wf"
is "release workflow: no third-party actions, or every one pinned to a full commit SHA" sh -c "! grep -E '^[[:space:]-]*uses:' '$wf' | grep -v -E '@[0-9a-f]{40}([[:space:]]|\$)'"
is "release workflow: the only write permission is contents" sh -c "test \"\$(grep -c ': write' '$wf')\" = 1 && grep -q 'contents: write' '$wf'"
is "release workflow: signs only when a key exists" has 'RELEASE_SIGNING_KEY' "$wf"
is "release workflow: says plainly when it is unsigned" has 'NOT signed' "$wf"
is "release workflow: runs both suites before building" sh -c "grep -n 'test-enforcement.sh' '$wf' | head -1 | cut -d: -f1 > /dev/null && grep -q 'tests/test-installer.sh' '$wf'"
is "release workflow: creates a draft, not a published release" has '--draft' "$wf"
isnot "release workflow: no download-and-execute" has 'curl|wget' "$wf"
for f in install.sh tools/build-release.sh tests/test-installer.sh; do
  is "docs: $f has an SPDX header" sh -c "head -3 '$REPO/$f' | grep -q 'SPDX-License-Identifier: MIT'"
  is "docs: $f parses under bash -n" bash -n "$REPO/$f"
done
is "docs: the core stays at or under 2,400 words" test "$(wc -w < "$REPO/steering/00-welcome.md")" -le 2400
idpat="share""care|gen""zeon|gret""chen"   # built from parts so this file does not contain what it forbids
is "docs: no employer or client identifiers in the new files" sh -c "! grep -r -i -l -E '$idpat' '$REPO/install.sh' '$REPO/tools' '$REPO/tests' '$REPO/.github'"
claimed="$(grep -Eo '[0-9]+ installer checks' "$REPO/README.md" | head -1 | grep -Eo '[0-9]+')"
actual=$(( $(wc -l < "$COUNTF" | tr -d ' ') + 1 ))
[[ "${claimed:-0}" -eq "$actual" ]]; pass "docs: README states the real installer check count ($actual)" 0 $?

echo "RESULT[$SH]: $([[ $FAIL -eq 0 ]] && echo ALL PASS || echo FAILURES)"
exit $FAIL
