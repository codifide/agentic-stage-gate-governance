# We Were Already Doing Loop Engineering. We Just Didn't Know It.

*A pragmatic guide to the pattern everyone's talking about — written from 13 sessions of shipping real healthcare software with AI agents.*

---

A colleague dropped a bomb in our team chat last week: "If you are still prompting, we are dead."

I didn't know what he meant. He said: "Just go deep on Loop Engineering."

So we did. And what we found was both validating and humbling. Validating because our system — built over a year of shipping a CMS-certified healthcare quality platform with AI agents — already embodied most of what Karpathy's loop engineering describes. Humbling because the gaps we'd been ignoring were exactly the ones that kept biting us.

This is what we learned.

---

## What Loop Engineering Actually Is (In One Paragraph)

Stop being the middleman between every AI turn. Define a goal. Define an automated verifier that isn't the AI grading its own work. Give the loop persistent state so it remembers what it tried. Let it iterate until the verifier passes or you hit a retry limit. That's it.

Three components. Miss one and you've built a money burner.

---

## The Origin Story Nobody Tells

In March 2026, Andrej Karpathy released `autoresearch` — about 630 lines of code. The agent edits `train.py`, runs training for 5 minutes, keeps improvements, rolls back failures, repeats. In two days it ran 700 experiments and found 20 improvements that humans missed.

But here's what the breathless coverage left out: the system only worked because training loss is a *perfect* verifier. It's numeric. It's unambiguous. It's fast to compute. You can't argue with it.

Most software doesn't have that luxury. "Is this the right architecture?" doesn't have a loss function.

---

## What We Were Already Doing

We've been building a MIPS quality measure platform — 199 clinical measures, 37,000 patients, real Medicare compliance requirements. Here's what our system looked like before we'd ever heard the term "loop engineering":

**Our ETL pipeline** runs 7 steps automatically: compute measures → generate care gaps → refresh indicators → backfill CPTs → compute recommendations → refresh MIPS score → update quality.score. That's a loop with a state file (the ETL run log) and verification (row counts, score computation).

**Our session state** (`next-session-prompt.md`) persists what was accomplished, what's next, and what the environment looks like. That's Karpathy's "state on disk, not in context" — we just called it "institutional memory."

**Our A-Team/B-Team persona system** separates builders from critics. The generator can't grade its own homework. That's the generator-verifier pattern with a different name.

We were doing loop engineering. We just had gaps.

---

## The Gaps That Kept Biting Us

In one session, we shipped 8 new measure engines. They all "worked" — they imported cleanly, the build passed. But when a clinical analyst looked at the Quality Measures page, the MIPS Composite showed "4.0" instead of "22.5/30." The HEDIS section was mislabeled. Inverse measures showed warning icons when they should have shown green.

The build passed. The loop "succeeded." But the output was wrong.

Why? Because our verifier was a build check. The actual requirement was CMS-compliant display logic. No test encoded that. The loop closed on a weak verifier.

In another session, we left 32,000 patients with stale numerator data because the materialized view hadn't been refreshed after the engine re-ran. The pipeline had a step for that — but it came AFTER the step that failed (deadlock). No circuit breaker. No alerting. We found out because the demo looked wrong.

These aren't failures of the AI. They're failures of the harness.

---

## The Hybrid Model We Landed On

After researching Karpathy's work, reviewing our own patterns, and running a full persona review (8 reviewers, 2 new personas created specifically for this), we arrived at a three-layer model:

```
HUMAN LAYER     →  Goals, design decisions, gate approvals (5 minutes)
GATE LAYER      →  Persona review, CMS compliance, architecture (30 minutes)
LOOP LAYER      →  Build, test, deploy, verify, repeat (runs overnight)
```

Each task finds its correct altitude:

- "Implement MIPS_476 with proper IPSS score extraction" → Human defines goal, Gate verifies CMS compliance, Loop handles the mechanical coding and testing.
- "Is our pipeline too slow for large orgs?" → Human flags it, Gate investigates architecture, Loop benchmarks and optimizes.
- "Refresh all materialized views after pipeline" → Pure loop. No human needed. Verifier: MV row counts match source tables.

The insight is that most teams try to put everything in one layer. Either everything needs approval (slow) or everything runs free (dangerous). The sweet spot is knowing which layer each task belongs in.

---

## Five Rules for Production Loops

1. **The verifier must be harder than the task.** If your test is easier to pass than the real requirement, the loop finds the easiest path — not the correct one.

