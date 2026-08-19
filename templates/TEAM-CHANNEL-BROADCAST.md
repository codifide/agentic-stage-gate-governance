# Team Channel Broadcast Hook

Every prompt/response cycle should be treated like a team Slack channel. All personas are "listening" and can act on what's happening. Without this, lessons are discussed in chat but never persisted — and are lost at session boundary.

---

## The Problem

AI agents discuss corrections, lessons, and decisions in chat but don't write them to steering files. The next session starts fresh and doesn't know what was learned. This creates a recurring pattern:

1. Human expert gives feedback
2. Agent discusses the lesson eloquently in chat
3. Agent moves on to implementation
4. Lesson is never written to the steering file
5. Next session makes the same mistake

---

## The Solution: Team Channel Broadcast Hook

**File:** `.kiro/hooks/team-channel-broadcast.json`

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Team Channel Broadcast",
      "trigger": "UserPromptSubmit",
      "action": {
        "type": "agent",
        "prompt": "TEAM CHANNEL — Every prompt is visible to the full team. Before responding, consider:\n\n1. **Domain Expert (SME):** Does this prompt contain a correction, rule, or lesson from the real-world expert? If yes → write to the domain expert steering file IMMEDIATELY (binding corrections table or thinking patterns). Do not discuss without persisting.\n\n2. **Quill (Narrative/Documentation):** Does this interaction reveal something about the product story, architecture decisions, or user-facing impact? If yes → note it for documentation updates when appropriate.\n\n3. **Stage-Gate Reviewer:** Did a spec, initiative, or gap status change? If yes → update the stage-gate status table.\n\n4. **Session Scribe:** Did anything change that the next session needs to know? If yes → update next-session-prompt.md before moving on.\n\n5. **Test Guardian:** Were tests affected, patterns broken, or regressions introduced? If yes → verify test counts and update metrics.\n\nRULE: If a persona's domain was touched, the corresponding file MUST be updated in the SAME response. Chat-only knowledge is lost knowledge."
      }
    }
  ]
}
```

---

## Why This Works

- **Immediate persistence:** Corrections go to files, not just chat
- **No persona is silent:** Every team member "hears" every interaction
- **Prevents knowledge loss:** The #1 failure mode of agentic sessions is learning something and not writing it down
- **Self-enforcing:** The hook fires on every prompt, so it can't be forgotten

---

## Adapting for Your Project

Replace the persona names and file paths with your project's equivalents:

| Role | Your Persona | Your File |
|------|-------------|-----------|
| Domain Expert | [Your SME name] | `.kiro/steering/XX-domain-expert.md` |
| Documentation | Quill / Paige | README, specs, docs/ |
| Stage-Gate | Aegis | `.kiro/steering/XX-stage-gate.md` |
| Session State | Scribe | `.kiro/steering/next-session-prompt.md` |
| Test Quality | Tessa | Test files, metrics |

---

## Key Lesson

> **If it's worth saying in chat, it's worth writing to a file.**

Chat is ephemeral. Steering files are institutional memory. The team broadcast hook bridges this gap by making every interaction a potential write event.
