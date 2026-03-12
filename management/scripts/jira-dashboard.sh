#!/bin/bash
# Jira Dashboard - Terminal-based command center
# Usage: ./jira-dashboard.sh [--team NAME] [--refresh SECS]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args before sourcing lib
REFRESH_SECS=0
for arg in "$@"; do
  case "$arg" in
    --refresh=*) REFRESH_SECS="${arg#*=}" ;;
    --refresh) REFRESH_SECS="${2:-60}" ;;
  esac
done

source "$SCRIPT_DIR/jira-lib.sh"

# Color themes
THEME="${THEME:-default}"

set_theme() {
  case "$1" in
    default)
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[0;33m'
      BLUE='\033[0;34m'
      CYAN='\033[0;36m'
      ACCENT="$CYAN"
      ;;
    ocean)
      RED='\033[0;31m'
      GREEN='\033[0;36m'  # cyan for success
      YELLOW='\033[0;33m'
      BLUE='\033[0;34m'
      CYAN='\033[0;34m'   # blue
      ACCENT='\033[0;34m'
      ;;
    forest)
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[0;32m' # green
      BLUE='\033[0;32m'   # green
      CYAN='\033[0;32m'   # green
      ACCENT='\033[0;32m'
      ;;
    sunset)
      RED='\033[0;31m'
      GREEN='\033[0;33m'  # yellow
      YELLOW='\033[0;33m'
      BLUE='\033[0;31m'   # red
      CYAN='\033[0;33m'   # yellow
      ACCENT='\033[0;33m'
      ;;
    mono)
      RED='\033[0;37m'
      GREEN='\033[0;37m'
      YELLOW='\033[0;37m'
      BLUE='\033[0;37m'
      CYAN='\033[0;37m'
      ACCENT='\033[0;37m'
      ;;
  esac
  THEME="$1"
}

BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Initialize theme
set_theme "$THEME"

# Clear screen and move cursor to top
clear_screen() {
  printf "\033[2J\033[H"
}

# Print colored header
header() {
  local context="$TEAM"
  [[ -n "$POD" ]] && context="$POD (pod)"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}  JIRA COMMAND CENTER${NC}  ${DIM}$context | $PROJECT | $(date '+%Y-%m-%d %H:%M')${NC}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
  # WIP warning banner
  if [[ "$WIP_OVER" -eq 1 ]]; then
    echo -e "${BOLD}${RED}🚨 STOP STARTING! ${WIP_COUNT} items in progress (limit: ${WIP_LIMIT}) - FINISH SOMETHING 🚨${NC}"
  fi
  echo ""
}

# Section header
section() {
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
}

# Status indicators
status_ok() { echo -e "${GREEN}✓${NC} $1"; }
status_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
status_bad() { echo -e "${RED}✗${NC} $1"; }

# WIP limit
WIP_LIMIT=$(get_wip_limit)
WIP_COUNT=0
WIP_OVER=0

# Progress bar
progress_bar() {
  local pct=$1
  local width=30
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  printf "${GREEN}"
  printf '%*s' "$filled" | tr ' ' '█'
  printf "${DIM}"
  printf '%*s' "$empty" | tr ' ' '░'
  printf "${NC} %d%%" "$pct"
}

# ============================================
# Dashboard Panels
# ============================================

panel_sprint_health() {
  section "[1] SPRINT HEALTH"

  local sprint_jql="project = $PROJECT AND sprint in openSprints()"
  local total_pts=$(jira_sum_points "$sprint_jql")
  local done_pts=$(jira_sum_points "$sprint_jql AND status = Done")
  local total_count=$(jira_count "$sprint_jql")
  local done_count=$(jira_count "$sprint_jql AND status = Done")

  local pct=0
  [[ "$total_pts" -gt 0 ]] && pct=$((done_pts * 100 / total_pts))

  # Get days remaining
  local SPRINT_ID=$(get_active_sprint_id)
  local days_left="?"
  if [[ -n "$SPRINT_ID" ]]; then
    local sprint_info=$(curl -s -H "Content-Type: application/json" \
      -u "${JIRA_USER}:${JIRA_TOKEN}" \
      "${JIRA_URL}/rest/agile/1.0/sprint/${SPRINT_ID}" 2>/dev/null)
    local end_date=$(echo "$sprint_info" | jq -r '.endDate // empty' | cut -dT -f1)
    if [[ -n "$end_date" ]]; then
      local end_epoch=$(date -j -f "%Y-%m-%d" "$end_date" "+%s" 2>/dev/null)
      local today_epoch=$(date "+%s")
      days_left=$(( (end_epoch - today_epoch) / 86400 ))
      [[ "$days_left" -lt 0 ]] && days_left=0
    fi
  fi

  echo -n "  Progress: "
  progress_bar "$pct"
  echo ""
  echo -e "  ${DIM}$done_pts / $total_pts pts | $done_count / $total_count items | $days_left days left${NC}"

  # Health indicator
  if [[ "$pct" -ge 70 ]]; then
    status_ok "On Track"
  elif [[ "$pct" -ge 40 ]]; then
    status_warn "At Risk"
  else
    status_bad "Behind Schedule"
  fi
  echo ""
}

