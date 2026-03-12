#!/bin/bash
# Jira Velocity Report
# Usage: ./jira-velocity.sh [--team NAME] [--board ID] [--project KEY]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh" "$@"

# ============================================
# Get closed sprints for this board
# ============================================
SPRINTS=$(get_closed_sprints 6)

if [[ -z "$SPRINTS" ]]; then
  echo "No closed sprints found for board $BOARD_ID"
  exit 1
fi

# ============================================
# Output
# ============================================
print_header "Velocity Report"

echo "| Sprint | Committed | Delivered | Rate | Done/Total |"
echo "|--------|-----------|-----------|------|------------|"

rm -f /tmp/velocity_totals.txt

echo "$SPRINTS" | while IFS='|' read -r id name; do
  committed=$(jira_sum_points "project = $PROJECT AND sprint = $id")
  delivered=$(jira_sum_points "project = $PROJECT AND sprint = $id AND status = Done")
  total=$(jira_count "project = $PROJECT AND sprint = $id")
  done_count=$(jira_count "project = $PROJECT AND sprint = $id AND status = Done")

  if [[ "$committed" -gt 0 ]] 2>/dev/null; then
    rate=$(echo "scale=0; $delivered * 100 / $committed" | bc)
  else
    rate=0
  fi

  echo "| $name | $committed | $delivered | ${rate}% | $done_count/$total |"
  echo "$committed $delivered" >> /tmp/velocity_totals.txt
done

# ============================================
# Summary
# ============================================
if [[ -f /tmp/velocity_totals.txt ]]; then
  sprint_count=$(wc -l < /tmp/velocity_totals.txt | tr -d ' ')
  totals=$(awk '{c+=$1; d+=$2} END {print c, d}' /tmp/velocity_totals.txt)
  total_c=$(echo $totals | cut -d' ' -f1)
  total_d=$(echo $totals | cut -d' ' -f2)
  rm /tmp/velocity_totals.txt

  echo ""
  echo "### Summary"
  if [[ "$sprint_count" -gt 0 ]]; then
    avg=$(echo "scale=1; $total_d / $sprint_count" | bc)
  else
    avg=0
  fi
  if [[ "$total_c" -gt 0 ]]; then
    rate=$(echo "scale=0; $total_d * 100 / $total_c" | bc)
  else
    rate=0
  fi
  echo "- **Avg Velocity:** $avg pts/sprint"
  echo "- **Avg Delivery Rate:** ${rate}%"
  echo "- **Total Delivered:** $total_d pts ($sprint_count sprints)"
fi
