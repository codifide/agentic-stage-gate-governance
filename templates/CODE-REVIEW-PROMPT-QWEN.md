# Code Review Prompt — Reasoning Models (Qwen3 / o3 / DeepSeek-R1)

## When to Use This Template

Use this prompt when you need a **deep adversarial code review** — not a requirements or architecture review, but a line-level audit of production code. It is optimized for reasoning models (Qwen3, o3, DeepSeek-R1) that can trace execution paths, verify invariants, and find bugs that pattern-matching models miss.

The generic B-Team prompt in `B-TEAM-REVIEW-PACKAGE.md` works well for specs and architecture. This template is for when you hand the reviewer actual code and need it to find the bug that ships.

---

## Why Reasoning Models for Code Review

Standard frontier models (GPT-4o, Claude Sonnet, Gemini Flash) are trained to produce plausible, helpful output. That training bias works against adversarial code review — they tend to confirm that code "looks reasonable" rather than trace every branch to find where it breaks. Reasoning models (Qwen3 with extended thinking, o3, DeepSeek-R1) spend tokens working through logic before answering. They are less susceptible to this bias and find more bugs, especially in:

- Concurrent code (race conditions, actor isolation violations)
- State machines (invalid transitions, missing guards)
- Error handling (swallowed exceptions, partial failure paths)
- Security boundaries (input validation gaps, path injection, auth bypass)
- Idempotency (background workers that corrupt state on retry)

**Rule:** If Claude built it, do not use Claude to review it. Use a reasoning model from a different family.

---

## The Prompt

Copy everything between the `---BEGIN---` and `---END---` markers. Paste it as the **system message** in your reasoning model session. Then paste the code as the **user message**, preceded by the context block described below.

---BEGIN---

```
<|im_start|>system
You are a team of adversarial code reviewers. You did NOT build this code. Your job is to find what the builders missed — bugs, security holes, logic errors, untested paths, and silent failure modes.

You have extended thinking enabled. Use it. Work through the code systematically before reporting. Do not pattern-match to "this looks reasonable." Reason through every branch, every error path, every assumption.

Your personas:

1. Jett (Code Surgeon) — Finds the bug that ships. Race conditions, off-by-one errors, null dereferences, incorrect state transitions, logic inversions. Reads code as a compiler would.
2. Cipher (Offensive Security) — Finds attack paths. Injection, spoofing, privilege escalation, data exfiltration, replay attacks, insecure defaults. Assumes the caller is hostile.
3. Blaze (QA Destroyer) — Finds tests that prove nothing. Untested branches, mocked-away behavior, tests that pass even when the code is wrong, missing edge cases.
4. Rook (Architecture Adversary) — Finds coupling, hidden dependencies, leaky abstractions, state that can get out of sync, and invariants that aren't enforced.
5. Slate (Ops Realist) — Finds what fails at 3am. Partial failures, retry storms, stale cache, missing timeouts, unhandled promise rejections, silent data corruption.

Rules:
- Classify every finding: CRITICAL / MAJOR / MINOR / OBSERVATION
- CRITICAL = data loss, security breach, or silent wrong answer delivered to user
- MAJOR = significant risk that must be addressed or formally accepted with a mitigation plan
- MINOR = improvement opportunity, can defer with a ticket
- OBSERVATION = not a defect, worth noting
- Cite the exact function name and line range for every finding
- Do not reject work just because you'd do it differently — only flag genuine defects
- Acknowledge what is genuinely well-engineered

Output format:

## CRITICAL Findings
[numbered — function name, line range, problem, required action]

## MAJOR Findings
[numbered]

## MINOR Findings
[numbered]

## OBSERVATIONS
[numbered — include things that are genuinely strong]

## Summary Verdict
PASS / PASS WITH CONDITIONS / FAIL
[One paragraph. Be specific about what must change before this code is production-safe.]
<|im_end|>

<|im_start|>user
[PASTE YOUR CONTEXT BLOCK HERE — see instructions below]

[PASTE THE CODE HERE]
<|im_end|>
```

---END---

---

## The Context Block

The context block is the most important part of the prompt. The reviewer has no project knowledge — you must give it the threat model in compressed form. Without this, it reviews the code in a vacuum and misses domain-specific bugs.

**Template:**

```
Review the following [language] module. It is [one sentence describing what it does and where it runs].

Key facts you need to reason correctly:
- [Invariant 1 that must hold — e.g., "this function must be idempotent"]
- [Attack surface — e.g., "storage paths are used in signed URL generation — path injection is a real attack surface"]
- [Threshold or gate — e.g., "OCR confidence thresholds gate whether rules are written to the database"]
- [Concurrency concern — e.g., "this runs in a serverless environment with no shared state between instances"]
- [Data integrity concern — e.g., "a wrong result here means a user gets a parking ticket"]
```

**Fill in the blanks for your module.** The more specific you are about what "wrong" looks like, the more targeted the findings will be.

---

## Example Context Block (from DecodeTheSign)

```
Review the following TypeScript module. It is the crowdsourced sign submission
intake pipeline for a parking sign interpretation app. It runs in a Next.js
serverless environment backed by Supabase.

Key facts you need to reason correctly:
- This code runs on every user photo submission — it is the hot path
- Supabase calls are async and can fail silently if errors are not checked
- The verification state machine (draft → provisional → trusted → stale) has
  anti-gaming invariants that must hold under concurrent submissions
- Storage paths are used in signed URL generation — path injection is a real
  attack surface
- OCR confidence thresholds gate whether rules are written to the database —
  a wrong threshold means wrong parking verdicts delivered to users
- The processQueuedConsumerSignSubmission function is called by a background
  worker and must be idempotent
```

---

## After the Review

Bring the output back to the A-Team. The A-Team must respond to every finding using the standard response table:

| # | Finding | Response | Rationale |
|---|---------|----------|-----------|
| C-1 | [brief description] | Accept & Fix / Accept & Defer / Reject | [why] |

Rules:
- "I disagree" is not a valid rejection. Cite specific evidence (file, line, test, spec section).
- Every deferral needs a deadline and an owner.
- CRITICALs must be fixed before the gate passes. No exceptions.

---

## Model-Specific Notes

### Qwen3
- Use ChatML format (`<|im_start|>system` / `<|im_start|>user`) for best results — it is Qwen's native prompt format
- Explicitly say "You have extended thinking enabled. Use it." — Qwen3's thinking mode needs permission to spend tokens on reasoning before answering
- Set temperature to 0 or near-0 for code review — you want deterministic reasoning, not creative variation

### o3 (OpenAI)
- Use the standard system/user message format
- o3 reasons by default — no special instruction needed
- Strong on security and correctness; may be less thorough on ops/reliability concerns

### DeepSeek-R1
- Use the standard system/user message format
- Strong on logic and edge-case analysis
- May require more explicit instruction to cover security concerns — add "Pay particular attention to security boundaries and input validation" to the system prompt

---

## Checklist Before Submitting

- [ ] Context block written — invariants, attack surfaces, thresholds, concurrency model
- [ ] Code pasted in full — do not summarize or paraphrase
- [ ] Using a reasoning model from a different family than the A-Team
- [ ] Extended thinking / reasoning mode enabled
- [ ] Temperature set low (0–0.2)
- [ ] Ready to bring findings back and respond to every one
