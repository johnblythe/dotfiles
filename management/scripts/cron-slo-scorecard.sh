#!/bin/bash
# SLO Scorecard Push — weekly Confluence update
# Queries Datadog SLO API, updates Observability Scorecard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/code/management/jira-data/snapshots"
TIMESTAMP=$(date +%Y-%m-%d)

mkdir -p "$LOG_DIR"

echo "[$TIMESTAMP] Running SLO scorecard push..."

# Run the push (captures output for log)
OUTPUT=$(python3 "$SCRIPT_DIR/slo-scorecard-push.py" --push 2>&1) || {
  echo "[$TIMESTAMP] SLO scorecard push FAILED"
  echo "$OUTPUT"
  osascript -e 'display notification "Scorecard push failed — check logs" with title "📊 SLO Scorecard" subtitle "Error"'
  exit 1
}

echo "$OUTPUT"

# Save snapshot
echo "$OUTPUT" > "$LOG_DIR/${TIMESTAMP}-slo-scorecard.md"

# Notify
osascript -e 'display notification "Confluence scorecard updated" with title "📊 SLO Scorecard" subtitle "Weekly push complete"'

echo "[$TIMESTAMP] SLO scorecard push complete"
