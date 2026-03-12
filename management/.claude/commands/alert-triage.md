# Alert Triage

Investigate a Datadog alert, identify root causes via parallel subagents, and create Jira tickets.

## Usage
- `/alert-triage <monitor-url-or-id>` — Full triage
- `/alert-triage <monitor-url-or-id> --no-tickets` — Investigation only

## Arguments
$ARGUMENTS

## Steps

1. **Extract monitor ID** from URL or use directly. Parse monitor ID from URLs like `https://app.datadoghq.com/monitors/257641403?...` → `257641403`

2. **Invoke the `alert-triage` skill** — follow its workflow exactly:
   - Phase 1: Fetch monitor config
   - Phase 2: Dispatch 3 parallel investigation subagents
   - Phase 3: Pattern match against known anti-patterns
   - Phase 4: Present findings summary
   - Phase 5: Create Jira tickets (unless `--no-tickets`)

3. **For ticket creation**, ask user for:
   - Sprint (default: current active sprint for their pod)
   - Epic (default: Q1 Reactive Work — HEAL-1330)
   - Sizing (default: 0.5pt each)
   - Pod label

4. **Post summary** formatted for Slack copy-paste.
