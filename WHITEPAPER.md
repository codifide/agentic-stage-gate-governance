# Stage-Gate Rebooted: How We Govern AI-Powered Development in Healthcare

**When your developer is an AI agent, who watches the gates?**

---

## The Problem No One Talks About

Agentic AI can write code faster than any human team. It can produce 50 files in an hour, refactor entire architectures in a session, and generate test suites that hit 95% coverage before lunch.

But speed without governance is just faster failure.

In healthcare software — where a bug isn't a broken button but a misdirected medical record — the question isn't *"can AI build it?"* It's *"should this ship?"*

We took Robert Cooper's Stage-Gate® framework (1986), stripped it to its core principle — **evidence, not confidence** — and rebuilt it for a world where AI agents do the building and humans decide what ships.

---

## The Classic Stage-Gate (1986)

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│Discovery│───▶│ Scoping │───▶│Business │───▶│Develop- │───▶│ Launch  │
│         │    │         │    │  Case   │    │  ment   │    │         │
└────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘
     │              │              │              │              │
   Gate 1        Gate 2        Gate 3        Gate 4        Gate 5
   "Is it        "Is it        "Is the       "Is it        "Is it
    real?"        worth it?"    plan solid?"   working?"     ready?"
```

Cooper's insight: **don't let bad projects consume resources.** Kill early, kill cheap. Each gate is a go/kill/hold decision made by senior management with evidence, not enthusiasm.

80% of product development organizations use some form of Stage-Gate ([PDMA Best Practices Study](https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products)).

---

## What Changes When AI Builds the Software

| Classic Assumption | New Reality |
|---|---|
| Development takes months | AI produces working code in hours |
| The bottleneck is building | The bottleneck is *deciding what to build* |
| Code review catches defects | AI generates plausible-looking code that passes superficial review |
| One team builds, another reviews | The same AI can build AND review (confirmation bias risk) |
| Security is a phase | AI doesn't instinctively think about attack surfaces |
| "Ship it" pressure comes from deadlines | "Ship it" pressure comes from how easy it is to produce |

**The danger isn't that AI builds bad software. It's that AI builds software so fast that governance can't keep up.**

---

## Our Reboot: 7 Gates for AI-Assisted Healthcare Development

```
┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
│  G0  │──▶│  G1  │──▶│G2/G3 │──▶│  G4  │──▶│  G5  │──▶│LAUNCH│──▶│  G6  │
│Worth │   │Reqs  │   │Design│   │Build │   │Ready │   │      │   │Learn │
│doing?│   │solid?│   │safe? │   │works?│   │ship? │   │      │   │      │
└──┬───┘   └──┬───┘   └──┬───┘   └──┬───┘   └──┬───┘   └──────┘   └──┬───┘
   │          │          │          │          │                       │
   ▼          ▼          ▼          ▼          ▼                       ▼
 Problem    Evidence   Adversarial  Proof    Patient                 Reality
 is real    survives   review of    it       safety                  vs.
            attack     architecture works    verified                plan
