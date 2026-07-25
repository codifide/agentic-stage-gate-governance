# Agent Hooks — Session State Management

These hook templates ensure your AI agent loads full project context at session start and persists state at session end. They work with Kiro's hook system (`.kiro/hooks/*.json`).

---

## Why Hooks Matter

AI agents lose context between sessions. Without hooks:
- The agent forgets what was accomplished
- It re-discovers things already documented in steering files
- It skips files and loses institutional memory
- Session handoffs are incomplete

With hooks:
- Every session starts with full context loaded — no files skipped
- Every session ends with a state handoff for the next one
- PHI and security boundaries are enforced automatically

---

## Hook 1: Load All Steering Files on Session Start

**File:** `.kiro/hooks/load-session-state.json`

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Load all steering files on session start",
      "trigger": "SessionStart",
      "description": "Ensures ALL steering files are loaded at the start of every session — no subset, no skipping",
      "action": {
        "type": "agent",
        "prompt": "MANDATORY: Before doing ANYTHING else, you MUST list the directory <YOUR_PROJECT>/.kiro/steering/ and then read EVERY .md file in it using read_files (batch them as needed). Do NOT skip any files — they are ALL institutional memory and ground truth. Start with next-session-prompt.md to understand current state, then load every remaining file. After all steering files are loaded, act on the next-session-prompt immediately."
      }
    }
  ]
}
```

### Key Design Decisions

1. **List the directory first, then load everything.** This means new steering files added between sessions are automatically picked up — no hook edits needed.
2. **Start with `next-session-prompt.md`.** This gives the agent immediate context on what to do, while the remaining files provide the institutional knowledge to do it correctly.
3. **"Do NOT skip any files"** is explicit because agents will optimize for brevity if given a choice. Every steering file exists for a reason.

---

## Hook 2: Update Session State on End

**File:** `.kiro/hooks/update-session-state.json`

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Update next-session-prompt on session end",
      "trigger": "Stop",
      "description": "Reminds the agent to update next-session-prompt.md before the session ends",
      "action": {
        "type": "agent",
        "prompt": "Before this session ends, you MUST update .kiro/steering/next-session-prompt.md with: 1) What was accomplished this session, 2) Current initiative/gate status, 3) Immediate next actions for the following session, 4) Any key metrics or environment state changes. This is the institutional memory handoff — future sessions depend on it."
      }
    }
  ]
}
```

### What Goes in `next-session-prompt.md`

The session state file is the agent's short-term memory between sessions. It should contain:

| Section | Purpose |
|---------|---------|
| Current Status | What was just accomplished, when, git SHA |
| Environment State | Which services are running, ports, health |
| Immediate Next Actions | Prioritized list of what to do next |
| Key Metrics | Numbers that matter (scores, counts, rates) |
| Architecture Decisions | Decisions made this session that affect future work |

---

## Hook 3: PHI Screenshot Guard (Healthcare Projects)

**File:** `.kiro/hooks/phi-screenshot-guard.json`

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "PHI Screenshot Guard",
      "trigger": "PreToolUse",
      "matcher": "browser_take_screenshot",
      "description": "Prevents screenshots from being saved into git-tracked directories where they could expose PHI",
      "action": {
        "type": "agent",
        "prompt": "IMPORTANT: You are about to take a screenshot. Screenshots of healthcare applications may contain PHI. You MUST save the screenshot to /tmp/ or ~/Downloads — NEVER to the project directory or any git-tracked location. Verify the filename path before proceeding."
      }
    }
  ]
}
```

---

## Installation

```bash
# From your project root:
mkdir -p .kiro/hooks

# Copy the hook files you need:
# Option A: Create them manually from the templates above
# Option B: Copy from this repo's templates

# Verify hooks are loaded — they activate on next session start
```

---

## Designing Custom Hooks

### Trigger Reference

| Trigger | Fires When | Common Use |
|---------|------------|------------|
| `SessionStart` | New session begins | Load context, check environment |
| `Stop` | Session is ending | Persist state, update handoff docs |
| `PreToolUse` | Before a tool executes | Access control, safety guards |
| `PostToolUse` | After a tool executes | Logging, verification |
| `PostFileSave` | User saves a file | Lint, format, test |
| `PostFileCreate` | New file created | Template enforcement, naming conventions |
| `UserPromptSubmit` | User sends a message | Input validation, routing |

### Action Types

| Type | What It Does | Use When |
|------|--------------|----------|
| `agent` | Injects a prompt into agent context | You want the agent to consider/follow instructions |
| `command` | Runs a shell command | You want automated verification (lint, test, build) |

### Best Practices

1. **Keep prompts directive.** "You MUST" is clearer than "Please consider."
2. **Be explicit about what NOT to do.** Agents optimize for completion — tell them what to skip.
3. **Use matchers to scope hooks.** A `PostFileSave` hook on `\\.(ts|tsx)$` won't fire on Python files.
4. **Test hooks by starting a new session.** SessionStart hooks only fire once — not mid-conversation.
5. **Don't hardcode file lists.** Use "list the directory and load everything" instead of naming specific files. New files added later will be picked up automatically.

---

*Part of Agentic Stage-Gate-Loop Governance v2.0 — July 2026*
