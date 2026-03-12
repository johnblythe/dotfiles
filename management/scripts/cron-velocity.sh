#!/bin/bash
# Weekly velocity snapshot - run from cron
# Saves report, trends CSV, notification + email

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MGMT_DIR="${SCRIPT_DIR}/.."
SNAPSHOT_DIR="${MGMT_DIR}/jira-data/snapshots"
TRENDS_DIR="${MGMT_DIR}/jira-data/trends"

mkdir -p "$SNAPSHOT_DIR" "$TRENDS_DIR"

DATE=$(date +%Y-%m-%d)
TRENDS_FILE="${TRENDS_DIR}/velocity.csv"
REPORT="${SNAPSHOT_DIR}/${DATE}-velocity.md"

# Run velocity and save snapshot
bash "$SCRIPT_DIR/jira-velocity.sh" > "$REPORT"

# Extract summary data
SPRINT=$(grep "Sprint:" "$REPORT" | sed 's/.*Sprint: //' | tr -d '*')
COMMITTED=$(grep "Committed:" "$REPORT" | grep -oE '[0-9]+' | head -1)
DONE=$(grep "Delivered:" "$REPORT" | grep -oE '[0-9]+' | head -1)
ACCURACY=$(grep "Accuracy:" "$REPORT" | grep -oE '[0-9]+' | head -1)

# Init CSV if needed
if [[ ! -f "$TRENDS_FILE" ]]; then
  echo "date,sprint,committed,done" > "$TRENDS_FILE"
fi

echo "${DATE},${SPRINT},${COMMITTED:-0},${DONE:-0}" >> "$TRENDS_FILE"

SUMMARY="Sprint: $SPRINT | Delivered: ${DONE:-0}/${COMMITTED:-0} pts (${ACCURACY:-0}%)"

# macOS notification
osascript -e "display notification \"$SUMMARY\" with title \"Jira Velocity Report\" subtitle \"$DATE\""

echo "Velocity snapshot: $REPORT"
echo "Trends updated: $TRENDS_FILE"
