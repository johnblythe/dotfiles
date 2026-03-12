#!/bin/bash
# Jira Capacity - Sprint planning helper
# Usage: ./jira-capacity.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "Sprint Capacity"

# ============================================
# Get all sprint items with assignee + points
# ============================================
sprint_jql="project = $PROJECT AND sprint in openSprints() AND status != Done"
sprint_items=$(jira_search "$sprint_jql" "key,assignee,customfield_10026,status")

total_items=$(echo "$sprint_items" | jq '.issues | length // 0')
total_items=${total_items:-0}

if [[ "$total_items" -eq 0 ]]; then
  echo "No items in current sprint."
  exit 0
fi

# ============================================
# Per-person breakdown
# ============================================
echo "### Load by Assignee"
echo "| Assignee | Items | Points | Status |"
echo "|----------|-------|--------|--------|"

# Get unique assignees and their stats
echo "$sprint_items" | jq -r '
  .issues | group_by(.fields.assignee.displayName // "Unassigned") |
  .[] |
  {
    name: (.[0].fields.assignee.displayName // "Unassigned"),
    count: length,
    points: ([.[].fields.customfield_10026 // 0] | add),
    in_progress: ([.[] | select(.fields.status.name == "In Progress")] | length),
    todo: ([.[] | select(.fields.status.name == "To Do")] | length)
  } |
  "\(.name)|\(.count)|\(.points)|\(.in_progress) IP, \(.todo) TD"
' 2>/dev/null | sort -t'|' -k3 -rn | while IFS='|' read -r name count pts status; do
  echo "| $name | $count | ${pts:-0} pts | $status |"
done

echo ""

# ============================================
# Team totals
# ============================================
total_pts=$(echo "$sprint_items" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0')
assignee_count=$(echo "$sprint_items" | jq '[.issues[].fields.assignee.displayName // "Unassigned"] | unique | length')
avg_pts=$(echo "scale=1; ${total_pts:-0} / ${assignee_count:-1}" | bc 2>/dev/null || echo "0")

unassigned_jql="project = $PROJECT AND sprint in openSprints() AND assignee is EMPTY AND status != Done"
unassigned=$(jira_search "$unassigned_jql" "customfield_10026")
unassigned_pts=$(echo "$unassigned" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0')
unassigned_count=$(echo "$unassigned" | jq '.issues | length // 0')

echo "### Summary"
echo "- **Total:** ${total_pts:-0} pts across $total_items items"
echo "- **Team members:** $assignee_count"
echo "- **Average load:** ${avg_pts:-0} pts/person"
echo "- **Unassigned:** ${unassigned_count:-0} items (${unassigned_pts:-0} pts)"
echo ""

# ============================================
# Recommendations
# ============================================
echo "### Recommendations"

# Find overloaded (>150% of avg)
threshold=$(echo "scale=0; $avg_pts * 15 / 10" | bc 2>/dev/null || echo "999")
overloaded=$(echo "$sprint_items" | jq -r --arg thresh "$threshold" '
  .issues | group_by(.fields.assignee.displayName // "Unassigned") |
  .[] |
  select(([.[].fields.customfield_10026 // 0] | add) > ($thresh | tonumber)) |
  {name: .[0].fields.assignee.displayName, pts: ([.[].fields.customfield_10026 // 0] | add)} |
  "- **\(.name)** has \(.pts) pts (above avg)"
' 2>/dev/null)

if [[ -n "$overloaded" ]]; then
  echo "$overloaded"
else
  echo "- Load appears balanced"
fi

if [[ "${unassigned_pts:-0}" -gt 0 ]]; then
  echo "- **${unassigned_pts} pts need assignment**"
fi

echo ""
echo "*Generated: $(date)*"
