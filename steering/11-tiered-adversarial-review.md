---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Tiered Adversarial Review — Scaling B-Team for Daily Deployment

The full 12-persona B-Team review takes ~30 minutes and produces comprehensive adversarial coverage. For teams deploying daily or multiple times per day, running that full review on every change creates a bottleneck that pushes teams back toward quarterly batching.

This steering file defines a risk-tiered review model that maintains security rigor while enabling high-velocity deployment.

---

## The Problem

**Full B-Team on every PR:** Comprehensive but slow. Teams batch changes to avoid review overhead, which defeats the purpose of continuous deployment.

**No B-Team:** Fast but dangerous. Logic-level vulnerabilities, missing authorization checks, and business rule violations ship to production undetected.

**The solution:** Match review depth to change risk. Low-risk changes get automated verification. High-risk changes get full adversarial scrutiny. The system stays safe AND fast.

---

## Three Review Tiers

### Tier 1: Auto-Pass (Loop Verification Only)

**No B-Team review required.** G-LOOP verifiers are sufficient.

**Criteria (ALL must be true):**
- Change touches only code with existing test coverage >= 95%
- No new files created in security-sensitive paths (auth, crypto, permissions, data access)
- No dependency additions or version changes
- No API surface changes (endpoints, request/response schemas)
- No infrastructure changes (IaC, Docker, CI/CD config)
- Change is a bug fix, refactor, documentation update, or UI polish
- All automated checks pass (build, test, lint, SAST, SCA)

**Verifiers required:**
- Full test suite passes
- Coverage threshold maintained
- SAST scan clean
- SCA scan clean
- Build compiles
- No new warnings introduced

**Deployment:** Same day. Merge when verifiers pass.

**Examples:**
- Fixing a typo in a UI label
- Refactoring a function for readability (tests unchanged)
- Updating documentation
- CSS/styling changes
- Adding tests to existing code
- Dependency patch version bump (no behavioral change, no CVE)

---

### Tier 2: Focused Review (3-Persona B-Team)

**Lightweight adversarial review.** Three security-relevant personas evaluate the change.

**Criteria (ANY triggers Tier 2):**
- Change touches authentication, authorization, or session management
- Change modifies data access patterns or query logic
- Change adds or modifies an API endpoint
- Change introduces a new dependency
- Change modifies error handling in security-sensitive paths
- Change affects data validation or sanitization
- AI-generated code touching any of the above

**Personas activated:**

| Persona | Focus |
|---------|-------|
| **Cipher** (Offensive Security) | Attack paths, injection vectors, privilege escalation |
| **Jett** (Code Surgeon) | Logic bugs, race conditions, state management errors |
| **Blaze** (QA Destroyer) | Test adequacy — do the tests actually prove correctness? |

**Review format (abbreviated):**

```markdown
## Tier 2 Focused Review

### Cipher (Security)
- [ ] No new injection vectors introduced
- [ ] Authorization checks present on all new/modified endpoints
- [ ] Input validation covers edge cases
- [ ] Error messages don't leak internal state
- Findings: [CRITICAL/MAJOR/MINOR/NONE]

### Jett (Logic)
- [ ] State transitions are correct and complete
- [ ] Race conditions addressed (concurrent access paths)
- [ ] Edge cases handled (null, empty, overflow, boundary)
- [ ] No silent failures in critical paths
- Findings: [CRITICAL/MAJOR/MINOR/NONE]

### Blaze (Testing)
- [ ] Tests cover the change's failure modes, not just happy path
- [ ] Negative tests present (invalid input, unauthorized access)
- [ ] Integration points tested (not just unit-level mocking)
- Findings: [CRITICAL/MAJOR/MINOR/NONE]

### Verdict: [PASS / PASS WITH CONDITIONS / FAIL]
```

**Time budget:** 10-15 minutes.

**Deployment:** Same day if PASS. Next day if conditions need resolution.

**Examples:**
- Adding a new REST endpoint
- Modifying a database query in a service layer
- Adding role-based access to a feature
- Introducing a new npm/pip package
- Fixing a security vulnerability (looped remediation gets Tier 2 verification)

---

### Tier 3: Full Review (12-Persona B-Team)

**Comprehensive adversarial review.** All 12 personas plus optional Zero-Context Reviewer.

**Criteria (ANY triggers Tier 3):**
- New feature or initiative (G1 and beyond per governance gates)
- Architectural change (new service, new data store, new integration)
- Change to encryption, key management, or certificate handling
- Change to infrastructure-as-code affecting production
- Compliance-relevant change (data handling, consent, audit trails)
- Change affecting > 500 lines across > 5 files
- Any change the Security Lead flags for full review
- Novel AI integration (new model, new agent capability, new data flow to/from AI)

**Full B-Team per `04-adversarial-review.md`:**
All 12 personas (Vex, Kade, Noor, Rook, Cipher, Jett, Blaze, Wren, Slate, Ember, Volt, Ink)

**Time budget:** 30 minutes.

**Deployment:** Next deployment window after PASS. Not same-day unless emergency.

**Examples:**
- Implementing a new permission system
- Adding a microservice
- Integrating with a new external API
- Database migration affecting production data
- Any HIPAA/SOC2/PCI-relevant change
- Deploying a new AI agent with autonomous capabilities

---

## Tier Classification Decision Tree

