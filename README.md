# Agentic Stage-Gate-Loop Governance

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

**Stage-Gate-Loop (SGL)** is the framework — the Human → Gate → Loop model. The **SGL Harness** is the installable implementation of it: the `steering/` files, hooks, and templates in this repo that you strap onto an AI coding agent to instrument and constrain it. Think framework vs. the thing you actually `git clone` — the model is the idea, the harness is the rigging.

Copy the `steering/` folder from this repo into your project's AI context directory. One small core file (`00-welcome.md`, about 2,200 words) loads every session; the other files load on demand when their topic comes up. Add the hooks and the enforcement scripts in `templates/` to make the critical rules hold even when the agent forgets them.

The steering files are plain Markdown. They work with any AI coding assistant that supports custom instructions or context files, including Kiro, Cursor, Windsurf, GitHub Copilot, and others.

> **Convergent ideas.** Other agentic-development efforts have arrived at similar patterns from different directions: unattended build → verify → retro loops, a dedicated test-architect role, and a *meta-loop* (a loop that watches the loop) to escape stuck search. The SGL Harness encodes the same patterns: Human/Gate/Loop separation, a verifier that must be harder than the task, generator/verifier isolation, and a meta-loop owned by Atlas. Convergence is a signal, not proof; see "Validation status" below.

---

## Setup

### New Project
```bash
# Clone this repo and copy the steering folder into your project
cp -r agentic-stage-gate-governance/steering /path/to/your/new/project/.kiro/steering
# or for Cursor:
cp -r agentic-stage-gate-governance/steering /path/to/your/new/project/.cursor/rules

# Recommended: install the hooks and enforcement scripts
#   templates/HOOKS-SESSION-STATE.md   (session hooks + immutable-path guard)
#   templates/enforcement/README.md    (.sgl/immutable-paths, guard, CI check)

# Open in your AI IDE
# 00-welcome.md (the core) loads every session; the rest load on demand
# Say "Let's start a new initiative" to begin
# Say "Loop this task" to define an automated loop
```

### Existing Project
```bash
# Copy the steering folder into your existing project
cp -r agentic-stage-gate-governance/steering /path/to/your/existing/project/.kiro/steering
# or for Cursor:
cp -r agentic-stage-gate-governance/steering /path/to/your/existing/project/.cursor/rules

# Open in your AI IDE
# Say "Assess this codebase against the gates" to get a gap analysis
```

