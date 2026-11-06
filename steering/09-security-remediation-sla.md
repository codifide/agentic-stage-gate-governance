---
inclusion: auto
name: sgl-security-remediation-sla
description: SGL security remediation SLA - CVSS-aligned severity classification, the single remediation clock per severity, extension classes, loop-vs-gate routing for fixes (credentials and security config are always gated), breach escalation, and metrics. Load when triaging, fixing, or reporting on any vulnerability.
# For non-Kiro tools, load this file on demand for vulnerability work.
---

# Security Remediation SLA — Time-to-Fix Governance

Every vulnerability is classified by severity, given one remediation clock, and routed to a **loop** (automated fix + verify) or a **gate** (human judgment).

Named roles here (Security Lead, Architecture Lead, Compliance Officer, CTO) are **humans**. If the organization doesn't have one, the Human Steward holds the role (`00-welcome.md` §1).

---

## Severity Classification

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Actively exploited, OR remotely exploitable without authentication, OR data exfiltration possible, OR authentication/authorization bypass, OR dependency with CVSS ≥ 9.0 |
| **HIGH** | Remotely exploitable with authentication, OR local privilege escalation, OR public exploit exists, OR dependency with CVSS 7.0–8.9 |
| **MEDIUM** | Requires specific conditions to exploit, OR theoretical path with no known exploit, OR dependency with CVSS 4.0–6.9 |
| **LOW** | Informational exposure, OR physical access required, OR defense-in-depth gap with no direct exploit path, OR dependency with CVSS < 4.0 |

CVSS bands follow the standard CVSS v3 qualitative ratings.

### Override rules

- Any vulnerability in authentication, authorization, or encryption → minimum HIGH
- Any vulnerability with a public exploit → minimum HIGH
- Any vulnerability affecting > 50% of users → minimum HIGH
- Any exposed secret or credential → CRITICAL
- The Security Lead may raise any classification. Lowering one requires the Human Steward, in writing.

---

## Remediation Clock (single source)

The clock runs from detection to deployed fix (or deployed interim mitigation plus an approved extension). Deployment cadence and sprint boundaries do not extend it.

| Severity | Deployed fix within | Deployment path | Notify |
|----------|---------------------|-----------------|--------|
| **CRITICAL** | 24 hours | Emergency hotfix, outside any sprint | Security Lead + CTO immediately |
| **HIGH** | 24 hours | Next deployment window inside the 24 hours | Security Lead |
| **MEDIUM** | 72 hours | Next deployment window | Tracked |
| **LOW** | 72 hours | Next deployment window, may be bundled | Tracked |

With mature loop automation the pipeline is not the bottleneck; severity sets queue priority. The only things that extend the clock are the four extension classes below.

---

## Extension Classes

A remediation that cannot meet its clock MUST be classified at triage (not retroactively) with one extension class.

Extensions are exceptions (`00-welcome.md` §1). Each one is approved by the **Human Steward**, or by a delegate the Intent Contract names for that extension class (e.g., the Architecture Lead for ARCH), for that class only. The parties in the last column must also agree before the extension is approved.

| Class | Description | Extended clock | Interim mitigation | Must also agree |
|---|---|---|---|---|
| **ARCH** | Fix needs structural change (new services, data flows, patterns) | 7 days | Required within 24h | Architecture Lead |
| **CROSS** | Fix spans services owned by different teams | 5 days | Required within 24h | Service owners jointly |
| **COMPLY** | Fix changes regulated data handling and needs compliance sign-off **for that specific change** | 5 days | Required within 24h | Compliance Officer |
| **BREAK** | Fix requires a published API contract change | 5 days | Required within 24h | API consumers acknowledge |

### Extension rules

1. **Interim mitigation within 24 hours, always**: WAF rule, feature flag, rate limit, access restriction, or monitoring alert. The vulnerability is contained immediately; only the permanent fix waits.
2. **No extension exceeds 7 days** without the Human Steward convening a war room and recording the decision.
3. **Recurring extensions trigger architectural review**: the same class used 3+ times in a quarter for the same component indicates a structural problem.
4. **Not valid reasons to extend:** fixed deployment days, long manual regression cycles, standing review-board cadences, or batching for convenience. (COMPLY covers a sign-off needed for *this* change, not waiting for a recurring meeting.)

---

## Loop vs Gate Routing

