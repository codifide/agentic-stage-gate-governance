> **Note:** The canonical version of this article is the HTML file on the Codifide website.
> - [ai-timing-lesson.html](./ai-timing-lesson.html) (local HTML)
> - Live at [codifide.com/ai-timing-lesson](https://www.codifide.com/ai-timing-lesson)

---

# The $200K Lesson: Why AI Timing Matters More Than Strategy

**A Medical Records Automation Story**

*Douglas Jones · May 2026*

---

## The Problem

A large healthcare organization processes approximately 30,000 Release of Information requests daily. Each requires matching a patient's demographics against an EMR system. At a baseline cost of $3–4 per authorization for manual processing, the operational stakes are significant. Every minute spent deciphering a faded photocopy is a minute a patient waits for care.

## The First Attempt: The Vendor (2023–2024)

In August 2023, a vendor was engaged — promising AI-powered document intelligence at $1 per authorization. After 10 months and over $200K in upfront costs, the project was paused. The system struggled with degraded documents, costs were orders of magnitude higher than proposed, and had it reached production, the projected annual operating cost would have exceeded **$1 million per year**.

The technology wasn't ready yet.

## The Learning

The vendor wasn't incompetent. The team wasn't unprepared. In 2023, vision AI couldn't reliably handle degraded, complex documents at scale. But the team learned what "production-ready" meant for the use case — which features were hardest to extract, where confidence scoring mattered, what staff needed from the system.

## The Breakthrough: Platform AI (2025)

In October 2025, another proof-of-concept crossed the threshold. Confidence scores >90%. Managed platform AI with pay-per-use pricing. No custom infrastructure. The difference: **18 months of AI evolution.**

## Building Internally

- **Team:** 1 architect, 2 engineers, 1 QA, 1 PM, domain advisors
- **Timeline:** 5 months from POC to production
- **Architecture:** RESTful API, 20+ endpoints, database-driven prompts, multi-client, confidence-based routing
- **Cost:** <$1/document all-in (vs. $3–4 manual baseline)

## The Comparison

| | Vendor (2023–24) | Internal (2025–26) |
|---|---|---|
| Infrastructure | Custom K8s/ES/ML stack | Managed platform AI |
| Timeline | 10 months, paused | 5 months to production |
| Cost | $200K+ upfront, $1M+/year projected | <$1/document |
| Control | Black box | Full visibility |
| Outcome | Paused | Live, scaling |

## Key Lessons

1. **Timing is everything** — AI maturity matters more than strategy, budget, or vendor selection
2. **Platform maturity changed the economics** — managed AI eliminated custom ML infrastructure
3. **Prompt engineering is systems engineering** — not "call an API and hope"
4. **Patient safety must be foundational** — confidence thresholds, human-in-the-loop, error handling
5. **Internal development became viable** — foundation models + platform AI = control
6. **Change management matters** — reframe "failure" as reconnaissance

---

*[Douglas Jones](https://www.codifide.com/douglas-jones) · [Codifide](https://www.codifide.com)*

*The [Agentic Stage-Gate Governance](https://github.com/codifide/agentic-stage-gate-governance) framework is open source.*
