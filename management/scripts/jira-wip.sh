#!/bin/bash
# WIP Detail Report
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh" "$@"

WIP_LIMIT=$(get_wip_limit)

echo "## Work In Progress - $(date +%Y-%m-%d)"
echo ""

wip_jql="project = $PROJECT AND sprint in openSprints() AND status = 'In Progress'"
wip_data=$(jira_search "$wip_jql" "key,summary,assignee" 200)
wip_count=$(echo "$wip_data" | jq '.issues | length // 0')

echo "**Limit:** $WIP_LIMIT | **Current:** $wip_count"
echo ""

# Group by assignee
echo "### By Assignee"
echo ""

echo "$wip_data" | jq -r '
  .issues
  | group_by(.fields.assignee.displayName // "Unassigned")
  | sort_by(-length)
  | .[]
  | "**\(.[0].fields.assignee.displayName // "Unassigned")** (\(length)):\n\([.[] | "- \(.key): \((.fields.summary // "?") | .[0:60])"] | join("\n"))\n"
'
