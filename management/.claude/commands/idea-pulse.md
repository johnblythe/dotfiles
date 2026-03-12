# Idea Pulse

Generate a weekly status update for a PDCR Idea showing movement, activity, blockers, and progress.

## Usage

```
/idea-pulse PDCR-XXX
```

Or by label:
```
/idea-pulse roi-platform
```

Or with date range:
```
/idea-pulse PDCR-294 --since 2026-01-01
```

## What It Tracks

### Movement
- Tickets that changed status this week
- New tickets added
- Tickets completed (moved to Done)
- Blockers added vs resolved

### Activity
- Tickets with most comments (hot topics)
- Recently updated tickets
- Assignee changes

### Health
- Blockers count trend
- In-flight vs To Do ratio
- Completion rate (points done / total points)

## Workflow

### 1. Load Previous Snapshot (if exists)
Check `context/pdcr-XXX-pulse-YYYY-MM-DD.json` for last week's state.

### 2. Get Current State
```bash
# Get all tickets for the initiative
acli jira workitem search --jql '"Epic Link" in (ROIP-XXX, ROIP-YYY) OR key in (ROIP-XXX, ROIP-YYY)' \
  --fields "key,summary,status,assignee,updated,created" --csv
```

### 3. Get Recent Activity
```bash
source scripts/jira-lib.sh

# Tickets updated in last 7 days
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/search/jql" \
  -d '{
    "jql": "labels = \"roi-platform\" AND updated >= -7d ORDER BY updated DESC",
    "fields": ["key", "summary", "status", "updated", "comment"],
    "maxResults": 100
  }'
```

### 4. Get Comment Activity
```bash
# For each hot ticket, get recent comments
curl -s -X GET -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/ROIP-XXX/comment?orderBy=-created&maxResults=5"
```

### 5. Get Status Transitions
```bash
# Check changelog for status changes
curl -s -X GET -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/ROIP-XXX?expand=changelog&fields=status"
```

### 6. Compare to Previous Week
- Diff status counts
- Identify new blockers
- Calculate velocity (points completed)

### 7. Generate Pulse Report

## Output Template

```markdown
# [Initiative Name] - Weekly Pulse

**Period:** YYYY-MM-DD to YYYY-MM-DD
**PDCR:** [PDCR-XXX](link)

---

## TL;DR

[2-3 sentence summary: what progressed, what's blocked, overall health]

---

## Movement This Week

### Completed :white_check_mark:
| Key | Summary | Points |
|-----|---------|--------|
| ROIP-XXX | Title | 2 |

**Total:** X tickets, Y points

### Started :arrow_forward:
| Key | Summary | Assignee |
|-----|---------|----------|
| ROIP-XXX | Title | Name |

### Newly Blocked :x:
| Key | Summary | Blocker Reason |
|-----|---------|----------------|
| ROIP-XXX | Title | Reason |

### Unblocked :tada:
| Key | Summary |
|-----|---------|
| ROIP-XXX | Title |

---

## Hot Tickets :fire:

Tickets with most activity (comments, updates) this week:

| Key | Summary | Comments | Last Update |
|-----|---------|----------|-------------|
| ROIP-XXX | Title | 5 new | 2h ago |

---

## Health Snapshot

| Metric | Last Week | This Week | Trend |
|--------|-----------|-----------|-------|
| Done | X | Y | +Z |
| In Flight | X | Y | = |
| To Do | X | Y | -Z |
| Blocked | X | Y | :warning: +Z |
| Completion % | XX% | YY% | +Z% |

### Blockers
| Key | Summary | Days Blocked | Owner |
|-----|---------|--------------|-------|
| ROIP-XXX | Title | 5 | Name |

---

## Next Week Focus

Based on current state, recommended focus:
1. [Unblock ROIP-XXX - critical path]
2. [Complete code reviews: ROIP-YYY, ROIP-ZZZ]
3. [Start ROIP-AAA to maintain velocity]

---

*Generated: YYYY-MM-DD HH:MM*
```

## Snapshot Storage

Save weekly snapshots for trend tracking:

```
context/
├── pdcr-294-db-scaling.md           # Static overview
├── pdcr-294-pulse-2026-01-06.json   # Weekly snapshot
├── pdcr-294-pulse-2026-01-13.json
└── pdcr-294-pulse-latest.md         # Most recent pulse report
```

### Snapshot JSON Format
```json
{
  "date": "2026-01-06",
  "pdcr": "PDCR-294",
  "label": "roi-platform",
  "epics": ["ROIP-372", "ROIP-382", ...],
  "tickets": {
    "ROIP-368": {"status": "Done", "points": 2, "assignee": "..."},
    "ROIP-371": {"status": "To Do", "points": 1, "assignee": "..."}
  },
  "counts": {
    "done": 9,
    "in_flight": 4,
    "to_do": 4,
    "blocked": 1
  },
  "points": {
    "done": 18,
    "total": 40
  }
}
```

## Automation Ideas

- Run weekly via cron/scheduled task
- Post to Slack channel
- Generate for multiple initiatives at once
- Track velocity trends over time

## JQL Patterns

```bash
# Updated this week
'labels = "roi-platform" AND updated >= -7d'

# Status changed this week
'labels = "roi-platform" AND status changed AFTER -7d'

# Became blocked this week
'labels = "roi-platform" AND status changed TO Blocked AFTER -7d'

# Completed this week
'labels = "roi-platform" AND status changed TO Done AFTER -7d'

# New tickets this week
'labels = "roi-platform" AND created >= -7d'

# Stale (no update in 14+ days while in progress)
'labels = "roi-platform" AND status = "In Progress" AND updated < -14d'
```

## Tips

- Run on same day each week for consistent comparison
- Flag tickets blocked >5 days as critical
- Highlight assignee changes (may indicate handoff issues)
- Watch for "hot" tickets - lots of comments often means contention or complexity
- Track points velocity, not just ticket counts
