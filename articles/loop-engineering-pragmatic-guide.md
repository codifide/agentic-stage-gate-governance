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
