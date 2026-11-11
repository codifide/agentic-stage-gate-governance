# Hook files

Real, copyable hook files. Copy what you use; nothing here is installed for you.

| File | Host | Type | Effect |
|---|---|---|---|
| `kiro/load-session-state.json` | Kiro | advisory | loads the core, reads the handoff as data |
| `kiro/update-session-state.json` | Kiro | advisory | persists a handoff |
| `kiro/screenshot-data-guard.json` | Kiro | advisory | reminder only |
| `kiro/guard-immutable-paths.json` | Kiro | **blocking** | runs `.codifide/guard-immutable-paths.sh` before file-write tools |
| `claude-code/settings.example.json` | Claude Code | **blocking** | same guard, on `Write`, `Edit`, `MultiEdit`, `NotebookEdit` |

Copy Kiro files to `.kiro/hooks/`. Merge the Claude Code example into `.claude/settings.json` (do not overwrite an existing file).

Both blocking hooks run `bash <guard> || exit 2`, so a missing `bash` or a crash blocks the write instead of allowing it. The hook only works if the host treats exit code 2 from a PreToolUse command as a block. That is documented for Claude Code. For Kiro it is `[UNVERIFIED]` by us: test it (see `templates/enforcement/README.md`, "Check that your hook blocks").

Cursor, Copilot, Windsurf and Codex also have hook mechanisms. We do not ship hook files for them, because we have not tested them. On those tools the CI check is your only blocking control; see the coverage table in `templates/enforcement/README.md`.

The guard needs `bash`, `git`, and `jq` or `python3`. On Windows use WSL or Git Bash.
