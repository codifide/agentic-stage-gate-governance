# Enforcement — Making the Critical Rules Hold

Two harness rules matter too much to leave to prose: **a loop may never edit what judges it**, and **a change may never be reviewed below its Review Level**. These scripts enforce them. They fail closed: if they can't decide (bad input, missing base ref, git error), they block. The one deliberate exception is a repo that has not adopted `.codifide/immutable-paths` yet; set `CODIFIDE_REQUIRE_IMMUTABLE_LIST=1` once it has, and a missing list blocks too.

| File | What it does | Where it goes |
|------|--------------|---------------|
| `immutable-paths.example` | The human-owned list of protected paths | Copy to `<repo>/.codifide/immutable-paths` and edit |
| `guard-immutable-paths.sh` | Blocks agent write tools from touching protected paths (exit 2). Resolves `..`, `.`, directory symlinks, and symlinked files before matching. Supports `!exception` lines (e.g., the handoff file inside `.kiro/steering/`). | `<repo>/.codifide/`, registered as a PreToolUse command hook |
| `check-immutable-paths.sh` | Fails CI if a PR's diff touches protected paths (list read from the base branch), unless the Human Steward approved it | CI, every PR |
| `check-review-level.sh` | Per commit (merges on their conflict resolutions): requires valid `Generated-By` and `Review-Level` trailers, computes the floor from the files that commit touches (harness files are R3), rejects under-declaration and agent-written approval markers (the enforcement scripts, their tests and this README are not scanned for markers, since they must name them; every other file is). If the PR trips the size rule, every commit must meet it. | CI, every PR |
| `check-licenses.sh` | Fails CI if a dependency's license is not on `.codifide/allowed-licenses` (or can't be determined). Reads an SBOM / license report on stdin: CycloneDX, SPDX, or `name,license` CSV/TSV. Keeps copyleft out of a proprietary repo. | CI, every PR |
| `allowed-licenses.example` | The license allow-list (copy to `.codifide/allowed-licenses`). Two postures: permissive-OSS and proprietary. | — |
| `test-enforcement.sh` | 70-case test suite for the four scripts, run against throwaway repos | Run locally or in CI after editing any script |

## Install

```bash
mkdir -p .codifide
cp templates/enforcement/immutable-paths.example .codifide/immutable-paths
cp templates/enforcement/{guard-immutable-paths,check-immutable-paths,check-review-level}.sh .codifide/
chmod +x .codifide/*.sh
# Edit .codifide/immutable-paths and commit it on main.
bash templates/enforcement/test-enforcement.sh   # expect: RESULT ... ALL PASS
```

Register the guard as a hook: `templates/HOOKS-SESSION-STATE.md`, Hook 4.

## CI (GitHub Actions example)

Run the checks **from the base branch**, not from the PR. Otherwise a PR can edit the check that judges it.

```yaml
name: codifide-enforcement
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened, labeled, unlabeled]
jobs:
  codifide:
    runs-on: ubuntu-latest
    env:
      CODIFIDE_REQUIRE_IMMUTABLE_LIST: "1"
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Load Codifide checks from the base branch
        run: |
          mkdir -p "$RUNNER_TEMP/codifide"
          for f in check-immutable-paths.sh check-review-level.sh; do
            git show "origin/${{ github.base_ref }}:.codifide/$f" > "$RUNNER_TEMP/codifide/$f"
          done
      - name: Immutable paths
        env:
          # Records the label, not the PR author; who may apply it is governed below.
          CODIFIDE_VERIFIER_CHANGE_APPROVED_BY: ${{ contains(github.event.pull_request.labels.*.name, 'codifide-verifier-change-approved') && 'label:codifide-verifier-change-approved' || '' }}
        run: bash "$RUNNER_TEMP/codifide/check-immutable-paths.sh" "origin/${{ github.base_ref }}"
      - name: Review level + provenance
        env:
          CODIFIDE_WAIVE: ${{ contains(github.event.pull_request.labels.*.name, 'codifide-mechanical-refactor') && 'size' || '' }}
          CODIFIDE_STEWARD: ${{ contains(github.event.pull_request.labels.*.name, 'codifide-mechanical-refactor') && 'label:codifide-mechanical-refactor' || '' }}
        run: bash "$RUNNER_TEMP/codifide/check-review-level.sh" "origin/${{ github.base_ref }}"
```

**Make the approval human-only.** A label is only as trustworthy as who can apply it. Pair this with:

- a `CODEOWNERS` entry making the Human Steward the required reviewer for `.codifide/`, `.kiro/`, `.github/workflows/`, `CODEOWNERS` itself, and every path in `.codifide/immutable-paths`;
- branch protection requiring CODEOWNERS review and these checks to pass;
- label permissions restricted to the Steward, or replace the labels with a GitHub environment that requires the Steward's approval.

Agent identities must never hold those permissions.

## What each layer covers

| Write path | Guard hook | CI check |
|------------|------------|----------|
| Agent file tools (write, edit, append, delete, move, rename) | Blocks | Catches |
| Shell commands (`sed -i`, `mv`, redirects) | Not inspected | Catches |
| Edits to `.codifide/immutable-paths` itself | Blocks | Catches (list is read from base) |

## What the review-level check can and cannot compute

| Computed (enforced) | Not computable (reviewers and the Steward apply them, and can only raise) |
|---------------------|----------------------------------------------------------------------------|
| Harness files (`.kiro/`, `.codifide/`, `steering/`, CI workflows, CODEOWNERS) → R3; handoff file exempt | New architectural pattern, service, or integration (rule 3) |
| R1 only for the allowlist (tests, docs, styles); everything else ≥ R2 | Auth or crypto code outside conventional paths (rule 2) |
| R3 paths (crypto, keys, prod infra, migrations, IaC) | Compliance relevance (rule 5) |
| Any non-`human` change to auth/authz/permissions/crypto paths → R3 | AI-infrastructure dependencies (rule 6); user-facing behavior outside an approved design (rule 7) |
| Size: > 500 lines across > 5 files → every commit R3 (R2 with the Steward's mechanical-refactor waiver) | A change that failed a check before passing (rule 14); "three R1 changes to one module in 24 hours" (G-LOOP) |
| Merge commits, on their conflict resolutions | Product code placed under a test or docs path (path convention; CODEOWNERS and review catch it) |
| Every commit has valid provenance and a level; agents can't add human-approval markers | Whether the declared `Generated-By` is truthful (quarterly audit, `03`) |

Neither layer replaces review. A loop that **can't** modify its verifier can still write code that games a weak one. That is what the B-Team and Primum are for.
