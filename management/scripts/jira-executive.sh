#!/bin/bash
# Jira Executive - High-level stakeholder summary
# Usage: ./jira-executive.sh [--team NAME]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-lib.sh"

print_header "Executive Summary"

# ============================================
# Initiative Status
# ============================================
echo "### 📊 Initiative Status"

active_jql="project = PDCR AND status in (Development, \"In Progress\", \"To Do\")"
active=$(jira_search "$active_jql" "key,summary,status")
active_count=$(echo "$active" | jq '.issues | length // 0')
active_count=${active_count:-0}

done_30d_jql="project = PDCR AND status = Done AND resolved >= -30d"
done_30d=$(jira_search "$done_30d_jql" "key")
done_30d_count=$(echo "$done_30d" | jq '.issues | length // 0')
done_30d_count=${done_30d_count:-0}

echo "- **Active initiatives:** $active_count"
echo "- **Completed (30 days):** $done_30d_count"
echo ""

# Top 5 active
if [[ "$active_count" -gt 0 ]]; then
  echo "**Top Active:**"
  echo "$active" | jq -r '.issues[0:5][] | "- \(.key): \((.fields.summary // "No summary") | .[0:50]) [\(.fields.status.name)]"' 2>/dev/null
  echo ""
fi

# ============================================
# Sprint Health
# ============================================
echo "### 🏃 Sprint Health ($PROJECT)"

sprint_jql="project = $PROJECT AND sprint in openSprints()"
total_pts=$(jira_sum_points "$sprint_jql")
done_pts=$(jira_sum_points "$sprint_jql AND status = Done")

if [[ "$total_pts" -gt 0 ]]; then
  pct=$((done_pts * 100 / total_pts))
else
  pct=0
fi

# Get days info
SPRINT_ID=$(get_active_sprint_id)
if [[ -n "$SPRINT_ID" ]]; then
  sprint_info=$(curl -s -H "Content-Type: application/json" \
    -u "${JIRA_USER}:${JIRA_TOKEN}" \
    "${JIRA_URL}/rest/agile/1.0/sprint/${SPRINT_ID}" 2>/dev/null)
  end_date=$(echo "$sprint_info" | jq -r '.endDate // empty' | cut -dT -f1)
  if [[ -n "$end_date" ]]; then
    end_epoch=$(date -j -f "%Y-%m-%d" "$end_date" "+%s" 2>/dev/null || date -d "$end_date" "+%s" 2>/dev/null)
    today_epoch=$(date "+%s")
    days_left=$(( (end_epoch - today_epoch) / 86400 ))
    [[ "$days_left" -lt 0 ]] && days_left=0
  fi
fi

echo "- **Progress:** $done_pts / $total_pts pts ($pct%)"
echo "- **Days remaining:** ${days_left:-?}"

# Health indicator
if [[ "$pct" -ge 70 ]]; then
  echo "- **Status:** 🟢 On Track"
elif [[ "$pct" -ge 40 ]]; then
  echo "- **Status:** 🟡 At Risk"
else
  echo "- **Status:** 🔴 Behind"
fi
echo ""

# ============================================
# Top Risks
# ============================================
echo "### ⚠️ Top Risks"

# Large items not started
large_jql="project = $PROJECT AND sprint in openSprints() AND \"Story Points[Number]\" >= 3 AND status = \"To Do\""
large=$(jira_search "$large_jql" "key,summary,customfield_10026")
large_count=$(echo "$large" | jq '.issues | length // 0')
large_count=${large_count:-0}

# Stale items
stale_jql="project = $PROJECT AND sprint in openSprints() AND status = \"In Progress\" AND updated < -3d"
stale=$(jira_search "$stale_jql" "key")
stale_count=$(echo "$stale" | jq '.issues | length // 0')
stale_count=${stale_count:-0}

# Blocked
blocked_jql="project = $PROJECT AND sprint in openSprints() AND (status = Blocked OR labels = blocked)"
blocked=$(jira_search "$blocked_jql" "key")
blocked_count=$(echo "$blocked" | jq '.issues | length // 0')
blocked_count=${blocked_count:-0}

risks=0
if [[ "$large_count" -gt 0 ]]; then
  echo "- **$large_count large items** (3+ pts) not yet started"
  risks=$((risks + 1))
fi
if [[ "$stale_count" -gt 0 ]]; then
  echo "- **$stale_count items stale** (In Progress >3 days, no update)"
  risks=$((risks + 1))
fi
if [[ "$blocked_count" -gt 0 ]]; then
  echo "- **$blocked_count items blocked**"
  risks=$((risks + 1))
fi
if [[ "$risks" -eq 0 ]]; then
  echo "- No significant risks identified"
fi
echo ""

# ============================================
# Velocity Trend
# ============================================
echo "### 📈 Velocity Trend"

TRENDS_FILE="${SCRIPT_DIR}/../jira-data/trends/velocity.csv"
if [[ -f "$TRENDS_FILE" ]]; then
  # Last 4 sprints
  echo "| Sprint | Committed | Delivered | Accuracy |"
  echo "|--------|-----------|-----------|----------|"
  tail -5 "$TRENDS_FILE" | head -4 | while IFS=',' read -r date sprint sid committed delivered acc rest; do
    [[ "$sprint" == "sprint" ]] && continue
    pct_acc=$((delivered * 100 / (committed > 0 ? committed : 1)))
    echo "| $sprint | $committed | $delivered | ${pct_acc}% |"
  done
  echo ""

  # Trend direction
  recent=$(tail -2 "$TRENDS_FILE" | head -1 | cut -d',' -f5)
  previous=$(tail -3 "$TRENDS_FILE" | head -1 | cut -d',' -f5)
  if [[ "${recent:-0}" -gt "${previous:-0}" ]]; then
    echo "**Trend:** 📈 Improving"
  elif [[ "${recent:-0}" -lt "${previous:-0}" ]]; then
    echo "**Trend:** 📉 Declining"
  else
    echo "**Trend:** ➡️ Stable"
  fi
else
  echo "- No velocity data available yet"
fi
echo ""

# ============================================
# Key Wins
# ============================================
echo "### 🏆 Recent Wins (7 days)"

wins_jql="project = $PROJECT AND status = Done AND resolved >= -7d"
wins=$(jira_search "$wins_jql" "key,summary")
wins_count=$(echo "$wins" | jq '.issues | length // 0')
wins_count=${wins_count:-0}

if [[ "$wins_count" -gt 0 ]]; then
  echo "$wins" | jq -r '.issues[0:5][] | "- \(.key): \((.fields.summary // "No summary") | .[0:50])"' 2>/dev/null
else
  echo "- None in last 7 days"
fi
echo ""

echo "*Generated: $(date)*"
