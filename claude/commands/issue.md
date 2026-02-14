---
description: Manage GitHub issues - list, log, close, sync
---

# Issue Management

Unified command for issue tracking with local `.issues.json` cache.

## Usage

```
/issue              # List open issues (default)
/issue list         # Same as above
/issue log <title>  # Create new issue
/issue close <num>  # Close an issue
/issue sync         # Sync with GitHub + archive plans
```

---

## `/issue` or `/issue list`

Show prioritized open issues from `.issues.json`.

**Display format:**
```
## HIGH
- [#123] Fix auth bug (bug) - in_progress
- [local-1] Add dark mode (feature) ⚡ needs sync

## MED
- [#124] Refactor utils (chore)

## LOW
- [#125] Update docs (chore)

---
Last synced: 2 hours ago
```

Markers: ⚡ = needs sync, 🆕 = local-only

---

## `/issue log <title>`

Create issue on GitHub + local cache.

**Quick mode with flags:**
```
/issue log fix the auth bug -bug -high
```

Flags:
- `-bug`, `-feature`, `-chore` → labels
- `-high`, `-med`, `-low` → priority

**Steps:**
1. Parse title and flags
2. Create on GitHub: `gh issue create --title "TITLE" --label "LABELS"`
3. Add to `.issues.json` with `needsSync: false`
4. Confirm: "Created #NUMBER: TITLE"

**Local-only mode:** If `--local` flag or GitHub unavailable:
- Generate `id: "local-{n}"`
- Set `localOnly: true`, `needsSync: true`

---

## `/issue close <num>`

Close issue locally and on GitHub.

**Arguments:** Issue number (`123`, `#123`) or local ID (`local-1`)

**Steps:**
1. Find in `.issues.json`
2. If has GH number: `gh issue close NUMBER`
3. Update local: `status: "closed"`
4. Confirm: "Closed #NUMBER: TITLE"

**With comment:**
```
/issue close 123 --comment "Fixed in PR #456"
```

---

## `/issue sync`

Bidirectional sync between `.issues.json` and GitHub.

**Steps:**

1. **Pull from GitHub:**
   ```bash
   gh issue list --state all --json number,title,labels,state --limit 100
   ```
   Add new GH issues to local cache.

2. **Push local-only issues:**
   For `localOnly: true` issues, create on GitHub and update local with number.

3. **Sync status changes:**
   - Local closed → `gh issue close NUMBER`
   - Local reopened → `gh issue reopen NUMBER`
   - GH closed → update local status

4. **Archive completed plans:**
   If `plans/` exists, archive plans linked to closed issues:
   - Check filename pattern: `123-*.md`
   - Check frontmatter: `Issue: #123`
   - Move to `plans/archived/`
   - Prompt for orphan plans (no issue link)

5. **Report:**
   ```
   Sync complete:
   - Pulled: 3 new from GH
   - Pushed: 1 local to GH
   - Archived: 2 plans
   Last synced: just now
   ```

6. **Show `/issue list`** output

---

## Schema: `.issues.json`

```json
{
  "issues": [
    {
      "id": "string",
      "number": 123,
      "title": "string",
      "labels": ["bug"],
      "status": "open|in_progress|closed",
      "priority": "high|med|low",
      "needsSync": false,
      "localOnly": false,
      "createdAt": "ISO",
      "updatedAt": "ISO"
    }
  ],
  "lastSyncedAt": "ISO"
}
```
