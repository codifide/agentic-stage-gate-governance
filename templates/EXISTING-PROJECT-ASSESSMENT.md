# Existing Project Assessment Template

## Purpose

Use this template when applying stage-gate governance to a project that already has working code. Instead of starting from G0, you assess where the project currently stands and identify gaps to close.

---

## Instructions

1. Copy this template into your project's `docs/` directory
2. For each gate, search the codebase for existing evidence
3. Classify each gate as PASS, PARTIAL, or NOT_STARTED
4. Produce a prioritized remediation sequence
5. Close gaps in priority order — don't retroactively gate everything

---

## Assessment Methodology

- **Evidence-based** — only artifacts that exist in the repository count
- **Status definitions:**
  - **PASS** — all required evidence artifacts for that gate are present and current
  - **PARTIAL** — at least one but not all required evidence artifacts exist
  - **NOT_STARTED** — no required evidence artifacts exist in gate format
- **Risk classification:** HIGH / MEDIUM / LOW per domain
- **Priority levels:**
  - **P0-Critical** — blocks launch, affects user safety
  - **P1-High** — significant risk, must address before release
  - **P2-Medium** — improvement needed, can be scheduled
  - **P3-Low** — documentation-only, nice to have
- **Effort estimates:** <1 day / 1–3 days / 4–10 days / >10 days

---

## Gate Status Matrix

| Gate | Status | Risk Level | Gap Count | Blocking Launch? |
|------|--------|-----------|-----------|-----------------|
| **G0** | | | | |
| **G1** | | | | |
| **G2/G3** | | | | |
| **G4** | | | | |
| **G5** | | | | |
| **G6** | | | | |

---

## Gate-by-Gate Assessment

### G0 — Problem Statement

**Status:** [PASS / PARTIAL / NOT_STARTED]

#### Existing Evidence

| Artifact | Location | Date Updated |
|----------|----------|-------------|
| | | |

#### Missing Evidence

| Artifact | Effort | Priority |
|----------|--------|----------|
| | | |

#### Assessment Notes

[What exists, what's missing, what's the gap]

---

### G1 — Requirements & Evidence

**Status:** [PASS / PARTIAL / NOT_STARTED]

#### Existing Evidence

| Artifact | Location | Date Updated |
|----------|----------|-------------|

#### Missing Evidence

| Artifact | Effort | Priority |
|----------|--------|----------|

---

### G2/G3 — Design & Architecture

**Status:** [PASS / PARTIAL / NOT_STARTED]

#### Existing Evidence

| Artifact | Location | Date Updated |
|----------|----------|-------------|

#### Missing Evidence

| Artifact | Effort | Priority |
|----------|--------|----------|

---

### G4 — Build & Verify

**Status:** [PASS / PARTIAL / NOT_STARTED]

#### Existing Evidence

| Artifact | Location | Date Updated |
|----------|----------|-------------|

#### Missing Evidence

| Artifact | Effort | Priority |
|----------|--------|----------|

---

### G5 — Release Readiness

**Status:** [PASS / PARTIAL / NOT_STARTED]

#### Existing Evidence

| Artifact | Location | Date Updated |
|----------|----------|-------------|

#### Missing Evidence

| Artifact | Effort | Priority |
|----------|--------|----------|

---

### G6 — Post-Release Review

**Status:** [NOT_STARTED — expected for pre-launch projects]

---

## Risk Assessment

| Domain | Level | Rationale |
|--------|-------|-----------|
| Security | | |
| Data Handling | | |
| User Safety | | |

---

## Remediation Sequence

Order by: priority (P0→P3), then effort ascending within same priority.

| # | Gap | Gate | Priority | Effort | Dependency |
|---|-----|------|----------|--------|-----------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

---

## Recommended Execution Order

1. **Immediate (this week):** [low effort, high value items]
2. **Short-term (next 2 weeks):** [moderate effort, required for launch]
3. **Before release (next month):** [higher effort, gate-blocking]

---

*Assessment conducted: [date]*
*Methodology: Evidence-based evaluation against governance gates*
