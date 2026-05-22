---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Adversarial Review Process

Every gate review MUST include an adversarial review by the B-Team before the gate can pass.

---

## The Rule

The builder cannot review their own work. A **separate AI** (different model, different prompt, hostile personas) attacks the spec/code at every gate.

## Teams

- **A-Team** (Builders): Primary AI assistant. Designs, specs, implements, delivers.
- **B-Team** (Critics): Different AI model. Reviews, challenges, finds weaknesses.

Teams NEVER use the same AI model. This eliminates model-specific confirmation bias.

---

## Model Selection

The choice of model for B-Team review is not arbitrary. Different model families have different failure modes, and the goal is to find what the builder missed — not to get a second opinion from a model with the same blind spots.

### A-Team (Builder)
Frontier models with large context windows. Best for generation, refactoring, and multi-file reasoning.
- Claude Sonnet / Claude Opus
- GPT-4o
- Gemini 2.5 Pro

### B-Team (Adversarial Reviewer)
**Use reasoning/thinking models for code review.** These grind through logic systematically rather than pattern-matching to the most plausible answer. They are less susceptible to the RLHF bias toward confirming that code looks reasonable. They find more bugs — especially race conditions, state machine violations, idempotency failures, and security boundary gaps.

| Model | Strengths | Notes |
|-------|-----------|-------|
| **Qwen3** | Strong adversarial posture by default, extended thinking, ChatML native format | Recommended for code review. Use `<\|im_start\|>system` format and explicitly enable thinking. |
| **o3** | Deep reasoning, excellent at security and correctness | Strong default; no special prompt needed to activate reasoning. |
| **DeepSeek-R1** | Strong logic and edge-case analysis | Add explicit security instruction — less thorough on security by default. |
| **Claude (extended thinking)** | Good if A-Team used a different model family | Do not use if Claude built the code. |

**Rule:** Do not use the same model family as the A-Team for B-Team review. If Claude built it, do not use Claude to review it.

### Zero-Context Reviewer (optional, recommended at G5)
Any capable model in a clean session with no system prompt or project files. The goal is a naive read — fresh eyes catch undocumented assumptions and invisible jargon.
- Gemini 2.5 Flash
- GPT-4o mini
- Any model with no prior project context

---

## How to Run a B-Team Review

### Step 1: Prepare the Review Package

Concatenate the relevant artifacts into a single document for the B-Team to review. The B-Team must also receive links to the codebase BEFORE and AFTER the change so holistic comparison can be performed, avoiding code duplication or errors caused by looking at code in isolation.

### Step 2: Use the B-Team System Prompt

Copy the system prompt below into a DIFFERENT AI (ChatGPT o3, GPT-4o, Gemini, etc.):

```
You are a team of 12 adversarial reviewers conducting a gate review. You are the B-Team — skeptics, critics, and specialists who did NOT build this system. Your job is to find what the builders missed.

Your personas:
1. Vex (Chief Critic) — Finds gaps between claims and proof.
2. Kade (Product Strategist) — Finds vanity features and timeline fiction.
3. Noor (Requirements Assassin) — Finds ambiguous, untestable, or contradictory requirements.
4. Rook (Architecture Adversary) — Finds coupling, scaling walls, and leaky abstractions.
5. Cipher (Offensive Security) — Finds attack paths the threat model missed.
6. Jett (Code Surgeon) — Finds the bug that ships.
7. Blaze (QA Destroyer) — Finds tests that prove nothing.
8. Wren (Privacy Hawk) — Finds data exposure and compliance gaps.
9. Slate (Ops Realist) — Finds what fails at 3am.
10. Ember (Accessibility Advocate) — Finds what audits miss.
11. Volt (Performance Skeptic) — Finds unrealistic benchmarks.
12. Ink (Devil's Advocate) — Asks the question nobody wants to answer.

Rules:
- Classify every finding as CRITICAL, MAJOR, MINOR, or OBSERVATION
- CRITICAL = stop-ship, must resolve before proceeding
- MAJOR = significant risk, must address or formally accept
- MINOR = improvement opportunity, can defer with ticket
- OBSERVATION = not a defect, worth noting
- Be specific. Cite the section and requirement.
- Don't reject work just because you'd do it differently.
- Acknowledge what's genuinely strong.

Output format:
## CRITICAL Findings
[numbered list with section reference, problem, required action]

## MAJOR Findings
[numbered list]

## MINOR Findings
[numbered list]

## OBSERVATIONS
[numbered list]

## Summary Verdict
[PASS / PASS WITH CONDITIONS / FAIL]
[One paragraph overall assessment]
```

### Step 3: Submit the Spec/Code

Paste the review package after the system prompt. Let the B-Team run.

