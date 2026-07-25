---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Loop Engineering — Automated Verification and Execution

This steering file governs how and when to use automated execution loops. Loops handle mechanical tasks that have clear verifiers. Gates handle everything else.

---

## The Decision Framework: Loop or Gate?

Ask three questions. If all three answers are "yes," loop it. If any answer is "no," gate it.

### Question 1: Can a machine verify the output?

Does a test, build check, metric comparison, schema validation, or other automated process exist (or can be built) that definitively says "pass" or "fail" without human interpretation?

- **Yes → loop candidate.** Tests pass, builds compile, checksums match, benchmarks hit targets.
- **No → gate it.** "Good design," "clear writing," "appropriate architecture," "correct per CMS spec interpretation."

### Question 2: Is the task bounded and repeatable?

Does the task have a clear start, a clear end, and can it be retried without side effects?

- **Yes → loop candidate.** Fix a failing test. Run ETL and verify row counts. Refactor to a known pattern.
- **No → gate it.** Design a new feature. Decide between architectural approaches. Interpret ambiguous requirements.

### Question 3: Is the cost of failure low and recoverable?

If the loop produces a wrong answer and the verifier doesn't catch it, is the blast radius contained?

- **Yes → loop candidate.** Bad code that fails tests. Incorrect refactoring caught by existing tests.
- **No → gate it.** Data migration with no rollback. Security logic. Compliance interpretation.

---

## Five Rules for Production Loops

### 1. The Verifier Must Be Harder Than the Task

If your test is easier to pass than the real requirement, the loop will find the easiest path that satisfies the test — not the correct solution. Write verifiers that are genuinely hard to fool.

**Good verifier:** Run all 199 measure engines, compare output against known-correct baselines, flag any divergence.
**Bad verifier:** Check that the function returns a number.

### 2. State Belongs on Disk, Not in Context

Context windows degrade. Sessions end. Models forget. Anything a loop needs to remember goes in a file.

Every loop gets a state file:
```
loops/{loop-name}/
├── state.json          # Current iteration, last result, retry count
├── history.jsonl       # Append-only log of all iterations
├── verifier-output/    # Latest verifier results
└── escalations.md      # Issues that require human judgment
```

### 3. Separate Generator from Verifier

The thing that writes code cannot be the thing that judges code. Same model, different invocation is acceptable. Same prompt, same context is NOT.

This is the loop-level equivalent of A-Team/B-Team separation.

### 4. Hard Stop at N Retries

No loop runs forever. Set limits based on task type:

| Task Type | Max Retries | Escalation |
|-----------|-------------|------------|
| Build fix | 3 | Escalate to human with failure log |
| Test fix | 5 | Escalate with root cause analysis |
| Research/exploration | 10 | Present best result so far |
| Data migration | 1 | If it fails, escalate immediately |
| Performance optimization | 7 | Accept best result above threshold |

### 5. Promote Successful Patterns to Templates

When a loop solves a problem, extract the pattern. Next time that problem type appears, it's a template, not an exploration.

**Tier 3 → Tier 2 → Tier 1 promotion:**
- **Tier 3:** First-time exploration. High token cost. Full iteration.
- **Tier 2:** Known pattern with template. Medium cost. Fewer iterations.
- **Tier 1:** Cached/deterministic. Near-zero token cost. Single execution.

Over time, more work moves from expensive iteration to cheap execution.

---

## Loop State Management

### State File Format

```json
{
  "loop_id": "measure-engine-verification",
  "created": "2026-07-15T08:00:00Z",
  "status": "running|passed|failed|escalated",
  "iteration": 4,
  "max_iterations": 10,
  "last_result": {
    "timestamp": "2026-07-15T08:12:00Z",
    "verifier_passed": false,
    "failure_reason": "MIPS_238 score diverged by 0.3%",
    "tokens_consumed": 1847
  },
  "total_tokens": 7203,
  "cost_tier": 2,
  "escalation_threshold": "3 consecutive identical failures"
}
```

### Rules for State

1. **Write after every iteration.** If the session dies, the next session picks up where it left off.
2. **Append to history, never overwrite.** The full iteration log is audit evidence.
3. **Include token counts.** Cost tracking is mandatory.
4. **PHI never enters state files.** Reference by ID only. Follow the same data classification as source data.

---

## Verifier Requirements

### Independence

The verifier MUST be independently invokable. It cannot share context with the generator. For regulated work (healthcare, finance, compliance), the verifier MUST run in a separate session.

### Honest Gates

A verifier must be able to say "no." If the verifier always passes, it's not a verifier — it's a rubber stamp.

Test your verifiers by giving them known-bad input. If they pass it, fix the verifier before trusting the loop.

### Verifier Types

| Type | Example | Cost |
|------|---------|------|
| **Build check** | `npm run build` exits 0 | Free |
| **Test suite** | `pytest` all green | Free |
| **Schema validation** | API response matches OpenAPI spec | Free |
| **Metric comparison** | Score within ±0.01% of baseline | Low |
| **Adversarial review** | B-Team model reviews output | Medium |
| **Human spot-check** | Sample 5 of 100 outputs for manual review | High |

Prefer cheaper verifiers. Escalate to expensive verifiers only when cheap ones pass.

