# Jira Sprint Analysis

Analyze Jira sprints, compare capacity vs load, break down by epic, and identify spillover.

## Usage
`/jira <command> [args]`

## Commands

### Sprint Analysis
- `/jira sprint Q4.S6` — Analyze a sprint (tickets, points, epics, assignees)
- `/jira sprint current` — Analyze the active sprint
- `/jira sprint next` — Analyze the next upcoming sprint

### Comparisons
- `/jira compare Q4.S5 Q4.S6` — Compare two sprints
- `/jira spillover` — Show items not Done in current sprint that will carry over

### Capacity
- `/jira capacity <points>` — Set capacity and compare against sprint load
- `/jira load Q4.S6` — Show total points and breakdown for a sprint

### Epics
- `/jira epics Q4.S6` — Break down sprint by epic with points and ticket counts
- `/jira epic HEAL-858` — Show all tickets in an epic with status/points

---

## Implementation Notes

**Board ID:** 389 (HEAL board)

**Getting sprint IDs:**
```bash
acli jira board list-sprints --id 389 --state "active,future"
```

**Story Points field:** `customfield_10026`
**Epic Link field:** `customfield_10014`

**To get story points (requires per-ticket lookup):**
```bash
acli jira sprint list-workitems --sprint SPRINT_ID --board 389 --csv | tail -n +2 | cut -d',' -f1 > /tmp/keys.txt
while read key; do
  pts=$(acli jira workitem view "$key" --fields '*all' --json 2>/dev/null | jq -r '.fields.customfield_10026 // 0')
  echo "$key: $pts"
done < /tmp/keys.txt
```

---

## What to do when invoked

1. Parse the command and args
2. Look up sprint ID if sprint name given
3. Fetch tickets using `acli jira sprint list-workitems`
4. For each ticket, get story points via `acli jira workitem view --fields '*all' --json`
5. Aggregate by status, assignee, epic as requested
6. Present as markdown tables

### Output Format

**Sprint Summary:**
```
Sprint: Q4.S6 (Dec 22 - Jan 5)
Total: X tickets, Y points
Capacity: Z points
Delta: +/- N points
```

**By Status:**
| Status | Points | Tickets |
|--------|--------|---------|
| To Do | X | N |
| In Progress | X | N |
| Done | X | N |

**By Epic:**
| Epic | Summary | Points | Tickets |
|------|---------|--------|---------|
| HEAL-XXX | Name | X | N |

**By Assignee:**
| Assignee | Points | Tickets |
|----------|--------|---------|
| Name | X | N |

**Spillover (if applicable):**
| Key | Summary | Status | Points | Assignee |
|-----|---------|--------|--------|----------|
