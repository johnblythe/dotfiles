#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Jira Dashboard
# @raycast.mode fullOutput
# @raycast.packageName Jira Command Center

# Optional parameters:
# @raycast.icon 📊
# @raycast.argument1 { "type": "text", "placeholder": "team (optional)", "optional": true }

TEAM="${1:-platform}"
cd ~/code/management && bash scripts/jira-dashboard.sh --team "$TEAM"