---

## Cost Control

### Tier System

| Tier | Description | Token Budget | Example |
|------|-------------|--------------|---------|
| **Tier 1** | Deterministic, cached, template-driven | 0–100 tokens | Run existing test suite, apply known fix |
| **Tier 2** | Known pattern, minor adaptation needed | 100–5,000 tokens | Implement from template, fix similar bug |
| **Tier 3** | Exploration, novel problem, iteration required | 5,000–50,000 tokens | Research new approach, optimize unknown |

### Cost Control Rules

1. **Default to Tier 1.** Only escalate when lower tiers fail.
2. **Track tokens per loop.** Every loop logs total token consumption.
3. **Set budgets before starting.** A loop without a budget is a loop without a stop condition.
4. **Fail fast, fail cheap.** Detect failure in the first 100 tokens, not after 5,000.
5. **Cache aggressively.** Never re-answer a question already answered.
6. **ROI formula:** `(human hours saved × hourly rate) / (tokens consumed × $/token + verifier compute cost)`. If ROI < 1, the loop isn't worth running.

### Promote Patterns

After a Tier 3 loop succeeds:
1. Extract the solution pattern
2. Create a template for the pattern
3. Next occurrence uses the template (Tier 2)
4. After 3 successful template uses, promote to Tier 1 (deterministic)

---

## Integration with Auto-Research

Loops ARE the inner cycle of auto-research. The relationship:

```
Auto-Research (07-auto-research-protocol.md)
├── Phase 1: GENERATE → multiple approaches (Gate: human picks direction)
├── Phase 2: BUILD → each approach implemented
│   └── INNER LOOP: build → test → fix → verify (Loop: no human needed)
├── Phase 3: EVALUATE → adversarial review (Gate: B-Team judgment)
├── Phase 4: REFINE → address findings
│   └── INNER LOOP: fix → verify → fix → verify (Loop: no human needed)
└── Phase 5: CONVERGE CHECK (Gate: human decides continue/ship/kill)
```

Auto-research is the outer cycle (gate-governed). Loops are the inner cycle (verifier-governed). The two compose naturally:
- Auto-research decides WHAT to build (judgment → gate)
- Loops handle HOW to build it (mechanical → automated)

---

## Loop Design Checklist

Before activating a loop, confirm:

- [ ] **Verifier defined** — What automated check proves success?
- [ ] **Verifier tested** — Does it reject known-bad input?
- [ ] **State file location** — Where does iteration state persist?
- [ ] **Max retries set** — What's the hard stop?
- [ ] **Cost tier assigned** — What's the token budget?
- [ ] **Escalation path defined** — What happens on failure?
- [ ] **Failure alerting configured** — Who gets notified if it breaks?
- [ ] **PHI check** — Does the loop touch sensitive data? If yes, extra constraints apply.

---

## Activation Phrases

| Phrase | What It Does |
|--------|-------------|
| **"Loop this task"** | Convert the current task to an automated loop with verifier |
| **"Define a loop: [task]"** | Design a new loop from scratch |
| **"Add a verifier for X"** | Design and implement a verifier for an existing process |
| **"Run overnight: [goal]"** | Define a long-running loop with morning report |
| **"What loops are running?"** | Status check on all active loops |
| **"Promote this pattern"** | Extract a successful loop into a reusable template |

---

## Examples

### Example 1: Fix a Failing Test
```
Task: test_measure_238_calculation is failing
Decision: Loop it (verifier = the test itself, bounded, recoverable)
Max retries: 3
Tier: 2 (known pattern — test fix)
```

### Example 2: Design a Permission System
```
Task: Design RBAC for healthcare records
Decision: Gate it (no automated verifier for "good design")
Process: G2/G3 with full A-Team/B-Team review
```

### Example 3: Overnight Data Verification
```
Task: Verify all 199 measure engines produce consistent output
Decision: Loop it (verifier = baseline comparison, bounded, recoverable)
Max retries: 1 per engine, 3 for full suite
Tier: 1 (deterministic — run and compare)
Run: Overnight, report by morning
```

### Example 4: Refactor to New Pattern
```
Task: Migrate 50 components from class to functional
Decision: Loop it (verifier = existing tests pass + build compiles)
Max retries: 5 per component
Tier: 2 (template-driven after first success)
Promote: After 3 successful migrations, extract template
```

---

## Guardrails

### What Loops Must NEVER Do

1. **Make irreversible changes without human approval** — Data deletion, production deployment, security configuration changes
2. **Access resources beyond their scope** — A loop fixing tests doesn't get database write access
3. **Exceed their token budget silently** — Hard stop, then escalate
4. **Store PHI in state files** — Reference by ID only
5. **Self-approve gate decisions** — Loops run BETWEEN gates, not INSTEAD of gates

### Circuit Breakers

- **3 identical failures** → Stop and escalate (likely a structural problem, not a retry problem)
- **Token budget exceeded** → Stop, report best result so far
- **Verifier itself fails** → Stop immediately (broken verifier = unverified output)
- **Unexpected resource usage** → Pause and notify (possible infinite loop or resource leak)

---

*Loop Engineering Steering v1.0 — Part of Stage-Gate-Loop Governance v2.0 — July 2026*
