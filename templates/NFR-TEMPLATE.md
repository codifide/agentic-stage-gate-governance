# Non-Functional Requirements Template

## How to Use

1. Copy this file into your project's `docs/` directory as `NFRS.md`
2. Replace all `[placeholder]` values with project-specific targets
3. Delete categories that don't apply to your project
4. Mark automated assertions in the test suite — these become hard CI gate blocks
5. Reference this document from your `GATE_EVIDENCE_CHECKLIST.md`

**Rule:** Every initiative that reaches G1 MUST have NFRs defined with measurable targets.
If you can't measure it, you can't ship it. (See `steering/05-nfr-kpi-mandate.md`)

---

## Overview

These are measurable performance targets that must be met before the relevant gate can pass.
Each NFR has a pass/fail threshold and a measurement method.
Items marked **[GATE-BLOCKING]** must have passing evidence before the gate closes.

---

## Performance

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-PERF-001 | [Primary user action] end-to-end latency (p95) | ≤ [Xs] | [measurement method] | G4 |
| NFR-PERF-002 | [Cached/repeat action] latency (p95) | ≤ [Xs] | [measurement method] | G4 |
| NFR-PERF-003 | [API endpoint] response time (p95) | ≤ [Xs] | [measurement method] | G4 |
| NFR-PERF-004 | [Background job / batch process] completion | ≤ [Xs] | [measurement method] | G4 |
| NFR-PERF-005 | [Cold start / launch] to interactive | ≤ [Xs] | [measurement method] | G4 |

**Guidance:**
- Define separate targets for cold (no cache) and warm (cache hit) paths — they differ by 3–10×
- P95 is the right percentile for user-facing latency; P99 for SLA commitments
- Measure at the user's device/browser, not at the server — network is part of the experience
- Hard timeouts in code must be ≤ your NFR target, not greater

---

## Accuracy / Correctness

*Use this section for AI/ML systems, rule engines, data pipelines, or any system where output correctness is a first-class concern.*

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-ACC-001 | [Model/rule] confidence on [standard input] | ≥ [X]% | [measurement method] | G4 |
| NFR-ACC-002 | Correct output rate on known test cases | ≥ [X]% | [parity/regression test suite] | G4 |
| NFR-ACC-003 | False positive rate ([specific case]) | < [X]% | [measurement method] | G5 |
| NFR-ACC-004 | Refusal / low-confidence rate | < [X]% | [production analytics] | G6 |

**Guidance:**
- Parity tests (known input → known output) are the most reliable accuracy gate
- Separate "correctness on known cases" (G4, automated) from "field accuracy" (G4/G5, manual)
- False positive rate often requires production data — plan for G5/G6 measurement
- If your system has permit/exception logic, test that exceptions don't suppress the base restriction

---

## Reliability

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-REL-001 | Success rate on primary user action | ≥ [X]% | [measurement method] | G4 |
| NFR-REL-002 | Server 5xx error rate | < [X]% | [log/monitoring tool] | G4 |
| NFR-REL-003 | Graceful degradation on dependency outage | [specific behavior] | [automated test] | G4 |
| NFR-REL-004 | API uptime | ≥ [X]% monthly | [uptime monitor] | G5 |
| NFR-REL-005 | Crash-free session rate | ≥ [X]% | [crash reporting tool] | G5 |
| NFR-REL-006 | Offline / degraded-network behavior | [specific behavior] | Manual test | G4 |

**Guidance:**
- "Graceful degradation" must be specific: what does the user see? What data is preserved?
- Test the outage path in CI — mock the dependency and assert the fallback behavior
- Crash-free rate requires production data; plan for G5 measurement
- Rate limiting must return clean error codes (e.g. 429), not 500s

---

## Security

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-SEC-001 | Transport security (HTTPS/TLS) | 100% of connections | [audit method] | G4 |
| NFR-SEC-002 | No secrets in client bundle / repository | 0 hardcoded secrets | [automated scan] | G4 |
| NFR-SEC-003 | Authentication coverage | 100% of protected endpoints | [code review / test] | G4 |
| NFR-SEC-004 | PII handling — [specific data type] | [specific requirement] | [audit method] | G4 |
| NFR-SEC-005 | Rate limiting on [sensitive endpoint] | [limit] enforced cleanly | [automated test] | G4 |
| NFR-SEC-006 | Vulnerability scan | 0 critical, 0 high | [scan tool] | G5 |