2. **State belongs on disk.** Context windows degrade. Sessions end. Models forget. If a loop needs to remember something, write it to a file.

3. **Separate generator from verifier.** The thing that writes code cannot judge code. Same model, different invocation is acceptable. Same session is not.

4. **Hard stop at N retries.** No loop runs forever. 10 iterations for research. 3 retries for a build fix. Without limits, you get infinite token burn on unsolvable problems.

5. **Promote successful patterns.** When a loop solves a problem, extract the pattern. Next time, it's a template. Over time, work migrates from expensive exploration to cheap execution.

---

## What We're Building Next

Tests. Specifically: the tests that would have caught this session's bugs. Not aspirational 100% coverage — targeted verification for the things that actually broke:

- Does the MV match quality.measure after pipeline runs?
- Does quality.score match the MV?
- Do all 57 eCQM engines have MEASURE_ID set?
- Does the API return non-empty data for known-good orgs?

These become the verifiers. Once they exist, the pipeline can run overnight and we trust the output without reading every row. That's the unlock.

---

## The Uncomfortable Truth (Ink's Contribution)

Here's what nobody in the loop engineering hype wants to say: **most software problems don't have clean verifiers.**

Training loss is numeric. Test pass/fail is binary. But "Is this measure engine CMS-compliant?" requires a human expert with 10 years of MIPS knowledge. "Is this UI clear to a quality administrator?" requires watching someone use it. "Will this scale to 2,200 clients?" requires production traffic.

Loop engineering works brilliantly for the 60% of software work that's mechanical — the ETL, the migrations, the refactoring, the optimization. For the other 40% — the design, the compliance, the judgment calls — you still need gates. You still need humans. You still need the uncomfortable conversation where someone says "this isn't right" and the agent has to start over.

The teams that pretend everything can be looped will ship fast and break things that matter. The teams that refuse to loop anything will be too slow to compete. The sweet spot is knowing the difference.

We learned that the hard way this week.

---

## The Bottom Line

If you're still writing individual prompts for every task, you're working too hard. But if you're letting loops run without honest verifiers, you're working dangerously.

The answer isn't one or the other. It's both — with clear boundaries between them.

Loop the mechanical. Gate the judgment. Invest in honest verifiers. And when the demo is tomorrow, make sure the materialized view got refreshed.

---

*Douglas Jones leads healthcare AI engineering at Sharecare, where the team has shipped 199 CMS quality measure engines using agentic development with stage-gate governance.*

