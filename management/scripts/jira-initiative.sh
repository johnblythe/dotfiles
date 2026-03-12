#!/bin/bash
# Jira Initiative - PDCR item status with linked work
# Usage: ./jira-initiative.sh PDCR-123

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get initiative key BEFORE sourcing lib
INITIATIVE_KEY="$1"

source "$SCRIPT_DIR/jira-lib.sh"

if [[ -z "$INITIATIVE_KEY" ]]; then
  echo "Usage: jira-initiative.sh <PDCR-KEY>"
  echo "Example: jira-initiative.sh PDCR-123"
  exit 1
fi

# ============================================
# Fetch initiative data
# ============================================
init_data=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/${INITIATIVE_KEY}?fields=summary,status,assignee,issuetype,description")

if echo "$init_data" | jq -e '.errorMessages' >/dev/null 2>&1; then
  echo "Error: Initiative not found or access denied"
  exit 1
fi

summary=$(echo "$init_data" | jq -r '.fields.summary // "N/A"')
status=$(echo "$init_data" | jq -r '.fields.status.name // "N/A"')
assignee=$(echo "$init_data" | jq -r '.fields.assignee.displayName // "Unassigned"')
issue_type=$(echo "$init_data" | jq -r '.fields.issuetype.name // "N/A"')

print_header "Initiative: $INITIATIVE_KEY"
echo "**$summary**"
echo "Type: $issue_type | Status: $status | Owner: $assignee"
echo ""

# ============================================
# Find linked issues
# ============================================
echo "### Linked Work"

# Get issues linked to this initiative (direct links + children of linked epics)
jql="issue in linkedIssues(${INITIATIVE_KEY}) OR parent in linkedIssues(${INITIATIVE_KEY})"
linked=$(jira_search "$jql" "key,summary,status,issuetype,customfield_10026")

total=$(echo "$linked" | jq '.issues | length // 0')
total=${total:-0}

if [[ "$total" -eq 0 ]]; then
  echo "No linked issues found."
  echo ""
else
  done_count=$(echo "$linked" | jq '[.issues[] | select(.fields.status.name == "Done")] | length')
  ip_count=$(echo "$linked" | jq '[.issues[] | select(.fields.status.name == "In Progress")] | length')

  total_pts=$(echo "$linked" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0')
  done_pts=$(echo "$linked" | jq '[.issues[] | select(.fields.status.name == "Done") | .fields.customfield_10026 // 0] | add // 0')

  echo "| Status | Count | Points |"
  echo "|--------|-------|--------|"
  echo "| Done | $done_count | ${done_pts:-0} pts |"
  echo "| In Progress | $ip_count | - |"
  echo "| Other | $((total - done_count - ip_count)) | - |"
  echo "| **Total** | **$total** | **${total_pts:-0} pts** |"
  echo ""

  # Progress bar
  if [[ "$total" -gt 0 ]]; then
    pct=$((done_count * 100 / total))
    echo "**Progress:** $pct% complete ($done_count/$total items)"
    echo ""
  fi

  # ============================================
  # Active Work
  # ============================================
  echo "### Active Work (In Progress)"
  active=$(echo "$linked" | jq -r '.issues[] | select(.fields.status.name == "In Progress") | "\(.key)|\(.fields.summary // "No summary")"')

  if [[ -z "$active" ]]; then
    echo "None"
  else
    echo "| Key | Summary |"
    echo "|-----|---------|"
    echo "$active" | head -10 | while IFS='|' read -r key sum; do
      echo "| $key | ${sum:0:50} |"
    done
  fi
  echo ""

  # ============================================
  # Blocked / Stale
  # ============================================
  echo "### Needs Attention"

  # Stale in progress (>5 days)
  stale_jql="(issue in linkedIssues(${INITIATIVE_KEY}) OR parent in linkedIssues(${INITIATIVE_KEY})) AND status = \"In Progress\" AND updated < -5d"
  stale=$(jira_search "$stale_jql" "key,summary,assignee")
  stale_count=$(echo "$stale" | jq '.issues | length // 0')
  stale_count=${stale_count:-0}

  if [[ "$stale_count" -gt 0 ]]; then
    echo "**Stale (In Progress >5 days):**"
    echo "$stale" | jq -r '.issues[] | "- \(.key): \(.fields.summary // "No summary")[0:40]"' 2>/dev/null | head -5
  fi

  # Unassigned
  unassigned_jql="(issue in linkedIssues(${INITIATIVE_KEY}) OR parent in linkedIssues(${INITIATIVE_KEY})) AND assignee is EMPTY AND status != Done"
  unassigned=$(jira_search "$unassigned_jql" "key")
  unassigned_count=$(echo "$unassigned" | jq '.issues | length // 0')
  unassigned_count=${unassigned_count:-0}

  if [[ "$unassigned_count" -gt 0 ]]; then
    echo "**Unassigned:** $unassigned_count items"
  fi

  if [[ "$stale_count" -eq 0 && "$unassigned_count" -eq 0 ]]; then
    echo "None - all work is progressing normally"
  fi
fi

echo ""
echo "*Generated: $(date)*"