**Guidance:**
- Secrets scanning should run in CI on every commit — not just at gate time
- PII requirements must be specific: what data, where stored, how long retained, who can access
- Rate limiting tests should assert the correct HTTP status code, not just "doesn't crash"
- Certificate pinning (if used) must have a rotation plan — document it

---

## Accessibility

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-A11Y-001 | All interactive elements have accessible labels | 100% | [automated test] | G4 |
| NFR-A11Y-002 | Minimum tap/click target size | [44×44pt / 24×24px] | Manual check | G4 |
| NFR-A11Y-003 | Color contrast — normal text | ≥ 4.5:1 | [accessibility tool] | G4 |
| NFR-A11Y-004 | Color contrast — large text | ≥ 3:1 | [accessibility tool] | G4 |
| NFR-A11Y-005 | Screen reader completability — primary flows | 100% | Manual walkthrough | G4 |
| NFR-A11Y-006 | Text scaling support | [range] | Visual inspection | G4 |

**Guidance:**
- Automated label checks catch the most common failures cheaply — wire them into UI tests
- Manual VoiceOver/screen reader walkthrough is required — automated tools miss ~40% of issues
- WCAG 2.1 AA is the baseline; document any intentional deviations with rationale
- Accessibility is a G4 gate item, not a post-launch nice-to-have

---

## Scalability

*Include only if your system has meaningful scale requirements at launch or within 12 months.*

| ID | Metric | Target | Measurement | Gate |
|----|--------|--------|-------------|------|
| NFR-SCALE-001 | Concurrent users without degradation | [N] simultaneous | [load test tool] | G5 |
| NFR-SCALE-002 | Data volume without query degradation | [N] records | [query timing at scale] | G5 |
| NFR-SCALE-003 | [Specific bottleneck] throughput | [N] req/s | [load test] | G5 |

**Guidance:**
- Scale NFRs are typically G5 (release readiness), not G4 — you need a deployed environment
- Define "degradation" precisely: what metric degrades, by how much, at what load
- Load tests should simulate realistic user behavior, not just raw request volume

---

## Automated Gate Assertions

Wire measurable NFRs into your test suite. A CI failure on any of these is a hard gate block.

| NFR | Test file | Assertion |
|-----|-----------|-----------|
| NFR-PERF-[X] | `[test file]` | [specific assertion] |
| NFR-ACC-[X] | `[test file]` | [specific assertion] |
| NFR-REL-[X] | `[test file]` | [specific assertion] |
| NFR-SEC-[X] | `[test file]` | [specific assertion] |
| NFR-A11Y-[X] | `[test file]` | [specific assertion] |

**Which NFRs should be automated:**
- Rule engine / evaluator correctness → parity test suite
- Graceful degradation → mock dependency + assert fallback
- Rate limiting → assert 429 status code
- Accessible labels → UI test assertion
- In-process latency → benchmark test with p95 assertion

**Which NFRs require manual evidence:**
- End-to-end latency (network involved) → stopwatch + log evidence
- Field accuracy → structured field test with known ground truth
- VoiceOver completability → manual walkthrough with notes
- Color contrast → Accessibility Inspector screenshots

---

## Measurement Schedule

| Gate | NFRs Due |
|------|----------|
| G1 | NFRs defined with targets (this document exists and is complete) |
| G4 | All Performance, Accuracy (known cases), Reliability (automated), Security, Accessibility |
| G5 | Availability, Crash-free rate, Scalability, Vulnerability scan, Field accuracy |
| G6 | Production actuals vs. targets (requires live data) |

---

## Evidence Format

For each NFR requiring manual evidence, record:

```
NFR-[ID]: [metric name]
Target: [threshold]
Result: [actual value]
Date: [YYYY-MM-DD]
Method: [how measured]
Pass/Fail: [PASS / FAIL]
Notes: [any context]
```

---

*Template version: 1.0 — May 2026*
*Derived from: decode the sign v1.0 NFR gate experience*
*Persona: Forge (Performance Engineer)*
