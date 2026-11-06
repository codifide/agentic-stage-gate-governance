# Intent Contract — {INITIATIVE_ID}

> Human-authorized intent is persistent system state. Agents may optimize execution, not silently redefine the goal.

## 1. Goal

What outcome are we authorizing?

- **Goal:**
- **Primary user/customer:**
- **Definition of done:**

## 2. Why

Why does this matter?

- **Business/user problem:**
- **Expected value:**
- **Why now:**

## 3. Authorized Scope

What may change?

### Systems / repositories
- 

### Data
- 

### Interfaces / APIs
- 

### Infrastructure
- 

### Permissions / tools agents may use
- 

## 4. Protected Constraints

What must not degrade while achieving the goal?

| Constraint | Baseline | Minimum acceptable | Evidence |
|------------|----------|--------------------|----------|
| Security | | | |
| Privacy | | | |
| Reliability | | | |
| Performance | | | |
| Cost | | | |
| Accessibility | | | |
| Domain accuracy | | | |
| Compliance | | | |

## 5. Non-Goals

The initiative is explicitly **not** authorized to:

- 
- 
- 

## 6. Harm Boundaries

The following outcomes are unacceptable even if the primary goal is achieved:

- 
- 
- 

## 7. Escalation Conditions

Human review is REQUIRED before:

- destructive or irreversible production actions;
- expansion beyond authorized systems/data;
- privilege expansion;
- changes to verifier expectations or acceptance thresholds;
- material degradation of a protected constraint;
- unresolved domain ambiguity with consequential impact;
- any condition listed below:

| Condition | Escalate To | Required Evidence |
|-----------|-------------|-------------------|
| | | |

## 8. Success Evidence

What evidence proves the intended outcome, not merely proxy metrics?

- 
- 
- 

## 9. Reversibility Requirements

- **Rollback required?**
- **Maximum acceptable blast radius:**
- **Recovery objective:**
- **State that must be backed up/preserved:**

## 10. Authority Boundaries

| Actor / Persona | May | May Not |
|-----------------|-----|---------|
| Human Steward (named below) | Pass/kill/hold gates; select track; approve exceptions, verifier changes, cloud resources; resume after HALT; change this contract | Delegate these to an AI persona |
| Aegis | Enforce policy; require evidence; block | Pass a gate; grant exceptions; resume after HALT |
| Primum | HALT (mandatory on boundary violation) and escalate | Redefine intent; waive harm boundaries; resume |
| Atlas / loops | Run within scope; propose immutable paths | Modify immutable paths; touch security config; exceed budget |
| A-Team | | Approve its own work |
| B-Team (independent model) | Review and challenge | Modify code or production |
| Domain Expert Persona | | Stand in for the human SME on consequential calls |

## 11. Immutable Paths

Loops in scope may read but never modify the paths in `.sgl/immutable-paths` (verifiers, fixtures, baselines, harness, rubrics).

- **Additions for this initiative:**
- **Approved by (Human Steward):**

## 12. Approvals

- **Human Steward (name):**
- **Delegates, if any (name + scope):**
- **Date:**
- **Current version:**
- **Change history:**

---

## Intent Change Protocol

Changing intent is allowed. **Silent intent drift is not.**

When the goal, scope, protected constraints, harm boundaries, or authority boundaries change:

1. update this contract;
2. record the reason;
3. re-run affected gate reviews;
4. invalidate stale verifier baselines if necessary;
5. obtain Human Steward approval before autonomous work resumes.

Only the Human Steward edits this contract. An agent may propose changes in a separate document.