*The full Loop Engineering Guide and the Agentic Stage-Gate Governance framework are open source at [github.com/codifide/agentic-stage-gate-governance](https://github.com/codifide/agentic-stage-gate-governance).*


---

## Appendix: Stage-Gate vs Loop Engineering — A Comparison

### Stage-Gate System (What We Had Before)

Our Agentic Stage-Gate Governance system, built over a year of production work, operates on a simple principle: **"AI builds. Humans decide. Evidence proves."**

| Strength | Description |
|----------|-------------|
| Judgment at every step | 7 gates (G0–G6) ensure no work ships without human approval |
| Adversarial review | B-Team critics use a DIFFERENT model to find weaknesses |
| CMS compliance | Domain experts (Gretchen) validate clinical logic at gates |
| Audit trail | Every gate produces evidence artifacts — traceable, defensible |
| Persona separation | 12 A-Team builders + 12 B-Team critics prevent groupthink |

| Weakness | Description |
|----------|-------------|
| Human bottleneck | Every decision waits for the human — even mechanical ones |
| No overnight execution | Work stops when the session ends |
| No automated verification | "It builds" was the only check between gates |
| Reactive, not proactive | Doesn't catch stale data until someone looks at a screen |
| Flow state interruption | Gate ceremonies can break momentum on simple tasks |

### Loop Engineering (What Karpathy Proposes)

| Strength | Description |
|----------|-------------|
| Autonomous execution | Runs 700 experiments in 2 days — no human in the inner loop |
| Automated verification | Verifier closes the loop without human review |
| Overnight capability | Define goal → sleep → wake up to results |
| Self-recovery | Failed attempts roll back automatically, loop continues |
| Compounding search | Each iteration builds on prior knowledge (state file) |

| Weakness | Description |
|----------|-------------|
| Requires measurable objectives | Can't loop "design something good" |
| Comprehension debt | Ships code faster than anyone can understand it |
| Verifier ≠ Correct | Passing tests doesn't mean the output is RIGHT |
| Token cost on retries | Failed iterations burn money with no return |
| No judgment layer | Can't ask "should we even be doing this?" |
| Runaway risk | Bad loops at 3am produce 40 commits of nonsense |
| Cognitive surrender | Teams stop thinking because "the loop verified it" |

### The Merged System (What We Built)

Neither system alone is sufficient. Stage-gate is too slow for mechanical work. Loop engineering is too dangerous for judgment work. The merged system puts each task at the correct altitude:

```
┌────────────────────────────────────────────────────────┐
│ STAGE-GATE LAYER (Judgment)                            │
│                                                        │
│  Human goals → Persona review → Gate decisions         │
│  CMS compliance, architecture, design, priorities      │
│                                                        │
│  When: Requirements, design, compliance, go/no-go      │
│  Frequency: Per initiative (days/weeks)                │
│  Cost: Human time (expensive but irreplaceable)        │
├────────────────────────────────────────────────────────┤
│ LOOP LAYER (Execution)                                 │
│                                                        │
│  Goal → Iterate → Verify → State → Iterate → Done     │
│  ETL, testing, optimization, data consistency          │
│                                                        │
│  When: Implementation, verification, maintenance       │
│  Frequency: Continuous (hours/overnight)               │
│  Cost: Tokens + compute (cheap and getting cheaper)    │
└────────────────────────────────────────────────────────┘
```

### How Merging Solved Both Systems' Weaknesses

| Original Weakness | How the Merge Fixes It |
|---|---|
| **Stage-gate: human bottleneck** | Loops handle mechanical execution without waiting |
| **Stage-gate: no overnight work** | Loops run pipelines and verify while you sleep |
| **Stage-gate: no automated verification** | Loop verifiers catch stale data, broken APIs, schema drift |
| **Loop: no judgment** | Gates still control design, compliance, architecture |
| **Loop: comprehension debt** | Gates force documentation and persona review before shipping |
| **Loop: runaway risk** | Gates define scope; loops can't exceed what's been approved |
| **Loop: cognitive surrender** | B-Team adversarial review remains mandatory at gates |
| **Loop: verifier ≠ correct** | Gretchen reviews correctness; loops only verify consistency |

### Decision Framework: Gate It or Loop It?

Ask these three questions:

1. **Can a machine verify the output?** (tests, metrics, row counts, schema checks)
   - Yes → Loop it
   - No → Gate it

2. **Is the cost of being wrong catastrophic?** (CMS audit, patient safety, data loss)
   - Yes → Gate it, even if a machine CAN verify
   - No → Loop it

3. **Will this task repeat?** (ETL runs, deployments, data refreshes)
   - Yes → Loop it (amortize verifier construction cost)
   - No → Gate it (one-off judgment call)

### Real Examples From This Week

| Task | System Used | Outcome |
|---|---|---|
| Design measure evidence discovery feature | Stage-Gate (G0/G1, 5 personas) | Right architecture, clear requirements |
| Run ETL pipeline for all orgs | Loop (post_etl_pipeline + MV refresh) | 199 measures recomputed, data consistent |
| Fix Quality Measures page CMS compliance | Stage-Gate (Gretchen review, 8 findings) | Caught scoring errors no test would find |
| Rebuild quality-service Docker image | Loop (build → deploy → health check) | Mechanical, repeatable, no judgment needed |
| Decide whether to use Airflow | Stage-Gate (IT mandate review) | Killed it — domain judgment, not automatable |
| Verify MV matches quality.measure | Loop (SQL assertion) | Catches inconsistency without human looking |
| Write Medium article on loop engineering | Stage-Gate + Quill persona | Needs voice, narrative, honesty — can't loop "be insightful" |

### The Competitive Advantage

Most teams will adopt one system or the other:
- **All-gate teams** will be too slow. Every commit waits for approval.
- **All-loop teams** will ship fast and break regulated things. CMS doesn't accept "the loop verified it."

We're building both — and the judgment to know which to use when. That's the moat. In healthcare, where a wrong measure calculation can cost a practice $75K in MIPS penalties, you can't afford to loop your compliance logic. But you also can't afford to manually verify 199 measures × 220 clients × 4 data refresh cycles per year.

The merged system handles 175,560 measure-client-cycles per year autonomously (loops) while keeping 42 CMS-regulated decisions under human authority (gates).

That's the sweet spot.
