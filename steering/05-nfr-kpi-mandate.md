---
inclusion: auto
---

# NFRs, KPIs, and Benchmarks Are Mandatory

## Rule

Every initiative that reaches G1 MUST include measurable targets. If you can't measure it, you can't ship it.

---

## What's Required

### NFRs (Non-Functional Requirements)
Technical performance targets with pass/fail thresholds.

**Format:**
| ID | Metric | Target | Measurement Method | Gate |
|----|--------|--------|--------------------|------|
| NFR-PERF-001 | Page load time | < 2s (P95) | Lighthouse CI | G4 |
| NFR-SEC-001 | Vulnerability scan | 0 critical, 0 high | OWASP ZAP | G5 |

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
