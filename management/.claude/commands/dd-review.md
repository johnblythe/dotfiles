# Datadog Observability Review

Assess monitoring posture across HealthSource services. Classifies monitors, scores 10 coverage categories, tracks deltas, optionally updates Confluence.

## Usage
- `/dd-review` — Full review + Confluence update
- `/dd-review --no-confluence` — Local report only
- `/dd-review --since 48h` — Extend event lookback window (default 24h)

## Prerequisites
- `dd.py` available at `~/.claude/skills/investigating-datadog/scripts/dd.py`
- Run wrapper: `~/.claude/skills/investigating-datadog/scripts/run_dd.sh`
- Datadog API keys configured (DD_API_KEY, DD_APP_KEY in env or keychain)

## Execution Phases

### Phase 1: Inventory

Gather all monitoring assets:

```bash
# 1a. All DD monitors (JSON for parsing)
~/.claude/skills/investigating-datadog/scripts/run_dd.sh monitors --json 2>/dev/null

# 1b. TF monitor definitions (count resources per file)
TF_DIR=~/code/healthsource/monitors/terraform/modules/datadog-hs-monitors-v2
for f in custom_application_monitors.tf datadog_monitors.tf azure_postgres_monitors.tf slo_monitors.tf azure_service_bus_monitors.tf azure_storage_queue_monitors.tf k8s_monitors.tf asm_monitors.tf; do
  echo "$f: $(grep -c 'resource "datadog_monitor"' $TF_DIR/$f 2>/dev/null || echo 0)"
done

# 1c. Load services.yaml
cat ~/code/management/night-light/services.yaml
```

Also fetch Confluence scorecard for previous scores:
- Use `confluence_get_page` with `page_id: "2531786791"`

### Phase 2: Live State

```bash
# 2a. Currently alerting monitors
~/.claude/skills/investigating-datadog/scripts/run_dd.sh monitors --status alert --json 2>/dev/null

# 2b. Monitor events (state changes in last 24h, or --since value)
~/.claude/skills/investigating-datadog/scripts/run_dd.sh events --tags "source:monitor" --since 24h --json 2>/dev/null

# 2c. Check for recent Night Light runs
ls -la ~/code/management/night-light/runs/ | tail -5
```

Read the most recent Night Light run if within 24h for cross-reference.

### Phase 3: Assessment

Using the `observability-review` skill's classification and scoring logic:

1. **Classify each monitor** into: Healthy, Alerting, Noisy, Silent, Broken, Gap
   - Parse monitor JSON for status, notify_no_data, type
   - Cross-ref events for flapping detection (>3 transitions = Noisy)
   - Cross-ref NL anomaly findings for Silent gaps

2. **Score 10 categories** per skill definitions:
   - Map monitors to services via `service:hs-*` tags
   - Count covered vs expected per category
   - Calculate percentage

3. **Compute deltas** from previous dd-review report:
   - Find most recent `night-light/runs/*-dd-review.md`
   - Parse Previous/Current columns
   - Calculate change

### Phase 4: Report

Generate markdown report following the template in `observability-review` SKILL.md.

Save to: `~/code/management/night-light/runs/YYYY-MM-DD-dd-review.md`

Display the full report to the user.

### Phase 5: Confluence Update (unless --no-confluence)

Update two pages using MCP Confluence tools:

**Scorecard (2531786791):**
1. `confluence_get_page` — fetch current content
2. Parse the "Observability Coverage" table
3. Update "Current" column with today's scores
4. `confluence_update_page` with `is_minor_edit: true`, version comment `"DD Review auto-update YYYY-MM-DD"`

**Gap Analysis (2531983424):**
1. `confluence_get_page` — fetch current content
2. Update "Active Alerts" section
3. Same update pattern

**Safety:** If page structure doesn't match expected format, warn and skip. Never overwrite content you don't understand.

## After the Review

Based on findings, suggest next actions:
- **Noisy monitors**: "Want me to look at tuning thresholds for {monitor}?"
- **Gaps found**: "I found N gaps. Want me to use the monitoring-gap skill to generate Terraform?"
- **Alerting monitors**: "Want me to investigate {monitor} with dd.py?"
- **Coverage declining**: "Coverage dropped in {category}. Might be related to {recent change}."

## Example Output (abbreviated)

```
# DD REVIEW - 2026-02-13

## Monitor Status
| Status | Count | Change |
|--------|-------|--------|
| Alert | 3 | -1 |
| OK | 45 | +2 |
| No Data | 2 | 0 |

## Coverage Scorecard
| Category | Previous | Current | Delta | Q1 Target | Status |
|----------|----------|---------|-------|-----------|--------|
| Error Rates | 12% | 15% | +3 | 50% | Behind |
| Database | 75% | 80% | +5 | 80% | On Track |
...

## Action Items
### Create (gaps)
- [ ] hs-workflow needs error rate monitor
- [ ] hs-cipui needs synthetic test
```
