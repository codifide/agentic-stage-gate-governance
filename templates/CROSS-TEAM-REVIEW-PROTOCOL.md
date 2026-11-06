# Cross-Team Review Protocol

Who reviews the reviewers? This protocol periodically reviews the **persona definitions themselves**: A-Team definitions are attacked by B-Team critics, and B-Team definitions are assessed by A-Team builders. The goal is to keep both sets of definitions sharp, current, and operationally honest.

This reviews **definitions**, not code or gate artifacts. Code and gate review follow `04-adversarial-review.md` and `11-tiered-adversarial-review.md`. Persona roles are defined in `steering/02-personas.md`; this template does not redefine them.

---

## Independence Requirement (read first)

Per `00-welcome.md` §3, B-Team review is never self-conducted. The same applies here, in both directions:

- Each review runs in a **separate context** that has not seen the author's reasoning, on a **different model family** when one is available. If only the same family is available, isolate the context, label the review `same-family`, and the Human Steward acknowledges it.
- The A-Team assessment of B-Team definitions is evidence-gathering by a builder-side reviewer. It is not a substitute for the B-Team.
- If you cannot start an independent context, **prepare the review package and stop**. Do not role-play both teams in one session and record the result as a completed review.
- Do not send secrets, credentials, or sensitive data in persona files to an external model. Redact first (`04`, "Data Handling Before You Send Anything").

Everything below assumes these rules hold. An in-context "you are now the B-Team" prompt does not satisfy them.

---

## The Loop

```
1. Prepare packages: A-Team definitions for B-Team review, B-Team definitions for A-Team review
2. Run each review in an independent context (or package and stop)
3. Record findings with the Review Level and reviewer model/context labelled
4. Human Steward decides which findings to accept, defer, or reject
5. Implement accepted fixes as reviewed changes
6. Repeat on the schedule below
```

Findings are recommendations. The Human Steward dispositions them; no persona closes its own finding.

---

## B-Team Reviews A-Team Definitions

Suggested questions per A-Team persona. Use the critics and specialties as defined in `02-personas.md`.

| Critic | Question |
|--------|----------|
| **Vex** | What is the weakest aspect of this definition? What fails first? |
| **Rook** | Are authority boundaries clean? Any overlaps or contradictions with other personas or with `00-welcome.md`? |
| **Blaze** | Can this persona be shown to be working? Or is the behavior aspirational with no observable check? |
| **Cipher** | Does this persona's described access exceed what it needs? |
| **Slate** | Will this still work late in a long session when context is full or compacted? |

### Expected output

A structured findings report:
- Critical findings (fix before relying on the definition)
- Important findings (fix soon)
- Cross-cutting issues (affect several personas)
- Specific recommendations

---

## A-Team Reviews B-Team Definitions

Suggested questions per B-Team critic, asked from the builder side:

| Builder | Question |
|---------|----------|
| **Amelia** | Is the technical knowledge accurate? Would the challenges catch real bugs? |
| **Winston** | Do they probe the right architectural weaknesses? |
| **Tessa** | Would the challenges lead to better tests, or just noise? |
| **Aegis** | Do they fit the gate process? At which gate or Review Level would you invoke them? |

### Expected output

A structured assessment:
- Coverage map (which failure modes are covered, which are gaps)
- Per-critic findings (is the core question the right one?)
- Missing attack vectors
- Sharpening recommendations

---

## Recurring Findings

These themes tend to appear in every cross-review of persona definitions:

1. **The single-model problem.** Personas are prompts to the same model, so they share blind spots. Persona separation is not independence. Real enforcement comes from independent review, tests, linters, CI, and human decisions.
2. **Opt-in defeats the purpose.** If every persona is loaded manually, most work happens with none loaded. Keep a short always-on core (`CORE-RULES-ALWAYS-ON.md`) and load full definitions on demand.
3. **Context budget.** Loading every persona leaves no room for the work. Use the two-tier approach.
4. **Activation language is aspirational.** A definition that says a persona "activates automatically" describes intent, not mechanism. Unless a hook or CI check exists, activation is the agent's or human's choice. Hooks of type `agent` are advisory (`templates/HOOKS-SESSION-STATE.md`). [UNVERIFIED] whether a given runtime fires a given hook event reliably.
5. **Self-assessment is not assessment.** One model grading output it produced under another persona's name has the same blind spots. Evidence from tests, scanners, and independent reviewers carries more weight.
6. **Stale embedded facts.** Counts, dates, and status snapshots inside persona files go out of date. Prefer references to a source of truth.

---

## Procedure

### Step 1: Build the packages

Assemble the persona files under review into a package per `templates/B-TEAM-REVIEW-PACKAGE.md`. Include a short charge for the reviewer, for example:

> Attack these persona definitions. Find weaknesses, contradictions with the core rules, unenforced claims, and operational fragility. Report findings by severity.

> Assess whether these critics are sharp enough. Are they asking the right questions? What failure modes do they miss?

### Step 2: Run independently

Send each package to an independent reviewer per `04`, or stop and hand the package to the Human Steward. Record the Review Level (persona definitions that change harness behavior are harness edits and therefore R3 per `11`).

### Step 3: Disposition and implement

- The Human Steward accepts, defers, or rejects each finding.
- Accepted fixes go in as normal changes with a `Review-Level:` trailer.
- Document both reviews as steering artifacts for the audit trail (Quill may record the discussion; it does not edit the findings).

### Step 4: Verify

Re-run the review against the updated definitions in an independent context and confirm accepted critical findings are resolved.

---

## Frequency

| Trigger | Action |
|---------|--------|
| After initial persona creation | First cross-review |
| After major system changes (new services, domains, compliance requirements) | Re-review affected personas |
| Quarterly | Staleness check on examples and embedded facts |
| After a production incident | Check whether a definition needs updating based on what failed |
