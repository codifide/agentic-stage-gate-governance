---
inclusion: auto
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