```

### The Key Differences

**1. Adversarial B-Team + Zero-Context Reviewer at every gate**

We don't let the builder review their own work. A separate B-Team AI (different model, different prompt, hostile persona) attacks the spec at every gate. But teams immersed in months of development share the same blind spots. So we add a Zero-Context Reviewer — an agent that knows nothing about the development, the system architecture, or the business assumptions. It reads the final spec and code as a regulator or auditor would, asking "why does this work this way?" Not to be hostile, but because nobody told it. It surfaces undocumented assumptions, catches things newcomers would find confusing, flags terminology gaps that would stop an auditor cold. In healthcare, this agent mimics the perspective of a compliance officer reading your system for the first time.

**2. Evidence is code, not slides**

At G4, "it works" means: test coverage report, security review sign-off, accessibility audit, integration test against real backend. Not a demo. Not a deck. Artifacts.

**3. 100% test coverage is a gate requirement, not a goal**

When AI writes the code, AI can write the tests. There's no excuse for untested code when your developer never gets tired.

**4. Security is every-gate, not a phase**

G0 classifies risk. G1 defines security requirements. G2/G3 reviews threat model. G4 verifies implementation. G5 penetration tests. No gate passes without security evidence.

**5. The human decides. The AI provides evidence.**

AI builds. AI tests. AI reviews. But the gate decision — go, kill, hold — is human. Always.

---

## How It Worked: A Real Example

**Project:** Native iOS app for medical records requests (HIPAA-regulated, handles PHI)

| Gate | What Happened | Time |
|------|---------------|------|
| **G0** | Problem validated: #1 support call is "where's my request?" | Day 1 |
| **G1** | 13-section spec written. B-Team review: **FAIL** (6 criticals). Fixed. Zero-Context review: PASS (3 clarifications added). Resubmitted. **PASS.** | Day 1 |
| **G2/G3** | 4 iterations of B-Team and Zero-Context adversarial review. 7 ADRs. 18-threat model. Zero findings rejected. | Day 1 |
| **G4** | 53+ tests. Security review: PASS. Accessibility audit: PASS. Integration tests against real API. Zero-Context catches missing error handling documentation. | Day 3 |

Three days from "should we build this?" to a verified, secure, accessible working application — with full audit trail.

**Without governance, that same AI could have produced the same volume of code in 3 hours.** But it would have shipped with a race condition in the submit guard, a missing file upload parameter, and assumptions baked into the code that no regulator could verify.

---

## The Gate Evidence Table

| Gate | Question | Evidence Required | Reviewers |
|------|----------|-------------------|-----------|
| **G0** | Worth doing? | Problem statement, users, risk classification, scope | Product + Director |
| **G1** | Requirements solid? | Testable requirements, API contracts, NFRs, B-Team review, Zero-Context review | Director + B-Team + Zero-Context |
| **G2/G3** | Design safe? | ADRs, threat model, test strategy, 3 Amigos on tickets, Zero-Context assumptions audit | Architect + Security + Zero-Context |
| **G4** | Code works? | 100% coverage, security review, accessibility audit, integration tests, Zero-Context clarity check | Test + Security + Director + Zero-Context |
| **G5** | Safe to ship? | Pen test, rollback plan, monitoring, NFR evidence, full team sign-off, Zero-Context auditor perspective | Everyone |
| **G6** | What did we learn? | Production metrics, incidents, KPI actuals vs. targets | Director + SRE + Journalist |

---

## The Three-Model Review Architecture

```
                     ┌─────────────────────┐
                     │    A-TEAM (Builder)  │
                     │                     │
                     │  • Writes spec      │
                     │  • Builds code      │
                     │  • Runs tests       │
                     │  • Proposes design  │
                     └──────────┬──────────┘
                                │
                          Submits for review
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
        ┌─────────────────────┐  ┌──────────────────────┐
        │   B-TEAM (Critic)   │  │ZERO-CONTEXT REVIEWER │
        │                     │  │                      │
        │  • Different AI     │  │ • Different model    │
        │  • Hostile personas │  │ • No dev knowledge   │
        │  • Domain expert    │  │ • Naive eye          │
        │  • Finds what       │  │ • Auditor/Regulator  │
        │    builders missed  │  │   perspective        │
        │  • CRITICAL/MAJOR/  │  │ • Surfaces hidden    │
        │    MINOR/OBS        │  │   assumptions        │
        └──────────┬──────────┘  │ • Clarifies docs     │
                   │             │ • Flags confusing    │
                   │             │   terminology        │
                   │             └──────────┬───────────┘
                   │                        │
                   └───────────┬────────────┘
                               │
                          Both reviews complete
                               │
                               ▼
                    ┌─────────────────────┐
                    │   A-TEAM Response   │
                    │                     │
                    │  • Accept & fix     │
                    │  • Accept & defer   │
                    │  • Reject (with     │
                    │    evidence only)   │
                    └──────────┬──────────┘
                               │
                         Resubmit until PASS
                               │
                               ▼
                    ┌─────────────────────┐
                    │    GATE DECISION    │
                    │    (Human only)     │
                    │                     │
                    │  GO / KILL / HOLD   │
                    └─────────────────────┘
