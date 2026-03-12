#!/bin/bash
# Jira Standup - Daily summary for standups
# Usage: ./jira-standup.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "Standup Summary"

# ============================================
# What got done (last 24h)
# ============================================
echo "### ✅ Completed (Last 24h)"

done_jql="project = $PROJECT AND status changed to Done after -1d"
done_items=$(jira_search "$done_jql" "key,summary,assignee")
done_count=$(echo "$done_items" | jq '.issues | length // 0')
done_count=${done_count:-0}

if [[ "$done_count" -gt 0 ]]; then
  echo "$done_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:50]) (@\(.fields.assignee.displayName // "unassigned"))"' 2>/dev/null | head -10
else
  echo "- None"
fi
echo ""

# ============================================
# What started (last 24h)
# ============================================
echo "### 🚀 Started (Last 24h)"

started_jql="project = $PROJECT AND status changed to \"In Progress\" after -1d"
started_items=$(jira_search "$started_jql" "key,summary,assignee")
started_count=$(echo "$started_items" | jq '.issues | length // 0')
started_count=${started_count:-0}

if [[ "$started_count" -gt 0 ]]; then
  echo "$started_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:50]) (@\(.fields.assignee.displayName // "unassigned"))"' 2>/dev/null | head -10
else
  echo "- None"
fi
echo ""

# ============================================
# What's stuck (In Progress, no update 2+ days)
# ============================================
echo "### ⚠️ Stuck (No Update 2+ Days)"

stuck_jql="project = $PROJECT AND sprint in openSprints() AND status = \"In Progress\" AND updated < -2d"
stuck_items=$(jira_search "$stuck_jql" "key,summary,assignee")
stuck_count=$(echo "$stuck_items" | jq '.issues | length // 0')
stuck_count=${stuck_count:-0}

if [[ "$stuck_count" -gt 0 ]]; then
  echo "$stuck_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:50]) (@\(.fields.assignee.displayName // "unassigned"))"' 2>/dev/null | head -10
else
  echo "- None"
fi
echo ""

# ============================================
# Needs help (unassigned in sprint)
# ============================================
echo "### 🆘 Needs Assignment"

unassigned_jql="project = $PROJECT AND sprint in openSprints() AND assignee is EMPTY AND status != Done"
unassigned_items=$(jira_search "$unassigned_jql" "key,summary,customfield_10026")
unassigned_count=$(echo "$unassigned_items" | jq '.issues | length // 0')
unassigned_count=${unassigned_count:-0}

if [[ "$unassigned_count" -gt 0 ]]; then
  echo "$unassigned_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:50]) (\(.fields.customfield_10026 // 0) pts)"' 2>/dev/null | head -10
else
  echo "- None"
fi
echo ""

# ============================================
# Quick stats
# ============================================
echo "---"
echo "**Today:** $done_count done | $started_count started | $stuck_count stuck | $unassigned_count unassigned"
echo ""
echo "*Generated: $(date)*"
