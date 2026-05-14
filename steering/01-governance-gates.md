---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Governance Gates

Every initiative passes through seven gates. No gate passes on confidence — only on evidence.

## The Gates

| Gate | Question | Who Decides |
|------|----------|-------------|
| **G0** | Is this worth exploring? | Product Owner + Director |
| **G1** | Are the requirements and evidence strong enough? | Director + B-Team |
| **G2/G3** | Is the design/architecture ready? | Architect + Security + Director |
| **G4** | Build and verify. | Test Architect + Security + Director |
| **G5** | Release readiness. | Full team |
| **G6** | Post-release review. | Director + SRE + Journalist |

---

## G0 — Is This Worth Exploring?

**Purpose:** Confirm the work is real, bounded, and worth doing.

**Must include:**
- Business problem statement
- Target users and workflow
- Risk classification (does it touch sensitive data, identity, release logic?)
- Stakeholders identified
- Scope boundaries (what's in, what's out)

**Passes when:** The problem is worth solving and the scope is honest.

**Template:** Create `specifications/{ID}/G0_PROBLEM_STATEMENT.md`

---

## G1 — Are the Requirements and Evidence Strong Enough?

**Purpose:** Ensure we're building from evidence, not assumptions.

**Must include:**
- Evidence-backed requirements with acceptance criteria
- Glossary and business rules
- NFRs (Non-Functional Requirements) with measurable targets
- KPIs (Key Performance Indicators) with baselines
- API contracts or integration specifications
- Backend traceability (if integrating with existing systems)
- Open assumptions documented
- B-Team adversarial review completed

**Passes when:** Requirements are testable, traceable, and survived adversarial review.

**Template:** Create `specifications/{ID}/G1_REQUIREMENTS.md`

---

## G2/G3 — Is the Design/Architecture Ready?

**Purpose:** Prevent unsafe or unworkable design from reaching implementation.

**Must include:**
- Architecture overview with module boundaries
- ADRs for significant decisions (with alternatives considered)
- Threat model (identify attack surfaces, mitigations, residual risk)
- Data flow and trust boundaries
- Test strategy
- Decomposed tickets with acceptance criteria
- 3 Amigos approval on each execution ticket (Product + Dev + Test)
- B-Team review of architecture and threat model

**Passes when:** The design is implementable, secure, testable, and the team knows what to build.

**Template:** Create `specifications/{ID}/G2_ARCHITECTURE.md` + `ADR-*.md` + `THREAT-MODEL.md`

---

## G4 — Build and Verify

**Purpose:** Prove the implementation is correct before discussing release.

**Must include:**
- Code complete against ticket acceptance criteria
- **100% test coverage on all new code** (no exceptions without Director-approved exception ticket)
- Legacy/ported code: risk-based coverage (95% critical paths, 80% services)
- Security review passed (no open CRITICALs)
- Accessibility audit passed
- Traceability updated (requirement → test → verification)

**Passes when:** The code works, is proven to work, and the proof is documented.

**Template:** Create `specifications/{ID}/G4_VERIFICATION.md`

---

## G5 — Release Readiness

**Purpose:** Prove the system can be deployed and operated safely.

**Must include:**
- Release notes
- Rollback plan (tested, not theoretical)
- Monitoring and alerting configured
- Security penetration test completed (or risk accepted with rationale)
- Compliance review completed (if applicable)
- NFR targets met (with evidence)
- KPI baseline collected (or measurement plan documented)
- Full B-Team final review

**Passes when:** The system is safe to put in front of users.

**Template:** Create `specifications/{ID}/G5_RELEASE_READINESS.md`

---

## G6 — Post-Release Review

**Purpose:** Close the loop. Learn from reality.

**Must include:**
- Production observations (7-day minimum)
- KPI actuals vs. targets
- Incident review (if any)
- Reliability metrics (crash-free rate, error rate, uptime)
- User feedback summary
- Follow-up actions identified
- Documentary capture (what worked, what didn't, what we'd change)

**Passes when:** We've learned from the release and captured it for the next one.

**Template:** Create `specifications/{ID}/G6_RETROSPECTIVE.md`

---

## Principles

1. **User safety outranks throughput.** We don't ship faster by skipping gates.
2. **Evidence, not confidence.** "We think it's fine" is not a gate pass.
3. **B-Team reviews every gate.** Different AI, different perspectives, different blind spots.
4. **No single persona self-approves.** Separation of duties is non-negotiable.
5. **NFRs, KPIs, and Benchmarks are mandatory.** If you can't measure it, you can't ship it.
6. **Accessibility is every-phase, not a late fix.** Every ticket includes accessibility acceptance criteria.
7. **100% test coverage on new code.** If AI writes it, AI tests it. No exceptions without approval.
8. **Kill early, kill cheap.** The answer to a bad idea is G0 rejection, not G5 failure.

---

## Fast-Track Rules

Small features (< 1 week effort, read-only, no new security surface) may be fast-tracked:
- Combined G0/G1 document
- Skip standalone G2/G3 if architecture is already established
- Still requires G4 evidence (tests, review)
- Director must explicitly approve fast-track

---

## For Existing Projects

When applying this governance to an existing codebase:

1. **Assess current state** — Which gate criteria does the project already meet?
2. **Identify gaps** — What evidence is missing?
3. **Create a gap-closure plan** — Prioritize: security gaps first, then coverage, then documentation
4. **Don't retroactively gate everything** — Apply gates to NEW work going forward; address existing gaps as a separate workstream
