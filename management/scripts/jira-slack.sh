#!/bin/bash
# Jira Slack - Post any jira command output to Slack
# Usage: ./jira-slack.sh <command> [channel]
# Examples:
#   ./jira-slack.sh standup platform
#   ./jira-slack.sh executive stakeholders
#   ./jira-slack.sh burndown

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Save args BEFORE sourcing lib (lib consumes args)
COMMAND="$1"
CHANNEL="${2:-default}"

source "$SCRIPT_DIR/jira-lib.sh"

if [[ -z "$COMMAND" ]]; then
  echo "Usage: jira-slack.sh <command> [channel]"
  echo ""
  echo "Commands: standup, risk, capacity, dependencies, burndown, executive, hygiene, velocity"
  echo "Channels: default, platform, stakeholders (configure in jira-data/config.yaml)"
  echo ""
  echo "Examples:"
  echo "  jira-slack.sh standup platform     # Post standup to #platform"
  echo "  jira-slack.sh executive stakeholders  # Post exec summary to #stakeholders"
  exit 1
fi

# Map command to script
case "$COMMAND" in
  standup)     SCRIPT="jira-standup.sh" ;;
  risk)        SCRIPT="jira-risk.sh" ;;
  capacity)    SCRIPT="jira-capacity.sh" ;;
  dependencies) SCRIPT="jira-dependencies.sh" ;;
  burndown)    SCRIPT="jira-burndown.sh" ;;
  executive)   SCRIPT="jira-executive.sh" ;;
  hygiene)     SCRIPT="jira-hygiene.sh" ;;
  velocity)    SCRIPT="jira-velocity.sh" ;;
  *)
    echo "Unknown command: $COMMAND"
    exit 1
    ;;
esac

# Run command and capture output
OUTPUT=$(bash "$SCRIPT_DIR/$SCRIPT" 2>&1)

# Post to Slack
if slack_post "$CHANNEL" "$OUTPUT"; then
  echo "---"
  echo "Posted $COMMAND report to Slack channel: $CHANNEL"
fi
