# Q1 2026 Dashboard

*Last updated: Dec 2024*

## Status at a Glance

```
ATHENA COUNTDOWN        DB HEALTH              EVENT INFRA
━━━━━━━━━━━━━━━━━━━    ━━━━━━━━━━━━━━━━━━━    ━━━━━━━━━━━━━━━━━━━
API Ready: 58 days     Cloud: ✓ UNBLOCKED     Pipeline: NOT STARTED
Prod Live: 100 days    Migration: TESTING     Schema: DEFINED
Risk: MEDIUM           Risk: LOW              Risk: MEDIUM (scoping)
```

## This Week's Focus

| Priority | Item | Owner | Action |
|----------|------|-------|--------|
| P0 | PDCR-451 DB Migration | Platform | Continue cloud testing |
| P0 | PDCR-434 Indirect Chase | I&L | Pilot goes live Jan 6 |
| P1 | PDCR-422 Event Logging | J-Welch | Unblock scoping |
| P1 | PDCR-409 Athena | Alegu | Prep for Feb 14 API milestone |

## Syncs Needed

| Who | About | Urgency |
|-----|-------|---------|
| J-Welch | PDCR-422 scoping — unblock event logging | HIGH |
| Michael & Jenny | PDCR-412 AWS IAM — clarify scope | MED |
| Eric & Tomas | PDCR-405 Ontellus — reconcile 2 vs 9 sprint delta | MED |
| DS Team | PDCR-417 STORK — get Jira populated | MED |
| Vivian | PDCR-167 Pre-Fulfillment — when do designs land? | MED |

## Risks Bubbling Up

| Risk | Impact | Projects | Mitigation |
|------|--------|----------|------------|
| Event scoping delayed | Slows ops efficiency work | PDCR-422, downstream | Sync with J-Welch this week |
| Ontellus scope unclear | 2-9 sprint swing | PDCR-405 | Reconcile with Eric/Tomas |
| Tray App black box | Intake acceleration blocked | PDCR-406 | Spike on Tray App internals |
| Search speed for Athena | Could miss Feb 14 | PDCR-404, 409 | Confirm if on critical path |

## Capacity Snapshot

```
COMMITTED (Above Line)           FIXED ALLOCATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━━━━━━━━━━━━━━━━
~35-40 sprints estimated        Security: 12 sprints
+ TBD items unsized             Reactive: 42 sprints
                                PTO: ~11 sprints
                                ─────────────────────
                                Fixed: ~65 sprints

Q1 = 13 weeks × ? engineers = ??? available sprints
```

## Workstream Health

| Workstream | Status | Notes |
|------------|--------|-------|
| Foundations (DB, Search, Events) | YELLOW | DB unblocked, Events needs scoping |
| Athena | GREEN | On track, hard dates known |
| Quality/UADs | YELLOW | Pre-Fulfillment waiting on designs |
| Integrations | YELLOW | Ontellus scope unclear |
| Q4 Spillover | GREEN | Small items, in motion |

## New/Incoming (Inbox)

| Item | Status | Next Step |
|------|--------|-----------|
| TBD-001 Payer ERM | NEW | Get details, create Jira |
| TBD-002 Provider Retrieval | NEW | Kicks off Feb, get project name |
| TBD-003 DAQARI Phase 1 | NEW | Clarify shadow mode scope |

## Quick Links

- [Timeline / Gantt](timeline.md)
- [Risk Register](risks.md)
- [Themes](themes.md)
- [Team Map](people/team-map.md)
- [Inbox](inbox.md)
- [Blog](blog/README.md)

---

## By Initiative

| Initiative | Key Projects | Status |
|------------|--------------|--------|
| [Stabilize ROI](projects/stabilize-roi/summary.md) | DB Migration, Tray App, Security | Active |
| [Modernize Provider Ops](projects/modernize-provider-ops/summary.md) | Events, Search, Spillovers | Mixed |
| [Quality/UADs](projects/quality-uads/summary.md) | Pre-Fulfillment, STORK, UX | Waiting |
| [Partnerships](projects/partnerships/summary.md) | Athena, Ontellus | On Track |
