# Agentic AI Project Template — Stage-Gate Governance

A ready-to-use project template for AI-assisted software development with built-in governance, adversarial review, and quality gates.

## What This Is

Drop the `.kiro/` folder into any project workspace. Open in Kiro. The governance system activates automatically — personas, gates, standards, and review processes are all baked in.

## Setup

### New Project
```bash
# Clone this repo and copy the steering folder into your project
cp -r agentic-stage-gate-governance/steering /path/to/your/new/project/.kiro/steering

# Open in Kiro
# The steering files activate automatically
# Say "Let's start a new initiative" to begin
```

### Existing Project
```bash
# Copy the steering folder into your existing project
cp -r agentic-stage-gate-governance/steering /path/to/your/existing/project/.kiro/steering

# Open in Kiro
# Say "Assess this codebase against the gates" to get a gap analysis
```

### Global (All Projects)
```bash
# Copy steering files to your user-level Kiro config
cp agentic-stage-gate-governance/steering/*.md ~/.kiro/steering/

# Now every project you open in Kiro gets the governance system
```

## What's Included

```
steering/
    ├── 00-welcome.md              # Splash screen — guides developer through gates
    ├── 01-governance-gates.md     # The 7-gate process (G0–G6)
    ├── 02-personas.md             # A-Team + B-Team + Zero-Context persona definitions
    ├── 03-coding-standards.md     # Coverage, security, accessibility, CI/CD
    ├── 04-adversarial-review.md   # B-Team review protocol + system prompt
    └── 05-nfr-kpi-mandate.md      # Measurable targets requirement
WHITEPAPER.md                      # Stage-Gate Rebooted — full methodology paper
```

## How It Works

1. **Steering files** are auto-included in every Kiro conversation
2. The AI reads them and follows the governance process
3. When you say "start a new initiative," it walks you through G0
4. When you say "review this," it invokes the appropriate personas
5. Gate decisions are always yours — the AI provides evidence, you decide

## Customization

- **Industry-specific:** Edit `01-governance-gates.md` to add domain-specific gate criteria (HIPAA, SOC2, PCI-DSS, etc.)
- **Team-specific:** Edit `02-personas.md` to rename personas or adjust responsibilities
- **Standards:** Edit `03-coding-standards.md` to match your tech stack's conventions
- **Lighter governance:** Remove gates you don't need (but keep G0, G4, and G6 at minimum)

## Philosophy

> "AI builds. Humans decide. Evidence proves."

Based on Robert Cooper's Stage-Gate® (1986), adapted for a world where AI agents produce code faster than humans can review it. The gates ensure that speed doesn't compromise safety.

---

*Template version 1.0 — May 2026*
