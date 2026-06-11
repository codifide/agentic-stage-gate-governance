# Agentic AI Project Template — Stage-Gate Governance

A ready-to-use project template for AI-assisted software development with built-in governance, adversarial review, and quality gates.

## What This Is

Copy the `steering/` folder from this repo into your project's AI context directory. The governance system activates automatically — personas, gates, standards, and review processes are all baked in.

The steering files are plain Markdown. They work with any AI coding assistant that supports custom instructions or context files, including Kiro, Cursor, Windsurf, GitHub Copilot, and others.

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

## What's Included

```
steering/
    ├── 00-welcome.md              # Splash screen — guides developer through gates
    ├── 01-governance-gates.md     # The 7-gate process (G0–G6)
    ├── 02-personas.md             # A-Team + B-Team + Zero-Context persona definitions
    ├── 03-coding-standards.md     # Coverage, security, accessibility, CI/CD
    ├── 04-adversarial-review.md   # B-Team review protocol + A-Team response format
    ├── 05-nfr-kpi-mandate.md      # Measurable targets requirement
    ├── 06-existing-project-assessment.md  # How to assess projects that already have code
    └── 07-auto-research-protocol.md       # Autonomous solution iteration system
templates/
    ├── B-TEAM-REVIEW-PACKAGE.md   # Copy-paste template for B-Team reviews
    ├── GATE-EVIDENCE-CHECKLIST.md # Per-gate artifact tracking with binary states
    └── EXISTING-PROJECT-ASSESSMENT.md  # Full assessment document structure
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
```

## How It Works

1. **Steering files** are loaded into your AI assistant's context (automatically or manually, depending on your IDE)
2. The AI reads them and follows the governance process
3. When you say "start a new initiative," it walks you through G0
4. When you say "review this," it invokes the appropriate personas
5. Gate decisions are always yours — the AI provides evidence, you decide

### Auto-Research Mode

Say `"Auto-research: [problem statement]"` to trigger autonomous solution iteration:
- AI generates multiple solution approaches
- Implements and tests each approach  
- Uses adversarial review to find weaknesses
- Iteratively refines until optimal solution found
- Presents evidence-backed recommendation

Example: `"Auto-research: Build a rate limiter that handles 100k requests/second"`

### IDE-Specific Context Loading

| IDE | Where to put the files | How they load |
|-----|------------------------|---------------|
| **Kiro** | `.kiro/steering/` or `~/.kiro/steering/` | Auto-included in every conversation |
| **Cursor** | `.cursor/rules/` | Auto-included per project |
| **Windsurf** | `.windsurf/rules/` | Auto-included per project |
| **GitHub Copilot** | `.github/copilot-instructions.md` (combine files) | Auto-included in Copilot Chat |
| **Any other** | Paste into system prompt or custom instructions | Manual inclusion |

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Remove gates you don't need (but keep G0, G4, and G6 at minimum)
- **Domain-specific reviews:** Create tailored B-Team prompts for your platform (see `04-adversarial-review.md` for examples)
- **Existing projects:** Use `templates/EXISTING-PROJECT-ASSESSMENT.md` to assess where you stand before applying gates

## Philosophy

> "AI builds. Humans decide. Evidence proves."

Based on Robert Cooper's Stage-Gate® (1986), adapted for a world where AI agents produce code faster than humans can review it. The gates ensure that speed doesn't compromise safety.

---

*Template version 1.1 — May 2026*
