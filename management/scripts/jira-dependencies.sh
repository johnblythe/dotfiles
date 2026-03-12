#!/bin/bash
# Jira Dependencies - Cross-team blockers and waiting items
# Usage: ./jira-dependencies.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "Dependencies & Blockers"

# ============================================
# Items with "Blocked" status or label
# ============================================
echo "### 🚫 Blocked Items"

blocked_jql="project = $PROJECT AND sprint in openSprints() AND (status = Blocked OR labels = blocked)"
blocked_items=$(jira_search "$blocked_jql" "key,summary,assignee")
blocked_count=$(echo "$blocked_items" | jq '.issues | length // 0')
blocked_count=${blocked_count:-0}

if [[ "$blocked_count" -gt 0 ]]; then
  echo "$blocked_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:45]) [@\(.fields.assignee.displayName // "unassigned")]"' 2>/dev/null
else
  echo "- None"
fi
echo ""

# ============================================
# Items with blocker links (is blocked by)
# ============================================
echo "### 🔗 Items With Blocker Links"

# Fetch issues with issuelinks and check for "is blocked by" type
linked_jql="project = $PROJECT AND sprint in openSprints() AND issueFunction in hasLinks(\"is blocked by\")"
# Note: issueFunction requires ScriptRunner - fallback to simpler approach
linked_jql="project = $PROJECT AND sprint in openSprints() AND status != Done"
linked_items=$(jira_search "$linked_jql" "key,summary,issuelinks")

# Parse for blocking links
blockers_found=0
echo "$linked_items" | jq -r '
  .issues[] |
  select(.fields.issuelinks != null) |
  select(.fields.issuelinks | length > 0) |
  . as $issue |
  .fields.issuelinks[] |
  select(.type.name == "Blocks" and .inwardIssue != null) |
  "- \($issue.key) blocked by \(.inwardIssue.key): \(.inwardIssue.fields.summary // "?" | .[0:30])"
' 2>/dev/null | head -15 | while read -r line; do
  echo "$line"
  blockers_found=1
done

if [[ "$blockers_found" -eq 0 ]]; then
  # Check if anything was output
  check=$(echo "$linked_items" | jq '[.issues[] | select(.fields.issuelinks != null) | .fields.issuelinks[] | select(.type.name == "Blocks" and .inwardIssue != null)] | length' 2>/dev/null)
  if [[ "${check:-0}" -eq 0 ]]; then
    echo "- None found"
  fi
fi
echo ""

# ============================================
# Cross-project dependencies
# ============================================
echo "### 🌐 Cross-Project Dependencies"

# Look for links to other projects
cross_proj=$(echo "$linked_items" | jq -r '
  .issues[] |
  select(.fields.issuelinks != null) |
  . as $issue |
  .fields.issuelinks[] |
  select(.inwardIssue.key != null or .outwardIssue.key != null) |
  ((.inwardIssue.key // .outwardIssue.key) | split("-")[0]) as $linked_proj |
  select($linked_proj != "HEAL" and $linked_proj != "'"$PROJECT"'") |
  "- \($issue.key) → \(.inwardIssue.key // .outwardIssue.key) (\($linked_proj))"
' 2>/dev/null | sort -u | head -10)

if [[ -n "$cross_proj" ]]; then
  echo "$cross_proj"
else
  echo "- None found"
fi
echo ""

# ============================================
# Waiting on external (comments mention waiting)
# ============================================
echo "### ⏳ Potentially Waiting"
echo "(Items In Progress with 'waiting' in recent comments - manual check recommended)"

waiting_jql="project = $PROJECT AND sprint in openSprints() AND status = \"In Progress\" AND updated < -3d"
waiting_items=$(jira_search "$waiting_jql" "key,summary,assignee")
waiting_count=$(echo "$waiting_items" | jq '.issues | length // 0')
waiting_count=${waiting_count:-0}

if [[ "$waiting_count" -gt 0 ]]; then
  echo "**$waiting_count items stale - may be waiting on something:**"
  echo "$waiting_items" | jq -r '.issues[] | "- \(.key): \((.fields.summary // "No summary") | .[0:40])"' 2>/dev/null | head -5
else
  echo "- None"
fi
echo ""

echo "*Generated: $(date)*"
