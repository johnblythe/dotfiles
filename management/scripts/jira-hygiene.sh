#!/bin/bash
# Jira Hygiene Audit
# Usage: ./jira-hygiene.sh [--team NAME] [--board ID] [--project KEY]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh" "$@"

# ============================================
# Output
# ============================================
print_header "Hygiene Report"

# ============================================
# 1. Missing Story Points
# ============================================
echo "### Missing Story Points"
missing_jql="project = $PROJECT AND sprint in openSprints() AND \"Story Points[Number]\" is EMPTY AND issuetype in (Story, Task, Bug)"
missing=$(acli jira workitem search --jql "$missing_jql" --fields "key,summary,assignee,status" --csv 2>/dev/null)
missing_count=$(echo "$missing" | tail -n +2 | grep -v '^$' | wc -l | tr -d ' ')

if [[ "$missing_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee | Status |"
  echo "|-----|---------|----------|--------|"
  echo "$missing" | tail -n +2 | while IFS=',' read -r key assignee status summary; do
    echo "| $key | ${summary:0:40} | $assignee | $status |"
  done
else
  echo "None"
fi
echo ""
echo "**Count:** $missing_count"
echo ""

# ============================================
# 2. Unassigned in Sprint
# ============================================
echo "### Unassigned in Sprint"
unassigned_jql="project = $PROJECT AND sprint in openSprints() AND assignee is EMPTY"
unassigned=$(acli jira workitem search --jql "$unassigned_jql" --fields "key,summary,status" --csv 2>/dev/null)
unassigned_count=$(echo "$unassigned" | tail -n +2 | grep -v '^$' | wc -l | tr -d ' ')

if [[ "$unassigned_count" -gt 0 ]]; then
  echo "| Key | Summary | Status |"
  echo "|-----|---------|--------|"
  echo "$unassigned" | tail -n +2 | while IFS=',' read -r key status summary; do
    echo "| $key | ${summary:0:40} | $status |"
  done
else
  echo "None"
fi
echo ""
echo "**Count:** $unassigned_count"
echo ""

# ============================================
# 3. Stale In Progress (>5 days)
# ============================================
echo "### Stale In Progress (>5 days)"
stale_ip_jql="project = $PROJECT AND status = \"In Progress\" AND updated < -5d"
stale_ip=$(acli jira workitem search --jql "$stale_ip_jql" --fields "key,summary,assignee" --csv 2>/dev/null)
stale_ip_count=$(echo "$stale_ip" | tail -n +2 | grep -v '^$' | wc -l | tr -d ' ')

if [[ "$stale_ip_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee |"
  echo "|-----|---------|----------|"
  echo "$stale_ip" | tail -n +2 | while IFS=',' read -r key assignee summary; do
    echo "| $key | ${summary:0:40} | $assignee |"
  done
else
  echo "None"
fi
echo ""
echo "**Count:** $stale_ip_count"
echo ""

# ============================================
# 4. Stale Code Review (>3 days)
# ============================================
echo "### Stale Code Review (>3 days)"
stale_cr_jql="project = $PROJECT AND status = \"Code Review\" AND updated < -3d"
stale_cr=$(acli jira workitem search --jql "$stale_cr_jql" --fields "key,summary,assignee" --csv 2>/dev/null)
stale_cr_count=$(echo "$stale_cr" | tail -n +2 | grep -v '^$' | wc -l | tr -d ' ')

if [[ "$stale_cr_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee |"
  echo "|-----|---------|----------|"
  echo "$stale_cr" | tail -n +2 | while IFS=',' read -r key assignee summary; do
    echo "| $key | ${summary:0:40} | $assignee |"
  done
else
  echo "None"
fi
echo ""
echo "**Count:** $stale_cr_count"
echo ""

# ============================================
# Summary
# ============================================
echo "---"
echo "### Summary"

total_violations=$((missing_count + unassigned_count + stale_ip_count + stale_cr_count))
health_score=$((100 - (missing_count * 5) - (unassigned_count * 2) - (stale_ip_count * 4) - (stale_cr_count * 3)))
[[ $health_score -lt 0 ]] && health_score=0

echo "- **Total Violations:** $total_violations"
echo "- **Health Score:** $health_score/100"
echo ""
echo "*Generated: $(date)*"
