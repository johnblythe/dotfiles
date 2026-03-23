---
name: find-skills
description: Analyze conversation history to identify patterns, gaps, and repetitions that suggest new skills. Use when user says "analyze this conversation", "what skills would help", "convo analysis", or wants to audit their workflow for skill opportunities.
---

# Find Skills

Analyze conversations to surface skill opportunities.

## Data Source

Conversations stored at: `~/.claude/projects/<project-path>/<session-id>.jsonl`

Each line is JSON with:
- `type`: "user" or "assistant"
- `message.content`: the actual text
- `timestamp`: ISO timestamp
- `cwd`: working directory (indicates project context)

## Process

1. **Determine scope** - Ask user:
   - Current conversation only?
   - Last 7/14/30 days?
   - Specific project?

2. **Load conversations**

```bash
# List all projects
ls ~/.claude/projects/

# Find recent conversations (last 7 days)
find ~/.claude/projects -name "*.jsonl" -mtime -7

# Extract user+assistant messages from a convo
cat <file>.jsonl | jq -c 'select(.type == "user" or .type == "assistant") | {type, content: .message.content, ts: .timestamp}'
```

3. **Scan for signals:**

| Signal | Skill Opportunity |
|--------|-------------------|
| Same code written 2+ times | Script-based skill |
| Repeated domain explanations | Reference-based skill |
| 3+ failed fix attempts | Debugging workflow skill |
| Same clarifying questions | Checklist/scaffold skill |
| Manual steps repeated | Automation script skill |
| Copy-paste from external docs | Reference skill |
| "I always do X before Y" patterns | Workflow skill |
| Context repeatedly re-established | Onboarding skill |
| Output format corrections | Template skill |

4. **Cross-conversation patterns** (for multi-day analysis):
   - Same setup steps across projects
   - Repeated boilerplate code
   - Common error patterns
   - Frequently requested features

## Output Format

```markdown
# Conversation Analysis

**Scope:** [current | 7d | 14d | 30d] across [N] conversations

## Summary
- X patterns detected
- Y skill opportunities identified

## Skill Suggestions

### [Suggested Skill Name]
**Signal:** What pattern was detected (with examples)
**Frequency:** How often it occurred
**Concept:** What the skill would do
**Contents:** scripts/references/assets needed
**Trigger:** When it should activate

## Low-Priority Observations
[minor patterns not worth a full skill]
```

## Guidelines

- Prioritize high-frequency cross-conversation patterns
- Combine related patterns into single skill when logical
- Be specific about trigger phrases
- Note if existing skill covers the need (just wasn't invoked)
- For large history scans, sample strategically rather than exhaustively