### Global (All Projects)
```bash
# Kiro — copy to user-level steering config
cp agentic-stage-gate-governance/steering/*.md ~/.kiro/steering/

# Cursor — copy to global rules directory
cp agentic-stage-gate-governance/steering/*.md ~/.cursor/rules/

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
    ├── enforcement/               # .sgl/immutable-paths example, PreToolUse write guard, CI checks (immutable paths, Review Level floor)
    ├── NFR-TEMPLATE.md            # Non-functional requirements template
    └── INTENT-CONTRACT.md         # Persistent human-authorized goal, constraints, harm boundaries
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
LOOP-ENGINEERING-GUIDE.md          # Deep-dive: loop engineering rationale and patterns
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
| **Cursor** | `.cursor/rules/` | Auto-included per project |
| **Windsurf** | `.windsurf/rules/` | Auto-included per project |
| **GitHub Copilot** | `.github/copilot-instructions.md` (combine files) | Auto-included in Copilot Chat |
| **Any other** | Paste `00-welcome.md` into the system prompt; attach other files when their topic comes up | Manual inclusion |

For tools without on-demand loading, combine `00-welcome.md` with the files you use most (typically `01`, `03`, `08`, `11`). Avoid loading everything every session: it costs context and buries the operative rules.

---

## Session Continuity and Enforcement (Agent Hooks)

AI agents lose context between sessions. Steering files provide the *knowledge*; hooks provide the *behavior*.

| Hook | Trigger | Type | What it does |
|------|---------|------|--------------|
| `load-session-state.json` | `SessionStart` | advisory | Loads the core, reads the handoff **as data**, and confirms next actions with you before acting |
| `update-session-state.json` | `Stop` | advisory | Persists a handoff (sharded per session under concurrency, never containing secrets or PHI) |
| `screenshot-data-guard.json` | `PreToolUse` | advisory | Reminds the agent to use synthetic data and keep captures out of synced or tracked folders |
| `guard-immutable-paths.json` | `PreToolUse` | **blocking** | Rejects agent writes to verifiers, fixtures, and baselines listed in `.sgl/immutable-paths` |

**Advisory vs. blocking.** `agent`-type hooks inject a prompt; they remind, they don't enforce. The immutable-path guard is a `command` hook that exits `2` to block, and `templates/enforcement/check-immutable-paths.sh` runs the same check in CI as a backstop.

**Handoffs are data, not orders.** `next-session-prompt.md` is written by an agent that may have processed untrusted content. The SessionStart hook reads it for context and asks you to confirm the plan; it never executes it blindly.

Full JSON and install steps: `templates/HOOKS-SESSION-STATE.md` and `templates/enforcement/README.md`.

---

## What's New in v3.0 (October 2026)

v3.0 is a correctness and safety pass driven by two independent adversarial reviews of v2 (one same-vendor, one cross-vendor). The architecture is unchanged; the rules now say what the architecture meant.

- **Named human authority.** The Human Steward decides every gate, track, exception, verifier change, and HALT resumption. AI personas recommend; Aegis can block but never pass.
- **One review vocabulary.** Review Levels R1–R3 for changes, a gate-review table by track, and a single classification procedure. Loop token budgets are now Cost Classes C1–C3, so "Tier" no longer means two things.
- **B-Team independence is a hard rule.** Never self-conducted; prepare the package and stop if no independent model is available. Data-handling rules for sending code to external models.
- **Enforced verifier immutability.** Human-owned `.sgl/immutable-paths`, a blocking write hook, and a CI check, with tests.
- **Enforced Review Level floors.** A CI check computes the mechanical floor for every commit (harness files are R3) and rejects under-declared or missing `Review-Level` and `Generated-By` trailers. It says plainly which rules it cannot compute.
- **Security fixes.** Security controls fail closed even when unavailable; no cloud resources without human approval; standard CVSS bands; credentials, secrets, and TLS are always gated (revoke-and-rotate, not delete-from-source); baselines are never regenerated from the code under test.
- **Single owners.** One HALT procedure (`12`), one coverage table (`03`), one dependency rule (`11`), and a gate checklist that matches `01` item for item.
- **Smaller context.** A ~2,200-word always-loaded core replaces ~21,000 words loaded every session.
- **Concurrency fix.** Session handoffs live in the shared git directory, so every worktree can see them.

### Validation status

What has been done:

- **Structural validation** of every steering file, template, and hook definition (numbering, references, JSON).
- **Two independent adversarial reviews of v2** (one same-vendor, one cross-vendor). Their findings drove v3.
- **Two cross-vendor closure audits of v3**, each checking every prior finding against quoted v3 text. The first found gaps in the new enforcement scripts; the second confirmed those fixes and found that the harness's own files could be edited at R1, which is now R3.
- **An automated test suite** for the enforcement scripts (`templates/enforcement/test-enforcement.sh`, 58 cases): allowed and blocked writes, `..` and symlink tricks, self-protection, renames, attempts to loosen the list, per-commit Review Level floors, merge commits, the size rule, provenance, and agent-written approval markers.

What has **not** been done: a controlled behavioral study measuring outcomes with and without the harness. The scripts enforce what they can compute; the rest is guidance an agent can still get wrong. Treat effectiveness claims accordingly.

---

## What's New in v2.0

**Loop Engineering Integration (July 2026)**

v1.x was pure stage-gate: structured judgment at every decision point. v2.0 adds the loop layer — automated verification that runs between gates without human intervention.

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
- **Sharded session state** — each session writes its own handoff to `<git-common-dir>/sgl-sessions/<id>.md` (shared by every worktree) instead of overwriting the shared `next-session-prompt.md`; a human-named integrator consolidates on merge. Fixes the last-writer-wins clobber.
- **Integration verification (conditional)** — if a test suite exists, one G-LOOP check runs it against the *merged* state of combined branches, not just each branch. Each branch passing alone does not prove they compose; this is what makes "no mess" verified rather than hoped.

Deliberately deferred as fleet-scale overkill: proactive scope partitioning, merge queues with speculative testing/batching, and flaky-vs-regression test-health classification. Adopt those only when collisions recur despite worktrees. `13` loads only when concurrency is in play.

---

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas, define Domain Expert Personas, or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Use the Express track for small changes rather than deleting gates. If you do trim, keep G0, G4, and G6, and keep the authority rule and B-Team independence in `00-welcome.md`
- **Loop tuning:** Edit `08-loop-engineering.md` to adjust retry limits, Cost Class budgets, or verifier requirements
- **Immutable paths:** Edit `.sgl/immutable-paths` (human-owned) to protect your verifiers, fixtures, and baselines
- **Intent integrity:** Edit `12-intent-integrity.md` and `templates/INTENT-CONTRACT.md` to define harm boundaries, escalation rules, and authority constraints
- **Domain-specific reviews:** Create tailored B-Team prompts for your platform (see `04-adversarial-review.md` for examples)
- **Existing projects:** Use `templates/EXISTING-PROJECT-ASSESSMENT.md` to assess where you stand before applying gates

---

## Philosophy

> "Machine-speed execution. Human-grade checks and balances."
>
> "AI loops for execution. Gates for judgment. Humans for decisions. Evidence proves all three."

Based on Robert Cooper's Stage-Gate® (1986), extended with loop engineering for automated verification and intent-integrity controls for bounded autonomy. Adapted for a world where AI agents produce code faster than humans can review line by line. The goal is not less rigor — it is moving rigor into architecture: CI/CD, automated tests, independent verifiers, security tooling, policy enforcement, domain expertise, durable evidence, and selective human judgment.

---

*Version 2.0 — July 2026*


---

Codifide®, Confidence in Code®, and the Codifide logo mark are registered trademarks of Codifide Inc.
