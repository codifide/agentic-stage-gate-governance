---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Auto-Research Protocol — Autonomous Solution Iteration

This protocol enables autonomous research and development cycles where the AI team iterates on solutions until convergence, with human oversight at key decision points.

---

## How It Works

**User provides:** A problem statement
**System delivers:** Iteratively refined solutions with evidence

The system runs autonomous cycles of:
1. **Generate** → multiple solution approaches
2. **Evaluate** → adversarial review and scoring  
3. **Refine** → improve based on findings
4. **Converge** → when improvements plateau or target is met

**Human involvement:** Gate decisions only. The system presents evidence; you decide continue/ship/kill.

---

## Auto-Research Cycle

### Initialization (Human Input Required)
```
Problem: [Your problem statement]
Success Criteria: [How you'll know it's solved]
Constraints: [Technical, business, timeline constraints]
Quality Bar: [Performance, security, accessibility requirements]
```

### Autonomous Iteration Loop
```
Phase 1: GENERATE (Harper + Winston + Amelia)
├── Generate 3-5 solution approaches
├── Estimate effort, risk, complexity for each
└── Select top 2-3 for development

Phase 2: BUILD (Amelia + Tessa + Sentinel)  
├── Implement selected approaches
├── Write comprehensive tests
├── Security review
└── Performance benchmarking

Phase 3: EVALUATE (B-Team Review)
├── Adversarial review of each approach
├── Score: correctness, performance, maintainability, security
├── Identify weaknesses and improvement vectors
└── Rank approaches by composite score

Phase 4: REFINE (A-Team)
├── Address B-Team findings
├── Combine best elements across approaches
├── Generate next iteration candidates
└── Check convergence criteria

Phase 5: CONVERGE CHECK
├── Has improvement plateaued? (< 5% gain over 2 cycles)
├── Has quality bar been met?
├── Has iteration limit been reached? (max 10 cycles)
└── If not converged: return to Phase 1
```

### Human Decision Points (Gates)
- **G0:** Approve problem definition and success criteria
- **G-MID:** Review progress every 3 cycles, continue/pivot/stop
- **G-FINAL:** Accept best solution or request additional iteration

---

## Convergence Criteria

**Auto-stop when ANY of:**
- Quality bar met + B-Team approval
- Improvement < 5% for 2 consecutive cycles  
- 10 iteration cycles completed
- Diminishing returns detected (effort > benefit)

**Human escalation when:**
- Fundamental blocker discovered
- Requirements ambiguity prevents progress
- Technical constraint violation

---

## Solution Scoring Matrix

Each solution approach is scored 0-100 on:

| Dimension | Weight | Measurement |
|-----------|--------|-------------|
| **Correctness** | 30% | Passes all test cases, handles edge cases |
| **Performance** | 25% | Meets NFR targets (latency, throughput) |
| **Maintainability** | 20% | Code quality, documentation, modularity |
| **Security** | 15% | Threat model compliance, no critical findings |
| **Feasibility** | 10% | Implementation complexity, timeline fit |

**Composite Score = Σ(dimension × weight)**

B-Team provides adversarial scoring; A-Team provides evidence.

---

## Output Artifacts

Each cycle produces:
```
/auto-research/{problem-id}/
├── cycle-{n}/
│   ├── approaches-generated.md      # All approaches considered
│   ├── implementations/            # Working code for each approach  
│   ├── test-results.md            # Performance + correctness evidence
│   ├── b-team-review.md           # Adversarial findings
│   ├── scores.json                # Quantitative scoring
│   └── refinements.md             # Improvements for next cycle
├── convergence-analysis.md         # Why the system stopped iterating
├── final-recommendation.md         # Best approach with evidence
└── implementation-ready/           # Production-ready code + tests
```

---

## Usage Examples

### Simple Usage
```
User: "Auto-research: Build a rate limiter that can handle 100k requests/second with Redis backend"

System: [Runs 4 cycles, presents 3 final approaches with benchmarks]

User: "Ship approach B"
```

### Complex Usage  
```
User: "Auto-research: Design a permission system for healthcare records that's HIPAA compliant and supports role-based access with audit trails"

Success Criteria:
- Sub-100ms permission check latency
- Complete audit trail
- HIPAA compliance verified
- Supports 10k concurrent users

System: [Runs 7 cycles, iterating through database designs, caching strategies, audit mechanisms]

User: [Reviews at cycle 3, asks for focus on audit performance]

System: [Continues 4 more cycles focused on audit optimization]

User: "Ship the final hybrid approach"
```

---

## Personas in Auto-Research

### A-Team (Builders)
- **Harper:** Defines success criteria, prioritizes dimensions
- **Winston:** Generates architectural approaches  
- **Amelia:** Implements and benchmarks solutions
- **Tessa:** Ensures comprehensive test coverage
- **Sentinel:** Security review and threat modeling
- **Forge:** Performance optimization and NFR verification

### B-Team (Critics) 
- **Vex:** Leads adversarial scoring, finds approach weaknesses
- **Cipher:** Attacks security assumptions
- **Jett:** Finds implementation bugs  
- **Blaze:** Destroys insufficient tests
- **Volt:** Challenges performance claims

### Automatic Role Assignment
The system automatically assigns personas based on problem domain:
- Security-sensitive → Sentinel + Cipher lead
- Performance-critical → Forge + Volt lead  
- Data handling → Ruth + Wren lead
- User-facing → Ember (accessibility) active

---

## Integration with Stage-Gate

Auto-research operates **within** gates, not instead of them:

- **G0:** Define the problem for auto-research
- **G1:** Success criteria become auto-research targets  
- **G2/G3:** Auto-research explores architecture space
- **G4:** Auto-research produces tested implementations
- **G5:** Human reviews auto-research recommendation
- **G6:** Post-deployment learning feeds back into the system

---

## Guardrails

### Safety Limits
- Maximum 10 iteration cycles per problem
- Maximum 4 hours wall-clock time per cycle
- Human approval required for any external API calls
- No file system modifications outside designated research directory

### Quality Gates
- Every cycle must pass B-Team review to continue
- Security review required if problem touches sensitive data  
- Performance benchmarks must be reproducible
- All code must maintain 100% test coverage

### Escalation Triggers
- 3 consecutive cycles with no improvement → human review
- Any CRITICAL finding from B-Team → human review
- Resource usage exceeds limits → pause and notify

---

## Activation

Say any of these to trigger auto-research:
- "Auto-research: [problem statement]"
- "Iterate until optimal: [problem statement]"  
- "Research and develop: [problem statement]"
- "Find the best solution for: [problem statement]"

Add constraints with:
- "Success criteria: [specific targets]"
- "Constraints: [limitations]"
- "Focus on: [performance|security|maintainability]"

---

## Example Problems Well-Suited for Auto-Research

**Algorithmic:**
- "Build the fastest JSON parser for our data format"
- "Design optimal database indexing for our query patterns"
- "Create the most memory-efficient image processing pipeline"

**Architectural:**  
- "Design authentication system balancing security and UX"
- "Build caching layer that minimizes cache misses"
- "Create deployment pipeline with zero-downtime guarantees"

**Optimization:**
- "Minimize API response times while maintaining accuracy"  
- "Reduce infrastructure costs while meeting SLA"
- "Optimize mobile app for battery life and performance"

---

*Auto-Research Protocol v1.0 — February 2027*