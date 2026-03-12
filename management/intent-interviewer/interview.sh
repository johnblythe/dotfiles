#!/bin/bash
#
# Intent Interviewer - Generate CLAUDE.md files through SME interviews
#
# Usage:
#   ./interview.sh intakeservices
#   ./interview.sh workflow
#   ./interview.sh searchservices
#   ./interview.sh securityservices
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTHSOURCE_DIR="$HOME/code/healthsource"

# Validate service argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <service_name>"
    echo ""
    echo "Available pilot services:"
    echo "  intakeservices"
    echo "  workflow"
    echo "  searchservices"
    echo "  securityservices"
    echo ""
    echo "Example: $0 intakeservices"
    exit 1
fi

SERVICE_NAME="$1"

# Map service name to path
case "$SERVICE_NAME" in
    intakeservices)
        SERVICE_PATH="services/intakeservices"
        ;;
    workflow)
        SERVICE_PATH="services/workflow"
        ;;
    searchservices)
        SERVICE_PATH="services/searchservices"
        ;;
    securityservices)
        SERVICE_PATH="services/securityservices"
        ;;
    *)
        echo "Unknown service: $SERVICE_NAME"
        echo "Available: intakeservices, workflow, searchservices, securityservices"
        exit 1
        ;;
esac

FULL_PATH="$HEALTHSOURCE_DIR/$SERVICE_PATH"

# Verify path exists
if [ ! -d "$FULL_PATH" ]; then
    echo "Error: Service path not found: $FULL_PATH"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Intent Interviewer - CLAUDE.md Generator             ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Service: $SERVICE_NAME"
echo "║  Path:    $SERVICE_PATH"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Starting interactive interview session..."
echo "The agent will analyze the code, then ask you ~10-15 questions."
echo "Answer based on your knowledge - 'I don't know' is fine."
echo ""
echo "Press Enter to begin..."
read

# Build the prompt
PROMPT=$(cat <<EOF
$(cat "$SCRIPT_DIR/PROMPT.md")

---

## This Interview Session

**Service:** $SERVICE_NAME
**Code Path:** $FULL_PATH
**Output:** $FULL_PATH/CLAUDE.md

**Stock Questions Available:** $SCRIPT_DIR/questions.yaml

---

## Begin

1. First, silently analyze the service at $FULL_PATH:
   - Read key source files to understand the structure
   - Check pom.xml for dependencies
   - Look for existing docs/READMEs
   - Note areas of uncertainty

2. Then start the interactive interview with the SME.

3. After the interview, use the Write tool to create:
   $FULL_PATH/CLAUDE.md

Go - start with your analysis, then begin asking questions.
EOF
)

# Launch interactive Claude session in the service directory
cd "$FULL_PATH"
claude "$PROMPT"