```

### Why Three Models Matter

**B-Team** finds things that are wrong or incomplete — defects in the implementation, missing test cases, architectural flaws. The B-Team is critical but has context. They know what you were trying to build.

**Zero-Context Reviewer** finds things that are invisible to the B-Team because the B-Team built it. It finds:
- Undocumented assumptions baked into requirements
- Terminology that only makes sense to the team
- Missing failure mode documentation
- Design rationale that's in someone's head but not in ADRs
- Edge cases that everyone missed because they were all thinking the same way

In healthcare, this is the regulatory auditor asking "why is this the way it is?" not because they're hostile, but because they have no context.

**Result:** 4 review iterations. B-Team first review: 6 criticals. Zero-Context first review: 3 clarifications + 2 assumption surfacing. After fixes, B-Team: PASS with 5 minors. Zero-Context: PASS. Every finding accepted. Zero rejected.

---

## Principles

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   1. Patient safety outranks throughput.                    │
│                                                             │
│   2. Evidence, not confidence.                              │
│      "We think it's fine" is not a gate pass.              │
│                                                             │
│   3. The B-Team reviews every gate.                        │
│      Different AI. Different blind spots.                   │
│                                                             │
│   4. Zero-Context reviews every gate.                      │
│      Naive eye catches invisible assumptions.               │
│                                                             │
│   5. AI builds. Humans decide.                             │
│      The gate decision is never automated.                  │
│                                                             │
│   6. 100% test coverage on new code.                       │
│      If AI writes it, AI tests it. No excuses.             │
│                                                             │
│   7. Security is every-gate, not a phase.                  │
│                                                             │
│   8. Accessibility is every-ticket, not a sprint.          │
│                                                             │
│   9. Kill early, kill cheap.                               │
│      A failed gate at G1 costs hours.                      │
│      A failed gate at G5 costs months.                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Why This Matters for Healthcare

Healthcare software has a unique constraint: **you cannot move fast and break things when "things" are patient records.**

Agentic AI removes the speed constraint on building. It does NOT remove the constraint on safety. Stage-Gate provides the structure to let AI build at full speed while humans maintain control over what ships.

The gates aren't bureaucracy. They're the reason we caught:
- A race condition that would have allowed duplicate medical records submissions
- A missing file upload parameter that would have silently dropped patient ID photos
- An unverified certificate pinning implementation that could have exposed PHI in transit
- **A set of undocumented assumptions about patient consent flow that a regulator would have flagged immediately** (caught by Zero-Context Reviewer)

All found before any patient was affected. All found because the gate required evidence, not confidence.

---

## Getting Started

1. **Define your gates.** What questions must be answered before code ships?
2. **Define your evidence.** What artifacts prove the answer? (Not opinions. Artifacts.)
3. **Establish your B-Team.** Who attacks the work? (Must be different from who builds it.)
4. **Establish your Zero-Context Reviewer.** Who reviews as if they know nothing? (Should be a different model/prompt than B-Team.)
5. **Automate what you can.** Coverage reports, security scans, accessibility audits — these are gate evidence that AI can produce.
6. **Keep the decision human.** The go/kill/hold choice is never delegated to the machine.

---

## References

- Cooper, R.G. (1990). "Stage-Gate Systems: A New Tool for Managing New Products." *Business Horizons.* [ResearchGate](https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products)
- Cooper, R.G. (2024). *Winning at New Products: Creating Value Through Innovation.* 5th Edition.
- Cooper, R.G. (2024). "Stage-Gate® is Not Waterfall… Find Out Why & How." [ResearchGate](https://www.researchgate.net/publication/381834441_Stage-GateR_is_Not_Waterfall_Find_Out_Why_How)
- Sopheon (2025). "Stage-Gate – The Origin, Status Quo and Future." [Interview with Cooper](https://www.sopheon.com/blog/stage-gate-the-origin-status-quo-and-its-future/)
- MIT Technology Review (2026). "From Guardrails to Governance: A CEO's Guide for Securing Agentic Systems." [Link](https://www.technologyreview.com/2026/02/04/1131014/from-guardrails-to-governance-agentic-ai/)
- Deloitte (2026). "Health Care Leans Into Agentic AI." [Link](https://www.deloitte.com/us/en/insights/industry/health-care/agentic-ai-health-care-operating-model-change.html)
- IGI Global (2024). "Application of Agile Stage Gate Hybrid Model in the Healthcare Industry." [Link](https://www.igi-global.com/chapter/application-of-agile-stage-gate-hybrid-model-in-the-healthcare-industry/)

---

## The Loop Evolution (v2.0 — July 2026)

### How Loop Engineering Extends the Stage-Gate Model

Stage-Gate governance answers: "Should this ship?" Loop engineering answers: "Can a machine verify this without asking?"

The original model (v1.x) applied human judgment at every decision point. This worked — but it created a bottleneck. Mechanical tasks (running tests, verifying data consistency, checking build status) don't need human judgment. They need a verifier.

v2.0 introduces the **loop layer** — automated execution with automated verification that runs between gates, continuously, without human intervention. Gates still govern judgment. Loops handle execution.

### The Three-Layer Architecture

```
                ┌─────────────────────────────────────┐
                │          HUMAN LAYER                 │
                │  Goals · Decisions · Gate Approvals  │
                │  (5 minutes per decision)            │
                └──────────────────┬──────────────────┘
                                   │ defines
                ┌──────────────────▼──────────────────┐
                │          GATE LAYER                  │
                │  Personas · Adversarial Review       │
                │  Compliance · Architecture           │
                │  (30 minutes per review)             │
                └──────────────────┬──────────────────┘
                                   │ governs
                ┌──────────────────▼──────────────────┐
                │          LOOP LAYER                  │
                │  Build · Test · Deploy · Verify      │
                │  ETL · Migration · Optimization      │
                │  (Runs overnight — or continuously)  │
                └─────────────────────────────────────┘
