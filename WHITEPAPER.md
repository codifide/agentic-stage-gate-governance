# Stage-Gate Rebooted: How We Govern AI-Powered Development in Healthcare

**When your developer is an AI agent, who watches the gates?**

---

## The Problem No One Talks About

Agentic AI can write code faster than any human team. It can produce 50 files in an hour, refactor entire architectures in a session, and generate test suites that hit 95% coverage before lunch.

But speed without governance is just faster failure.

In healthcare software — where a bug isn't a broken button but a misdirected medical record — the question isn't *"can AI build it?"* It's *"should this ship?"*

We took Robert Cooper's Stage-Gate® framework (1986), stripped it to its core principle — **evidence, not confidence** — and rebuilt it for a world where AI agents do the building and humans do the deciding.

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

80% of product development organizations use some form of Stage-Gate ([PDMA Best Practices Study](https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products)). It works. But it was designed for physical products with 18-month development cycles and human-only teams.

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

**1. Adversarial B-Team at every gate**

We don't let the builder review their own work. A separate AI (different model, different prompt, hostile persona) attacks the spec at every gate. Our B-Team found 6 critical flaws that the building team missed — including physically impossible storage claims and unimplementable security architecture.

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
| **G1** | 13-section spec written. External AI review: **FAIL** (6 criticals). Fixed. Resubmitted. **PASS.** | Day 1 |
| **G2/G3** | 4 iterations of external adversarial review. 7 ADRs. 18-threat model. Zero findings rejected. | Day 1 |
| **G4** | 53+ tests. Security review: PASS. Accessibility audit: PASS. Integration tests against real API. | Day 3 |

Three days from "should we build this?" to a verified, secure, accessible working application — with full audit trail.

**Without governance, that same AI could have produced the same volume of code in 3 hours.** But it would have shipped with a race condition in the submit guard, a missing file upload parameter, and no certificate pinning verification. We know because we caught all three during self-review.

---

## The Gate Evidence Table

| Gate | Question | Evidence Required | Who Decides |
|------|----------|-------------------|-------------|
| **G0** | Worth doing? | Problem statement, users, risk classification, scope | Product + Director |
| **G1** | Requirements solid? | Testable requirements, API contracts, NFRs, B-Team review | Director + B-Team |
| **G2/G3** | Design safe? | ADRs, threat model, test strategy, 3 Amigos on tickets | Architect + Security |
| **G4** | Code works? | 100% coverage, security review, accessibility audit, integration tests | Test + Security + Director |
| **G5** | Safe to ship? | Pen test, rollback plan, monitoring, NFR evidence, full team sign-off | Everyone |
| **G6** | What did we learn? | Production metrics, incidents, KPI actuals vs. targets | Director + SRE + Journalist |

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
│   4. AI builds. Humans decide.                             │
│      The gate decision is never automated.                  │
│                                                             │
│   5. 100% test coverage on new code.                       │
│      If AI writes it, AI tests it. No excuses.             │
│                                                             │
│   6. Security is every-gate, not a phase.                  │
│                                                             │
│   7. Accessibility is every-ticket, not a sprint.          │
│                                                             │
│   8. Kill early, kill cheap.                               │
│      A failed gate at G1 costs hours.                      │
│      A failed gate at G5 costs months.                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## The Adversarial B-Team Model

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
                               ▼
                    ┌─────────────────────┐
                    │   B-TEAM (Critic)   │
                    │                     │
                    │  • Different AI     │
                    │  • Hostile personas │
                    │  • Finds what       │
                    │    builders missed  │
                    │  • CRITICAL/MAJOR/  │
                    │    MINOR/OBS        │
                    └──────────┬──────────┘
                               │
                         Findings returned
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

In our implementation, the B-Team is a different AI model (we used ChatGPT o3 as adversary while Claude built). The B-Team plays 12 hostile personas: security red-teamer, FDA reviewer, accessibility advocate, performance skeptic, privacy hawk, and more.

**Result:** 4 review iterations. First review returned FAIL with 6 criticals. Final review: PASS with 5 minors. Every finding accepted. Zero rejected.

---

## Why This Matters for Healthcare

Healthcare software has a unique constraint: **you cannot move fast and break things when "things" are patient records.**

Agentic AI removes the speed constraint on building. It does NOT remove the constraint on safety. Stage-Gate provides the structure to let AI build at full speed while humans maintain control over what ships.

The gates aren't bureaucracy. They're the reason we caught:
- A race condition that would have allowed duplicate medical records submissions
- A missing file upload parameter that would have silently dropped patient ID photos
- An unverified certificate pinning implementation that could have exposed PHI in transit

All found before any patient was affected. All found because the gate required evidence, not confidence.

---

## Getting Started

1. **Define your gates.** What questions must be answered before code ships?
2. **Define your evidence.** What artifacts prove the answer? (Not opinions. Artifacts.)
3. **Establish your B-Team.** Who attacks the work? (Must be different from who builds it.)
4. **Automate what you can.** Coverage reports, security scans, accessibility audits — these are gate evidence that AI can produce.
5. **Keep the decision human.** The go/kill/hold choice is never delegated to the machine.

---

## References

- Cooper, R.G. (1990). "Stage-Gate Systems: A New Tool for Managing New Products." *Business Horizons.* [ResearchGate](https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products)
- Cooper, R.G. (2024). *Winning at New Products: Creating Value Through Innovation.* 5th Edition.
- Cooper, R.G. (2024). "Stage-Gate® is Not Waterfall… Find Out Why & How." [ResearchGate](https://www.researchgate.net/publication/381834441_Stage-GateR_is_Not_Waterfall_Find_Out_Why_How)
- Sopheon (2025). "Stage-Gate – The Origin, Status Quo and Future." [Interview with Cooper](https://www.sopheon.com/blog/stage-gate-the-origin-status-quo-and-its-future/)
- MIT Technology Review (2026). "From Guardrails to Governance: A CEO's Guide for Securing Agentic Systems." [Link](https://www.technologyreview.com/2026/02/04/1131014/from-guardrails-to-governance-a-ceos-guide-for-securing-agentic-systems)
- Deloitte (2026). "Health Care Leans Into Agentic AI." [Link](https://www.deloitte.com/us/en/insights/industry/health-care/agentic-ai-health-care-operating-model-change.html)
- IGI Global (2024). "Application of Agile Stage Gate Hybrid Model in the Healthcare Industry." [Link](https://www.igi-global.com/chapter/application-of-agile-stage-gate-hybrid-model-in-the-healthcare-industry/348482)

---

*Built with AI. Governed by humans. Verified by evidence.*

---

**Author:** Douglas Jones | Sharecare Health Data Services
**Date:** May 2026
