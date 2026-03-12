# Idea Changelog

Generate a sprint-by-sprint changelog for a PDCR Idea, suitable for stakeholder updates.

## Usage

```
/idea-changelog PDCR-XXX
```

Or with sprint range:
```
/idea-changelog PDCR-294 --from Q4.S4 --to Q1.S0
```

## What It Produces

A reverse-chronological list of what shipped, what's in progress, and what's coming - organized by sprint for easy stakeholder consumption.

## Workflow

### 1. Get Initiative Tickets
```bash
source scripts/jira-lib.sh

# Get all tickets by label
acli jira workitem search --jql 'labels = "roi-platform"' \
  --fields "key,summary,status,customfield_10020,resolution,resolutiondate" --csv
```

### 2. Get Sprint History
```bash
# List recent sprints
acli jira board list-sprints --id 389 --state closed --limit 10 --csv
acli jira board list-sprints --id 389 --state active --csv
```

### 3. Group Tickets by Sprint Completion
For each ticket marked Done, check which sprint it was completed in:
```bash
# Get issue changelog to find sprint completion
curl -s -X GET -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/ROIP-XXX?expand=changelog&fields=status,customfield_10020"
```

### 4. Generate Changelog

## Output Template

```markdown
# [Initiative Name] - Changelog

**PDCR:** [PDCR-XXX](link)
**Label:** `label-name`

---

## Q1.S0 (Current Sprint)

### In Progress
- **ROIP-414**: Deploy & Validate Audit Log Migration in Remote Environment
- **ROIP-408**: Create centralized workers for logging operations

### In Review
- **ROIP-403**: Backfill: Backup + Script + Checksum Validation
- **ROIP-397**: FDW Setup Script (local → audit) + Schema Sync

### Blocked
- **ROIP-401**: FDW Query Path Wiring & Validation *(needs: TBD)*

---

## Q4.S6 (Completed: 2026-01-03)

### Shipped :rocket:
- **ROIP-412**: Discovery on backfill options
- **ROIP-404**: Backfill Progress & Verification Report
- **ROIP-398**: README: Local Dual-DB Spin-Up & Common Tasks

### Carried Over
- ROIP-414, ROIP-408 (continued into Q1.S0)

---

## Q4.S5 (Completed: 2025-12-20)

### Shipped :rocket:
- **ROIP-396**: Docker: Dual-Postgres Compose + Seed Data
- **ROIP-370**: Add transactional dual-write logic
- **ROIP-369**: Implement feature-flag scaffolding

---

## Q4.S4 (Completed: 2025-12-06)

### Shipped :rocket:
- **ROIP-384**: Code & Datadog Discovery
- **ROIP-383**: Enable Query Logging for Audit Tables
- **ROIP-368**: Provision new DBs

---

## Summary

| Sprint | Shipped | Carried | Blocked |
|--------|---------|---------|---------|
| Q1.S0 | - | 4 | 1 |
| Q4.S6 | 3 | 2 | 0 |
| Q4.S5 | 3 | 0 | 0 |
| Q4.S4 | 3 | 0 | 0 |

**Total Shipped:** 9 tickets
**Velocity:** ~3 tickets/sprint

---

*Generated: YYYY-MM-DD*
```

## Slack-Friendly Version

For posting to Slack, use condensed format:

```
*[Initiative] Q1.S0 Update*

:rocket: *Shipped this sprint:*
• ROIP-412: Discovery on backfill options
• ROIP-404: Backfill Progress & Verification Report

:arrows_counterclockwise: *In flight:*
• ROIP-414: Deploy & Validate (In Progress)
• ROIP-403: Backfill Script (Code Review)

:x: *Blocked:*
• ROIP-401: FDW Query Path (needs unblock)

_Next sprint focus: Complete backfill, unblock read-path migration_
```

## Tips

- Run at end of sprint for stakeholder updates
- Include "Carried Over" to show continuity
- Highlight blockers prominently
- Keep Slack version to 5-7 items max
- Link to full Confluence page for details

## Related Skills

- `/idea-overview` - Deep dive on initiative structure
- `/idea-pulse` - Weekly movement/activity tracking
