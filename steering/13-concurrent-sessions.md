---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Concurrent Sessions — Running Multiple Agents on One Codebase Without a Mess

Most work is a single session, and this file should be invisible then. It applies **only when two or more agent sessions run against the same repository at the same time.** If you are working solo, ignore everything here — it adds zero ceremony to single-session work by design.

The harness is single-writer by default. Concurrency breaks it at exactly two points: the **working tree** (two sessions editing the same files clobber each other) and the **session-state handoff** (two sessions overwriting the same file lose each other's notes). This file fixes both, plus an optional integration check for teams that have a test suite.

The guiding principle is the same scale-adaptive rule used at the gates: **pay for coordination only when the work demands it.** Two mechanisms carry ~90% of the benefit. Everything heavier is deferred until collisions actually happen despite them.

---

## Mechanism 1: Worktree-per-session (isolation)

This is the foundation. Each concurrent session gets its own git worktree — a separate working directory and branch that shares the one `.git` object store. Two sessions physically cannot overwrite each other's files, because they are editing different directories.

### Setup

```bash
# From the main repo, create an isolated worktree + branch per session:
git worktree add ../<repo>-worktrees/<session-id> -b session/<session-id>

# The agent session works entirely inside that directory.
# When done and merged, remove it:
git worktree remove ../<repo>-worktrees/<session-id>
git branch -d session/<session-id>
```

### What is shared vs. isolated

| Component | Shared or isolated | Implication |
|---|---|---|
| `.git/objects` (history) | Shared | Stored once; space-efficient |
| Branch refs | Shared | All sessions see each other's branches |
| Working directory files | **Isolated** | Each session edits independently — no clobber |
| Staging index | **Isolated** | Each session stages independently |
| `HEAD` | **Isolated** | Each session tracks its own branch |

### The part teams forget: external state is NOT isolated

Worktrees isolate files, not the world around them. Each concurrent session must also get its own:

- **Ports** — two dev servers on `:3000` collide. Assign per-session ports.
- **Database / schema** — use a scratch DB or a per-session schema namespace, never the shared one.
- **Caches, build output, temp dirs** — scope them per worktree.

If external state isn't separated, worktrees give you a false sense of safety — the files won't clobber but the running processes will.

### Serialize git metadata operations

Concurrent `git commit` / `fetch` / `pull` / `gc` across worktrees can corrupt shared `.git` metadata. These operations must be serialized — one session's metadata op completes before another's begins. Editing, building, and testing run freely in parallel; only the git metadata writes serialize.

---

## Mechanism 2: Sharded session state (no more clobbered handoffs)

The single `next-session-prompt.md` is a shared mutable file. Two sessions both read it at start and both overwrite it at Stop — last writer wins, the other session's handoff is silently lost. The fix is one file per session plus a read-mostly index.

### Model

```
.kiro/steering/
├── next-session-prompt.md          # read-mostly INDEX — links active session files;
│                                   # the canonical handoff when only one session is active
└── sessions/
    ├── <session-id-A>.md           # Session A writes only this
    └── <session-id-B>.md           # Session B writes only this
```

- **At Stop:** each session writes its own `sessions/<session-id>.md`. No contention — no two sessions write the same file.
- **At SessionStart:** a session reads `next-session-prompt.md` (the index) *and* any sibling files in `sessions/` so it can see what concurrent sessions are doing.
- **Integration:** one designated **integrator** session (or the human) consolidates the per-session files back into `next-session-prompt.md` when the parallel work merges, then clears the consumed session files.

Solo work is unaffected: a single session can keep writing `next-session-prompt.md` directly. The `sessions/` directory only comes into play when more than one session is live.

See `templates/HOOKS-SESSION-STATE.md` for the updated Stop and SessionStart hook definitions.

---

## Mechanism 3 (CONDITIONAL): Integration-level verification

**Adopt this only if you have a test suite worth running.** Without one, it is theater — skip it and rely on sequential human-reviewed merges.

The failure mode it addresses is real and subtle: **each branch passes its own tests, but the merged result is broken.** One session changes an interface or invariant another session still relies on. Per-session G-LOOP passing is necessary but not sufficient — green-alone does not mean green-together.

If you have tests, add one G-LOOP check that runs the suite against the **merged state of the combined branches**, not just each branch in isolation:

1. Merge session branches one at a time into an integration branch (dependency order if known).
2. After each merge, run the full suite against the integration branch.
3. A clean textual merge is **not** a pass — git detects textual conflicts, not semantic ones (an interface-drift or timezone-class bug compiles, lints, and passes isolated tests). The integration suite is what catches it.
4. Only promote to `main` after the integration suite is green.

This is the step that earns the word "confidently." It is the difference between hoping two sessions composed cleanly and verifying it.

---

## What we deliberately do NOT do (yet)

These are real techniques from larger multi-agent systems. They are **fleet-scale machinery** — adopt them only when you are regularly running enough concurrent sessions that collisions happen *despite* worktrees. For a one-person operation running a handful of sessions, they are overhead without matching payoff.

| Deferred technique | Adopt when |
|---|---|
| Proactive scope partitioning (declare disjoint scopes + merge-order graph up front) | Collisions recur despite worktrees, or 4+ concurrent sessions are routine |
| Merge queue with speculative testing + batching + bisect | Churn is high enough that serial merges are the bottleneck |
| Test-health classification (flaky vs. real regression before retry) | Flaky tests are causing loops to waste cycles |

---

## Quick reference

**Running one session?** Ignore this file.

**Running two or more?**
1. `git worktree add` per session — isolated dir + branch.
2. Give each session its own ports / scratch DB / caches.
3. Serialize git metadata ops (commit/fetch/pull/gc).
4. Each session writes its own `sessions/<id>.md` at Stop; integrator consolidates on merge.
5. If you have tests: merge branches one at a time and run the suite against the merged state before promoting to `main`.

That is the whole capability. Worktrees make a mess structurally impossible; sharded state makes handoffs lossless; the integration check (if you have tests) makes "no mess" verified rather than hoped.

---

*Part of Agentic Stage-Gate-Loop Governance — the SGL Harness. Activates only under concurrent sessions.*
