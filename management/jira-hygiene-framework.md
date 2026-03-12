# Jira Hygiene Framework

A comprehensive system for tracking project health, workflow efficiency, and team performance.

## Overview

### Goals
1. **Visibility**: Easy status checks at project, sprint, and ticket level
2. **Early Warning**: Detect bottlenecks and hygiene issues before they compound
3. **Trends**: Track performance over time, not just point-in-time snapshots
4. **Actionable**: Every report should suggest specific remediation

### Components
- **Commands**: Slash commands for on-demand analysis
- **Logs**: Structured data files for trend tracking
- **Automation**: Scheduled runs to keep data fresh

---

## Command Specifications

### 1. `/jira hygiene` - Audit Current State

**Purpose**: Run all hygiene checks against active sprint and backlog.

**Output**:
```
## Hygiene Report - 2024-01-15

### Style Guide Violations
| Key | Issue | Assignee |
|-----|-------|----------|
| HEAL-123 | Missing story points | @john |
| HEAL-456 | No acceptance criteria | @sarah |
| HEAL-789 | 5+ points (needs breakdown) | @mike |

### Stale Items
| Key | Status | Days Stuck | Assignee |
|-----|--------|------------|----------|
| HEAL-234 | In Progress | 8 days | @john |
| HEAL-567 | Code Review | 5 days | @sarah |

### Unassigned in Sprint
| Key | Summary | Points |
|-----|---------|--------|
| HEAL-890 | Setup logging | 2 |

### Summary
- Violations: 3
- Stale items: 2
- Unassigned: 1
```

**JQL Queries**:
```bash
# Missing story points (stories/tasks/bugs only)
'project = HEAL AND sprint in openSprints() AND "Story Points[Number]" is EMPTY AND issuetype in (Story, Task, Bug)'

# Stale In Progress (>5 days no update)
'project = HEAL AND status = "In Progress" AND updated < -5d'

# Stale Code Review (>3 days)
'project = HEAL AND status = "Code Review" AND updated < -3d'

# Unassigned in sprint
'project = HEAL AND sprint in openSprints() AND assignee is EMPTY'

# Stale To Do (>30 days)
'project = HEAL AND status = "To Do" AND created < -30d'
```

**Checking for 4+ points** (requires per-ticket lookup):
```bash
# Get all sprint items, then filter by points
acli jira sprint list-workitems --sprint $SPRINT_ID --board 389 --csv | tail -n +2 | cut -d',' -f1 > /tmp/keys.txt
while read key; do
  pts=$(acli jira workitem view "$key" --fields '*all' --json 2>/dev/null | jq -r '.fields.customfield_10026 // 0')
  if [ "$pts" -ge 5 ]; then
    echo "$key: $pts points (needs breakdown)"
  fi
done < /tmp/keys.txt
```

**Checking for acceptance criteria** (requires description parsing):
```bash
# Heuristic: description contains "acceptance criteria" or has checklist
acli jira workitem view $KEY --fields 'description' --json | jq -r '.fields.description' | grep -qi "acceptance\|criteria\|checklist"
```

---

### 2. `/jira bottlenecks` - Workflow Analysis

**Purpose**: Identify where work is getting stuck in the pipeline.

**Output**:
```
## Workflow Bottlenecks - 2024-01-15

### Pipeline Summary
| Status | Count | Avg Days | Oldest |
|--------|-------|----------|--------|
| To Do | 8 | 3.2 | HEAL-100 (12d) |
| In Progress | 5 | 2.1 | HEAL-200 (6d) |
| Code Review | 3 | 1.8 | HEAL-300 (4d) |
| QA/UAT | 2 | 4.5 | HEAL-400 (9d) |

### Stuck Items (> threshold)
| Key | Status | Days | Assignee | Last Update |
|-----|--------|------|----------|-------------|
| HEAL-400 | UAT | 9 | @qa-team | Dec 6 |
| HEAL-200 | In Progress | 6 | @john | Dec 9 |

### Re-opened (quality signal)
| Key | Re-opened | Times | Summary |
|-----|-----------|-------|---------|
| HEAL-500 | Dec 10 | 2 | Auth bug |

### Recommendations
- UAT has longest avg wait (4.5d) - consider UAT capacity
- 1 item re-opened 2x - investigate root cause
```

**JQL Queries**:
```bash
# By status (run for each status)
'project = HEAL AND sprint in openSprints() AND status = "In Progress"'

# Re-opened recently
'project = HEAL AND status changed FROM "Done" AFTER -30d'

# Blocked items (if using Blocked status or flag)
'project = HEAL AND (status = "Blocked" OR labels = "blocked")'
```

**Time-in-status** (requires changelog API):
```bash
# Get issue changelog to calculate time in each status
curl -s -H "Authorization: Basic $AUTH" \
  "https://datavant.atlassian.net/rest/api/3/issue/HEAL-123/changelog" | \
  jq '.values[] | select(.items[].field == "status")'
```

