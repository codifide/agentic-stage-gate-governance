---
inclusion: auto
name: sgl-governance-gates
description: Full criteria for SGL gates G0, G1, G2/G3, G4, G5, G6, the G-LOOP, scale-adaptive tracks (Express/Standard/Enterprise), and governance principles. Load when running, preparing, or assessing any gate, or when selecting a track.
# For non-Kiro tools, load this file on demand when gate work begins.
---

# Governance Gates

Every initiative passes through **six gates**: G0, G1, G2/G3 (one combined design-and-architecture gate), G4, G5, G6. No gate passes on confidence, only on evidence. Between gates, automated loops (G-LOOP) verify consistency, run tests, and catch drift.

**Authority:** the Human Steward decides every gate (see `00-welcome.md` §1). AI personas produce evidence and recommendations. Aegis may block a gate for missing evidence; it may never pass one.

**Review requirements** for each gate and track are defined once, in `00-welcome.md` §3. This file does not restate them.

**Intent Contract:** required at G0 for Standard and Enterprise (`templates/INTENT-CONTRACT.md`). Express uses an inline Intent block in the combined G0/G1 note.

## The Gates

| Gate | Question | Evidence owners (AI personas) | Decision |
|------|----------|-------------------------------|----------|
| **G0** | Is this worth exploring? | Harper, Mary, Primum | Human Steward |
| **G1** | Are the requirements and evidence strong enough? | Harper, Mary, Forge, Ruth | Human Steward |
| **G2/G3** | Is the design/architecture ready? | Winston, Sentinel, Tessa | Human Steward (+ Architecture/Security Lead on Enterprise) |
| **G4** | Build and verify. | Amelia, Tessa, Sentinel, Primum | Human Steward |
| **G5** | Release readiness. | Sable, Sentinel, Ruth, Forge | Human Steward |
| **G6** | Post-release review. | Sable, Harper, Quill | Human Steward |

---

## G-LOOP — Automated Verification Between Gates

Between gates, automated loops run continuously. They don't require human approval but DO log their results.

**G-LOOP handles:**
- Running test suites after every change
- Verifying data consistency (row counts, checksums, view freshness)
- Build verification (compile, lint, type-check)
- Regression detection (benchmarks, API contract compliance)
- Drift monitoring (schema, dependency, config divergence)
- Intent-integrity checks (scope drift, protected-constraint regression, verifier manipulation)
- Computing the Review Level floor for each change (`11`)

**G-LOOP does NOT handle:**
- Design decisions or architecture changes
- Compliance interpretation
- Anything requiring "it depends" reasoning
- Redefining intent, waiving harm boundaries, or accepting residual risk
- Passing a gate

**Rule:** If a verifier can judge it, it belongs in G-LOOP. If it needs human judgment, it goes through a gate.

---

## G0 — Is This Worth Exploring?

**Must include:**
- Business problem statement
- Target users and workflow
- Risk classification (sensitive data, identity, release logic?)
- Stakeholders identified
- Scope boundaries (in / out)
- Proposed track with rationale
- Primum intent check (fresh context, `00` §5) against the draft Intent Contract
- Intent Contract (Standard/Enterprise) or inline Intent block (Express), naming the Human Steward

**Passes when:** The Human Steward agrees the problem is worth solving, the scope is honest, and the track is right.

**Template:** `specifications/{ID}/G0_PROBLEM_STATEMENT.md`

### Loop-Eligible Tasks at G0
- Stakeholder identification from org charts and prior specs
- Risk classification lookup against known patterns
- Duplicate detection (has this been proposed before?)

---

## G1 — Are the Requirements and Evidence Strong Enough?

**Must include:**
- Evidence-backed requirements with acceptance criteria
- Glossary and business rules
- NFRs with measurable targets, KPIs with baselines, and Benchmarks (`05`)
- API contracts or integration specifications
- Backend traceability (if integrating with existing systems)
- Open assumptions documented
- Gate review completed at the level required by `00` §3, findings dispositioned
- Intent Contract traced into acceptance criteria and NFRs
- Primum intent check (fresh context) passed

**Passes when:** Requirements are testable, traceable, and survived adversarial review.

**Template:** `specifications/{ID}/G1_REQUIREMENTS.md`

### Loop-Eligible Tasks at G1
- Acceptance-criteria completeness check
- Glossary consistency verification
- NFR target validation (measurable, not subjective)
- API contract schema validation
- Traceability matrix generation (requirement → test)

---

## G2/G3 — Is the Design/Architecture Ready?

G2/G3 is **one gate**. The label is historical (design and architecture used to be separate gates); there is no standalone G2 or G3.

**Must include:**
- Architecture overview with module boundaries
- ADRs for significant decisions (with alternatives considered), including any new cloud service or account (requires Human Steward approval)
- Threat model (attack surfaces, mitigations, residual risk)
- Data flow and trust boundaries
- Test strategy
- Decomposed tickets with acceptance criteria
- 3 Amigos approval on each execution ticket (the product, development, and test owners for the ticket; humans where the organization has them, otherwise the Human Steward)
- Gate review at the level required by `00` §3
- Authority boundaries and irreversible-action controls for agents/loops, including `.sgl/immutable-paths`

**Passes when:** The design is implementable, secure, and testable, and the team knows what to build.

**Template:** `specifications/{ID}/G2_ARCHITECTURE.md` + `ADR-*.md` + `THREAT-MODEL.md`

