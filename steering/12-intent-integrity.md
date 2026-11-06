---
inclusion: auto
name: sgl-intent-integrity
description: SGL Intent Contract requirements, Primum intent-integrity checks (goal, scope, constraints, metric and verifier integrity, reversibility, human impact), and the single authoritative HALT procedure. Load when writing an Intent Contract, issuing or handling a HALT, or changing any verifier, baseline, or threshold.
# For non-Kiro tools, load this file on demand for intent or HALT work.
---

# Intent Integrity and Do No Harm

Agentic systems can execute faster than humans can inspect every line, command, or intermediate decision. That makes **human-authorized intent** a first-class control artifact.

This steering file defines the Intent Contract and the Primum / Do No Harm circuit-breaker protocol.

---

## Why Intent Integrity Exists

Traditional review assumes humans can inspect the implementation closely enough to notice when the system has drifted from the original purpose.

At agentic velocity, that assumption breaks.

A system may:
- pass tests while solving the wrong problem;
- improve one KPI by degrading another;
- expand scope because the agent discovered an "easier" path;
- change a verifier rather than fix the implementation;
- acquire broader privileges than the task requires;
- take an irreversible action before a human sees the diff.

The answer is not to ask humans to review faster. The answer is to make intent, constraints, evidence, and escalation machine-readable and continuously enforceable.

---

## The Intent Contract

**Standard and Enterprise initiatives MUST create** `specifications/{ID}/INTENT_CONTRACT.md` at G0, using `templates/INTENT-CONTRACT.md`. The Human Steward approves it, and only the Human Steward may change it.

**Express initiatives MUST include an inline Intent block** in the combined G0/G1 note: goal, authorized scope, protected constraints, harm boundary, and rollback. That block is what Primum checks Express work against.

The contract contains:

1. **Goal** — what outcome the human is authorizing
2. **Why** — the business, user, or operational reason
3. **Authorized Scope** — what systems, data, and behaviors may change
4. **Protected Constraints** — what must not degrade
5. **Non-Goals** — what the initiative is explicitly not trying to solve
6. **Harm Boundaries** — outcomes that are unacceptable even if the goal is achieved
7. **Escalation Conditions** — situations that require human judgment
8. **Success Evidence** — what proves the intended outcome was achieved
9. **Reversibility Requirements** — what must be rollback-capable
10. **Authority Boundaries** — which agents/personas may do what, and the named Human Steward
11. **Immutable Paths** — pointer to `.sgl/immutable-paths` for any loops in scope

The Intent Contract is persistent state. It must survive context-window resets and session boundaries.

---

## Intent Integrity Checks

Primum evaluates proposed and executed actions against the Intent Contract.

### Goal Alignment
Is the action necessary for the authorized goal, or has the system started solving an adjacent problem?

### Scope Alignment
Does the action modify only approved systems, data, dependencies, permissions, and workflows?

### Constraint Preservation
Does the proposed optimization degrade security, privacy, accessibility, reliability, cost, clinical accuracy, compliance, or another protected constraint?

### Metric Integrity
Is the agent improving the real outcome or merely improving the measurement?

Examples of metric gaming:
- weakening a test so it passes;
- changing a benchmark baseline without justification;
- suppressing an error instead of resolving it;
- excluding difficult cases to improve a rate;
- optimizing token cost by routing complex cases to an incapable model.

### Verifier Integrity
The generator may not silently modify the verifier that judges its own work.

Any change to:
- test expectations,
- acceptance thresholds,
- comparison baselines,
- security policy,
- lint rules,
- benchmark definitions,
- evaluator prompts,
- quality scoring,

is a governance event: made on its own change, with written justification, approved by the Human Steward, outside any loop that the verifier judges. Regenerating a baseline from the code under test is never acceptable.

### Reversibility
Before destructive, production, migration, deletion, privilege, or customer-impacting operations:
- determine blast radius;
- confirm rollback path;
- confirm authorization;
- HALT if any are unknown and the impact is consequential.

### Human Impact
Ask whether a technically successful outcome can still create unacceptable harm to users, patients, customers, employees, operators, finances, legal posture, or trust.

---

## HALT Protocol (authoritative)

This is the only HALT procedure in the harness. Other files point here.

Primum **MUST** issue `PRIMUM: HALT` when an action:
- violates an explicit harm boundary;
- exceeds authorized scope;
- meets an escalation condition defined in the Intent Contract;
- manipulates a verifier, baseline, or evidence without Human Steward approval;
- creates consequential irreversible impact without authorization ("consequential" as defined in `00-welcome.md` §5: production, real user data, money, credentials or security posture, or no tested rollback; when unsure, it is consequential);
- cannot be reconciled with human-authorized intent.

Any agent or persona that observes one of these conditions must also stop and raise HALT; it does not need to wait for Primum.

When HALT occurs:

1. Stop the affected loop/action immediately.
2. Persist current state.
3. Record the proposed action and why it triggered HALT in `specifications/{ID}/HALT_LOG.md`.
4. Preserve evidence: diffs, test results, verifier output, and the relevant prompts and logs. **Redact before preserving:** secrets, credentials, and real PHI/PII are referenced by ID, never copied. If a secret was exposed, say so and flag it for rotation.
5. Notify Aegis (to block dependent gates).
6. Escalate to the Human Steward with the record.
7. **Do not resume until the Human Steward explicitly resolves the conflict in writing.** No AI persona, including Aegis and Primum, may resume.

Primum can stop execution. It cannot waive the boundary that caused the stop.

---

## Relationship to Other Personas

| Persona | Primary Question |
|---------|------------------|
| **Sentinel** | Is it secure? |
| **Ruth** | Is it compliant and privacy-safe? |
| **Tessa** | Is it correctly tested and independently verifiable? |
| **Atlas** | Can it run autonomously with state, observability, and circuit breakers? |
| **Aegis** | Does the evidence satisfy the governance policy? |
| **Primum** | Are we still doing what the human authorized, without unacceptable harm? |
| **Quill** | What actually happened, why, and what did we learn? |

These responsibilities overlap intentionally but are not interchangeable.

---

## Human Review at Agentic Velocity

Humans can't review every line of agent-generated code at agentic speed. Assurance shifts to automated evidence (architecture conformance, regression tests, security and policy checks, independent verifiers, intent checks, resolved B-Team findings, rollback evidence). Human attention shifts to intent, architecture, risk acceptance, exceptions, evidence quality, and domain judgment.

---

## Do No Harm Principle

"Do no harm" is not a claim that an AI can perfectly predict every consequence.

It is an engineering rule:

> **When the system detects a credible conflict between execution and human-authorized intent, protected constraints, or harm boundaries, autonomy yields to escalation.**

That rule is enforceable, reviewable, and auditable.

---

## Summary

**Humans define intent.  
Agents execute.  
Verifiers prove.  
Primum watches the boundary.  
Aegis enforces policy.  
Quill preserves the history.  
Humans decide when judgment matters.**
