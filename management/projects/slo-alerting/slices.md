---
shaping: true
---

# SLO Alerting Integration — Slices

Parent: [shaping.md](./shaping.md)
Selected shape: **A — DD-native burn rate alerts + Night Light scorecard push**

---

## Slice Overview

Three vertical slices, each independently demo-able:

| Slice | What | Demo |
|-------|------|------|
| **V1** | Fast burn alerts (incident) | Trigger test → PD pages ROI Platform |
| **V2** | Slow burn alerts (ticket) | Trigger test → Slack message in roi-alerts |
| **V3** | Scorecard push | Run script → Confluence table updates with live SLO data |

V1 and V2 are independent (can be built in either order or parallel).
V3 is independent of both.

**Recommended order:** V1 → V2 → V3 (highest-value-first: catch fires, then slow bleeds, then reporting).

---

## V1: Fast Burn Alerts (A1 + A3)

**Goal:** When a domain burns error budget at >14x the sustainable rate over a 5m window, page ROI Platform via PagerDuty.

### Parts

| Part | Mechanism |
|------|-----------|
| **V1.1** | 6 `datadog_monitor` resources (one per domain) querying `burn_rate` on the corresponding monitor-based SLO. Window: 5m actual, 1h budget. Threshold: >14x. |
| **V1.2** | Monitor message includes `@pagerduty-HealthSource`. Priority = 1. |
| **V1.3** | Tags: `domain:<domain>`, `purpose:slo-burn-rate`, `severity:incident` |
| **V1.4** | Variable block `burn_rate_alerts` in `variables.tf` — per-domain enabled/threshold override |

### Files

| File | Action |
|------|--------|
| `modules/datadog-hs-monitors-v2/slo_burn_rate_alerts.tf` | Create — 6 fast-burn + 6 slow-burn monitors (V1 + V2 in same file) |
| `modules/datadog-hs-monitors-v2/variables.tf` | Modify — add `burn_rate_alerts` variable |
| `environments/prod/main.tf` | Modify — add `burn_rate_alerts` config |

### Demo

1. Show new monitors in DD with `purpose:slo-burn-rate` tag
2. Show PD routing in monitor config
3. (If testable) Simulate threshold breach → PD incident fires

### Open: Burn rate math for 98-99% targets

Google SRE multi-window burn rate for 99.9%:
- Fast: 14.4x over 1h (alerts in ~5m of 100% outage)
- Slow: 6x over 6h (alerts on sustained degradation)

Our targets are lower (98-99%), meaning we have MORE error budget. Same multipliers still work — they're ratios relative to sustainable burn. A 14x burn on a 99% SLO means "you'll exhaust your 30d budget in ~2 days at this rate." That's page-worthy.

**Decision: use 14x fast / 6x slow as starting thresholds, tune from there.**

---

## V2: Slow Burn Alerts (A2 + A3)

**Goal:** When a domain burns error budget at >6x the sustainable rate over a 30m window, post to Slack for escalation ticket.

### Parts

| Part | Mechanism |
|------|-----------|
| **V2.1** | 6 `datadog_monitor` resources querying `burn_rate`, long window: 30m actual, 6h budget. Threshold: >6x. |
| **V2.2** | Monitor message includes `@slack-roi-alerts`. Priority = 3. No PD. |
| **V2.3** | Tags: `domain:<domain>`, `purpose:slo-burn-rate`, `severity:ticket` |

### Files

Same as V1 — both fast and slow burn monitors live in `slo_burn_rate_alerts.tf`.

### Demo

1. Show slow-burn monitors in DD alongside fast-burn
2. Show Slack routing (no PD)
3. Show priority 3 vs priority 1 differentiation

---

## V3: Scorecard Push (A4)

**Goal:** Night Light queries DD SLO API for 30d achievement + error budget remaining, updates the Confluence Observability Scorecard.

### Parts

| Part | Mechanism |
|------|-----------|
| **V3.1** | Script (`scripts/slo-scorecard-push.sh` or similar) that calls DD API `v1/slo` for each of the 6 domain monitor-based SLOs |
| **V3.2** | Extracts 30d SLO status (%) and error budget remaining (%) per domain |
| **V3.3** | Updates the "SLO Achievement" table in Confluence page 2531786791 via REST API (ADF format) |
| **V3.4** | Also updates "Current State" column in the domain table (🔴→🟢 based on SLO health) |

### Files

| File | Action |
|------|--------|
| `scripts/slo-scorecard-push.sh` | Create — DD API → Confluence update |
| (Night Light integration) | Future — wire into periodic run |

### Demo

1. Run script manually
2. Show Confluence page before/after — dashes replaced with live data
3. Show domain status indicators updated

---

## Dependency Map

```
V1 (fast burn) ──┐
                  ├── independent, share same TF file
V2 (slow burn) ──┘

V3 (scorecard) ──── fully independent
```

No blocking dependencies. Can parallelize or sequence by priority.
