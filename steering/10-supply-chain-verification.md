---
inclusion: auto
# Note: The `inclusion: auto` front matter is used by Kiro to auto-load this file.
# For other IDEs, place this file in the appropriate context directory for your tool.
---

# Supply Chain Verification — AI Infrastructure Security Loop

AI-integrated software has a uniquely concentrated supply chain risk. AI proxy packages, model gateways, and inference SDKs aggregate API keys, cloud credentials, and sensitive data flows into single points of failure. A compromised AI infrastructure package can cascade through an entire organization in minutes.

This steering file defines the verification loops and gates for supply chain security.

---

## The Threat Model

### Why AI Supply Chain Is Different

Traditional supply chain attacks compromise a dependency to inject malicious code. AI supply chain attacks are worse because:

1. **Credential concentration** — AI proxy/gateway packages (LiteLLM, LangChain, etc.) hold API keys for multiple model providers, cloud credentials, and often database connection strings. One compromised package = all keys.
2. **CI/CD as attack vector** — Build pipelines that run AI-powered security scanners can be compromised to steal publish tokens, which are then used to backdoor the AI packages themselves (recursive supply chain attack).
3. **Implicit trust in AI outputs** — Developers implicitly trust AI-generated dependency recommendations. 49% of AI-recommended dependencies contain known vulnerabilities (Endor Labs, 2026).
4. **Volume and velocity** — AI agents select, install, and integrate dependencies at machine speed. A human might evaluate a package before adding it. An agent adds it because it solves the immediate problem.

### Reference Incidents

- **LiteLLM/TeamPCP (March 2026):** Backdoored versions of a package with 95M monthly downloads. Three-stage payload harvesting SSH keys, cloud credentials, Kubernetes secrets. Attack chain started by compromising an upstream security scanner.
- **PyPI typosquatting campaigns (ongoing):** AI agents are more susceptible to typosquatting because they select packages by name similarity and popularity signals, not by manual verification.

---

## Supply Chain Verification Loop (G-LOOP)

This loop runs automatically on every dependency change (addition, update, or removal).

### Trigger Conditions

The loop activates when ANY of these occur:
- A new dependency is added to any manifest file (package.json, requirements.txt, pom.xml, go.mod, Cargo.toml, etc.)
- An existing dependency version is changed
- A lockfile is regenerated
- A Dockerfile base image is changed
- A model endpoint or AI service SDK is added or updated

### Verification Steps

```
Step 1: PROVENANCE CHECK
├── Is the package published by a verified publisher? (PyPI Trusted Publishers, npm provenance)
├── Does the package have a Sigstore signature?
├── Is the publisher identity consistent with prior releases?
├── Has the package changed maintainers recently? (flag if < 30 days)
└── FAIL if: no provenance, new maintainer on critical package, signature mismatch

Step 2: VULNERABILITY SCAN (SCA)
├── Check against NVD, OSV, GitHub Advisory Database
├── Check transitive dependencies (not just direct)
├── Flag any dependency with CVSS >= 7.0
└── FAIL if: CRITICAL CVE in direct dependency, HIGH CVE without patch available

Step 3: BEHAVIORAL ANALYSIS
├── Does the package access network resources unexpectedly?
├── Does it read environment variables or credential files?
├── Does it execute subprocess calls?
├── Has the package's behavior changed between versions? (diff analysis)
└── FLAG if: network access, credential reads, or subprocess calls not present in prior version

Step 4: LICENSE AND LEGAL
├── Is the license compatible with project requirements?
├── Are there license changes between versions?
└── FAIL if: incompatible license, license downgrade (permissive → copyleft)

Step 5: AI-SPECIFIC CHECKS (for AI/ML packages)
├── Does the package transmit data to external endpoints?
├── Does it cache or log prompts/completions?
├── Does it have telemetry that could leak sensitive information?
├── Is the model endpoint configurable (or hardcoded to vendor)?
└── FLAG if: external data transmission, prompt logging, non-configurable endpoints
```

### Verifier Output

```json
{
  "package": "litellm",
  "version": "1.85.0",
  "provenance": "PASS",
  "vulnerability_scan": "PASS",
  "behavioral_analysis": "FLAG - reads AWS_ACCESS_KEY_ID (expected for AI proxy)",
  "license": "PASS",
  "ai_specific": "FLAG - telemetry enabled by default",
  "overall": "PASS WITH FLAGS",
  "flags_require_review": false,
  "notes": "Behavioral flags are expected for this package category. Telemetry should be disabled in production config."
}
```

---

## AI Bill of Materials (AI-BOM)

Every project using AI components MUST maintain an AI-BOM. This is separate from the standard SBOM and tracks AI-specific components.

### AI-BOM Contents

