#!/bin/bash
# Jira Burndown - Sprint progress stats
# Usage: ./jira-burndown.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "Sprint Burndown"

# ============================================
# Get sprint info
# ============================================
SPRINT_ID=$(get_active_sprint_id)
SPRINT_NAME=$(acli jira board list-sprints --id "$BOARD_ID" --state active --csv 2>/dev/null | tail -1 | cut -d',' -f2)

if [[ -z "$SPRINT_ID" ]]; then
  echo "No active sprint found."
  exit 1
fi

# Get sprint dates
sprint_info=$(curl -s -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/agile/1.0/sprint/${SPRINT_ID}" 2>/dev/null)

start_date=$(echo "$sprint_info" | jq -r '.startDate // empty' | cut -dT -f1)
end_date=$(echo "$sprint_info" | jq -r '.endDate // empty' | cut -dT -f1)

echo "**Sprint:** ${SPRINT_NAME:-$SPRINT_ID}"
echo "**Dates:** $start_date → $end_date"
echo ""

# ============================================
# Calculate progress
# ============================================
total_jql="project = $PROJECT AND sprint = $SPRINT_ID"
done_jql="project = $PROJECT AND sprint = $SPRINT_ID AND status = Done"

total_pts=$(jira_sum_points "$total_jql")
done_pts=$(jira_sum_points "$done_jql")
remaining=$((total_pts - done_pts))

total_count=$(jira_count "$total_jql")
done_count=$(jira_count "$done_jql")

# Calculate days
today=$(date +%Y-%m-%d)
if [[ -n "$start_date" && -n "$end_date" ]]; then
  start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null || date -d "$start_date" "+%s" 2>/dev/null)
  end_epoch=$(date -j -f "%Y-%m-%d" "$end_date" "+%s" 2>/dev/null || date -d "$end_date" "+%s" 2>/dev/null)
  today_epoch=$(date "+%s")

  total_days=$(( (end_epoch - start_epoch) / 86400 ))
  days_elapsed=$(( (today_epoch - start_epoch) / 86400 ))
  days_remaining=$(( (end_epoch - today_epoch) / 86400 ))

  [[ "$days_remaining" -lt 0 ]] && days_remaining=0
  [[ "$days_elapsed" -lt 0 ]] && days_elapsed=0
else
  total_days=14
  days_elapsed=7
  days_remaining=7
fi

# ============================================
# Progress display
# ============================================
echo "### Progress"
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total | $total_pts pts ($total_count items) |"
echo "| Done | $done_pts pts ($done_count items) |"
echo "| Remaining | $remaining pts ($((total_count - done_count)) items) |"
echo ""

# Percentage
if [[ "$total_pts" -gt 0 ]]; then
  pct=$((done_pts * 100 / total_pts))
else
  pct=0
fi

# ASCII progress bar
bar_width=20
filled=$((pct * bar_width / 100))
empty=$((bar_width - filled))
bar=$(printf '%*s' "$filled" | tr ' ' '█')$(printf '%*s' "$empty" | tr ' ' '░')

echo "### Burndown"
echo "\`\`\`"
echo "[$bar] $pct%"
echo "\`\`\`"
echo ""

echo "**Time:** Day $days_elapsed of $total_days ($days_remaining days left)"
echo ""

# ============================================
# Pace check
# ============================================
echo "### Pace"

if [[ "$days_elapsed" -gt 0 && "$total_pts" -gt 0 ]]; then
  # Ideal pace
  ideal_done=$((total_pts * days_elapsed / total_days))

  # Actual vs ideal
  diff=$((done_pts - ideal_done))

  if [[ "$diff" -ge 0 ]]; then
    echo "✅ **On track** - $done_pts pts done vs $ideal_done ideal (+$diff)"
  else
    echo "⚠️ **Behind** - $done_pts pts done vs $ideal_done ideal ($diff)"
  fi

  # Required pace to finish
  if [[ "$days_remaining" -gt 0 && "$remaining" -gt 0 ]]; then
    needed_per_day=$(echo "scale=1; $remaining / $days_remaining" | bc 2>/dev/null || echo "?")
    echo "📈 Need **$needed_per_day pts/day** to complete remaining work"
  fi
else
  echo "- Insufficient data for pace calculation"
fi

echo ""
echo "*Generated: $(date)*"
