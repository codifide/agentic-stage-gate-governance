---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Security Remediation SLA — Time-to-Fix Governance

Security vulnerabilities have defined remediation timelines. Every vulnerability is classified by severity and routed to either a **loop** (automated fix + verify) or a **gate** (human judgment required).

---

## Remediation Timelines

| Severity | Time to Patch | Deployment | Escalation |
|----------|---------------|------------|------------|
| **CRITICAL** | 24 hours | Emergency hotfix — bypasses sprint | CTO + Security Lead notified immediately |
| **HIGH** | 72 hours | Next available deployment window | Security Lead notified; blocks next release if unresolved |
| **MEDIUM** | 14 days | Current sprint | Tracked in backlog; escalates to HIGH if deadline missed |
| **LOW** | 30 days | Scheduled maintenance | Tracked; no escalation unless pattern emerges |

### Severity Classification

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Actively exploited OR remotely exploitable without authentication OR data exfiltration possible OR affects authentication/authorization bypass |
| **HIGH** | Remotely exploitable with authentication OR local privilege escalation OR known exploit exists in the wild OR dependency with CVSS >= 9.0 |
| **MEDIUM** | Requires specific conditions to exploit OR no known exploit but theoretical path exists OR dependency with CVSS 7.0-8.9 |
| **LOW** | Informational exposure OR requires physical access OR defense-in-depth violation with no direct exploit path OR dependency with CVSS 4.0-6.9 |

---

## Loop vs Gate Routing

### Loop It (Automated Remediation)

Route to a loop when ALL THREE conditions are met:
1. **Machine-verifiable fix** — existing tests + security scans confirm the fix
2. **Bounded change** — dependency bump, config change, or known-pattern code fix
3. **Low blast radius** — fix cannot introduce behavioral regression beyond what tests cover

**Examples that loop:**
- Dependency version bump for known CVE (SCA flagged, tests verify no regression)
- Adding input validation to a parameter (SAST flagged, unit tests verify)
- Rotating an exposed credential (secret scan flagged, integration test verifies)
- Updating TLS configuration (DAST flagged, connectivity test verifies)
- Removing a hardcoded secret (SAST flagged, build verifies)

**Loop verifier requirements:**
- Full test suite passes
- Security scan (SAST/SCA) confirms vulnerability resolved
- No new vulnerabilities introduced
- Build compiles clean
- API contract tests pass (if applicable)

### Gate It (Human Judgment Required)

Route to a gate when ANY of these apply:
1. **Fix requires architectural change** — the vulnerability is structural, not a single-point fix
2. **Business logic is involved** — the fix changes application behavior in ways tests can't fully verify
3. **Compliance interpretation needed** — the fix touches regulated data handling or consent flows
4. **Novel attack vector** — no existing test pattern covers this class of vulnerability
5. **Cross-service impact** — the fix affects multiple services or shared infrastructure

**Examples that require gates:**
- Redesigning an authorization model (architectural, business logic)
- Fixing a TOCTOU race condition in a payment flow (business logic, compliance)
- Responding to a novel prompt injection technique (novel vector, no existing verifier)
- Remediating a supply chain compromise affecting build infrastructure (cross-service, architectural)
- Adding encryption to a data store that was previously unencrypted (compliance, migration)

**Gate requirements:**
- Full B-Team adversarial review (Tier 2 or Tier 3 per `11-tiered-adversarial-review.md`)
- Threat model update documenting the new attack surface
- Regression test suite expanded to cover the vulnerability class
- Rollback plan documented and tested

---

## Automated Severity Classification

G-LOOP can auto-classify most vulnerabilities without human triage:

```
IF source = SCA (dependency vulnerability):
    severity = MAX(CVSS score mapping, known-exploit-in-wild bonus)
    route = LOOP (dependency bump + test)

IF source = SAST (code pattern):
    severity = rule_severity from scanner
    route = LOOP if fix is pattern-based, GATE if architectural

IF source = DAST (runtime finding):
    severity = based on exploitability + data exposure
    route = GATE (runtime issues often require behavioral understanding)

IF source = pen_test OR manual_report:
    severity = reporter classification (human-assigned)
    route = GATE (always — novel findings need judgment)

IF source = B-Team adversarial review:
    severity = finding classification (CRITICAL/MAJOR/MINOR)
    route = already in gate process
```

### Override Rules

- Any vulnerability in authentication, authorization, or encryption → minimum HIGH
- Any vulnerability with a public exploit → minimum HIGH
- Any vulnerability affecting > 50% of users → minimum HIGH
- Security Lead can override any classification upward (never downward without Director approval)

---

## Integration with Deployment Cadence

### Daily Deployment Model

For teams deploying daily:

| Change Type | Security Gate | Can Deploy Same Day? |
|---|---|---|
| CRITICAL fix (looped) | Automated verifiers pass | Yes — emergency path |
| CRITICAL fix (gated) | Expedited B-Team (Cipher + Jett only) | Yes — if review completes |
| HIGH fix (looped) | Automated verifiers pass | Yes |
| HIGH fix (gated) | Standard B-Team Tier 2 | Next day if review late |
| MEDIUM fix | Standard loop or gate per classification | Yes (loop) / Next sprint (gate) |
| LOW fix | Bundled with next feature deployment | Whenever convenient |

### Sprint Cadence (Weekly)

For weekly sprints:
- CRITICAL: still 24-hour emergency path (outside sprint)
- HIGH: must be in current sprint
- MEDIUM: must be scheduled within 2 sprints
- LOW: backlog, prioritized against feature work

---

## Metrics and Reporting

Track these metrics continuously (G-LOOP automated collection):

| Metric | Target | Measurement |
|--------|--------|-------------|
| Mean Time to Remediate (CRITICAL) | < 12 hours | Time from detection to deployed fix |
| Mean Time to Remediate (HIGH) | < 48 hours | Time from detection to deployed fix |
| % CRITICALs resolved within SLA | 100% | No exceptions |
| % HIGHs resolved within SLA | 95% | 5% allowance for complex architectural fixes |
| % looped vs gated remediations | > 70% looped | Higher = more automation maturity |
| Regression rate from security fixes | < 2% | Fixes that introduce new bugs |
| False positive rate (auto-classification) | < 10% | Mis-classified severities |

### SLA Breach Escalation

| Breach | Escalation |
|--------|------------|
| CRITICAL > 24h unresolved | CTO, Security Lead, Director — war room |
| HIGH > 72h unresolved | Security Lead, Director — daily standup item |
| MEDIUM > 14d unresolved | Auto-escalates to HIGH; enters next sprint |
| Pattern: 3+ LOWs in same component | Auto-escalates to MEDIUM; architectural review triggered |

---

## Relationship to Other Steering Files

- **01-governance-gates.md** — Security SLA integrates with G4 (build verification) and G5 (release readiness)
- **03-coding-standards.md** — Security standards define what scanners check; SLA defines what happens when they find something
- **04-adversarial-review.md** — B-Team findings are classified and routed per this SLA
- **08-loop-engineering.md** — Looped remediations follow loop engineering rules (verifier, state, stop condition)
- **10-supply-chain-verification.md** — Supply chain vulnerabilities follow CRITICAL path by default
- **11-tiered-adversarial-review.md** — Gate routing uses tiered review to maintain deployment velocity

---

*Security Remediation SLA v1.0 — July 2026*