```yaml
ai_bom:
  version: "1.0"
  last_updated: "2026-07-28"
  
  model_providers:
    - provider: "Anthropic"
      models: ["claude-sonnet-4-20250514", "claude-opus-4-20250918"]
      access_method: "API key"
      data_residency: "US"
      
    - provider: "OpenAI"
      models: ["gpt-4o", "o3"]
      access_method: "API key"
      data_residency: "US"
  
  ai_infrastructure_packages:
    - package: "litellm"
      version: "1.85.0"
      purpose: "Multi-model proxy/gateway"
      credentials_managed: ["ANTHROPIC_API_KEY", "OPENAI_API_KEY", "AWS_ACCESS_KEY_ID"]
      risk_classification: "HIGH - credential aggregator"
      
    - package: "langchain"
      version: "0.3.x"
      purpose: "Agent orchestration"
      credentials_managed: ["OPENAI_API_KEY"]
      risk_classification: "MEDIUM - orchestration layer"
  
  ai_development_tools:
    - tool: "GitHub Copilot"
      scope: "code generation"
      data_sent: "code context, file contents"
      
    - tool: "Kiro"
      scope: "full SDLC assistance"
      data_sent: "workspace files, terminal output"
  
  training_data:
    - description: "No custom fine-tuned models in use"
    
  inference_endpoints:
    - endpoint: "api.anthropic.com"
      authentication: "API key (rotated quarterly)"
      
    - endpoint: "api.openai.com"
      authentication: "API key (rotated quarterly)"
```

### AI-BOM Maintenance Rules

1. **Updated on every AI dependency change** — the supply chain verification loop triggers an AI-BOM review
2. **Reviewed quarterly** — full audit of all AI components, credentials, and data flows
3. **Included in G5 release readiness** — no release without current AI-BOM
4. **Credential rotation tracked** — AI-BOM includes last rotation date and rotation schedule

---

## CI/CD Credential Isolation

The LiteLLM incident demonstrated that CI/CD credentials are the attack vector for supply chain compromise. Protect them:

### Credential Segmentation

| Credential Type | Storage | Access Scope | Rotation |
|---|---|---|---|
| Package publish tokens (PyPI, npm) | Dedicated secrets vault | CI publish job ONLY — not build, not test | Every 90 days |
| Cloud credentials (AWS, GCP, Azure) | IAM roles (not static keys) | Per-service, least privilege | Session-based (no long-lived) |
| Model API keys | Secrets manager | Runtime only — never in build pipeline | Every 90 days |
| Container registry tokens | CI-specific service account | Push access only for release pipeline | Every 90 days |

### CI/CD Hardening Rules

1. **No credential sharing between pipeline stages** — build, test, scan, and publish each get their own identity
2. **Security scanners run in isolated environments** — a compromised scanner cannot access publish credentials
3. **Publish tokens are never available during build or test** — only activated in the explicit publish step
4. **All pipeline steps log their credential access** — anomalous access patterns trigger alerts
5. **Dependency installation uses lockfiles only** — no `pip install` without pinned versions in CI

---

## Dependency Addition Gate (Human Judgment)

When the supply chain verification loop FLAGS a dependency (but doesn't FAIL it), a lightweight gate review is required:

### Who Reviews

- **AI infrastructure packages** (model SDKs, proxies, agents): Security Lead + Architecture Lead
- **Standard packages with behavioral flags**: Senior developer + automated risk assessment
- **New-maintainer flags on critical packages**: Security Lead (expedited review)

### Review Checklist

- [ ] Is there a less-privileged alternative that achieves the same goal?
- [ ] Are the behavioral flags expected for this package category?
- [ ] Can credentials be isolated from this package's access scope?
- [ ] Is the package actively maintained (commits in last 90 days)?
- [ ] Does the package have a security policy and vulnerability disclosure process?
- [ ] Are we pinning to an exact version with hash verification?

---

## Emergency Response: Supply Chain Compromise Detected

When a supply chain compromise is confirmed (vendor advisory, security researcher disclosure, or internal detection):

### Immediate Actions (First 30 Minutes)

1. **Identify exposure** — which projects use the affected package and version?
2. **Pin/block the compromised version** — update lockfiles, add to deny list
3. **Rotate ALL credentials** the package had access to — assume they are compromised
4. **Check CI/CD logs** — did the compromised package run in any pipeline? What credentials did it access?
5. **Notify affected teams** — broadcast with severity and required actions

### Short-Term Actions (First 24 Hours)

6. **Audit package behavior** — did it exfiltrate data? Check network logs.
7. **Update AI-BOM** — document the incident and affected components
8. **Verify clean versions** — confirm replacement version is not compromised (check provenance)
9. **Deploy clean version** — emergency deployment path per Security SLA (CRITICAL = 24h)
10. **Post-incident review** — why wasn't this caught earlier? What verification step failed?

### Long-Term Actions (First 7 Days)

11. **Strengthen verification loop** — add behavioral check that would have caught this pattern
12. **Audit similar packages** — are other packages from the same maintainer/organization affected?
13. **Update threat model** — document the attack vector for future B-Team reference
14. **Credential rotation schedule** — reduce rotation interval for affected credential types

---

## Integration with Other Steering Files

- **01-governance-gates.md** — Supply chain verification is part of G2/G3 (architecture safety) and G4 (build verification)
- **03-coding-standards.md** — Dependency pinning and lockfile requirements
- **08-loop-engineering.md** — Supply chain verification IS a loop (automated, verifier-driven, bounded)
- **09-security-remediation-sla.md** — Supply chain compromises follow CRITICAL path by default
- **11-tiered-adversarial-review.md** — Dependency changes touching AI infrastructure trigger Tier 2 review

---

*Supply Chain Verification v1.0 — July 2026*
