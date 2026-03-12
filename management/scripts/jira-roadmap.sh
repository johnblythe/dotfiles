#!/bin/bash
# Jira Roadmap - All PDCR initiatives overview
# Usage: ./jira-roadmap.sh [--status STATUS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args before sourcing lib
FILTER_STATUS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) FILTER_STATUS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

source "$SCRIPT_DIR/jira-lib.sh"

print_header "PDCR Roadmap"

# ============================================
# Fetch all PDCR items by status
# ============================================

# Status categories
active_statuses="Development,\"In Progress\",\"To Do\""
planning_statuses="\"Needs Refinement\",\"Ready for Dev\""
done_status="Done"
parking_status="\"Parking lot\""

# Count per status
echo "### Overview"
echo "| Status | Count |"
echo "|--------|-------|"

for status_group in "Development" "In Progress" "To Do" "Needs Refinement" "Ready for Dev" "Parking lot" "Done"; do
  jql="project = PDCR AND status = \"$status_group\""
  result=$(jira_search "$jql" "key")
  count=$(echo "$result" | jq '.issues | length // 0')
  count=${count:-0}
  echo "| $status_group | $count |"
done

echo ""

# ============================================
# Active Initiatives
# ============================================
echo "### Active Initiatives"
echo "| Key | Summary | Status | Owner |"
echo "|-----|---------|--------|-------|"

active_jql="project = PDCR AND status in (Development, \"In Progress\", \"To Do\")"
active=$(jira_search "$active_jql" "key,summary,status,assignee")
active_count=$(echo "$active" | jq '.issues | length // 0')
active_count=${active_count:-0}

if [[ "$active_count" -gt 0 ]]; then
  echo "$active" | jq -r '.issues[] | "\(.key)|\(.fields.summary // "N/A")|\(.fields.status.name // "N/A")|\(.fields.assignee.displayName // "Unassigned")"' | while IFS='|' read -r key sum status owner; do
    echo "| $(jira_link "$key") | ${sum:0:40} | $status | $owner |"
  done
else
  echo "| - | No active initiatives | - | - |"
fi

echo ""

# ============================================
# Planning Pipeline
# ============================================
echo "### Planning Pipeline"
echo "| Key | Summary | Status |"
echo "|-----|---------|--------|"

planning_jql="project = PDCR AND status in (\"Needs Refinement\", \"Ready for Dev\")"
planning=$(jira_search "$planning_jql" "key,summary,status")
planning_count=$(echo "$planning" | jq '.issues | length // 0')
planning_count=${planning_count:-0}

if [[ "$planning_count" -gt 0 ]]; then
  echo "$planning" | jq -r '.issues[] | "\(.key)|\(.fields.summary // "N/A")|\(.fields.status.name // "N/A")"' | head -10 | while IFS='|' read -r key sum status; do
    echo "| $(jira_link "$key") | ${sum:0:45} | $status |"
  done
  [[ "$planning_count" -gt 10 ]] && echo "| ... | +$((planning_count - 10)) more | |"
else
  echo "| - | None in planning | - |"
fi

echo ""

# ============================================
# Recently Completed
# ============================================
echo "### Recently Completed (Last 30 Days)"
echo "| Key | Summary |"
echo "|-----|---------|"

done_jql="project = PDCR AND status = Done AND resolved >= -30d"
done=$(jira_search "$done_jql" "key,summary")
done_count=$(echo "$done" | jq '.issues | length // 0')
done_count=${done_count:-0}

if [[ "$done_count" -gt 0 ]]; then
  echo "$done" | jq -r '.issues[] | "\(.key)|\(.fields.summary // "N/A")"' | head -10 | while IFS='|' read -r key sum; do
    echo "| $(jira_link "$key") | ${sum:0:50} |"
  done
else
  echo "| - | None completed in last 30 days |"
fi

echo ""
echo "---"
echo "**Active:** $active_count | **Planning:** $planning_count | **Completed (30d):** $done_count"
echo ""
echo "*Generated: $(date)*"