### Loop it (automated remediation)

Only when ALL are true:
1. **Machine-verifiable fix**: existing tests + security scans confirm it
2. **Bounded code or dependency change**: no security configuration, no credentials, no auth policy
3. **Low blast radius**: no behavioral regression beyond what tests cover

**Examples that loop:**
- Dependency version bump for a known CVE (SCA flagged, tests verify, change reviewed at R2, or R3 if it is an AI-infrastructure dependency, per `11` rules 6 and 11)
- Adding input validation to a parameter (SAST flagged, unit tests verify)
- Replacing an unsafe API call with its known-safe equivalent (SAST flagged, tests verify)

**Loop verifier requirements:** full test suite; SAST/SCA confirms the finding is resolved; no new findings; build clean; API contract tests pass.

### Gate it (human judgment)

Route to a gate when ANY apply:
1. **Credentials, secrets, TLS, auth policy, or IAM** are involved (always; loops never touch security configuration, `08`)
2. The fix requires architectural change
3. Business logic changes in ways tests can't fully verify
4. Compliance interpretation is needed
5. Novel attack vector with no existing test pattern
6. Cross-service impact

**Examples that require gates:**
- **Exposed credential or hardcoded secret.** Remediation is: revoke and rotate the credential (human-approved), confirm nothing used it maliciously (access logs), then remove it from source and, if required, from git history. Deleting it from source without revoking it leaves the exposure live, and a passing build proves nothing about that.
- Updating TLS configuration or certificate handling
- Redesigning an authorization model
- Fixing a race condition in a payment flow
- Responding to a novel prompt-injection technique
- Remediating a supply-chain compromise in build infrastructure (`10`)
- Adding encryption to a previously unencrypted store

**Gate requirements:** B-Team review at the change's Review Level (R2 minimum, R3 per `11`); threat model updated; regression tests expanded to cover the vulnerability class; rollback plan documented and tested.

**Expedited path for gated CRITICAL/HIGH:** start the review the change's floor requires (`11`) immediately, in parallel with the fix, using parallel R3 batches (Cipher + Jett + Blaze first). The fix ships after that review passes. If an R3-floor fix cannot finish R3 inside the clock, the **Human Steward may, in writing and for that change only**, approve shipping on a passed R2 with the interim mitigation in place and the remaining R3 personas completed within 72 hours. That is a recorded floor lowering, not a default. A missed 72-hour follow-up is an SLA breach (table below).

---

## Automated Severity Classification

```
IF source = SCA (dependency):
    severity = CVSS band (table above), raised by override rules
    route = LOOP (dependency bump + tests) unless override rules or gate criteria apply
IF source = SAST:
    severity = scanner rule severity, raised by override rules
    route = LOOP if the fix is pattern-based, GATE if architectural
IF source = secret scanner:
    severity = CRITICAL; route = GATE (revoke + rotate)
IF source = DAST:
    route = GATE (runtime issues usually need behavioral understanding)
IF source = pen test OR manual report:
    severity = human-assigned; route = GATE
IF source = B-Team review:
    severity = finding classification; already in a gate process
```

---

## SLA Breach Escalation

Any remediation that passes its clock (including an approved extension) escalates **one severity level** and is reported:

| Breach | Escalation |
|--------|------------|
| CRITICAL past clock | Human Steward, CTO, Security Lead: war room |
| HIGH past clock | Becomes CRITICAL; Security Lead + Human Steward |
| MEDIUM past clock | Becomes HIGH |
| LOW past clock | Becomes MEDIUM |
| 3+ LOWs in the same component | Raised to MEDIUM; architectural review |

---

## Metrics

| Metric | Target |
|--------|--------|
| Mean time to remediate, CRITICAL | < 8 hours |
| % CRITICAL and HIGH within clock | 100% |
| % MEDIUM and LOW within clock (excluding approved extensions) | ≥ 95% |
| % remediations looped vs gated | Observed, not a quota |
| Regression rate from security fixes | < 2% |
| Auto-classification error rate | < 10% |

---

## Related Files

- `03-coding-standards.md`: what scanners check
- `08-loop-engineering.md`: loop rules for looped remediations
- `10-supply-chain-verification.md`: supply-chain compromises follow the CRITICAL path
- `11-tiered-adversarial-review.md`: Review Levels for remediation changes