```

Each task finds its correct altitude:
- **Judgment tasks** → Gate Layer (design decisions, compliance interpretation, architecture)
- **Mechanical tasks** → Loop Layer (test execution, data verification, build checks, refactoring)
- **Strategic tasks** → Human Layer (priorities, trade-offs, go/kill/hold)

### The 41,800:1 Automation Ratio

In production use across 199 MIPS measure engines and 3 organizations:
- **1 human decision** (approve the measure logic) enables
- **41,800 automated verifications** (engine runs × org × measure × verification type)

The gates ensured the logic was correct. The loops ensured it STAYED correct across every execution, every organization, every data refresh — without a human re-approving each run.

This is the power of the hybrid model: invest judgment once at the gate, then let loops verify continuously at near-zero marginal cost.

### What This Doesn't Replace

Loop engineering does NOT replace gates. It augments them.

| Still Requires Gates | Now Handled by Loops |
|---------------------|---------------------|
| "Is this the right approach?" | "Does the build pass?" |
| "Is this HIPAA compliant?" | "Do all tests pass after this change?" |
| "Should we ship this?" | "Is the data consistent across all orgs?" |
| "Is this architecture sound?" | "Did performance regress?" |
| "Does this meet the CMS spec?" | "Are all 199 engines producing output?" |

The question isn't "gates or loops?" — it's "which tasks belong where?" The three-question framework (Can a machine verify it? Is it bounded? Is failure recoverable?) makes the distinction mechanical.

### Integration with Existing Governance

The loop layer integrates with every gate:
- **G0:** Loops detect duplicate proposals and validate scope against history
- **G1:** Loops verify requirement completeness and glossary consistency
- **G2/G3:** Loops catch architecture drift and dependency vulnerabilities
- **G4:** Loops run continuous test execution and coverage enforcement
- **G5:** Loops verify rollback plans and monitoring configuration
- **G6:** Loops monitor production KPIs and detect degradation

Between every gate, G-LOOP runs: automated verification that catches drift, maintains consistency, and alerts on anomalies — without waiting for a human to ask.

---

*Built with AI. Governed by humans. Verified by evidence. Looped for confidence.*

---

**Author:** Douglas Jones | Sharecare Health Data Services
**Date:** May 2026 (v1.0), July 2026 (v2.0 — Loop Evolution)