panel_risks() {
  section "[2] RISKS"

  # Large items not started
  local large_jql="project = $PROJECT AND sprint in openSprints() AND \"Story Points[Number]\" >= 3 AND status = \"To Do\""
  local large_count=$(jira_count "$large_jql")

  # Stale
  local stale_jql="project = $PROJECT AND sprint in openSprints() AND status = \"In Progress\" AND updated < -3d"
  local stale_count=$(jira_count "$stale_jql")

  # Blocked
  local blocked_jql="project = $PROJECT AND sprint in openSprints() AND (status = Blocked OR labels = blocked)"
  local blocked_count=$(jira_count "$blocked_jql")

  # Unassigned
  local unassigned_jql="project = $PROJECT AND sprint in openSprints() AND assignee is EMPTY AND status != Done"
  local unassigned_count=$(jira_count "$unassigned_jql")

  [[ "$large_count" -gt 0 ]] && status_warn "$large_count large items (3+ pts) not started" || status_ok "No large items waiting"
  [[ "$stale_count" -gt 0 ]] && status_warn "$stale_count items stale (>3 days)" || status_ok "No stale items"
  [[ "$blocked_count" -gt 0 ]] && status_bad "$blocked_count items blocked" || status_ok "Nothing blocked"
  [[ "$unassigned_count" -gt 0 ]] && status_warn "$unassigned_count items unassigned" || status_ok "All items assigned"
  echo ""
}

panel_velocity() {
  section "[3] VELOCITY"

  TRENDS_FILE="${SCRIPT_DIR}/../jira-data/trends/velocity.csv"
  if [[ -f "$TRENDS_FILE" ]]; then
    # Last 4 sprints as mini chart
    echo -e "  ${DIM}Sprint    Delivered${NC}"
    tail -5 "$TRENDS_FILE" | head -4 | while IFS=',' read -r date sprint sid committed delivered rest; do
      [[ "$sprint" == "sprint" ]] && continue
      local bar_len=$((delivered / 10))
      [[ "$bar_len" -gt 20 ]] && bar_len=20
      local bar=$(printf '%*s' "$bar_len" | tr ' ' '▇')
      printf "  %-8s ${GREEN}%s${NC} %s\n" "$sprint" "$bar" "$delivered pts"
    done
  else
    echo -e "  ${DIM}No velocity data yet${NC}"
  fi
  echo ""
}

panel_today() {
  section "[4] TODAY"

  # Done today
  local done_jql="project = $PROJECT AND status changed to Done after -1d"
  local done_today=$(jira_count "$done_jql")

  # Started today
  local started_jql="project = $PROJECT AND status changed to \"In Progress\" after -1d"
  local started_today=$(jira_count "$started_jql")

  echo -e "  ${GREEN}✓ $done_today completed${NC}  |  ${CYAN}▶ $started_today started${NC}"
  echo ""
}

panel_initiatives() {
  section "[5] INITIATIVES"

  local active_jql="project = PDCR AND status in (Development, \"In Progress\", \"To Do\")"
  local active=$(jira_search "$active_jql" "key,summary,status" 2>/dev/null)
  local active_count=$(echo "$active" | jq '.issues | length // 0')

  echo -e "  ${BOLD}$active_count active initiatives${NC}"
  # Output with clickable hyperlinks
  echo "$active" | jq -r '.issues[0:3][] | "\(.key)\t\((.fields.summary // "?") | .[0:40])"' 2>/dev/null | while IFS=$'\t' read -r key summary; do
    local link=$(jira_link "$key")
    echo "  ${link}: ${summary}"
  done
  [[ "$active_count" -gt 3 ]] && echo -e "  ${DIM}... and $((active_count - 3)) more${NC}"
  echo ""
}

