---
name: ralph-status
description: Check Ralph autonomous agent progress. Use when asking "how's ralph doing", "ralph status", "check ralph", or wanting to see task completion status.
---

# Check Ralph Progress

Run these commands to get Ralph's current status:

## 1. Overall Progress

```bash
# Story completion summary
cat scripts/ralph/prd.json 2>/dev/null | jq -r '
  (.userStories | length) as $total |
  ([.userStories[] | select(.passes == true)] | length) as $done |
  "Progress: \($done)/\($total) stories complete (\($done * 100 / $total)%)"
'
```

## 2. Story Status

```bash
# List all stories with status
cat scripts/ralph/prd.json 2>/dev/null | jq -r '.userStories[] |
  (if .passes then "✅" else "⬜" end) + " " + .id + ": " + .title'
```

## 3. What's Left

```bash
# Pending stories only
cat scripts/ralph/prd.json 2>/dev/null | jq -r '.userStories[] | select(.passes != true) |
  "⬜ " + .id + ": " + .title + "\n   " + .description'
```

## 4. Recent Activity

```bash
# Last 30 lines of progress log
tail -30 scripts/ralph/progress.txt 2>/dev/null
```

## 5. Latest Iteration Log

```bash
# Most recent non-empty log
latest=$(ls -t scripts/ralph/logs/*.log 2>/dev/null | while read f; do [ -s "$f" ] && echo "$f" && break; done)
[ -n "$latest" ] && cat "$latest"
```

## 6. Is Ralph Running?

```bash
# Check for running ralph process
pgrep -f "ralph.sh" > /dev/null && echo "🟢 Ralph is running" || echo "⚪ Ralph is not running"
```

---

## Quick Summary Format

After running the above, summarize as:

```
Ralph Status: X/Y complete (Z%)
✅ Done: US-001, US-002, ...
⬜ Pending: US-XXX (title)
🟢/⚪ Running: yes/no
Last activity: [summary from progress.txt]
```
