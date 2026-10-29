---
inclusion: auto
name: sgl-adversarial-review
description: How to prepare, run, and respond to an independent SGL B-Team adversarial review - review packages, reviewer model selection, data handling before sending code to an external model, A-Team response protocol, verdicts, and findings tracking. Load when a B-Team review is requested or required.
# For non-Kiro tools, load this file on demand when a review is needed.
---

# Adversarial Review Process

**When review is required** is defined once, in `00-welcome.md` §3 (gate reviews by track) and `11-tiered-adversarial-review.md` (change reviews by Review Level). This file defines **how** to run one.

---

## The Rule

The builder cannot review their own work. B-Team review runs in a **separate context** that has not seen the builder's reasoning, using a **different model family when one is available**.

- Same context, same prompt: **never** acceptable. This includes the builder "putting on the B-Team hat."
- Same model family, isolated context: acceptable only when no other family is available. Withhold the builder's rationale until first-pass findings are in, label the review `same-family`, and have the Human Steward acknowledge it.
- No independent reviewer reachable: **prepare the package, tell the human, and stop.** The review is not done.

Model diversity reduces correlated reasoning failures; it does not eliminate them. Evidence and human judgment remain required.

---

## Data Handling Before You Send Anything

A review package leaves your environment. Before sending it to any external model:

1. **Check the provider is approved for the data class.** PHI requires a provider under a BAA (or equivalent). Restricted or proprietary code may require a self-hosted model. Record the provider and data class in the review record.
2. **Never include secrets, credentials, or real PHI/PII.** Use synthetic fixtures. Scan the package with your secret scanner before sending.
3. **Send the minimum.** The diff plus the context needed to judge it, not the whole repository, unless the review requires it and the provider is approved for it.
4. Self-hosted open-weight models (e.g., Qwen3, DeepSeek-R1 run locally) avoid egress entirely and are a good default for sensitive codebases.

---

## Choosing a Reviewer Model

Prefer a reasoning model from a **different family than the builder**. Reasoning models trace logic rather than pattern-match to "looks reasonable," and they find more race conditions, state-machine violations, idempotency failures, and security-boundary gaps.

| Builder family | Good reviewer choices |
|----------------|-----------------------|
| Anthropic (Claude) | OpenAI reasoning models, Qwen3, DeepSeek-R1, Gemini, xAI Grok |
| OpenAI | Claude (extended thinking), Qwen3, DeepSeek-R1, Gemini |
| Google | Claude (extended thinking), OpenAI reasoning models, Qwen3, DeepSeek-R1 |
| Open-weight | Any frontier family above |

Model line-ups change quickly. Treat this table as a starting point and record the exact model and version used in every review record.

**Zero-context reader (Enterprise G5):** any capable model in a clean session with no system prompt or project files, reading the release package cold. It catches undocumented assumptions and jargon.

---

## How to Run a B-Team Review

### Step 1: Prepare the package

| Reviewing | Template |
|-----------|----------|
| Gate artifacts (spec, design, release package) | `templates/B-TEAM-REVIEW-PACKAGE.md` (12-persona prompt) |
| A code change at R2 | The paste-ready R2 prompt in `11-tiered-adversarial-review.md` (Cipher + Jett + Blaze) |
| A code change at R3 | `templates/CODE-REVIEW-PROMPT-QWEN.md` with all six forensic personas, **plus** the `B-TEAM-REVIEW-PACKAGE.md` 12-persona prompt for the design, privacy, accessibility, ops, and product aspects. Together they cover all 12 B-Team personas. |

`templates/CODE-REVIEW-PROMPT-CLAUDE.md` is the same forensic prompt formatted for Anthropic models. Use it only when the builder was **not** Claude-family, or as a second, different-family pass at R3.

Include the diff **and** the surrounding code before and after the change, so the reviewer can judge it in context rather than in isolation.

### Step 2: Run it in the independent context

Paste the system prompt, then the package. Let it run. Record: reviewer model and version, date, provider, data class, and whether it was `same-family`.

### Step 3: Bring findings back

The A-Team responds to **every** finding:

| Response | Meaning |
|----------|---------|
| **Accept & Fix** | Valid. Fixed before the gate or merge. |
| **Accept & Defer** | Valid but not blocking. Ticket, owner, and deadline required. |
| **Reject** | Incorrect. Counter-evidence required (file, line, test, or spec section). "I disagree" is not a rejection. |

```markdown
| # | Finding | Response | Rationale / Evidence |
|---|---------|----------|----------------------|
| C-1 | [brief description] | Accept & Fix / Accept & Defer / Reject | [why, with references] |
```

**Deferrals:** every deferral has an owner and a deadline. Deferrals past deadline escalate to MAJOR at the next gate. The Human Steward can reject any deferral.

### Step 4: Resubmit if needed

If the verdict is FAIL, fix and resubmit. Re-review covers the fixed items plus a regression check of the fixes.

---

## Verdicts

| Verdict | Meaning | Action |
|---------|---------|--------|
| **PASS** | No CRITICALs, no unresolved MAJORs | Can proceed to the human decision |
| **PASS WITH CONDITIONS** | No CRITICALs; every MAJOR has an owner, plan, and deadline | Can proceed once the Human Steward accepts the conditions |
| **FAIL** | Any CRITICAL, or MAJORs without a resolution plan | Fix and resubmit |

A B-Team verdict is evidence for the gate, not the gate decision. The Human Steward decides.

---

## Tracking

All B-Team findings, of every severity, go in `specifications/{ID}/FINDINGS_TRACKER.md`:

- Finding ID and severity
- Description
- Response (fix / defer / reject) and evidence
- Owner and deadline
- Status

Items past their deadline escalate to MAJOR at the next gate.

---

## Domain-Specific Code Review

Code review needs different context than spec review. The reviewer has to trace execution paths, know which invariants must hold, know the attack surfaces, and know what "wrong" means in this domain. The code-review templates include a **context block** for exactly that. Without it, a reviewer finds generic issues and misses the domain bugs that matter.

Extend the template's context block for platform-specific risks:

- **Mobile:** platform store policies, memory, concurrency, accessibility
- **Web:** XSS, CSRF, CSP, performance budgets
- **APIs:** rate limiting, auth bypass, input validation, versioning
- **Infrastructure:** IAM policies, network segmentation, secrets management
- **ML/AI pipelines:** model drift, hallucination, bias, data poisoning, prompt injection
