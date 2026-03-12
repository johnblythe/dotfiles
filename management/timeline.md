# Portfolio Timeline

## Q1 2026 Gantt

```mermaid
gantt
    title Q1 2026 Portfolio
    dateFormat YYYY-MM-DD
    axisFormat %b %d

    section Foundations
    PDCR-451 DB Migration (MD)        :db, 2026-01-06, 4w
    PDCR-404 Search Speed (LG)        :search, 2026-01-06, 8w
    PDCR-422 Event Logging (XL)       :events, 2026-01-13, 12w

    section Athena (Hard Dates)
    PDCR-409 Athena Phase 2           :athena, 2026-01-13, 11w
    API Endpoints Ready               :milestone, m1, 2026-02-14, 0d
    Integration Testing Complete      :milestone, m2, 2026-03-07, 0d
    Production Live                   :milestone, m3, 2026-03-28, 0d

    section Quality / UADs
    PDCR-167 Pre-Fulfillment (6wk)    :prefill, 2026-02-03, 6w
    PDCR-411 Pull List (SM)           :pull, 2026-01-20, 2w
    PDCR-410 RfR UX Alpha (TBD)       :rfr, 2026-02-10, 4w
    PDCR-435 Verify Assist UX (TBD)   :verify, 2026-02-17, 4w
    PDCR-417 STORK (LG)               :stork, 2026-02-03, 8w

    section Integrations
    PDCR-405 Ontellus Ph2 (MD?)       :ont, 2026-02-17, 4w
    TBD-002 Provider Retrieval        :prov, 2026-02-10, 8w
    PDCR-412 AWS IAM (TBD)            :iam, 2026-02-24, 2w

    section Q4 Spillover
    PDCR-434 Indirect Chase (SM)      :chase, 2026-01-06, 2w
    PDCR-433 Duplicate Logic (SM)     :dup, 2026-01-06, 2w
    PDCR-443 Embedded Reporting (SM)  :embed, 2026-01-13, 2w
    PDCR-444 Correspondence (MD)      :corr, 2026-01-20, 4w

    section Fixed / Parallel
    PDCR-432 Tray App Cert            :tray, 2026-01-06, 12w
    Security & Reactive               :sec, 2026-01-06, 12w

    section At Risk (Unscheduled)
    PDCR-418 Payment Integrity (LG)   :crit, 2026-03-01, 4w
    PDCR-406 Intake Acceleration (LG) :intake, 2026-03-01, 4w
```

## Key Milestones

| Date | Project | Milestone | Status |
|------|---------|-----------|--------|
| Jan 6 | PDCR-434 | Indirect Chase pilot begins | Pending |
| Feb 14 | PDCR-409 | HS API endpoints ready for Athena integration testing | Pending |
| Mar 7 | PDCR-409 | Integration testing complete, hand off to Athena validation | Pending |
| Mar 28 | PDCR-409 | Production live, begin customer testing | Pending |
| TBD | PDCR-432 | Tray App cert updated before expiry | Pending |

## By Pod Allocation

| Pod | Projects | Total Sprints (Est) |
|-----|----------|---------------------|
| Platform | DB Space, Tray App Cert, Athena Ph2, Intake Accel, Ontellus | ~12 + fixed |
| Intake & Logging | Event Logging, Search Speed, STORK, Pull List, RfR UX | ~11 |
| Fulfillment & QC | Event Logging, Search Speed, Pre-Fulfill Review, Correspondence, AWS IAM | ~10 |
| KTLO | Tray App Cert, Embedded Reporting | ~3 |
| Newfire | Duplicate Logic | ~1 |

## Fixed Allocations (ongoing)

| Item | Sprints | Pod |
|------|---------|-----|
| Security (Sailpoint, vulns) | 12 (2/wk) | Platform |
| Reactive Work | 42 (7/wk) | Mixed |
| PTO | 10.8 | All |

## Dependencies to Track

- PDCR-422 (Event Logging) — J-Welch scoping, but PRD is workable
- PDCR-167 (Pre-Fulfillment) — waiting on designs
- PDCR-412 (AWS IAM) — needs Michael & Jenny sync
- PDCR-410 (RfR UX) — needs Paul/Jen M discussion
- PDCR-417 (STORK) — needs DS team sync
- PDCR-405 (Ontellus) — scope unclear (2 vs 9 sprint delta)

## Notes

- Dates are estimates based on current info; many need workshopping
- "At Risk" section shows unscheduled items with scope questions
- TBD-001 (Payer ERM), TBD-003 (DAQARI Ph1) not shown — need scoping
