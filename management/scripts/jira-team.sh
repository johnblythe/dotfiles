#!/bin/bash
# Jira Team - Per-person workload and delivery
# Usage: ./jira-team.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh" "$@"

print_header "Team Report"

sprint_id=$(get_active_sprint_id)
sprint_name=$(get_active_sprint_name)

echo "**Sprint:** $sprint_name"
echo ""

# ============================================
# Get all sprint items with assignee and status
# ============================================
all_items=$(acli jira workitem search --jql "project = $PROJECT AND sprint = $sprint_id" --fields "key,assignee,status" --csv 2>/dev/null | tail -n +2)

# ============================================
# Current Sprint by Person
# ============================================
echo "### Current Sprint Load"
echo "| Assignee | Total | Done | In Prog | To Do | Other |"
echo "|----------|-------|------|---------|-------|-------|"

# Get unique assignees and process
assignees=$(echo "$all_items" | cut -d',' -f2 | sort -u | grep -v '^$')

while IFS= read -r assignee; do
  [[ -z "$assignee" ]] && continue

  # Filter and count
  person_items=$(echo "$all_items" | grep ",$assignee,")
  total=$(echo "$person_items" | wc -l | tr -d ' ')
  done_count=$(echo "$person_items" | grep -c ",Done$" 2>/dev/null); done_count=${done_count:-0}
  ip_count=$(echo "$person_items" | grep -c ",In Progress$" 2>/dev/null); ip_count=${ip_count:-0}
  todo_count=$(echo "$person_items" | grep -c ",To Do$" 2>/dev/null); todo_count=${todo_count:-0}
  other=$((total - done_count - ip_count - todo_count)); [[ $other -lt 0 ]] && other=0

  # Short name
  short_name=$(echo "$assignee" | cut -d'@' -f1)

  echo "| $short_name | $total | $done_count | $ip_count | $todo_count | $other |"
done <<< "$assignees"

# Unassigned
unassigned=$(echo "$all_items" | grep -E "^[^,]+,," | wc -l | tr -d ' ')
if [[ "$unassigned" -gt 0 ]]; then
  echo "| *unassigned* | $unassigned | - | - | - | - |"
fi

echo ""

# ============================================
# Summary Stats
# ============================================
echo "### Summary"

total_items=$(echo "$all_items" | grep -c "." 2>/dev/null || echo 1)
total_done=$(echo "$all_items" | grep -c ",Done$" 2>/dev/null || echo 0)
total_ip=$(echo "$all_items" | grep -c ",In Progress$" 2>/dev/null || echo 0)

pct=$((total_done * 100 / total_items))
echo "- **Total Items:** $total_items"
echo "- **Done:** $total_done ($pct%)"
echo "- **In Progress:** $total_ip"
echo "- **Unassigned:** $unassigned"
echo ""

# ============================================
# Flags
# ============================================
echo "### Flags"

while IFS= read -r assignee; do
  [[ -z "$assignee" ]] && continue
  count=$(echo "$all_items" | grep -c ",$assignee," 2>/dev/null || echo 0)
  if [[ "$count" -gt 8 ]]; then
    short_name=$(echo "$assignee" | cut -d'@' -f1)
    echo "- **$short_name** has $count items (high load)"
  fi
done <<< "$assignees"

if [[ "$unassigned" -gt 3 ]]; then
  echo "- **$unassigned items** unassigned in sprint"
fi

echo ""
echo "*Generated: $(date)*"
