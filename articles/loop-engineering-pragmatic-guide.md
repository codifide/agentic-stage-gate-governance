# We Were Already Doing Loop Engineering. We Just Didn't Know It.

*"If you are still prompting, we are dead."*

I didn't know what he meant. I'd already integrated Karpathy's autoresearch concept into the system — autonomous iteration with adversarial review and convergence criteria. But "loop engineering" was a different frame. A colleague said it like it was obvious — like I should have already moved past something fundamental. He said to research it. So I did.

What I found was both validating and humbling. Validating because the governance system I'd spent hundreds of hours building already embodied most of what the research describes. Humbling because the gaps I'd been ignoring — the ones that kept biting me in demos and making me ask "why can't you get this right after three tries?" — were exactly the problems loop engineering solves.

This is the story of how we got here, what we learned, and where it goes next.

---

## The Evolution: How We Got Here

A year ago I started using AI for coding the way most people do — as a better Stack Overflow. "How do I parse a C-CDA XML document?" Immediate answer, no context switching, faster than searching forums.

Then MCP connections changed everything. Suddenly the AI could pull database state, server logs, and configuration files together in one context. We started solving production issues that humans couldn't correlate manually — the kind where the answer lives across 4 systems and 6 log files.

That earned enough trust for the next step: building components. Well-defined modules, one at a time, with human review after each. An ETL connector. A measure engine. A frontend page.

Then whole systems. Not one component — the full stack. Architecture, data model, API, frontend, deployment. Simulating a traditional development team at 10x speed. Architect drafts the design. Developer implements. Tester verifies. Security reviews. The AI played all the roles.

But speed without governance produced garbage that looked like gold until you inspected it closely. The code compiled. The build passed. But the MIPS score showed 4.0% instead of 22.5/30. The materialized view was stale. The measure showed "Met: 0" when the data said 19. The AI said "done" when the system was internally inconsistent.

That's when we built the governance layer — stage-gates, adversarial review, domain expert personas, persistent session state. Not to slow things down, but to catch the 40% of errors that "it builds" doesn't catch.

And now we're adding the final piece: automated verification loops that run without asking permission. Not replacing the governance — augmenting it with mechanical consistency checks that catch drift between pipeline runs.

Each stage earned the right to exist by solving the pain of the previous one.

---

## What Loop Engineering Actually Is

Three components. Miss one and you've built a money burner:

**Verifier** — an automated gate that isn't the AI grading its own homework. Tests, metrics, schema checks. Something that says "no" without human intervention.

**State** — persistent record of what's been tried and what failed. Survives session boundaries. Tomorrow resumes instead of restarts.

**Stop condition** — "done" must be definable. Verifier passes, or you hit a retry limit. Open-ended goals without measurable completion are just prompting wearing a loop costume.

In March 2026, Andrej Karpathy demonstrated this with `autoresearch` — 630 lines of code that ran 700 ML training experiments in two days, finding 20 improvements humans missed. The key insight: with an objective metric, you shouldn't be the experiment runner. Remove yourself from the inner loop and let verification drive search.

---

## The Real Pain Point

Let me be direct about where this comes from.

I spent hundreds of hours building the governance harness — personas, gates, steering files, session state — not because I love process, but because I was tired of correcting the AI on the same mistakes repeatedly. The same stale data left behind. The same hardcoded values that should be database-driven. The same "it builds" confidence when the output was clinically wrong.

The harness simulates all the checks and balances of a real development team: the tech lead who catches architecture drift, the QA engineer who tests the output, the domain expert who says "that's not how CMS works." It reduced the frustration significantly. But it didn't eliminate it.

The critical gap was always *systems coherence verification*. An AI that writes beautiful code to populate `quality.measure`, then forgets to refresh the materialized view the API reads from, has produced a system where the database says one thing and the screen says another. No persona review catches that — it only manifests at runtime, across service boundaries.

That's what loop engineering adds: the ability to say "after every pipeline run, verify that every downstream artifact matches the source of truth." Not as a suggestion. As an automated gate that fails loudly when things drift.

---

## The Timing Question

When do you install these gates?

**Don't gate during discovery.** When you're building 8 measure engines in an afternoon, changing the API contract twice, pivoting the UI based on live feedback — tests are drag. You need flow state. The human IS the verifier.

**Gate when interfaces solidify.** Once the same bug bites you twice. Once the pipeline steps are stable. That's when you know the interface has settled enough to be worth encoding. The signal is: it broke because of *drift*, not *change*.

**Gate what repeats.** If you run it once, verify manually. If you run it daily for 220 clients, gate it. Verifier construction cost ÷ future executions = ROI. For 880 executions/year, even expensive tests pay for themselves in a month.

---

## The Merged Model

Neither stage-gates alone nor loops alone are sufficient.

Stage-gates without loops: every mechanical task waits for human approval. Slow.

Loops without gates: everything runs autonomously, including compliance logic. Dangerous.

The merged system gives each task its correct altitude:

- *"Implement MIPS_476 with proper IPSS score extraction"* → Human defines goal. Gate verifies CMS compliance. Loop handles coding and testing.
- *"Is our pipeline too slow for large orgs?"* → Human flags it. Gate investigates architecture. Loop benchmarks and optimizes.
- *"Refresh all materialized views after pipeline"* → Pure loop. No human needed. Verifier: row counts match source tables.

