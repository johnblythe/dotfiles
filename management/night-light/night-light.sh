#!/bin/bash
#
# Night Light - Overnight anomaly detection and remediation agent
#
# Usage:
#   ./night-light.sh                        # Dry run, last 2 hours
#   ./night-light.sh --live                 # Creates tickets + PRs
#   ./night-light.sh --hours 4              # Look back 4 hours
#   ./night-light.sh --replay "2026-01-07 17:19" --hours 1  # Historical replay
#

set -euo pipefail

# Zscaler cert for SSL (Datadog API calls)
export SSL_CERT_FILE="$HOME/Documents/combined-ca-bundle.pem"
export REQUESTS_CA_BUNDLE="$HOME/Documents/combined-ca-bundle.pem"
export NODE_EXTRA_CA_CERTS="$HOME/Documents/combined-ca-bundle.pem"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MGMT_DIR="$(dirname "$SCRIPT_DIR")"
HEALTHSOURCE_DIR="$HOME/code/healthsource"
# Reports written to healthsource (where Claude runs) - sandbox restriction
LOG_DIR="$HEALTHSOURCE_DIR/night-light-runs"
TIMESTAMP=$(date +%Y-%m-%d-%H%M)

# Defaults
DRY_RUN=true
HOURS=2
REPLAY_TIME=""

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --live)
      DRY_RUN=false
      shift
      ;;
    --hours)
      HOURS="$2"
      shift 2
      ;;
    --replay)
      REPLAY_TIME="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--live] [--hours N] [--replay DATETIME]"
      echo "  --live              Create real Jira tickets and PRs (default: dry-run)"
      echo "  --hours N           Look back N hours (default: 2)"
      echo "  --replay DATETIME   Replay from historical time (e.g., '2026-01-07 17:19')"
      echo ""
      echo "Examples:"
      echo "  $0 --hours 4                          # Last 4 hours"
      echo "  $0 --replay '2026-01-07 17:19' --hours 1  # Incident replay"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Setup
mkdir -p "$LOG_DIR"

# Calculate time window
if [ -n "$REPLAY_TIME" ]; then
  # Historical replay mode
  REPLAY_EPOCH=$(date -j -f "%Y-%m-%d %H:%M" "$REPLAY_TIME" "+%s" 2>/dev/null || date -d "$REPLAY_TIME" "+%s")
  NOW_EPOCH=$(date "+%s")
  HOURS_AGO=$(( (NOW_EPOCH - REPLAY_EPOCH) / 3600 ))

  # Adjust lookback to cover from REPLAY_TIME for HOURS duration
  # We need to tell Claude: "look at data from X hours ago, for a Y hour window"
  TIME_CONTEXT="
## HISTORICAL REPLAY MODE

**Replaying incident from:** $REPLAY_TIME
**Window:** $HOURS hour(s) starting from that time
**Hours ago from now:** ~$HOURS_AGO hours

When querying Datadog, use \`--from ${HOURS_AGO}h\` to look back to the incident window.
Focus on what monitors were alerting and what anomalies existed during that specific time period.
Note: Some historical data may be aggregated or unavailable - work with what's available.
"
  OUTPUT_SUFFIX="replay-$(echo "$REPLAY_TIME" | tr ' :' '-')"
else
  TIME_CONTEXT=""
  OUTPUT_SUFFIX=""
  HOURS_AGO=$HOURS
fi

if [ "$DRY_RUN" = true ]; then
  if [ -n "$OUTPUT_SUFFIX" ]; then
    OUTPUT_FILE="$LOG_DIR/$TIMESTAMP-$OUTPUT_SUFFIX-dry-run.md"
  else
    OUTPUT_FILE="$LOG_DIR/$TIMESTAMP-dry-run.md"
  fi
  echo "🌙 Night Light DRY RUN - $TIMESTAMP"
  if [ -n "$REPLAY_TIME" ]; then
    echo "   📼 REPLAY MODE: $REPLAY_TIME"
  fi
  echo "   Output: $OUTPUT_FILE"
  echo ""
  MODE_INSTRUCTION="
## DRY RUN MODE

This is a dry run. Do NOT create actual Jira tickets or GitHub PRs.

CRITICAL: Use the Write tool to save your FULL report to this file:
**$OUTPUT_FILE**

Your report MUST include ALL of these sections:

# Night Light Report - $TIMESTAMP

## Anomalies Detected
[List ALL anomalies found from Datadog with their scores]

## Investigation #1: [Service - Brief Description]
### Datadog Findings
[What you found - error messages, counts, timeframes]
### Code Investigation
[Files examined, stack traces analyzed, root cause identified]
### WOULD CREATE TICKET:
[Full Jira ticket content - summary, description, labels, priority]
### WOULD CREATE PR: (if confidence >= 4)
[Branch: night-light/HEAL-XXX, files changed, actual diff]

## Investigation #2: ...
[Repeat for each top anomaly]

## Summary
- X tickets would be created
- Y PRs would be created
- Key patterns identified

Write the COMPLETE report using the Write tool. Do not summarize.
"
else
  OUTPUT_FILE="$LOG_DIR/$TIMESTAMP.log"
  echo "🌙 Night Light LIVE RUN - $TIMESTAMP"
  echo "   Log: $OUTPUT_FILE"
  echo ""
  MODE_INSTRUCTION=""
fi

# Build the prompt
PROMPT=$(cat <<EOF
$(cat "$SCRIPT_DIR/PROMPT.md")

---

## This Run Configuration

- **Timestamp:** $TIMESTAMP
- **Lookback Window:** $HOURS hours
- **HealthSource Repo:** $HEALTHSOURCE_DIR
- **Services Config:** $SCRIPT_DIR/services.yaml
$TIME_CONTEXT
$MODE_INSTRUCTION

---

## Begin

Start by querying Datadog for anomalies in the hs-* namespace from the last $HOURS_AGO hours.
Then follow the phases in the prompt above.

Go.
EOF
)

# Run Claude
cd "$HEALTHSOURCE_DIR"

if [ "$DRY_RUN" = true ]; then
  # Dry run: Claude writes report directly to OUTPUT_FILE via Write tool
  claude --print "$PROMPT" 2>&1

  # Verify report was written
  if [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo "Report written to: $OUTPUT_FILE"
    echo "Lines: $(wc -l < "$OUTPUT_FILE")"
  else
    echo "WARNING: Report file was not created"
  fi
else
  # Live run: log output
  claude --print "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"
fi

echo ""
echo "════════════════════════════════════════════"
echo "Night Light complete. Output: $OUTPUT_FILE"
echo "════════════════════════════════════════════"
