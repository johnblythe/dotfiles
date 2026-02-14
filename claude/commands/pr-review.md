---
description: Fetch PR feedback and convert to actionable todos
---

Fetch PR review feedback and create actionable todos:

1. Get PR number from argument or detect from current branch:
   ```bash
   gh pr list --head $(git branch --show-current) --json number --jq '.[0].number'
   ```

2. Fetch PR details with comments and reviews:
   ```bash
   gh pr view <number> --json title,body,comments,reviews
   ```

3. Parse and display all feedback items:
   - PR description suggestions
   - Inline code review comments
   - General review comments
   - Requested changes

4. Use AskUserQuestion to present feedback items with multiSelect: true
   - Each option should be a concise summary of the feedback
   - User selects which items they want to address

5. For selected items, create TodoWrite entries with:
   - content: Brief description of what to fix
   - activeForm: Present continuous form
   - status: "pending"

6. Display the created todos so user sees the plan

## Example Usage
```
/pr-review          # Uses current branch's PR
/pr-review 29       # Uses PR #29
```

## Notes
- Group similar feedback items when possible
- Make todo descriptions actionable and specific
- Include file/line references when available
- If no feedback, inform user PR looks good
