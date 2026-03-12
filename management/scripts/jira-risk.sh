#!/bin/bash
# Jira Risk - Items at risk of missing sprint
# Usage: ./jira-risk.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "At-Risk Items"

RISK_COUNT=0

# ============================================
# Large items not started (3+ pts, still To Do)
# ============================================
echo "### 🎯 Large Items Not Started (3+ pts)"

large_jql="project = $PROJECT AND sprint in openSprints() AND \"Story Points[Number]\" >= 3 AND status = \"To Do\""
large_items=$(jira_search "$large_jql" "key,summary,assignee,customfield_10026")
large_count=$(echo "$large_items" | jq '.issues | length // 0')
large_count=${large_count:-0}

if [[ "$large_count" -gt 0 ]]; then
  echo "$large_items" | jq -r '.issues[] | "- \(.key) (\(.fields.customfield_10026 // 0) pts): \((.fields.summary // "No summary") | .[0:40]) [@\(.fields.assignee.displayName // "unassigned")]"' 2>/dev/null
  RISK_COUNT=$((RISK_COUNT + large_count))
else
  echo "- None"
fi
echo ""

# ============================================
# Stale In Progress (no update 3+ days)
# ============================================
echo "### 🐌 Stale In Progress (3+ days)"

stale_jql="project = $PROJECT AND sprint in openSprints() AND status = \"In Progress\" AND updated < -3d"
stale_items=$(jira_search "$stale_jql" "key,summary,assignee,customfield_10026")
stale_count=$(echo "$stale_items" | jq '.issues | length // 0')
stale_count=${stale_count:-0}

if [[ "$stale_count" -gt 0 ]]; then
  echo "$stale_items" | jq -r '.issues[] | "- \(.key) (\(.fields.customfield_10026 // 0) pts): \((.fields.summary // "No summary") | .[0:40]) [@\(.fields.assignee.displayName // "unassigned")]"' 2>/dev/null
  RISK_COUNT=$((RISK_COUNT + stale_count))
else
  echo "- None"
fi
echo ""

# ============================================
# Unassigned with points
# ============================================
echo "### 👻 Unassigned Work"

unassigned_jql="project = $PROJECT AND sprint in openSprints() AND assignee is EMPTY AND status != Done"
unassigned_items=$(jira_search "$unassigned_jql" "key,summary,customfield_10026")
unassigned_count=$(echo "$unassigned_items" | jq '.issues | length // 0')
unassigned_count=${unassigned_count:-0}
unassigned_pts=$(echo "$unassigned_items" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0')

if [[ "$unassigned_count" -gt 0 ]]; then
  echo "**$unassigned_count items (${unassigned_pts:-0} pts) need assignment:**"
  echo "$unassigned_items" | jq -r '.issues[] | "- \(.key) (\(.fields.customfield_10026 // 0) pts): \((.fields.summary // "No summary") | .[0:40])"' 2>/dev/null | head -10
  RISK_COUNT=$((RISK_COUNT + unassigned_count))
else
  echo "- None"
fi
echo ""

# ============================================
# Items in QA/Review too long (2+ days)
# ============================================
echo "### 🔍 Stuck in Review/QA (2+ days)"

review_jql="project = $PROJECT AND sprint in openSprints() AND status in (\"Code Review\", \"QA\", \"Review\") AND updated < -2d"
review_items=$(jira_search "$review_jql" "key,summary,assignee")
review_count=$(echo "$review_items" | jq '.issues | length // 0')
review_count=${review_count:-0}

if [[ "$review_count" -gt 0 ]]; then
  echo "$review_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:40]) [@\(.fields.assignee.displayName // "unassigned")]"' 2>/dev/null
  RISK_COUNT=$((RISK_COUNT + review_count))
else
  echo "- None"
fi
echo ""

# ============================================
# Summary
# ============================================
echo "---"
if [[ "$RISK_COUNT" -gt 0 ]]; then
  echo "**⚠️ Total at-risk items: $RISK_COUNT**"
else
  echo "**✅ No items at risk**"
fi
echo ""
echo "*Generated: $(date)*"