### Loop-Eligible Tasks at G2/G3
- Dependency vulnerability scanning on the proposed stack
- Interface contract validation across modules
- Architecture drift detection against ADRs
- Ticket decomposition verification

---

## G4 — Build and Verify

**Must include:**
- Code complete against ticket acceptance criteria
- Coverage meets the targets in `03-coding-standards.md` (the single coverage table). Exceptions are approved by the Human Steward.
- Security review passed (no open CRITICALs)
- Accessibility audit passed
- Every change reviewed at its Review Level (`11`), with findings dispositioned
- Traceability updated (requirement → test → verification)
- Primum intent-integrity check passed with no unresolved HALT
- Any verifier, baseline, threshold, or immutable-path change approved by the Human Steward as its own change

**Passes when:** The code works, is proven to work, and the proof is documented.

**Template:** `specifications/{ID}/G4_VERIFICATION.md`

### Loop-Eligible Tasks at G4
- Continuous test execution on every commit
- Coverage enforcement
- Security scan automation (SAST, SCA, secret detection)
- Accessibility linting
- Build verification
- Performance regression detection against an approved baseline
- Immutable-path check on every PR (`templates/enforcement/check-immutable-paths.sh`)

---

## G5 — Release Readiness

**Must include:**
- Release notes
- Rollback plan (tested, not theoretical)
- Monitoring and alerting configured
- Penetration test completed, **or** residual risk accepted in writing by the Human Steward with rationale
- Compliance review completed (if applicable), signed by the Compliance Officer role
- NFR targets met (with evidence)
- KPI baseline collected (or measurement plan documented)
- Current AI-BOM (`10`) if AI components are used
- Gate review at the level required by `00` §3, verdict PASS, or PASS WITH CONDITIONS where every condition has an owner and a deadline and the Human Steward has accepted the conditions in writing (`04`)
- Intent Contract revalidated against release behavior and protected constraints

**Passes when:** The Human Steward is satisfied the system is safe to put in front of users.

**Template:** `specifications/{ID}/G5_RELEASE_READINESS.md`

### Loop-Eligible Tasks at G5
- Rollback dry-run
- Monitoring configuration validation
- Alert threshold testing
- NFR evidence collection
- Release artifact integrity (checksums, signatures)

---

## G6 — Post-Release Review

**Must include:**
- Production observations (7-day minimum)
- KPI actuals vs. targets
- Incident review (if any)
- Reliability metrics
- User feedback summary
- Follow-up actions identified
- Quill lifecycle narrative completed (`specifications/{ID}/QUILL_LOG.md`)

**Passes when:** We've learned from the release and captured it for the next one.

**Template:** `specifications/{ID}/G6_RETROSPECTIVE.md`

### Loop-Eligible Tasks at G6
- KPI collection and dashboard updates
- Error-rate monitoring and trend detection
- SLA compliance reporting
- Loop health monitoring

---

## Principles

1. **User safety outranks throughput.** We don't ship faster by skipping gates.
2. **Evidence, not confidence.** "We think it's fine" is not a gate pass.
3. **Independent adversarial review, sized to risk.** Review levels per `00` §3. Never self-conducted.
4. **No single persona self-approves, and no AI approves.** AI recommends; humans decide.
5. **NFRs, KPIs, and Benchmarks are mandatory** for Standard and Enterprise; Express states NFR impact (or "no NFR change") in its G0/G1 note.
6. **Security and accessibility are every-phase.** Not a late fix.
7. **Automate repeatable assurance.** Coverage is evidence, not proof of correctness.
8. **Kill early, kill cheap.** The answer to a bad idea is G0 rejection, not G5 failure.
9. **Loop the mechanical, gate the judgment.**
10. **Intent is a control surface.** Agents may optimize execution, not redefine the goal.
11. **Do no harm.** When execution conflicts with intent or harm boundaries, autonomy yields to HALT.

---

## Scale-Adaptive Tracks

At G0 the Human Steward selects a **track** that sizes process depth to the work. Tracks change how much ceremony applies, **never whether evidence is required**.

| Track | When | Gate path | Evidence still required |
|-------|------|-----------|-------------------------|
| **Express** | < 1 week, read-only or additive, no new security surface, no sensitive data/identity/release logic, no compliance impact, architecture already established | Combined G0/G1 note → G4 → human ship decision | Inline Intent block; NFR impact statement; change reviews at their Review Level; G-LOOP; rollback note (how to revert and how to tell it worked) |
| **Standard** | Normal feature on established architecture | G0 → G1 → G2/G3 → G4 → G5 → G6 | Full gate evidence; Intent Contract |
| **Enterprise** | Sensitive data, identity, release logic, regulated, irreversible, or high blast radius | G0 → G1 → G2/G3 → G4 → G5 → G6 | Full gate evidence; Intent Contract; domain-expert sign-off (human SME); review levels per `00` §3 |

**Selecting a track:**
- Recorded in the G0 note with rationale; chosen by the Human Steward.
- When in doubt, go up a track.
- Anything touching sensitive data, identity, or release logic is Enterprise.
- Work can be **promoted mid-flight**. If Express work turns out to touch a security surface, it stops and re-enters as Standard or Enterprise.

**What never changes across tracks:** G-LOOP runs; evidence over confidence; the Human Steward makes the go/kill/hold decision.

---

## For Existing Projects

See `06-existing-project-assessment.md`. In short: assess each gate, close security gaps first (a missing threat model for a system handling user data is always P0), apply gates to new work going forward, and establish G-LOOP immediately.
