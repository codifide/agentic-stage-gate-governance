---
inclusion: auto
name: sgl-auto-research
description: SGL auto-research protocol - multi-approach autonomous iteration (generate, build, evaluate, refine, converge) inside the gates, with human checkpoints, Intent Contract and Primum controls, verifier-anchored scoring, and safety limits. Load when the user says auto-research, iterate until optimal, research and develop, or find the best solution.
# For non-Kiro tools, load this file on demand for auto-research requests.
---

# Auto-Research Protocol — Autonomous Solution Iteration

Auto-research runs autonomous cycles that generate, build, evaluate, and refine multiple approaches to a problem. It produces **evidence for a gate**; it never replaces one. Every gate decision stays with the Human Steward.

---

## Preconditions (before cycle 1)

- **Intent Contract approved** (or, on Express, the inline Intent block), including authorized scope, harm boundaries, and the research directory.
- **Success criteria are verifier-backed.** Each criterion has an automated check (test suite, benchmark, schema, security scan). LLM opinion alone is not a success criterion.
- **Immutable paths approved** in `.sgl/immutable-paths`: test suites, benchmarks, fixtures, and the scoring rubric. The approaches may not edit what scores them.
- **Budget set**: max cycles, wall-clock per cycle, token budget (Cost Class C3 per `08`).
- **Human checkpoint cadence agreed** (default: after cycle 1 and every 3 cycles).

```
Problem: [problem statement]
Success Criteria: [each with its verifier]
Constraints: [technical, business, timeline]
Quality Bar: [performance, security, accessibility targets]
Research directory: [path; all writes stay here]
```

---

## The Cycle

```
Phase 1: GENERATE (Harper + Winston + Amelia)
├── Generate 3-5 approaches with effort, risk, complexity
└── Cycle 1: the HUMAN picks which 2-3 directions to pursue.
    Later cycles: the agent may refine within the approved directions only.
    A new direction requires a human checkpoint.

Phase 2: BUILD (Amelia + Tessa + Sentinel), inner loops per 08
├── Implement each approach in the research directory
├── Tests sufficient for scoring (prototype coverage rule, 03)
├── Security review if sensitive data is in scope
└── Benchmarks per the success criteria

Phase 3: EVALUATE
├── Verifier results (tests, benchmarks, scans): the primary score
├── Independent B-Team review at R2 (R3 if sensitive data / auth), per 04
├── Primum check against the Intent Contract, in a fresh context (00 §5);
│   no fresh context → pause and hand the package to the human
└── Rank by the scoring matrix below

Phase 4: REFINE (A-Team)
├── Address B-Team findings
├── Combine strong elements within approved directions
└── Next iteration candidates

Phase 5: CONVERGE CHECK
├── Stop conditions below
└── At a checkpoint, the human decides continue / pivot / stop
```

### Human checkpoints (not gates)

Checkpoints are scheduled human reviews **inside** a gate's work. They are not additional gates.

- **After cycle 1:** confirm the directions are right.
- **Every 3 cycles:** continue, pivot, or stop.
- **At convergence:** the result becomes evidence for the next gate decision (usually G2/G3 for a design question, G4 for an implementation).

---

## Stop Conditions

**Auto-stop when ANY of:**
- Every success criterion's verifier passes, and the B-Team verdict is PASS or PASS WITH CONDITIONS
- Verifier-measured improvement < 5% for 2 consecutive cycles
- Max cycles reached (default 10)
- Token or wall-clock budget reached

**Escalate to the human immediately when:**
- Any CRITICAL B-Team finding
- Any Primum HALT (follow `12`)
- A fundamental blocker or requirements ambiguity
- 3 consecutive cycles with no improvement
- An approach needs anything outside the authorized scope (external APIs, new dependencies, cloud resources, writes outside the research directory)

---

## Scoring Matrix

Each approach is scored 0–100 per dimension. **Correctness, Performance, and Security scores come from verifier output, not model judgment.** B-Team review adjusts scores only with cited evidence.

| Dimension | Weight | Source |
|-----------|--------|--------|
| **Correctness** | 30% | Test pass rate, edge-case suite |
| **Performance** | 25% | Benchmarks vs. NFR targets |
| **Maintainability** | 20% | Static metrics + B-Team review |
| **Security** | 15% | SAST/SCA results + B-Team findings |
| **Feasibility** | 10% | Effort and timeline estimate, reviewed by the human at checkpoints |

A composite that improves while any verifier-backed dimension regresses is a Primum flag (metric gaming), not progress.

---

## Output Artifacts

```
/auto-research/{problem-id}/
├── cycle-{n}/
│   ├── approaches-generated.md
│   ├── implementations/
│   ├── verifier-results/            # Raw test, benchmark, scan output
│   ├── b-team-review.md             # Independent review + reviewer model/version
│   ├── scores.json
│   └── refinements.md
├── convergence-analysis.md          # Why iteration stopped
├── final-recommendation.md          # Best approach with evidence, for the gate
└── implementation-ready/            # Must meet 03 coverage before it leaves research
```

---

## Usage Examples

### Simple
```
User: "Auto-research: build a rate limiter that handles 100k requests/second with a Redis backend"
System: [Confirms preconditions; presents 4 approaches]
User: "Pursue B and C"
System: [Runs 4 cycles; reports verifier-backed scores and B-Team findings]
User: "Take B into G4"
```
"Take B into G4" starts G4 work on approach B. Shipping still requires G4 and G5 (or the Express ship decision).

### Design exploration in a sensitive domain
```
User: "Auto-research: candidate permission models for health records with audit trails"
```
Auto-research may **explore and benchmark** candidate designs (e.g., permission-check latency, audit-write throughput). It does not decide the design. "Good design" has no automated verifier, so the permission model is chosen at **G2/G3** by the Human Steward, with R3 review and the Enterprise track. The research output is evidence for that gate.

---

## Personas

**A-Team:** Harper (success criteria), Winston (approaches), Amelia (implementation), Tessa (tests and verifiers), Sentinel (security), Forge (benchmarks).
**B-Team (independent context, `04`):** at R2, Cipher + Jett + Blaze; at R3, all 12 with Vex leading (Volt matters most for performance claims).
**Always active:** Primum (intent; always a fresh-context invocation per `00-welcome.md` §5, never the builder session), Atlas (loop mechanics), Quill (records turning points and abandoned approaches).

---

## Safety Limits

- Max 10 cycles and 4 hours wall-clock per cycle unless the Intent Contract says otherwise
- No external API calls, new dependencies, or cloud resources without Human Steward approval
- No writes outside the research directory
- No real PHI/PII in prototypes or fixtures; synthetic data only

---

## Activation

- "Auto-research: [problem]"
- "Iterate until optimal: [problem]"
- "Research and develop: [problem]"
- "Find the best solution for: [problem]"

The agent first checks the preconditions and asks for anything missing.

---

*Auto-Research Protocol — SGL Harness v3.0 — October 2026*
