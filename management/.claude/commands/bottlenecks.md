# Jira Bottlenecks

Pipeline analysis - identify where work is getting stuck.

## Usage
```bash
/bottlenecks
/bottlenecks --team roio
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-bottlenecks.sh
bash ~/code/management/scripts/jira-bottlenecks.sh --team roio
```

## What It Shows

### Pipeline Overview
Count of items per status in current sprint.

### Stuck Items
- **In Progress > 5 days** - Work not moving
- **Code Review > 3 days** - Reviews stalled
- **UAT/QA > 5 days** - Testing bottleneck

### Summary
- Total stuck count
- Biggest bottleneck stage

## Thresholds
| Stage | Stuck After |
|-------|-------------|
| In Progress | 5 days |
| Code Review | 3 days |
| UAT/QA | 5 days |
