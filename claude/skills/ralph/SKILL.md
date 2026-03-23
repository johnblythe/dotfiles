---
name: ralph
description: "Run Ralph autonomous agent OR convert PRDs/issues to prd.json. Triggers on: ralph it, run ralph, start ralph, convert this prd, turn this into ralph format, create prd.json, or when given issue numbers to batch."
---

# Ralph - Autonomous Agent Runner & PRD Converter

Ralph is an autonomous agent loop that executes user stories from prd.json.

---

## Decision Tree

```
┌─────────────────────────────────────────────────────────┐
│ 0. Context says "PRD in use" or "create as queued"?     │
│    YES → QUEUED MODE (Section D) - don't overwrite      │
├─────────────────────────────────────────────────────────┤
│ 1. prd.json exists with incomplete stories?             │
│    YES → RUN RALPH (Section A)                          │
├─────────────────────────────────────────────────────────┤
│ 2. Given GitHub issue numbers (#123, #124...)?          │
│    YES → FETCH & CONVERT ISSUES (Section C) → RUN       │
├─────────────────────────────────────────────────────────┤
│ 3. Given PRD text/file?                                 │
│    YES → CONVERT PRD (Section B) → RUN                  │
├─────────────────────────────────────────────────────────┤
│ 4. Nothing provided?                                    │
│    → Ask user for PRD or issue numbers                  │
└─────────────────────────────────────────────────────────┘
```

**Check for existing prd.json:**
```bash
jq '[.userStories[] | select(.passes == false)] | length' scripts/ralph/prd.json 2>/dev/null
```

---

# Section A: RUN RALPH

If prd.json exists with incomplete stories, **run Ralph immediately in the background.**

```bash
# Run ralph.sh in background - DO NOT WAIT
cd [project-root] && nohup ./scripts/ralph/ralph.sh > /dev/null 2>&1 &
```

**Report to user:**
```
Ralph started with [N] stories. Running in background.

Monitor: tail -f scripts/ralph/progress.txt
Cancel: /cancel-ralph
```

**Show current status:**
```bash
jq -r '.userStories[] | "\(.id): \(.title) - \(if .passes then "✅" else "⏳" end)"' scripts/ralph/prd.json
```

---

# Section B: CONVERT PRD TO prd.json

If no prd.json exists (or all stories complete), convert the provided PRD.

## The Job

Take a PRD (markdown file or text) and convert it to `scripts/ralph/prd.json`.

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",  // or null for work-in-place mode
  "baseBranch": "main",  // or "ralph/previous-phase" for cascading
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "npm run typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Story Size: The #1 Rule

**Each story must be completable in ONE Ralph iteration (~one context window).**

Ralph spawns a fresh instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column + migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list
- Create a single component with props
- Wire up one API endpoint

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one story per endpoint or pattern
- "Build the full app" → Split into foundation, then feature-by-feature

**Rule of thumb:** If you can't describe the change in 2-3 sentences, it's too big.

---

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Project setup / scaffolding
2. Schema/database changes (migrations)
3. Server actions / backend logic
4. UI components that use the backend
5. Dashboard/summary views that aggregate data

