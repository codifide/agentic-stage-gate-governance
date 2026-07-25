# Agentic Stage-Gate-Loop Governance

**Loop the mechanical. Gate the judgment. Ship with confidence.**

A ready-to-use governance system for AI-assisted software development that combines stage-gates (structured human judgment) with loop engineering (automated verification). Three layers, one coherent model.

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
- **Gate Layer:** AI personas evaluate whether the approach is sound. Adversarial review ensures nothing slips through. 30 minutes.
- **Loop Layer:** Mechanical execution with automated verification. Runs continuously — or overnight. No human intervention needed, but results are logged and observable.

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
    └── 08-loop-engineering.md             # Loop engineering: verifiers, state, cost control
templates/
    ├── B-TEAM-REVIEW-PACKAGE.md   # Copy-paste template for B-Team reviews
    ├── GATE-EVIDENCE-CHECKLIST.md # Per-gate artifact tracking with binary states
    └── EXISTING-PROJECT-ASSESSMENT.md  # Full assessment document structure
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
LOOP-ENGINEERING-GUIDE.md          # Deep-dive: loop engineering rationale and patterns
```

---

## How It Works

1. **Steering files** are loaded into your AI assistant's context (automatically or manually, depending on your IDE)
2. The AI reads them and follows the governance process
3. When you say "start a new initiative," it walks you through G0
4. When you say "loop this task," it designs an automated verification loop
5. When you say "review this," it invokes the appropriate personas
6. Gate decisions are always yours — the AI provides evidence, you decide
7. Between gates, loops run continuously to verify consistency, run tests, and catch drift

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

## What's New in v2.0

**Loop Engineering Integration (July 2026)**

v1.x was pure stage-gate: structured judgment at every decision point. v2.0 adds the loop layer — automated verification that runs between gates without human intervention.

What changed:
- **New steering file** (`08-loop-engineering.md`) — practical instructions for when to loop, how to design verifiers, and cost control
- **Loop-eligible tasks per gate** — each gate now identifies what can be automated vs. what requires judgment
- **G-LOOP concept** — between gates, automated loops run continuously to verify consistency, run tests, and catch drift
- **New personas** — Atlas (Loop Systems Engineer) and Iris (Developer Experience) ensure loops are well-designed and don't kill velocity
- **Three-layer architecture** — Human → Gate → Loop, each task at its correct altitude

The insight: most teams put everything in one layer. Either everything needs human approval (slow) or everything runs autonomously (dangerous). The three-layer model lets each task find its correct altitude.

---

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Remove gates you don't need (but keep G0, G4, and G6 at minimum)
- **Loop tuning:** Edit `08-loop-engineering.md` to adjust retry limits, cost tiers, or verifier requirements
- **Domain-specific reviews:** Create tailored B-Team prompts for your platform (see `04-adversarial-review.md` for examples)
- **Existing projects:** Use `templates/EXISTING-PROJECT-ASSESSMENT.md` to assess where you stand before applying gates

---

## Philosophy

> "AI loops for execution. Gates for judgment. Humans for decisions. Evidence proves all three."

Based on Robert Cooper's Stage-Gate® (1986), extended with loop engineering for automated verification. Adapted for a world where AI agents produce code faster than humans can review it. The gates ensure that speed doesn't compromise safety. The loops ensure that mechanical tasks don't bottleneck on human availability.

---

*Version 2.0 — July 2026*
