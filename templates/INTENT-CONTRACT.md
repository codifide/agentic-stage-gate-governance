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
| Human Project Steward | | |
| Aegis | | |
| Primum | HALT and escalate | Redefine intent; waive harm boundaries |
| Atlas / loops | | |
| A-Team | | |
| B-Team | Review and challenge | Modify production |
| Domain Expert Persona | | |

## 11. Approvals

- **Human Project Steward:**
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
5. obtain human approval before autonomous work resumes.
