# Jira Automation

Cron jobs for automated reports and trend tracking.

## Setup Cron

Add to crontab (`crontab -e`):

```cron
# Daily hygiene snapshot at 8am
0 8 * * * /Users/john.blythe/code/management/scripts/cron-hygiene.sh

# Weekly velocity on Friday 5pm
0 17 * * 5 /Users/john.blythe/code/management/scripts/cron-velocity.sh
```

## Scripts

### cron-hygiene.sh
- Runs daily hygiene audit
- Saves to `jira-data/snapshots/YYYY-MM-DD-hygiene.md`

### cron-velocity.sh
- Runs weekly velocity report
- Saves to `jira-data/snapshots/YYYY-MM-DD-velocity.md`
- Appends to `jira-data/trends/velocity.csv`

## Manual Run
```bash
bash ~/code/management/scripts/cron-hygiene.sh
bash ~/code/management/scripts/cron-velocity.sh
```

## Output Locations
```
jira-data/
├── snapshots/
│   ├── 2026-01-01-hygiene.md
│   └── 2026-01-01-velocity.md
└── trends/
    └── velocity.csv
```
