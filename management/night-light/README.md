# Night Light

Overnight incident detection and anomaly investigation agent for HealthSource.

## What Changed (v3)

Night Light now uses a **4-tier detection system** that captures both incidents AND operational hygiene:

```
TIER 0: ACTIVE INCIDENTS     - P1/P2 monitors alerting now
TIER 1: ANOMALY DETECTION    - Statistical outliers (>2σ), traffic/latency spikes
TIER 2: OPERATIONAL HYGIENE  - Error patterns, NullPointers, deprecations [NEW]
TIER 3: OBSERVABILITY GAPS   - Missing monitors, threshold recommendations
```

**Why v3?** v2 was great at incident detection but "all clear" reports meant losing the small-win hygiene value. Tier 2 now runs independently - surfacing fixable issues even when no incidents exist.

## Tier Structure

| Tier | Trigger | Example | Action |
|------|---------|---------|--------|
| 0 - Incidents | P1/P2 alert firing | Security Services Hits Outlier | Immediate |
| 1 - Anomalies | >2σ from baseline | 3x traffic spike | Same-day investigation |
| 2 - Hygiene | Any occurrence | NullPointer, timeout, deprecation | Small PR |
| 3 - Observability | Detection gap | Pattern found but no monitor | Backlog |

### Tier 2: Hygiene Patterns

Core patterns (always checked):
- `NullPointerException` - code quality
- `IllegalArgumentException` - input validation
- `deprecated` warnings - tech debt
- `timeout` / `timed out` - performance
- `connection refused` / `reset` - infrastructure

Extended patterns in `services.yaml` (team-configurable).

## Quick Start

```bash
# Dry run (outputs to .md, no Jira/GH changes)
./night-light.sh

# Live run (creates tickets + draft PRs)
./night-light.sh --live

# Custom lookback window
./night-light.sh --hours 4

# Historical replay (incident post-mortem)
./night-light.sh --replay "2026-01-07 17:19" --hours 1
```

## What It Does

1. **Phase 0:** Check alerting monitors (P1/P2)
2. **Phase 1:** Run anomaly detection on critical services (MANDATORY)
3. **Phase 1.5:** Supplement with log analysis for anomaly context
4. **Phase 1.5b:** Run hygiene pattern queries (ALWAYS, independent of anomalies)
5. **Phase 2:** Score and prioritize all findings
6. **Phase 3:** Investigate top items, map to code
7. **Phase 4:** Identify monitoring gaps
8. **Phase 5:** Document in HEAL Jira tickets
9. **Phase 6:** Create draft PRs (confidence ≥4)

## Files

```
night-light/
├── night-light.sh      # Main runner script
├── PROMPT.md           # Agent instructions (v3: tiered detection)
├── services.yaml       # Service mapping + hygiene patterns + incident patterns
├── README.md           # This file
└── runs/               # Output logs (written to ~/code/healthsource/night-light-runs/)
```

## services.yaml Structure

```yaml
services:              # 50+ services mapped from healthsource charts
  hs-securityservices:
    critical: true
    user_facing: true
    incident_patterns: [...]

aliases:               # DD name → code mapping
  hs-stageworker: hs-artifactprocessor

incident_patterns:     # Known incident signatures (INC-930, etc.)

hygiene_patterns:      # Tier 2 detection patterns [NEW in v3]
  core_npe:
    query: "NullPointerException service:hs-*"
    category: code_quality
    effort: small
  search_slow_query:
    query: 'service:hs-searchservices "slow query"'
    category: performance
    suggested_fix: Review query plans, add indexes

hygiene_categories:    # Pattern groupings with icons
  code_quality: { icon: "🔧", typical_effort: small }
  performance: { icon: "⚡", typical_effort: medium }
```

## Report Format (v3)

```
# NIGHT LIGHT REPORT - 2026-01-13

═══════════════════════════════════════════════════════════════════
                         TIER 0: ACTIVE INCIDENTS
═══════════════════════════════════════════════════════════════════
✅ None

═══════════════════════════════════════════════════════════════════
                         TIER 1: ANOMALY DETECTION
═══════════════════════════════════════════════════════════════════
Services analyzed: 6
✅ All services within normal bounds

═══════════════════════════════════════════════════════════════════
                         TIER 2: OPERATIONAL HYGIENE
═══════════════════════════════════════════════════════════════════
### NPE-1: NullPointerException in hs-searchservices
- Count: 12 occurrences overnight
- Suggested fix: Add null-safe Optional wrapper
- Effort: Small

═══════════════════════════════════════════════════════════════════
                         TIER 3: OBSERVABILITY GAPS
═══════════════════════════════════════════════════════════════════
- Consider adding monitor for searchservices NPE pattern

═══════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════
| Tier | Status | Count | Action |
|------|--------|-------|--------|
| 0 - Incidents | ✅ | 0 | None |
| 1 - Anomalies | ✅ | 0 | None |
| 2 - Hygiene | ⚠️ | 1 | Small PR |
| 3 - Observability | 💡 | 1 | Backlog |
```

## Morning Review

```bash
# Check what Night Light found
ls -la ~/code/healthsource/night-light-runs/

# See draft PRs
gh pr list --author @me --draft --search "night-light"

# Check Jira tickets
acli jira workitem search --jql 'labels = night-light' --csv
```

## Scheduled Runs

For overnight automation via launchd:

```bash
launchctl load ~/Library/LaunchAgents/com.nightlight.plist
launchctl unload ~/Library/LaunchAgents/com.nightlight.plist
```

## Adding Hygiene Patterns

To extend Tier 2 detection, add to `services.yaml`:

```yaml
hygiene_patterns:
  my_new_pattern:
    name: Descriptive name
    query: 'service:hs-myservice "error pattern"'
    category: code_quality  # or performance, infrastructure, etc.
    effort: small           # small, medium
    suggested_fix: What to do about it
```

## Detection Coverage

| Tier | Signal Type | Detection Method |
|------|-------------|------------------|
| 0 | Monitor alerts | `dd.py monitors --status alert` |
| 1 | Traffic outliers | `dd.py anomalies SERVICE --metric traffic` |
| 1 | Latency spikes | `dd.py anomalies SERVICE --metric latency` |
| 1 | Error spikes | `dd.py anomalies SERVICE --metric errors` |
| 2 | NullPointer | `dd.py logs "NullPointerException service:hs-*"` |
| 2 | Timeouts | `dd.py logs 'status:error timeout service:hs-*'` |
| 2 | Deprecations | `dd.py logs 'status:warn *deprecated*'` |
| 3 | Gaps | Analysis of findings vs existing monitors |
