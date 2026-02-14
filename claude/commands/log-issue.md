---
description: Log a new issue to local cache and GitHub
---

Create a new issue in both `.issues.json` (local) and GitHub.

**Arguments:** $ARGUMENTS (the issue title/description)

**Steps:**

1. Parse the input. If just a title, prompt for:
   - Labels (bug/feature/chore or custom, comma-separated)
   - Priority (high/med/low, default: med)
   - Body/description (optional, can skip)

2. Create on GitHub first using:
   ```bash
   gh issue create --title "TITLE" --body "BODY" --label "LABELS"
   ```
   Capture the issue number from output.

3. Add to `.issues.json`:
   ```json
   {
     "id": "NUMBER",
     "number": NUMBER,
     "title": "TITLE",
     "labels": ["LABELS"],
     "status": "open",
     "priority": "PRIORITY",
     "needsSync": false,
     "localOnly": false,
     "createdAt": "NOW",
     "updatedAt": "NOW"
   }
   ```

4. Confirm: "Created issue #NUMBER: TITLE"

**Quick mode:** If I say `/log-issue fix the auth bug -bug -high`, parse inline flags:
- `-bug`, `-feature`, `-chore` → labels
- `-high`, `-med`, `-low` → priority
- Everything else → title

**Local-only mode:** If GitHub is unavailable or I say `--local`:
- Generate id as `local-{nextLocalId}`
- Set `number: null`, `localOnly: true`, `needsSync: true`
- Remind to sync later
