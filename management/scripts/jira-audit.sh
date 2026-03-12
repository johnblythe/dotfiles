#!/bin/bash
# Jira Audit - Single ticket style guide check
# Usage: ./jira-audit.sh HEAL-123

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get ticket key BEFORE sourcing lib (lib consumes args)
TICKET_KEY="$1"

source "$SCRIPT_DIR/jira-lib.sh"

if [[ -z "$TICKET_KEY" ]]; then
  echo "Usage: jira-audit.sh <TICKET_KEY>"
  echo "Example: jira-audit.sh HEAL-123"
  exit 1
fi

echo "## Audit: $TICKET_KEY"
echo ""

# ============================================
# Fetch ticket data
# ============================================
ticket_data=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/${TICKET_KEY}?fields=summary,status,assignee,issuetype,customfield_10026,customfield_10014,description")

# Check if ticket exists
if echo "$ticket_data" | jq -e '.errorMessages' >/dev/null 2>&1; then
  echo "Error: Ticket not found or access denied"
  exit 1
fi

# Extract fields
summary=$(echo "$ticket_data" | jq -r '.fields.summary // "N/A"')
status=$(echo "$ticket_data" | jq -r '.fields.status.name // "N/A"')
assignee=$(echo "$ticket_data" | jq -r '.fields.assignee.displayName // "Unassigned"')
issue_type=$(echo "$ticket_data" | jq -r '.fields.issuetype.name // "N/A"')
story_points=$(echo "$ticket_data" | jq -r '.fields.customfield_10026 // "null"')
epic_link=$(echo "$ticket_data" | jq -r '.fields.customfield_10014 // "null"')
description=$(echo "$ticket_data" | jq -r '.fields.description // "null"')

echo "**Summary:** $summary"
echo "**Type:** $issue_type | **Status:** $status | **Assignee:** $assignee"
echo ""

# ============================================
# Style Guide Checks
# ============================================
echo "### Style Guide Compliance"
echo "| Check | Status | Notes |"
echo "|-------|--------|-------|"

recommendations=()

# 1. Story Points
if [[ "$story_points" == "null" || "$story_points" == "" ]]; then
  echo "| Has story points | FAIL | Missing |"
  recommendations+=("Add story points estimate (1-4)")
else
  echo "| Has story points | PASS | $story_points pts |"

  # 2. Points <= 4
  pts_int=$(echo "$story_points" | cut -d. -f1)
  if [[ "$pts_int" -gt 4 ]]; then
    echo "| Points <= 4 | FAIL | $pts_int pts |"
    recommendations+=("Break down into smaller tickets (max 4 pts per style guide)")
  else
    echo "| Points <= 4 | PASS | |"
  fi
fi

# 3. Assignee
if [[ "$assignee" == "Unassigned" ]]; then
  echo "| Has assignee | FAIL | Unassigned |"
  recommendations+=("Assign to team member")
else
  echo "| Has assignee | PASS | $assignee |"
fi

# 4. Epic Link
if [[ "$epic_link" == "null" || "$epic_link" == "" ]]; then
  if [[ "$issue_type" != "Epic" && "$issue_type" != "Initiative" && "$issue_type" != "Theme" ]]; then
    echo "| Has epic link | WARN | No parent epic |"
    recommendations+=("Link to parent epic for tracking")
  else
    echo "| Has epic link | N/A | (Is an Epic/Initiative) |"
  fi
else
  echo "| Has epic link | PASS | $epic_link |"
fi

# 5. Acceptance Criteria (check description for keywords)
if [[ "$description" == "null" || -z "$description" ]]; then
  echo "| Has description | FAIL | Empty |"
  recommendations+=("Add description with acceptance criteria")
else
  # Check for AC keywords
  if echo "$description" | jq -r '.' 2>/dev/null | grep -qiE "acceptance|criteria|given.*when.*then|should|must"; then
    echo "| Has acceptance criteria | PASS | Found AC keywords |"
  else
    echo "| Has acceptance criteria | WARN | No clear AC found |"
    recommendations+=("Add clear acceptance criteria (Given/When/Then or checklist)")
  fi
fi

# 6. Summary quality (check if too vague)
word_count=$(echo "$summary" | wc -w | tr -d ' ')
if [[ "$word_count" -lt 3 ]]; then
  echo "| Summary quality | WARN | Too short ($word_count words) |"
  recommendations+=("Make summary more descriptive")
elif echo "$summary" | grep -qiE "^(fix|update|change|do|misc|todo)$"; then
  echo "| Summary quality | WARN | Too vague |"
  recommendations+=("Make summary more specific")
else
  echo "| Summary quality | PASS | |"
fi

echo ""

# ============================================
# Recommendations
# ============================================
if [[ ${#recommendations[@]} -gt 0 ]]; then
  echo "### Recommendations"
  for rec in "${recommendations[@]}"; do
    echo "- $rec"
  done
else
  echo "### Result"
  echo "Ticket meets style guide requirements."
fi

echo ""
echo "*Audited: $(date)*"
