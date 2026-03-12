---
shaping: true
---

# SLO Alerting Integration — Shaping

## Source

> everything is merged in now. they were def noisy though so we're lowering the chatter for the moment.

Context: We shipped 15 metric-based SLOs (request success rate), 6 monitor-based SLOs (time availability), 6 health monitors, and a TF-managed dashboard across PRs #2587 and #2602. The health monitors fired too aggressively — thresholds and no-data windows need tuning. But the bigger gap: SLOs are passive. Nobody gets notified when error budget burns. Teams learn about availability issues from customer complaints or retros, not from SLOs.

---

## Problem

We have SLOs that measure availability but don't drive action. Error budgets burn silently. The dashboard exists but is pull-only — someone has to look at it. When a domain degrades gradually (not a hard outage), nobody notices until a retro or ELT asks "what happened last week?"

---

## Outcome

The right person gets notified at the right time when error budget consumption indicates a real problem — not noise. SLO health becomes an input to incident response, not a post-hoc reporting tool.

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Alert when error budget burn rate indicates a real problem (not transient noise) | Core goal |
| 🟡 R1 | Two severity tiers: fast burn → incident (page), slow burn → escalation ticket | Must-have |
| 🟡 R2 | Routes to ROI Platform team (single destination, two pods) | Must-have |
| 🟡 R3 | Tolerate deploy-induced error spikes without false-firing | Nice-to-have |
| 🟡 R4 | SLO achievement data pushes to Confluence Observability Scorecard (page 2531786791) periodically — not real-time alerts for ELT | Must-have |
| 🟡 R5 | SLO burn rate alerts complement existing service monitors — both can fire. If both fire, it confirms the problem is real (not noise). No suppression needed. | Must-have |
| R6 | Works with existing PagerDuty + Slack infrastructure | Must-have |

**Decisions:**
- R1: Two tiers, not more. Incident = "wake someone up." Ticket = "look at this today."
- R2: Single team for now. Per-domain routing is a later concern.
- R3: Deploys happen throughout the day, no predictable windows. Can't use scheduled downtime. Reframed as "tolerate spikes" — this is about burn rate window math, not muting. Downgraded to nice-to-have since multi-window burn rate (R1) naturally absorbs short spikes.
- R5: No suppression. Both can fire — if a service monitor AND an SLO burn rate alert fire, that's signal, not noise. Overlap confirms severity.

---

## Shapes

### A: DD-native burn rate alerts + Night Light scorecard push

All alerting stays in Datadog (TF-managed). Scorecard updates via Night Light automation.

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **A1** | **Burn rate monitors (fast)** — Per-domain `datadog_monitor` on `burn_rate` metric, short window (5m actual / 1h budget). Threshold: burning >14x budget rate. Fires to PD (incident). | |
| **A2** | **Burn rate monitors (slow)** — Per-domain `datadog_monitor` on `burn_rate` metric, long window (30m actual / 6h budget). Threshold: burning >6x budget rate. Fires to Slack only (escalation ticket). | |
| **A3** | **Priority separation** — Fast-burn monitors get `priority = 1` (pages). Slow-burn get `priority = 3` (ticket). Existing service monitors keep current priorities. No suppression — overlap is signal. | |
| **A4** | **Night Light scorecard push** — Script queries DD SLO API for 30d achievement + error budget remaining per domain, updates the Confluence Observability Scorecard table via REST API. Runs weekly (or on-demand). | |

---

## Fit Check: R × A

| Req | Requirement | Status | A |
|-----|-------------|--------|---|
| R0 | Alert when error budget burn rate indicates a real problem (not transient noise) | Core goal | ✅ |
| R1 | Two severity tiers: fast burn → incident (page), slow burn → escalation ticket | Must-have | ✅ |
| R2 | Routes to ROI Platform team (single destination, two pods) | Must-have | ✅ |
| R3 | Tolerate deploy-induced error spikes without false-firing | Nice-to-have | ✅ |
| R4 | SLO achievement data pushes to Confluence Observability Scorecard periodically | Must-have | ✅ |
| R5 | SLO burn rate alerts complement existing service monitors — both can fire. If both fire, it confirms the problem is real. No suppression needed. | Must-have | ✅ |
| R6 | Works with existing PagerDuty + Slack infrastructure | Must-have | ✅ |

Shape A passes all requirements. No flags remaining. B dropped (failed R4).

---

## Open Questions

| # | Question | Relates to |
|---|----------|------------|
| Q1 | What are the right burn rate multipliers for our SLO targets? Google SRE suggests 14x/6x for 99.9% — our targets are 98-99%, so thresholds may differ. | A1, A2 |
