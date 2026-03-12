---
name: observability-review
description: Assesses HealthSource monitoring posture — classifies monitors, scores coverage across 10 categories, tracks deltas, updates Confluence scorecard. PROACTIVELY suggest when discussing monitoring improvements, post-incident reviews, or when scorecard is stale.
---

# Observability Review Skill

Evaluate whether monitoring is getting better or worse across 42 HealthSource services.

## Proactive Triggers

Suggest running `/dd-review` when:
- Discussing monitoring improvements, coverage gaps, or HEAL-1699
- Post-incident review where a monitor was missing or slow to fire
- Sprint planning that includes observability work
- "How are our monitors doing?" / "What's our coverage?"
- Scorecard hasn't been updated in >7 days
- After creating monitors via `monitoring-gap` skill

Prompt: **"Want me to run a DD review to score our current monitoring posture?"**

## Key References

| Resource | Location |
|----------|----------|
| dd.py | `~/.claude/skills/investigating-datadog/scripts/dd.py` |
| run_dd.sh | `~/.claude/skills/investigating-datadog/scripts/run_dd.sh` |
| services.yaml | `~/code/management/night-light/services.yaml` |
| Terraform monitors | `~/code/healthsource/monitors/terraform/modules/datadog-hs-monitors-v2/` |
| Confluence Scorecard | Page `2531786791` |
| Confluence Gap Analysis | Page `2531983424` |
| Confluence SLO Framework | Page `2532540468` |
| monitoring-gap skill | `.claude/skills/monitoring-gap/SKILL.md` |
| Night Light runs | `~/code/management/night-light/runs/` |

## Terraform Monitor Files

| File | What It Covers |
|------|----------------|
| `custom_application_monitors.tf` | Service-specific error rates, latency |
| `datadog_monitors.tf` | Generic APM monitors |
| `azure_postgres_monitors.tf` | Database monitors |
| `slo_monitors.tf` | SLO burn-rate monitors |
| `azure_service_bus_monitors.tf` | Service Bus queue monitors |
| `azure_storage_queue_monitors.tf` | Storage queue monitors |
| `k8s_monitors.tf` | Kubernetes/container monitors |
| `asm_monitors.tf` | Application Security monitors |

## Monitor Classification

Classify every monitor into exactly one bucket:

| Class | Criteria | Icon | Action |
|-------|----------|------|--------|
| **Healthy** | Status=OK, no flapping | :white_check_mark: | None |
| **Alerting** | Status=Alert or Warn | :red_circle: | Report; investigate if new (<24h) |
| **Noisy** | >3 state transitions in 24h (from DD events) | :large_orange_diamond: | Tune thresholds or add recovery period |
| **Silent** | Anomaly detected by NL/manual check but monitor didn't fire | :black_circle: | Fix query or threshold |
| **Broken** | Status=No Data | :warning: | Service down or query wrong |
| **Gap** | Service has no monitor for expected category | :white_circle: | Create (link to monitoring-gap skill) |

### How to Detect Each

**Healthy**: `dd.py monitors --json` -> status=OK, then cross-ref events for no Alert->OK->Alert churn.

**Alerting**: `dd.py monitors --json` -> status in (Alert, Warn).

**Noisy**: `dd.py events --tags "source:monitor" --since 24h --json` -> group by monitor_id, count state changes. >3 = noisy.

**Silent**: Compare Night Light anomaly findings (most recent `night-light/runs/*.md`) against monitor alerts. If NL found an anomaly for a service but no monitor fired = silent gap.

**Broken**: `dd.py monitors --json` -> status=No Data.

**Gap**: Cross-reference services.yaml against monitors. If a service has no monitor matching a category = gap.

## Coverage Scoring (10 Categories)

Each category: `score = covered_services / expected_services * 100`

| # | Category | How to Count "Covered" | Expected Count |
|---|----------|----------------------|----------------|
| 1 | **Error Rates** | DD monitors with "error" AND ("rate" OR "percentage") in name/query, OR TF `custom_application_monitors.tf` error_rate resources | 42 (all services) |
| 2 | **Latency** | DD monitors with "duration" OR "latency" OR "percentile" in name/query | 42 (all services) |
| 3 | **JVM Health** | DD monitors with "jvm" OR "heap" OR "gc" in name/query | Java services only (count from services.yaml, exclude frontends and non-Java) |
| 4 | **Database** | TF `azure_postgres_monitors.tf` resources + DD monitors with "postgres" OR "database" | Count unique DB metrics expected (connections, CPU, storage, replication lag, deadlocks) |
| 5 | **SLOs** | TF `slo_monitors.tf` resources + DD SLO count (or `--` if no API) | 8 domains |
| 6 | **Security** | DD monitors with "security" OR "auth" OR "401" OR "403" OR "asm" | Expected auth-related monitors per TF `asm_monitors.tf` |
| 7 | **Synthetics** | DD monitors where type=synthetics | Expected user journey tests (count user_facing services from services.yaml) |
| 8 | **Queues** | TF `azure_service_bus_monitors.tf` + `azure_storage_queue_monitors.tf` resources | Expected per services that use queues |
| 9 | **No-Data Guards** | DD monitors where `notify_no_data=true` (from JSON) | 42 (all services should have at least 1) |
| 10 | **Anomaly Detection** | DD monitors where type contains "anomaly" | Critical services (from services.yaml `critical: true`) x 3 key metrics |

