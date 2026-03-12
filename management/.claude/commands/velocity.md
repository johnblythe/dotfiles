# Jira Velocity Report

Track points delivered across sprints and show velocity trends.

## Usage
`/velocity` - Last 6 sprints (Q4)

## Quick Run
```bash
bash ~/code/management/scripts/jira-velocity.sh
```

## API Details

Uses Jira REST API v3 (POST /rest/api/3/search/jql) with credentials from `~/.config/jiratui/config.yaml`.

### Get Story Points Sum
```bash
curl -s -X POST -H "Content-Type: application/json" \
  -u "${USER}:${TOKEN}" \
  "${JIRA_URL}/rest/api/3/search/jql" \
  -d '{"jql": "project = HEAL AND sprint = 10733", "fields": ["customfield_10026"], "maxResults": 200}' | \
  jq '[.issues[].fields.customfield_10026 // 0] | add'
```

## Output Format

```markdown
## Velocity Report - {DATE}

### Last 6 Sprints
| Sprint | Committed | Delivered | Rate | vs Avg |
|--------|-----------|-----------|------|--------|
| Q4.S5 | 24 | 22 | 92% | +3 |
| Q4.S4 | 28 | 20 | 71% | +1 |
| Q4.S3 | 22 | 19 | 86% | 0 |
| Q4.S2 | 26 | 21 | 81% | +2 |
| Q4.S1 | 20 | 18 | 90% | -1 |
| Q4.S0 | 18 | 17 | 94% | -2 |

### Summary
- **Avg Velocity:** 19.5 pts/sprint
- **Avg Commitment Accuracy:** 85%
- **Trend:** Stable

### Velocity Chart
```
Q4.S0 █████████████████░ 17
Q4.S1 ██████████████████░ 18
Q4.S2 █████████████████████░ 21
Q4.S3 ███████████████████░ 19
Q4.S4 ████████████████████░ 20
Q4.S5 ██████████████████████░ 22
      0    5    10   15   20   25
```

### Recommendations
{Based on data: overcommitting? increasing? decreasing?}
```

## Trend Calculation

```
Trend = (Last 3 avg) - (Previous 3 avg)
  > +2: Increasing
  < -2: Decreasing
  else: Stable
```

## Sprint IDs Reference (Q4)

| Sprint | ID |
|--------|-----|
| Q4.S0 | 9040 |
| Q4.S1 | 9110 |
| Q4.S2 | 10474 |
| Q4.S3 | 10731 |
| Q4.S4 | 10732 |
| Q4.S5 | 10733 |
| Q4.S6 | 11870 (active) |

## Saving to Trends

Append to `jira-data/trends/velocity.csv`:

```csv
date,sprint,sprint_id,committed_pts,delivered_pts,accuracy_pct
2025-12-22,Q4.S5,10733,24,22,92
```

## Notes

- Story points are in `customfield_10026`
- Sprint start/end dates from board list-sprints
- "Committed" = total points at sprint end (not start - we don't track start snapshot)
- Consider: capture "committed at sprint start" separately if planning vs delivery accuracy matters
