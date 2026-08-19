# Cross-Team Review Protocol

## Purpose

A-Team builds. B-Team critiques. But who reviews the reviewers? This protocol ensures both teams remain sharp, relevant, and operationally effective by having each team adversarially review the other's definitions.

---

## The Loop

```
1. A-Team reviews B-Team: "Are our critics sharp enough?"
2. B-Team reviews A-Team: "Are the builders' boundaries correct?"
3. Both teams' findings are documented
4. Actionable fixes are implemented
5. Repeat quarterly (or after major system changes)
```

---

## B-Team Reviews A-Team

The B-Team asks of each A-Team persona:

| Critic | Question |
|--------|----------|
| **Vex** | What's the weakest aspect? What fails first? |
| **Rook** | Are authority boundaries clean? Overlaps? Contradictions? |
| **Blaze** | Can this persona be TESTED as working? Or is it aspirational? |
| **Cipher** | Does this persona have access to things it shouldn't? |
| **Slate** | Will this work at 3am when context is exhausted? |

### Expected Output

A structured findings report with:
- Critical findings (must fix before use)
- Important findings (should fix soon)
- Cross-cutting issues (affect multiple personas)
- Specific recommendations

---

## A-Team Reviews B-Team

The A-Team asks of each B-Team critic:

| Builder | Question |
|---------|----------|
| **Amelia** | Is the technical knowledge accurate? Would challenges catch real bugs? |
| **Winston** | Are they probing the RIGHT architectural weaknesses? |
| **Tessa** | Would their challenges lead to better tests? Or just noise? |
| **Aegis** | Do they fit into the gate process? When would you invoke them? |

### Expected Output

A structured assessment with:
- Coverage map (which failure modes are covered, which are gaps)
- Per-critic findings (is their core question the RIGHT question?)
- Missing attack vectors (what fails that no critic catches?)
- Sharpening recommendations

---

## Common Findings (From Production Use)

These findings appear in every cross-review we've run:

### 1. The Single-Model Problem
All personas are prompts to the SAME AI model. No true separation of concerns exists. The model has the same blind spots in every persona. External validation (CI, linting, human review) is the only real enforcement.

### 2. Manual Inclusion Defeats the Purpose
If every persona is opt-in, 80% of work happens without any persona loaded. Fix: core-rules always-on + targeted activation hooks.

### 3. Context Budget Economics
Loading all personas leaves no room for code. Fix: two-tier system (40-line summary always on, full persona on demand).

### 4. Activation Triggers Are Aspirational
"Activates automatically when..." has no runtime implementation unless backed by hooks. Fix: create actual hooks for the most critical personas.

### 5. Self-Assessment Is Not Assessment
When the AI (as Aegis) reviews work that the AI (as Amelia) produced, it's evaluating its own output with the same blind spots. Fix: external tooling (tests, linters, CI) provides real evidence.

---

## Implementation

### Step 1: Run B-Team Review
Feed all A-Team persona files to the AI with the prompt:
> "You are the B-Team. Attack these persona definitions. Find weaknesses, contradictions, operational fragility. Be harsh — these serve real patients."

### Step 2: Run A-Team Review
Feed all B-Team persona files to the AI with the prompt:
> "You are the A-Team. Assess whether these critics are sharp enough. Are they asking the right questions? What failure modes do they miss?"

### Step 3: Implement Fixes
- Critical findings → fix immediately
- Important findings → add to backlog
- Document both reviews as steering artifacts

### Step 4: Verify
- Re-run both teams against the updated definitions
- Confirm critical findings are resolved
- File reviews for audit trail

---

## Frequency

- **After initial persona creation:** Mandatory first cross-review
- **After major system changes:** New services, new domains, new compliance requirements
- **Quarterly:** Staleness check (are examples still relevant? Are metrics current?)
- **After production incidents:** Does a persona's definition need updating based on what failed?
