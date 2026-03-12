# Sprint Status

Pull current sprint status from Jira and summarize.

## What to do

1. Get active sprint:
   ```bash
   acli jira board list-sprints --id 389 --state active
   ```

2. Get sprint items:
   ```bash
   acli jira sprint list-workitems --sprint {SPRINT_ID} --board 389 --csv --paginate
   ```

3. For story points, loop through tickets:
   ```bash
   # Story points are in customfield_10026
   acli jira workitem view {KEY} --fields '*all' --json | jq '.fields.customfield_10026'
   ```

4. Summarize:
   - Total tickets and points
   - Breakdown by status (Done, In Progress, To Do, Blocked, UAT, Code Review)
   - Flag items with no assignee
   - Flag items at risk of not completing (In Progress but large)
   - Show spillover candidates (To Do items)

## Output Format

```
## Sprint: {NAME} ({START} - {END})

**Summary:** X tickets, Y points
**Done:** X pts (N tickets)
**In Progress:** X pts (N tickets)
**Remaining:** X pts (N tickets)

### At Risk
| Key | Summary | Status | Points | Assignee |
|-----|---------|--------|--------|----------|

### Unassigned
| Key | Summary | Status | Points |
|-----|---------|--------|--------|

### By Assignee
| Assignee | Done | In Progress | To Do | Total |
|----------|------|-------------|-------|-------|
```
