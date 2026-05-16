# Gate Evidence Checklist Template

## How to Use

1. Copy this template into your project's `docs/` directory
2. Fill in the checklist items based on your project's gate requirements
3. Mark items `[x]` as they are completed
4. Mark items `[BLOCKED: reason, ETA]` if a dependency prevents completion
5. A gate **cannot pass** while any required item is incomplete or blocked

---

## G0 — Problem Statement

- [ ] Business problem statement
- [ ] Target users and workflow
- [ ] Risk classification (security, data handling, user safety)
- [ ] Stakeholders identified
- [ ] Scope boundaries (what's in, what's out)

**Gate Status: _/5 complete**

---

## G1 — Requirements & Evidence

- [ ] Evidence-backed requirements with acceptance criteria
- [ ] Glossary and business rules
- [ ] NFRs with measurable targets
- [ ] KPIs with baselines
- [ ] API contracts or integration specifications
- [ ] B-Team adversarial review completed

**Gate Status: _/6 complete**

---

## G2/G3 — Design & Architecture

- [ ] Architecture overview with module boundaries
- [ ] ADRs for significant decisions
- [ ] Threat model (attack surfaces, mitigations, residual risk)
- [ ] Data flow and trust boundaries documented
- [ ] Test strategy document
- [ ] B-Team review of architecture and threat model

**Gate Status: _/6 complete**

---

## G4 — Build & Verify

- [ ] Code complete against requirements
- [ ] Test coverage report meets threshold
- [ ] CI pipeline operational
- [ ] Security scanning operational
- [ ] Security review passed (no open CRITICALs)
- [ ] Accessibility audit passed
- [ ] Integration tests passing

**Gate Status: _/7 complete**

---

## G5 — Release Readiness

- [ ] Release notes
- [ ] Rollback plan (tested, not theoretical)
- [ ] Monitoring and alerting configured
- [ ] Penetration test completed
- [ ] Deployment documentation
- [ ] Operations runbook
- [ ] NFR targets met with evidence
- [ ] B-Team final review (zero CRITICALs, all MAJORs resolved)

**Gate Status: _/8 complete**

---

## G6 — Post-Release Review

- [ ] Production observations (7-day minimum)
- [ ] KPI actuals vs. targets comparison
- [ ] Incident review (if any)
- [ ] Reliability metrics
- [ ] User feedback summary
- [ ] Follow-up actions identified

**Gate Status: _/6 complete**

---

## Evidence Tools and Thresholds

> Customize these for your project's tech stack.

| Category | Tool | Threshold | Report Format |
|----------|------|-----------|---------------|
| Test Coverage | [your tool] | ≥ [X]% | [format] |
| Security Scan | [your tool] | 0 critical, 0 high | [format] |
| Accessibility | [your tool] | WCAG 2.1 AA | [format] |
| Performance | [your tool] | [targets] | [format] |

---

## Artifact Registry

| Artifact | Gate | Status | Responsible | Location |
|----------|------|--------|-------------|----------|
| Problem statement | G0 | ❌ Must create | [owner] | [path] |
| Requirements | G1 | ❌ Must create | [owner] | [path] |
| Threat model | G2/G3 | ❌ Must create | [owner] | [path] |
| Coverage report | G4 | ❌ Must create | [owner] | [path] |
| Release notes | G5 | ❌ Must create | [owner] | [path] |

> Status values: ✅ Exists | ⚠️ Partially exists | ❌ Must create | ⏳ Post-launch
