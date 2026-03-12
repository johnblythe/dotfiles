#!/bin/bash
# Jira Bottlenecks - Pipeline analysis
# Usage: ./jira-bottlenecks.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh" "$@"

print_header "Bottlenecks Report"

# Status thresholds (days)
THRESH_IP=5
THRESH_CR=3
THRESH_UAT=5

# ============================================
# Pipeline Overview
# ============================================
echo "### Pipeline Overview"
echo "| Status | Count | Oldest Item |"
echo "|--------|-------|-------------|"

for status in "To Do" "In Progress" "Code Review" "UAT" "QA"; do
  # Get items in this status
  jql="project = $PROJECT AND sprint in openSprints() AND status = \"$status\""
  items=$(acli jira workitem search --jql "$jql" --fields "key,updated" --csv 2>/dev/null | tail -n +2)
  count=$(echo "$items" | grep -c "^${PROJECT}" 2>/dev/null || echo "0")
  count=${count//[^0-9]/}  # strip non-numeric
  [[ -z "$count" ]] && count=0

  if [[ "$count" -gt 0 ]]; then
    # Find oldest (first line after sort by date)
    oldest=$(echo "$items" | head -1 | cut -d',' -f1)
    echo "| $status | $count | $oldest |"
  else
    echo "| $status | 0 | - |"
  fi
done

echo ""

# ============================================
# Stuck Items
# ============================================
echo "### Stuck Items"
echo ""

# In Progress > 5 days
echo "**In Progress > ${THRESH_IP} days:**"
stuck_ip=$(acli jira workitem search --jql "project = $PROJECT AND status = \"In Progress\" AND updated < -${THRESH_IP}d" --fields "key,summary,assignee" --csv 2>/dev/null)
stuck_ip_count=$(echo "$stuck_ip" | tail -n +2 | grep -c "^${PROJECT}" || echo 0)

if [[ "$stuck_ip_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee |"
  echo "|-----|---------|----------|"
  echo "$stuck_ip" | tail -n +2 | head -10 | while IFS=',' read -r key assignee summary; do
    echo "| $key | ${summary:0:35}... | ${assignee:-unassigned} |"
  done
  [[ "$stuck_ip_count" -gt 10 ]] && echo "| ... | +$((stuck_ip_count - 10)) more | |"
else
  echo "None"
fi
echo ""

# Code Review > 3 days
echo "**Code Review > ${THRESH_CR} days:**"
stuck_cr=$(acli jira workitem search --jql "project = $PROJECT AND status = \"Code Review\" AND updated < -${THRESH_CR}d" --fields "key,summary,assignee" --csv 2>/dev/null)
stuck_cr_count=$(echo "$stuck_cr" | tail -n +2 | grep -c "^${PROJECT}" || echo 0)

if [[ "$stuck_cr_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee |"
  echo "|-----|---------|----------|"
  echo "$stuck_cr" | tail -n +2 | head -10 | while IFS=',' read -r key assignee summary; do
    echo "| $key | ${summary:0:35}... | ${assignee:-unassigned} |"
  done
else
  echo "None"
fi
echo ""

# UAT/QA > 5 days
echo "**UAT/QA > ${THRESH_UAT} days:**"
stuck_uat=$(acli jira workitem search --jql "project = $PROJECT AND status in (\"UAT\", \"QA\") AND updated < -${THRESH_UAT}d" --fields "key,summary,assignee" --csv 2>/dev/null)
stuck_uat_count=$(echo "$stuck_uat" | tail -n +2 | grep -c "^${PROJECT}" || echo 0)

if [[ "$stuck_uat_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee |"
  echo "|-----|---------|----------|"
  echo "$stuck_uat" | tail -n +2 | head -10 | while IFS=',' read -r key assignee summary; do
    echo "| $key | ${summary:0:35}... | ${assignee:-unassigned} |"
  done
else
  echo "None"
fi
echo ""

# ============================================
# Summary
# ============================================
echo "---"
echo "### Summary"
total_stuck=$((stuck_ip_count + stuck_cr_count + stuck_uat_count))
echo "- **Total Stuck:** $total_stuck items"
echo "- **Biggest Bottleneck:** $(
  if [[ "$stuck_ip_count" -ge "$stuck_cr_count" && "$stuck_ip_count" -ge "$stuck_uat_count" ]]; then
    echo "In Progress ($stuck_ip_count)"
  elif [[ "$stuck_cr_count" -ge "$stuck_uat_count" ]]; then
    echo "Code Review ($stuck_cr_count)"
  else
    echo "UAT/QA ($stuck_uat_count)"
  fi
)"
echo ""
echo "*Generated: $(date)*"
