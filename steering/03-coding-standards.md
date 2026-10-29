---
inclusion: auto
name: sgl-coding-standards
description: SGL coding standards - the single test coverage table, security and accessibility standards, error handling (no silent catches), AI-code provenance commit trailers, and CI requirements. Load before writing, reviewing, or committing code.
# For non-Kiro tools, load this file on demand before code work.
---

# Coding Standards & Quality Gates

These standards apply to all code produced in this project, whether written by AI or human. Stack-specific rules (container platform, database ownership, mobile platform guidelines, ticket system) belong in the project's ADRs, not here.

---

## Test Coverage

This is the **single coverage table** for the harness. Other files point here. The most specific row wins.

| Category | Target | Rationale |
|----------|--------|-----------|
| Security-sensitive code | **100%** | Security gaps are not acceptable |
| Validators / business logic | **100%** | Incorrect logic = incorrect behavior |
| Navigation / routing | **100%** | Wrong path = broken user flow |
| Serialization / API contracts | **100%** | Payload mismatch = backend rejection |
| Other new code (not in a row below) | **100%** | AI can write tests. No excuse for gaps. |
| New UI / view-layer code | **80%** lines, plus 100% of any logic it contains (handlers, state, formatting) | Layout is visual; logic is testable |
| Legacy / ported code | **95%** critical paths, **80%** services | Risk-based: focus on high-impact paths |
| Generated / boilerplate code | **Excluded** | Not our code; generator config is reviewed instead |
| Auto-research prototypes (not shipped) | Tests sufficient for scoring | Only `implementation-ready/` output must meet the rows above |

### Exception Process
If code genuinely cannot meet its target:
1. Document the reason in a code comment: `// COVERAGE-EXCEPTION: <reason> (ticket <id>)`
2. Create a tracking ticket
3. The Human Steward approves or rejects in the ticket. The agent may write the comment and the request; it may not record the approval.
4. "It's hard to test" is NOT a valid reason

---

## Security Standards

### Every PR / Change
- No secrets in source code (CI scans for this)
- No sensitive data in logs (no PHI, PII, tokens, passwords)
- Input validation on all user-provided data
- Parameterized queries (no string concatenation for SQL/queries)
- HTTPS only for anything beyond the local development machine (no HTTP exceptions in shared, staging, or production environments)

### Architecture Level
- PHI/PII is flagged in data models
- Rate limiting on abuse-prone endpoints
- **Security controls fail closed, including when they are unavailable.** If an authentication, authorization, policy, or rate-limit dependency times out or errors, deny the request.
- **Fail-soft only on non-security paths.** A non-essential feature (recommendations, analytics, avatars) may degrade gracefully when its dependency is down, as long as no security decision depends on it. The user sees a specific, documented degraded state.
- Database migrations are versioned and run through the application's migration tooling
- **No new cloud services, accounts, regions, credentials, or paid resources without Human Steward approval**, recorded in an ADR or the Intent Contract. Agents never provision cloud resources on their own initiative.

