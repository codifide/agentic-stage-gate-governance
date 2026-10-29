---
inclusion: auto
name: sgl-review-levels
description: SGL Review Levels R1, R2, R3 for individual changes (PRs, loop output) - criteria, the single classification procedure, path-based floors computed by CI, dependency rules, override rules, and calibration metrics. Load when assigning or checking a Review Level on any change.
# For non-Kiro tools, load this file on demand when classifying a change.
---

# Review Levels — Scaling B-Team for Daily Deployment

A full 12-persona B-Team review on every PR pushes teams back toward batching. This file defines **Review Levels** for individual changes (a PR, a loop's output) so that review depth matches risk.

**Scope:** these levels apply to **changes**. Gate reviews (reviewing a gate's artifacts) are set by track in `00-welcome.md` §3. "Review Level R1–R3" is unrelated to the **Cost Classes C1–C3** in `08-loop-engineering.md`.

---

## The Three Levels

### R1 — Verifier-only

No B-Team review. G-LOOP verifiers are sufficient.

**Allowed only when ALL are true:**
- Every touched file is on the R1 allowlist: tests, docs, or styles (see path floors below)
- No rule in the classification procedure below sets a higher floor
- All automated checks pass (build, test, lint, SAST, SCA, immutable-path check)

**Verifiers required:** full test suite, coverage threshold, SAST, SCA, build, no new warnings.

**Examples:** CSS/styling; documentation; adding tests. (A typo in a UI label inside a component file, or a small readability refactor, touches source code and is R2.)

### R2 — Focused B-Team (Cipher + Jett + Blaze)

Three personas, independent context (`04`).

| Persona | Focus |
|---------|-------|
| **Cipher** | Attack paths, injection, privilege escalation |
| **Jett** | Logic bugs, races, state errors, edge cases, silent failures |
| **Blaze** | Do the tests prove the change correct, including failure modes? |

**R2 prompt (paste-ready, the single R2 source).** Paste as the system message in an independent session on a different model family (`04`). Enable reasoning/thinking in the model settings. Then paste the diff, the surrounding code, and a short context block (what the code does, invariants, attack surfaces, what "wrong" means here) as the user message.

```markdown
You are three adversarial reviewers who did NOT write this change: Cipher (offensive
security), Jett (logic and state), and Blaze (test adequacy). Assume the change is wrong
until the code proves otherwise. Trace execution paths; do not pattern-match to "looks
reasonable." The default verdict is FAIL; the change must earn PASS.

Classify every finding CRITICAL / MAJOR / MINOR / OBSERVATION, cite file and line, and
state the required action. If you cannot verify a property, report it as UNVERIFIABLE
(MAJOR minimum). Fill in every checkbox below with PASS / FAIL / UNVERIFIABLE.

### Cipher (Security)
- [ ] No new injection vectors
- [ ] Authorization checks on all new/modified endpoints
- [ ] Input validation covers edge cases
- [ ] Errors don't leak internal state or sensitive data
- [ ] Security controls fail closed when their dependency is unavailable

### Jett (Logic)
- [ ] State transitions correct and complete
- [ ] Concurrent access paths handled
- [ ] Edge cases (null, empty, overflow, boundary)
- [ ] No silent failures

### Blaze (Testing)
- [ ] Failure modes tested, not just the happy path
- [ ] Negative tests (invalid input, unauthorized access)
- [ ] Integration points tested, not only mocked

### Verdict: PASS / PASS WITH CONDITIONS / FAIL
One paragraph: what evidence would change the verdict. Your verdict is evidence for
the human's decision, not the decision.
```

**Examples:** new REST endpoint; query-logic change; role-based access on an existing feature; any dependency addition or version change; remediation of a known-pattern vulnerability.

### R3 — Full B-Team (all 12 personas)

Independent context. For code, use the forensic code-review template plus the 12-persona package for design, privacy, accessibility, and ops aspects (`04`).

**Examples:** new permission system; new microservice or data store; new external integration; production data migration; any regulated-data change; new autonomous AI capability.

---

## Classification Procedure (the only one)

Walk the rules in order. **The highest level any rule assigns is the floor.** Start at R1.

| # | If the change... | Floor |
|---|------------------|-------|
| 0 | Edits the harness itself: steering files, hooks, `.sgl/`, CI workflows, CODEOWNERS (the handoff file `next-session-prompt.md` excepted) | R3 |
| 1 | Touches encryption, key management, certificates, or secrets handling | R3 |
| 2 | Has any non-`human` provenance (`ai-agent`, `ai-paired`, or `ai-assisted`) **and** touches auth, authz, permissions, or crypto | R3 |
| 3 | Introduces a new architectural pattern, service, data store, or external integration | R3 |
| 4 | Changes production infrastructure-as-code, or any database migration (migrations reach production) | R3 |
| 5 | Is compliance-relevant (regulated data handling, consent, audit trails) | R3 |
| 6 | Adds or changes AI infrastructure dependencies (model SDKs, proxies, agent frameworks) or a new AI capability | R3 |
| 7 | Adds user-facing behavior **not** covered by an approved G2/G3 design or Express G0/G1 note | R3 |
| 8 | Exceeds 500 changed lines **across** more than 5 files, unless it is a tool-verified mechanical refactor with unchanged tests (then R2) | R3 |
| 9 | Touches authentication, authorization, session management, or data-access/query logic | R2 |
| 10 | Adds or modifies an API endpoint or schema | R2 |
| 11 | Adds, removes, or changes the version of **any** dependency, lockfile, or base image | R2 |
| 12 | Changes non-production infrastructure or CI/CD config | R2 |
| 13 | Changes error handling or validation in a security-sensitive path | R2 |
| 14 | Failed any automated check at any point before passing | R2 |
| 15 | None of the above, and every R1 condition holds | R1 |
| — | Anything not clearly covered | **R2** |

### Path-based floors (enforced per commit by `templates/enforcement/check-review-level.sh`)

```
R3:  governance: */.kiro/*, */.sgl/*, */steering/*, */.github/workflows/*, */CODEOWNERS,
     */templates/enforcement/*, and the SGL review/checklist/hook/intent/NFR templates
     (except .kiro/steering/next-session-prompt.md)
R3:  */crypto/*, */encryption/*, */keys/*, */certs/*, */certificates/*, */tls/*, */secrets/*,
     *.pem, *.key, *.crt, *.p12, */infrastructure/prod*, */terraform/*prod*,
     */migrations/*, */migrate/*, */db/migrate*, *.iac.*, docker-compose.prod.yml
R2+: auth/authz/permissions/crypto paths are never R1, whatever the file name
R3:  any non-human commit touching */auth/*, */authz/*, */permissions/*, */crypto/*, */encryption/*, */keys/*
R1 allowlist (the ONLY files that may be R1):
     tests (*/tests/*, */test/*, */__tests__/*, *.test.*, *.spec.*), docs (*.md, */docs/*),
     styles (*.css, *.scss, */styles/*)
R2:  every other file
```

Dependency manifests, lockfiles, Dockerfiles, CI config, API schemas, and auth or data-access code all land in "every other file," so they are R2 at minimum by construction. Add project-specific R3 paths (anything the threat model flags) to the script's `R3_GLOBS`.

An allowlisted path does not make a change R1; the change must still satisfy every R1 condition. The allowlist works by path convention: product code placed under a test or docs path is a review and CODEOWNERS problem the script cannot see.

**Computed by the script** (per commit; merge commits on their conflict resolutions), **for the paths listed above only:** rule 0, rules 1, 2, and 4 for files under those paths, the R1 allowlist, and rule 8 (if the PR trips the size rule, every commit must declare that floor).

**Not computed: the agent and reviewers must apply these and can only raise:** rules 1, 2, and 4 for secrets, certificates, auth, crypto, or migration code outside those paths, 3 (new architecture), 5 (compliance), 6 (AI-infrastructure dependencies), 7 (behavior outside an approved design), and 14 (failed an automated check before passing).

### Override rules

- Every commit declares a level in its `Review-Level` trailer (`03`). It may declare **higher** than the floor, never lower. `check-review-level.sh` rejects missing or under-declared trailers per commit for the computed rules listed above. The agent and reviewers apply the non-computed rules (2 outside conventional paths, 3, 5, 6, 7, 14) and can only raise.
- The Human Steward or the Security Lead role can raise any change.
- Only the Human Steward can lower a computed floor, in writing, with rationale. The script supports one such lowering (rule 8's mechanical-refactor exception, via a Steward-only workflow); any other lowering is a recorded Steward decision on the PR.
- Three R1 changes to the same module within 24 hours trigger an R2 review of the combined diff (a G-LOOP check; not in the reference scripts).

---

## Reviewer Availability

| Level | Reviewer | Typical latency |
|-------|----------|-----------------|
| R2 | One reasoning model from a different family than the builder | Minutes |
| R3 | A different-family reasoning model, plus a second different-family pass or zero-context reader if Enterprise | Under an hour |

**Parallel R3:** run Cipher + Jett + Blaze first (most likely to find CRITICALs). If they find CRITICALs, fix before running the rest.

---

## Calibration Metrics

These are **observations for calibrating the floors, not quotas.** Never classify a change down to hit a distribution.

| Metric | Watch for |
|--------|-----------|
| R1 escape rate (R1 changes later found to need R2+) | Anything above ~1% means the R1 rules are too loose |
| R2/R3 reviews that find nothing, by trigger | A trigger that never finds anything may be too strict; the Human Steward decides |
| Review latency (R2, R3) | Review becoming a bottleneck |
| Level distribution by provenance | AI code being under-classified |

---

## Security Remediation Routing

`09-security-remediation-sla.md` routes remediations through the same procedure. A dependency bump that fixes a CVE is a dependency change, so it is **R2**.
