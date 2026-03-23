---
description: Review PR feedback, resolve items, compound learnings, create PR, monitor build, merge, clean up
---

# Deploy

End-to-end ship sequence: review → resolve → compound → PR → build check → merge → cleanup → summary.

## Step 1: Pre-flight

```bash
git branch --show-current
git status --porcelain
git fetch origin main --quiet 2>&1 && git log HEAD..origin/main --oneline
```

- Uncommitted changes → STOP, ask to commit first.
- Behind main → warn, let user decide.
- On main/master → STOP, must be on feature branch.

## Step 2: PR Review

Run the `/pr-review-toolkit:review-pr` skill to get reviewer feedback on the current branch's changes.

If an open PR already exists for this branch, review that. Otherwise review the diff against main.

## Step 3: Resolve ALL review items

Resolve every item the reviewers come back with. No skipping, no deferring.

- Fix each issue in the codebase
- Commit fixes (group logically — one commit for lint/style, one for logic fixes, etc.)
- If a review item is a false positive or doesn't apply, note why and move on

## Step 4: Compound Learnings

**MANDATORY. Do not skip. Do not defer to after merge.**

Run `/workflows:compound` to document any problems solved during this work. The output goes into `docs/solutions/` and must be committed into this branch so the learnings ship with the code.

After compound finishes:
1. Stage and commit the new docs: `git add docs/solutions/ && git commit -m "docs: compound learnings from this PR"`
2. Push the commit

This ensures learnings are in the repo, in the PR, reviewable, and deployed — not just local state.

## Step 5: Create PR

If no PR exists yet for this branch:

1. Extract issue number(s) from branch name (e.g., `feature/foo-123` → `#123`)
2. Push branch and create PR using `--body-file tmp/gh-body.md` (write body with Write tool first)

If PR already exists, push the review-fix and compound commits.

## Step 6: Monitor Vercel build

Poll the PR's check status until it resolves:

```bash
# Poll every 30s, up to 10 min
for i in $(seq 1 20); do
  STATUS=$(gh pr checks --json name,state --jq '[.[] | select(.name | test("Vercel"; "i"))] | .[0].state' 2>/dev/null)
  if [ "$STATUS" = "SUCCESS" ]; then echo "BUILD PASSED"; break; fi
  if [ "$STATUS" = "FAILURE" ]; then echo "BUILD FAILED"; break; fi
  sleep 30
done
```

If no Vercel-specific check found, fall back to checking all PR checks:
```bash
gh pr checks
```

### If build FAILED:
- Fetch build logs: `gh pr checks --json name,state,link`
- Show error summary
- STOP — do not merge. Say: "Build failed. Fix and run `/deploy` again."

### If build PASSED:
- Continue to merge.

## Step 7: Merge

```bash
gh pr merge --squash --delete-branch
```

Use `--squash` by default. If the branch has meaningful individual commits the user wants preserved, use `--merge` instead — but squash is the default.

## Step 8: Post-merge cleanup

### Close GitHub Issues
1. Extract issue number(s) from branch name
2. For each:
   ```bash
   gh issue close <number> --comment "Shipped via PR #<pr-number>"
   ```
3. No issue number in branch → skip silently.

### Worktree cleanup
1. Check if in worktree: compare `git rev-parse --git-common-dir` vs `--git-dir`
2. If in worktree:
   ```bash
   BRANCH=$(git branch --show-current)
   WORKTREE_PATH=$(pwd)
   cd "$(git rev-parse --git-common-dir)/.."
   git worktree remove "$WORKTREE_PATH" --force
   git branch -D "$BRANCH" 2>/dev/null
   ```
3. Not in worktree → skip.

## Step 9: Marketing Coverage Check

Run the `marketing-check` agent via the Task tool to audit whether recently shipped features are represented on the marketing site.

- Present the gap report to the user
- If gaps found, ask whether to address now or create GitHub issues for later
- If no gaps, note it in the summary and move on

This step is non-blocking — a failed or skipped marketing check should not prevent the deploy from completing.

## Step 10: Summary

**This is the LAST thing that happens. Nothing comes after this.**

```
Ship complete ✓
  PR: #<number> merged (squash)
  Build: passed
  Issue: #123 closed
  Branch: feature/foo-123 deleted
  Worktree: cleaned up
  Compound: docs/solutions/<path> committed
  Marketing: X gaps found (or "no gaps")
```

Omit lines that don't apply.
