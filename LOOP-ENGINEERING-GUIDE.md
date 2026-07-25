# Loop Engineering: A Pragmatic Guide

## Finding the Sweet Spot Between Speed and Judgment

---

## Executive Summary

Loop engineering says: stop being the middleman between every AI turn. Define a goal, define a verifier, let the agent iterate until done. It's the natural evolution from prompt engineering — and it's right about 60% of the time.

The other 40% — design decisions, compliance logic, architectural choices — still needs human judgment. The teams that win will be the ones who know which tasks belong in loops and which belong in gates.

This guide shows how to get that right. It's built from real-world experience: 13 sessions shipping a healthcare compliance platform, running 199 MIPS measure engines, and learning the hard way what happens when you let things "just run" without verification.

Our system already does loop engineering. We just didn't call it that.

---

## What Loop Engineering Actually Is

Three components. Miss one and you've built a money burner:

**1. Verifier** — An automated gate that isn't the agent grading its own work. Tests, build checks, metric comparisons, schema validation. Something that can say "no" without human intervention.

**2. State** — Persistent record of what's been tried, what worked, what failed. Survives session boundaries. Our `next-session-prompt.md` is exactly this.

**3. Stop Condition** — "Done" must be definable. Either the verifier passes, or you hit a retry limit. Open-ended goals without measurable completion are prompt engineering wearing a loop costume.

If your task has all three, loop it. If it's missing any one, gate it.

---

## The Decision Matrix

| Task Type | Loop It? | Why |
|-----------|----------|-----|
| Run ETL, verify data consistency | Yes | Measurable: row counts match, MV consistent |
| Fix a failing test | Yes | Verifier IS the test |
| Refactor to a known pattern | Yes | Build + existing tests verify |
| Implement CMS measure logic | No | "Correct per CMS spec" isn't testable without Gretchen |
| Design a new feature | No | No verifier for "good design" |
| Performance optimization | Yes | Benchmark is the verifier |
| Security review | No | Absence of findings ≠ security |
| Data migration | Yes | Row count + checksum verification |
| UI polish | No | "Looks right" is subjective |

**Rule of thumb:** If a junior engineer could verify the output with a checklist, loop it. If it needs a senior engineer's judgment, gate it.

---

## Where Our System Already Loops

We've been doing loop engineering without the label:

| What We Do | Loop Engineering Term |
|---|---|
| `post_etl_pipeline.py --org all` | Autonomous execution loop |
| Pre-commit hook (PHI scan + secret check) | Automated verifier |
| `next-session-prompt.md` | Persistent state |
| `REFRESH MATERIALIZED VIEW` after pipeline | Self-healing verification |
| B-Team review → A-Team fix → re-review | Iteration with adversarial verifier |
| Auto-Research Protocol (07-auto-research) | Full bilevel loop with convergence criteria |

The gap isn't concept — it's **continuity**. Our loops pause at session boundaries and wait for human re-initiation. True loop engineering runs without a human triggering each iteration.

---

## How to Reduce Drag

The overhead of loop engineering comes from three sources. Minimize each:

### 1. Verifier Construction Cost

**Problem:** Writing tests and verification logic takes longer than just doing the work.

**Sweet spot:** Write verifiers for things that will be checked repeatedly. A test you run once isn't worth writing. A test that runs after every commit for the next 2 years is worth 10x its construction cost.

**Practical:** Start with the tests that would have caught THIS session's bugs:
- MV matches quality.measure (would have caught stale scorecard)
- quality.score matches MV (would have caught the MIPS_238 mismatch)
- All engines have MEASURE_ID set (would have caught missing exclusions)
- API returns non-empty for known-good org (would have caught the 500 error)

### 2. Retry Token Cost

**Problem:** Loops that fail and retry burn tokens on failed attempts.

**Sweet spot:** Fail fast, fail cheap. Structure loops to detect failure in the first 100 tokens, not after generating 5,000 tokens of code that won't compile.

**Practical:**
- Check syntax before running logic
- Verify prerequisites before attempting work
- Use small probe queries before full execution
- Cache: never re-answer a question you've already answered

