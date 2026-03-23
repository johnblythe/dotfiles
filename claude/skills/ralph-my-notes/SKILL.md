---
name: ralph-my-notes
description: Convert raw notes or voice dumps (Wispr Flow, etc.) into GitHub issues and optionally batch into prd.json for Ralph. Use when user says "ralph my notes", "turn this dump into issues", "convert my notes into issues", or has unstructured text to process into trackable work items.
---

# Ralph My Notes

Transform unstructured notes into GitHub issues. Optionally chain to Ralph for execution.

## PRD Contention Handling

Before invoking ralph skill, check if prd.json is "in use":

```bash
# Check 1: Is ralph.sh running?
pgrep -f "ralph.sh" > /dev/null && echo "RALPH_RUNNING"

# Check 2: Does prd.json exist with incomplete stories?
jq '[.userStories[] | select(.passes == false)] | length' scripts/ralph/prd.json 2>/dev/null
```

**If either check shows active work:**
- Pass `--queued` context to ralph skill
- Ralph will create `prd.queued-{n}.json` instead of overwriting prd.json
- Report: "PRD queued as prd.queued-{n}.json (current prd.json in use)"

**If no contention:**
- Normal flow - ralph creates/overwrites prd.json

## Critical: Trigger Intent

| Trigger | Intent | Behavior |
|---------|--------|----------|
| "ralph my notes" | Full auto | Issues → invoke ralph skill with issue list |
| "ralph my notes and get to work" | Full auto | Same as above |
| "turn this dump into issues" | Issues only | Create issues, done |
| "convert my notes into issues" | Issues only | Create issues, done |

**"ralph" in the trigger = create issues, then invoke ralph skill. No confirmations.**

## Workflow

```
User says "ralph my notes" + raw text
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ 1. Parse text → extract work items                  │
│ 2. Create GH issues (all, no confirmation)          │
│ 3. Invoke ralph skill with issue numbers            │
│    (ralph skill creates prd.json, runs ralph.sh)   │
└─────────────────────────────────────────────────────┘
```

**This skill does NOT create prd.json.** The ralph skill owns that format.

## Step 1: Parse & Extract

Analyze raw text for work items:
- Features ("need to add...", "should have...")
- Bugs ("broken", "doesn't work", "fix...")
- Tasks ("update", "change", "refactor...")
- Ideas (label as `idea`)

Extract: title, description, type.

## Step 2: Create GitHub Issues

Create ALL issues immediately. No confirmation needed.

```bash
gh issue create --title "Title" --body "Description" --label "type:feature"
```

Capture the issue numbers from output (e.g., #123, #124, #125).

Check CLAUDE.md for `issue-tracker` preference. Default: github.

## Step 3: Invoke Ralph (if requested)

**If user said "ralph" anywhere in their request:**

First, check for PRD contention (see above). Then invoke the `ralph` skill with:
- The issue numbers created
- Brief context: "Created from voice dump, batch these for execution"
- **If contention detected:** Add "PRD in use - create as queued"

The ralph skill will:
1. Create proper prd.json (or prd.queued-{n}.json if contention)
2. Run ralph.sh in background (only if not queued)

DO NOT:
- Create prd.json yourself
- Ask "want me to run ralph?"
- Output commands and wait

JUST INVOKE THE RALPH SKILL.

## Configuration (CLAUDE.md)

```markdown
## Ralph My Notes Config
- issue-tracker: github
```

## Example Flow

**User:** "ralph my notes: login is broken on mobile, need password reset, dashboard is slow, update readme with env vars"

**You do (silently, no confirmations):**
1. Create 4 GH issues → #45, #46, #47, #48
2. Check PRD contention:
   - `pgrep -f ralph.sh` → running?
   - `jq ... prd.json` → incomplete stories?
3. Invoke ralph skill with context:
   - No contention: "Created issues #45-48 from voice dump. Convert to prd.json and run."
   - **With contention:** "Created issues #45-48 from voice dump. PRD in use - create as queued."
4. Report:
   - No contention: "Created 4 issues (#45-48), handed off to Ralph."
   - **With contention:** "Created 4 issues (#45-48), queued as prd.queued-1.json (Ralph currently running)."

Done. Hands off.
