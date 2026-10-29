#!/usr/bin/env bash
# SGL Harness — enforcement test suite.
# Runs every enforcement script against throwaway git repos in $TMPDIR.
# Usage: bash templates/enforcement/test-enforcement.sh   (SH_UNDER_TEST=/path/to/bash to pick a shell)
# Exit 0 = all pass.
set -u
SH="${SH_UNDER_TEST:-bash}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
pass(){ local ok=PASS; [[ $2 -ne $3 ]] && { ok=FAIL; FAIL=1; }; echo "$ok  $1 (want $2, got $3)"; }

# ---------- guard ----------
T=$(mktemp -d); cd "$T" && git init -q -b main && git config user.email t@t && git config user.name t
mkdir -p .sgl verifiers src tests/golden
cp "$SRC"/immutable-paths.example .sgl/immutable-paths; cp "$SRC"/guard-immutable-paths.sh "$SRC"/check-immutable-paths.sh .sgl/
echo v > verifiers/check.py; echo g > tests/golden/a.json; echo s > src/app.py
git add -A && git commit -qm base
g(){ printf '%s' "$3" | $SH .sgl/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: $1" "$2" $?; }
g "allow src write" 0 '{"input":{"path":"src/app.py","text":"x"}}'
g "block verifier write" 2 '{"input":{"path":"verifiers/check.py"}}'
g "block relative dotdot (foo/../verifiers)" 2 '{"input":{"path":"foo/../verifiers/eval.py"}}'
g "block src/../tests/golden" 2 '{"input":{"path":"src/../tests/golden/a.json"}}'
g "block ./ and // forms" 2 '{"input":{"path":".//verifiers/./x.py"}}'
g "block abs symlinked tmp path" 2 "{\"input\":{\"path\":\"$T/tests/golden/a.json\"}}"
g "block abs dotdot path" 2 "{\"input\":{\"path\":\"$T/src/../verifiers/x.py\"}}"
g "allow abs src path" 0 "{\"input\":{\"path\":\"$T/src/new.py\"}}"
g "allow dotdot that stays in src" 0 '{"input":{"path":"src/a/../b.py"}}'
g "block list self-edit" 2 '{"input":{"path":".sgl/immutable-paths"}}'
g "block guard self-edit" 2 '{"input":{"path":".sgl/guard-immutable-paths.sh"}}'
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
printf '!.sgl/immutable-paths\n' >> .sgl/immutable-paths
g "list cannot be excepted" 2 '{"input":{"path":".sgl/immutable-paths"}}'
mv .sgl/immutable-paths /tmp/sgl-list-$$
printf '%s' '{"input":{"path":"src/app.py"}}' | SGL_REQUIRE_IMMUTABLE_LIST=1 $SH .sgl/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: missing list + required blocks" 2 $?
printf '%s' '{"input":{"path":"src/app.py"}}' | $SH .sgl/guard-immutable-paths.sh >/dev/null 2>&1; pass "guard: missing list, not required, allows" 0 $?
mv /tmp/sgl-list-$$ .sgl/immutable-paths
git checkout -q -- .sgl/immutable-paths
rm -f src/alias.py; rm -rf .kiro

# ---------- immutable CI ----------
ci(){ $SH .sgl/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: $1" "$2" $?; }
git checkout -qb feat/a; echo y >> src/app.py; git commit -qam ok; ci "clean feature branch" 0
echo z >> verifiers/check.py; git commit -qam bad; ci "verifier edit on ordinary branch" 1
SGL_VERIFIER_CHANGE_APPROVED_BY="Pat Steward" $SH .sgl/check-immutable-paths.sh main >/dev/null 2>&1; pass "immutable-ci: steward-approved change" 0 $?
git checkout -qb feat/b main; git mv tests/golden/a.json src/a.json; git commit -qm mv; ci "rename out of golden" 1
git checkout -qb feat/c main; printf '' > .sgl/immutable-paths; echo z >> verifiers/check.py; git commit -qam loosen; ci "loosen list + edit" 1
$SH .sgl/check-immutable-paths.sh does-not-exist >/dev/null 2>&1; pass "immutable-ci: bad base fails closed" 2 $?
git checkout -q --orphan nolist && git rm -rqf . && echo x > f && git add f && git commit -qm nolist && git checkout -qb nolist-feat && echo y >> f && git commit -qam y
$SH "$SRC"/check-immutable-paths.sh nolist >/dev/null 2>&1; pass "immutable-ci: no list, not required, passes" 0 $?
SGL_REQUIRE_IMMUTABLE_LIST=1 $SH "$SRC"/check-immutable-paths.sh nolist >/dev/null 2>&1; pass "immutable-ci: no list + required fails closed" 2 $?
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
SGL_WAIVE=size SGL_STEWARD="Pat" $SH "$S" main >/dev/null 2>&1; pass "review-level: size waiver + R2 big commit passes" 0 $?
SGL_WAIVE=size $SH "$S" main >/dev/null 2>&1; pass "review-level: waiver without steward errors" 2 $?
SGL_WAIVE=path SGL_STEWARD=Pat $SH "$S" main >/dev/null 2>&1; pass "review-level: unsupported waiver errors" 2 $?
nb t12; echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' >> src/lib/access.ts; cm mk "Generated-By: ai-agent
Review-Level: R2"; rl "agent adds approval marker" 1
nb t13; echo 'x // SILENT-CATCH-APPROVED: Pat, 2026' >> src/lib/access.ts; cm mk "Generated-By: human
Review-Level: R2"; rl "human adds approval marker" 0
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
cd /; rm -rf "$T"
echo "RESULT[$SH]: $([[ $FAIL -eq 0 ]] && echo ALL PASS || echo FAILURES)"
exit $FAIL
