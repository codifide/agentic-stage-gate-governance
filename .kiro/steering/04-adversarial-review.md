---
inclusion: auto
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

## How to Run a B-Team Review

### Step 1: Prepare the Review Package

Concatenate the relevant artifacts into a single document for the B-Team to review.

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

### Step 5: Resubmit if Needed

If the verdict is FAIL or PASS WITH CONDITIONS (with CRITICALs), fix and resubmit. Repeat until PASS.

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
