---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Assessing Existing Projects

When applying governance to a project that already has working code, don't start from scratch. Assess where it stands, identify gaps, and close them systematically.

---

## The Process

1. **Evaluate each gate** against the existing codebase and documentation
2. **Classify status** as PASS, PARTIAL, or NOT_STARTED
3. **Identify gaps** with effort estimates and priority
4. **Produce a remediation sequence** ordered by priority then effort
5. **Close gaps incrementally** — don't try to do everything at once

---

## Assessment Rules

- **Only count what exists in the repository.** "We discussed it" is not evidence. "It's in the code" needs a document that says so.
- **Don't retroactively gate everything.** Apply gates to NEW work going forward. Address existing gaps as a separate workstream.
- **Security gaps first.** If the project handles user data, a threat model is P0 regardless of what else is missing.
- **The code IS evidence.** A working CI pipeline is G4 evidence. A comprehensive test suite is G4 evidence. Don't dismiss what's already there just because it wasn't produced through the gate process.

---

## What to Look For (by gate)

### G0 — Problem Statement
Look in: README, product docs, roadmap, PRD, pitch decks
- Is the problem clearly stated?
- Are target users identified?
- Is scope bounded (what's in vs. out)?
- Is risk classified?

### G1 — Requirements
Look in: specs, API docs, test files (tests ARE implicit requirements), issue trackers
- Are there testable acceptance criteria (even if informal)?
- Are NFRs defined (latency, availability, accuracy)?
- Are KPIs tracked (even if just in analytics code)?

### G2/G3 — Architecture
Look in: README, architecture docs, ADRs, code structure, config files
- Is the architecture documented (even implicitly via directory structure)?
- Are significant decisions recorded?
- Does a threat model exist?
- Is there a test strategy?

### G4 — Build & Verify
Look in: CI config, test directories, coverage reports, security scan config
- Is CI running?
- What's the test coverage?
- Is security scanning configured?
- Has an accessibility audit been done?

### G5 — Release Readiness
Look in: deployment docs, runbooks, monitoring config, release notes
- Can the system be deployed safely?
- Can it be rolled back?
- Is it monitored?
- Has it been pen-tested?

### G6 — Post-Release
Look in: dashboards, incident reports, retrospectives
- Are production metrics collected?
- Have incidents been reviewed?
- Is there a feedback loop?

---

## Common Patterns

### "Code-complete but governance-empty"
The project works, has tests, has CI — but no formal gate documents. This is the most common pattern for AI-built projects. The code IS the evidence; the gap is documentation and formal review.

**Strategy:** Close G0 and G1 first (low effort — the content exists, just needs formatting). Then focus on G4 evidence (coverage report, security review). G2/G3 can often be backfilled from the code structure.

### "Documentation-heavy but untested"
Lots of specs and design docs, but test coverage is low and no security review exists.

**Strategy:** Focus on G4 — tests and security. The documentation gates are already met.

### "Shipped but ungoverned"
Already in production with users, but no formal governance was applied.

**Strategy:** Start with G6 (you have production data — use it). Then work backwards: G5 (is monitoring in place?), G4 (is it tested?), G2/G3 (is the architecture documented?).

---

## Template

Use `templates/EXISTING-PROJECT-ASSESSMENT.md` for the full assessment document structure.

---

## Triggering an Assessment

Say any of these to your AI assistant:
- "Assess this codebase against the gates"
- "Where does this project stand?"
- "Run a gap analysis"
- "What gate are we at?"

The AI will evaluate the project against each gate and produce a status matrix with remediation recommendations.
