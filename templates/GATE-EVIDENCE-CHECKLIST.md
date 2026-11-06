# Gate Evidence Checklist Template

This checklist mirrors `steering/01-governance-gates.md` item for item. If the two ever disagree, `01` is authoritative and the mismatch is a defect.

## How to Use

1. Copy into `specifications/{ID}/GATE_CHECKLIST.md`
2. Delete the track sections that don't apply
3. Mark items `[x]` when the evidence exists, with a link to it
4. Mark items `[BLOCKED: reason, ETA]` if a dependency prevents completion
5. A gate **cannot pass** while any required item is incomplete or blocked
6. **The Human Steward records the decision** at the bottom of each gate. An AI persona may recommend; it may not fill in the decision line.

Review levels referenced below: R1 verifier-only, R2 focused B-Team, R3 full B-Team (`steering/00-welcome.md` §3). Reviews run in an independent context, never self-conducted.

---

## Express Track (Combined G0/G1 → G4 → Ship)

### Combined G0/G1 note
- [ ] Problem, users, scope (in/out)
- [ ] Express eligibility confirmed (< 1 week; read-only or additive; architecture already established; no new security surface; no sensitive data, identity, or release logic; no compliance impact)
- [ ] Inline Intent block: goal, authorized scope, protected constraints, harm boundary, rollback
- [ ] NFR impact statement (or "no NFR change" + reason)
- [ ] Primum intent check (fresh context) against the Intent block
- [ ] R2 review (Vex + Kade + Noor) of this note, findings dispositioned
- **Decision (Human Steward):** ☐ Go ☐ Kill ☐ Hold — name, date: ______

### G4 + ship
- [ ] Code complete against acceptance criteria
- [ ] Coverage per `03` (or approved exception)
- [ ] Every change reviewed at its Review Level (`11`), findings dispositioned
- [ ] Security scans clean (no open CRITICALs), a11y checks pass
- [ ] Traceability updated (requirement → test → verification)
- [ ] Any verifier/baseline/threshold/immutable-path change approved by the Human Steward as its own change
- [ ] Primum check (fresh context) passed against the Intent block; no unresolved HALT
- [ ] NFR impact re-verified as stated in the G0/G1 note
- [ ] Rollback note: how to revert and how to tell it worked
- **Ship decision (Human Steward):** ☐ Ship ☐ Hold — name, date: ______

---

## Standard and Enterprise Tracks

### G0 — Problem Statement
- [ ] Business problem statement
- [ ] Target users and workflow
- [ ] Risk classification (sensitive data, identity, release logic)
- [ ] Stakeholders identified
- [ ] Scope boundaries (in / out)
- [ ] Track proposed with rationale
- [ ] Intent Contract drafted (`templates/INTENT-CONTRACT.md`), Human Steward named
- [ ] Primum intent check against the draft Intent Contract
- [ ] Gate review: Standard R2 (Vex + Kade + Noor) / Enterprise R3
- **Decision (Human Steward):** ☐ Go ☐ Kill ☐ Hold — track: ______ — name, date: ______

### G1 — Requirements & Evidence
- [ ] Evidence-backed requirements with acceptance criteria
- [ ] Glossary and business rules
- [ ] NFRs with measurable targets
- [ ] KPIs with baselines
- [ ] Benchmarks defined
- [ ] API contracts or integration specifications
- [ ] Backend traceability (if integrating with existing systems)
- [ ] Open assumptions documented
- [ ] Intent Contract traced into acceptance criteria and NFRs
- [ ] Gate review: R3, findings dispositioned
- **Decision (Human Steward):** ☐ Go ☐ Kill ☐ Hold — name, date: ______

