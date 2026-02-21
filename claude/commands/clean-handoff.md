---
description: Save session context to HANDOFF.md, archive previous, then clear session
---

# Clean Handoff

Analyze our entire conversation and prepare a clean context handoff. This will:
1. Archive any existing HANDOFF.md
2. Write a new comprehensive `context/HANDOFF.md`
3. Show a brief summary — then you hit `/clear`

## Step 1: Archive

If `context/HANDOFF.md` exists, move it to `context/archive/{YYYY-MM-DD}-{NNN}.md` where NNN is the next available zero-padded number for today (001, 002, etc.). Create `context/archive/` if needed.

## Step 2: Write HANDOFF.md

Create `context/HANDOFF.md` by analyzing the full conversation:

```markdown
# Handoff — [ISO 8601 timestamp]

> Handoff #{N} today. Arc: [one-line breadcrumb trail of today's handoffs if archive files exist, e.g. "auth scaffolding → API routes → frontend integration"]

## What We're Building
[1-2 sentences: the feature/task and its purpose]

## Where We Are Right Now
- **Status**: [exactly where things stand]
- **Active files**: [files currently being modified]
- **Working/broken**: [what's passing, what's failing]

## Key Decisions
[Bullet list of architectural/technical decisions made and WHY. Only meaningful ones — skip obvious stuff.]

## What Changed This Session
- **Modified**: [file list]
- **Added**: [new files/deps]
- **Config**: [env/build/config changes]

## Unfinished Work
- **In progress**: [what's partially done — be specific about state]
- **Blocked**: [what's waiting on something]
- **Known issues**: [bugs, gotchas discovered]

## Next Steps
[Prioritized list of immediate actions. First item = what to do RIGHT NOW.]

## How to Resume
[Commands to run, servers to start, tests to check — everything needed to pick up where we left off]
```

**Important**: This file is the SOLE context carrier for the next session. It must be complete enough to resume work without any conversation history. Don't be terse to the point of losing critical context.

## Step 3: Summary

After writing the file, output EXACTLY this format:

```
📋 Handoff #{N} saved → context/HANDOFF.md
{if archived} 📦 Archived → context/archive/{filename}
Working on: [one line]
Next: [first next step]

→ /clear
```

DO NOT add extra text, bullets, explanations, or try to run /clear yourself.
The last line is a prompt for the user to copy/paste. Keep it on its own line.

## SessionStart Hook

The existing SessionStart hook will auto-inject `context/HANDOFF.md` (update the hook to read HANDOFF.md instead of WORKING.md).
