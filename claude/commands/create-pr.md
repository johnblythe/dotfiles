---
description: Create a pull request from current branch
---

Create a pull request for the current branch:

1. Check current branch name with `git branch --show-current`
2. Determine base branch (main or master) with `git remote show origin | grep 'HEAD branch'`
3. Extract issue number(s) from branch name (e.g., `feature/foo-123` → `123`, `feature/bar-45-67` → `45, 67`)
4. Run `git log <base>..HEAD --oneline` to see commits being PRed
5. Run `git diff <base>...HEAD --stat` to see file changes summary
6. Generate PR title from most recent commit or summarize all commits
7. Generate PR body with HEREDOC format:
   - **Summary** section: bullet points of key changes from commits
   - **Closes** section: `Closes #X` for each issue number found in branch name
   - **Test plan** section: markdown checklist of what to test
8. Write PR body to temp file, then create PR:
   ```bash
   cat <<'EOF' > /tmp/gh-body.md
   ## Summary
   - Key change 1
   - Key change 2

   Closes #123

   ## Test plan
   - [ ] Test item 1
   - [ ] Test item 2
   EOF
   gh pr create --title "PR title here" --body-file /tmp/gh-body.md --base <base-branch>
   ```
   **NEVER use `$()` command substitution** — always use `--body-file` to avoid permission prompts.
9. Display the PR URL returned

## Important Notes
- Do NOT push if branch isn't pushed yet - let gh CLI handle it
- Keep PR title concise (< 72 chars)
- Summary should highlight user-facing changes
- Test plan should be actionable checklist items
- ALWAYS include `Closes #X` for issue numbers found in branch name (auto-closes issues on merge)