### G2/G3 — Design & Architecture (one gate)
- [ ] Architecture overview with module boundaries
- [ ] ADRs for significant decisions (alternatives considered), including any new cloud service/account, approved by the Human Steward
- [ ] Threat model (attack surfaces, mitigations, residual risk)
- [ ] Data flow and trust boundaries
- [ ] Test strategy
- [ ] Decomposed tickets with acceptance criteria
- [ ] 3 Amigos approval on each execution ticket
- [ ] Agent/loop authority boundaries and irreversible-action controls defined
- [ ] `.sgl/immutable-paths` approved for any loops in scope
- [ ] Gate review: R3, findings dispositioned
- **Decision (Human Steward; + Architecture/Security Lead on Enterprise):** ☐ Go ☐ Kill ☐ Hold — names, date: ______

### G4 — Build & Verify
- [ ] Code complete against ticket acceptance criteria
- [ ] Coverage meets `03` targets (exceptions approved by the Human Steward, linked)
- [ ] Security review passed (no open CRITICALs)
- [ ] Accessibility audit passed
- [ ] Every change reviewed at its Review Level (`11`), findings dispositioned
- [ ] Traceability updated (requirement → test → verification)
- [ ] Primum intent-integrity check passed; no unresolved HALT
- [ ] Any verifier/baseline/threshold/immutable-path change approved by the Human Steward as its own change
- [ ] Enterprise only: R3 review of the G4 package (in addition to per-change reviews)
- **Decision (Human Steward):** ☐ Go ☐ Kill ☐ Hold — name, date: ______

### G5 — Release Readiness
- [ ] Release notes
- [ ] Rollback plan (tested, not theoretical)
- [ ] Monitoring and alerting configured
- [ ] Penetration test completed **or** residual risk accepted in writing by the Human Steward (link)
- [ ] Compliance review completed, if applicable (Compliance Officer role)
- [ ] NFR targets met with evidence
- [ ] KPI baseline collected or measurement plan documented
- [ ] AI-BOM current (`10`), if AI components are used
- [ ] Intent Contract revalidated against release behavior and protected constraints
- [ ] Gate review: R3 (Enterprise: + zero-context reader). Verdict PASS, or PASS WITH CONDITIONS with every condition owned, dated, and accepted in writing by the Human Steward
- **Decision (Human Steward):** ☐ Release ☐ Hold ☐ Kill — name, date: ______

### G6 — Post-Release Review
- [ ] Production observations (7-day minimum)
- [ ] KPI actuals vs. targets
- [ ] Incident review (if any)
- [ ] Reliability metrics
- [ ] User feedback summary
- [ ] Follow-up actions identified
- [ ] Quill lifecycle narrative completed (`QUILL_LOG.md`)
- [ ] Gate review: Standard R2 (Vex + Ink + Slate) / Enterprise R3
- **Decision (Human Steward):** ☐ Close ☐ Follow-up required — name, date: ______

---

## Evidence Tools and Thresholds

> Customize for your stack.

| Category | Tool | Threshold | Report Format |
|----------|------|-----------|---------------|
| Test Coverage | [your tool] | Per `03` coverage table | [format] |
| Security Scan | [your tool] | 0 critical, 0 high | [format] |
| Accessibility | [your tool] | WCAG 2.1 AA | [format] |
| Performance | [your tool] | [NFR targets] | [format] |

---

## Artifact Registry

| Artifact | Gate | Status | Responsible | Location |
|----------|------|--------|-------------|----------|
| Problem statement + Intent Contract | G0 | ❌ Must create | [owner] | [path] |
| Requirements | G1 | ❌ Must create | [owner] | [path] |
| Threat model | G2/G3 | ❌ Must create | [owner] | [path] |
| Coverage report | G4 | ❌ Must create | [owner] | [path] |
| Release notes + rollback plan | G5 | ❌ Must create | [owner] | [path] |
| Findings tracker | All | ❌ Must create | [owner] | `FINDINGS_TRACKER.md` |

> Status values: ✅ Exists | ⚠️ Partially exists | ❌ Must create | ⏳ Post-launch
