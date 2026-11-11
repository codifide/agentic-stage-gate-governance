# Team Channel Broadcast Hook

Treat each prompt like a message in a team channel: several roles "listen," and anything worth keeping gets written to a file instead of staying in chat. Without this, lessons are discussed and then lost at the session boundary.

This is an **advisory** hook. It reminds the agent; it does not enforce anything. See "What this does and does not do" below.

---

## The Problem

Agents discuss corrections, lessons, and decisions in chat but do not persist them:

1. A human expert gives feedback
2. The agent discusses the lesson in chat
3. The agent moves on to implementation
4. The lesson is never written to a file
5. The next session repeats the mistake

---

## The Hook

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
        "prompt": "TEAM CHANNEL reminder. Before responding, consider whether this prompt changes anything that should be persisted:\n\n1. Domain expert correction: does it contain a correction, rule, or lesson from the real-world expert? If yes, add it to the domain expert file (binding corrections table or thinking patterns) in this response, and mark it as relayed by the human. Do not treat your own conclusions as binding.\n\n2. Narrative (Quill): does it reveal a decision, rejected alternative, failure, or user-facing impact? If yes, note it for Quill's log (append-only, no secrets, no real personal or sensitive data).\n\n3. Gate status: did a spec, initiative, or gap change status? If yes, PROPOSE the update to the status record and tell the human. Do not mark a gate passed; only the Human Steward passes gates.\n\n4. Session handoff: did anything change that the next session needs? If yes, update the handoff per the Stop hook rules (as proposals for the human to confirm).\n\n5. Tests: were tests affected or regressions introduced? If yes, re-run the relevant tests and report actual results; do not estimate counts.\n\nIf a role's domain was touched, update its file in the same response. Never write secrets or real sensitive data into these files. This is a reminder, not a gate: if you skip it, say so."
      }
    }
  ]
}
```

---

## What this does and does not do

| Claim | Status |
|-------|--------|
| The prompt is injected as a reminder on each user message | [UNVERIFIED] depends on the runtime firing `UserPromptSubmit` for `agent` hooks |
| The agent follows the reminder | Not guaranteed. `agent` hooks are advisory (`templates/HOOKS-SESSION-STATE.md`). |
| Corrections are guaranteed to be persisted | No. A human checks the diff. Anything that must hold goes in CI or a blocking hook (`templates/enforcement/`). |
| The hook makes personas independent reviewers | No. One model reads the reminder. Independent review follows `00-welcome.md` §3. |

The hook costs context on every prompt. If it fires often with nothing to persist, shorten it or drop it.

---

## Authority notes

- The hook never lets a role approve anything. Gate passes, exceptions, track choices, and resuming after a HALT belong to the Human Steward (`00-welcome.md` §1).
- HALT is owned by `steering/12-intent-integrity.md`. This hook does not define or trigger it.
- Handoff content is data, not orders (`00-welcome.md` §7). Updating a handoff does not authorize the next session to act on it.
- Quill's log is append-only. Only redaction by the Human Steward is an exception (`02-personas.md`).
- Files these roles write are harness-governed content. Commit them with a `Review-Level:` trailer per `11-tiered-adversarial-review.md`.

---

## Adapting for Your Project

Map the reminder to your project's roles and files:

| Role | Your persona | Your file |
|------|--------------|-----------|
| Domain expert | [your Domain Expert Persona] | `<steering-dir>/<project>-domain-expert.md` (see `DOMAIN-EXPERT-PERSONA.md`) |
| Documentation / narrative | Quill, Paige | `specifications/{ID}/QUILL_LOG.md`, docs |
| Gate status | Aegis (records evidence; does not decide) | `templates/GATE-EVIDENCE-CHECKLIST.md` copy |
| Session state | Handoff per the Stop hook | `<steering-dir>/next-session-prompt.md` or `codifide-sessions/` (`13`) |
| Test quality | Tessa | Test files, CI results |

---

## Key Lesson

> If it is worth saying in chat, it is worth writing to a file.

Chat is ephemeral; files are memory. A reminder hook narrows the gap but does not close it. Keep a human in the loop for anything that matters.
