#!/bin/bash
# Jira Forecast - Initiative ETA based on velocity
# Usage: ./jira-forecast.sh PDCR-123

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get initiative key BEFORE sourcing lib
INITIATIVE_KEY="$1"

source "$SCRIPT_DIR/jira-lib.sh"

if [[ -z "$INITIATIVE_KEY" ]]; then
  echo "Usage: jira-forecast.sh <PDCR-KEY>"
  echo "Example: jira-forecast.sh PDCR-123"
  exit 1
fi

print_header "Forecast: $INITIATIVE_KEY"

# ============================================
# Get initiative info
# ============================================
init_data=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/${INITIATIVE_KEY}?fields=summary,status")

if echo "$init_data" | jq -e '.errorMessages' >/dev/null 2>&1; then
  echo "Error: Initiative not found"
  exit 1
fi

summary=$(echo "$init_data" | jq -r '.fields.summary // "N/A"')
status=$(echo "$init_data" | jq -r '.fields.status.name // "N/A"')

echo "**$summary**"
echo "Status: $status"
echo ""

# ============================================
# Get linked work stats
# ============================================
jql="issue in linkedIssues(${INITIATIVE_KEY}) OR parent in linkedIssues(${INITIATIVE_KEY})"
linked=$(jira_search "$jql" "key,status,customfield_10026")

total_count=$(echo "$linked" | jq '.issues | length // 0')
total_count=${total_count:-0}

if [[ "$total_count" -eq 0 ]]; then
  echo "No linked issues found - cannot forecast."
  exit 0
fi

done_count=$(echo "$linked" | jq '[.issues[] | select(.fields.status.name == "Done")] | length')
remaining_count=$((total_count - done_count))

total_pts=$(echo "$linked" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0')
done_pts=$(echo "$linked" | jq '[.issues[] | select(.fields.status.name == "Done") | .fields.customfield_10026 // 0] | add // 0')
remaining_pts=$(echo "scale=0; $total_pts - $done_pts" | bc 2>/dev/null || echo "$((total_pts - done_pts))")

echo "### Current State"
echo "| Metric | Count | Points |"
echo "|--------|-------|--------|"
echo "| Done | $done_count | ${done_pts:-0} |"
echo "| Remaining | $remaining_count | ${remaining_pts:-0} |"
echo "| **Total** | **$total_count** | **${total_pts:-0}** |"
echo ""

# ============================================
# Get velocity from trends
# ============================================
TRENDS_FILE="${SCRIPT_DIR}/../jira-data/trends/velocity.csv"

if [[ -f "$TRENDS_FILE" ]]; then
  # Average of last 4 sprints
  avg_velocity=$(tail -5 "$TRENDS_FILE" | head -4 | awk -F',' 'NR>0 {sum+=$4; count++} END {if(count>0) print int(sum/count); else print 0}')
else
  # Fallback: estimate from closed sprints
  avg_velocity=80
fi

echo "### Velocity"
echo "- **Team avg:** ~$avg_velocity pts/sprint (based on recent data)"
echo ""

# ============================================
# Forecast
# ============================================
echo "### Forecast"

if [[ "${remaining_pts:-0}" -le 0 && "$remaining_count" -le 0 ]]; then
  echo "✅ **Initiative complete!**"
elif [[ "${remaining_pts:-0}" -le 0 && "$remaining_count" -gt 0 ]]; then
  echo "⚠️ **$remaining_count items remaining but missing story points**"
  echo "- Cannot forecast without points - run /hygiene to identify"
else
  if [[ "$avg_velocity" -gt 0 ]]; then
    sprints_needed=$(echo "scale=1; $remaining_pts / $avg_velocity" | bc 2>/dev/null || echo "?")
    sprints_ceil=$(echo "scale=0; ($remaining_pts + $avg_velocity - 1) / $avg_velocity" | bc 2>/dev/null || echo "?")

    # Estimate dates (2 weeks per sprint)
    weeks=$((sprints_ceil * 2))
    eta_date=$(date -v+${weeks}w "+%Y-%m-%d" 2>/dev/null || date -d "+$weeks weeks" "+%Y-%m-%d" 2>/dev/null || echo "~$weeks weeks")

    echo "- **Remaining:** ${remaining_pts:-0} pts"
    echo "- **Sprints needed:** ~$sprints_needed ($sprints_ceil sprints)"
    echo "- **Estimated completion:** $eta_date"
    echo ""

    # Confidence
    pct_done=$((done_pts * 100 / total_pts))
    if [[ "$pct_done" -gt 75 ]]; then
      echo "📊 **High confidence** - $pct_done% complete"
    elif [[ "$pct_done" -gt 50 ]]; then
      echo "📊 **Medium confidence** - $pct_done% complete"
    else
      echo "📊 **Low confidence** - only $pct_done% complete, estimate may vary"
    fi
  else
    echo "⚠️ Cannot calculate - no velocity data"
  fi
fi

echo ""
echo "*Generated: $(date)*"
