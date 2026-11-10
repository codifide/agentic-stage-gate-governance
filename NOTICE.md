# Notice

This file records the licence of this repository, the sources that influenced its ideas, trademark information, and a note on AI-assisted authorship. It is informational and is not legal advice.

## 1. Licence of this repository

This repository is licensed under the MIT License. Copyright (c) Codifide Inc. See [LICENSE](LICENSE).

The MIT License does not grant any right to use Codifide names or logos.

Codifide®, Confidence in Code®, and the Codifide logo mark are registered trademarks of Codifide Inc. (registration documentation held by Codifide Inc.). "Codifide Harness" (this framework and harness, formerly Stage-Gate-Loop and SGL Harness) and "Codifide Swarm" (a separate private commercial product) are product names in use by Codifide Inc., not registered trademarks; no registration is claimed for them.

## 2. Acknowledgements
This framework, its harness and its site were shaped by the sources below. Where a source corroborated a design we had already reached, or was only compared, the table says so. Licence information was checked against primary sources on 2026-11-10. Licences listed here are those of the third-party works, not of this repository.

**Ideas only.** no code or documentation text from these sources was copied. Similarity is not a claim of endorsement or equivalence. Descriptions are short summaries of an idea, not an endorsement of any claim by the source.

### Methods and frameworks