**Wrong order:**
1. ❌ UI component (depends on schema that doesn't exist yet)
2. ❌ Schema change

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `investorType` column to investor table with default 'cold'"
- "Filter dropdown has options: All, Cold, Friend"
- "Clicking toggle shows confirmation dialog"
- "npm run typecheck passes"
- "npm run build succeeds without errors"
- "npm test passes"
- "Component renders at localhost:3005"

### Bad criteria (vague):
- ❌ "Works correctly"
- ❌ "User can do X easily"
- ❌ "Good UX"
- ❌ "Handles edge cases"

### Always include as final criterion:
```
"npm run typecheck passes"
```

For setup stories, also include:
```
"npm run build succeeds without errors"
```

For stories with testable logic, also include:
```
"npm test passes"
```

### For stories that change UI, also include:
```
"Verify component renders correctly in browser"
```

Frontend stories are NOT complete until visually verified.

---

## Branching Modes

Ralph supports two branching strategies:

### 1. Named Branch (default)
```json
"branchName": "ralph/feature-name"
```
- Ralph creates/checks out this branch
- Standard for isolated feature work
- Use when: starting fresh feature, want clean history

### 2. Work-in-Place Mode
```json
"branchName": null
```
- Ralph stays on current branch
- No branch switching or creation
- Use when: already on correct branch, adding to existing work, avoiding branch sprawl

**Tip:** Use `/ralph-cleanup` to manage accumulated ralph/* branches.

### 3. Cascading Branch Mode (for phased work)
```json
"branchName": "ralph/phase-2-feature",
"baseBranch": "ralph/phase-1-foundation"
```
- Ralph branches FROM the specified baseBranch (not main)
- Use when: multi-phase features, PRs shouldn't merge to main yet
- Creates stacked PRs: phase-2 → phase-1 → main

**Detection:** Before creating prd.json, check for existing ralph/* branches:
```bash
git branch -a | grep 'ralph/' | head -5
```

**When to use cascading:**
- User mentions "phase", "part 2", "next phase", "building on previous"
- Existing ralph/* branch has open PR not yet merged
- User explicitly wants to avoid merging to main/production

**Ask user if unclear:**
> "I see `ralph/phase-1-xxx` exists. Should this new work cascade from it (PR → phase-1) or branch from main independently?"

---

## Conversion Rules

1. **Each user story → one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name (prefixed with `ralph/`) OR set to `null` for work-in-place
6. **baseBranch**: Default to `"main"`, or set to existing ralph/* branch for cascading
7. **Always add**: "npm run typecheck passes" to every story's acceptance criteria

---

## Splitting Large PRDs

If a PRD has big features, split them:

**Original:**
> "Build a daily quote app with journaling"

**Split into:**
1. US-001: Initialize Next.js project with TypeScript and Tailwind
2. US-002: Configure PWA (manifest, service worker)
3. US-003: Set up typography and base styles
4. US-004: Create IndexedDB schema and wrapper
5. US-005: Create Quote type and seed data
6. US-006: Build Quote display component
7. US-007: Build Onboarding flow component
8. US-008: Wire up main page with quote display
... etc

Each is one focused change that can be completed and verified independently.

---

## Example

**Input PRD:**
```markdown
# Friends Outreach

Add ability to mark investors as "friends" for warm outreach.

## Requirements
- Toggle between cold/friend on investor list
- Friends get shorter follow-up sequence (3 instead of 5)
- Different message template asking for deck feedback
- Filter list by type
```

**Output prd.json:**
```json
{
  "project": "Untangle",
  "branchName": "ralph/friends-outreach",
  "baseBranch": "main",
  "description": "Friends Outreach Track - Warm outreach for deck feedback",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add investorType field to investor table",
      "description": "As a developer, I need to categorize investors as 'cold' or 'friend'.",
      "acceptanceCriteria": [
        "Add investorType column: 'cold' | 'friend' (default 'cold')",
        "Generate and run migration successfully",
        "npm run typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Add type toggle to investor list rows",
      "description": "As Ryan, I want to toggle investor type directly from the list.",
      "acceptanceCriteria": [
        "Each row has Cold | Friend toggle",
        "Switching shows confirmation: 'Delete tasks and regenerate?'",
        "On confirm: updates type, deletes tasks, regenerates",
        "npm run typecheck passes",
        "Verify component renders correctly in browser"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Create friend-specific phase progression",
      "description": "As a developer, friends should use 3 follow-ups instead of 5.",
      "acceptanceCriteria": [
        "Friends: initial → followup_1 → followup_2 → followup_3 → final",
        "Cold: keeps all 5 follow-ups",
        "getNextPhase respects investorType",
        "npm run typecheck passes"
      ],
      "priority": 3,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Create friend message templates",
      "description": "As Ryan, friends should get deck feedback request, not cold pitch.",
      "acceptanceCriteria": [
        "Initial message asks for deck feedback with link and password",
        "4 channel variations with same meaning, slight phrasing differences",
        "Follow-ups are gentle nudges",
        "npm run typecheck passes"
      ],
      "priority": 4,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-005",
      "title": "Filter investors by type",
      "description": "As Ryan, I want to filter the list to see just friends or cold.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Cold | Friend",
        "Filter persists in URL params",
        "npm run typecheck passes",
        "Verify component renders correctly in browser"
      ],
      "priority": 5,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Output Location

**Normal mode:** `scripts/ralph/prd.json`

**Queued mode:** `scripts/ralph/prd.queued-{n}.json`
- Find next available number: `ls scripts/ralph/prd.queued-*.json 2>/dev/null | wc -l` + 1
- Example: prd.queued-1.json, prd.queued-2.json, etc.

---

# Section C: CONVERT ISSUES TO prd.json

When given GitHub issue numbers (from ralph-my-notes or directly), fetch and convert them.

## Step 1: Fetch Issue Details

```bash
# Fetch each issue
gh issue view 123 --json title,body,labels
gh issue view 124 --json title,body,labels
# ... etc
```

## Step 2: Convert to User Stories

For each issue:
- **title** → story title
- **body** → story description + acceptance criteria
- **labels** → hints for ordering (bug vs feature, frontend vs backend)

Apply all the same rules from Section B:
- Right-size stories (split if too big)
- Order by dependencies
- Add "npm run typecheck passes" to all criteria
- Add visual verification for UI stories

## Step 3: Generate prd.json

Use the same format as Section B. Derive branchName from the batch context.

## Step 4: Run Ralph

After creating prd.json, immediately run Ralph (Section A behavior).

**Full auto. No confirmations.**

---

---

# Section D: QUEUED MODE

When context indicates "PRD in use" or "create as queued" (typically from ralph-my-notes detecting contention):

## Step 1: Determine Queue Number

```bash
# Count existing queued files, add 1
next_num=$(($(ls scripts/ralph/prd.queued-*.json 2>/dev/null | wc -l) + 1))
echo "prd.queued-${next_num}.json"
```

## Step 2: Create Queued PRD

Follow Section B (PRD) or Section C (issues) conversion rules, but write to:
`scripts/ralph/prd.queued-{n}.json`

## Step 3: DO NOT Run Ralph

Queued PRDs wait for manual promotion. Report:
```
Created prd.queued-{n}.json with [N] stories.
Current prd.json still active - this PRD is queued for later.

To promote when ready:
  mv scripts/ralph/prd.queued-{n}.json scripts/ralph/prd.json
  Then: /ralph
```

## Listing Queued PRDs

```bash
ls -la scripts/ralph/prd.queued-*.json 2>/dev/null
```

---

## Checklist Before Saving

Before writing prd.json (or prd.queued-{n}.json), verify:

- [ ] Each story is completable in one iteration (small enough)
- [ ] Stories are ordered by dependency (setup → schema → backend → UI)
- [ ] Every story has "npm run typecheck passes" as criterion
- [ ] UI stories have visual verification as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Project scaffolding/setup comes first
