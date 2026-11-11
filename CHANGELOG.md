# Changelog

Versions follow semantic versioning. The version is in `VERSION`. Pin installs to a tag.

## [3.1.0] - 2026-11-11

Security and distribution hardening of the enforcement layer. Driven by a read-only assessment and a Grok 4.7 cold adversarial review; every finding is either fixed with a regression test or stated as a documented limit in `templates/enforcement/README.md`.

### Changed (behaviour you may notice)
- `check-immutable-paths.sh`: the verifier approval (`CODIFIDE_VERIFIER_CHANGE_APPROVED_BY`) no longer waives edits to `.codifide/`, `.github/workflows/`, `CODEOWNERS`, `.kiro/hooks/` or `.claude/settings.json`. Those need `CODIFIDE_ENFORCER_CHANGE_APPROVED_BY`.
- `check-licenses.sh`: reads the policy from the base branch (`--base REF`, `CODIFIDE_BASE`, or `origin/main`). Falls back to the working tree with a warning only when no base ref exists and none was requested. Pass `--base` in CI. CycloneDX entries with several licenses are read as AND. `OR` now means either side may be chosen.
- `check-review-level.sh`: `docs/` files are R1 only with a document extension; binary files count 100 lines each toward the size rule; more migration, schema, Terraform, session, oauth, jwt, password, login, middleware, rbac, acl, iam and policy paths raise the floor; matching is case-insensitive.
- Guard: empty input and an unreadable list now block.

### Fixed
- Guard allowed a case variant of a protected path (`Verifiers/check.py`) on case-insensitive filesystems.
- Guard dropped any string of 1,024 characters or more, so a long `a/../` path reached a protected file.
- Guard dropped a path ending in a newline.
- Guard did not resolve hard links to protected files.
- Any unexpected guard exit code other than 2 was a possible "allow"; an EXIT trap now converts it to 2, and the hook files run `bash <guard> || exit 2`.
- CI check missed protected paths with non-ASCII or newline characters in the name (git quotes them), a file named like a protected directory, case variants, and symlinks added into protected paths.
- License check: policy came from the PR's own tree; `*` in a license expression expanded to file names; a policy line of `*` allowed everything; `MIT License` and similar names were rejected; `A OR B` was treated as AND; SPDX tag-value expressions were truncated to the first word.
- Review-level check: wrong file names for git-quoted paths; R1 allowlist accepted code under `docs/`.
- Stale text: the case count, the gate count in CONTRIBUTING and the whitepaper, the old version footer, a counsel marker in CONTRIBUTING and NOTICE, unqualified coverage and timing claims in the whitepaper and an article.

### Added
- `templates/hooks/` real hook files (Kiro x4, Claude Code guard).
- `templates/cursor/to-mdc.sh` Cursor `.mdc` converter (Cursor ignores plain `.md` rules).
- `templates/enforcement/workflow.example.yml` complete workflow: trusted base copies, first-run bootstrap, push tripwire, two scoped labels.
- `VERSION`, `CHANGELOG.md`, `.gitattributes` (LF endings), SPDX headers on scripts.
- Documented limits and compensating controls; Windows/WSL and `jq`/`python3` prerequisites.
- Regression tests for each fix, and documentation-consistency tests.

## [3.0.0] - 2026-10

Correctness and safety pass (named human authority, Review Levels, small always-loaded core, enforcement scripts). See the README, "What's New in v3.0".
