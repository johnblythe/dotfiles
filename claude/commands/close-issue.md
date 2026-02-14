---
description: Close an issue locally and on GitHub
---

Close an issue in both `.issues.json` and GitHub.

**Arguments:** $ARGUMENTS (issue number or local-id)

**Steps:**

1. **Find the issue** in `.issues.json` by:
   - `number` (e.g., `123` or `#123`)
   - `id` (e.g., `local-1`)

2. **If has GH number:**
   ```bash
   gh issue close NUMBER
   ```
   Update local: `status: "closed"`, `needsSync: false`

3. **If local-only:**
   Update local: `status: "closed"`, `needsSync: true`
   Note: "Closed locally. Run /sync-issues to push to GH when created."

4. **Update timestamp:** Set `updatedAt` to now.

5. **Confirm:** "Closed #NUMBER: TITLE"

**Bonus - close with comment:**
If I say `/close-issue 123 --comment "Fixed in PR #456"`:
```bash
gh issue close NUMBER --comment "COMMENT"
```

**Reopen:** If status is already closed and I run this, ask if I want to reopen instead.