```
START
│
├── Does the change touch auth, crypto, permissions, or data access?
│   ├── YES → Is it architectural (new system, new service, new pattern)?
│   │   ├── YES → TIER 3
│   │   └── NO → TIER 2
│   └── NO ↓
│
├── Does the change add/modify API endpoints or dependencies?
│   ├── YES → TIER 2
│   └── NO ↓
│
├── Does the change affect > 500 lines or > 5 files?
│   ├── YES → Is it a refactor with no behavioral change?
│   │   ├── YES → TIER 1 (if tests unchanged and passing)
│   │   └── NO → TIER 3
│   └── NO ↓
│
├── Does the change modify infrastructure or CI/CD?
│   ├── YES → TIER 2 (TIER 3 if production-affecting)
│   └── NO ↓
│
├── Is the change purely test, docs, refactor, or UI polish?
│   ├── YES → TIER 1
│   └── NO ↓
│
└── DEFAULT → TIER 2 (when in doubt, get focused review)
```

---

## Automated Tier Assignment

G-LOOP can auto-assign tier based on file paths and change characteristics:

```
TIER 3 triggers (file path patterns):
- */auth/*
- */crypto/*
- */encryption/*
- */infrastructure/*
- */terraform/*
- */migrations/* (production schema changes)
- docker-compose.prod.yml
- *.iac.*
- Any file flagged in threat model

TIER 2 triggers (file path patterns):
- */controllers/*
- */routes/*
- */middleware/*
- */services/* (if modifying query logic)
- */validators/*
- package.json, requirements.txt, pom.xml (dependency changes)
- Dockerfile

TIER 1 (everything else that passes all automated checks):
- */components/* (UI)
- */styles/*
- */tests/*
- *.md
- *.css / *.scss
- Refactoring tools report "no behavioral change"
```

### Override Rules

- Security Lead can escalate any change to a higher tier
- An agent (AI) modifying security-sensitive code auto-escalates one tier
- Three consecutive Tier 1 changes to the same module within 24 hours triggers Tier 2 review of the combined diff
- Any change that fails automated checks cannot remain Tier 1 (minimum Tier 2)

---

## B-Team Availability for Daily Deployment

### Model Rotation for Speed

To avoid B-Team review becoming a bottleneck:

| Tier | Model Options | Latency |
|------|---------------|---------|
| Tier 2 | o3, Qwen3, DeepSeek-R1 (any available) | < 5 min |
| Tier 3 | Primary: o3 or Qwen3. Secondary: different model family for Zero-Context | < 30 min |

**Rule:** B-Team model must differ from the model that wrote the code. If Claude wrote it, review with o3 or Qwen3. If GPT-4o wrote it, review with Claude or Qwen3.

### Parallel Review

For Tier 3 reviews, run personas in parallel (not sequential):
- **Batch 1:** Cipher + Jett + Blaze (security + logic + testing) — most likely to find CRITICALs
- **Batch 2:** Rook + Wren + Slate (architecture + privacy + ops) — structural concerns
- **Batch 3:** Vex + Kade + Noor + Ember + Volt + Ink (broad coverage) — completeness

If Batch 1 finds CRITICALs, stop and fix before running Batch 2/3. This saves review time on code that will change.

---

## Metrics

| Metric | Target | Why |
|--------|--------|-----|
| % changes at Tier 1 | 60-70% | Most daily changes should be low-risk |
| % changes at Tier 2 | 20-30% | Focused review for moderate risk |
| % changes at Tier 3 | 5-15% | Full review reserved for significant changes |
| Mean review time (Tier 2) | < 15 min | Must not bottleneck daily deployment |
| Mean review time (Tier 3) | < 45 min | Acceptable for significant changes |
| Tier 1 escape rate | < 1% | Changes that should have been Tier 2+ but weren't caught |
| False escalation rate | < 10% | Changes escalated unnecessarily (review finds nothing) |

### Calibration

Review tier distribution monthly:
- If > 40% of changes are Tier 3: your classification is too aggressive (slowing deployment)
- If Tier 1 escape rate > 1%: your classification is too permissive (shipping risks)
- If Tier 2 reviews consistently find nothing: consider relaxing those triggers to Tier 1

---

## Integration with Security Remediation SLA

Per `09-security-remediation-sla.md`:

| Remediation Type | Review Tier | Rationale |
|---|---|---|
| Dependency bump (CVE fix, no behavioral change) | Tier 1 | Automated verification sufficient |
| Code fix for SAST finding (known pattern) | Tier 2 | Focused review confirms fix correctness |
| Architectural remediation | Tier 3 | Full review — structural change |
| Novel vulnerability class | Tier 3 | No existing pattern to verify against |

---

## Relationship to Other Steering Files

- **01-governance-gates.md** — Tier 3 = full gate review. Tier 2 = focused gate. Tier 1 = G-LOOP only.
- **04-adversarial-review.md** — Defines the full B-Team process (Tier 3). This file extends it with Tier 1/2.
- **08-loop-engineering.md** — Tier 1 changes are fully loopable. Tier 2 adds a lightweight gate. Tier 3 is a full gate.
- **09-security-remediation-sla.md** — Remediation routing uses tiers to maintain velocity.
- **10-supply-chain-verification.md** — Dependency changes auto-trigger minimum Tier 2.

---

*Tiered Adversarial Review v1.0 — July 2026*
