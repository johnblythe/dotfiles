---
description: Sync local issues with GitHub (bidirectional)
---

Perform bidirectional sync between `.issues.json` and GitHub issues.

**Steps:**

1. **Fetch from GitHub:**
   ```bash
   gh issue list --state all --json number,title,labels,state,url --limit 100
   ```

2. **Pull new GH issues → local:**
   For each GH issue not in local:
   - Add with `localOnly: false`, `needsSync: false`
   - Default priority: `med`
   - Map GH `state` to local `status` (open/closed)

3. **Push local-only issues → GH:**
   For each issue where `localOnly: true`:
   ```bash
   gh issue create --title "TITLE" --label "LABELS"
   ```
   - Update local: set `number`, `localOnly: false`, `needsSync: false`

4. **Sync status changes:**
   For issues where `needsSync: true`:
   - If local status changed to `closed`:
     ```bash
     gh issue close NUMBER
     ```
   - If local status changed to `open`:
     ```bash
     gh issue reopen NUMBER
     ```
   - Clear `needsSync` flag

5. **Reconcile closed on GH:**
   For GH issues marked closed but local shows open:
   - Update local status to `closed`

6. **Update timestamp:**
   Set `lastSyncedAt` to current ISO timestamp.

7. **Report sync results:**
   ```
   Sync complete:
   - Pulled: 3 new issues from GH
   - Pushed: 1 local issue to GH
   - Status synced: 2 issues
   - Last synced: just now
   ```

8. **Archive completed plans:**
   If `plans/` directory exists, run `/archive-plans` logic:
   - Scan plans for linked issues (filename `123-*.md` or frontmatter `Issue: #123`)
   - Archive plans whose linked issues are now closed
   - Prompt for orphan plans (no issue link)
   - Report archive results

9. **Tee up /next:**
   After sync and archive complete, display the `/next` output showing prioritized open issues and prompt for what to work on.

**Conflict handling:**
If same issue edited both places, prefer GH as source of truth for title/labels, local for status/priority.