panel_wip() {
  section "[W] WIP STATUS"

  local wip_jql="project = $PROJECT AND sprint in openSprints() AND status = 'In Progress'"
  local wip_data=$(jira_search "$wip_jql" "key,summary,assignee" 200)
  WIP_COUNT=$(echo "$wip_data" | jq '.issues | length // 0')

  # Per-person breakdown - find individuals with high WIP
  local high_wip_people=$(echo "$wip_data" | jq -r '
    [.issues[].fields.assignee.displayName // "Unassigned"]
    | group_by(.)
    | map({name: .[0], count: length})
    | sort_by(-.count)
    | .[] | select(.count >= 3)
    | "\(.name) has \(.count) items"
  ' 2>/dev/null)

  # Highlight individuals with high WIP first
  if [[ -n "$high_wip_people" ]]; then
    echo -e "  ${RED}${BOLD}⚠ HIGH WIP:${NC}"
    echo "$high_wip_people" | while read -r line; do
      echo -e "    ${RED}$line${NC}"
    done
    echo ""
  fi

  # Team total
  if [[ "$WIP_COUNT" -gt "$WIP_LIMIT" ]]; then
    WIP_OVER=1
    echo -e "  Team: ${RED}${BOLD}$WIP_COUNT${NC}/${WIP_LIMIT} ${RED}over limit${NC}"
  elif [[ "$WIP_COUNT" -eq "$WIP_LIMIT" ]]; then
    WIP_OVER=0
    echo -e "  Team: ${YELLOW}${BOLD}$WIP_COUNT${NC}/${WIP_LIMIT} ${YELLOW}at limit${NC}"
  else
    WIP_OVER=0
    echo -e "  Team: ${GREEN}${BOLD}$WIP_COUNT${NC}/${WIP_LIMIT} ${GREEN}✓${NC}"
  fi
  echo ""
}

panel_commands() {
  section "QUICK COMMANDS"
  echo -e "  ${DIM}/standup  /risk  /capacity  /burndown  /executive${NC}"
  echo -e "  ${DIM}/hygiene  /velocity  /dependencies  /forecast PDCR-X${NC}"
  echo ""
}

# ============================================
# Main Dashboard
# ============================================

DASHBOARD_CACHE=""
DASHBOARD_STALE=1  # 1 = needs refresh, 0 = use cache

render_dashboard() {
  if [[ "$DASHBOARD_STALE" -eq 1 || -z "$DASHBOARD_CACHE" ]]; then
    # Fetch fresh data with spinner
    if [[ "$HAS_GUM" -eq 1 && -n "$DASHBOARD_CACHE" ]]; then
      # Show old dashboard while loading
      clear_screen
      echo "$DASHBOARD_CACHE"
      echo ""
      gum spin --spinner dot --title "Refreshing..." -- sleep 0.1 &
    fi

    # Calculate WIP first (must be in main shell to set WIP_COUNT/WIP_OVER for header)
    local wip_jql="project = $PROJECT AND sprint in openSprints() AND status = 'In Progress'"
    WIP_COUNT=$(jira_search "$wip_jql" "key" 200 | jq '.issues | length // 0')
    [[ "$WIP_COUNT" -gt "$WIP_LIMIT" ]] && WIP_OVER=1 || WIP_OVER=0

    # Capture fresh dashboard
    DASHBOARD_CACHE=$(
      header
      panel_wip
      panel_sprint_health
      panel_risks
      panel_velocity
      panel_today
      panel_initiatives
    )
    DASHBOARD_STALE=0
  fi

  clear_screen
  echo "$DASHBOARD_CACHE"
}

# ============================================
# Interactive Mode (gum)
# ============================================

HAS_GUM=$(command -v gum >/dev/null 2>&1 && echo 1 || echo 0)
HAS_GLOW=$(command -v glow >/dev/null 2>&1 && echo 1 || echo 0)

# Report cache directory (bash 3 compatible)
CACHE_DIR="${TMPDIR:-/tmp}/lazyjira-cache-$$"
mkdir -p "$CACHE_DIR"
trap "rm -rf '$CACHE_DIR'" EXIT

# Render output with nice styling
render_styled() {
  local title="$1"
  local content="$2"

  if [[ "$HAS_GLOW" -eq 1 ]]; then
    # Use glow for markdown rendering
    echo "$content" | glow -s dark -
  elif [[ "$HAS_GUM" -eq 1 ]]; then
    # Use gum style for bordered output
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $title${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    # Convert markdown-ish to styled output
    echo "$content" | sed \
      -e "s/^### \(.*\)$/$(printf '\033[1;36m')▶ \1$(printf '\033[0m')/" \
      -e "s/^## \(.*\)$/$(printf '\033[1;33m')■ \1$(printf '\033[0m')/" \
      -e "s/^# \(.*\)$/$(printf '\033[1;32m')█ \1$(printf '\033[0m')/" \
      -e "s/^- \(.*\)$/  • \1/" \
      -e "s/\*\*\([^*]*\)\*\*/$(printf '\033[1m')\1$(printf '\033[0m')/g"
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  else
    # Plain output
    echo "$content"
  fi
}

run_command() {
  local cmd="$1"
  local force_refresh="${2:-0}"

  # Build the command to run
  local script_cmd=""
  local title=""
  local cache_key="${cmd}_${TEAM}"

  case "$cmd" in
    standup)      script_cmd="$SCRIPT_DIR/jira-standup.sh --team $TEAM"; title="STANDUP SUMMARY" ;;
    risk)         script_cmd="$SCRIPT_DIR/jira-risk.sh --team $TEAM"; title="RISK REPORT" ;;
    capacity)     script_cmd="$SCRIPT_DIR/jira-capacity.sh --team $TEAM"; title="CAPACITY" ;;
    burndown)     script_cmd="$SCRIPT_DIR/jira-burndown.sh --team $TEAM"; title="BURNDOWN" ;;
    executive)    script_cmd="$SCRIPT_DIR/jira-executive.sh --team $TEAM"; title="EXECUTIVE SUMMARY" ;;
    hygiene)      script_cmd="$SCRIPT_DIR/jira-hygiene.sh --team $TEAM"; title="SPRINT HYGIENE" ;;
    velocity)     script_cmd="$SCRIPT_DIR/jira-velocity.sh --team $TEAM"; title="VELOCITY" ;;
    dependencies) script_cmd="$SCRIPT_DIR/jira-dependencies.sh --team $TEAM"; title="DEPENDENCIES" ;;
    forecast)
      echo -e "${CYAN}Enter initiative key (e.g., PDCR-123):${NC}"
      if [[ "$HAS_GUM" -eq 1 ]]; then
        local key=$(gum input --placeholder "PDCR-XXX")
      else
        read -r key
      fi
      if [[ -n "$key" ]]; then
        script_cmd="$SCRIPT_DIR/jira-forecast.sh $key"
        title="FORECAST: $key"
        cache_key="forecast_${key}"
      fi
      ;;
    roadmap|initiatives) script_cmd="$SCRIPT_DIR/jira-roadmap.sh"; title="INITIATIVES ROADMAP"; cache_key="initiatives" ;;
    bottlenecks) script_cmd="$SCRIPT_DIR/jira-bottlenecks.sh --team $TEAM"; title="BOTTLENECKS" ;;
    audit)       script_cmd="$SCRIPT_DIR/jira-audit.sh --team $TEAM"; title="SPRINT AUDIT" ;;
    wip) script_cmd="$SCRIPT_DIR/jira-wip.sh --team $TEAM"; title="WIP DETAIL" ;;
    *) echo "Unknown command: $cmd"; return ;;
  esac

  [[ -z "$script_cmd" ]] && return

  # Report view loop (allows refresh)
  while true; do
    clear_screen
    local output

    # Check cache or fetch (file-based for bash 3 compat)
    local cache_file="$CACHE_DIR/$cache_key"
    if [[ "$force_refresh" -eq 0 && -f "$cache_file" ]]; then
      output=$(cat "$cache_file")
    else
      # Fetch with spinner (spinner shows on terminal, output captured separately)
      if [[ "$HAS_GUM" -eq 1 ]]; then
        gum spin --spinner dot --title "Loading $title..." -- bash -c "$script_cmd > '$cache_file' 2>&1"
        output=$(cat "$cache_file")
      else
        echo "Loading $title..."
        output=$($script_cmd 2>&1)
        echo "$output" > "$cache_file"
      fi
      force_refresh=0
    fi

    render_styled "$title" "$output"

    echo ""
    echo -e "${DIM}[Enter] back  [r] refresh${NC}"

    local key
    read -rsn1 key
    case "$key" in
      r|R) force_refresh=1; continue ;;
      *) break ;;
    esac
  done
}

