# DW Team Observations — Breadcrumb Trail
**Date:** 2026-02-11 | **Source:** John + Brett (interim mgmt observations)

---

## What's Working Well

### Pre-Assignment at Planning
- All work gets assigned during sprint planning, not ad-hoc mid-sprint
- Per Brett: this is a consistent practice, not a one-off
- Zero unassigned tickets at sprint start
- Shows planning discipline and ownership culture

### Organic Throughput Discovery
- Team stabilized at ~60 pts/sprint across 6 sprints
- No mandate drove this — they found their rhythm naturally
- Pointing discipline improved from ~60% (Q4) to 82-88% (Q1)

### Strong Individual Patterns
- Ben: 9/10 decomposition (sequential dependency chains, DDL in tickets)
- Nina: 8/10 vertical slicing (55% burn at midpoint, best on team)

---

## Needs Tuning

### Points Accuracy
- 4-pt tickets are the most inconsistent size: some = 150 LOC, others = 600+ LOC
- Team needs calibration specifically at the 3-5 pt range
- Some tickets undersized (PDC-6541: 4 pts for multi-service refactor, should be 5-6)
- Some tickets oversized or unverifiable (empty descriptions make sizing meaningless)

### ACs / Descriptions
- 5 tickets with empty or effectively empty descriptions (6 pts of unexecutable work)
- Informal ACs like "check w/ [name]" or "manual testing" with no test plan
- Contrast with Ben: schema DDL, method signatures, file paths in every ticket
- Gap: the good pattern exists on the team, it's just not universal

### Decomposition Quality
- Varies 5x across engineers (Ben 9/10 → Daniel 3/10)
- Team average: 5.9/10
- Monolithic tickets (multi-service refactors in one ticket) vs properly sliced vertical work
- Zero-point subtasks masking real effort in some workstreams

### Specialization / Bus Factor
- Each workstream owned by 1-2 people with no cross-training
- When someone is out, there's no same-position backup — it's the running back playing wide receiver
- This compounds the code review problem: nobody can review what they don't understand
- Knowledge silos → fewer qualified reviewers → reviews sit → WIP grows
- Natural outcome of how work was assigned over time, not a blame issue
- **Risk level: HIGH** — one departure could stall an entire workstream for weeks

---

## Connecting the Dots

```
Specialization Risk
  → Only 1 person knows the code
  → Nobody qualified to review
  → Reviews sit 15-51 days
  → Dependency chains stall
  → Sprint completion suffers

Empty Descriptions
  → Nobody else can help
  → Claude can't assist
  → Work stalls for weeks
  → Points rot in "In Progress"

Pre-Assignment (positive)
  → Everyone knows their work day 1
  → But over-commitment (124 vs 60 pts) dilutes the signal
  → Right-sizing commitment preserves this strength
```

---

*Part of ongoing DW team health data trail. See also:*
- `2026-02-09-dw-sprint-health.md` — sprint health + historical trends
- `2026-02-11-dw-deep-analysis.md` — workstream decomp, sizing, Claude-assistability
