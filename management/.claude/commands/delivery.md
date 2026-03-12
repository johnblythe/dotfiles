Analyze team delivery health using Jira sprint data.

## Data Collection

1. Get recent closed sprints (last 5-6):
   ```
   acli jira board list-sprints --id 2694 --state closed --limit 15
   ```
   Focus on Q4.Sx sprints (most recent naming convention)

2. For each sprint, get work items with status:
   ```
   acli jira sprint list-workitems --sprint {ID} --board 2694 --fields "key,summary,status,issuetype,assignee" --json
   ```

## Metrics to Calculate

### Completion Rate
- Count items with status "Done" vs total items in sprint
- Report as percentage per sprint
- Show trend over last 5 sprints

### Carryover/Spillover
- Identify items that appear in multiple consecutive sprints (not Done)
- Flag chronic spillover items (3+ sprints)

### Promise Keeping
- If sprint had a goal, was it met?
- Count of planned vs actually delivered

### Disruption Index
- Items added mid-sprint (if detectable via created date vs sprint start)
- Items removed/descoped

## Output Format

```
## Delivery Health Report

### Completion Rate Trend
| Sprint | Done | Total | Rate | Trend |
|--------|------|-------|------|-------|

### Spillover Items
Items carried across 2+ sprints:
- {KEY}: {summary} — {N} sprints

### Team Capacity Notes
- Avg items/sprint: X
- Velocity trend: stable/increasing/decreasing

### Flags
- Any chronic blockers
- Capacity concerns
```

## Questions to Answer
- Are we getting better or worse at completing what we commit to?
- What items keep slipping?
- Is the team overcommitting?
- Any individuals consistently overloaded?
