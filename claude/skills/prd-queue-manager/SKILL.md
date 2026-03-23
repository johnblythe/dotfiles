---
name: prd-queue-manager
description: Manage PRD queue when Ralph is running. Detects active prd.json usage, creates queued PRDs with timestamps, and handles promotion. Use when creating new PRDs while Ralph is busy, checking PRD status, or managing the queue.
---

# PRD Queue Manager

Handle PRD contention when Ralph is actively working on a prd.json.

## When to Use

- Creating a new PRD while Ralph is running
- "ralph is busy", "queue this prd", "save for later"
- Checking if prd.json is in use
- Promoting a queued PRD to active

## Detection: Is Ralph Running?

Check for active Ralph work:

```bash
# Check if prd.json exists and has incomplete stories
if [ -f scripts/ralph/prd.json ]; then
  incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' scripts/ralph/prd.json)
  if [ "$incomplete" -gt 0 ]; then
    echo "PRD ACTIVE: $incomplete stories remaining"
  fi
fi

# Check for recent git activity on ralph branch
git log --oneline -5 --since="1 hour ago" 2>/dev/null | grep -q "feat:" && echo "Ralph actively committing"

# Check for running claude processes (Ralph agents)
ps aux | grep -E "claude.*ralph" | grep -v grep
```

## Queuing a New PRD

When prd.json is busy:

1. **Create queued file:**
```bash
# Format: prd.queued-{timestamp}.json
timestamp=$(date +%Y%m%d-%H%M%S)
cp new_prd.json "scripts/ralph/prd.queued-${timestamp}.json"
```

2. **Or with incrementing ID:**
```bash
# Find next queue number
next_id=$(ls scripts/ralph/prd.queued-*.json 2>/dev/null | wc -l | xargs expr 1 +)
cp new_prd.json "scripts/ralph/prd.queued-${next_id}.json"
```

## Queue Status

```bash
# List queued PRDs
ls -la scripts/ralph/prd.queued-*.json 2>/dev/null

# Show queue with summaries
for f in scripts/ralph/prd.queued-*.json; do
  echo "=== $f ==="
  jq -r '.description // .project' "$f" 2>/dev/null
  jq '[.userStories | length] | "Stories: \(.[0])"' "$f" 2>/dev/null
done
```

## Promotion

When Ralph finishes (all stories pass or branch merged):

```bash
# Check if current PRD is complete
all_pass=$(jq '[.userStories[] | select(.passes == false)] | length == 0' scripts/ralph/prd.json)

if [ "$all_pass" = "true" ]; then
  # Archive completed PRD
  mv scripts/ralph/prd.json "scripts/ralph/prd.completed-$(date +%Y%m%d).json"

  # Promote oldest queued PRD
  oldest=$(ls scripts/ralph/prd.queued-*.json 2>/dev/null | head -1)
  if [ -n "$oldest" ]; then
    mv "$oldest" scripts/ralph/prd.json
    echo "Promoted: $oldest"
  fi
fi
```

## Manual Promotion

Force promote a specific queued PRD:

```bash
# Backup current (even if incomplete)
mv scripts/ralph/prd.json scripts/ralph/prd.paused-$(date +%Y%m%d-%H%M%S).json

# Promote specific queue item
mv scripts/ralph/prd.queued-{id}.json scripts/ralph/prd.json
```

## Workflow Summary

```
┌─────────────────┐
│ New PRD created │
└────────┬────────┘
         │
    ┌────▼────┐
    │ prd.json│──── busy? ────┐
    │ in use? │               │
    └────┬────┘               │
         │ no                 │ yes
         ▼                    ▼
┌─────────────────┐   ┌──────────────────────┐
│ Write to        │   │ Write to             │
│ prd.json        │   │ prd.queued-{ts}.json │
└─────────────────┘   └──────────────────────┘
                              │
                      ┌───────▼───────┐
                      │ Ralph finishes│
                      │ current work  │
                      └───────┬───────┘
                              │
                      ┌───────▼───────┐
                      │ Auto-promote  │
                      │ oldest queued │
                      └───────────────┘
```

## File Naming Convention

| File | Purpose |
|------|---------|
| `prd.json` | Active PRD (Ralph works on this) |
| `prd.queued-{timestamp}.json` | Waiting in queue |
| `prd.completed-{date}.json` | Archived after all stories pass |
| `prd.paused-{timestamp}.json` | Interrupted/deprioritized |
