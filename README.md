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

Copy the `steering/` folder from this repo into your project's AI context directory. The governance system activates automatically — personas, gates, loops, standards, and review processes are all baked in.

The steering files are plain Markdown. They work with any AI coding assistant that supports custom instructions or context files, including Kiro, Cursor, Windsurf, GitHub Copilot, and others.

---

## Setup

### New Project
```bash
# Clone this repo and copy the steering folder into your project
cp -r agentic-stage-gate-governance/steering /path/to/your/new/project/.kiro/steering
# or for Cursor:
cp -r agentic-stage-gate-governance/steering /path/to/your/new/project/.cursor/rules

# Open in your AI IDE
# The steering files activate automatically
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
    ├── 00-welcome.md              # Splash screen — guides developer through gates and loops
    ├── 01-governance-gates.md     # The 7-gate process (G0–G6) + loop integration
    ├── 02-personas.md             # A-Team + B-Team + Loop personas
    ├── 03-coding-standards.md     # Coverage, security, accessibility, CI/CD
    ├── 04-adversarial-review.md   # B-Team review protocol + A-Team response format
    ├── 05-nfr-kpi-mandate.md      # Measurable targets requirement
    ├── 06-existing-project-assessment.md  # How to assess projects that already have code
    ├── 07-auto-research-protocol.md       # Autonomous solution iteration system
    ├── 08-loop-engineering.md             # Loop engineering: verifiers, state, cost control
    └── 12-intent-integrity.md             # Intent Contracts, Do No Harm, Primum circuit breaker
templates/
    ├── B-TEAM-REVIEW-PACKAGE.md   # Copy-paste template for B-Team reviews
    ├── CODE-REVIEW-PROMPT-QWEN.md # Forensic code review prompt for reasoning models (bounded pass)
    ├── CODE-REVIEW-PROMPT-CLAUDE.md # Adversarial gate review prompt for Claude (final pass — a miss ships)
    ├── GATE-EVIDENCE-CHECKLIST.md  # Per-gate artifact tracking with binary states
    ├── EXISTING-PROJECT-ASSESSMENT.md  # Full assessment document structure
    ├── HOOKS-SESSION-STATE.md     # Agent hooks for session continuity + PHI guards
    ├── NFR-TEMPLATE.md            # Non-functional requirements template
    └── INTENT-CONTRACT.md         # Persistent human-authorized goal, constraints, harm boundaries
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
LOOP-ENGINEERING-GUIDE.md          # Deep-dive: loop engineering rationale and patterns
```

**Three-model review slot assignment:** The framework prescribes adversarial review from a model that did not build the code. In practice, this means two review passes with different assignments: local/reasoning models (Qwen3, o3, DeepSeek-R1) handle the high-volume bounded pass — every PR, every module, every iteration. Claude handles the adversarial gate pass — the final review before code ships, where a miss reaches production. The bounded pass catches 80% at low cost; the gate pass catches the 20% that would otherwise ship.

---

## How It Works

1. **Steering files** are loaded into your AI assistant's context (automatically or manually, depending on your IDE)
2. The AI reads them and follows the governance process
3. When you say "start a new initiative," it walks you through G0
4. When you say "loop this task," it designs an automated verification loop
5. When you say "review this," it invokes the appropriate personas
6. Gate decisions are always yours — the AI provides evidence, you decide
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

Example: `"Define a loop: Run all 199 measure engines and verify scorecard consistency"`

### IDE-Specific Context Loading

| IDE | Where to put the files | How they load |
|-----|------------------------|---------------|
| **Kiro** | `.kiro/steering/` or `~/.kiro/steering/` | Auto-included in every conversation |
| **Cursor** | `.cursor/rules/` | Auto-included per project |
| **Windsurf** | `.windsurf/rules/` | Auto-included per project |
| **GitHub Copilot** | `.github/copilot-instructions.md` (combine files) | Auto-included in Copilot Chat |
| **Any other** | Paste into system prompt or custom instructions | Manual inclusion |

---

## Session Continuity (Agent Hooks)

AI agents lose all context between sessions. Steering files provide the *knowledge*, but hooks provide the *behavior* — ensuring the agent loads that knowledge every time without being told.

### The Problem

Without hooks, every new session starts cold. The agent might:
- Skip steering files (or load only a subset)
- Forget what was accomplished in the prior session
- Lose track of environment state, running services, or active backlog

### The Solution: Two Hooks

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `load-session-state.json` | `SessionStart` | Lists the steering directory and loads EVERY file — no hardcoded subset |
| `update-session-state.json` | `Stop` | Reminds the agent to update `next-session-prompt.md` with session state |

**Key principle: Don't hardcode file lists.** The hook says "list the directory and load everything." This means new steering files added between sessions are automatically picked up — no hook maintenance required.

### Setup (Kiro)

```bash
mkdir -p .kiro/hooks
# Copy from templates/HOOKS-SESSION-STATE.md or create directly:
```

**`.kiro/hooks/load-session-state.json`**
```json
{
  "version": "v1",
  "hooks": [{
    "name": "Load all steering files on session start",
    "trigger": "SessionStart",
    "action": {
      "type": "agent",
      "prompt": "MANDATORY: Before doing ANYTHING else, you MUST list the directory <PROJECT>/.kiro/steering/ and then read EVERY .md file in it using read_files (batch them as needed). Do NOT skip any files — they are ALL institutional memory and ground truth. Start with next-session-prompt.md to understand current state, then load every remaining file. After all steering files are loaded, act on the next-session-prompt immediately."
    }
  }]
}
```

**`.kiro/hooks/update-session-state.json`**
```json
{
  "version": "v1",
  "hooks": [{
    "name": "Update next-session-prompt on session end",
    "trigger": "Stop",
    "action": {
      "type": "agent",
      "prompt": "Before this session ends, you MUST update .kiro/steering/next-session-prompt.md with: 1) What was accomplished this session, 2) Current initiative/gate status, 3) Immediate next actions for the following session, 4) Any key metrics or environment state changes. This is the institutional memory handoff — future sessions depend on it."
    }
  }]
}
```

See `templates/HOOKS-SESSION-STATE.md` for the full reference including PHI guards and custom hook design patterns.

---

## What's New in v2.0

**Loop Engineering Integration (July 2026)**

v1.x was pure stage-gate: structured judgment at every decision point. v2.0 adds the loop layer — automated verification that runs between gates without human intervention.

What changed:
- **New steering file** (`08-loop-engineering.md`) — practical instructions for when to loop, how to design verifiers, and cost control
- **Session continuity hooks** — templates for SessionStart/Stop hooks that ensure full context loading every session
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
- **Quill** operates as an embedded journalist / organizational historian across the entire lifecycle, preserving how and why the system evolved.

The objective is not to make humans review machine-speed output faster. It is to move repeatable assurance into CI/CD, automated testing, policy enforcement, independent verification, and continuous evidence — while preserving human judgment for consequential decisions.

---

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas, define Domain Expert Personas, or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Remove gates you don't need (but keep G0, G4, and G6 at minimum)
- **Loop tuning:** Edit `08-loop-engineering.md` to adjust retry limits, cost tiers, or verifier requirements
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