### Review Triggers
Sentinel reviews (and the change's Review Level floor rises per `11`) for any change that touches:
- Authentication / authorization
- Encryption / key management
- Network security (TLS, certificate pinning, platform transport policies)
- Data storage (local or remote)
- Third-party integrations
- Permission requests

---

## Accessibility Standards

**Target:** WCAG 2.1 AA (minimum)

### Every Component
- All interactive elements have accessibility labels
- All form fields have labels AND hints
- Error messages announced to assistive technology
- Minimum touch/click targets: 44x44pt (mobile) / 24x24px (web)
- Dynamic text sizing supported (no truncation)
- No information conveyed by color alone
- Focus management on navigation/state changes

### Every Ticket
- Accessibility acceptance criteria included (not a separate sprint)
- A screen reader (VoiceOver, TalkBack, NVDA, or equivalent for the platform) can complete the flow
- Keyboard navigation works (web/desktop)

---

## Code Quality

### Naming
- Clear, descriptive names (no abbreviations unless universally understood)
- Functions describe what they DO, not how
- Boolean variables read as questions (`isValid`, `hasPermission`, `canSubmit`)

### Architecture
- Single responsibility (one reason to change)
- In tests, mocks are limited to module edges. Prefer real or in-memory implementations of collaborators, and test from the outermost practical entry point (controller/handler level).
- No god objects (if a class does 5 things, split it into 5 classes)
- Composition over inheritance
- Dependencies injected, not created internally

### Documentation
- Git commits reference the tracking ticket for the work (`Ticket:` trailer)
- Public APIs have doc comments
- Complex logic has inline comments explaining WHY (not what)
- Architectural Decision Records (ADR) for significant decisions
- README kept current

---

## Error Handling — No Silent Failures

### The Rule

**A `catch` block that swallows an error without logging it is a defect, not a pattern.**

Silent error swallowing hides failures, makes debugging impossible, and can cause a system to silently fall back to expensive or incorrect paths when a fast path fails. The failure is invisible. The user suffers. Nobody knows why.

### What Is Forbidden

```typescript
// ❌ FORBIDDEN — silent swallow
} catch {
  return null;
}

// ❌ FORBIDDEN — silent swallow with comment that doesn't justify it
} catch { /* fall through */ }

// ❌ FORBIDDEN — catches error but discards it
} catch (e) {
  return null;
}

// ❌ FORBIDDEN — logs nothing, returns nothing
} catch (error) {
  // ignore
}
```

### What Is Required

Every `catch` block must do at least one of:

1. **Log the error** with enough context to diagnose it in production
2. **Re-throw** (let the caller handle it)
3. **Return a typed error result** that the caller can inspect

Error messages and stack traces can contain sensitive data (query fragments, identifiers, payload values). Log the error's **type, code, and a correlation ID**; send the full error only to a log sink approved for that data class.

```typescript
// ✅ Return a typed error result the caller must handle
type Result<T> = { ok: true; value: T } | { ok: false; error: "NOT_FOUND" | "UPSTREAM_FAILED" };

} catch (err) {
  logger.error({ op: "lookupMember", errorType: errName(err), correlationId });
  return { ok: false, error: "UPSTREAM_FAILED" };
}

// ✅ Re-throw with context, preserving the original cause and stack
} catch (err) {
  throw new Error("[member-lookup] upstream call failed", { cause: err });
}

// ✅ Fail-soft for non-critical, non-security background work only
} catch (err) {
  logger.warn({ op: "refreshAvatarCache", errorType: errName(err), correlationId });
}
```

### The Exception Process

There is exactly one case where a silent catch is acceptable: **when the operation is genuinely fire-and-forget AND the failure has zero impact on the user experience AND the code is not on any critical path.**

To use a silent catch in that case:

1. Explain WHY the failure is safe to ignore in a comment
2. Request approval from the human Architecture Lead (or the Human Steward) in the PR
3. The **human** adds the approval line in a commit marked `Generated-By: human`. An agent never writes `SILENT-CATCH-APPROVED`; `check-review-level.sh` rejects the marker in any non-human commit.

```typescript
// SILENT-CATCH-APPROVED: [human approver name], [date], PR [link]
// Reason: [specific justification — what fails, why it's safe, what the user sees]
} catch {
  // intentionally silent — see comment above
}
```

Without this comment and approval, any silent catch is a **blocking code review defect**.

### Enforcement

- Sentinel flags any `catch` block without a log statement, re-throw, or typed error result during code review
- Enable ESLint's core `no-empty` rule (it catches empty blocks only). Catch blocks that swallow by returning `null`/`undefined` need a custom lint rule or review; no core rule catches them.
- Any PR introducing a silent catch without a human-written `SILENT-CATCH-APPROVED` comment is rejected

---

## AI-Generated Code Provenance

### The Problem

When much of the code is AI-generated but indistinguishable from human-written code in the repository, security teams lose the ability to apply differential risk assessment. Functionally correct code is not necessarily secure code. Without provenance tracking, you cannot measure your own exposure or target review effort.

### Provenance Requirements

Every commit MUST include metadata indicating the code generation source:

**Git trailer format (preferred):**
```
feat: add rate limiting to /api/users endpoint

Implements token bucket rate limiter with Redis backend.
Configured for 100 req/min per authenticated user.

Ticket: PROJ-1234
Generated-By: ai-agent
Agent-Model: <model name and version>
Agent-Tool: kiro
Review-Level: R2
```

**Valid `Generated-By` values:**
- `human` — entirely human-written
- `ai-agent` — primarily AI-generated (agent wrote the implementation)
- `ai-assisted` — human-written with AI suggestions/completions incorporated
- `ai-paired` — interactively developed with AI (human directing, AI implementing)

### Tracking Fields

| Field | Required | Values |
|-------|----------|--------|
| `Generated-By` | Yes | `human`, `ai-agent`, `ai-assisted`, `ai-paired` |
| `Agent-Model` | If AI-generated | Model name and version |
| `Agent-Tool` | If AI-generated | IDE/tool (kiro, cursor, copilot, etc.) |
| `Review-Level` | Yes | `R1`, `R2`, `R3` (per `11-tiered-adversarial-review.md`) |

The `Review-Level` trailer is a **declaration, checked by CI**. `templates/enforcement/check-review-level.sh` computes the mechanical floor from file paths, dependency changes, provenance, and size (`11`) and fails the build if any commit omits the trailer or the declared level is lower. The declared level may be higher than the floor, never lower.

### Provenance Effects on Review Level

Provenance raises the floor; the full rules are in `11`.

| Code Source | Change touches | Review Level floor |
|---|---|---|
| Any | Nothing security-relevant | Per `11` |
| `human` | Security-relevant path | R2 |
| `ai-agent` / `ai-paired` / `ai-assisted` | Security-relevant path | R2 |
| `ai-agent` / `ai-paired` / `ai-assisted` | Auth, crypto, permissions | **R3** |
| Any | New architectural pattern | R3 |

### Metrics Derived from Provenance

Track monthly:
- **% code by source** — what proportion is ai-agent vs human vs assisted?
- **Defect rate by source** — do AI-generated commits have higher bug/vulnerability rates?
- **Security finding rate by source** — are SAST/SCA findings disproportionately in AI code?
- **Review Level distribution by source** — is AI code appropriately escalated?
- **Time-to-merge by source** — is AI code moving faster (less scrutiny) or slower (more review)?

These metrics inform calibration of the Review Level floors. If AI-generated code consistently shows higher defect rates in a specific category, raise that category's floor.

### Enforcement

- CI (`templates/enforcement/check-review-level.sh`) requires valid `Generated-By` and `Review-Level` trailers on every commit, rejects under-declared commits, and rejects human-approval markers added by non-human commits
- Missing provenance blocks merge (same as missing tests)
- Quarterly provenance audit: sample PRs and verify accuracy of self-reported source

---

## CI/CD Requirements

Every PR must pass:
1. **Build** — compiles without errors
2. **Test** — all tests pass, coverage meets threshold
3. **Lint** — no lint errors (warnings acceptable with justification)
4. **Security scan** — no secrets; no CRITICAL findings; no finding past its remediation clock in `09` (open findings inside their clock are tracked, not build-breaking)
5. **Accessibility check** — automated checks pass (where tooling exists)
6. **Provenance check** — valid `Generated-By` and `Review-Level` trailers on every commit (`check-review-level.sh`)

### Branch Protection
- No direct pushes to main/develop
- Minimum 1 **human** approval required (CODEOWNERS for governance paths)
- All CI checks must pass
- Stale reviews dismissed on new push