| Source | What we learned | Where it shows up | Link | Licence / terms |
|---|---|---|---|---|
| Robert G. Cooper, Stage-Gate® model: *Winning at New Products* (1986); "Stage-Gate Systems: A New Tool for Managing New Products", *Business Horizons* (1990) | Work moves through stages separated by gates. Each gate is a go, kill or hold decision made on evidence, so weak projects are stopped early. This framework keeps that structure and adds automated verification loops and controls for AI agents. | Harness: `steering/01-governance-gates.md`, `WHITEPAPER.md`. Site: /governance-whitepaper, /governance/stage-gate-loop | [ResearchGate](https://www.researchgate.net/publication/4883499_Stage-Gate_Systems_A_New_Tool_for_Managing_New_Products)<br>[Sopheon interview](https://www.sopheon.com/blog/stage-gate-the-origin-status-quo-and-its-future/) | Published works; see the publishers' terms. Stage-Gate® is a registered trademark (see the trademark notice). |
| Andrej Karpathy, *autoresearch* (GitHub repository, 2026) | An agent edits one file under a fixed time budget, a separate evaluation file stays unmodified, and each change is kept or discarded by a metric. We apply the same discipline as a rule: a loop may read its verifier but never edit it. | Harness: `steering/08-loop-engineering.md`, `templates/enforcement/`. Site: /loop-engineering | [GitHub](https://github.com/karpathy/autoresearch) | The README says MIT, but the repository has no LICENSE file and GitHub reports no licence. Treat the licence as unclear. Nothing was copied. |
| BMad Code, LLC, *BMAD Method* ("Breakthrough Method for Agile Ai Driven Development") | Process depth should be sized to the change, and agent roles can be packaged as reusable skills. This framework's Express, Standard and Enterprise tracks follow the right-sizing idea; the track names, the gate rules and the authority boundaries on personas are our own. | Harness: `steering/01-governance-gates.md` (tracks). Site: /governance/domain-expert-personas | [GitHub](https://github.com/bmad-code-org/BMAD-METHOD) | MIT, Copyright (c) 2025 BMad Code, LLC. "BMad" and "BMAD-METHOD" are trademarks of BMad Code, LLC (see their TRADEMARK.md). Nothing was copied. |
| GitHub, Inc., *Spec Kit* | A specification-driven workflow (constitution, specify, plan, tasks, implement). We reviewed it as a comparison for requirements artifacts. No Spec Kit feature or text is used. | None (compared only) | [GitHub](https://github.com/github/spec-kit) | MIT, Copyright GitHub, Inc. Nothing was copied. |

### Research

| Source | What we learned | Where it shows up | Link | Licence / terms |
|---|---|---|---|---|
| Yaonan Qu, Meng Lu, "Bilevel Autoresearch: Meta-Autoresearching Itself", arXiv:2603.23420 (2026) | An outer loop can change how an inner loop searches when the inner loop stalls. Our bounded meta-loop (one intervention per plateau, never touching the verifier) is a related idea. This paper is separate from Karpathy's repository, which contains no meta-loop. | Harness: `steering/08-loop-engineering.md` (Meta-Loop). Site: /loop-engineering | [arXiv](https://arxiv.org/abs/2603.23420) | Academic publication; see the arXiv page for its terms. |
| Jiayi Geng, Graham Neubig, "Effective Strategies for Asynchronous Software Engineering Agents", arXiv:2603.21489 (2026) | Concurrent agents work best in isolated workspaces with branch-and-merge integration checked by executable tests. This corroborated our worktree-per-session and test-based integration design; it did not originate it. | Harness: `steering/13-concurrent-sessions.md` | [arXiv](https://arxiv.org/abs/2603.21489) | Academic publication; see the arXiv page for its terms. |
| Haocheng Xia, Eugene Wu, Yongjoo Park, "Passes Alone, Fails Together: Benchmarking Semantic Coordination in Parallel LLM-Agent Development", arXiv:2609.25396 (2026) | Patches that each pass their own tests can fail once merged, so integration must be tested on the merged state. We added an integration check that runs against the merged branches. | Harness: `steering/13-concurrent-sessions.md` (integration verifier) | [arXiv](https://arxiv.org/abs/2609.25396) | Academic publication; see the arXiv page for its terms. |
| Sumanyu Muku, "Verifying Coordination in Parallel Coding Agents: NP-Bench and a Scheduling Planner", arXiv:2610.07261 (2026) | Declare disjoint scopes and order merges up front instead of reacting to conflicts afterwards. We document this as an option to adopt when collisions recur; it is not a default. | Harness: `steering/13-concurrent-sessions.md` (deferred-options table) | [arXiv](https://arxiv.org/abs/2610.07261) | Academic publication; see the arXiv page for its terms. |
| Dipankar Sarkar, "Before the Pull Request: Mining Multi-Agent Coordination", arXiv:2606.19616 (2026) | Background: the coordination gap between agents appears before a pull request, while work is claimed and divided. It motivated handling coordination at task-division time. We did not adopt its tooling. | Background only (informed `steering/13-concurrent-sessions.md`) | [arXiv](https://arxiv.org/abs/2606.19616) | Academic publication; see the arXiv page for its terms. |
| Vivek Acharya, "Semantic Consensus: Process-Aware Conflict Detection and Resolution for Enterprise Multi-Agent LLM Systems", arXiv:2604.16339 (2026) | Background: the paper reports that most multi-agent production failures come from specification and coordination problems rather than model capability. We cite it as motivation only; no file implements its framework. | Background only (motivation for the concurrency work) | [arXiv](https://arxiv.org/abs/2604.16339) | Academic publication; see the arXiv page for its terms. |

### Engineering practice

| Source | What we learned | Where it shows up | Link | Licence / terms |
|---|---|---|---|---|
| Mergify, "Merge Queues Were Built for Humans. AI Agents Need More." (company blog, 2026) | Merge skew: two changes that each pass can break once combined. Test candidate merges together, batch with bisect on failure, and tell flaky failures from real regressions. We kept the merged-state check and listed the queue and test-health ideas as options to adopt when needed. | Harness: `steering/13-concurrent-sessions.md` | [Mergify blog](https://mergify.com/blog/merge-queues-and-ai-coding-agents) | Company blog post; all rights reserved by the publisher. Nothing was copied. |
| Anthropic, Claude Code documentation: "Run parallel sessions with worktrees"; Git documentation: git-worktree | Give each concurrent agent session its own git worktree, a separate checkout and branch, so edits do not collide. | Harness: `steering/13-concurrent-sessions.md` (worktree per session) | [Claude Code docs](https://code.claude.com/docs/en/common-workflows)<br>[git-worktree](https://git-scm.com/docs/git-worktree) | Vendor and project documentation; see their terms. Nothing was copied. |

### Tools used to build and review

| Source | What we learned | Where it shows up | Link | Licence / terms |
|---|---|---|---|---|
| AI coding assistants and language models from several vendors (for example the Kiro assistant and Anthropic's Claude models) | AI assistants and multiple model families were used to draft this work and to review it adversarially. A human reviewed the results. Model output can be wrong and was treated as untrusted until checked. | Throughout; see the AI-assisted authorship note | [Third-party names](https://www.codifide.com/trademarks) | Used under each provider's terms. Names are used to identify the tools only. |

### Other sources

| Source | What we learned | Where it shows up | Link | Licence / terms |
|---|---|---|---|---|
| Press, industry and security publications cited in individual articles | Each article and whitepaper carries its own reference list. Those lists are the attribution for the specific points made there. | Harness: `articles/`, `WHITEPAPER.md`, `LOOP-ENGINEERING-GUIDE.md`. Site: article reference lists | See each document | Published works; see each publisher's terms. |

Stage-Gate® is a registered trademark of Stage-Gate International (United States, Australia) and of R.G. Cooper & Associates (European Union, Canada), as stated in the cited literature. This framework is based on Robert G. Cooper's Stage-Gate® model. Codifide Inc. is not affiliated with, sponsored by, or endorsed by Stage-Gate International or R.G. Cooper & Associates.

## 3. Trademarks

Names of other parties' products, projects, and companies are used to identify them (nominative use). No affiliation with, sponsorship by, or endorsement by those parties is implied. Marks belong to their respective owners.

- "BMad" and "BMAD-METHOD" are identified by the BMAD project as trademarks of BMad Code, LLC. See https://github.com/bmad-code-org/BMAD-METHOD/blob/main/TRADEMARK.md.
- Stage-Gate® is a registered trademark of Stage-Gate International (United States, Australia) and of R.G. Cooper & Associates (European Union, Canada), as stated in the cited literature. The Codifide Harness framework (formerly called Stage-Gate-Loop) is based on Robert G. Cooper's Stage-Gate® model and extends it with automated verification loops and AI-specific controls. Codifide Inc. is not affiliated with, sponsored by, or endorsed by Stage-Gate International or R.G. Cooper & Associates.


## 4. AI-assisted authorship

Some content in this repository was drafted with AI assistance and reviewed by a human. Generated text can be wrong, can resemble existing works, and needs review before reuse. Contributors and users should treat it that way. This file makes no statement about whether any part of the content is or is not protected by copyright.

> **[FLAG FOR COUNSEL]** Copyrightability and ownership of AI-assisted content.
