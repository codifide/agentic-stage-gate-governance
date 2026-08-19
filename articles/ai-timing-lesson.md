> **Note:** The canonical version of this article is the HTML file on the Codifide website.
> - [ai-timing-lesson.html](./ai-timing-lesson.html) (local HTML)
> - Live at [codifide.com/ai-timing-lesson](https://www.codifide.com/ai-timing-lesson)

---

# Why AI Timing Matters More Than Strategy

**A Healthcare Document Automation Story**

*Douglas Jones · 2026*

---

## The Problem

Release of Information (ROI) processing is the invisible infrastructure that keeps healthcare moving. Authorization forms arrive via fax as degraded photocopies with dozens of fields requiring manual entry. At scale, the processing cost is significant — and every delay is a delay in patient care.

## The Vendor Attempt

In late 2023, a vendor was engaged with a compelling AI-powered document intelligence pitch. Nearly a year of effort and significant investment later, the project was paused. The system struggled with degraded documents, costs diverged from proposals, and the projected production operating cost would have been well into seven figures annually.

The technology wasn't ready yet.

## The Learning

The engagement wasn't wasted — it produced invaluable knowledge about which features were hardest to extract, where confidence scoring mattered, what staff needed, and what production integration required. The narrative was reframed: not failure, but reconnaissance.

## The Breakthrough: Platform AI

Roughly 18 months later, vision-language models and managed AI platforms had matured dramatically. A proof-of-concept crossed the production-viability threshold. High confidence scores on real documents. Predictable pay-per-use economics. No custom infrastructure required.

## Building Internally

A small team built the replacement in months — a RESTful API with database-driven prompts, multi-client support, confidence-based routing, and full observability. Production-deployed and scaling.

## The Comparison

| | Vendor Attempt | Internal Build |
|---|---|---|
| Infrastructure | Custom ML stack | Managed platform AI |
| Timeline | Nearly a year, paused | Months to production |
| Cost trajectory | Six figures upfront, seven figures/year projected | Fraction of manual cost per document |
| Control | Black box | Full visibility |
| Outcome | Paused | Live, scaling |

Same problem. Same documents. Different outcome. The difference was timing.

## Key Lessons

1. **Timing is everything** — AI maturity matters more than strategy or vendor selection
2. **Platform maturity changed the economics** — managed AI eliminated custom infrastructure
3. **Prompt engineering is systems engineering** — not "call an API and hope"
4. **Patient safety must be foundational** — confidence thresholds, human-in-the-loop, error handling
5. **Internal development became viable** — foundation models + platform AI = control
6. **Change management matters** — reframe past attempts as learning, lead with evidence

---

*[Douglas Jones](https://www.codifide.com/douglas-jones) · [Codifide](https://www.codifide.com)*

*The [Agentic Stage-Gate Governance](https://github.com/codifide/agentic-stage-gate-governance) framework is open source.*
