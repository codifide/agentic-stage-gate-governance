# Core Rules — Always-On Template

## The Problem (from Production Use)

Persona definitions are `inclusion: manual` (loaded on demand) to manage context budget. But this means the entire persona system is opt-in — and opt-in means opt-out in practice. The AI works without persona guidance 80% of the time.

The most dangerous failure mode: the one guardrail that should NEVER be off (patient safety, security, test quality) is the one that's disabled by default.

## The Solution: Two-Tier System

**Tier 1: Core Rules (always on, ~40 lines)**
Non-negotiable rules extracted from each persona. Set to `inclusion: auto`. Always in context regardless of what the session is doing.

**Tier 2: Full Persona Definitions (on demand, 100-175 lines each)**
Complete operational definitions loaded when deep review is needed. Set to `inclusion: manual`.

This gives you always-on coverage without burning the context window.

---

## Template

Create: `.kiro/steering/00-core-rules.md`

```markdown
---
inclusion: auto
---

# Core Rules — Non-Negotiable (Always Active)

These rules are ALWAYS in context. They are the enforceable subset of persona authority.
Full persona files exist in `.kiro/steering/personas/` for deep reviews.

## [Safety Persona] (Do No Harm)
- Before ANY [domain-critical] change: What's the blast radius? Is it reversible? Is it in scope?
- NEVER modify [critical logic] without verifying against authoritative source
- NEVER run bulk operations on [critical data] without confirming backup exists
- If unsure whether an action is safe, STOP and ask. Do not rationalize.

## [Security Persona]
- ALL data access MUST use parameterized statements. No string interpolation.
- Every table with [sensitive data] MUST have access controls enforced
- NEVER echo secrets or sensitive data in responses, logs, or error messages
- Pre-commit security hooks are non-negotiable. Never suggest bypassing.

## [Test Guardian Persona]
- No feature ships without test coverage. Period.
- Critical test fixtures are IMMUTABLE without domain expert re-approval
- Tests MUST prove correctness, not just execution
- Tests must pass in a clean environment (no leaked state)

## [Performance Persona]
- No unindexed queries on large tables
- Use caching/materialization for dashboard aggregations
- [Domain-specific timing constraints]

## [Architecture Persona]
- Service boundaries are explicit. Do not blur.
- Schema ownership is defined. Respect it.
- All temporal operations explicit about timezone and boundaries.

## [Domain Expert Persona]
- NEVER infer domain-specific meanings from memory. QUOTE the source.
- Document each criterion/rule SEPARATELY when multiple exist.
- Expert corrections are BINDING. Write to steering file immediately.
- Rules change between versions/years. Always verify against current source.

## [Governance Persona]
- No spec progresses past requirements without acceptance criteria
- No spec progresses past implementation without passing tests
- Status tracking must reflect reality, not aspiration
```

---

## Key Design Principles

1. **~40 lines total.** If it's longer, you're including too much. Each persona gets 3-5 rules maximum.

2. **Non-negotiable only.** These rules should NEVER be situationally overridden. If "it depends," it doesn't belong here.

3. **Actionable, not aspirational.** "Parameterized queries only" is actionable. "Write secure code" is aspirational.

4. **Testable where possible.** "No unindexed queries on tables >100K rows" can be verified. "Consider performance" cannot.

5. **The safety persona should also be `inclusion: auto`.** Core rules cover the summary; the full Primum/safety persona file provides depth for edge cases.

---

## What This Fixes (B-Team Findings)

| Critical Finding | How Core Rules Addresses It |
|-----|------|
| C-4: All personas opt-in | Core rules are auto-included — always in context |
| C-5: Safety persona always-active contradiction | Safety rules + full safety persona both `inclusion: auto` |
| C-7: Context budget makes full coverage impossible | 40 lines covers essentials; full personas loaded for deep reviews |
| CC-3: Context budget economics | Two-tier system: cheap always-on + expensive on-demand |

---

## Anti-Pattern: Do NOT Do This

```markdown
# BAD: Putting full persona content in core rules
## Security (500 lines of threat model, evidence standards, credential inventory...)
```

Core rules are a SUMMARY. They contain the rules that would cause harm if violated. The context, rationale, and detailed guidance live in the full persona files.