Most teams try to put everything in one layer. Either everything needs approval (slow) or everything runs free (dangerous). The sweet spot is knowing which layer each task belongs in.

---

## Five Rules for Production Loops

1. **The verifier must be harder than the task.** If your test is easier to pass than the real requirement, the loop finds the easiest path — not the correct one.

2. **State belongs on disk.** Context windows degrade. Sessions end. Models forget. If a loop needs to remember something, write it to a file.

3. **Separate generator from verifier.** The thing that writes code cannot judge code.

4. **Hard stop at N retries.** No loop runs forever. Without limits, you get infinite token burn on unsolvable problems.

5. **Promote successful patterns.** When a loop solves a problem, extract the pattern. The first time costs tokens. The 220th time costs nothing.

---

## Cost Control

Three mechanisms:

**Tier the loops.** Pre-computed checks (row counts, schema matches) cost zero tokens. Parameterized SQL verifiers cost zero tokens. Only truly novel verification needs AI — rare and cached.

**Invest in the verifier, not the loop.** A good test suite runs in 10 seconds and catches 90% of problems. Cheaper than an AI retrying 5 times at 10,000 tokens each.

**Promote aggressively.** Every time a loop discovers something (like "IPSS scores are regex-extractable from notes"), promote it to a template. First client costs tokens. The 220th costs nothing.

---

## The Uncomfortable Truth

Here's what nobody in the loop engineering hype wants to say: most software problems don't have clean verifiers.

Training loss is numeric. Test pass/fail is binary. But "Is this measure engine CMS-compliant?" requires a human expert with 10 years of MIPS knowledge. "Is this UI clear to a quality administrator?" requires watching someone use it. "Will this scale to 2,200 clients?" requires production traffic.

Loop engineering works brilliantly for the 60% that's mechanical. For the other 40% — design, compliance, judgment calls — you still need gates. You still need the uncomfortable conversation where someone says "this isn't right."

The teams that pretend everything can be looped will ship fast and break things that matter. The teams that refuse to loop anything will be too slow to compete.

The sweet spot is knowing the difference.

---

## The Bottom Line

Loop the mechanical. Gate the judgment. Invest in honest verifiers.

The teams that get this right won't just ship faster — they'll ship with confidence. And in healthcare, where a wrong number can cost a practice $75,000 in MIPS penalties, confidence isn't a luxury. It's the product.

---

*Douglas Jones leads healthcare AI engineering at Sharecare, where the team has shipped 199 CMS quality measure engines serving millions of patients across hundreds of organizations using agentic development with stage-gate governance.*

*The [Agentic Stage-Gate Governance](https://github.com/codifide/agentic-stage-gate-governance) framework is open source.*

---

## References

1. Karpathy, A. (2026). *AutoResearch*. [github.com/karpathy/autoresearch](https://github.com/karpathy/autoresearch)
2. Fortune (2026). "'The Karpathy Loop': 700 experiments, 2 days, and a glimpse of where AI is heading." [fortune.com](https://fortune.com/2026/03/17/andrej-karpathy-loop-autonomous-ai-agents-future/)
3. Bilevel Autoresearch: Meta-Autoresearching Itself (2026). arXiv:2603.23420
4. Cooper, R.G. (1986). *Winning at New Products: Accelerating the Process from Idea to Launch*. Stage-Gate® methodology.
5. CMS MIPS Payment Adjustment. 42 CFR § 414.1405. Up to ±9% Medicare Part B adjustment based on composite performance score.
6. AI Builder Club (2026). "Karpathy's LOOPS.md: The Rules and What's Verified." [aibuilderclub.com](https://www.aibuilderclub.com/blog/loops-md-karpathy)

---

## Appendix: Stage-Gate vs Loop Engineering — Side-by-Side

### Stage-Gate Strengths & Weaknesses

| Strength | Weakness |
|----------|----------|
| Judgment at every step | Human bottleneck on mechanical tasks |
| Adversarial review (B-Team) | No overnight execution |
| CMS compliance via domain experts | No automated verification between gates |
| Full audit trail | Reactive — catches problems when humans look |

### Loop Engineering Strengths & Weaknesses

| Strength | Weakness |
|----------|----------|
| Autonomous overnight execution | Requires measurable objectives |
| Self-recovery on failure | Comprehension debt (ships faster than anyone reads) |
| Compounding search | Token cost on retries |
| No human bottleneck | No judgment layer |

### How Merging Fixes Both

| Weakness | How the Merge Solves It |
|---|---|
| Stage-gate: human bottleneck | Loops execute mechanical work without waiting |
| Stage-gate: no overnight work | Loops run pipelines while you sleep |
| Loop: no judgment | Gates still control design and compliance |
| Loop: comprehension debt | Gates force documentation before shipping |

### Decision Framework

Three questions:

1. **Can a machine verify the output?** → Yes: loop it. No: gate it.
2. **Is the cost of being wrong catastrophic?** → Yes: gate it, even if verifiable.
3. **Will this task repeat?** → Yes: loop it (amortize verifier cost).

### The Numbers

- 199 measures × 220 clients × 4 quarterly refreshes = **175,560 loop-cycles/year** (automated)
- Scaling to: 199 measures × 2,200 clients × millions of patients = **1.75M loop-cycles/year**
- 7 gates × 6 initiatives/year = **42 gated decisions/year** (human judgment)
- At scale ratio: **41,800 automated executions per human decision**

That's the leverage.