---

### 3. `/jira velocity` - Sprint Velocity Trends

**Purpose**: Track delivered points over recent sprints.

**Output**:
```
## Velocity Report

### Last 6 Sprints
| Sprint | Committed | Delivered | Rate | Trend |
|--------|-----------|-----------|------|-------|
| Q4.S6 | 24 | 20 | 83% | -- |
| Q4.S5 | 28 | 22 | 79% | -4% |
| Q4.S4 | 22 | 21 | 95% | +16% |
| Q4.S3 | 26 | 18 | 69% | -26% |
| Q4.S2 | 20 | 19 | 95% | +26% |
| Q4.S1 | 18 | 17 | 94% | -- |

### Summary
- Avg velocity: 19.5 pts/sprint
- Avg commitment accuracy: 86%
- Trend: Stable (within 10% variance)

### Velocity Chart
Q4.S1 ████████████████░ 17
Q4.S2 ███████████████████░ 19
Q4.S3 ██████████████████░ 18
Q4.S4 █████████████████████░ 21
Q4.S5 ██████████████████████░ 22
Q4.S6 ████████████████████░ 20
```

**Data Collection**:
```bash
# Get closed sprints
acli jira board list-sprints --id 389 --state closed --limit 10

# For each sprint, sum Done points
# Requires per-ticket point lookup (see CLAUDE.md pattern)
```

---

### 4. `/jira team` - Individual Performance

**Purpose**: Per-person metrics for capacity planning and balance.

**Output**:
```
## Team Performance - Q4.S6

### Current Sprint Load
| Person | Assigned | Done | In Progress | Remaining |
|--------|----------|------|-------------|-----------|
| @john | 8 pts | 4 | 2 | 2 |
| @sarah | 6 pts | 3 | 3 | 0 |
| @mike | 10 pts | 2 | 4 | 4 |

### 5-Sprint Averages
| Person | Avg Delivered | Avg Assigned | Delivery % |
|--------|---------------|--------------|------------|
| @john | 7.2 | 8.0 | 90% |
| @sarah | 5.8 | 6.2 | 94% |
| @mike | 6.0 | 8.5 | 71% |

### Notes
- @mike consistently overloaded (71% delivery)
- @sarah has capacity headroom
```

---

### 5. `/jira audit <KEY>` - Single Ticket Audit

**Purpose**: Check one ticket against style guide.

**Output**:
```
## Audit: HEAL-123

### Compliance
| Check | Status |
|-------|--------|
| Has story points | PASS (2 pts) |
| Points <= 4 | PASS |
| Has acceptance criteria | FAIL |
| Has assignee | PASS (@john) |
| In epic | PASS (HEAL-800) |
| Summary is specific | WARN (too vague?) |

### Recommendations
1. Add acceptance criteria section
2. Consider more specific summary
```

---

### 6. `/jira spillover` - Carryover Analysis

**Purpose**: Track what's not getting done and why.

**Output**:
```
## Spillover Analysis

### Current Sprint -> Next
Items likely to spill:
| Key | Points | Status | Assignee | Risk |
|-----|--------|--------|----------|------|
| HEAL-100 | 3 | To Do | @john | HIGH |
| HEAL-200 | 2 | In Progress | @mike | MED |

### Chronic Spillover (3+ sprints)
| Key | Sprints | Summary |
|-----|---------|---------|
| HEAL-050 | 4 | Legacy migration |

### Historical Rate
| Sprint | Spillover Pts | % of Committed |
|--------|---------------|----------------|
| Q4.S5 | 6 | 21% |
| Q4.S4 | 4 | 18% |
| Q4.S3 | 8 | 31% |
```

---

## Data/Logging Structure

### Directory Layout
```
management/
├── jira-data/
│   ├── snapshots/
│   │   ├── 2024-01-15-hygiene.json
│   │   ├── 2024-01-15-velocity.json
│   │   └── ...
│   ├── trends/
│   │   ├── velocity.csv
│   │   ├── spillover.csv
│   │   └── team-performance.csv
│   └── alerts/
│       └── 2024-01-15-alerts.md
```

### Snapshot Format (hygiene)
```json
{
  "timestamp": "2024-01-15T09:00:00Z",
  "sprint": "Q4.S6",
  "violations": {
    "missing_points": ["HEAL-123", "HEAL-456"],
    "oversized": ["HEAL-789"],
    "no_acceptance_criteria": ["HEAL-234"],
    "unassigned": ["HEAL-567"]
  },
  "stale": {
    "in_progress": [{"key": "HEAL-100", "days": 8}],
    "code_review": [{"key": "HEAL-200", "days": 4}],
    "uat": []
  },
  "summary": {
    "total_violations": 5,
    "total_stale": 2
  }
}
```

