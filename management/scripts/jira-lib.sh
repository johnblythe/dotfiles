#!/bin/bash
# Jira shared library - source this in other scripts
# Usage: source scripts/jira-lib.sh [--team NAME] [--board ID] [--project KEY]

# Determine paths - handle symlinks and both sourced/direct execution
_resolve_script_dir() {
  local source="${BASH_SOURCE[0]}"
  # Resolve symlinks
  while [[ -L "$source" ]]; do
    local dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}
SCRIPT_DIR="$(_resolve_script_dir)"

# Config paths
MGMT_DIR="${SCRIPT_DIR}/.."
CONFIG_FILE="${MGMT_DIR}/jira-data/config.yaml"
CREDS_FILE=~/.config/jiratui/config.yaml

# Validate config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  CONFIG_FILE=~/code/management/jira-data/config.yaml
fi

# ============================================
# Credentials (from jiratui config)
# ============================================
JIRA_USER=$(grep 'jira_api_username' "$CREDS_FILE" | sed "s/.*: *'//" | sed "s/'.*//")
JIRA_TOKEN=$(grep 'jira_api_token' "$CREDS_FILE" | sed "s/.*: *'//" | sed "s/'.*//")
JIRA_URL=$(grep 'jira_api_base_url' "$CREDS_FILE" | sed "s/.*: *'//" | sed "s/'.*//")

