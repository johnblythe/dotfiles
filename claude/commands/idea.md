---
description: Explore and develop ideas from the ideas repo
---

# Idea Management

Work with ideas captured via `idea "foo"` shell command.

## Usage

```
/idea              # List recent ideas
/idea explore <num> # Deep dive on an idea
/idea triage       # Review, label, close stale
/idea move <num> <repo>  # Promote to project repo
```

---

## `/idea` or `/idea list`

Show recent ideas from `johnblythe/ideas`.

```bash
gh issue list -R johnblythe/ideas --limit 20 --json number,title,createdAt,labels
```

**Display:**
```
Recent Ideas:
#42  Add voice memo transcription (2 days ago)
#41  CLI tool for expense tracking (3 days ago)  [explored]
#40  Dark mode for cooking app (1 week ago)  [promoted]
...
```

---

## `/idea explore <num>`

Deep dive on an idea. Research, expand, make concrete.

**Steps:**

1. Fetch the idea:
   ```bash
   gh issue view <num> -R johnblythe/ideas --json title,body
   ```

2. **Research phase** - Use web search and codebase knowledge to explore:
   - What problem does this solve?
   - Who has solved this before? (competitors, OSS)
   - What technologies/approaches exist?
   - Is this a feature for an existing project or new?

3. **Expansion** - Generate structured details:
   ```markdown
   ## Problem
   What pain point or opportunity does this address?

   ## Prior Art
   - [Competitor/tool] - how they do it
   - [OSS project] - relevant implementation

   ## Approach Options
   1. **Option A** - description, tradeoffs
   2. **Option B** - description, tradeoffs

   ## MVP Scope
   - Core feature 1
   - Core feature 2
   - Explicitly NOT: [out of scope items]

   ## Open Questions
   - Question 1?
   - Question 2?
   ```

4. **Update the issue** with exploration:
   ```bash
   gh issue edit <num> -R johnblythe/ideas --body "EXPANDED_BODY"
   ```

5. **Add label:**
   ```bash
   gh issue edit <num> -R johnblythe/ideas --add-label "explored"
   ```

6. **Ask next step:**
   - Explore further?
   - Promote to a project?
   - Shelve for later?

---

## `/idea triage`

Review all open ideas, clean up stale ones.

**Steps:**

1. Fetch all open ideas:
   ```bash
   gh issue list -R johnblythe/ideas --state open --json number,title,createdAt,labels,body
   ```

2. Group by age:
   - **Fresh** (< 1 week)
   - **Aging** (1-4 weeks)
   - **Stale** (> 1 month)

3. For each idea, use AskUserQuestion with options:
   - **Keep** - still interested
   - **Explore** - run `/idea explore`
   - **Close** - not pursuing
   - **Skip** - decide later

4. Apply labels based on theme (auto-suggest):
   - `app:cooking`, `app:travel`, `tool:cli`, `tool:web`
   - `effort:small`, `effort:medium`, `effort:large`

5. Close dismissed ideas:
   ```bash
   gh issue close <num> -R johnblythe/ideas --comment "Triaged: not pursuing"
   ```

6. **Summary:**
   ```
   Triage complete:
   - Kept: 5 ideas
   - Explored: 2 ideas
   - Closed: 3 ideas
   ```

---

## `/idea move <num> <repo>`

Promote an idea to a project repo as a full issue.

**Arguments:**
- `<num>` - idea issue number
- `<repo>` - target repo (e.g., `travel`, `cooking`, `johnblythe/newproject`)

**Steps:**

1. Fetch the idea:
   ```bash
   gh issue view <num> -R johnblythe/ideas --json title,body,labels
   ```

2. Resolve target repo:
   - If short name like `travel`, expand to `johnblythe/travel`
   - Verify repo exists: `gh repo view <repo>`

3. Create issue in target repo:
   ```bash
   gh issue create -R <repo> --title "TITLE" --body "BODY"
   ```

4. Update original idea:
   ```bash
   gh issue close <num> -R johnblythe/ideas --comment "Promoted to <repo>#<new_num>"
   gh issue edit <num> -R johnblythe/ideas --add-label "promoted"
   ```

5. **Confirm:**
   ```
   Moved idea #42 → johnblythe/travel#15
   Original idea closed and labeled "promoted"
   ```

6. **Offer to start work:**
   - Run `/branch-start <new_num>` on target repo?
