# Jira Team Report

Per-person workload and sprint load distribution.

## Usage
```bash
/team
/team --team roio
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-team.sh
bash ~/code/management/scripts/jira-team.sh --team roio
```

## What It Shows

### Current Sprint Load
Per-person breakdown: Total items, Done, In Progress, To Do, Other statuses.

### Summary
- Total items in sprint
- Completion percentage
- Unassigned count

### Flags
- People with >8 items (high load)
- Unassigned items if >3
