# Notice

This file records the licence of this repository, the sources that influenced its ideas, trademark information, and a note on AI-assisted authorship. It is informational and is not legal advice.

## 1. Licence of this repository

This repository is licensed under the MIT License. Copyright (c) Codifide Inc. See [LICENSE](LICENSE).

The MIT License does not grant any right to use Codifide names or logos.

> **[FLAG FOR COUNSEL]** The status of the Codifide marks is not asserted by this file. The README footer currently states that certain marks are registered; counsel should confirm that statement before it is relied on.

## 2. Acknowledgements

The projects and publications below influenced ideas in this harness. Licence information was checked against the primary sources on 2026-11-10. Licences listed here are those of the third-party projects, not of this repository.

**Ideas only.** No code or documentation text from the projects below was copied into this repository. Where a source is academic or published, it is cited. Descriptions are a short summary of the idea, not an endorsement of any claim by the source.

| Source | Idea that influenced this harness | URL | Licence, as verified |
|---|---|---|---|
| karpathy/autoresearch (Andrej Karpathy) | An agent loop with a fixed evaluator it must not edit, a fixed time budget, and keep-or-discard of changes by a metric. `steering/08` describes the harness's immutable-verifier rule as the same discipline. | https://github.com/karpathy/autoresearch | The README says "MIT", but the repository contains no LICENSE file and GitHub reports no detected licence. Treat the licence as unclear. Nothing was copied. |
| Bilevel Autoresearch: Meta-Autoresearching Itself (Yaonan Qu, Meng Lu), arXiv:2603.23420 | An outer loop that changes how an inner loop searches. The bounded meta-loop in `steering/08` is a related idea. This paper is third-party work, separate from the autoresearch repository. | https://arxiv.org/abs/2603.23420 | Academic publication; see the arXiv page for its terms. Nothing was copied. |
| BMAD Method (BMad Code, LLC), described by the project as "Breakthrough Method for Agile Ai Driven Development" | Specialised agent personas and reviewer roles used as a point of comparison for the persona and review design. | https://github.com/bmad-code-org/BMAD-METHOD | MIT, Copyright (c) 2025 BMad Code, LLC. The project has a separate trademark notice (see below). Nothing was copied. |
| GitHub Spec Kit (GitHub, Inc.) | Specification-driven workflow (constitution, specify, plan, tasks, implement) reviewed as a comparison for intent and requirements artifacts. No Spec Kit feature is adopted in this repository at the time of writing. | https://github.com/github/spec-kit | MIT, Copyright GitHub, Inc. Nothing was copied. |
| Robert G. Cooper, Stage-Gate model | The stage-gate structure of decision points between development stages, which this harness extends with loops and AI-specific controls. See the references in [WHITEPAPER.md](WHITEPAPER.md) and [README.md](README.md). | https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products | Published works; see the publishers' terms. "Stage-Gate" is shown with the (R) symbol in cited sources. See the trademark flag below. |
| Other cited references | The articles in `articles/`, [WHITEPAPER.md](WHITEPAPER.md), and [LOOP-ENGINEERING-GUIDE.md](LOOP-ENGINEERING-GUIDE.md) each carry their own reference lists (for example press coverage, industry surveys, and security publications). Those lists are the attribution for the points made in those documents. | See each document | Published works; see each publisher's terms. |

## 3. Trademarks

Names of other parties' products, projects, and companies are used to identify them (nominative use). No affiliation with, sponsorship by, or endorsement by those parties is implied. Marks belong to their respective owners.

- "BMad" and "BMAD-METHOD" are identified by the BMAD project as trademarks of BMad Code, LLC. See https://github.com/bmad-code-org/BMAD-METHOD/blob/main/TRADEMARK.md.
- "Stage-Gate" appears with the (R) symbol in sources cited by this repository. This repository's own name for its framework is "Stage-Gate-Loop".

> **[FLAG FOR COUNSEL]** Whether the name "Stage-Gate-Loop" is acceptable alongside a third party's "Stage-Gate" mark is a question for an attorney. This file makes no conclusion.

## 4. AI-assisted authorship

Some content in this repository was drafted with AI assistance and reviewed by a human. Generated text can be wrong, can resemble existing works, and needs review before reuse. Contributors and users should treat it that way. This file makes no statement about whether any part of the content is or is not protected by copyright.

> **[FLAG FOR COUNSEL]** Copyrightability and ownership of AI-assisted content.
