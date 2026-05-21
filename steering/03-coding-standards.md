---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Coding Standards & Quality Gates

These standards apply to all code produced in this project, whether written by AI or human.

---

## Test Coverage

| Category | Target | Rationale |
|----------|--------|-----------|
| New code (built from scratch) | **100%** | AI can write tests. No excuse for gaps. |
| Validators / business logic | **100%** | Incorrect logic = incorrect behavior |
| Navigation / routing | **100%** | Wrong path = broken user flow |
| Serialization / API contracts | **100%** | Payload mismatch = backend rejection |
| Security-sensitive code | **100%** | Security gaps are not acceptable |
| Legacy / ported code | **95%** critical, **80%** services | Risk-based — focus on high-impact paths |
| UI / view layer | **80%** | Layout is visual; logic is testable |
| Generated / boilerplate code | **Excluded** | Not our code |

### Exception Process
If code genuinely cannot reach 100%:
1. Document the reason in a code comment: `// COVERAGE-EXCEPTION: <reason>`
2. Create a tracking ticket
3. Director (Aegis) approves or rejects
4. "It's hard to test" is NOT a valid reason

---

## Security Standards

### Every PR / Change
- No secrets in source code (CI scans for this)
- No sensitive data in logs (no PHI, PII, tokens, passwords)
- Input validation on all user-provided data
- Parameterized queries (no string concatenation for SQL/queries)
- HTTPS only (no HTTP exceptions)

### Architecture Level
- PHI/PII is flagged in data models
- Rate limiting on abuse-prone endpoints
- Fail closed on security failures (deny by default)
- Fail open on availability failures (don't trap the user)
- Database migrations managed inside application
- No shared databases
- All code to be packaged in Docker images for deployment in Kubernetes
- AWS services to be used without approval

### Review Triggers
Sentinel reviews any change that touches:
- Authentication / authorization
- Encryption / key management
- Network security (TLS, pinning, ATS)
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
- VoiceOver/screen reader can complete the flow
- Keyboard navigation works (web)

---

## Code Quality

### Naming
- Clear, descriptive names (no abbreviations unless universally understood)
- Functions describe what they DO, not how
- Boolean variables read as questions (`isValid`, `hasPermission`, `canSubmit`)

### Architecture
- Single responsibility (one reason to change)
- In testing mocks are limited to the edges of modules. Use of in-memory replacements such as H2 preferred. Testing from controller level is preferred.
- No god objects (if a class does 5 things, split it into 5 classes)
- Composition over inheritance
- Dependencies injected, not created internally

### Documentation
- Git commits contain JIRA ticket number associated with work for tracing
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

```typescript
// ✅ Log and return typed fallback
} catch (err) {
  console.error("[module-name] operation failed:", err instanceof Error ? err.message : String(err));
  return null; // caller must check for null and handle it
}

// ✅ Re-throw with context
} catch (err) {
  throw new Error(`[module-name] operation failed: ${err instanceof Error ? err.message : String(err)}`);
}

// ✅ Fail-soft with structured logging — for non-critical background work
} catch (err) {
  console.warn("[module-name] non-critical operation failed, continuing:", err instanceof Error ? err.message : String(err));
}
```

### The Exception Process

There is exactly one case where a silent catch is acceptable: **when the operation is genuinely fire-and-forget AND the failure has zero impact on the user experience AND the code is not on any critical path.**

To use a silent catch in that case:

1. Write a comment naming the architect who approved it
2. Explain WHY the failure is safe to ignore
3. Get explicit approval from Winston (Architect) before merging

```typescript
// SILENT-CATCH-APPROVED: [Architect name], [date]
// Reason: [specific justification — what fails, why it's safe, what the user sees]
} catch {
  // intentionally silent — see comment above
}
```

Without this comment and approval, any silent catch is a **blocking code review defect**.

### Enforcement

- Sentinel flags any `catch` block without a log statement or re-throw during code review
- Enable `no-empty-catch` lint rule where tooling supports it
- Any PR introducing a silent catch without the `SILENT-CATCH-APPROVED` comment is rejected

---

## CI/CD Requirements

Every PR must pass:
1. **Build** — compiles without errors
2. **Test** — all tests pass, coverage meets threshold
3. **Lint** — no lint errors (warnings acceptable with justification)
4. **Security scan** — no secrets, no known vulnerabilities
5. **Accessibility check** — automated checks pass (where tooling exists)

### Branch Protection
- No direct pushes to main/develop
- Minimum 1 approval required
- All CI checks must pass
- Stale reviews dismissed on new push