switch_team() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    local new_team=$(gum choose --header "Select Team" "platform" "roio" "roip")
    [[ -n "$new_team" ]] && TEAM="$new_team" && POD="" && POD_LABEL="" && load_team_config "$TEAM"
  else
    echo "Teams: platform, roio, roip"
    echo -n "Enter team: "
    read -r new_team
    [[ -n "$new_team" ]] && TEAM="$new_team" && POD="" && POD_LABEL="" && load_team_config "$TEAM"
  fi
}

switch_pod() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    local choice=$(gum choose --header "Select Pod View (or 'none' to clear)" \
      "intake-logging" "platform-pod" "fulfillment-qc" "none")
    if [[ "$choice" == "none" ]]; then
      POD=""
      POD_LABEL=""
    elif [[ -n "$choice" ]]; then
      load_pod_config "$choice"
    fi
  else
    echo "Pods: intake-logging, platform-pod, fulfillment-qc, none"
    echo -n "Enter pod (or 'none' to clear): "
    read -r choice
    if [[ "$choice" == "none" ]]; then
      POD=""
      POD_LABEL=""
    elif [[ -n "$choice" ]]; then
      load_pod_config "$choice"
    fi
  fi
}

show_help() {
  clear_screen
  echo -e "${BOLD}${CYAN}JIRA COMMAND CENTER - HELP${NC}"
  echo ""
  echo -e "${BOLD}Quick Keys:${NC}"
  echo "  [1] Sprint Health (burndown)    [4] Today (standup)"
  echo "  [2] Risks                       [5] Initiatives"
  echo "  [3] Velocity                    [w] WIP Status (stop starting!)"
  echo "  [/] Full command menu"
  echo "  [q] Quit  [r] Refresh  [s] Search  [t] Team  [p] Pod  [c] Theme"
  echo ""
  echo -e "${BOLD}Reports (drill into dashboard panels):${NC}"
  echo -e "  ${CYAN}standup${NC}       Daily summary - what happened today"
  echo -e "  ${CYAN}risk${NC}          At-risk items - blocked, stale, large unstarted"
  echo -e "  ${CYAN}capacity${NC}      Team workload - points by assignee"
  echo -e "  ${CYAN}burndown${NC}      Sprint progress - % complete, days left"
  echo -e "  ${CYAN}velocity${NC}      Historical trends - last N sprints"
  echo -e "  ${CYAN}initiatives${NC}   All PDCR items - active company projects"
  echo ""
  echo -e "${BOLD}Analysis:${NC}"
  echo -e "  ${CYAN}hygiene${NC}       Sprint health - missing points, unassigned"
  echo -e "  ${CYAN}executive${NC}     Stakeholder summary - high level overview"
  echo -e "  ${CYAN}dependencies${NC}  Cross-team blockers & external links"
  echo -e "  ${CYAN}bottlenecks${NC}   Workflow issues - stuck items, slow transitions"
  echo -e "  ${CYAN}audit${NC}         Complete sprint audit - all checks"
  echo -e "  ${CYAN}forecast${NC}      Initiative timeline - prompts for PDCR key"
  echo ""
  echo -e "${BOLD}System Commands:${NC}"
  echo -e "  ${DIM}/search${NC}       Find tickets by key or text"
  echo -e "  ${DIM}/team${NC}         Switch team (current: ${CYAN}$TEAM${NC})"
  echo -e "  ${DIM}/theme${NC}        Color theme (current: ${CYAN}$THEME${NC})"
  echo -e "  ${DIM}/auto${NC}         Set auto-refresh interval"
  echo -e "  ${DIM}/refresh${NC}      Reload dashboard now"
  echo -e "  ${DIM}/help${NC}         This screen"
  echo -e "  ${DIM}/quit${NC}         Exit lazyjira"
  echo ""
  echo -e "${DIM}Press Enter to return...${NC}"
  read -r
}