### Step 4: Bring Findings Back

Copy the B-Team output back to the A-Team (this conversation). The A-Team must respond to every finding:

| Response | Meaning |
|----------|---------|
| **Accept & Fix** | Finding is valid. Will fix before gate. |
| **Accept & Defer** | Finding is valid but not gate-blocking. Tracked with ticket and deadline. |
| **Reject** | Finding is incorrect. Must provide counter-evidence (not just disagreement). |

### A-Team Response Protocol

The A-Team response MUST follow this format for each finding:

```markdown
| # | Finding | Response | Rationale |
|---|---------|----------|-----------|
| C-1 | [brief description] | Accept & Fix / Accept & Defer / Reject | [why] |
| M-1 | [brief description] | Accept & Fix / Accept & Defer / Reject | [why] |
```

**Rules for rejection:**
- "I disagree" is not a valid rejection. You must cite specific evidence (file path, line number, existing test, or spec section) that proves the finding is incorrect.
- If the B-Team didn't have codebase access, cite the code that already handles their concern.
- If the B-Team misunderstood the architecture, explain the actual design with references.

**Rules for deferral:**
- Every deferral MUST have a deadline and an owner.
- Deferrals past their deadline escalate to MAJOR at the next gate.
- The human (project steward) can reject deferrals and require immediate fixes.

### Step 5: Resubmit if Needed

If the verdict is FAIL or PASS WITH CONDITIONS (with CRITICALs), fix and resubmit. Repeat until PASS.

**Re-review scope:** Only the fixed items need re-review, not the entire package. The B-Team should confirm fixes and check for regressions introduced by the fixes.

---

## When to Invoke B-Team

- Before any gate passes (G0–G6)
- Before any major architecture decision is finalized
- Before any release candidate is approved
- When the team disagrees on risk level
- When the feature touches security, privacy, or compliance

---

## Scoring

| Verdict | Meaning | Action |
|---------|---------|--------|
| **PASS** | No CRITICALs, no unresolved MAJORs | Gate can proceed |
| **PASS WITH CONDITIONS** | No CRITICALs, MAJORs have resolution plan | Gate can proceed if conditions met |
| **FAIL** | CRITICALs present OR too many unresolved MAJORs | Must fix and resubmit |

---

## Tracking

All B-Team findings are tracked in a `MINOR_FINDINGS_TRACKER.md` with:
- Finding ID
- Description
- Owner
- Phase deadline
- Resolution status

Items past their deadline escalate to MAJOR at the next gate.

---

## Review Package Template

Use `templates/B-TEAM-REVIEW-PACKAGE.md` for a ready-to-use template that combines the system prompt and artifact sections into one copy-pasteable document.

---

## Domain-Specific Review Prompts

The generic B-Team prompt works well for requirements and architecture reviews. For **code reviews**, use a domain-specific prompt that focuses on platform-specific risks and gives the reviewer the threat model context it needs to find domain-specific bugs.

### Why Code Review Needs a Different Prompt

The generic B-Team prompt is designed for reviewing specs and architecture — it asks 12 personas to evaluate claims, requirements, and design decisions. Code review is different. The reviewer needs to:

1. Trace execution paths, not evaluate arguments
2. Know what invariants must hold (so it can check whether they do)
3. Know the attack surfaces (so it knows where to look for injection, bypass, and data corruption)
4. Know what "wrong" looks like in this domain (a wrong parking verdict means a user gets a ticket)

Without a context block that provides this information, a code reviewer — human or AI — is reviewing in a vacuum. It will find generic issues but miss the domain-specific bugs that actually matter.

### The Code Review Template

`templates/CODE-REVIEW-PROMPT-QWEN.md` contains:
- The full system prompt in Qwen3 ChatML format (also works for o3 and DeepSeek-R1)
- Instructions for writing the context block
- A worked example from a real production module
- Model-specific notes for Qwen3, o3, and DeepSeek-R1
- A pre-submission checklist

**Use this template for any G4 code review.** The generic B-Team prompt is for G1/G2/G3.

### When to Create a Custom Domain-Specific Prompt

If your codebase has platform-specific risks not covered by the generic template, extend it:

- **Mobile apps (iOS/Android):** App Store rejection risks, memory management, concurrency, accessibility
- **Web apps:** XSS, CSRF, CSP compliance, performance budgets, SEO
- **APIs:** Rate limiting, auth bypass, input validation, versioning
- **Infrastructure:** IAM policies, network segmentation, secrets management
- **ML/AI pipelines:** Model drift, hallucination, bias, data poisoning

Start from `templates/CODE-REVIEW-PROMPT-QWEN.md` and add platform-specific concerns to the personas and context block instructions.
