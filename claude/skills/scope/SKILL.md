---
name: scope
description: Set today's work scope from open issues, track progress, resist scope creep. Use at session start to pick a fixed list, during work to stay focused, and at session end to reconcile.
---

# /scope — Daily Work Scope

Define a bounded set of work for today. Track it. Stop when it's done.

## Commands

- `/scope` or `/scope set` — Start of session. Pick today's work.
- `/scope status` — Show progress against today's plan.
- `/scope done` — End of session. Reconcile and close out.
- `/scope add #N` — Add an issue mid-session (will prompt to bump something).

## Behavior

### `/scope` (start of session)

1. Check for existing `plans/` file for today. If found, show it and ask to resume or replace.
2. If no file exists:
   - Fetch open issues from GitHub (`gh issue list`)
   - Present them grouped by label (bug, enhancement, marketing, etc.)
   - Ask: "What's on the plate today?"
   - User picks specific issue numbers
3. Write `plans/YYYY-MM-DD.md` with the scope.
4. Confirm: "Scope set. N items. Let's go."

### During work (scope enforcement — soft/medium)

When the user asks to work on something NOT in today's scope:

- **If it's clearly a fast follow** (review finding, broken by current work): Allow it, log under `## Unplanned` with justification.
- **If it's a new ask**: Say something like — "That's not on today's list. Want to add it and bump something, or stash it for next session?"
- **Never block work.** Just surface the trade-off.

### `/scope status`

Read today's plan file. Show:
- What's done (checked off)
- What's in progress
- What's remaining
- Any unplanned additions

### `/scope done` (end of session)

1. Read today's plan file
2. For completed items: note the PR number
3. For incomplete items: mark as spillover
4. Show summary:
   ```
   Today: 3/4 completed
   ✓ #527 → PR #530
   ✓ #528 → PR #530
   ✓ #484 → PR #535
   ○ #482 — spillover

   Unplanned: 1
   ✓ #529 NaN guard (fast follow)
   ```
5. Ask: "Want to carry #482 to next session or drop it back to the backlog?"

## File Format

Location: `scope/YYYY-MM-DD.md` in the project root.

```markdown
# YYYY-MM-DD

## Scope
- [ ] #N — short description (label, effort estimate)
- [ ] #N — short description (label, effort estimate)
- [ ] #N — short description (label, effort estimate)

## Completed
<!-- moved here as items finish -->

## Spillover
<!-- incomplete items at end of session -->

## Unplanned
<!-- scope creep log — what got added and why -->
```

## Rules

- `plans/` should be in `.gitignore` — this is local working state, not project history.
- Each session starts with a finite list. The list IS the work.
- "One more thing" is the enemy. Surface it, don't enable it.
- Completing the list early = done early. Don't fill the gap.
- The skill doesn't judge priorities — user picks, skill tracks.