# Switch color theme
switch_theme() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    local new_theme=$(gum choose --header "Select Theme (current: $THEME)" \
      "default" "ocean" "forest" "sunset" "mono")
    [[ -n "$new_theme" ]] && set_theme "$new_theme"
  else
    echo "Themes: default ocean forest sunset mono"
    echo -n "Enter theme: "
    read -r new_theme
    [[ -n "$new_theme" ]] && set_theme "$new_theme"
  fi
}

# Set auto-refresh interval
set_refresh() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    local secs=$(gum input --placeholder "Refresh interval in seconds (0 = off)" --value "$REFRESH_SECS")
    if [[ "$secs" =~ ^[0-9]+$ ]]; then
      REFRESH_SECS="$secs"
      if [[ "$REFRESH_SECS" -gt 0 ]]; then
        echo -e "${GREEN}Auto-refresh set to ${REFRESH_SECS}s${NC}"
      else
        echo -e "${YELLOW}Auto-refresh disabled${NC}"
      fi
      sleep 1
    fi
  else
    echo -n "Refresh interval (seconds, 0=off): "
    read -r secs
    [[ "$secs" =~ ^[0-9]+$ ]] && REFRESH_SECS="$secs"
  fi
}

# Search for tickets interactively
search_tickets() {
  if [[ "$HAS_GUM" -eq 1 ]]; then
    local query=$(gum input --placeholder "Search term or ticket key (e.g., HEAL-123)")
    [[ -z "$query" ]] && return

    clear_screen
    echo -e "${BOLD}${CYAN}Search Results for: ${query}${NC}"
    echo ""

    # Check if it looks like a ticket key
    if [[ "$query" =~ ^[A-Z]+-[0-9]+$ ]]; then
      # Direct ticket lookup
      local result=$(curl -s -H "Content-Type: application/json" \
        -u "${JIRA_USER}:${JIRA_TOKEN}" \
        "${JIRA_URL}/rest/api/3/issue/${query}?fields=key,summary,status,assignee,customfield_10026" 2>/dev/null)

      if echo "$result" | jq -e '.key' >/dev/null 2>&1; then
        local key=$(echo "$result" | jq -r '.key')
        local summary=$(echo "$result" | jq -r '.fields.summary // "?"')
        local status=$(echo "$result" | jq -r '.fields.status.name // "?"')
        local assignee=$(echo "$result" | jq -r '.fields.assignee.displayName // "Unassigned"')
        local points=$(echo "$result" | jq -r '.fields.customfield_10026 // "?"')

        echo -e "${BOLD}$key${NC}: $summary"
        echo -e "  Status: ${CYAN}$status${NC} | Assignee: $assignee | Points: $points"
        echo ""
        echo -e "${DIM}Open in browser? (y/n)${NC}"
        if gum confirm "Open in browser?"; then
          open "${JIRA_URL}/browse/${key}"
        fi
      else
        echo "Ticket not found: $query"
      fi
    else
      # Text search
      local jql="project = $PROJECT AND (summary ~ \"$query\" OR description ~ \"$query\") ORDER BY updated DESC"
      local results=$(jira_search "$jql" "key,summary,status" 20)
      local count=$(echo "$results" | jq '.issues | length // 0')

      if [[ "$count" -gt 0 ]]; then
        echo "Found $count matching tickets:"
        echo ""
        # Build selection list
        local tickets=$(echo "$results" | jq -r '.issues[] | "\(.key): \(.fields.summary // "?" | .[0:60])"')
        local selected=$(echo "$tickets" | gum filter --placeholder "Select ticket...")

        if [[ -n "$selected" ]]; then
          local ticket_key=$(echo "$selected" | cut -d: -f1)
          open "${JIRA_URL}/browse/${ticket_key}"
        fi
      else
        echo "No tickets found matching: $query"
      fi
    fi
  else
    echo -n "Search term: "
    read -r query
    [[ -z "$query" ]] && return

    local jql="project = $PROJECT AND (summary ~ \"$query\" OR key = \"$query\") ORDER BY updated DESC"
    jira_search "$jql" "key,summary,status" 10 | jq -r '.issues[] | "\(.key): \(.fields.summary // "?")"'
  fi

  echo ""
  echo -e "${DIM}Press Enter to return to dashboard...${NC}"
  read -r
}