### Counting Methodology

1. Load `services.yaml` -> get total service count, critical services, user_facing services
2. `dd.py monitors --json` -> parse all monitors, extract name, query, type, tags, notify_no_data, status
3. Map monitors to services by matching `service:hs-*` in tags
4. For each category, count distinct services that have at least 1 matching monitor
5. For TF-sourced categories, `grep -c 'resource "datadog_monitor"' <file>.tf` or count resource blocks

### Delta Tracking

- Look for previous dd-review report in `night-light/runs/` (most recent `*-dd-review.md`)
- Parse "Current" column from that report
- Compute delta = current - previous for each category
- Display as `+N` or `-N` in Delta column

## Report Output

Save to `~/code/management/night-light/runs/YYYY-MM-DD-dd-review.md`

```markdown
# DD REVIEW - {DATE}

## Monitor Status
| Status | Count | Change |
|--------|-------|--------|
| Alert | N | +/-N |
| Warn | N | +/-N |
| OK | N | +/-N |
| No Data | N | +/-N |
| **Total** | **N** | |

### Currently Alerting
| Monitor | Duration | Service |
|---------|----------|---------|

### Flapping (>3 transitions/24h)
| Monitor | Transitions | Recommendation |
|---------|-------------|----------------|

### No-Data
| Monitor | Expected Service |
|---------|------------------|

## Coverage Scorecard
| Category | Previous | Current | Delta | Q1 Target | Status |
|----------|----------|---------|-------|-----------|--------|
| Error Rates | N% | N% | +/-N | 50% | On Track / Behind / Exceeded |
| Latency | N% | N% | +/-N | 30% | |
| JVM Health | N% | N% | +/-N | 25% | |
| Database | N% | N% | +/-N | 80% | |
| SLOs | N% | N% | +/-N | 40% | |
| Security | N% | N% | +/-N | 30% | |
| Synthetics | N% | N% | +/-N | 20% | |
| Queues | N% | N% | +/-N | 60% | |
| No-Data Guards | N% | N% | +/-N | 50% | |
| Anomaly Detection | N% | N% | +/-N | 25% | |

## SLO Status
| Domain | Target | 30d Actual | Budget | Status |
|--------|--------|------------|--------|--------|
(8 rows, "--" if not yet defined)

## Action Items
### Tune (noisy/poorly-calibrated)
- [ ] {monitor}: {recommendation}

### Fix (broken/no-data)
- [ ] {monitor}: {diagnosis}

### Create (gaps)
- [ ] {service} needs {category} monitor (use monitoring-gap skill)

## Night Light Cross-Reference
{Reference most recent NL run if within 24h, note any anomalies that overlap with alerting monitors}

## Summary
- **Total monitors:** N
- **Overall coverage:** N% (weighted avg of 10 categories)
- **Active alerts:** N
- **Recommendations:** N action items
- **Trend:** Improving / Stable / Degrading (based on deltas)
```

## Confluence Update Logic

### Scorecard Page (2531786791)

1. Fetch via `confluence_get_page` with `page_id: "2531786791"`
2. Parse existing markdown table for "Observability Coverage"
3. Update "Current" column with today's scores
4. Use `confluence_update_page`:
   - `page_id`: `"2531786791"`
   - `content_format`: `"markdown"`
   - `is_minor_edit`: `true`
   - `version_comment`: `"DD Review auto-update YYYY-MM-DD"`

### Gap Analysis Page (2531983424)

1. Fetch via `confluence_get_page` with `page_id: "2531983424"`
2. Update "Active Alerts" table with currently alerting monitors
3. Same update pattern as scorecard

### Important

- **Read the existing page content first** — preserve all sections not being updated
- Only modify the specific table rows with new data
- If page structure doesn't match expected format, warn and skip (don't corrupt)
- `--no-confluence` flag skips both updates

## Chaining to Other Skills

### monitoring-gap

When gaps are identified:
> "I found N services without {category} monitors. Want me to use the monitoring-gap skill to generate Terraform for the highest-priority ones?"

### investigating-datadog

When alerting monitors need investigation:
> "Monitor {name} has been alerting for {duration}. Want me to investigate with dd.py?"

### Night Light

Cross-reference NL anomaly findings. If NL detected an anomaly that a monitor missed, classify that monitor as **Silent** and recommend threshold adjustment.

## Q1 Targets (Reference)

| Category | Q1 Target | Rationale |
|----------|-----------|-----------|
| Error Rates | 50% | Baseline — cover critical + high-traffic services |
| Latency | 30% | Start with user-facing + API services |
| JVM Health | 25% | Cover critical Java services |
| Database | 80% | Most infrastructure, high leverage |
| SLOs | 40% | 3-4 domains with formal SLOs |
| Security | 30% | Auth services + user-facing |
| Synthetics | 20% | Key user journeys only |
| Queues | 60% | Queue-based services well-known |
| No-Data Guards | 50% | Ensure critical services have no-data alerts |
| Anomaly Detection | 25% | Critical services only |
