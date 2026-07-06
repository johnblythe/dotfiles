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

## Step 4.5: Rebase onto main + CHANGELOG

**Before touching CHANGELOG, always rebase onto main.** This prevents cascading merge conflicts when deploying multiple worktree PRs sequentially.

```bash
git fetch origin main --quiet
git rebase origin/main
```

If rebase has conflicts, resolve them, then `git rebase --continue`.

**Then** update CHANGELOG.md:
1. Add entries under `## [Unreleased]` in the appropriate section (Added/Changed/Fixed)
2. Include GitHub issue numbers
3. Commit: `git add CHANGELOG.md && git commit -m "Update CHANGELOG"`

This ordering (rebase → CHANGELOG → push) guarantees each CHANGELOG edit starts from the latest version of main.

## Step 5: Create PR

If no PR exists yet for this branch:

1. Extract issue number(s) from branch name (e.g., `feature/foo-123` → `#123`)
2. Push branch and create PR using `--body-file tmp/gh-body.md` (write body with Write tool first)

If PR already exists, push the review-fix and compound commits.

## Step 6: Monitor Vercel build

Start `gh pr checks --watch` in the background, then use the Monitor tool to stream its output. This replaces sleep-based polling — do NOT use `sleep` or a loop.

```bash
gh pr checks --watch
```

Run with `run_in_background: true`, then call Monitor on the returned task ID. Monitor fires on each stdout line and completes when the command exits (i.e., all checks reach a terminal state).

Parse Monitor output to determine outcome:
- Any line containing `fail` or `FAIL` → build failed
- All checks show `pass` / `PASS` → build passed
- If no Vercel-specific check appears → fall back: `gh pr checks` (single snapshot)

### If build FAILED:
- Fetch build logs: `gh pr checks --json name,state,link`
- Show error summary
- STOP — do not merge. Say: "Build failed. Fix and run `/deploy` again."

### If build PASSED:
- Continue to merge.

## Step 7: Merge

First, detect if you're in a worktree:

```bash
GIT_DIR=$(git rev-parse --git-dir)
GIT_COMMON=$(git rev-parse --git-common-dir)
# If these differ, you're in a worktree
```

**If in a worktree** — `gh pr merge` will fail because it tries to checkout main locally, but main is already checked out in the primary repo. Use the GitHub API directly:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/merge -f merge_method=squash
# Then delete the remote branch:
gh api repos/{owner}/{repo}/git/refs/heads/{branch_name} -X DELETE
```

**If NOT in a worktree** — use the standard command:

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
2. If in worktree, use the `ExitWorktree` tool to leave and clean up. This is the correct way — do NOT try to `cd` out and `git worktree remove` manually from inside the worktree.
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

---

**Context reset check** — after the summary, always prompt:

> "Deploy complete. This is a good point to `/clear` context before starting the next task — especially if this session has been running a while or covered multiple topics. Want to clear now?"

Do not skip this prompt. It's the natural checkpoint.