### Trend Format (velocity.csv)
```csv
date,sprint,committed_pts,delivered_pts,accuracy_pct,team_size
2024-01-01,Q4.S5,28,22,79,5
2024-01-15,Q4.S6,24,20,83,5
```

### Trend Format (spillover.csv)
```csv
date,sprint,spillover_pts,spillover_pct,chronic_items
2024-01-01,Q4.S5,6,21,2
2024-01-15,Q4.S6,4,17,2
```

---

## Automation

### Daily Hygiene Check
```bash
#!/bin/bash
# Run daily via cron or launchd

cd ~/code/management
DATE=$(date +%Y-%m-%d)

# Run hygiene check, save snapshot
claude --skill jira-hygiene --output json > jira-data/snapshots/${DATE}-hygiene.json

# Check for critical violations
VIOLATIONS=$(jq '.summary.total_violations' jira-data/snapshots/${DATE}-hygiene.json)
if [ "$VIOLATIONS" -gt 5 ]; then
  # Alert via Slack/email
  echo "High hygiene violations: $VIOLATIONS" | slack-notify
fi
```

### Weekly Velocity Update
```bash
#!/bin/bash
# Run end-of-sprint or weekly

cd ~/code/management
DATE=$(date +%Y-%m-%d)

# Get sprint velocity data
claude --skill jira-velocity --output json > jira-data/snapshots/${DATE}-velocity.json

# Append to trend file
jq -r '[.date, .sprint, .committed, .delivered, .accuracy] | @csv' \
  jira-data/snapshots/${DATE}-velocity.json >> jira-data/trends/velocity.csv
```

### Scheduled via launchd (macOS)
```xml
<!-- ~/Library/LaunchAgents/com.jira-hygiene.daily.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jira-hygiene.daily</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>~/code/management/scripts/daily-hygiene.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
</dict>
</plist>
```

---

## JQL Reference

### Hygiene Checks
```
# Missing story points
project = HEAL AND sprint in openSprints() AND "Story Points[Number]" is EMPTY AND issuetype in (Story, Task, Bug)

# Unassigned in sprint
project = HEAL AND sprint in openSprints() AND assignee is EMPTY

# Stale To Do (30+ days)
project = HEAL AND status = "To Do" AND created < -30d

# Stale In Progress (5+ days)
project = HEAL AND status = "In Progress" AND updated < -5d

# Stale Code Review (3+ days)
project = HEAL AND status = "Code Review" AND updated < -3d

# Stale UAT (5+ days)
project = HEAL AND status in ("QA", "UAT") AND updated < -5d
```

### Workflow Analysis
```
# Items by status
project = HEAL AND sprint in openSprints() AND status = "In Progress"

# Re-opened items
project = HEAL AND status changed FROM "Done" AFTER -30d

# Blocked
project = HEAL AND (status = "Blocked" OR labels = "blocked")

# Added mid-sprint (disruption)
project = HEAL AND sprint in openSprints() AND created > startOfSprint()
```

### Velocity/Performance
```
# Done in sprint
project = HEAL AND sprint = "Q4.S6" AND status = "Done"

# All items in sprint (for commitment)
project = HEAL AND sprint = "Q4.S6"

# By assignee
project = HEAL AND sprint in openSprints() AND assignee = "john@company.com"
```

### Spillover
```
# Not done in current sprint
project = HEAL AND sprint in openSprints() AND status != "Done"

# Chronic spillover (in 3+ sprints - requires manual tracking)
# Must track via snapshots over time
```

---

## Implementation Roadmap

### Phase 1: Core Commands
1. `/jira hygiene` - Most immediate value
2. `/jira audit <KEY>` - Quick single-ticket check
3. Update existing `/sprint` with hygiene flags

### Phase 2: Trend Tracking
4. Set up `jira-data/` directory structure
5. `/jira velocity` with historical data
6. `/jira spillover` with chronic tracking

### Phase 3: Team Insights
7. `/jira team` - Individual metrics
8. `/jira bottlenecks` - Workflow analysis

### Phase 4: Automation
9. Daily hygiene script
10. Weekly velocity capture
11. Alert thresholds

---

## Configuration

### Thresholds (customize per team)
```yaml
# jira-data/config.yaml
thresholds:
  stale_in_progress_days: 5
  stale_code_review_days: 3
  stale_uat_days: 5
  stale_todo_days: 30
  max_story_points: 4
  high_violation_alert: 5

team:
  board_id: 389
  project: HEAL
  sprint_prefix: "Q"

members:
  - john@company.com
  - sarah@company.com
  - mike@company.com
```

---

## Success Metrics

After implementation, track:
- Reduction in tickets missing story points
- Decrease in chronic spillover items
- More consistent velocity (lower variance)
- Shorter time-in-status for review stages
- Earlier identification of blocked items
