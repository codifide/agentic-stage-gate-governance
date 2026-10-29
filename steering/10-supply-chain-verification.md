---
inclusion: auto
name: sgl-supply-chain-verification
description: SGL supply chain verification loop for every dependency, lockfile, base image, or AI SDK change - provenance, vulnerability, behavioral, license, and AI-specific checks, the AI-BOM, CI credential isolation, the dependency review gate, and compromise response. Load before adding, bumping, or removing any dependency.
# For non-Kiro tools, load this file on demand for dependency changes.
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
3. **Implicit trust in AI outputs** — AI-recommended dependencies are often outdated, vulnerable, or hallucinated (non-existent names that attackers can register).
4. **Volume and velocity** — AI agents select, install, and integrate dependencies at machine speed. A human might evaluate a package before adding it. An agent adds it because it solves the immediate problem.

### Reference Attack Patterns

- **Backdoored AI gateway release:** an upstream CI tool is compromised, its access is used to steal a publish token, and a popular AI proxy package ships a release that harvests SSH keys, cloud credentials, and cluster secrets.
- **Typosquatting and slopsquatting:** agents select packages by name similarity or invent plausible names; attackers publish packages under those names.

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
├── Flag any dependency (direct or transitive) with CVSS >= 7.0 (HIGH or CRITICAL per `09`)
└── FAIL if: CRITICAL CVE in any direct or transitive dependency, or HIGH CVE without a patch available

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
  "package": "example-ai-gateway",
  "version": "2.4.1",
  "provenance": "PASS",
  "vulnerability_scan": "PASS",
  "behavioral_analysis": "FLAG - reads cloud credential environment variables",
  "license": "PASS",
  "ai_specific": "FLAG - telemetry enabled by default",
  "overall": "PASS WITH FLAGS",
  "flags_require_review": true,
  "notes": "Any FLAG requires the Dependency Review Gate below. The loop never self-waives a flag, even if the behavior looks expected for the package category."
}
```

**Rule:** `flags_require_review` is `true` whenever any check returns FLAG. Only a human reviewer in the Dependency Review Gate can clear a flag.

---

## AI Bill of Materials (AI-BOM)

Every project using AI components MUST maintain an AI-BOM. This is separate from the standard SBOM and tracks AI-specific components.

### AI-BOM Contents

```yaml
ai_bom:
  version: "1.0"
  last_updated: "2026-07-28"
  
  model_providers:
    - provider: "<provider A>"
      models: ["<model id and version>"]
      access_method: "Secrets-manager API key"
      data_residency: "US"
      approved_data_classes: ["internal", "synthetic"]   # e.g., add "PHI" only under a BAA

    - provider: "<cloud model service>"
      models: ["<model id and version>"]
      access_method: "IAM role (no static keys)"
      data_residency: "US"
      approved_data_classes: ["internal", "PHI"]

  ai_infrastructure_packages:
    - package: "<ai-gateway-package>"
      version: "<exact pinned version>"
      purpose: "Multi-model proxy/gateway"
      credentials_managed: ["<PROVIDER_A>_API_KEY (from secrets manager)", "cloud access via IAM role"]
      risk_classification: "HIGH - credential aggregator"

    - package: "<agent-framework>"
      version: "<exact pinned version>"
      purpose: "Agent orchestration"
      credentials_managed: ["<PROVIDER_A>_API_KEY (from secrets manager)"]
      risk_classification: "MEDIUM - orchestration layer"
  
  ai_development_tools:
    - tool: "<IDE agent>"
      scope: "full SDLC assistance"
      data_sent: "workspace files, terminal output"

    - tool: "<B-Team reviewer model(s)>"
      scope: "adversarial review"
      data_sent: "review packages (redacted, synthetic data only)"

  training_data:
    - description: "No custom fine-tuned models in use"

  inference_endpoints:
    - endpoint: "<provider A endpoint>"
      authentication: "API key from secrets manager (rotated every 90 days)"
```

### AI-BOM Maintenance Rules

1. **Updated on every AI dependency change** — the supply chain verification loop triggers an AI-BOM review
2. **Reviewed quarterly** — full audit of all AI components, credentials, and data flows
3. **Included in G5 release readiness** — no release without current AI-BOM
4. **Credential rotation tracked** — AI-BOM includes last rotation date and rotation schedule

---

## CI/CD Credential Isolation

CI/CD credentials are a primary vector for supply chain compromise. Protect them:

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

## Dependency Review Gate (Human Judgment)

Every dependency change is reviewed at **R2 minimum**, and AI infrastructure dependencies at **R3** (`11`). In addition, when the verification loop FLAGS a dependency (but doesn't FAIL it), a human must clear each flag:

### Who Clears Flags

Clearing a flag is accepting a risk, so it follows `00-welcome.md` §1: the Human Steward, or a delegate the Intent Contract names for dependency review. The roles below must also agree. If the organization lacks a role, the Human Steward holds it.

- **AI infrastructure packages** (model SDKs, proxies, agent frameworks): Security Lead + Architecture Lead
- **Standard packages with behavioral flags**: a senior developer, informed by the automated risk assessment
- **New-maintainer flags on critical packages**: Security Lead (expedited)

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

- **01-governance-gates.md** — Supply chain verification is part of G2/G3 (architecture safety) and G4 (build verification); a current AI-BOM is G5 evidence
- **08-loop-engineering.md** — Supply chain verification IS a loop (automated, verifier-driven, bounded)
- **09-security-remediation-sla.md** — Supply chain compromises follow the CRITICAL path by default
- **11-tiered-adversarial-review.md** — Any dependency change is R2 minimum; AI infrastructure dependencies are R3

---

*Supply Chain Verification — SGL Harness v3.0 — October 2026*
