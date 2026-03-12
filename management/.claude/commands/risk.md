# Jira Risk

Items at risk of missing the sprint.

## Usage
```bash
/risk
/risk --team roio
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-risk.sh
```

## Risk Categories
- 🎯 Large items not started (3+ pts still in To Do)
- 🐌 Stale In Progress (no update 3+ days)
- 👻 Unassigned work in sprint
- 🔍 Stuck in Review/QA (2+ days)
