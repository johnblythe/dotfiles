#!/bin/bash
# Daily hygiene snapshot - run from cron
# Saves report, sends notification + email

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MGMT_DIR="${SCRIPT_DIR}/.."
SNAPSHOT_DIR="${MGMT_DIR}/jira-data/snapshots"

mkdir -p "$SNAPSHOT_DIR"

DATE=$(date +%Y-%m-%d)
REPORT="${SNAPSHOT_DIR}/${DATE}-hygiene.md"

# Run hygiene report and save
bash "$SCRIPT_DIR/jira-hygiene.sh" > "$REPORT"

# Extract summary for notification
VIOLATIONS=$(grep -c "FAIL\|WARN" "$REPORT" 2>/dev/null || echo "0")
MISSING_PTS=$(grep "Missing Story Points" "$REPORT" | grep -oE '[0-9]+' | head -1 || echo "0")
STALE=$(grep "Stale" "$REPORT" | grep -oE '[0-9]+' | head -1 || echo "0")

SUMMARY="Violations: $VIOLATIONS | Missing pts: ${MISSING_PTS:-0} | Stale: ${STALE:-0}"

# macOS notification
osascript -e "display notification \"$SUMMARY\" with title \"Jira Hygiene Report\" subtitle \"$DATE\""

echo "Snapshot saved: $REPORT"
