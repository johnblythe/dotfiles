#!/bin/bash
#
# Process a filled questionnaire and generate CLAUDE.md
#
# Usage:
#   ./process-questionnaire.sh questionnaires/intakeservices-questionnaire-filled.md
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTHSOURCE_DIR="$HOME/code/healthsource"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <filled-questionnaire.md>"
    exit 1
fi

QUESTIONNAIRE_FILE="$1"

if [ ! -f "$QUESTIONNAIRE_FILE" ]; then
    echo "Error: File not found: $QUESTIONNAIRE_FILE"
    exit 1
fi

# Extract service name from questionnaire
SERVICE_NAME=$(grep -m1 "^\*\*Service:\*\*" "$QUESTIONNAIRE_FILE" | sed 's/\*\*Service:\*\* //')

if [ -z "$SERVICE_NAME" ]; then
    echo "Error: Could not extract service name from questionnaire"
    exit 1
fi

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
        exit 1
        ;;
esac

FULL_PATH="$HEALTHSOURCE_DIR/$SERVICE_PATH"
OUTPUT_FILE="$FULL_PATH/CLAUDE.md"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Processing Questionnaire → CLAUDE.md                   ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Service: $SERVICE_NAME"
echo "║  Output:  $OUTPUT_FILE"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

PROMPT=$(cat <<EOF
You are generating a CLAUDE.md file from a completed SME questionnaire.

## Input: Completed Questionnaire

$(cat "$QUESTIONNAIRE_FILE")

---

## Your Task

1. Read the questionnaire answers above
2. Also briefly scan the actual code at $FULL_PATH to validate/supplement
3. Generate a token-efficient CLAUDE.md file

## Output Format

Use this structure (skip sections with no useful info):

\`\`\`markdown
# $SERVICE_NAME

> [One-line purpose from questionnaire]

## Scope

**Owns:**
- [bulleted list]

**Does NOT own (common misconception):**
- [from question 1.2]

## Entry Points

| Entry Point | Use Case | Notes |
|-------------|----------|-------|
| \`Class.method()\` | Main flow | [notes] |

## Patterns

- [Pattern]: [brief description]

## Gotchas

⚠️ **NEVER** [thing] because [reason]

⚠️ **ALWAYS** [thing] before [other thing]

## Anti-patterns

❌ Don't: [bad pattern]
✅ Do: [good pattern]

## External Dependencies

| Dependency | Notes |
|------------|-------|
| [Service] | [flakiness, config notes] |

## Known Issues / War Stories

- [Incident]: [what was learned]

## Testing Notes

- [What's hard to test]
- [Required setup]
\`\`\`

## Guidelines

- Be concise - this is for token efficiency
- Use tables and bullets over prose
- Include only actionable knowledge
- If an answer was empty/N/A, skip that part
- Capture the "voice" of the SME's warnings

---

Generate the CLAUDE.md now and save it to: $OUTPUT_FILE
EOF
)

cd "$FULL_PATH"
claude --print "$PROMPT"

if [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo "✅ Generated: $OUTPUT_FILE"
    echo ""
    echo "Preview:"
    head -30 "$OUTPUT_FILE"
    echo "..."
else
    echo ""
    echo "⚠️  File not created. Check Claude output above."
fi
