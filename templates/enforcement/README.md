# Enforcement — Making the Critical Rules Hold

Two harness rules matter too much to leave to prose: **a loop may never edit what judges it**, and **a change may never be reviewed below its Review Level**. These scripts enforce what they can compute. They fail closed: if they can't decide (bad input, unreadable list, missing base ref, git error, unexpected crash), they block. The one deliberate exception is a repo that has not adopted `.codifide/immutable-paths` yet; set `CODIFIDE_REQUIRE_IMMUTABLE_LIST=1` once it has, and a missing list blocks too. The guard and the check print a warning while the list is missing.

This page also says what the scripts do **not** do. Read "Documented limits" before relying on them.

| File | What it does | Where it goes |
|------|--------------|---------------|
| `immutable-paths.example` | The human-owned list of protected paths | Copy to `<repo>/.codifide/immutable-paths` and edit |
| `guard-immutable-paths.sh` | Blocks agent file-write tools from touching protected paths (exit 2). Resolves symlinks component by component (so `src/link/../x` is judged where the filesystem sends it), also checks a symlink's own name, hard links wherever they live, and directories that contain a protected path (recursive delete of `tests` when `tests/golden/` is protected; a bare `.` blocks); matches case-insensitively; trims surrounding whitespace and newlines; checks paths with interior newlines or a NUL byte and JSON object keys; has no path-length cutoff; judges a RELATIVE path against every plausible base (the repository root, the hook's working directory, and the `cwd` the payload reports), so `check.py` from inside `verifiers/` is blocked (a hook that runs inside a protected directory therefore over-blocks relative paths); ignores any `CODIFIDE_ROOT` that is not the repository's own top level and blocks instead (no decoy root); also checks the NFC and NFD Unicode spellings of every path (needs `python3`; without it only an inode comparison with literal list entries covers APFS-style aliases) and reads file names NUL-delimited so a newline in a name cannot hide a hard link. Empty input, an unreadable list, or any unexpected error blocks. | `<repo>/.codifide/`, registered as a PreToolUse command hook (`templates/hooks/`) |
| `check-immutable-paths.sh` | Fails CI if a PR's diff touches protected paths (list read from the base branch). Reads file names NUL-delimited, matches case-insensitively and Unicode-alias aware (a non-ASCII changed path is also matched in its NFC and NFD forms, because Linux git does not precompose; needs `python3`, otherwise such a path is reported, fail closed), follows a new symlink through the HEAD tree across any number of hops, looking each directory up case-insensitively (loops fail), classifies a symlink by where it points (a link into `.codifide/` needs the enforcer approval), and reports any change under the enforcement paths even if the list does not name them (that needs the enforcer approval). Two scoped approvals (below). | CI, every PR |
| `check-review-level.sh` | Per commit (merges on their conflict resolutions and on every file that differs from either parent and that the branch changes against the base): requires valid `Generated-By` and `Review-Level` trailers, computes the floor from the files that commit touches (harness files are R3; a root commit, such as an orphan history merged in, is checked against the empty tree), rejects under-declaration and agent-written approval markers. If the PR trips the size rule, every commit must meet it. Binary files count 100 lines each toward size; the marker scan reads binary diffs as text. | CI, every PR |
| `check-licenses.sh` | Fails CI if a dependency's license is not allowed by the policy **on the base branch**. SPDX `OR`, `AND`, parentheses and `WITH` are evaluated; common SBOM names ("MIT License") are mapped to SPDX ids. Reads an SBOM or `name,license` list on stdin or from a file; in a plain list every non-blank row must carry a license column, and a row that does not is a malformed report (exit 2), never silently dropped. Nested CycloneDX components are scanned; a package with no license is UNKNOWN; a parser failure is exit 2, never a partial pass. When a report lists several licenses for one package they are ANDed, each entry parenthesised; an SPDX `Concluded` license wins over `Declared` (`NOASSERTION` falls back to `Declared`); only the first csv row can be a header. | CI, every PR, after your dependency report step |
| `workflow.example.yml` | A complete GitHub Actions workflow that runs all three CI scripts (the license step is on and fails until you set the repository variable `CODIFIDE_LICENSE_REPORT_CMD` to your dependency-report command), including first-run bootstrap and a push-to-main tripwire | `.github/workflows/codifide-enforcement.yml` |
| `allowed-licenses.example` | The license allow-list (copy to `.codifide/allowed-licenses`). Two postures: permissive-OSS and proprietary. | — |
| `test-enforcement.sh` | The regression suite (run it: the last line and the README count must agree), against throwaway repos | Run locally or in CI after editing any script |

## Prerequisites

