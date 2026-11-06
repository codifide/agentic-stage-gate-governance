---
inclusion: auto
name: sgl-loop-engineering
description: SGL loop engineering - loop-or-gate decision, rules for production loops, verifier immutability and enforcement, baselines, meta-loop, state files, Cost Classes C1-C3, retry limits, circuit breakers, and verifier anti-patterns. Load before designing, running, or debugging any automated loop.
# For non-Kiro tools, load this file on demand for loop work.
---

# Loop Engineering — Automated Verification and Execution

This steering file governs how and when to use automated execution loops. Loops handle mechanical tasks that have clear verifiers. Gates handle everything else.

---

## The Decision Framework: Loop or Gate?

Ask three questions. If all three answers are "yes," loop it. If any answer is "no," gate it.

### Question 1: Can a machine verify the output?

Does a test, build check, metric comparison, schema validation, or other automated process exist (or can be built) that definitively says "pass" or "fail" without human interpretation?

- **Yes → loop candidate.** Tests pass, builds compile, checksums match, benchmarks hit targets.
- **No → gate it.** "Good design," "clear writing," "appropriate architecture," "correct per regulatory spec interpretation."

### Question 2: Is the task bounded and repeatable?

Does the task have a clear start, a clear end, and can it be retried without side effects?

- **Yes → loop candidate.** Fix a failing test. Run ETL and verify row counts. Refactor to a known pattern.
- **No → gate it.** Design a new feature. Decide between architectural approaches. Interpret ambiguous requirements.

### Question 3: Is the cost of failure low and recoverable?

If the loop produces a wrong answer and the verifier doesn't catch it, is the blast radius contained?

- **Yes → loop candidate.** Bad code that fails tests. Incorrect refactoring caught by existing tests.
- **No → gate it.** Data migration with no rollback. Security logic or security configuration (credentials, TLS, auth policy). Compliance interpretation.

---

## Five Rules for Production Loops

### 1. The Verifier Must Be Harder Than the Task

If your test is easier to pass than the real requirement, the loop will find the easiest path that satisfies the test — not the correct solution. Write verifiers that are genuinely hard to fool.

**Good verifier:** Run the full engine suite, compare output against known-correct baselines, flag any divergence.
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

### 3. Separate Generator from Verifier — and Make the Boundary Structural

The thing that writes code cannot be the thing that judges code. Same model, different invocation is acceptable. Same prompt, same context is NOT.

This is the loop-level equivalent of A-Team/B-Team separation.

**The boundary must be enforced, not advised.** A loop that can edit its own verifier will eventually make the test easier instead of making the work correct. This is the central failure mode of autonomous loops (verifier hacking).

- **Declared by a human, outside the loop.** Immutable paths (verifier code, golden fixtures, baselines, evaluation harness, scoring rubrics, the existing test files the loop is trying to satisfy) are listed in `.sgl/immutable-paths`, one glob per line. Atlas proposes the list; the Human Steward approves it. The loop's state file may *copy* the list for reference, but the state file is not the source of truth.
- **Enforced in two places.** A blocking PreToolUse hook rejects agent writes to those paths (`templates/enforcement/guard-immutable-paths.sh`). A CI check on **every PR** fails any diff that touches them, unless the Human Steward approved that change (`templates/enforcement/check-immutable-paths.sh`). The hook stops the attempt; CI is the backstop for anything the hook can't see (e.g., shell commands).
- **The generator may read those paths but is forbidden to modify them.** `.sgl/immutable-paths` protects itself.
- Changing a verifier is a human-approved change made on its own branch, outside the loop.

This is the same discipline as an autoresearch setup where the agent may edit the training code but never the evaluator.

### 4. Hard Stop at N Retries

No loop runs forever. Set limits based on task type:

| Task Type | Max Retries | Escalation |
|-----------|-------------|------------|
| Build fix | 3 | Escalate to human with failure log |
| Make a failing test pass (change the code; the test file is immutable) | 5 | Escalate with root cause analysis |
| Research/exploration | 10 | Present best result so far |
| Data migration | 1 | If it fails, escalate immediately |
| Performance optimization | 7 | Accept best result above threshold |

