# Codifide Harness
*Codifide Harness: agentic governance for AI-assisted software development. Codifide Swarm is the private commercial product.*


**Loop the mechanical. Gate the judgment. Ship with confidence.**

A ready-to-use governance system for AI-assisted software development that combines stage-gates (structured human judgment) with loop engineering (automated verification). It recreates the **checks and balances of a mature software organization inside an agentic execution environment**.

> **📖 Documentation & Research:**
> - [Agentic SDLC Governance](https://www.codifide.com/governance-whitepaper) — full framework specification
> - [Loop Engineering: A Pragmatic Guide](https://www.codifide.com/loop-engineering) — production lessons from agentic loops
> - [AI Security Changed in 90 Days](https://www.codifide.com/ai-security-threats) — why traditional SDLC security breaks
> - [About the Author](https://www.codifide.com/douglas-jones) — Douglas Jones, Codifide

---

## The Three-Layer Model

```
                ┌─────────────────────────────────────┐
                │          HUMAN LAYER                 │
                │  Goals · Decisions · Gate Approvals  │
                └──────────────────┬──────────────────┘
                                   │ defines
                ┌──────────────────▼──────────────────┐
                │          GATE LAYER                  │
                │  Personas · Adversarial Review       │
                │  Compliance · Architecture           │
                └──────────────────┬──────────────────┘
                                   │ governs
                ┌──────────────────▼──────────────────┐
                │          LOOP LAYER                  │
                │  Build · Test · Deploy · Verify      │
                │  ETL · Migration · Optimization      │
                └─────────────────────────────────────┘
```

- **Human Layer:** You define what success looks like and make go/kill/hold decisions. 5 minutes.
- **Gate Layer:** AI personas evaluate whether the approach is sound. Independent challenge, domain expertise, intent integrity, security, compliance, and architecture live here.
- **Loop Layer:** Mechanical execution with automated verification. Runs continuously — or overnight. No human intervention needed while it remains inside its Intent Contract; results are logged and observable.

---

## What This Is

**Codifide Harness** is both the framework and the free, MIT-licensed harness that implements it. The framework (the Codifide Harness framework) is the Human → Gate → Loop model. The harness (the harness files) is the installable part: the `steering/` files, hooks, and templates in this repo that you strap onto an AI coding agent to instrument and constrain it. Think framework vs. the thing you actually `git clone` — the model is the idea, the harness is the rigging. It is based on Robert G. Cooper's Stage-Gate® model (see the attribution at the end of this file and in [NOTICE.md](NOTICE.md)).

Codifide Swarm, a commercial multi-agent product built on this harness, is separate, private, and in development. The Codifide Harness governs one agent; Codifide Swarm governs a swarm of agents.

Copy the `steering/` folder from this repo into your project's AI context directory. One small core file (`00-welcome.md`, about 2,200 words) loads every session; the other files load on demand when their topic comes up. Add the hooks and the enforcement scripts in `templates/` to make the critical rules hold even when the agent forgets them.

The steering files are plain Markdown, so the rules text works with any AI coding assistant that reads custom instructions or context files. **Blocking enforcement is a separate layer** and is host-specific: a guard hook for Kiro and Claude Code (`templates/hooks/`), and CI checks for any host (`templates/enforcement/`). Where a tool has neither, the harness is guidance only. See the table under "IDE-Specific Context Loading" and "Documented limits" in `templates/enforcement/README.md`.

Version: see `VERSION` and `CHANGELOG.md`. Pin to a tagged release rather than copying from the default branch.

> **Scope of this (free, MIT) harness vs. the commercial product.** This open harness governs **one agent working one codebase** — gates, personas, review levels, the Intent Contract, HALT, and the enforcement layer. Codifide also builds a **commercial product on top of it** that governs a **coordinated swarm of agents** modernizing many entities in parallel (portfolio-scale decomposition, frozen seam contracts, per-lane verifiers, merged-state integration verification, connectors). If you need governed multi-agent delivery at portfolio scale — e.g. consolidating acquired entities onto one platform — reach out to Codifide. This repo stays free and MIT.

> **Related work.** Other efforts address overlapping problems. Examples: the [Bilevel Autoresearch](https://arxiv.org/abs/2603.23420) paper (Qu and Lu, arXiv:2603.23420) describes an outer loop that improves an inner loop's search strategy, reported on one benchmark built on [karpathy/autoresearch](https://github.com/karpathy/autoresearch); that repository itself is a single-file experiment loop with a fixed time budget and a keep/discard ledger, and contains no meta-loop. Codifide Harness includes a comparable bounded meta-loop owned by Atlas (`08`). We do not claim these were derived independently or are equivalent, and similarity between projects is a signal, not proof; see "Scope and limits" and "Validation status" below. See [NOTICE.md](NOTICE.md) for sources and licences.

> **Acknowledgements.** This work builds on Robert G. Cooper's Stage-Gate® model and learned from Karpathy's autoresearch, the BMAD Method, Bilevel Autoresearch (Qu and Lu), published research on parallel coding agents, Mergify's writing on merge queues, and Claude Code's worktree guidance. GitHub Spec Kit was reviewed for comparison only. Ideas only: no text or code was copied. The full list, with links, what each source contributed, and licences, is in [NOTICE.md](NOTICE.md) section 2.

---

## Setup

### Install with `install.sh` (recommended)

Download a release from the Releases page, check it against `SHA256SUMS`, unpack it, and run the installer from the unpacked tree (or from a clean checkout of the release tag). There is no one-line network install, on purpose: you should see which bytes enter your repository.

```bash
# 1. Dry run (the default): prints the plan and writes nothing
bash codifide-harness-3.2.0/install.sh --target /path/to/your/repo --host kiro
# 2. Write it
bash codifide-harness-3.2.0/install.sh --target /path/to/your/repo --host kiro --apply
# Hosts: kiro | claude | cursor | copilot | codex (repeat or comma-separate)
```

What it does: copies the steering files for your host (Cursor gets `.mdc` rules made by `templates/cursor/to-mdc.sh`), the four enforcement scripts into `.codifide/`, and starter policy files; records `.codifide/harness-version` and a hash manifest. What it will not do: use the network, commit or push, touch git configuration, or overwrite a file you own (`.codifide/immutable-paths`, `allowed-licenses`, your workflow, `CLAUDE.md`, `AGENTS.md`, the Copilot file; it prints a snippet to merge instead). It never writes `.claude/settings.json`; it prints the hook block to merge. It refuses to run from anything but a tagged release unless you pass `--i-know-this-is-unpinned`.

```bash
bash NEW-RELEASE/install.sh upgrade   --target /path/to/your/repo          # dry run: shows the diff
bash NEW-RELEASE/install.sh upgrade   --target /path/to/your/repo --apply
bash NEW-RELEASE/install.sh uninstall --target /path/to/your/repo --apply   # removes only unmodified files it installed
```

Upgrade replaces only files that still match the manifest and stops, writing nothing, if you edited one (`--force` overrides). Then open a normal pull request so your reviewers see the diff. Edit `.codifide/immutable-paths` and `.codifide/allowed-licenses` and set `CODIFIDE_LICENSE_REPORT_CMD` before relying on the checks.

**Verified and not verified.** The installer suite (`tests/test-installer.sh`, 367 installer checks) exercises the installer in throwaway repositories on macOS with bash 3.2. We did not run Kiro, Claude Code, Cursor, Copilot or Codex end to end: that each host loads the files, and that the guard hook blocks on exit code 2 in each host, is unverified (see `templates/enforcement/README.md`). The release workflow has not run on GitHub yet, and releases are unsigned until a signing key is configured.

The manual copy steps below still work.

### New Project
```bash
# Clone this repo and copy the steering folder into your project
cp -r codifide-harness/steering /path/to/your/new/project/.kiro/steering
# or for Cursor (Cursor ignores plain .md rules; convert to .mdc first, see the table below):
bash codifide-harness/templates/cursor/to-mdc.sh /path/to/your/new/project/.cursor/rules

# Recommended: install the hooks and enforcement scripts
#   templates/hooks/                   (real hook files: Kiro, Claude Code)
#   templates/HOOKS-SESSION-STATE.md   (what each hook does)
#   templates/enforcement/README.md    (.codifide/immutable-paths, guard, CI checks, documented limits)

# Open in your AI IDE
# 00-welcome.md (the core) loads every session; the rest load on demand
# Say "Let's start a new initiative" to begin
# Say "Loop this task" to define an automated loop
```

### Existing Project
```bash
# Copy the steering folder into your existing project
cp -r codifide-harness/steering /path/to/your/existing/project/.kiro/steering
# or for Cursor:
bash codifide-harness/templates/cursor/to-mdc.sh /path/to/your/existing/project/.cursor/rules

# Open in your AI IDE
# Say "Assess this codebase against the gates" to get a gap analysis
```

### Global (All Projects)
```bash
# Kiro — copy to user-level steering config
cp codifide-harness/steering/*.md ~/.kiro/steering/

# Cursor — global rules are set in Cursor's settings, not a folder; use the per-project .mdc files above

# Now every project you open gets the governance system
```

---

## What's Included

```
steering/
    ├── 00-welcome.md              # THE CORE (always loaded): authority, gates, review levels, loop + security rules, on-demand index
    ├── 01-governance-gates.md     # Full criteria for the six gates (G0, G1, G2/G3, G4, G5, G6) + tracks
    ├── 02-personas.md             # A-Team + B-Team + Loop personas
    ├── 03-coding-standards.md     # Coverage, security, accessibility, CI/CD
    ├── 04-adversarial-review.md   # B-Team review protocol + A-Team response format
    ├── 05-nfr-kpi-mandate.md      # Measurable targets requirement
    ├── 06-existing-project-assessment.md  # How to assess projects that already have code
    ├── 07-auto-research-protocol.md       # Autonomous solution iteration system
    ├── 08-loop-engineering.md             # Loop engineering: verifiers, state, meta-loop, cost control
    ├── 09-security-remediation-sla.md     # Security finding remediation timelines
    ├── 10-supply-chain-verification.md    # Dependency provenance + supply-chain checks
    ├── 11-tiered-adversarial-review.md    # Review Levels R1–R3 for individual changes
    ├── 12-intent-integrity.md             # Intent Contracts, Do No Harm, Primum circuit breaker
    └── 13-concurrent-sessions.md          # Multiple agents on one repo: worktrees + sharded state
templates/
    ├── B-TEAM-REVIEW-PACKAGE.md   # Copy-paste template for B-Team reviews
    ├── CODE-REVIEW-PROMPT-QWEN.md # Forensic code review prompt for reasoning models (ChatML-aware)
    ├── CODE-REVIEW-PROMPT-CLAUDE.md # Same forensic prompt formatted for Anthropic models (when Claude didn't build it)
    ├── GATE-EVIDENCE-CHECKLIST.md  # Per-gate artifact tracking with binary states
    ├── EXISTING-PROJECT-ASSESSMENT.md  # Full assessment document structure
    ├── HOOKS-SESSION-STATE.md     # Session hooks (core load, handoff-as-data) + blocking immutable-path guard
    ├── enforcement/               # .codifide/immutable-paths example, write guard, CI checks (immutable paths, Review Level floor, licenses), example workflow, test suite
    ├── hooks/                     # Real hook files: kiro/ (4) and claude-code/ (guard)
    ├── cursor/to-mdc.sh           # Converts steering/*.md to Cursor .mdc rules (alwaysApply for the core)
    ├── CORE-RULES-ALWAYS-ON.md    # Short project-level rules file kept in context every session (advisory unless backed by CI/hooks)
    ├── CROSS-TEAM-REVIEW-PROTOCOL.md  # Periodic independent review of the persona definitions themselves
    ├── DOMAIN-EXPERT-PERSONA.md   # Template for a Domain Expert Persona with binding expert corrections
    ├── TEAM-CHANNEL-BROADCAST.md  # Advisory per-prompt hook that reminds the agent to persist lessons to files
    ├── NFR-TEMPLATE.md            # Non-functional requirements template
    └── INTENT-CONTRACT.md         # Persistent human-authorized goal, constraints, harm boundaries
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
LOOP-ENGINEERING-GUIDE.md          # Deep-dive: loop engineering rationale and patterns
VERSION, CHANGELOG.md              # Release version and change history
.gitattributes                     # Forces LF endings on scripts and hook files
```

**Reviewer independence:** adversarial review always runs in a separate context, on a different model family from the builder when one is available, and is never role-played by the builder. If no independent model is reachable, the agent prepares the review package and stops. No model family is the designated "final gate"; pick any capable reasoning model from a different family than the one that wrote the code.

---

## How It Works

1. **The core** (`00-welcome.md`) is loaded every session; other steering files load when their topic comes up
2. The AI reads them and follows the governance process
3. When you say "start a new initiative," it walks you through G0
4. When you say "loop this task," it designs an automated verification loop
5. When you say "run a B-Team review," it prepares a redacted review package for an independent model, and stops until you bring the findings back
6. Gate decisions are always yours (the Human Steward). AI personas recommend and can block for missing evidence; they never approve
7. Between gates, loops run continuously to verify consistency, run tests, and catch drift
8. Primum continuously checks loop behavior against the human-approved Intent Contract
9. Quill observes G0–G6 and preserves the initiative's decisions, failures, evidence, and lessons

### Auto-Research Mode

Say `"Auto-research: [problem statement]"` to trigger autonomous solution iteration:
- AI generates multiple solution approaches
- Implements and tests each approach
- Uses adversarial review to find weaknesses
- Iteratively refines until optimal solution found
- Presents evidence-backed recommendation

Example: `"Auto-research: Build a rate limiter that handles 100k requests/second"`

### Loop Mode

Say `"Loop this task"` or `"Define a loop: [task]"` to create an automated execution loop:
- AI designs a verifier (automated gate that isn't the agent grading its own work)
- Defines state management (persisted to disk, not context)
- Sets stop conditions and cost limits
- Runs autonomously until the verifier passes or retry limit is hit

Example: `"Define a loop: Run the full regression suite and verify report output against the golden fixtures"`

### IDE-Specific Context Loading

| IDE | Where to put the files | How they load |
|-----|------------------------|---------------|
| **Kiro** | `.kiro/steering/` or `~/.kiro/steering/` | `00-welcome.md` is `inclusion: always` (every session). The rest are `inclusion: auto` with a `name` and `description`, which Kiro loads on demand when the request matches the description. If you want them only on explicit request, change them to `inclusion: manual` |
| **Cursor** | `.cursor/rules/*.mdc`, made by `templates/cursor/to-mdc.sh` (plain `.md` files are ignored by Cursor) | The core becomes `alwaysApply: true`. The rest become agent-requested rules (`alwaysApply: false` with a description). Based on Cursor's rules documentation; we have not run Cursor against it |
| **Claude Code** | Put `00-welcome.md` where your project CLAUDE.md can import it (for example `@.claude/steering/00-welcome.md`), and the rest beside it | The core loads with your CLAUDE.md; load the others by name when needed. Guard hook: `templates/hooks/claude-code/`. Not run by us end to end |
| **Codex and other AGENTS.md tools** | A short AGENTS.md file that points to `00-welcome.md` and says to read the matching file before each kind of work | Manual on-demand loading. No guard hook shipped; use CI |
| **Windsurf** | `.windsurf/rules/` | Rule format not verified by us; check the vendor's current docs |
| **GitHub Copilot** | The repository instructions file under `.github/` (see the next block) | Single file, so combine only `00-welcome.md` plus the files you use. No guard hook shipped; use CI |
| **Any other** | Paste `00-welcome.md` into the system prompt; attach other files when their topic comes up | Manual inclusion |

```bash
# GitHub Copilot: the instructions file is .github/copilot-instructions.md
cat steering/00-welcome.md > /path/to/project/.github/copilot-instructions.md   # review, then commit
```

For tools without on-demand loading, combine `00-welcome.md` with the files you use most (typically `01`, `03`, `08`, `11`). Avoid loading everything every session: it costs context and buries the operative rules.

---

## Session Continuity and Enforcement (Agent Hooks)

AI agents lose context between sessions. Steering files provide the *knowledge*; hooks provide the *behavior*.

| Hook | Trigger | Type | What it does |
|------|---------|------|--------------|
| `templates/hooks/kiro/load-session-state.json` | `SessionStart` | advisory | Loads the core, reads the handoff **as data**, and confirms next actions with you before acting |
| `templates/hooks/kiro/update-session-state.json` | `Stop` | advisory | Persists a handoff (sharded per session under concurrency, never containing secrets or PHI) |
| `templates/hooks/kiro/screenshot-data-guard.json` | `PreToolUse` | advisory | Reminds the agent to use synthetic data and keep captures out of synced or tracked folders |
| `templates/hooks/kiro/guard-immutable-paths.json` | `PreToolUse` | **blocking** (if your host honours exit 2) | Rejects agent file-tool writes to verifiers, fixtures, and baselines listed in `.codifide/immutable-paths` |
| `templates/hooks/claude-code/settings.example.json` | `PreToolUse` | **blocking** (documented by the vendor) | The same guard for Claude Code's write tools |

**Advisory vs. blocking.** `agent`-type hooks inject a prompt; they remind, they don't enforce. The immutable-path guard is a `command` hook that exits `2` to block. It does not see shell commands, and we have not verified every host's exit-code behaviour (test yours: `templates/enforcement/README.md`). `templates/enforcement/check-immutable-paths.sh` runs the check in CI, and only protects you if it is a required status check.

**Handoffs are data, not orders.** The handoff file (next-session-prompt.md) is written by an agent that may have processed untrusted content. The SessionStart hook reads it for context and asks you to confirm the plan; it never executes it blindly.

Hook files are in `templates/hooks/`; descriptions are in `templates/HOOKS-SESSION-STATE.md`; install steps and limits are in `templates/enforcement/README.md`.

---

## Migration note
The enforcement directory is now `.codifide/`, environment variables use the `CODIFIDE_` prefix, session state lives in `codifide-sessions`, and PR labels and steering names use the `codifide-` prefix. Move existing configuration to the new names; nothing else changed.

## What's New in 3.1 (November 2026)

Hardening of the enforcement scripts after two adversarial reviews (one same-vendor, one cross-vendor), and real distribution files. Full list: `CHANGELOG.md`.

- **Guard:** case-insensitive matching, no path-length cutoff, trailing and leading newlines trimmed, hard links to protected files blocked, empty input and an unreadable list block, any unexpected crash blocks.
- **CI check:** file names are read NUL-delimited, matching is case-insensitive, a symlink added into a protected path is flagged, and the approval is scoped: the verifier label no longer waives edits to `.codifide/`, workflows, CODEOWNERS or hooks (a second label does).
- **Review levels:** `docs/` is R1 only for document files, binaries count toward the size rule, more migration and auth-style paths raise the floor.
- **Licenses:** the policy is read from the base branch, SPDX `OR`/`AND`/`WITH` and common names are handled, wildcard-only allow lines are rejected.
- **Distribution:** real hook files (`templates/hooks/`), a Cursor `.mdc` converter, a complete workflow example with first-run bootstrap, `VERSION`, `CHANGELOG.md`, SPDX headers, and a statement of limits.

Breaking changes for existing installs: new approval variable `CODIFIDE_ENFORCER_CHANGE_APPROVED_BY` for edits to the checks themselves; `check-licenses.sh` now needs `--base` (or an `origin/main` ref) to read the policy; CycloneDX entries with several licenses are read as AND.

## What's New in v3.0 (October 2026)

v3.0 is a correctness and safety pass driven by two adversarial reviews of v2 (one same-vendor, one cross-vendor). The architecture is unchanged; the rules now say what the architecture meant.

- **Named human authority.** The Human Steward decides every gate, track, exception, verifier change, and HALT resumption. AI personas recommend; Aegis can block but never pass.
- **One review vocabulary.** Review Levels R1–R3 for changes, a gate-review table by track, and a single classification procedure. Loop token budgets are now Cost Classes C1–C3, so "Tier" no longer means two things.
- **B-Team independence is a hard rule.** Never self-conducted; prepare the package and stop if no independent model is available. Data-handling rules for sending code to external models.
- **Verifier immutability, enforced for file-tool writes and in CI.** Human-owned `.codifide/immutable-paths`, a blocking write hook (not applicable to shell commands), and a CI check, with tests.
- **Review Level floors computed from paths.** A CI check computes the mechanical floor for every commit (harness files are R3) and rejects under-declared or missing `Review-Level` and `Generated-By` trailers. It cannot tell whether those trailers are true, and it says plainly which rules it cannot compute.
- **Security fixes.** Security controls fail closed even when unavailable; no cloud resources without human approval; standard CVSS bands; credentials, secrets, and TLS are always gated (revoke-and-rotate, not delete-from-source); baselines are never regenerated from the code under test.
- **Single owners.** One HALT procedure (`12`), one coverage table (`03`), one dependency rule (`11`), and a gate checklist that matches `01` item for item.
- **Smaller context.** A ~2,200-word always-loaded core replaces ~21,000 words loaded every session.
- **Concurrency fix.** Session handoffs live in the shared git directory, so every worktree can see them.

### Scope and limits
- **The local write guard is a seatbelt, not a gate.** It catches accidental and simple agent file-tool writes. The controls that actually gate a change are the CI checks run from the **base** branch plus GitHub branch protection, CODEOWNERS and label permissions, which **you** must configure (see `templates/enforcement/README.md`, "What you must configure"). Without a required status check on the protected branch the CI scripts are advisory.
- **Defense in depth, not a proof.** Each fresh adversarial review of these scripts has found new edge cases (five rounds: 12, 10, 4, 8 and 8 bypasses, all fixed or documented, each with a regression test). The latest fixes have not been re-reviewed. Expect that another review would find more, and treat the scripts as one layer.

- This is a governance harness for AI coding agents. It is not a compliance certification, and it does not replace legal, security, regulatory, or clinical review.
- Using it does not make a system HIPAA, SOC 2, or ISO compliant. Those determinations belong to qualified people and auditors.
- It reduces specific risks through written rules and four tested scripts (`templates/enforcement/`: `guard-immutable-paths.sh`, `check-immutable-paths.sh`, `check-review-level.sh`, `check-licenses.sh`). Everything else is guidance an agent can still get wrong. Known limits that scripts cannot close are in the table below and, in full, under "Documented limits" in `templates/enforcement/README.md`. See "Session Continuity and Enforcement (Agent Hooks)" for which hooks are advisory and which block.

| Limit | Compensating control (yours to configure) |
|---|---|
| Shell commands are not seen by the write guard (`printf x >> verifiers/check.py`) | CI check as a required status check; deny shell writes to protected paths in the agent's permissions; sandbox the agent |
| `Generated-By` is self-asserted; `Review-Level: R3` is a declaration, not evidence that a review happened | Signed commits, a separate bot identity for agents, CODEOWNERS review, the Steward reads the review package |
| Path floors are a convention (`tests/` and `*.test.*` are trusted as tests) | CODEOWNERS on production directories; review |
| Approval labels and variables are only as strong as who can set them; the workflow file can be edited by the PR it judges | Label permissions, CODEOWNERS, branch protection, an organization required workflow |
| An absolute-target symlink is not followed by the CI check | Review absolute-target symlinks; keep protected data out of the agent's OS reach |
| A non-ASCII file name needs `python3` for the Unicode-alias check; without it the CI check reports the path (fail closed) and the guard falls back to an inode comparison | Install `python3` |
| Text-encoded approval markers (UTF-16, base64 in a data file) are not recognised | CODEOWNERS and review on data files |
| The guard over-blocks some harmless strings (`.`, a directory holding a protected path) and blocks hard-link writes when part of the repo is unreadable | Choose other arguments; fix the permissions (fail-closed direction) |
| How a host treats exit 2 and `inclusion: auto` is untested here | Run "Check that your hook blocks" in your environment |

- Host-runtime behaviours marked `[UNVERIFIED]` in the templates (for example how a tool loads `inclusion: auto` files, or whether a hook event fires) have not been verified and vary by tool.
- The software and documents are provided as is, without warranty; see [LICENSE](LICENSE).
- See also [NOTICE.md](NOTICE.md) (acknowledgements, trademarks, AI-assisted authorship) and [SECURITY.md](SECURITY.md) (reporting a vulnerability).

### Validation status

What has been done:

- **Structural validation** of every steering file, template, and hook definition (numbering, references, JSON).
- **Two adversarial reviews of v2** (one same-vendor, one cross-vendor). Their findings drove v3.
- **Two cross-vendor closure audits of v3**, each checking every prior finding against quoted v3 text. The first found gaps in the new enforcement scripts; the second confirmed those fixes and found that the harness's own files could be edited at R1, which is now R3.
- **An automated test suite** for the enforcement scripts (`templates/enforcement/test-enforcement.sh`, 245 cases; the script prints the authoritative result and checks that this number matches): allowed and blocked writes, `..` and symlink and hard-link tricks, case variants, very long and newline paths, self-protection, renames, attempts to loosen the list, scoped approvals, per-commit Review Level floors, merge commits, the size rule (including binaries), provenance, agent-written approval markers, license expressions and base-branch policy, hook and converter files, and documentation consistency. Cases marked "documented limit" pin behaviour we know cannot be fixed in a script.
- **Two further cross-vendor reviews of the enforcement scripts** (a read-only assessment and a Grok 4.7 cold review). Their findings are what 3.1 fixes, or states as limits.

What has **not** been done: a controlled behavioral study measuring outcomes with and without the harness. The scripts enforce what they can compute; the rest is guidance an agent can still get wrong. Treat effectiveness claims accordingly.

---

## Loop Engineering Integration (July 2026)

The first release was pure stage-gate: structured judgment at every decision point. The second added the loop layer — automated verification that runs between gates without human intervention.

What changed:
- **New steering file** (`08-loop-engineering.md`) — practical instructions for when to loop, how to design verifiers, and cost control
- **Session continuity hooks** — templates for SessionStart/Stop hooks (revised in v3.0: core-only load, handoff-as-data)
- **Loop-eligible tasks per gate** — each gate now identifies what can be automated vs. what requires judgment
- **G-LOOP concept** — between gates, automated loops run continuously to verify consistency, run tests, and catch drift
- **New personas** — Atlas (Loop Systems Engineer) and Iris (Developer Experience) ensure loops are well-designed and don't kill velocity
- **Three-layer architecture** — Human → Gate → Loop, each task at its correct altitude

The insight: most teams put everything in one layer. Either everything needs human approval (slow) or everything runs autonomously (dangerous). The three-layer model lets each task find its correct altitude.

### Intent Integrity Extension

As agentic implementation velocity increases, human line-by-line review becomes a bottleneck and eventually an inadequate primary control. The framework therefore treats human-authorized intent as persistent system state.

- **Primum (Intent Integrity / Do No Harm)** monitors goal drift, scope expansion, metric gaming, collateral impact, irreversible actions, verifier manipulation, and privilege expansion.
- **Intent Contracts** define goals, protected constraints, non-goals, harm boundaries, escalation conditions, success evidence, reversibility, and authority boundaries.
- **Circuit breakers** halt autonomous work when behavior leaves authorized intent.
- **Domain Expert Personas** scale access to scarce subject-matter expertise without pretending to replace the human expert.
- **Quill** operates as an embedded journalist across the entire lifecycle — recording decisions, failures, and organizational memory with structural independence from the builders.

The objective is not to make humans review machine-speed output faster. It is to move repeatable assurance into CI/CD, automated testing, policy enforcement, independent verification, and continuous evidence — while preserving human judgment for consequential decisions.

### Concurrent Sessions

The harness was single-writer by default — good for one session at a time, messy when several ran against the same repository. `13-concurrent-sessions.md` adds a deliberately right-sized capability: not fleet-scale coordination machinery, just the two mechanisms that carry most of the benefit.

- **Worktree-per-session** — each concurrent session gets its own git worktree (isolated working directory + branch, shared object store), plus per-session external state (ports, scratch DB, caches). Two sessions physically cannot clobber each other's files.
- **Sharded session state** — each session writes its own handoff to `<git-common-dir>/codifide-sessions/<id>.md` (shared by every worktree) instead of overwriting the shared handoff file (next-session-prompt.md); a human-named integrator consolidates on merge. Fixes the last-writer-wins clobber.
- **Integration verification (conditional)** — if a test suite exists, one G-LOOP check runs it against the *merged* state of combined branches, not just each branch. Each branch passing alone does not prove they compose; this checks composition for the tests you have, which is stronger than hoping branches compose.

Deliberately deferred as fleet-scale overkill: proactive scope partitioning, merge queues with speculative testing/batching, and flaky-vs-regression test-health classification. Adopt those only when collisions recur despite worktrees. `13` loads only when concurrency is in play.

---

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas, define Domain Expert Personas, or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Use the Express track for small changes rather than deleting gates. If you do trim, keep G0, G4, and G6, and keep the authority rule and B-Team independence in `00-welcome.md`
- **Loop tuning:** Edit `08-loop-engineering.md` to adjust retry limits, Cost Class budgets, or verifier requirements
- **Immutable paths:** Edit `.codifide/immutable-paths` (human-owned) to protect your verifiers, fixtures, and baselines
- **Intent integrity:** Edit `12-intent-integrity.md` and `templates/INTENT-CONTRACT.md` to define harm boundaries, escalation rules, and authority constraints
- **Domain-specific reviews:** Create tailored B-Team prompts for your platform (see `04-adversarial-review.md` for examples)
- **Existing projects:** Use `templates/EXISTING-PROJECT-ASSESSMENT.md` to assess where you stand before applying gates

---

## Philosophy

> "Machine-speed execution. Human-grade checks and balances."
>
> "AI loops for execution. Gates for judgment. Humans for decisions. Evidence proves all three."

Based on Robert G. Cooper's Stage-Gate® model (Stage-Gate® is a registered trademark of Stage-Gate International and of R.G. Cooper & Associates; Codifide is not affiliated with or endorsed by them; see [NOTICE.md](NOTICE.md)), extended with loop engineering for automated verification and intent-integrity controls for bounded autonomy. Adapted for a world where AI agents produce code faster than humans can review line by line. The goal is not less rigor — it is moving rigor into architecture: CI/CD, automated tests, independent verifiers, security tooling, policy enforcement, domain expertise, durable evidence, and selective human judgment.

---

*Codifide Harness 3.1.0 — November 2026. See `CHANGELOG.md`.*


---

Codifide®, Confidence in Code®, and the Codifide logo mark are registered trademarks of Codifide Inc.
