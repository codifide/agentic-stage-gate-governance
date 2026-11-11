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
- Guard resolved `..` before symlinks (`src/link/../check.py`), judged the target of a symlink instead of its own name (deleting `verifiers/link.py`), ignored a hard link whose other name lives outside the repo, allowed a recursive delete of an ancestor of a protected directory, and dropped any string with an interior newline. Symlinks are now resolved component by component and every candidate is checked three ways; interior-newline and NUL-truncated strings and JSON object keys are checked too.
- CI immutable check: a workflow or other enforcement-path edit was not reported unless the list named it; a symlink to another symlink (or through a directory symlink) escaped the one-hop check. The tree is now followed across any number of hops.
- Review-level check: a root commit (orphan history merged in) was never checked (`git diff-tree --root`).
- License check: nested CycloneDX components were skipped; partial parser output was accepted; an SPDX package with no license line was dropped; `MIT WITH` with no exception id was accepted.
- Iteration 3 review (gpt-6.1-sol), all with regression tests: a symlink into `.codifide/` was waived by the verifier approval (now classified by its target); a symlink target differing only in case from a directory symlink escaped the CI check; NFD spellings of a protected NFC file name passed the guard; a hard link to a newline-named protected file passed (find output was newline-split); license entries were joined without parentheses (`MIT OR GPL` AND `GPL` passed); a `License` value on a later csv row was dropped as a header; an SPDX `Concluded` license was ignored after `Declared`; a merge resolved with `--ours` had an empty combined diff and so an R1 floor; an approval marker inside a file containing a NUL byte was not scanned; the example workflow had the license step commented out.
- Iteration 4 review (gpt-6.1-sol), all with regression tests: a relative path was resolved against the repository root, not the hook's working directory (`check.py` from `verifiers/` passed), so relative paths are now judged against the root, the hook cwd and the payload cwd, and the hook metadata `cwd` is no longer treated as a write target; `CODIFIDE_ROOT` could point the guard at a decoy list, so a root that is not the real top level now blocks; an NFD alias of a protected NFC name passed the CI check on git that does not precompose, so non-ASCII changed paths are matched in both forms; a plain-list license row with a missing license was dropped, so it is now a malformed report (exit 2) and SPDX tag-value lines are no longer read as list rows.
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
