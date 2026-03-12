# Jira Dashboard

Terminal-based command center showing all key metrics at once.

## Usage
```bash
/dashboard
/dashboard --refresh=60   # Auto-refresh every 60s
/dashboard --team roio
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-dashboard.sh
bash ~/code/management/scripts/jira-dashboard.sh --refresh=30
```

## Panels
- **Sprint Health** - Progress bar, pts, items, days left
- **Risks** - Large items, stale, blocked, unassigned
- **Velocity Trend** - Last 4 sprints mini-chart
- **Today** - Completed and started counts
- **Initiatives** - Active PDCR count and top 3
- **Quick Commands** - Reference for other commands

## Auto-refresh
Use `--refresh=SECS` for live dashboard that updates automatically.