# ============================================
# Config parsing (simple grep-based, no yq)
# ============================================
get_team_config() {
  local team="$1"
  local field="$2"
  # Look for the team section, then find the field
  awk -v team="$team" -v field="$field" '
    /^  [a-z][a-z0-9-]*:$/ { current_team = substr($1, 1, length($1)-1) }
    current_team == team && $1 == field":" { gsub(/["\047]/, "", $2); print $2; exit }
  ' "$CONFIG_FILE"
}

get_default_team() {
  grep 'team:' "$CONFIG_FILE" | head -1 | sed 's/.*: *//' | tr -d '"'"'"
}

get_default_project() {
  grep 'project:' "$CONFIG_FILE" | head -1 | sed 's/.*: *//' | sed 's/#.*//' | tr -d '"'"'" | tr -d ' '
}

get_custom_field() {
  local name="$1"
  grep -A20 'custom_fields:' "$CONFIG_FILE" | grep "^  ${name}:" | sed 's/.*: *//' | tr -d '"'"'"
}

get_threshold() {
  local name="$1"
  grep "${name}:" "$CONFIG_FILE" | sed 's/.*: *//'
}

get_wip_limit() {
  local limit=$(grep 'wip_limit:' "$CONFIG_FILE" | sed 's/.*: *//' | sed 's/#.*//' | tr -d ' ')
  echo "${limit:-5}"
}

# ============================================
# Parse CLI args and set BOARD_ID, PROJECT, TEAM_VALUE
# ============================================
TEAM=""
BOARD_ID=""
PROJECT=""
TEAM_VALUE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --team)
      TEAM="$2"
      shift 2
      ;;
    --board)
      BOARD_ID="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    *)
      # Pass through other args
      shift
      ;;
  esac
done

# Apply defaults if not overridden
if [[ -z "$TEAM" && -z "$BOARD_ID" ]]; then
  TEAM=$(get_default_team)
fi

if [[ -n "$TEAM" && -z "$BOARD_ID" ]]; then
  BOARD_ID=$(get_team_config "$TEAM" "board_id")
  TEAM_VALUE=$(get_team_config "$TEAM" "team_value")
fi

# Get default project from config (shared across teams)
if [[ -z "$PROJECT" ]]; then
  PROJECT=$(get_default_project)
fi

# Fallback to platform if still empty
BOARD_ID="${BOARD_ID:-389}"
PROJECT="${PROJECT:-HEAL}"
TEAM="${TEAM:-platform}"

# Team(s) field for JQL filtering
TEAMS_FIELD=$(get_custom_field "teams")

# Pod support - label-based filtering
POD=""
POD_LABEL=""

get_pod_config() {
  local pod="$1"
  local field="$2"
  awk -v pod="$pod" -v field="$field" '
    /^pods:/ { in_pods = 1; next }
    /^[a-z]/ && !/^  / { in_pods = 0 }
    in_pods && /^  [a-z-]+:$/ { current_pod = substr($1, 1, length($1)-1) }
    in_pods && current_pod == pod && $1 == field":" { gsub(/["\047]/, "", $2); print $2 }
  ' "$CONFIG_FILE"
}

load_pod_config() {
  local pod="$1"
  POD="$pod"
  POD_LABEL=$(get_pod_config "$pod" "label")
  local pod_board=$(get_pod_config "$pod" "board_id")
  [[ -n "$pod_board" ]] && BOARD_ID="$pod_board"
  # Clear team filtering when using pod
  TEAM_VALUE=""
}

# ============================================
# JQL Helpers
# ============================================

# Build team/pod filter clause for JQL
# Returns: AND "Team(s)" = "Value" OR AND labels in (label)
# Usage: jql="project = HEAL $(jql_team_filter)"
jql_team_filter() {
  if [[ -n "$POD_LABEL" ]]; then
    echo "AND labels in ($POD_LABEL)"
  elif [[ -n "$TEAM_VALUE" && -n "$TEAMS_FIELD" ]]; then
    echo "AND \"Team(s)\" = \"$TEAM_VALUE\""
  fi
}

# Build base JQL for current team's project
# Returns: project = HEAL AND "Team(s)" = "HealthSource"
jql_base() {
  echo "project = $PROJECT $(jql_team_filter)"
}

# ============================================
# API Functions
# ============================================

# POST to search/jql endpoint
# Fields can be: "key" or "key,summary,status" - will auto-format to JSON array
# Note: Use single quotes in JQL status values, e.g., status = 'In Progress'
jira_search() {
  local jql="$1"
  local fields_input="${2:-key}"
  local max="${3:-200}"

  # Escape double quotes in JQL for JSON
  local jql_escaped=$(echo "$jql" | sed 's/"/\\"/g')

  # Convert "key,summary,status" to "\"key\",\"summary\",\"status\""
  local fields_json=$(echo "$fields_input" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')

  curl -s -X POST -H "Content-Type: application/json" \
    -u "${JIRA_USER}:${JIRA_TOKEN}" \
    "${JIRA_URL}/rest/api/3/search/jql" \
    -d "{\"jql\": \"$jql_escaped\", \"fields\": [$fields_json], \"maxResults\": $max}"
}

# Sum story points from search result
jira_sum_points() {
  local jql="$1"
  local result=$(jira_search "$jql" "customfield_10026")
  echo "$result" | jq '[.issues[].fields.customfield_10026 // 0] | add // 0' | cut -d. -f1
}

# Count issues from search (new API doesn't return total, must fetch all)
jira_count() {
  local jql="$1"
  local result=$(jira_search "$jql" "key" 200)
  echo "$result" | jq '.issues | length'
}

# Get issue list (keys only)
jira_keys() {
  local jql="$1"
  local result=$(jira_search "$jql" "key")
  echo "$result" | jq -r '.issues[].key'
}

# ============================================
# Sprint helpers
# ============================================

# Get active sprint ID for current board
get_active_sprint_id() {
  acli jira board list-sprints --id "$BOARD_ID" --state active --csv 2>/dev/null | \
    tail -n +2 | head -1 | cut -d',' -f1
}

# Get active sprint name
get_active_sprint_name() {
  acli jira board list-sprints --id "$BOARD_ID" --state active --csv 2>/dev/null | \
    tail -n +2 | head -1 | cut -d',' -f2
}

# Get recent closed sprints (returns: id|name per line)
# Filters to Q-format sprints (Q4.S1, Q1.S0, etc) and sorts by sprint name
get_closed_sprints() {
  local limit="${1:-6}"
  local quarter="${2:-}"  # Optional: "Q4" to filter specific quarter

  local pattern="^[0-9]+,Q[0-9]+\.S[0-9]"
  if [[ -n "$quarter" ]]; then
    pattern="^[0-9]+,${quarter}\.S[0-9]"
  fi

  acli jira board list-sprints --id "$BOARD_ID" --state closed --limit 50 --csv 2>/dev/null | \
    tail -n +2 | grep -E "$pattern" | \
    sort -t',' -k2 -V | tail -"$limit" | \
    awk -F',' '{print $1"|"$2}'
}

# ============================================
# Output helpers
# ============================================
print_header() {
  echo "## $1 - $(date +%Y-%m-%d)"
  echo ""
  if [[ -n "$TEAM_VALUE" ]]; then
    echo "**Team:** $TEAM ($TEAM_VALUE) | **Project:** $PROJECT | **Board:** $BOARD_ID"
  else
    echo "**Team:** $TEAM | **Project:** $PROJECT | **Board:** $BOARD_ID"
  fi
  echo ""
}

# Create clickable hyperlink (OSC 8 - works in Ghostty, iTerm2, etc)
# Usage: jira_link "HEAL-123" -> clickable link to browse/HEAL-123
jira_link() {
  local key="$1"
  local url="${JIRA_URL}/browse/${key}"
  local OSC=$'\e]8;;'
  local ST=$'\e\\'
  echo "${OSC}${url}${ST}${key}${OSC}${ST}"
}

# ============================================
# Slack Integration
# ============================================

# Get slack webhook from config
get_slack_webhook() {
  local channel="${1:-default}"
  # Extract value, strip quotes, strip inline comments
  local webhook=$(grep -A10 "slack:" "$CONFIG_FILE" 2>/dev/null | \
    grep "^  ${channel}:" | \
    sed 's/.*: *//' | \
    sed 's/#.*//' | \
    tr -d '"'"'" | \
    tr -d ' ')
  echo "$webhook"
}

# Post to Slack
# Usage: slack_post "channel_name" "message"
slack_post() {
  local channel="$1"
  local message="$2"

  local webhook=$(get_slack_webhook "$channel")
  if [[ -z "$webhook" ]]; then
    webhook=$(get_slack_webhook "default")
  fi

  if [[ -z "$webhook" ]]; then
    echo "No Slack webhook configured. Add to jira-data/config.yaml:"
    echo "  slack:"
    echo "    default: https://hooks.slack.com/services/XXX/YYY/ZZZ"
    return 1
  fi

  # Convert markdown to Slack mrkdwn (basic conversion)
  local slack_msg=$(echo "$message" | sed 's/\*\*/*_/g' | sed 's/^## /*/g' | sed 's/^### /*/g')

  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"text\": \"$slack_msg\"}" \
    "$webhook" >/dev/null

  echo "Posted to Slack"
}

# Wrapper to capture output and optionally post to Slack
# Usage: run_with_slack "script_output" [--slack channel]
run_with_slack() {
  local output="$1"
  local slack_flag="$2"
  local slack_channel="$3"

  echo "$output"

  if [[ "$slack_flag" == "--slack" && -n "$slack_channel" ]]; then
    slack_post "$slack_channel" "$output"
  fi
}