- `bash` 3.2 or newer, and `git`.
- `jq` **or** `python3`. The guard needs one of them to read the hook's JSON; if neither is installed it blocks every write while a list exists. `check-licenses.sh` uses `jq` for JSON reports.
- Linux and macOS are tested. **Windows: use WSL, or Git Bash.** Native PowerShell and cmd cannot run these scripts. Claude Code on Windows without Git Bash treats exit codes other than 0 and 2 differently, so test the hook there before relying on it.
- Line endings must be LF. The repo ships a `.gitattributes` for this; copy it, because a script saved with CRLF endings can fail in unexpected ways.

## Install

```bash
mkdir -p .codifide
cp templates/enforcement/immutable-paths.example .codifide/immutable-paths
cp templates/enforcement/{guard-immutable-paths,check-immutable-paths,check-review-level,check-licenses}.sh .codifide/
cp templates/enforcement/allowed-licenses.example .codifide/allowed-licenses   # then keep ONE posture
cp templates/enforcement/test-enforcement.sh .codifide/                        # optional
chmod +x .codifide/*.sh
# Edit .codifide/immutable-paths and .codifide/allowed-licenses, then commit them on main.
bash templates/enforcement/test-enforcement.sh   # expect: RESULT ... ALL PASS
```

Register the guard as a hook from `templates/hooks/` (Kiro or Claude Code), then add the workflow.

### Check that your hook blocks

The harness cannot know how your host treats a hook's exit code. After installing, ask the agent to edit a file listed in `.codifide/immutable-paths`. The edit must be refused. If it goes through, the hook is not enforcing in your tool and CI is your only blocking control. Also pipe a sample by hand:

```bash
echo '{"input":{"path":"verifiers/check.py"}}' | bash .codifide/guard-immutable-paths.sh; echo "exit=$?"   # expect exit=2
```

## CI

Use `workflow.example.yml`. It differs from a naive setup in five ways that matter:

1. **Checks run from the base branch.** The job copies `.codifide/*.sh` from `origin/<base>` and runs those, so a PR cannot weaken the checks that judge it.
2. **First-run bootstrap.** If the base branch has none of the scripts yet (the adoption PR), the job runs the PR's own copies once and prints a warning. That PR needs the Human Steward's review: on first adoption the PR is the only source of the rules. If the base has some of the scripts but not all, the job fails.
3. **License policy comes from the base branch** (`--base`; under GitHub Actions a missing base fails closed). A change that adds `GPL-3.0-only` to `allowed-licenses` cannot approve its own dependency.
4. **It also runs on pushes to `main`**, as a tripwire for anything that reached `main` without a passing PR check.
5. **Two labels, two decisions.** `codifide-verifier-change-approved` sets `CODIFIDE_VERIFIER_CHANGE_APPROVED_BY` and waives edits to verifiers, fixtures and baselines. It does **not** waive edits to `.codifide/`, `.github/workflows/`, `CODEOWNERS`, `.kiro/hooks/` or `.claude/settings.json`. Those need `codifide-enforcer-change-approved`, which sets `CODIFIDE_ENFORCER_CHANGE_APPROVED_BY`. A PR that changes both kinds needs both labels.

### What you must configure (the repo cannot check this for you)

A label is only as trustworthy as who can apply it, and a workflow file is only as trustworthy as who can edit it.

- A `CODEOWNERS` entry making the Human Steward the required reviewer for `.codifide/`, `.kiro/`, `.github/workflows/`, `CODEOWNERS` itself, and every path in `.codifide/immutable-paths`.
- Branch protection on `main`: require CODEOWNERS review, and require the `codifide-enforcement` check to pass. Without "required", the check is advisory.
- Restrict who can apply the two labels to the Steward. Agent identities must never hold that permission, or write access to `main`.
- The workflow itself lives in the PR, and for `pull_request` events GitHub uses the PR's version of it. The strongest fix is an organization ruleset or required workflow that runs a copy the PR cannot edit; the minimum is the CODEOWNERS rule above.
- Run agents under a separate bot identity or token, so the Steward's signing key and credentials are never in the agent's reach.

## What each layer covers

| Write path | Guard hook | CI check |
|------------|------------|----------|
| Agent file tools (write, edit, append, delete, move, rename) | Blocks (if your host honours exit 2) | Catches |
| Shell commands (`sed -i`, `mv`, redirects) | **Not inspected** | Catches |
| Edits to `.codifide/immutable-paths` itself | Blocks | Catches (list is read from base) |
| Hard link or symlink to a protected file | Blocks | Catches a symlink (any hop count); a hard link is the same blob under another name, caught if the protected file's content changes |
| Recursive delete or move of a directory that contains protected paths | Blocks | Catches |

Coverage by host:

| Host | Blocking guard hook shipped | Notes |
|------|-----------------------------|-------|
| Kiro | yes (`templates/hooks/kiro/`) | exit-2 behaviour `[UNVERIFIED]` by us; run the check above |
| Claude Code | yes (`templates/hooks/claude-code/`) | documented by the vendor to block on exit 2; most writes happen through the shell, which the hook does not see |
| Cursor, Copilot, Windsurf, Codex | no | they have hook mechanisms we have not tested; CI is your blocking control |

