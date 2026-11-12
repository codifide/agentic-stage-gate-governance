#!/usr/bin/env bash
# Codifide Harness — enforcement test suite.
# Runs every enforcement script against throwaway git repos in $TMPDIR.
# Usage: bash templates/enforcement/test-enforcement.sh   (SH_UNDER_TEST=/path/to/bash to pick a shell)
#   CODIFIDE_TEST_SCRIPTS=/dir runs the suite against another copy of the scripts (used to prove
#   that a regression test fails on the old scripts).
# Exit 0 = all pass.
set -u
SRC="${CODIFIDE_TEST_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Isolate from the caller: an inherited approval/waiver variable (e.g. CODIFIDE_VERIFIER_CHANGE_APPROVED_BY)
# would silently flip the "must fail" cases. Tests set these per case where needed.
unset GITHUB_ACTIONS CODIFIDE_WAIVE CODIFIDE_REQUIRE_IMMUTABLE_LIST CODIFIDE_STEWARD CODIFIDE_VERIFIER_CHANGE_APPROVED_BY CODIFIDE_SESSIONS CODIFIDE_LICENSE_POLICY CODIFIDE_BASE CODIFIDE_ENFORCER_CHANGE_APPROVED_BY CODIFIDE_ROOT CODIFIDE_BOOTSTRAP CODIFIDE_REQUIRE_BASE_POLICY
SH="${SH_UNDER_TEST:-bash}"
COUNTF="$(mktemp)"
FAIL=0
pass(){ local ok=PASS; [[ $2 -ne $3 ]] && { ok=FAIL; FAIL=1; }; echo "$ok  $1 (want $2, got $3)"; echo x >> "$COUNTF"; }

