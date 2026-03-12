## DW Sprint 2026.1.3 — Health Check
**Date:** 2026-02-09 | **Sprint:** Feb 2–14 | **Board:** 319 | **Sprint ID:** 17065

---

### Snapshot

| Metric | Value |
|---|---|
| Total tickets | 65 |
| Committed points | 124 |
| Done points (midpoint) | 35 (28%) |
| Code Review bottleneck | 13 tickets |
| To Do at midpoint | 15 tickets |
| Carryover from 1.2 | 28 tickets |
| Multi-sprint zombies (3+) | 18 tickets |
| Unpointed tickets | 9 |

### Sprint Goals vs Reality
Goals stated: Partial Fulfillment Demo (Pryce & Gene), Cache (Edd), Platform Admin table deletion (Dean), Default values (Daniel)

Actual: 17 distinct parent epics in flight across 7 engineers.

---

### Sprint-Over-Sprint Trend

| Sprint | Period | Tickets | Committed | Completed | % | Carryover IN |
|---|---|---|---|---|---|---|
| 12814 | Dec 8–22 | 40 | 43 pts | 31 pts | 72% | 15 |
| 12815 | Dec 22–Jan 5 | 25 | 45 pts | 34 pts | 76% | 22 |
| 17064 (1.1) | Jan 5–17 | 40 | 79 pts | 60 pts | 76% | 22 |
| 17066 (1.2) | Jan 20–31 | 44 | 96 pts | 60 pts | 63% | 27 |
| **17065 (1.3)** | **Feb 2–14** | **65** | **124 pts** | **35 @ mid** | **~28%** | **28** |

**Key trend:** Committed points escalating (43→124), carryover growing (15→28), completion rate declining (76%→63%→~50% projected).

**Sustainable throughput: ~60 pts/sprint.** Sprint 1.3 committed 124 — more than 2x capacity.

---

### Per-Person Trends (pts done / pts committed)

| Engineer | 12814 | 12815 | 1.1 | 1.2 | 1.3 (mid) | Pattern |
|---|---|---|---|---|---|---|
| Nina Ray | 14/15 | 14/14 | 16/22 | 19/25 | 16/29 | Consistent ~16 pts output. Load keeps growing. Being punished for delivering. |
| Gene Tanaka | 0/5 | 2/7 | 9/14 | 9/14 | 7/22 | Steady ~9 pts. 2 PRs in CR since Jan 12 (4 weeks, 3 sprints). |
| Dean Trim | 5/6 | 5/6 | 5.5/10.5 | 5/18 | 0/17 | Output flat ~5 pts. Load tripled. 3 PRs stuck in CR since sprint 1.1. Zero completions current sprint. |
| Edward Tsao | 4/4 | 4/4 | 7/7 | 8/10 | 3/15 | Was perfect 3 sprints running. Load jumped, output collapsed. Cache work dragging. |
| Daniel Centore | 6/6 | 6/6 | 8/11 | 8/14 | 2.25/17 | Steady ~8 pts. 2 migration tickets stale since 1.1. Placeholder ticket with no points. |
| Pryce Bevan | 4/4 | — | 9/9 | 7/9 | 0/10 | Boom/bust. Perfect 1.1, now 5 items in CR, zero completions. |
| Ben Kittrell | 2/2 | 3/3 | 6/6 | 4/6 | 7/14 | Healthiest. Consistent delivery. Reasonable load. |

---

### Structural Issues

**1. Code Review bottleneck is the #1 problem**
- 13 items in Code Review (same count as In Progress)
- Dean: 3 PRs stuck since sprint 1.1 (3+ weeks)
- Gene: 2 PRs stuck since Jan 12 (4 weeks)
- Pryce: 5 items in CR
- No evidence of review rotation, SLA, or prioritization

**2. No capacity-based planning**
- Team delivers ~60 pts when loaded right
- Sprint 1.3 committed 124 pts — 2x+ capacity
- Carryover treated as free — not counted against next sprint capacity

**3. Bulk carryover without re-commitment**
- 12 tickets show `updated: 2026-02-02` (sprint start date) — auto-carried, not intentionally re-committed
- 18 tickets have been in 3+ consecutive sprints

**4. Too many concurrent workstreams**
- 17 parent epics across 7 engineers = massive context switching
- Sprint goals name 4 workstreams; actual sprint has 10+

**5. Top performers getting overloaded**
- Nina: 15 → 25 → 29 pts committed (output stays ~16)
- This will eventually break

**6. Story pointing discipline is new**
- Nov sprints had 45/47 tickets unpointed
- Pointing only started ~Dec 2025
- Historical velocity data unreliable before then

---

### Stale Items (In Progress/CR, not updated since sprint start)

| Ticket | Status | Assignee | Last Updated | Summary |
|---|---|---|---|---|
| PDC-6539 | Code Review | Dean Trim | 2026-02-02 | Create DigitalFulfillmentService and additional tests |
| PDC-6540 | Code Review | Dean Trim | 2026-02-02 | Add isEligibleForDigitalFulfillment web service endpoint |
| PDC-6541 | Code Review | Dean Trim | 2026-02-02 | Update Request Worker and EIPServices to use DigitalFulfillmentService |
| PDC-6280 | Code Review | Gene Tanaka | 2026-02-02 | Use DARCS to control subsite selector show/hide |
| PDC-6644 | Code Review | Gene Tanaka | 2026-02-02 | [CIPUI][Deploy] DARCS subsite selector |
| PDC-6569 | In Progress | Dean Trim | 2026-02-02 | Add/Enable/Check Caching of the RCS Endpoint |
| PDC-6542 | In Progress | Dean Trim | 2026-02-02 | Manual Testing In Try/Staging |
| PDC-6758 | In Progress | Daniel Centore | 2026-02-02 | [Default Values] Write Migration |
| PDC-6759 | In Progress | Daniel Centore | 2026-02-02 | [Default Values] Write Backfill Script |
| PDC-6664 | In Progress | Ben Kittrell | 2026-02-02 | Reconcile Volume Move Tool params with postman API |
| PDC-6536 | In Progress | Nina Ray | 2026-02-02 | Specific Provider Config - DARCS |
| PDC-6792 | In Progress | Nina Ray | 2026-02-02 | Build out e2e feature flag for showing/hiding search |

---

### Bottom Line

The sprint is overcommitted and under-delivering. The core pattern: work enters Code Review and stays for weeks, gets bulk-carried to next sprint, inflating ticket count while real throughput stays flat. Team starts new work before finishing old work — classic flow problem.

**The problem is planning, not execution.** Nobody is gating commitment to capacity. Carryover isn't being accounted for. And Code Review has no SLA or prioritization.
