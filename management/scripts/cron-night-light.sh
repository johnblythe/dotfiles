#!/bin/bash
# Night Light scheduled run
# Runs anomaly detection, saves report, sends notification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIGHT_LIGHT_DIR="${SCRIPT_DIR}/../night-light"
REPORT_DIR="$HOME/code/healthsource/night-light-runs"

mkdir -p "$REPORT_DIR"

TIMESTAMP=$(date +%Y-%m-%d-%H%M)
HOUR=$(date +%H)

# Run night-light (dry run by default)
cd "$NIGHT_LIGHT_DIR"
./night-light.sh --hours 4

# Find the latest report
LATEST_REPORT=$(ls -t "$REPORT_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
    osascript -e 'display notification "No report generated" with title "🌙 Night Light" subtitle "Check logs"'
    exit 1
fi

# Extract summary from report
TICKETS=$(grep -oE 'Tickets WOULD be created: [0-9]+' "$LATEST_REPORT" | grep -oE '[0-9]+' || echo "0")
PRS=$(grep -oE 'PRs WOULD be created: [0-9]+' "$LATEST_REPORT" | grep -oE '[0-9]+' || echo "0")

# Get top issue if any
TOP_ISSUE=$(grep -A1 "Investigation #1:" "$LATEST_REPORT" | tail -1 | sed 's/^### //' | cut -c1-50 || echo "None")

# Build notification
if [ "$TICKETS" = "0" ]; then
    SUMMARY="All quiet - no significant anomalies"
    URGENCY="✅"
else
    SUMMARY="${TICKETS} issues found, ${PRS} PRs ready"
    URGENCY="⚠️"
fi

# Send macOS notification
osascript -e "display notification \"$SUMMARY\" with title \"🌙 Night Light ${URGENCY}\" subtitle \"${TOP_ISSUE}\""

echo "[$TIMESTAMP] Night Light complete: $TICKETS tickets, $PRS PRs"
echo "Report: $LATEST_REPORT"
