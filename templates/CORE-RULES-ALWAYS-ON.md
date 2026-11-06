# Core Rules — Always-On Template

How to keep a short, project-specific set of non-negotiable rules in context every session, while the full persona definitions load only when needed.

This is a template for a **project-level** rules file. The harness itself already ships its own always-loaded core: `steering/00-welcome.md`. When a project rule here conflicts with `00-welcome.md`, `00-welcome.md` wins and the conflict is a defect to report. Do not copy or redefine harness rules here; point to them.

---

## The Problem

Long persona definitions load on demand to protect the context budget. That means a guardrail only applies if someone remembers to load the file that holds it. In practice, the rules that matter most (safety, security, test integrity) are the ones most likely to be missing from context when work happens.

## The Solution: Two Tiers

**Tier 1: project core rules.** A short file (aim for about 40 lines) holding only the rules whose violation causes real harm. Loaded every session.

**Tier 2: full persona and domain files.** Longer definitions loaded on demand for deep work, per the On-Demand Index in `00-welcome.md`.

The harness core is Tier 1 for the framework. This template is for the project-specific rules you add beside it.

### What is and is not enforced

Putting a rule in an always-loaded file makes it **visible**, not **enforced**. A model can still ignore it, especially when context is long or compacted. Treat the file as a reminder and back every rule that matters with something that can fail a build or block a write:

| Mechanism | Effect |
|-----------|--------|
| Rules file (this template) | Advisory. Raises the odds the rule is followed. |
| `agent`-type hook | Advisory. Injects a reminder. See `templates/HOOKS-SESSION-STATE.md`. |
| Blocking `command` hook, CI check, test suite | Enforcing for the cases it matches. See `templates/enforcement/`. |

[UNVERIFIED] Whether your tool treats an `inclusion: auto` (or equivalent) file as always loaded, or loads it only when it judges the topic relevant, depends on the runtime. Confirm in your tool before relying on it. If it is only loaded on demand, use the tool's always-on setting instead (the harness core uses `inclusion: always`).

---

## Template

Create: `<steering-dir>/<project>-core-rules.md`

```markdown
---
inclusion: always   # [UNVERIFIED] key name and values vary by tool
---

# Project Core Rules — Non-Negotiable

Advisory reminders. Backed by CI and hooks where noted. Detail lives in the
full files listed in the On-Demand Index of 00-welcome.md.

## Do No Harm (see 12-intent-integrity.md for the HALT procedure)
- Before any consequential change: what is the blast radius, is it reversible,
  is it inside the Intent Contract scope?
- Never modify [critical logic] without checking it against its authoritative source.
- Never run bulk operations on [critical data] without confirming a restorable backup.
- If unsure whether an action is safe, stop and ask the Human Steward.

## Security
- Data access uses parameterized statements. No string interpolation.
- Tables holding [sensitive data] have access controls enforced at the data layer.
- Never echo secrets or sensitive data in responses, logs, or error messages.
- Pre-commit security checks are not bypassed.

## Test Integrity
- Changes ship with test coverage per 03-coding-standards.md.
- Golden fixtures and verifiers are immutable paths (.sgl/immutable-paths); changing one needs Human Steward approval.
- Tests assert correct behavior, not just that code ran.
- Tests pass in a clean environment with no leaked state.

## Performance
- [Project-specific rule, e.g. no unindexed queries on tables above N rows]
- [Project-specific timing or throughput constraint]

## Architecture
- Service and schema ownership boundaries are explicit. Respect them.
- Time-sensitive logic states its timezone and boundary behavior.

## Domain Expert
- Do not infer domain-specific meanings from memory. Quote the source.
- Document each criterion or rule separately when several exist.
- Expert corrections are recorded in the domain expert file in the same response.
- Rules change between versions. Verify against the current source.

## Governance
- Gate decisions, exceptions, and track selection belong to the Human Steward.
- A spec does not advance without acceptance criteria and passing tests.
- Status tracking reflects reality, not aspiration.
```

---

## Design Principles

1. **Short.** If it grows past roughly 40 lines, it is carrying detail that belongs in a Tier 2 file. Give each area 3 to 5 rules at most.
2. **Non-negotiable only.** If the right answer is "it depends," the rule does not belong here.
3. **Actionable, not aspirational.** "Parameterized queries only" can be followed and checked. "Write secure code" cannot.
4. **Checkable where possible.** A rule with a threshold or a grep can be turned into a CI check. Do that.
5. **Reference, don't redefine.** HALT lives in `12-intent-integrity.md`, the coverage table in `03-coding-standards.md`, authority in `00-welcome.md` §1. Link to them.

---

## Anti-Pattern

```markdown
# BAD: full persona content in the always-on file
## Security (500 lines of threat model, evidence standards, credential inventory...)
```

The always-on file is a summary of rules that would cause harm if broken. Context, rationale, and detailed guidance stay in the on-demand files.

---

## Known Limits

| Limit | Consequence |
|-------|-------------|
| One model plays every persona | Persona rules do not create independent review. Independent review follows `00-welcome.md` §3 and `04-adversarial-review.md`. |
| Reminders can be ignored | Anything that must hold regardless of agent behavior needs a blocking hook or CI check. |
| Numbers and examples go stale | Keep counts and dates out of the rules file, or regenerate them from the source of truth. |