### 5. Promote Successful Patterns to Templates

When a loop solves a problem, extract the pattern. Next time that problem type appears, it's a template, not an exploration.

**Cost Class C3 → C2 → C1 promotion** (see Cost Control below):
- **C3:** First-time exploration. High token cost. Full iteration.
- **C2:** Known pattern with template. Medium cost. Fewer iterations.
- **C1:** Cached/deterministic. Low token cost. Single execution.

Over time, more work moves from expensive iteration to cheap execution.

---

## The Meta-Loop: When the Loop Itself Stalls

A loop that hits its retry limit has two possible problems, and they need different responses:

1. **The task is genuinely hard or ill-posed** → escalate to a human gate.
2. **The search strategy is stuck** → the loop keeps proposing variations of the same failed idea, returning to the same priors even after they stop working.

Problem 2 is common and wasteful. Retrying the same strategy harder doesn't help — you need to change *how the loop searches*, not just let it search again. This is the **meta-loop**: an outer process that watches the inner loop and intervenes in the strategy, not the task.

### How it works

When an inner loop plateaus (**3 consecutive iterations with no verifier improvement**, unless the loop's design sets a different N), before hard-stopping, the meta-loop gets one pass:

1. **Read the history, not just the last result.** The meta-loop consumes the full `history.jsonl` — every attempt, every failure reason — looking for the pattern the inner loop can't see from inside.
2. **Diagnose the stall.** Is the loop proposing near-duplicate changes? Optimizing the wrong variable? Trapped by an assumption baked into its first attempt?
3. **Change the strategy, not the goal.** The meta-loop may widen the search (force exploration away from the stuck prior), reorder which variable is optimized first, or decompose the task differently. It does **not** change the verifier, the goal, or the Intent Contract — those are fixed.
4. **Re-run the inner loop with one fresh retry budget** (the same max retries as the original run) under the new strategy. If it breaks the plateau, continue. If it stalls again, escalate to a human gate with both the original failure and the meta-loop's diagnosis.

An inner loop reasons about the *task*; the meta-loop reasons about the *loop's own behavior*, a perspective the inner loop lacks. It is what notices "you have tried five variations of the same wrong idea."

### Boundaries (non-negotiable)

- The meta-loop changes **strategy only** — never the verifier, the goal, the paths in `.sgl/immutable-paths`, or the Intent Contract.
- The meta-loop gets **one** intervention per plateau. If the second stall occurs, escalate. No infinite meta-recursion.
- Every meta-loop intervention is logged to the loop's history as a distinct event, with its diagnosis. Atlas owns this; Quill records it.

### When NOT to use a meta-loop

- The task failed for a real reason (missing dependency, genuine ambiguity, a blocked external call) → escalate, don't re-strategize.
- Consequential or irreversible work → escalate on first stall; don't let an outer loop improvise strategy on high-blast-radius tasks.
- The verifier itself is suspect → stop immediately (a meta-loop on top of a broken verifier compounds the error).

---

## Loop State Management

### State File Format

```json
{
  "loop_id": "engine-output-verification",
  "created": "2026-07-15T08:00:00Z",
  "status": "running|passed|failed|escalated",
  "iteration": 4,
  "max_iterations": 10,
  "immutable_paths_source": ".sgl/immutable-paths",
  "last_result": {
    "timestamp": "2026-07-15T08:12:00Z",
    "verifier_passed": false,
    "failure_reason": "output diverged from baseline by 0.3%",
    "tokens_consumed": 1847
  },
  "total_tokens": 7203,
  "cost_class": "C2",
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

### Cost Classes

Cost Classes size a loop's **token budget**. They are unrelated to Review Levels R1–R3.

| Class | Description | Budget per loop run (order of magnitude) | Example |
|-------|-------------|------------------------------------------|---------|
| **C1** | Deterministic, cached, template-driven | Up to ~10k tokens | Run existing suite, apply a known fix |
| **C2** | Known pattern, minor adaptation | ~10k–200k tokens | Implement from template, fix a similar bug |
| **C3** | Exploration, novel problem | ~200k–2M tokens | Research a new approach, optimize an unknown |

Calibrate these to your models and codebase; the point is that every loop has a number before it starts.

### Cost Control Rules

1. **Default to the lowest class that can work.** Escalate only when it fails.
2. **Track tokens per loop.** Every loop logs total token consumption.
3. **Set budgets before starting.** A loop without a budget is a loop without a stop condition.
4. **Fail fast, fail cheap.** Run the cheapest verifier first, on the first iteration, before spending on the next one.
5. **Cache aggressively.** Never re-answer a question already answered.
6. **ROI formula:** `(human hours saved × hourly rate) / (tokens consumed × $/token + verifier compute cost)`. If ROI < 1, the loop isn't worth running.

### Promote Patterns

After a C3 loop succeeds:
1. Extract the solution pattern
2. Create a template for the pattern
3. Next occurrence uses the template (C2)
4. After 3 successful template uses, promote to C1 (deterministic)

---

## Integration with Auto-Research

Loops ARE the inner cycle of auto-research. The relationship:

```
Auto-Research (07-auto-research-protocol.md)
├── Phase 1: GENERATE → multiple approaches (human approves which directions to pursue)
├── Phase 2: BUILD → each approach implemented
│   └── INNER LOOP: build → test → fix → verify (Loop: no human needed)
├── Phase 3: EVALUATE → independent B-Team review + verifier results
├── Phase 4: REFINE → address findings
│   └── INNER LOOP: fix → verify → fix → verify (Loop: no human needed)
└── Phase 5: CONVERGE CHECK → human checkpoint decides continue / pivot / stop
```

Auto-research is the outer cycle (gate-governed). Loops are the inner cycle (verifier-governed). The two compose naturally:
- Auto-research decides WHAT to build (judgment → gate)
- Loops handle HOW to build it (mechanical → automated)

---

## Loop Design Checklist

Before activating a loop, confirm:

- [ ] **Verifier defined** — What automated check proves success?
- [ ] **Verifier tested** — Does it reject known-bad input?
- [ ] **Immutable paths approved** — Verifier, fixtures, baselines, and harness listed in `.sgl/immutable-paths` by the Human Steward; guard hook and CI check active
- [ ] **State file location** — Where does iteration state persist?
- [ ] **Max retries set** — What's the hard stop?
- [ ] **Meta-loop eligibility** — On plateau, is one strategy-change pass allowed, or does this escalate immediately (consequential/irreversible work)?
- [ ] **Cost Class and budget assigned** — What's the token budget?
- [ ] **Escalation path defined** — What happens on failure?
- [ ] **Primum checkpoints scheduled** — fresh-context intent check (`00-welcome.md` §5) before the loop starts, at every plateau or escalation, before any meta-loop strategy change, and before output is merged. No fresh context available → the loop pauses there and the package goes to the human.
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

## Proactive Loop Suggestion (MANDATORY)

**When the user gives a task that meets all three loop criteria (machine-verifiable, bounded/repeatable, low-cost failure), the AI MUST proactively ask:**

> "This looks like a good candidate for looping — it's verifiable, bounded, and recoverable. Want me to loop it (define verifier + state + stop condition) or just execute it once?"

**When to suggest:**
- Running a pipeline or ETL for multiple orgs
- Fixing a failing test (the test IS the verifier)
- Data consistency checks across tables/views
- Refactoring to a known pattern with existing tests
- Performance optimization with a measurable benchmark
- Any task the user is likely to run again

**When NOT to suggest:**
- Design decisions, architecture choices
- First-time implementation of new features
- Compliance interpretation
- Anything where "correct" requires human judgment

This is not optional. If the task fits, ask. Let the human decide.

---

## Examples

### Example 1: Fix a Failing Test
```
Task: a unit test for a calculation module is failing
Decision: Loop it (verifier = the test itself, bounded, recoverable)
Immutable: the test file and its fixtures (fix the code, not the test)
Max retries: 5
Cost Class: C2 (known pattern)
```

### Example 2: Design a Permission System
```
Task: Design RBAC for healthcare records
Decision: Gate it (no automated verifier for "good design")
Process: G2/G3 with full A-Team/B-Team review
```

### Example 3: Overnight Data Verification
```
Task: Verify the full engine suite produces consistent output
Decision: Loop it (verifier = baseline comparison, bounded, recoverable)
Max retries: 1 per engine, 3 for full suite
Cost Class: C1 (deterministic: run and compare)
Run: Overnight, report by morning
```

### Example 4: Refactor to New Pattern
```
Task: Migrate 50 components from class to functional
Decision: Loop it (verifier = existing tests pass + build compiles)
Max retries: 5 per component
Cost Class: C2 (template-driven after first success)
Promote: After 3 successful migrations, extract template
```

---

## Guardrails

### What Loops Must NEVER Do

1. **Make irreversible changes** — data deletion, production deployment
2. **Touch security configuration** — credentials, secret rotation, TLS, auth policy, IAM. These are gated, always.
3. **Access resources beyond their scope** — a loop fixing tests doesn't get database write access or cloud credentials
4. **Modify immutable paths** — verifiers, fixtures, baselines, harness
5. **Exceed their token budget silently** — hard stop, then escalate
6. **Store PHI or secrets in state files** — reference by ID only
7. **Self-approve gate decisions** — loops run BETWEEN gates, not INSTEAD of gates

### Circuit Breakers

- **Plateau (N iterations, no improvement)** → Hand to the meta-loop for one strategy-change pass. If still stuck, escalate.
- **Second stall after a meta-loop intervention** → Stop and escalate (strategy change didn't help — this needs human judgment)
- **3 identical failures** → Stop and escalate (likely a structural problem, not a retry problem)
- **Token budget exceeded** → Stop, report best result so far
- **Verifier itself fails** → Stop immediately (broken verifier = unverified output)
- **Guard hook or CI check blocks a write to an immutable path** → Stop immediately and escalate (a verifier-hacking attempt; the boundary held, but find out why it was tried)
- **Unexpected resource usage** → Pause and notify (possible infinite loop or resource leak)

---

## Verifier Anti-Patterns (Learned in Production)

### Stale Baseline Comparison

**Problem:** A verifier that compares new output against historical data will produce false failures when the system's behavior has legitimately changed (different engine routing, different data, different configuration).

**Example:** Bitmap pipeline verifier compared against the results table data from a prior run that used different engine routing rules. A subset of measures showed "discrepancies" that were actually correct new behavior.

**Solution:** Verifiers must do one of the following. **Never regenerate a baseline from the code under test**; that compares the system to itself and always passes.
1. **Refresh the baseline from a trusted reference** — a known-good build, an independent implementation, or hand-verified data — as a human-approved baseline change (a governance event per `12`), made outside the loop.
2. **Be self-contained** — verify round-trip correctness (write → read → compare input vs output) without depending on external historical state.
3. **Tolerate known divergences** — only via a Human Steward-approved, documented threshold or exclusion list tied to the explicit configuration change. The loop may not widen tolerances itself.

A verifier that compares against stale data trains the team to dismiss failures as "probably stale baseline again," which eventually hides a real bug. A verifier whose baseline the loop can refresh is no verifier at all.

### False Confidence from Partial Validation

**Problem:** Validating a small handful of cases out of the full set and declaring "prototype validated" creates false confidence. The B-Team correctly flagged this as single-digit-percent coverage.

**Solution:** If full validation is expensive, document explicitly: "Validated N of M (X%). Full validation required before Phase Y." Never use the word "validated" without the denominator.

---

## Practical Learnings: When Loops and Gates Interact

### Effort estimates for looped work

Reviewers estimate effort as if a human executes sequentially. Looped work with a shared interface and a fast verifier is often much faster. **Rule:** if a review estimates > 2 weeks for a looped task, challenge it: "What's the shared interface? How many unique changes vs. repetitions?"

### Classify before executing

Before starting any multi-step implementation, classify each step LOOP / GATE / DOCUMENT and present the classification to the human before executing. Agents in "implementation mode" otherwise skip the loop-or-gate assessment.

---

*Loop Engineering — SGL Harness v3.0 — October 2026*
