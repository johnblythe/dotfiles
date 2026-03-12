# Night Light: Overnight Anomaly Detection Agent

## Purpose

While the team sleeps, Night Light analyzes Datadog metrics to detect anomalies that haven't triggered alerts yet, investigates root causes, and prepares actionable work for morning review.

## Tiered Output

| Tier | Name | Description | Example |
|------|------|-------------|---------|
| 0 | Active Incidents | P1/P2 alerts firing now | Monitor "API Error Rate" in Alert state |
| 1 | Anomalies | Statistical outliers (>2σ from baseline) | Traffic spike 3181 hits (+258% from mean, 4.5σ) |
| 2 | Hygiene | Code quality issues (always runs) | NPEs, deprecation warnings, timeouts |
| 3 | Observability Gaps | Missing or misconfigured monitors | "No alert exists for searchservices latency" |

## Core Loop

```
1. DETECT    → Run anomaly detection on all critical services
2. SCORE     → Severity × Criticality × Impact
3. INVESTIGATE → Map to code, check git history, gather logs
4. DOCUMENT  → Create Jira tickets with evidence
5. FIX       → Draft PRs for high-confidence fixes (optional)
```

## Key Tool: `dd.py`

Located at `~/.claude/skills/investigating-datadog/scripts/dd.py`

```bash
# Anomaly detection (the core feature)
uv run dd.py anomalies hs-securityservices --metric traffic --from 12h
uv run dd.py anomalies hs-platformservices --metric errors --from 12h

# Log search
uv run dd.py logs "service:hs-* status:error" --from 12h

# Full investigation with timeline
uv run dd.py investigate "NullPointerException" --from 24h

# Check monitor status
uv run dd.py monitors --status alert
```

## Anomaly Detection Logic

The detector uses statistical analysis:
- Calculates mean and standard deviation of the metric
- Flags values > 2 standard deviations from mean
- Groups consecutive anomalies into events
- Ranks by severity (critical > warning > notice)

| Pattern | Meaning | Severity |
|---------|---------|----------|
| Traffic spike >2x baseline | Retry storm, attack, upstream issue | HIGH |
| Traffic drop >50% | Service failing silently | HIGH |
| Error spike >3σ | Something broke | HIGH |
| Latency spike >2x | Degraded experience | MEDIUM |
| Multiple services affected | Cascading failure | CRITICAL |

## Configuration

### `services.yaml`

Defines critical services, code paths, and known patterns:

```yaml
services:
  hs-securityservices:
    critical: true
    user_facing: true
    code_path: ~/code/healthsource/services/securityservices/

  hs-searchservices:
    critical: true
    code_path: ~/code/healthsource/services/searchservices/

hygiene_patterns:
  - name: NPE
    query: "NullPointerException service:hs-*"
  - name: Timeout
    query: "status:error timeout service:hs-*"
```

## Running Night Light

### Manual

```bash
cd ~/code/management/night-light
claude -p "run night-light analysis for past 12h"
```

### Cron (e.g., 6am daily)

```bash
0 6 * * * claude --dangerously-skip-permissions -p "run night-light for 12h" ~/code/management/night-light
```

### Permissions

To avoid approval prompts, add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(uv:*)",
      "Bash(cd:*)"
    ]
  }
}
```

## Sample Output

```
# NIGHT LIGHT REPORT - 2026-01-15

═══════════════════════════════════════════════════════════════════
                         TIER 0: ACTIVE INCIDENTS
═══════════════════════════════════════════════════════════════════
✅ None

═══════════════════════════════════════════════════════════════════
                         TIER 1: ANOMALY DETECTION
═══════════════════════════════════════════════════════════════════
Services analyzed: 6
Anomalies detected: 1

### ANO-1: hs-securityservices - Traffic spike
- Severity: CRITICAL (5.0σ, +321% from baseline)
- Time: 2026-01-14 22:10 - 22:40 UTC
- Peak: 3181 hits (baseline: ~750)
- Ticket: HEAL-1234

═══════════════════════════════════════════════════════════════════
                         TIER 2: OPERATIONAL HYGIENE
═══════════════════════════════════════════════════════════════════

### NPE-1: NullPointerException in hs-searchservices
- Count: 12 occurrences overnight
- Sample: `SearchServiceImpl.java:342`
- Suggested fix: Add null-safe Optional wrapper
- Effort: Small

═══════════════════════════════════════════════════════════════════
                         TIER 3: OBSERVABILITY GAPS
═══════════════════════════════════════════════════════════════════
✅ Current monitoring coverage appears adequate

═══════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════

| Tier | Status | Count | Action |
|------|--------|-------|--------|
| 0 - Incidents | ✅ | 0 | None |
| 1 - Anomalies | ⚠️ | 1 | Investigate |
| 2 - Hygiene | ⚠️ | 1 | Small PR |
| 3 - Observability | ✅ | 0 | None |
```

## Key Principles

1. **Data first** - Analyze metrics before checking monitor status
2. **Be specific** - "3181 hits at 22:10 UTC, 5σ from baseline" not "traffic was high"
3. **Prioritize critical services** - Check `services.yaml` for `critical: true`
4. **Identify monitoring gaps** - A key Night Light value-add
5. **Minimal fixes only** - Don't refactor, fix the anomaly cause
6. **When uncertain, ticket only** - A well-documented ticket > wrong PR

## Files

```
night-light/
├── PROMPT.md           # Full agent instructions
├── OVERVIEW.md         # This file
├── services.yaml       # Service definitions
├── runs/               # Historical run outputs
└── .claude/
    └── settings.local.json  # Project permissions
```

## Contributing

To improve Night Light:
1. Add services to `services.yaml`
2. Add hygiene patterns for common issues
3. Update `PROMPT.md` with new investigation techniques
4. Share findings in `runs/` for team learning
