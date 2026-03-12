# Documentation

Docs are **communication frozen in time**—the COLD layer.

Rule of thumb: If you explained it twice, write it down.

---

## Doc Types

| Type | When | Key |
|------|------|-----|
| ADR | Architectural decision with trade-offs | Context → Decision → Consequences |
| Tech Spec | Before building, updated after shipping | Must reflect reality, not aspirations |
| Runbook | Operational procedure to be repeated | Tested by someone other than author |
| README | Every repo | First thing new person reads |

---

## Lifecycle

```
Draft → Review → Published → Maintained → Archived
                     ↑______________|
```

Most docs die at "Published but not Maintained."

If stale, mark stale. If unowned, archive. If active, schedule reviews.

---

## Writing

1. Lead with the point
2. Headers liberally—scannable > readable
3. Code examples > prose
4. Link, don't duplicate
5. Date it, own it

---

## Where Docs Live

| Type | Location |
|------|----------|
| Code-adjacent | In repo |
| Project docs | [TODO] |
| Runbooks | [TODO] |
| Meeting notes | [TODO] |

Pick canonical homes. Scattered docs = dead docs.

---

## Fail Modes

| Mode | Symptom | Fix |
|------|---------|-----|
| Write-only | Confluence graveyard | Regular review cadence, clear owners |
| Spec drift | Doc doesn't match system | Update when shipping |
| Novel-length | 50 pages no one reads | Executive summary + details for those who need |
| Tribal knowledge | "Ask Steve" | Steve writes it down |
| Orphan docs | Everyone's responsibility = no one's | Explicit owner per doc |
| Scattered | Docs in 5 systems | Canonical homes, redirect everything else |
| Stale runbook | Steps don't work | Test after incidents, update immediately |
