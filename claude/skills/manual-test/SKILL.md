---
name: manual-test
description: Interactive manual testing walkthrough. Generates test cases from branch diff/commits, then walks through them one at a time in interview style — collecting pass/fail/partial results, drilling into failures, tracking progress. Use when the user asks to test, QA, manually test, or verify changes before merging. Also use when user says "test this", "QA checklist", "walk me through testing", or "manual test".
---

# Manual Test Walkthrough

Interactive, interview-style manual testing. Not a dump — a guided conversation.

## Workflow

### 1. Gather Context

Understand what changed:

```bash
# What branch are we on, what's the base?
git log --oneline main..HEAD
git diff --stat main..HEAD
```

Read changed files to understand the feature. Group changes into logical test phases.

### 2. Build Test Plan

Structure tests into phases (logical groups). Each test case:

```markdown
### Phase N: {Area Name}

1. {Action to take}
   - Expected: {what should happen}
2. {Next action}
   - Expected: {what should happen}
```

Present the full plan as overview first, with phase names and test counts:

```
Test Plan: 4 phases, 18 tests total

Phase 1: Basic UI (4 tests)
Phase 2: Core Feature (6 tests)
Phase 3: Edge Cases (5 tests)
Phase 4: Integration (3 tests)

Starting Phase 1...
```

### 3. Interview Loop

Present 1-3 tests at a time. Ask user to try them and report back.

Format each batch:

```
--- Phase 1: Basic UI (1/4) ---

Try this:
  1. Open the app and navigate to Settings
     Expected: Settings panel slides in from right

How'd it go?  [pass]  [fail]  [partial]  [skip]
```

#### Handling responses:

- **pass** — Log it, move on
- **fail** — Ask: "What happened instead?" Capture the details. Optionally ask if they want to file an issue now or continue.
- **partial / sorta** — Ask: "What worked and what didn't?" Log the nuance.
- **skip** — Note it, move on. Circle back at end if time permits.

#### Progress indicator after each response:

```
Progress: [====------] 7/18  |  6 pass  |  1 fail  |  0 skip
```

### 4. Adaptive Behavior

- If a phase has 3+ failures, ask: "This phase is rough — want to stop here and fix before continuing?"
- If user reports something unexpected, probe: "Was this a blocker or cosmetic?"
- Group related follow-up tests when a failure might cascade

### 5. Summary

At the end, produce a results table:

```markdown
## Test Results

| # | Phase | Test | Result | Notes |
|---|-------|------|--------|-------|
| 1 | UI | Button label says "Workshop" | pass | |
| 2 | UI | Button says "Re-workshop" after run | fail | Still says "Workshop" |
| ... | | | | |

### Summary
- Total: 18
- Pass: 14
- Fail: 3
- Partial: 1
- Skip: 0

### Failures
1. **Button says "Re-workshop" after run** — Still shows "Workshop". Phase 1, test 2.
2. ...

### Suggested Next Steps
- Fix the 3 failures above
- Re-test Phase 1 after fixes
```

Offer to:
- Create GitHub issues for failures
- Re-run failed tests only
- Save results to a file

## Guidelines

- Keep batches small (1-3 tests). Don't overwhelm.
- Use AskUserQuestion for each batch — this is a conversation, not a monologue
- If the user gives terse answers ("y", "n", "kinda"), that's fine — map to pass/fail/partial
- Include setup steps when needed ("Run `npm run dev` first", "Go to Review tab")
- For UI tests, be specific about what to look for — colors, positions, text
- Adapt phase order if user reports a blocker that affects later phases
- If user says "looks good" without specifics, gently ask them to confirm the expected behavior
