# Jira Initiative

PDCR initiative status with linked work breakdown.

## Usage
```bash
/initiative PDCR-123
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-initiative.sh PDCR-123
```

## What It Shows

### Initiative Overview
- Summary, type, status, owner

### Linked Work
- Count by status (Done, In Progress, Other)
- Story points completed vs total
- Progress percentage

### Active Work
- Items currently In Progress

### Needs Attention
- Stale items (In Progress >5 days)
- Unassigned items

## Notes
Uses `linkedIssues()` JQL to find all work connected to the initiative.