interactive_loop() {
  while true; do
    render_dashboard

    if [[ "$HAS_GUM" -eq 1 ]]; then
      echo ""
      echo -e "${DIM}[1-5] panels  [w] WIP  [p] pod  [/] commands  [q] quit${NC}"

      # Capture single keypress
      local key
      read -rsn1 key

      # Handle hotkeys
      case "$key" in
        1) run_command "burndown" ;;
        2) run_command "risk" ;;
        3) run_command "velocity" ;;
        4) run_command "standup" ;;
        5) run_command "initiatives" ;;
        w|W) run_command "wip" ;;
        q|Q) break ;;
        r|R) DASHBOARD_STALE=1; continue ;;  # force refresh
        t|T) DASHBOARD_STALE=1; switch_team ;;
        p|P) DASHBOARD_STALE=1; switch_pod ;;
        c|C) switch_theme ;;
        s|S) search_tickets ;;
        h|H|\?) show_help ;;
        ""|"/"|$'\n')
          # Show full command menu on Enter, /, or empty
          local commands=$(cat <<'CMDS'
standup       - Daily standup summary (what happened today)
risk          - At-risk items (blocked, stale, large)
capacity      - Team workload by assignee
burndown      - Sprint progress & completion rate
executive     - High-level stakeholder summary
hygiene       - Sprint health audit (missing points, unassigned)
velocity      - Historical velocity trends
dependencies  - Cross-team blockers & links
forecast      - Initiative timeline (prompts for PDCR key)
initiatives   - All active PDCR initiatives
roadmap       - Full roadmap view
bottlenecks   - Workflow issues & stuck items
audit         - Complete sprint audit
wip           - Work in progress detail (stop starting!)
/search       - Find tickets by key or text
/team         - Switch team (current: TEAM_PLACEHOLDER)
/pod          - Switch pod view (label-based filter)
/theme        - Color theme (current: THEME_PLACEHOLDER)
/auto         - Set auto-refresh interval
/refresh      - Reload dashboard now
/help         - Show all commands
/quit         - Exit lazyjira
CMDS
)
          commands=$(echo "$commands" | sed "s/TEAM_PLACEHOLDER/$TEAM/" | sed "s/THEME_PLACEHOLDER/$THEME/")
          local selection=$(echo "$commands" | gum filter --placeholder "Type to filter commands...")
          local cmd=$(echo "$selection" | awk '{print $1}')

          case "$cmd" in
            /quit) break ;;
            /refresh) continue ;;
            /auto) set_refresh ;;
            /team) DASHBOARD_STALE=1; switch_team ;;
            /pod) DASHBOARD_STALE=1; switch_pod ;;
            /theme) switch_theme ;;
            /search) search_tickets ;;
            /help) show_help ;;
            "") continue ;;
            *) run_command "$cmd" ;;
          esac
          ;;
        *) continue ;;  # Unknown key, refresh
      esac
    else
      # Fallback: simple read-based menu
      echo ""
      echo -e "${BOLD}Commands:${NC} standup risk capacity burndown executive hygiene velocity"
      echo -e "          dependencies forecast roadmap bottlenecks audit"
      echo -e "${DIM}Enter command (q=quit, t=team, c=theme, r=refresh, a=auto, s=search, ?=help):${NC}"
      read -r choice

      case "$choice" in
        q|quit) break ;;
        r|refresh) DASHBOARD_STALE=1; continue ;;
        a|auto) set_refresh ;;
        t|team) DASHBOARD_STALE=1; switch_team ;;
        c|theme) switch_theme ;;
        s|search) search_tickets ;;
        "?"|help) show_help ;;
        "") continue ;;
        *) run_command "$choice" ;;
      esac
    fi
  done

  clear_screen
  echo "Goodbye!"
}

# ============================================
# Main Entry Point
# ============================================

# Run once, refresh loop, or interactive
if [[ "$REFRESH_SECS" -gt 0 ]]; then
  # Auto-refresh display mode (no interaction)
  while true; do
    render_dashboard
    panel_commands
    echo -e "${DIM}Last updated: $(date '+%H:%M:%S') | Auto-refresh: ${REFRESH_SECS}s | Ctrl+C to exit${NC}"
    sleep "$REFRESH_SECS"
  done
else
  # Interactive mode
  interactive_loop
fi