### 3. Review Overhead for Loop Output

**Problem:** If you review every loop iteration, you've eliminated the efficiency gain.

**Sweet spot:** Review the VERIFIER, not the output. If you trust the verifier, you trust the loop. Invest review time in making verifiers honest, then let them run.

**Practical:** Our Gretchen review of the Quality Measures page found 8 issues that "passed the build." The build wasn't the right verifier. A CMS-compliance checklist verifier (is MIPS score computed correctly? are inverse measures flagged?) would have caught 6 of 8 automatically.

---

## The Hybrid Model: Loop for Execution, Gate for Judgment

```
                    ┌─────────────────────────────────┐
                    │         HUMAN LAYER              │
                    │  Goals · Design · Gate Decisions │
                    └──────────────┬──────────────────┘
                                   │ defines
                    ┌──────────────▼──────────────────┐
                    │        GATE LAYER                │
                    │  Personas · Adversarial Review   │
                    │  CMS Compliance · Architecture   │
                    └──────────────┬──────────────────┘
                                   │ governs
                    ┌──────────────▼──────────────────┐
                    │        LOOP LAYER                │
                    │  Build · Test · Deploy · Verify  │
                    │  ETL · Migration · Optimization  │
                    └─────────────────────────────────┘
```

- **Human Layer:** You define what success looks like. 5 minutes.
- **Gate Layer:** Personas evaluate whether the approach is sound. 30 minutes. (Our A-Team/B-Team)
- **Loop Layer:** Mechanical execution with automated verification. Runs overnight.

The insight: most teams try to put everything in one layer. Either everything needs human approval (slow) or everything runs autonomously (dangerous). The three-layer model lets each task find its correct altitude.

---

## Five Rules for Production Loops

### 1. The Verifier Must Be Harder Than the Task

If your test is easier to pass than the real requirement, the loop will find the easiest path that satisfies the test — not the correct solution. Write verifiers that are genuinely hard to fool.

### 2. State Belongs on Disk, Not in Context

Context windows degrade. Sessions end. Models forget. Anything a loop needs to remember goes in a file. Our steering + next-session-prompt pattern is correct. Extend it: every loop gets a state file.

### 3. Separate Generator from Verifier

The thing that writes code cannot be the thing that judges code. Same model, different invocation is acceptable. Same prompt, same context is not. Our A-Team/B-Team split is exactly this pattern.

### 4. Hard Stop at N Retries

No loop runs forever. Set a limit. 10 iterations for research. 3 retries for a build fix. 1 attempt for a data migration (if it fails, escalate). Without a hard stop, you get infinite token burn on unsolvable problems.

### 5. Promote Successful Patterns to Templates

When a loop solves a problem, extract the pattern. Next time that problem type appears, it's a template (Tier 2) not an exploration (Tier 3). Over time, more work moves from expensive iteration to cheap execution. This is how you control cost at scale.

---

## What We're Adding Next

Based on this analysis, our immediate loop engineering additions:

| Addition | Loop Type | Verifier |
|---|---|---|
| Post-pipeline data consistency check | Automated | MV = quality.measure, quality.score = MV |
| Engine smoke test | Automated | All 57 engines import + have MEASURE_ID |
| API health probe | Automated | /actuator/health + /scores returns non-empty |
| Frontend build on save | Automated | Vite build passes |
| Measure Evidence pre-compute | Scheduled | Evidence counts > 0 for orgs with data |

These are all Tier 1 loops — cheap verifiers, high value, zero token cost once built.

---

## The Bottom Line

Will was right: if you're still prompting, you're doing it wrong. But the correction isn't "loop everything" — it's "loop the mechanical, gate the judgment, and invest in honest verifiers."

Our system is already 70% there. The missing 30% is automated verification that runs without us asking. That's what we build next.

---

*Written from real-world experience: 13 sessions, 199 measures, 3 orgs, 1 demo deadline.*
*Agentic Stage-Gate Governance v1.1 — July 2026*
