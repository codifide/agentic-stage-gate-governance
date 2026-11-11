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
unset GITHUB_ACTIONS CODIFIDE_WAIVE CODIFIDE_REQUIRE_IMMUTABLE_LIST CODIFIDE_STEWARD CODIFIDE_VERIFIER_CHANGE_APPROVED_BY CODIFIDE_SESSIONS CODIFIDE_LICENSE_POLICY CODIFIDE_BASE
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
  workflow_ok(){ local w="$HERE/workflow.example.yml"; has 'check-immutable-paths.sh' "$w" && has 'check-review-level.sh' "$w" && has 'check-licenses.sh' "$w" && has 'push:' "$w" && has 'BOOTSTRAP' "$w" && has 'codifide-enforcer-change-approved' "$w"; }
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
  chk "workflow example runs all three CI scripts, bootstraps, and also runs on push" workflow_ok
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
