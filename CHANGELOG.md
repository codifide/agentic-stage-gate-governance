# Changelog

Versions follow semantic versioning. The version is in `VERSION`. Pin installs to a tag.

## [3.2.0] - 2026-11-11
A local installer, an upgrade and an uninstall path, and release automation. The steering files, the hook files and the four enforcement scripts are unchanged from 3.1.0; this release adds the way to get them into a repository and to keep them current.
### Added
- `install.sh`: copies a pinned release into a repository. Dry run by default (`--apply` writes). Per-host targets: `kiro`, `claude`, `cursor`, `copilot`, `codex`. Refuses to run unless it is a clean checkout of the tag that matches `VERSION`, or an unpacked release tarball whose `RELEASE` file names that tag (`--i-know-this-is-unpinned` overrides and is recorded). Writes `.codifide/harness-version` and `.codifide/harness-manifest` (a hash for every file it installed). Uses no network, makes no commit, and does not change git configuration.
- Policy files are never overwritten: `.codifide/immutable-paths`, `.codifide/allowed-licenses`, the enforcement workflow, `CLAUDE.md`, `AGENTS.md` and the Copilot instructions file are created only when absent, and a merge snippet is printed when they exist. `.claude/settings.json` is never written; the snippet is printed.
- `install.sh upgrade`: re-run from a newer tag. Shows a diff, replaces only files that still match the manifest, stops (writing nothing) on a locally edited harness file unless `--force`, and removes files the new release no longer ships if you have not edited them.
- `install.sh uninstall`: manifest-driven; removes only files that still match the recorded hash, leaves everything else, and prunes directories it emptied.
- Every path (from the release and from the manifest in your repository) is checked before any write: relative, from a fixed allow-list, no symbolic link on the way. A write failure rolls back everything the run wrote.
- `tools/build-release.sh` and `.github/workflows/release.yml`: build the tarball (`git archive` of the tag plus a `RELEASE` file) and `SHA256SUMS` on a pushed `v*` tag, run both test suites first, sign `SHA256SUMS` only if a `RELEASE_SIGNING_KEY` secret exists, and create a DRAFT release. The workflow uses no third-party actions and no `pull_request` triggers.
- `tests/test-installer.sh`: the installer suite (see the README for the count).
### Verification status (stated plainly)
- Verified by the installer suite, in throwaway repositories on macOS with bash 3.2: dry run writes nothing, the pin rules, each host's file layout, no-clobber, manifest hashes, idempotent re-run, upgrade, uninstall (a pristine tree is restored byte for byte), path-traversal, symlink and hostile-manifest cases, no network client or git write is called, rollback after a failed write, and the release build and an install from the built tarball.
- NOT verified end to end: any host actually loading what the installer wrote. Kiro `inclusion: auto` loading and exit-2 blocking, Claude Code reading `CLAUDE.md` and the merged hook, Cursor loading the `.mdc` rules, Copilot reading its instructions file, and Codex reading `AGENTS.md` were not run. The Cursor output is checked against the converter, not against Cursor.
- The release workflow ran once on GitHub for 3.2.0: both suites, the build and the checksum passed; the release step failed (see below). No release has been signed; the 3.1.0 release is unsigned and this one stays unsigned until a signing key is configured.
- A cross-vendor review (gpt-6.1-sol) of the installer found 3 major and 5 minor reproducible issues; all are fixed with regression tests: a forged manifest line can no longer make a policy or stub file deletable, a failed backup stops and rolls back, a hand-written `RELEASE` file no longer vouches for a dirty git checkout, files are re-checked just before each write, the temporary file is created with `mktemp` and verified, release files are not read through links, and the release workflow scopes the signing key and token to their steps and removes the key file on failure. The fixes themselves have not been re-reviewed.
- Release: the release workflow's final step failed on its first run (`gh release create` had no git remote because the workflow checks out without a remote); the 3.2.0 assets were built locally from the tag with `tools/build-release.sh`. Fixed after the tag by passing `--repo`.
### Not built (by decision)
Host plugins, a Kiro Power, an MCP server, a VS Code extension, npm or pip packages, `curl | bash`, auto-update, telemetry, a composite Action.
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
- Iteration 5 review (gpt-6.1-sol), all with regression tests: the guard honoured `GIT_DIR`/`GIT_WORK_TREE`, so a decoy work tree chose the list that was read (all `GIT_*` variables are now dropped); a delete of `/` was allowed (an ancestor of the repository is now blocked); a payload `cwd` such as `src/link/..` was normalised before the symlink was resolved; `docs/CODEOWNERS` was not an enforcer path; `.claude/`, `.cursor/` and `.codex/` agent settings could be changed at R2 (now governance, R3); CycloneDX `metadata.component.components` was not scanned; a plain-list row with an empty package name was dropped; a plain row mixed into an SPDX tag-value report was ignored (now exit 2).
- Iteration 6 (a bounded fix pass after the fifth gpt-6.1-sol review; these fixes are not re-reviewed), all with regression tests: the three CI scripts now drop every `GIT_*` variable, so `GIT_DIR`/`GIT_WORK_TREE` cannot point them at a decoy repository; a symlink target or file name ending in a newline lost the newline in `$(...)` (guard and CI), so such a link bypassed a protected `*?` pattern (results now travel in variables, `readlink -n`, sentinel for decoded values); the CI symlink traversal now folds NFC/NFD spellings of a path component (fail closed without `python3`); the guard's hard-link and directory scans block when `find` cannot read part of the repository; an SPDX `<text>` comment could overwrite a `PackageLicenseConcluded`/`Declared` value; CycloneDX nested `components` that is not an array was silently skipped (now exit 2); a symlink named `.codifide`, `.kiro`, `.claude`, `.cursor`, `.codex` or `.github` only got R2 (the directory entries themselves are now R3); the `workflow_ok` documentation test matched words anywhere (comments included) and now requires `run:` steps that execute each script.
- Stale text: the case count, the gate count in CONTRIBUTING and the whitepaper, the old version footer, a counsel marker in CONTRIBUTING and NOTICE, unqualified coverage and timing claims in the whitepaper and an article.

### Added
- `templates/hooks/` real hook files (Kiro x4, Claude Code guard).
- `templates/cursor/to-mdc.sh` Cursor `.mdc` converter (Cursor ignores plain `.md` rules).
- `templates/enforcement/workflow.example.yml` complete workflow: trusted base copies, first-run bootstrap, push tripwire, two scoped labels.
- `VERSION`, `CHANGELOG.md`, `.gitattributes` (LF endings), SPDX headers on scripts.
- Documented limits and compensating controls; Windows/WSL and `jq`/`python3` prerequisites.
- Regression tests for each fix (245 cases), and documentation-consistency tests.
- README "Scope and limits": the guard is a seatbelt, the base-branch CI checks plus branch protection are the gate, one table of documented limits, and a statement that the scripts are defense in depth, not a proof.

## [3.0.0] - 2026-10

Correctness and safety pass (named human authority, Review Levels, small always-loaded core, enforcement scripts). See the README, "What's New in v3.0".
