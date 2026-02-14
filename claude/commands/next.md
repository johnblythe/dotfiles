---
description: Check open GitHub issues and display what to work on next
---

Read the local `.issues.json` file in the project root. This is the local-first issue cache.

**Schema:**
```json
{
  "issues": [
    {
      "id": "string",           // "local-{n}" or GH issue number as string
      "number": number|null,    // GH issue number, null if local-only
      "title": "string",
      "labels": ["string"],     // predefined: bug/feature/chore, or custom
      "status": "open|in_progress|closed",
      "priority": "high|med|low",
      "needsSync": boolean,     // true if local changes need pushing to GH
      "localOnly": boolean,     // true if not yet on GH
      "createdAt": "ISO date",
      "updatedAt": "ISO date"
    }
  ],
  "lastSyncedAt": "ISO date"|null
}
```

**Display format:**
Group by priority (high → med → low), then show:

```
## HIGH
- [#123] Fix auth bug (bug, feature) - in_progress
- [local-1] Add dark mode (feature) ⚡ needs sync

## MED
- [#124] Refactor utils (chore)

## LOW
- [#125] Update docs (chore)

---
Last synced: 2 hours ago (or "never" if null)
```

Mark items needing sync with ⚡. Mark local-only with 🆕.

Then ask which issue to work on, or if I want to:
- Log a new issue (`/log-issue`)
- Sync with GitHub (`/sync-issues`)
- Work on something else
