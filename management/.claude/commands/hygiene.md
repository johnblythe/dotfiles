# Jira Hygiene Audit

Run comprehensive hygiene checks against active sprint and backlog. Flags style guide violations, stale items, and missing data.

## Usage
`/hygiene` or `/hygiene backlog`

## What to Check

### 1. Missing Story Points
Tickets in sprint without estimates.

```bash
acli jira workitem search --jql 'project = HEAL AND sprint in openSprints() AND "Story Points[Number]" is EMPTY AND issuetype in (Story, Task, Bug)' --fields "key,summary,assignee,status" --csv
```

### 2. Oversized Tickets (5+ points)
Per style guide, max is 4 points. Requires per-ticket lookup:

```bash
# Get active sprint ID first
SPRINT_ID=$(acli jira board list-sprints --id 389 --state active --json | jq -r '.[0].id')

# Get all sprint items
acli jira sprint list-workitems --sprint $SPRINT_ID --board 389 --csv | tail -n +2 | cut -d',' -f1 > /tmp/sprint-keys.txt

# Check each for points >= 5
while read key; do
  data=$(acli jira workitem view "$key" --fields '*all' --json 2>/dev/null)
  pts=$(echo "$data" | jq -r '.fields.customfield_10026 // 0')
  if [ "$pts" -ge 5 ] 2>/dev/null; then
    summary=$(echo "$data" | jq -r '.fields.summary')
    assignee=$(echo "$data" | jq -r '.fields.assignee.displayName // "Unassigned"')
    echo "$key|$pts|$assignee|$summary"
  fi
done < /tmp/sprint-keys.txt
```

### 3. Unassigned in Sprint
```bash
acli jira workitem search --jql 'project = HEAL AND sprint in openSprints() AND assignee is EMPTY' --fields "key,summary,status" --csv
```

### 4. Stale In Progress (>5 days)
```bash
acli jira workitem search --jql 'project = HEAL AND status = "In Progress" AND updated < -5d' --fields "key,summary,assignee,updated" --csv
```

### 5. Stale Code Review (>3 days)
```bash
acli jira workitem search --jql 'project = HEAL AND status = "Code Review" AND updated < -3d' --fields "key,summary,assignee,updated" --csv
```

### 6. Stale UAT (>5 days)
```bash
acli jira workitem search --jql 'project = HEAL AND status in ("QA", "UAT") AND updated < -5d' --fields "key,summary,assignee,updated" --csv
```

### 7. Stale To Do (>30 days old)
```bash
acli jira workitem search --jql 'project = HEAL AND status = "To Do" AND created < -30d' --fields "key,summary,created" --csv
```

### 8. No Epic Link
Orphan tickets not tied to any initiative:
```bash
acli jira workitem search --jql 'project = HEAL AND sprint in openSprints() AND "Epic Link" is EMPTY AND issuetype != Epic' --fields "key,summary,assignee" --csv
```

## Output Format

```markdown
## Hygiene Report - {DATE}

### Style Guide Violations

**Missing Story Points ({count}):**
| Key | Summary | Assignee | Status |
|-----|---------|----------|--------|

**Oversized (5+ pts, needs breakdown) ({count}):**
| Key | Points | Assignee | Summary |
|-----|--------|----------|---------|

**No Epic Link ({count}):**
| Key | Summary | Assignee |
|-----|---------|----------|

### Stale Items

**In Progress > 5 days ({count}):**
| Key | Summary | Assignee | Days |
|-----|---------|----------|------|

**Code Review > 3 days ({count}):**
| Key | Summary | Assignee | Days |
|-----|---------|----------|------|

**UAT > 5 days ({count}):**
| Key | Summary | Assignee | Days |
|-----|---------|----------|------|

**To Do > 30 days ({count}):**
| Key | Summary | Created |
|-----|---------|---------|

### Unassigned in Sprint ({count})
| Key | Summary | Status |
|-----|---------|--------|

---

### Summary
- Total violations: {n}
- Stale items: {n}
- Unassigned: {n}
- Health score: {X}/100

### Recommendations
{Based on findings, suggest specific actions}
```

## Health Score Calculation

```
Base: 100 points
- Missing points: -5 per ticket
- Oversized: -3 per ticket
- Stale In Progress: -4 per ticket
- Stale Review: -3 per ticket
- Unassigned: -2 per ticket
- No epic: -1 per ticket

Minimum: 0
```

## Thresholds (configurable)

| Check | Threshold | Severity |
|-------|-----------|----------|
| Stale In Progress | 5 days | High |
| Stale Code Review | 3 days | Medium |
| Stale UAT | 5 days | Medium |
| Stale To Do | 30 days | Low |
| Max story points | 4 | Medium |

## Backlog Mode

`/hygiene backlog` - Check backlog items (not in any sprint):

```bash
# Backlog items without points
acli jira workitem search --jql 'project = HEAL AND sprint is EMPTY AND "Story Points[Number]" is EMPTY AND status != Done' --fields "key,summary,created" --csv

# Old backlog items (>90 days)
acli jira workitem search --jql 'project = HEAL AND sprint is EMPTY AND created < -90d AND status != Done' --fields "key,summary,created" --csv
```

## Example Run

When invoked:

1. Get active sprint info
2. Run all JQL queries in parallel where possible
3. For point checks, loop through sprint tickets
4. Calculate health score
5. Format as markdown tables
6. Provide specific recommendations based on findings

## Saving Results

Optionally save to `jira-data/snapshots/`:

```bash
# Create directory if needed
mkdir -p ~/code/management/jira-data/snapshots

# Save JSON snapshot
cat > ~/code/management/jira-data/snapshots/$(date +%Y-%m-%d)-hygiene.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sprint": "$SPRINT_NAME",
  "violations": {
    "missing_points": [...],
    "oversized": [...],
    "no_epic": [...]
  },
  "stale": {
    "in_progress": [...],
    "code_review": [...],
    "uat": [...]
  },
  "unassigned": [...],
  "health_score": N
}
EOF
```