# ---------- guard ----------
T=$(mktemp -d); cd "$T" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide verifiers src tests/golden
cp "$SRC"/immutable-paths.example .codifide/immutable-paths; cp "$SRC"/guard-immutable-paths.sh "$SRC"/check-immutable-paths.sh .codifide/
echo v > verifiers/check.py; echo g > tests/golden/a.json; echo s > src/app.py
git add -A && git commit -qm base
g(){ printf '%s' "$3" | $SH .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: $1" "$2" $?; }
g "allow src write" 0 '{"input":{"path":"src/app.py","text":"x"}}'
g "block verifier write" 2 '{"input":{"path":"verifiers/check.py"}}'
g "block relative dotdot (foo/../verifiers)" 2 '{"input":{"path":"foo/../verifiers/eval.py"}}'
g "block src/../tests/golden" 2 '{"input":{"path":"src/../tests/golden/a.json"}}'
g "block ./ and // forms" 2 '{"input":{"path":".//verifiers/./x.py"}}'
g "block abs symlinked tmp path" 2 "{\"input\":{\"path\":\"$T/tests/golden/a.json\"}}"
g "block abs dotdot path" 2 "{\"input\":{\"path\":\"$T/src/../verifiers/x.py\"}}"
g "allow abs src path" 0 "{\"input\":{\"path\":\"$T/src/new.py\"}}"
g "allow dotdot that stays in src" 0 '{"input":{"path":"src/a/../b.py"}}'
g "block list self-edit" 2 '{"input":{"path":".codifide/immutable-paths"}}'
g "block guard self-edit" 2 '{"input":{"path":".codifide/guard-immutable-paths.sh"}}'
g "block nested array path" 2 '{"input":{"files":[{"path":"tests/golden/b.json"}]}}'
g "allow multiline content" 0 '{"input":{"path":"src/x.md","text":"see\nverifiers/"}}'
g "block invalid json" 2 'not json'
ln -s ../verifiers/check.py src/alias.py
g "block leaf symlink into verifiers" 2 '{"input":{"path":"src/alias.py"}}'
mkdir -p .kiro/steering && echo core > .kiro/steering/00-welcome.md
g "block harness core edit" 2 '{"input":{"path":".kiro/steering/00-welcome.md"}}'
g "allow handoff write" 0 '{"input":{"path":".kiro/steering/next-session-prompt.md"}}'
g "block new steering file" 2 '{"input":{"path":".kiro/steering/override.md"}}'
g "block hooks dir" 2 '{"input":{"path":".kiro/hooks/x.json"}}'
g "block CI workflow edit" 2 '{"input":{"path":".github/workflows/ci.yml"}}'
printf '!.codifide/immutable-paths\n' >> .codifide/immutable-paths
g "list cannot be excepted" 2 '{"input":{"path":".codifide/immutable-paths"}}'
mv .codifide/immutable-paths /tmp/codifide-list-$$
printf '%s' '{"input":{"path":"src/app.py"}}' | CODIFIDE_REQUIRE_IMMUTABLE_LIST=1 $SH .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: missing list + required blocks" 2 $?
printf '%s' '{"input":{"path":"src/app.py"}}' | $SH .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: missing list, not required, allows" 0 $?
mv /tmp/codifide-list-$$ .codifide/immutable-paths
git checkout -q -- .codifide/immutable-paths
rm -f src/alias.py; rm -rf .kiro
g "block case variant Verifiers/check.py" 2 '{"input":{"path":"Verifiers/check.py"}}'
g "block case variant TESTS/Golden dir" 2 '{"input":{"path":"TESTS/Golden/a.json"}}'
g "block case variant of the list itself" 2 '{"input":{"path":".CODIFIDE/Immutable-Paths"}}'
LONG1="$(printf './%.0s' $(seq 1 600))"
g "block 1200-char ./ path to verifier (no length cutoff)" 2 "{\"input\":{\"path\":\"${LONG1}verifiers/check.py\"}}"
LONG2="$(printf 'a/../%.0s' $(seq 1 300))"
g "block 1500-char a/../ path to verifier" 2 "{\"input\":{\"path\":\"${LONG2}verifiers/check.py\"}}"
g "block path with trailing newline" 2 '{"input":{"path":"verifiers/check.py\n"}}'
g "block path with leading newline and CRLF" 2 '{"input":{"path":"\r\nverifiers/check.py\r\n"}}'
g "block path with trailing spaces and tab" 2 '{"input":{"path":"  .codifide/immutable-paths \t"}}'
LONG3="$(printf 'x%.0s' $(seq 1 3000))"
g "allow long benign string" 0 "{\"input\":{\"text\":\"${LONG3}\",\"path\":\"src/app.py\"}}"
g "block empty stdin (fail closed)" 2 ''
g "block whitespace-only stdin (fail closed)" 2 '   '
ln verifiers/check.py src/hl.py
g "block hard link to verifier" 2 '{"input":{"path":"src/hl.py"}}'
rm -f src/hl.py
echo a > src/m1.py; ln src/m1.py src/m2.py
g "allow hard link between unprotected files" 0 '{"input":{"path":"src/m2.py"}}'
rm -f src/m1.py src/m2.py
chmod 000 .codifide/immutable-paths
if [[ -r .codifide/immutable-paths ]]; then echo "SKIP  guard: unreadable list (running as a user that ignores modes)"; else g "block when the list is unreadable" 2 '{"input":{"path":"src/app.py"}}'; fi
chmod 644 .codifide/immutable-paths
printf '%s' '{"input":{"path":"src/app.py"}}' | $SH .codifide/guard-immutable-paths.sh 2>&1 >/dev/null | grep -q . ; pass "guard: silent when allowing with a list present" 1 $?
g "documented limit: shell command text is not inspected" 0 '{"command":"printf x >> verifiers/check.py"}'
# --- iteration 2 regressions (each fails on the previous scripts) ---
mkdir -p verifiers/sub src/real; ln -s ../verifiers/sub src/link; ln -s real src/okdir
g "block symlinked dir then .. (src/link/../check.py resolves to verifiers/check.py)" 2 '{"input":{"path":"src/link/../check.py"}}'
g "allow symlinked dir then .. that stays outside protected paths" 0 '{"input":{"path":"src/okdir/../app.py"}}'
rm -f src/link src/okdir; rmdir src/real verifiers/sub
ln -s ../src/app.py verifiers/link.py
g "block delete of a symlink that sits inside a protected dir (target is unprotected)" 2 '{"input":{"path":"verifiers/link.py","operation":"delete"}}'
rm -f verifiers/link.py
OUTD="$(mktemp -d)"; ln verifiers/check.py "$OUTD/alias.py"
g "block hard link to a verifier that lives outside the repo" 2 "{\"input\":{\"path\":\"$OUTD/alias.py\"}}"
rm -rf "$OUTD"
g "block recursive delete of an ancestor of a protected dir (tests)" 2 '{"input":{"path":"tests","operation":"delete","recursive":true}}'
g "block delete of the repo root (.)" 2 '{"input":{"path":".","operation":"delete","recursive":true}}'
g "block delete of the directory that holds the list (.codifide)" 2 '{"input":{"path":".codifide","operation":"delete"}}'
g "allow a directory that holds no protected path (src)" 0 '{"input":{"path":"src","operation":"list"}}'
g "block path with an interior newline inside a protected dir" 2 '{"input":{"path":"verifiers/a\nb.py","operation":"write"}}'
g "block path with a NUL byte that truncates to a verifier" 2 '{"input":{"path":"verifiers/check.py\u0000.txt"}}'
g "block a protected path used as a JSON object key" 2 '{"files":{"verifiers/check.py":"x"}}'
SHIM="$(mktemp -d)"; for t in bash git python3 base64 find readlink sed tr head cat dirname basename grep awk mktemp rm; do ln -s "$(command -v $t)" "$SHIM/$t" 2>/dev/null; done
printf '%s' '{"input":{"path":"verifiers/a\nb.py"}}' | env PATH="$SHIM" bash .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: python3 fallback (no jq) blocks an interior-newline path" 2 $?
printf '%s' '{"input":{"path":"Verifiers/check.py\n"}}' | env PATH="$SHIM" bash .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: python3 fallback (no jq) blocks case variant with trailing newline" 2 $?
printf '%s' '{"input":{"path":"src/app.py"}}' | env PATH="$SHIM" bash .codifide/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: python3 fallback (no jq) allows src" 0 $?
rm -rf "$SHIM"

# --- iteration 3 regressions: guard ---
G3=$(mktemp -d); cd "$G3" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide src vault; cp "$SRC"/guard-immutable-paths.sh .codifide/
printf 'vault/*.pem\ncaf\303\251.py\n' > .codifide/immutable-paths
printf 'p\n' > "$(printf 'caf\303\251.py')"
g "block NFD spelling of a protected NFC file name (Unicode alias)" 2 "$(printf '{"input":{"path":"cafe\314\201.py"}}')"
g "allow an unrelated non-ASCII file name" 0 "$(printf '{"input":{"path":"caf\303\251-notes.md"}}')"
nlp="$(printf 'vault/a\nb.pem')"; printf 'p\n' > "$nlp"; ln "$nlp" src/alias
g "block hard link to a protected file whose name contains a newline" 2 '{"input":{"path":"src/alias"}}'
rm -f src/alias
cd /; rm -rf "$G3"
# --- iteration 4 regressions: guard (relative paths, CODIFIDE_ROOT, hook payload cwd) ---
G4=$(mktemp -d); cd "$G4" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide verifiers src decoy/.codifide; cp "$SRC"/guard-immutable-paths.sh .codifide/
printf 'verifiers/\n' > .codifide/immutable-paths; printf 'unrelated/\n' > decoy/.codifide/immutable-paths
echo v > verifiers/check.py; echo s > src/app.py
G4S="$G4/.codifide/guard-immutable-paths.sh"
g4(){ # $1 = name, $2 = want, $3 = cwd (relative to repo), $4 = payload, rest = env assignments
  local nm="$1" want="$2" wd="$3" pl="$4"; shift 4
  ( cd "$G4/$wd" && printf '%s' "$pl" | env "$@" $SH "$G4S" >/dev/null 2>&1 ); pass "guard: $nm" "$want" $?; }
g4 "relative path judged against the hook's cwd (cwd=verifiers, path check.py, input.path)" 2 verifiers '{"input":{"path":"check.py","text":"x"}}' X=1
g4 "relative path judged against the hook's cwd (cwd=verifiers, tool_input.file_path)" 2 verifiers '{"tool_input":{"file_path":"check.py"}}' X=1
g4 "relative path judged against the payload cwd (hook runs at the root, payload cwd=verifiers)" 2 . "{\"cwd\":\"$G4/verifiers\",\"tool_input\":{\"file_path\":\"check.py\"}}" X=1
g4 "allow a relative path to an unprotected file from a subdirectory (cwd=src, app.py)" 0 src '{"input":{"path":"app.py"}}' X=1
g4 "allow a Claude-style payload whose cwd is the repo root and whose target is unprotected" 0 . "{\"cwd\":\"$G4\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"src/app.py\"}}" X=1
g4 "block a Claude-style payload (cwd=repo root) that writes a verifier" 2 . "{\"cwd\":\"$G4\",\"tool_input\":{\"file_path\":\"verifiers/check.py\"}}" X=1
g4 "CODIFIDE_ROOT pointing at a decoy directory blocks (REQUIRE=1)" 2 . "{\"input\":{\"path\":\"$G4/verifiers/check.py\"}}" "CODIFIDE_ROOT=$G4/decoy" CODIFIDE_REQUIRE_IMMUTABLE_LIST=1
g4 "CODIFIDE_ROOT pointing at a decoy directory blocks even an unrelated write" 2 . '{"input":{"path":"src/app.py"}}' "CODIFIDE_ROOT=$G4/decoy"
g4 "CODIFIDE_ROOT equal to the real top level is accepted (allow control)" 0 . '{"input":{"path":"src/app.py"}}' "CODIFIDE_ROOT=$G4"
cd /; rm -rf "$G4"; cd "$T"
# --- iteration 5 regressions: guard (GIT_* decoy root, delete of /, symlink inside the payload cwd) ---
G5=$(mktemp -d); cd "$G5" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide verifiers/sub src decoy/.codifide; cp "$SRC"/guard-immutable-paths.sh .codifide/
printf 'verifiers/\n' > .codifide/immutable-paths; printf 'unrelated/\n' > decoy/.codifide/immutable-paths
echo v > verifiers/check.py; ln -s ../verifiers/sub src/link
G5S="$G5/.codifide/guard-immutable-paths.sh"
( cd "$G5" && printf '{"input":{"path":"%s/verifiers/check.py"}}' "$G5" | GIT_DIR="$G5/.git" GIT_WORK_TREE="$G5/decoy" $SH "$G5S" >/dev/null 2>&1 ); pass "guard: GIT_DIR/GIT_WORK_TREE decoy work tree cannot redirect the list" 2 $?
( cd "$G5" && printf '{"input":{"path":"/","operation":"delete","recursive":true}}' | $SH "$G5S" >/dev/null 2>&1 ); pass "guard: delete of / (an ancestor of the repository) is blocked" 2 $?
( cd "$G5" && printf '{"cwd":"%s/src/link/..","tool_input":{"file_path":"check.py"}}' "$G5" | $SH "$G5S" >/dev/null 2>&1 ); pass "guard: payload cwd src/link/.. is resolved through the symlink before .. applies" 2 $?
( cd "$G5" && printf '{"cwd":"%s/src","tool_input":{"file_path":"new.py"}}' "$G5" | $SH "$G5S" >/dev/null 2>&1 ); pass "guard: payload cwd inside src, unprotected file (allow control)" 0 $?
cd /; rm -rf "$G5"; cd "$T"
# ---------- immutable CI ----------
ci(){ $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: $1" "$2" $?; }
git checkout -qb feat/a; echo y >> src/app.py; git commit -qam ok; ci "clean feature branch" 0
echo z >> verifiers/check.py; git commit -qam bad; ci "verifier edit on ordinary branch" 1
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: steward-approved change" 0 $?
git checkout -qb feat/b main; git mv tests/golden/a.json src/a.json; git commit -qm mv; ci "rename out of golden" 1
git checkout -qb feat/c main; printf '' > .codifide/immutable-paths; echo z >> verifiers/check.py; git commit -qam loosen; ci "loosen list + edit" 1
git checkout -qb feat/case main; h=$(echo z | git hash-object -w --stdin)
git update-index --add --cacheinfo 100644,$h,Verifiers/new.py; git commit -qm case; ci "case-variant path Verifiers/new.py" 1
git checkout -qb feat/uni main; git update-index --add --cacheinfo 100644,$h,"tests/golden/é.json"; git commit -qm uni; ci "non-ASCII file name under golden (quoted by git)" 1
git checkout -qb feat/nl main; git update-index --add --cacheinfo 100644,$h,"tests/golden/a
b.json"; git commit -qm nl; ci "newline in file name under golden" 1
git checkout -qb feat/dirrule main; git update-index --add --cacheinfo 100644,$h,"eval"; git commit -qm evalfile; ci "file named like a protected directory (eval)" 1
git checkout -qb feat/sl1 main; sl=$(printf '../verifiers/check.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/alias2.py; git commit -qm sl; ci "new symlink into protected verifier" 1
git checkout -qb feat/sl2 main; sl=$(printf '../src/app.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/alias3.py; git commit -qm sl2; ci "new symlink to an unprotected file" 0
git checkout -qb feat/enf main; echo '# changed' >> .codifide/check-immutable-paths.sh; git commit -qam enf
ci "enforcer script edit without approval" 1
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: verifier approval does NOT waive an enforcer script edit" 1 $?
CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: enforcer approval waives an enforcer script edit" 0 $?
echo z >> verifiers/check.py; git commit -qam both
CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: enforcer approval does NOT waive a verifier edit" 1 $?
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat" CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: both approvals pass both kinds of edit" 0 $?
git checkout -qb feat/wf main; mkdir -p .github/workflows; echo w > .github/workflows/x.yml; git add -A; git commit -qm wf
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: verifier approval does NOT waive a workflow edit" 1 $?
git checkout -q main
$SH .codifide/check-immutable-paths.sh does-not-exist >/dev/null 2>&1; pass "immutable-ci: bad base fails closed" 2 $?
git checkout -q --orphan nolist && git rm -rqf . && echo x > f && git add f && git commit -qm nolist && git checkout -qb nolist-feat && echo y >> f && git commit -qam y
$SH "$SRC"/check-immutable-paths.sh nolist >/dev/null 2>&1; pass "immutable-ci: no list, not required, passes" 0 $?
CODIFIDE_REQUIRE_IMMUTABLE_LIST=1 $SH "$SRC"/check-immutable-paths.sh nolist >/dev/null 2>&1; pass "immutable-ci: no list + required fails closed" 2 $?
# --- iteration 2 regressions: CI check ---
C2=$(mktemp -d); cd "$C2" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide verifiers src; printf 'verifiers/\n' > .codifide/immutable-paths; cp "$SRC"/check-immutable-paths.sh .codifide/
echo v > verifiers/check.py; echo s > src/app.py; ln -s ../verifiers/check.py src/existing.py; ln -s ../verifiers src/vdir
git add -A && git commit -qm base
git checkout -qb feat/wf2 main; mkdir -p .github/workflows; echo w > .github/workflows/enforcement.yml; git add -A; git commit -qm wf
ci "workflow edit is an enforcer violation even when the list does not name it" 1
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: verifier approval does not waive an unlisted workflow edit" 1 $?
CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: enforcer approval passes an unlisted workflow edit" 0 $?
git checkout -qb feat/chain main; sl=$(printf 'existing.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/new.py; git commit -qm chain
ci "new symlink to an existing symlink that points into a verifier (two hops)" 1
git checkout -qb feat/dirchain main; sl=$(printf 'vdir/check.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/n2.py; git commit -qm dirchain
ci "new symlink through a directory symlink into a verifier" 1
git checkout -qb feat/loop main; a=$(printf 'b2.py' | git hash-object -w --stdin); b=$(printf 'a2.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$a,src/a2.py; git update-index --add --cacheinfo 120000,$b,src/b2.py; git commit -qm loop
ci "symlink loop is reported (fail closed)" 1
git checkout -qb feat/okchain main; sl=$(printf 'app.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/ok1.py; sl2=$(printf 'ok1.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl2,src/ok2.py; git commit -qm okchain
ci "chain of symlinks that ends at an unprotected file passes" 0
cd /; rm -rf "$C2"; cd "$T"
# --- iteration 3 regressions: CI check ---
C3=$(mktemp -d); cd "$C3" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .codifide verifiers src; printf 'verifiers/\n' > .codifide/immutable-paths; cp "$SRC"/check-immutable-paths.sh .codifide/
echo v > verifiers/check.py; ln -s ../verifiers src/bridge
git add -A && git commit -qm base
git checkout -qb feat/f01 main; ln -s ../.codifide/immutable-paths src/policy; git add -A; git commit -qm alias
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: symlink into the enforcement mechanism is NOT waived by the verifier approval" 1 $?
CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: symlink into the enforcement mechanism passes with the enforcer approval" 0 $?
git checkout -qb feat/f02 main; sl=$(printf '../SRC/bridge/check.py' | git hash-object -w --stdin)
git update-index --add --cacheinfo 120000,$sl,src/alias; git commit -qm casesl
ci "symlink whose target uses a different case for a directory symlink into a verifier" 1
cd /; rm -rf "$C3"
# --- iteration 4 regressions: CI check (Unicode aliases when git does not precompose) ---
C4=$(mktemp -d); cd "$C4" && git init -q -b main && git config user.email t@t && git config user.name t && git config core.precomposeunicode false
mkdir -p .codifide; printf 'caf\303\251.py\n' > .codifide/immutable-paths; cp "$SRC"/check-immutable-paths.sh .codifide/
h4=$(echo v | git hash-object -w --stdin); git update-index --add --cacheinfo 100644,$h4,"$(printf 'caf\303\251.py')"
git add -A && git commit -qm base
git checkout -qb feat/nfd main; git update-index --add --cacheinfo 100644,$h4,"$(printf 'cafe\314\201.py')"; git commit -qm nfd
ci "NFD alias of a protected NFC file name" 1
git checkout -qb feat/nfd-ok main; git update-index --add --cacheinfo 100644,$h4,"$(printf 'caf\303\251-notes.md')"; git commit -qm other
ci "unrelated non-ASCII file name passes (control)" 0
cd /; rm -rf "$C4"
cd "$T"
# --- iteration 5 regressions: CI check (docs/CODEOWNERS is an enforcer path) ---
git checkout -qb feat/own main; mkdir -p docs; echo '* @human' > docs/CODEOWNERS; git add -A; git commit -qm own; git checkout -qb feat/own2; echo '* @attacker' > docs/CODEOWNERS; git commit -qam own2
CODIFIDE_VERIFIER_CHANGE_APPROVED_BY="Pat" $SH .codifide/check-immutable-paths.sh feat/own >/dev/null 2>&1; pass "immutable-ci: docs/CODEOWNERS edit is blocked (verifier approval does not waive it)" 1 $?
CODIFIDE_ENFORCER_CHANGE_APPROVED_BY="Pat Steward" $SH .codifide/check-immutable-paths.sh feat/own >/dev/null 2>&1; pass "immutable-ci: docs/CODEOWNERS edit passes with enforcer approval" 0 $?
git checkout -q main
cd /; rm -rf "$T"

# ---------- review level ----------
T=$(mktemp -d); cd "$T" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p src/auth src/components src/crypto src/lib docs && echo a > src/components/a.css && echo b > src/auth/login.ts && echo c > src/crypto/k.ts && echo d > src/lib/access.ts
git add -A && git commit -qm base
S="$SRC"/check-review-level.sh
rl(){ $SH "$S" main >/dev/null 2>&1; pass "review-level: $1" "$2" $?; }
cm(){ git add -A; git commit -qm "$1" -m "$2"; }
nb(){ git checkout -qb "$1" main; mkdir -p docs; }

nb t1; echo x >> src/components/a.css; cm css "Generated-By: ai-agent
Review-Level: R1"; rl "styling R1" 0
nb t2; echo x >> docs/a.md; cm doc "Review-Level: R1"; rl "missing Generated-By" 1
nb t3; echo x >> docs/a.md; cm doc "Generated-By: robot
Review-Level: R1"; rl "invalid Generated-By" 1
nb t4; echo x >> docs/a.md; cm doc "Generated-By: human"; rl "missing Review-Level" 1
nb t5; echo y >> src/lib/access.ts; cm acc "Generated-By: human
Review-Level: R1"; rl "non-allowlist logic file at R1 (rule 9/10 gap)" 1
nb t6; echo 'type Q' > schema.graphql; cm gql "Generated-By: human
Review-Level: R1"; rl "API schema at R1" 1
nb t7; echo '{}' > package.json; cm dep "Generated-By: human
Review-Level: R2"; rl "dependency at R2" 0
nb t8; echo y >> src/auth/login.ts; cm auth "Generated-By: ai-assisted
Review-Level: R2"; rl "ai-assisted auth at R2 (no provenance escape)" 1
nb t9; echo y >> src/auth/login.ts; cm auth "Generated-By: human
Review-Level: R2"; rl "human auth at R2" 0
nb t10; echo y >> src/crypto/k.ts; cm c1 "Generated-By: human
Review-Level: R1"; echo z >> README.md; cm c2 "Generated-By: human
Review-Level: R3"; rl "per-commit: crypto R1 hidden behind README R3" 1
nb t11; for i in 1 2 3 4 5 6; do seq 1 100 > src/components/f$i.css; done; cm big "Generated-By: human
Review-Level: R1"; rl "600 lines / 6 files at R1" 1
nb t11b; for i in 1 2 3 4 5 6; do seq 1 100 > src/components/f$i.css; done; cm big "Generated-By: human
Review-Level: R2"; echo r >> docs/r.md; cm r "Generated-By: human
Review-Level: R3"; rl "size: big commit R2 hidden behind README R3" 1
CODIFIDE_WAIVE=size CODIFIDE_STEWARD="Pat" $SH "$S" main >/dev/null 2>&1; pass "review-level: size waiver + R2 big commit passes" 0 $?
CODIFIDE_WAIVE=size $SH "$S" main >/dev/null 2>&1; pass "review-level: waiver without steward errors" 2 $?
CODIFIDE_WAIVE=path CODIFIDE_STEWARD=Pat $SH "$S" main >/dev/null 2>&1; pass "review-level: unsupported waiver errors" 2 $?
nb t12; echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' >> src/lib/access.ts; cm mk "Generated-By: ai-agent
Review-Level: R2"; rl "agent adds approval marker" 1
nb t13; echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' >> src/lib/access.ts; cm mk "Generated-By: human
Review-Level: R2"; rl "human adds approval marker" 0
nb t13b; mkdir -p .codifide && printf '%s\n' "grep -E 'SILENT-CATCH-APPROVED|COVERAGE-EXCEPTION.*[Aa]pproved'" > .codifide/check-review-level.sh; cm tool "Generated-By: ai-agent
Review-Level: R3"; rl "agent installs enforcement script naming the markers" 0
nb t13c; mkdir -p .codifide src/lib && printf '%s\n' "x" > .codifide/check-review-level.sh; echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' >> src/lib/access.ts; cm tool "Generated-By: ai-agent
Review-Level: R3"; rl "agent marker in product code beside enforcement script still fails" 1
nb t13d; mkdir -p .codifide && echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' > .codifide/other.sh; cm tool "Generated-By: ai-agent
Review-Level: R3"; rl "agent marker in other .codifide file still fails" 1
nb ts15; mkdir -p .claude; echo '{"permissions":{"allow":["Write(verifiers/**)"]}}' > .claude/settings.json; cm cl "Generated-By: ai-agent
Review-Level: R2"; rl "agent settings (.claude/) at R2 is governance, needs R3" 1
nb ts16; mkdir -p .claude; echo '{}' > .claude/settings.json; cm cl "Generated-By: ai-agent
Review-Level: R3"; rl "agent settings (.claude/) at R3 passes (control)" 0
$SH "$S" nope >/dev/null 2>&1; pass "review-level: bad base fails closed" 2 $?
nb t14; mkdir -p .kiro/steering && echo rule > .kiro/steering/00-welcome.md; cm gov "Generated-By: human
Review-Level: R2"; rl "harness core edit at R2" 1
nb t15; mkdir -p .kiro/steering && echo rule > .kiro/steering/00-welcome.md; cm gov "Generated-By: human
Review-Level: R3"; rl "harness core edit at R3" 0
nb t16; mkdir -p .kiro/steering && echo h > .kiro/steering/next-session-prompt.md; cm h "Generated-By: ai-agent
Review-Level: R1"; rl "handoff write at R1" 0
nb t17; mkdir -p .github/workflows && echo w > .github/workflows/ci.yml; cm wf "Generated-By: human
Review-Level: R2"; rl "CI workflow edit at R2" 1
nb t18; echo s1 > docs/s.md; cm s "Generated-By: human
Review-Level: R1"
git checkout -q main; echo m >> src/crypto/k.ts; cm mc "Generated-By: human
Review-Level: R3"; git checkout -q t18
git merge -q --no-commit main >/dev/null 2>&1; echo evil >> src/crypto/k.ts; git add -A; git commit -qm merge -m "Generated-By: human
Review-Level: R1"
git checkout -q main; git reset -q --hard HEAD~1; git checkout -q t18
rl "evil merge touching crypto at R1" 1
nb t19; mkdir -p templates && echo t > templates/B-TEAM-REVIEW-PACKAGE.md; cm tpl "Generated-By: human
Review-Level: R1"; rl "harness template at R1" 1
nb t20; echo t >> src/auth/login.test.ts; cm at "Generated-By: human
Review-Level: R1"; rl "human auth file with test name at R1" 1
nb t21; mkdir -p src/tls && echo p > src/tls/pin.ts; cm tls "Generated-By: human
Review-Level: R2"; rl "TLS path at R2" 1
nb t22; mkdir -p db/migrate && echo m > db/migrate/001.sql; cm mg "Generated-By: human
Review-Level: R2"; rl "db/migrate at R2" 1
nb t23; echo x > docs/login.ts; cm dl "Generated-By: ai-agent
Review-Level: R1"; rl "code file under docs/ at R1 (docs allowlist is by document extension)" 1
nb t24; echo x > docs/guide.md; cm dm "Generated-By: ai-agent
Review-Level: R1"; rl "markdown under docs/ at R1" 0
nb t25; mkdir -p tests; for i in 1 2 3 4 5 6; do head -c 2048 /dev/urandom > tests/blob$i.bin; done; cm bin "Generated-By: ai-agent
Review-Level: R1"; rl "six binary files at R1 (binaries count toward size)" 1
nb t26; mkdir -p alembic/versions && echo m > alembic/versions/001.py; cm al "Generated-By: ai-agent
Review-Level: R2"; rl "alembic migration at R2" 1
nb t27; mkdir -p prisma && echo m > prisma/schema.prisma; cm pr "Generated-By: ai-agent
Review-Level: R2"; rl "prisma schema at R2" 1
nb t28; echo m > middleware.ts; cm mw "Generated-By: ai-agent
Review-Level: R2"; rl "agent edits middleware at R2" 1
nb t28b; echo m > middleware.ts; cm mw "Generated-By: human
Review-Level: R2"; rl "human edits middleware at R2" 0
nb t29; mkdir -p Lib/AUTH && echo m > Lib/AUTH/x.ts; cm ca "Generated-By: ai-agent
Review-Level: R2"; rl "case-variant Lib/AUTH path by agent at R2" 1
nb t30; echo m > "é.pem"; cm pem "Generated-By: ai-agent
Review-Level: R2"; rl "non-ASCII .pem name (git-quoted) at R2" 1
nb t31; mkdir -p src/billing && echo m > src/billing/charge.test.ts; cm bt "Generated-By: ai-agent
Review-Level: R1"; rl "documented limit: *.test.* is trusted as a test at R1" 0
nb t32; echo y >> src/auth/login.ts; cm lie "Generated-By: human
Review-Level: R2"; rl "documented limit: Generated-By is self-asserted (agent writing 'human' on auth passes at R2)" 0
nb t33; mkdir -p .kiro/steering && echo r > .kiro/steering/00-welcome.md; cm r3 "Generated-By: ai-agent
Review-Level: R3"; rl "documented limit: R3 is a declaration, no review artifact is checked" 0
nb t34; mkdir -p ".kiro/steering" && echo r > ".kiro/steering/a
b.md"; cm nlf "Generated-By: ai-agent
Review-Level: R2"; rl "newline in a governance file name at R2 (R3 floor)" 1
nb t40; git checkout -q --orphan t40orph; git rm -rqf . >/dev/null; mkdir -p src/crypto; echo k > src/crypto/key.ts; cm rootcrypto "Generated-By: ai-agent
Review-Level: R1"
git checkout -qb t40m main; git merge -q --allow-unrelated-histories --no-ff t40orph -m "merge orphan" -m "Generated-By: ai-agent
Review-Level: R1"; rl "orphan root commit touching src/crypto at R1 (merged with --allow-unrelated-histories)" 1
git checkout -q main
nb t41l; echo left >> src/crypto/k.ts; cm l "Generated-By: human
Review-Level: R3"
git checkout -q main; git checkout -qb t41r; echo right >> src/crypto/k.ts; cm r "Generated-By: human
Review-Level: R3"
git checkout -q t41l; git merge --no-commit t41r >/dev/null 2>&1; git checkout --ours src/crypto/k.ts; git add -A; git commit -qm res -m "Generated-By: human
Review-Level: R1"
rl "merge resolving a crypto conflict with --ours declares R1 (each parent diff counts)" 1
git checkout -q main
nb t42; printf '\000SILENT-CATCH-APPROVED: Steward\n' > src/approval.bin; cm bm "Generated-By: ai-agent
Review-Level: R2"; rl "agent adds an approval marker inside a NUL-containing file" 1
git checkout -q main
cd /; rm -rf "$T"

# ---------- license policy ----------
LT=$(mktemp -d); LIC_OUT=$(mktemp); ( FAIL=0; cd "$LT" && git init -q && mkdir .codifide
cat > .codifide/allowed-licenses <<'EOF'
MIT
Apache-2.0
BSD-3-Clause
ISC
!GPL-*
!LGPL-*
!AGPL-*
!MPL-*
EOF
lic(){ printf '%s' "$2" | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: $1" "$3" $?; }
lic "all permissive (json)" '{"a@1":{"licenses":"MIT"},"b@2":{"licenses":"Apache-2.0"}}' 0
lic "GPL denied (json)" '{"evil@9":{"licenses":"GPL-3.0-only"}}' 1
lic "unknown fails (json)" '{"x@1":{"licenses":"UNKNOWN"}}' 1
lic "not-on-allowlist fails (json)" '{"x@1":{"licenses":"BSD-2-Clause"}}' 1
lic "OR all allowed (json)" '{"x@1":{"licenses":"MIT OR Apache-2.0"}}' 0
lic "AND one denied fails (json)" '{"x@1":{"licenses":"MIT AND GPL-3.0"}}' 1
lic "cyclonedx LGPL denied" '{"components":[{"name":"a","licenses":[{"license":{"id":"LGPL-2.1-only"}}]}]}' 1
printf 'PackageName: bar\nPackageLicenseConcluded: GPL-3.0-only\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx GPL denied" 1 $?
printf '"name","license"\n"foo","MIT"\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: csv header skipped, allowed" 0 $?
printf 'foo,MPL-2.0\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: csv MPL denied" 1 $?
printf '' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: empty input errors" 2 $?
printf '{"a":"MIT"}' | CODIFIDE_LICENSE_POLICY=/nope $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: missing policy errors" 2 $?
lic "alias: MIT License (csv name)" 'x,MIT License' 0
lic "alias: Apache Software License" 'x,Apache Software License' 0
lic "OR: one side allowed passes" '{"x@1":{"licenses":"MIT OR GPL-3.0-only"}}' 0
lic "OR: both sides disallowed fails" '{"x@1":{"licenses":"GPL-3.0-only OR LGPL-2.1-only"}}' 1
lic "AND binds tighter than OR: (MIT AND GPL) OR Apache passes" '{"x@1":{"licenses":"(MIT AND GPL-3.0-only) OR Apache-2.0"}}' 0
lic "AND binds tighter than OR without parens: MIT AND GPL OR BSD-2 fails" '{"x@1":{"licenses":"MIT AND GPL-3.0-only OR BSD-2-Clause"}}' 1
lic "nested: MIT AND (GPL OR Apache) passes" '{"x@1":{"licenses":"MIT AND (GPL-3.0-only OR Apache-2.0)"}}' 0
lic "nested: MIT AND (GPL OR LGPL) fails" '{"x@1":{"licenses":"MIT AND (GPL-3.0-only OR LGPL-2.1-only)"}}' 1
lic "implicit operator (two ids, no OR/AND) fails" '{"x@1":{"licenses":"MIT Apache-2.0"}}' 1
lic "unbalanced parenthesis fails" '{"x@1":{"licenses":"(MIT"}}' 1
lic "WITH exception checks the license: GPL denied" '{"x@1":{"licenses":"GPL-2.0-only WITH Classpath-exception-2.0"}}' 1
lic "WITH exception on an allowed license passes" '{"x@1":{"licenses":"MIT WITH Foo-exception"}}' 0
lic "cyclonedx with two license entries is AND (MIT + GPL fails)" '{"components":[{"name":"a","licenses":[{"license":{"id":"MIT"}},{"license":{"id":"GPL-3.0-only"}}]}]}' 1
printf 'PackageName: bar\nPackageLicenseConcluded: MIT OR Apache-2.0\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx tag-value keeps the whole expression" 0 $?
touch mit
lic "wildcard license token does not glob to file names" '{"x@1":{"licenses":"*"}}' 1
rm -f mit
printf '*\n' > "$LT/wild-policy"; printf '{"a@1":{"licenses":"GPL-3.0-only"}}' | CODIFIDE_LICENSE_POLICY="$LT/wild-policy" $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: all-wildcard allow line is rejected" 2 $?
lic "nested cyclonedx component with a denied license fails" '{"components":[{"name":"parent","licenses":[{"license":{"id":"MIT"}}],"components":[{"name":"copyleft","licenses":[{"license":{"id":"GPL-3.0-only"}}]}]}]}' 1
lic "nested cyclonedx, allowed child passes" '{"components":[{"name":"parent","licenses":[{"license":{"id":"MIT"}}],"components":[{"name":"child","licenses":[{"license":{"id":"ISC"}}]}]}]}' 0
lic "partial parser output (a license field of the wrong type) is an error, not a pass" '{"components":[{"name":"ok","licenses":[{"license":{"id":"MIT"}}]},{"name":"unscanned","licenses":"GPL-3.0-only"}]}' 2
printf 'PackageName: unknown-dependency\nPackageVersion: 1\nPackageName: permitted\nPackageLicenseConcluded: MIT\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx package with no license line is UNKNOWN, not dropped" 1 $?
printf 'PackageName: only-name\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx trailing package with no license fails" 1 $?
lic "cyclonedx: an OR expression entry joined with a denied entry is AND" '{"components":[{"name":"restricted","licenses":[{"expression":"MIT OR GPL-3.0-only"},{"license":{"id":"GPL-3.0-only"}}]}]}' 1
lic "license-checker array: (MIT OR GPL) AND GPL fails" '{"r@1":{"licenses":["MIT OR GPL-3.0-only","GPL-3.0-only"]}}' 1
printf 'permitted,MIT\nunresolved,License\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: a 'License' value on a later csv row is a license, not a header" 1 $?
printf 'PackageName: restricted\nPackageLicenseDeclared: MIT\nPackageLicenseConcluded: GPL-3.0-only\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx tag-value Concluded GPL overrides Declared MIT" 1 $?
printf 'PackageName: ok\nPackageLicenseDeclared: GPL-3.0-only\nPackageLicenseConcluded: MIT\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx tag-value Concluded MIT is the stated conclusion" 0 $?
printf 'PackageName: x\nPackageLicenseDeclared: GPL-3.0-only\nPackageLicenseConcluded: NOASSERTION\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx Concluded NOASSERTION falls back to Declared (GPL fails)" 1 $?
lic "spdx json: Concluded NOASSERTION falls back to Declared GPL (fails)" '{"packages":[{"name":"x","licenseConcluded":"NOASSERTION","licenseDeclared":"GPL-3.0-only"}]}' 1
printf 'name,license\npermitted,MIT\nunresolved-dependency\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: a plain-list row with its license missing is a malformed report (exit 2), not dropped" 2 $?
printf 'name,license\npermitted,MIT\n\n\nother,ISC\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: blank lines in a plain list are ignored (control)" 0 $?
printf 'SPDXVersion: SPDX-2.3\nPackageName: a\nPackageSupplier: Organization: Foo, Inc\nPackageLicenseConcluded: MIT\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: spdx tag-value lines with commas are not read as list rows (control)" 0 $?
lic "malformed WITH (nothing after it) fails" 'dependency,MIT WITH' 1
lic "malformed WITH (open paren after it) fails" 'dependency,MIT WITH (' 1
lic "cyclonedx: GPL only under metadata.component.components is still scanned" '{"metadata":{"component":{"name":"app","components":[{"name":"c","licenses":[{"license":{"id":"GPL-3.0-only"}}]}]}},"components":[{"name":"p","licenses":[{"license":{"id":"MIT"}}]}]}' 1
lic "cyclonedx: permissive metadata.component.components passes (control)" '{"metadata":{"component":{"name":"app","components":[{"name":"c","licenses":[{"license":{"id":"MIT"}}]}]}},"components":[{"name":"p","licenses":[{"license":{"id":"MIT"}}]}]}' 0
printf 'permitted,MIT\n,GPL-3.0-only\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: plain-list row with an empty package name is a malformed report" 2 $?
printf 'permitted,MIT\ncopyleft,GPL-3.0-only\nPackageName: cover\nPackageLicenseConcluded: MIT\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: plain rows mixed with SPDX tag-value lines are rejected" 2 $?
printf 'SPDXVersion: SPDX-2.3\nPackageName: a\nPackageComment: <text>x, y\nz,w</text>\nPackageLicenseConcluded: MIT\n' | $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: multi-line <text> in SPDX tag-value is not read as rows (control)" 0 $?
# policy must come from the base branch
LB=$(mktemp -d); cd "$LB" && git init -q -b main && git config user.email t@t && git config user.name t && mkdir .codifide && printf 'MIT\nApache-2.0\n!GPL-*\n' > .codifide/allowed-licenses && git add -A && git commit -qm base
git checkout -qb feat/policy; printf 'GPL-3.0-only\n' >> .codifide/allowed-licenses; git commit -qam "allow GPL in the same change"
printf '{"evil@1":{"licenses":"GPL-3.0-only"}}' | $SH "$SRC"/check-licenses.sh --base main >/dev/null 2>&1; pass "licenses: policy edited in the same change cannot approve the dependency (--base)" 1 $?
printf '{"evil@1":{"licenses":"GPL-3.0-only"}}' | CODIFIDE_BASE=main $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: CODIFIDE_BASE selects the base policy" 1 $?
printf '{"ok@1":{"licenses":"MIT"}}' | $SH "$SRC"/check-licenses.sh --base main >/dev/null 2>&1; pass "licenses: allowed dependency passes against the base policy" 0 $?
printf '{"ok@1":{"licenses":"MIT"}}' | $SH "$SRC"/check-licenses.sh --base no-such-ref >/dev/null 2>&1; pass "licenses: unknown explicit base fails closed" 2 $?
printf '{"ok@1":{"licenses":"MIT"}}' | GITHUB_ACTIONS=true $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: under GitHub Actions with no base ref, fails closed" 2 $?
printf '{"ok@1":{"licenses":"MIT"}}' | CODIFIDE_REQUIRE_BASE_POLICY=1 $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: REQUIRE_BASE_POLICY with no origin/main fails closed" 2 $?
git checkout -q --orphan nopolbase; git rm -rqf . >/dev/null 2>&1; echo x > f; git add f; git commit -qm nopol
git checkout -qb adopt2; mkdir -p .codifide; printf 'MIT\n' > .codifide/allowed-licenses; git add -A; git commit -qm adopt
printf '{"ok@1":{"licenses":"MIT"}}' | $SH "$SRC"/check-licenses.sh --base nopolbase >/dev/null 2>&1; pass "licenses: base without a policy file fails closed" 2 $?
printf '{"ok@1":{"licenses":"MIT"}}' | CODIFIDE_BOOTSTRAP=1 $SH "$SRC"/check-licenses.sh --base nopolbase >/dev/null 2>&1; pass "licenses: bootstrap mode uses the branch policy" 0 $?
cd "$LT"; rm -rf "$LB"
exit $FAIL )
[[ $? -ne 0 ]] && FAIL=1
rm -rf "$LT" "$LIC_OUT"

# ---------- iteration 6 regressions (each fails on the 52b50be scripts; see docs ledger) ----------
mkrepo(){ local d; d="$(mktemp -d)"; ( cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t ) >/dev/null 2>&1; printf '%s' "$d"; }
# I6-F01: GIT_DIR / GIT_WORK_TREE in the environment must not redirect the three CI scripts to a decoy repository.
R6="$(mkrepo)"; D6="$(mkrepo)"
( cd "$R6" && mkdir -p .codifide verifiers && printf 'verifiers/\n' > .codifide/immutable-paths && printf 'MIT\n' > .codifide/allowed-licenses && echo o > verifiers/check.py \
  && git add -A && git commit -qm base && git checkout -qb attack && echo t >> verifiers/check.py && git commit -qam 'no trailers' ) >/dev/null 2>&1
( cd "$D6" && mkdir -p .codifide && printf 'unrelated/\n' > .codifide/immutable-paths && printf 'GPL-3.0-only\n' > .codifide/allowed-licenses && git add -A && git commit -qm base ) >/dev/null 2>&1
( cd "$R6" && GIT_DIR="$D6/.git" GIT_WORK_TREE="$D6" $SH "$SRC"/check-immutable-paths.sh main >/dev/null 2>&1 ); pass "immutable-ci: GIT_DIR/GIT_WORK_TREE decoy repo cannot hide a verifier edit" 1 $?
( cd "$R6" && GIT_DIR="$D6/.git" GIT_WORK_TREE="$D6" $SH "$SRC"/check-review-level.sh main >/dev/null 2>&1 ); pass "review-level: GIT_DIR/GIT_WORK_TREE decoy repo cannot hide a commit without trailers" 1 $?
( cd "$R6" && printf '{"evil":{"licenses":"GPL-3.0-only"}}' | GIT_DIR="$D6/.git" GIT_WORK_TREE="$D6" $SH "$SRC"/check-licenses.sh --base main >/dev/null 2>&1 ); pass "licenses: GIT_DIR/GIT_WORK_TREE decoy repo cannot supply a permissive policy" 1 $?
( cd "$R6" && $SH "$SRC"/check-immutable-paths.sh main >/dev/null 2>&1 ); pass "immutable-ci: same repo without the decoy variables is blocked (control)" 1 $?
rm -rf "$R6" "$D6"
# I6-F02: a symlink target that ends in a newline is a different name; the newline must survive command substitution.
R6="$(mkrepo)"
( cd "$R6" && mkdir -p .codifide vault src && printf 'vault/*.pem?\n' > .codifide/immutable-paths && printf 's\n' > $'vault/key.pem\n' \
  && ln -s $'../vault/key.pem\n' src/alias && git add -A && git commit -qm base && git checkout -qb attack \
  && ln -s $'../vault/key.pem\n' src/alias2 && git add src/alias2 && git commit -qm alias ) >/dev/null 2>&1
( cd "$R6" && printf '%s' '{"input":{"path":"src/alias"}}' | $SH "$SRC"/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "guard: symlink whose target ends in a newline resolves to the newline-named protected file" 2 $?
( cd "$R6" && $SH "$SRC"/check-immutable-paths.sh main >/dev/null 2>&1 ); pass "immutable-ci: new symlink whose target ends in a newline is a link into the protected file" 1 $?
( cd "$R6" && printf '%s' '{"input":{"path":"src/other.txt"}}' | $SH "$SRC"/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "guard: unrelated write in the same repository (allow control)" 0 $?
rm -rf "$R6"
# I6-F03: NFC/NFD alias in the CI symlink traversal (git does not precompose; the checkout filesystem may fold).
R6="$(mkrepo)"
( cd "$R6" && git config core.precomposeunicode false && mkdir -p .codifide && printf 'verifiers/\n' > .codifide/immutable-paths && git add -A && git commit -qm pol ) >/dev/null 2>&1
( cd "$R6" && h=$(echo v | git hash-object -w --stdin) && git update-index --add --cacheinfo 100644,$h,verifiers/check.py \
  && git update-index --add --cacheinfo 100644,$h,src2/other.py \
  && l1=$(printf '../verifiers' | git hash-object -w --stdin) && git update-index --add --cacheinfo 120000,$l1,"$(printf 'src/caf\303\251')" \
  && l2=$(printf '../src2' | git hash-object -w --stdin) && git update-index --add --cacheinfo 120000,$l2,"$(printf 'src/caf\303\251-ok')" \
  && git commit -qm base && git checkout -qb attack \
  && a=$(printf 'cafe\314\201/check.py' | git hash-object -w --stdin) && git update-index --add --cacheinfo 120000,$a,src/alias \
  && git commit -qm alias ) >/dev/null 2>&1
( cd "$R6" && $SH "$SRC"/check-immutable-paths.sh main >/dev/null 2>&1 ); pass "immutable-ci: NFD-spelled directory symlink component reaches the protected file" 1 $?
( cd "$R6" && git checkout -q main && git checkout -qb ok && b=$(printf 'cafe\314\201-ok/other.py' | git hash-object -w --stdin) && git update-index --add --cacheinfo 120000,$b,src/alias \
  && git commit -qm okalias ) >/dev/null 2>&1
( cd "$R6" && $SH "$SRC"/check-immutable-paths.sh main >/dev/null 2>&1 ); pass "immutable-ci: NFD-spelled symlink component that ends outside protected paths passes (control)" 0 $?
rm -rf "$R6"
# I6-F04: the hard-link scan must fail closed when find cannot read part of the repository.
R6="$(mkrepo)"
( cd "$R6" && mkdir -p .codifide vault src && printf 'vault/*\n' > .codifide/immutable-paths && echo s > vault/key && ln vault/key src/alias && echo p > src/plain && ln src/plain src/plain2 ) >/dev/null 2>&1
chmod 000 "$R6/vault"
if [[ -r "$R6/vault/key" || -x "$R6/vault" ]]; then
  echo "SKIP  guard: hard-link scan with an unreadable directory (running as a user that ignores modes)"
else
  ( cd "$R6" && printf '%s' '{"input":{"path":"src/alias"}}' | $SH "$SRC"/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "guard: hard link to a protected file hidden behind an unreadable directory blocks (fail closed)" 2 $?
  ( cd "$R6" && printf '%s' '{"input":{"path":"src/new.txt"}}' | $SH "$SRC"/guard-immutable-paths.sh >/dev/null 2>&1 ); pass "guard: a file with a single link is still allowed when a directory is unreadable (control)" 0 $?
fi
chmod 700 "$R6/vault"; rm -rf "$R6"
# I6-F05 / F06: license parsing.
LP6="$(mktemp)"; printf 'MIT\n!GPL-*\n' > "$LP6"
lic6(){ printf '%s\n' "$3" | CODIFIDE_LICENSE_POLICY="$LP6" $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: $1" "$2" $?; }
lic6 "spdx: a <text> comment cannot overwrite the concluded GPL license" 1 "$(printf 'SPDXVersion: SPDX-2.3\nPackageName: evil\nPackageLicenseConcluded: GPL-3.0-only\nPackageComment: <text>\nPackageLicenseConcluded: MIT\n</text>')"
lic6 "spdx: a <text> comment cannot overwrite the declared GPL license" 1 "$(printf 'PackageName: evil\nPackageLicenseDeclared: GPL-3.0-only\nPackageComment: <text>\nPackageLicenseDeclared: MIT\n</text>')"
lic6 "spdx: a <text> comment that quotes another license after a real MIT is ignored (control)" 0 "$(printf 'PackageName: ok\nPackageLicenseConcluded: MIT\nPackageComment: <text>\nPackageLicenseConcluded: GPL-3.0-only\n</text>')"
printf '%s' '{"components":[{"name":"parent","licenses":[{"license":{"id":"MIT"}}],"components":"unscanned dependency collection"}]}' | CODIFIDE_LICENSE_POLICY="$LP6" $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: cyclonedx nested components that is not an array is a parse error, not a pass" 2 $?
printf '%s' '{"components":[{"name":"parent","licenses":[{"license":{"id":"MIT"}}],"components":{"name":"c","licenses":[{"license":{"id":"GPL-3.0-only"}}]}}]}' | CODIFIDE_LICENSE_POLICY="$LP6" $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: cyclonedx nested components given as an object is a parse error" 2 $?
printf '%s' '{"components":[{"name":"parent","licenses":[{"license":{"id":"MIT"}}],"components":null}]}' | CODIFIDE_LICENSE_POLICY="$LP6" $SH "$SRC"/check-licenses.sh >/dev/null 2>&1; pass "licenses: cyclonedx nested components null is accepted (control)" 0 $?
rm -f "$LP6"
# I6-F07: a symlink named like a governance directory is a single tree entry and must be R3.
R6="$(mkrepo)"
( cd "$R6" && echo base > README.md && git add -A && git commit -qm base && git checkout -qb a1 && ln -s attacker-rules .codifide && git add .codifide \
  && git commit -qm 'redirect governance directory' -m 'Generated-By: ai-agent
Review-Level: R2' && git checkout -q main && git checkout -qb a2 && ln -s attacker .claude && git add .claude \
  && git commit -qm 'redirect agent settings' -m 'Generated-By: ai-agent
Review-Level: R2' && git checkout -q main && git checkout -qb a3 && ln -s attacker-rules .codifide && git add .codifide \
  && git commit -qm 'redirect governance directory' -m 'Generated-By: ai-agent
Review-Level: R3' ) >/dev/null 2>&1
( cd "$R6" && git checkout -q a1 && git branch -f cur a1 && $SH "$SRC"/check-review-level.sh main >/dev/null 2>&1 ); pass "review-level: symlink named .codifide at R2 is governance (R3 floor)" 1 $?
( cd "$R6" && git checkout -q a2 && $SH "$SRC"/check-review-level.sh main >/dev/null 2>&1 ); pass "review-level: symlink named .claude at R2 is governance (R3 floor)" 1 $?
( cd "$R6" && git checkout -q a3 && $SH "$SRC"/check-review-level.sh main >/dev/null 2>&1 ); pass "review-level: symlink named .codifide at R3 passes (control)" 0 $?
rm -rf "$R6"
# I6-F08: the workflow-example check must look for RUN steps, not for words anywhere in the file.
wf_steps_ok(){ command -v python3 >/dev/null 2>&1 && python3 - "$1" <<'WFPY'
import re, sys
need = ["check-immutable-paths.sh", "check-review-level.sh", "check-licenses.sh"]
lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
keys = {k: False for k in ("on:", "jobs:", "steps:")}
text = []          # non-comment text that sits in a `run:` step (one-line value or block scalar)
blk = None         # indent of the `run:` key while inside its block scalar
for ln in lines:
    if not ln.strip():
        continue
    ind = len(ln) - len(ln.lstrip())
    st = ln.strip()
    if blk is not None:
        if ind > blk:
            if not st.startswith("#"):
                text.append(st)
            continue
        blk = None
    if st.startswith("#"):
        continue
    for k in keys:
        if re.match(r"^" + re.escape(k), ln):
            keys[k] = True
    if st == "steps:" or st.startswith("steps:"):
        keys["steps:"] = True
    m = re.match(r"^(\s*(?:-\s+)?)run:\s*(.*)$", ln)
    if m:
        val = m.group(2).strip()
        if val in ("|", ">", "|-", ">-", "|+", ">+"):
            blk = len(m.group(1))
        elif val and not val.startswith("#"):
            text.append(val)
body = "\n".join(text)
ok = all(keys.values()) and all(re.search(r"\bbash\b[^\n#]*" + re.escape(n), body) for n in need)
sys.exit(0 if ok else 1)
WFPY
}
VAC="$(mktemp)"; printf '%s\n' '# check-immutable-paths.sh' '# check-review-level.sh' '# check-licenses.sh' '# push:' '# BOOTSTRAP' '# codifide-enforcer-change-approved' '# CODIFIDE_LICENSE_REPORT_CMD' 'check-licenses.sh" --base' 'check-immutable-paths.sh' 'check-review-level.sh' > "$VAC"
wf_steps_ok "$VAC"; pass "docs: a file of comments and bare script names is NOT a workflow that runs the checks" 1 $?
rm -f "$VAC"
if [[ -f "$HERE/workflow.example.yml" ]]; then
  wf_steps_ok "$HERE/workflow.example.yml"; pass "docs: the workflow example has run steps that execute all three scripts" 0 $?
  NOLIC="$(mktemp)"; sed 's/^\(.*\)check-licenses\.sh" --base/# \1check-licenses.sh" --base/' "$HERE/workflow.example.yml" > "$NOLIC"
  wf_steps_ok "$NOLIC"; pass "docs: a workflow whose license step was commented out is rejected" 1 $?
  rm -f "$NOLIC"
fi
cd /

# ---------- distribution and documentation consistency (only when run from the full repo) ----------
REPO="$(cd "$HERE/../.." && pwd)"
if [[ -f "$REPO/README.md" && -d "$REPO/steering" && -d "$REPO/templates/hooks" ]]; then
  chk(){ local n="$1"; shift; "$@" >/dev/null 2>&1; pass "docs: $n" 0 $?; }
  has(){ grep -q -E "$1" "$2"; }
  hooks_ok(){ local f; for f in "$REPO"/templates/hooks/*/*.json; do
    if command -v jq >/dev/null 2>&1; then jq -e . "$f" >/dev/null || return 1; else python3 -c 'import json,sys;json.load(open(sys.argv[1]))' "$f" || return 1; fi; done; }
  blocking_hooks_fail_closed(){ grep -q '|| exit 2' "$REPO/templates/hooks/kiro/guard-immutable-paths.json" && grep -q '|| exit 2' "$REPO/templates/hooks/claude-code/settings.example.json"; }
  readme_hooks_exist(){ local h; for h in $(grep -Eo '`[a-z-]+\.json`' "$REPO/README.md" | tr -d '`' | sort -u); do [[ -f "$REPO/templates/hooks/kiro/$h" ]] || { echo "missing $h"; return 1; }; done; }
  no_stale(){ local g=7 v=2 sv=sev pat  # built from parts so this file does not contain the strings it forbids
    pat="${g}-gate|${sv}en gates|Version ${v}\\.0|FLAG FOR COUNSE[L]|(^|[^0-9])${g}0 cases|${g} Gates for"
    ! grep -rIn -E "$pat" --exclude-dir=.git --exclude-dir=docs --exclude-dir=.worktrees "$REPO"; }
  spdx_ok(){ local f; for f in "$HERE"/guard-immutable-paths.sh "$HERE"/check-*.sh "$REPO"/templates/cursor/to-mdc.sh; do head -3 "$f" | grep -q 'SPDX-License-Identifier: MIT' || { echo "no SPDX: $f"; return 1; }; done; }
  workflow_ok(){ local w="$HERE/workflow.example.yml"; has 'check-immutable-paths.sh' "$w" && has 'check-review-level.sh' "$w" && has 'check-licenses.sh' "$w" && has 'push:' "$w" && has 'BOOTSTRAP' "$w" && has 'codifide-enforcer-change-approved' "$w" && has '^[^#]*check-licenses.sh" --base' "$w" && has 'CODIFIDE_LICENSE_REPORT_CMD' "$w" && has '^[^#]*check-immutable-paths.sh' "$w" && has '^[^#]*check-review-level.sh' "$w" && wf_steps_ok "$w"; }
  cursor_ok(){ local d; d="$(mktemp -d)"; bash "$REPO/templates/cursor/to-mdc.sh" "$d" >/dev/null || return 1
    head -4 "$d/00-welcome.mdc" | grep -q 'alwaysApply: true' || return 1
    head -4 "$d/11-tiered-adversarial-review.mdc" | grep -q 'alwaysApply: false' || return 1
    [[ "$(sed '1,4d' "$d/00-welcome.mdc")" == "$(awk 'f{print} /^---$/{c++; if(c==2)f=1}' "$REPO/steering/00-welcome.md")" ]] || return 1
    bash "$REPO/templates/cursor/to-mdc.sh" "$d" >/dev/null 2>&1 && return 1; rm -rf "$d"; return 0; }
  core_size(){ [[ "$(wc -w < "$REPO/steering/00-welcome.md")" -le 2400 ]]; }
  eol_ok(){ has 'eol=lf' "$REPO/.gitattributes" && has '\*\.sh' "$REPO/.gitattributes"; }
  version_ok(){ [[ "$(cat "$REPO/VERSION")" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && has "^## \[$(cat "$REPO/VERSION")\]" "$REPO/CHANGELOG.md"; }
  prereq_ok(){ has 'WSL' "$HERE/README.md" && has 'jq' "$HERE/README.md" && has 'python3' "$HERE/README.md"; }
  limits_ok(){ has 'DOCUMENTED LIMITS|Documented limits' "$HERE/README.md" && has 'self-asserted' "$HERE/README.md" && has 'Shell commands' "$HERE/README.md"; }
  chk "hook files are valid JSON" hooks_ok
  chk "blocking hooks run the guard as 'bash <guard> || exit 2'" blocking_hooks_fail_closed
  chk "every hook file named in the README exists" readme_hooks_exist
  chk "no stale gate count, version footer, counsel marker or case count" no_stale
  chk "scripts carry SPDX headers" spdx_ok
  chk "workflow example runs all three CI scripts uncommented, requires a license report command, bootstraps, and also runs on push" workflow_ok
  # 3.2.1: the default pull_request checkout is the synthetic merge commit (no trailers).
  pr_head_ok(){ local w="$HERE/workflow.example.yml"; has '^[^#]*ref: \$\{\{ github\.event\.pull_request\.head\.sha \|\| github\.sha \}\}' "$w"; }
  chk "workflow example checks out the PR head commit, not the synthetic merge commit" pr_head_ok
  chk "Cursor converter writes .mdc with alwaysApply, copies the core body, never overwrites" cursor_ok
  chk "always-loaded core stays at or under 2,400 words" core_size
  chk ".gitattributes forces LF for scripts" eol_ok
  chk "VERSION is semver and CHANGELOG has that entry" version_ok
  chk "enforcement README states WSL/Git Bash, jq/python3 prerequisites" prereq_ok
  chk "enforcement README states the documented limits" limits_ok
  claimed="$(grep -Eo '[0-9]+ cases' "$REPO/README.md" | head -1 | grep -Eo '[0-9]+')"
  actual=$(( $(wc -l < "$COUNTF" | tr -d ' ') + 1 ))
  [[ "${claimed:-0}" -eq "$actual" ]]; pass "docs: README states the real case count ($actual)" 0 $?
fi
rm -f "$COUNTF"

echo "RESULT[$SH]: $([[ $FAIL -eq 0 ]] && echo ALL PASS || echo FAILURES)"
exit $FAIL
