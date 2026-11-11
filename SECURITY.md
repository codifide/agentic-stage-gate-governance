# Security Policy

This policy covers Codifide Harness, the framework and free harness in this repository.

## Reporting a vulnerability

Please report vulnerabilities privately using GitHub's private vulnerability reporting: open this repository's **Security** tab and choose **Report a vulnerability**.

Please do not open public issues or pull requests that contain exploit details.

No response-time commitment is made in this document.

## In scope

- The scripts under `templates/enforcement/` (for example, a way to bypass the immutable-path guard, the review-level check, or the licence check).
- Text in `steering/` or `templates/` that could cause an AI agent to take an unsafe action (for example, instructions that lead an agent to expose secrets, skip a required human approval, or run untrusted content as instructions).

## Out of scope

- Vulnerabilities in host tools or IDEs that run the harness (for example, AI coding assistants or their hook runtimes). Report those to their vendors.
- Vulnerabilities in third-party frameworks or projects mentioned in this repository. Report those to the owners of those projects.
- Behaviour the documentation already marks as advisory or `[UNVERIFIED]`. See "Scope and limits" in [README.md](README.md).

## Warranty

This project is provided as is, without warranty. See [LICENSE](LICENSE).