## Documented limits

These cannot be fixed inside a bash script or a file-write hook. Each has a compensating control that **you** must put in place.

| Limit | Why it cannot be closed here | Compensating control |
|---|---|---|
| **Shell commands are not inspected** by the guard (`printf x >> verifiers/check.py`) | A file-write hook sees tool arguments, not what a shell will do | Make the CI check a required status check; deny shell writes to protected paths in your agent's permission settings; run agents in a sandbox without write access to those paths |
| **`Generated-By` is self-asserted.** An agent can write `Generated-By: human` and lower the sensitive-path floor | A commit message carries no identity proof | Signed commits; a separate bot identity for agents; CODEOWNERS review on sensitive paths; the quarterly provenance audit (`03`) |
| **`Review-Level: R3` is a declaration**, not evidence that a review or an independent model ran | No script reads a review artifact or knows which model reviewed | The Human Steward reads the review package at the gate; CODEOWNERS on governance paths |
| **Path-based floors are a convention.** `*.test.*` and `tests/` are trusted as tests; code placed there at R1 is not caught | The script cannot know a file's purpose | CODEOWNERS on production directories; review |
| **A missing list fails open by default** (guard and CI) so a half-installed harness does not brick a repo | A new repo has no list yet | Set `CODIFIDE_REQUIRE_IMMUTABLE_LIST=1` (the example workflow does); the guard and CI print a warning while the list is missing |
| **The size-rule waiver is a label.** `CODIFIDE_WAIVE=size` plus a steward name lowers the size floor from R3 to R2 | By design (rule 8, mechanical refactor); it is the only waiver | Restrict who can apply the label; the waiver is printed in the CI log |
| **The approval variables are only as strong as who sets them** | The scripts cannot see GitHub permissions | Label permissions, CODEOWNERS, branch protection (above) |
| **A symlink whose target is an absolute path** is not followed by the CI check (it leaves the repository), and a directory that does not exist yet is not an ancestor in the guard's file scan | The check reasons about the committed tree only | Review absolute-target symlinks; keep protected data out of reach of the agent's OS user |
| **The guard over-blocks some harmless strings.** A tool argument equal to `.`, to a directory holding a protected path, or to a path that case-folds to one is blocked | The guard cannot tell a path from text without knowing each tool's schema | Choose different arguments; this is the fail-closed direction |
| **Text-encoded approval markers** (for example UTF-16, or base64 in a data file) are not recognised by the marker scan; only the plain ASCII markers are | A scan sees bytes, not intent | CODEOWNERS and review on data files; the Steward reads agent diffs |
| **`CODIFIDE_ROOT` is no longer an override.** Setting it to anything but the repository top level makes the guard block | A caller-chosen root would let a decoy list stand in for the real one | Unset it; run the hook from inside the repository |
| **The workflow file can be edited by the PR it judges** (for `pull_request` events) | A property of how the CI host picks the workflow | CODEOWNERS on `.github/workflows/`, or an organization required workflow |
| **Host behaviour is untested here:** whether a host loads `inclusion: auto` files, and whether it honours exit 2 | We do not run those hosts in this repo's tests | Run the "Check that your hook blocks" test in your own environment |

## What the review-level check can and cannot compute

| Computed (enforced) | Not computable (reviewers and the Steward apply them, and can only raise) |
|---------------------|----------------------------------------------------------------------------|
| Harness files (`.kiro/`, `.codifide/`, `steering/`, CI workflows, CODEOWNERS) → R3; handoff file exempt | New architectural pattern, service, or integration (rule 3) |
| R1 only for the allowlist (tests, markdown, styles, and `docs/` files with a document extension); everything else ≥ R2 | Auth or crypto code outside conventional paths (rule 2) |
| R3 paths (crypto, keys, prod infra, migrations including alembic, prisma and flyway, IaC) | Compliance relevance (rule 5) |
| Any non-`human` change to auth, authz, permissions, crypto, session, oauth, jwt, password, login, middleware, rbac, acl, iam, policies or security paths → R3 | AI-infrastructure dependencies (rule 6); user-facing behavior outside an approved design (rule 7) |
| Size: > 500 lines across > 5 files → every commit R3 (R2 with the Steward's mechanical-refactor waiver); binaries count 100 lines each | A change that failed a check before passing (rule 14); "three R1 changes to one module in 24 hours" (G-LOOP) |
| Merge commits, on their conflict resolutions | Product code placed under a test path (see Documented limits) |
| Every commit has valid provenance and a level; agents can't add human-approval markers (the enforcement scripts, their tests and this README are not scanned for markers, since they must name them; every other file is) | Whether the declared `Generated-By` is truthful (see Documented limits) |

Neither layer replaces review. A loop that **can't** modify its verifier can still write code that games a weak one. That is what the B-Team and Primum are for.
