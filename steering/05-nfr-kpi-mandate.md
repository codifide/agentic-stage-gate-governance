---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# NFRs, KPIs, and Benchmarks Are Mandatory

## Rule

Every initiative that reaches G1 MUST include measurable targets. If you can't measure it, you can't ship it.

---

## What's Required

### NFRs (Non-Functional Requirements)
Technical performance targets with pass/fail thresholds.

Use `templates/NFR-TEMPLATE.md` as your starting point. It covers:
- Performance (latency tiers: cold, warm, cached)
- Accuracy / Correctness (for AI/ML, rule engines, data pipelines)
- Reliability (success rate, error rate, graceful degradation)
- Security (transport, secrets, auth, PII, rate limiting)
- Accessibility (labels, contrast, tap targets, screen reader)
- Scalability (concurrent users, data volume)

**Format:**
| ID | Metric | Target | Measurement Method | Gate |
|----|--------|--------|--------------------|------|
| NFR-PERF-001 | Page load time | < 2s (P95) | Lighthouse CI | G4 |
| NFR-SEC-001 | Vulnerability scan | 0 critical, 0 high | OWASP ZAP | G5 |

**Key guidance from field experience:**
- Define separate targets for cold (no cache) and warm (cache hit) paths — they differ by 3–10×
- Wire measurable NFRs into the test suite as hard CI assertions — don't rely on manual checks alone
- Parity tests (known input → known output) are the most reliable accuracy gate
- "Graceful degradation" must be specific: what does the user see when a dependency is down?
- Accessibility is a G4 gate item, not a post-launch nice-to-have

### KPIs (Key Performance Indicators)
Business/product outcome targets.

**Format:**
| ID | Metric | Baseline | Target | Measurement | Owner |
|----|--------|----------|--------|-------------|-------|
| KPI-001 | Task completion rate | 65% (current) | 85% | Analytics | Product |

### Benchmarks
Baseline comparisons (old vs. new, competitor vs. us).

**Format:**
| ID | Comparison | Current | Target | When Measured |
|----|-----------|---------|--------|---------------|
| BM-001 | Form completion time (web vs. native) | 12 min | 5 min | Post-Phase 2 |

---

## Ownership

| Category | Defines | Measures | Enforces |
|----------|---------|----------|----------|
| NFRs | Forge (Performance) | CI/CD pipeline | Build gates |
| KPIs | Harper (Product) | Analytics | Release go/no-go |
| Benchmarks | Forge + Tessa | Side-by-side testing | Phase gate evidence |

---

## Enforcement

- **G1 will not pass** without NFRs, KPIs, and Benchmarks defined
- **G4 will not pass** without NFR evidence (test results, not promises)
- **G5 will not pass** without KPI baseline collected or measurement plan documented
- **G6 requires** KPI actuals vs. targets comparison

---

## Automated vs. Manual Evidence

| NFR type | Approach |
|----------|----------|
| In-process latency (rule engine, parser) | Benchmark test with p95 assertion in CI |
| End-to-end latency (network involved) | Manual stopwatch + server log evidence |
| Correctness on known cases | Parity/regression test suite in CI |
| Field accuracy | Structured field test with known ground truth |
| Graceful degradation | Mock dependency in test + assert fallback behavior |
| Rate limiting | Assert correct HTTP status code (e.g. 429) in CI |
| Accessible labels | UI test assertion in CI |
| VoiceOver completability | Manual walkthrough with documented notes |
| Color contrast | Accessibility Inspector screenshots |

The goal: automate everything automatable. Manual evidence is for things that genuinely require a human or a deployed environment.
