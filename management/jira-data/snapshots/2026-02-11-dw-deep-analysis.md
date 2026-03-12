# DW Sprint Deep Analysis — Composability, Sizing & Claude Workflows
**Date:** 2026-02-11 | **Sprint:** DW 2026.1.3 (Feb 2-14) | **Board:** PDC 319

---

## Executive Summary

65 tickets / 124 pts committed across 7 engineers. Deep analysis of all 6 workstreams against `~/code/healthsource` and `~/code/idsb` repos reveals:

- **Decomposition quality varies 5x** across engineers (Ben exemplary → Dean/Daniel problematic)
- **Code Review is the #1 systemic bottleneck** — 13 items stuck, some 51+ days
- **~60% of remaining sprint work is Claude-assistable** at HIGH or MEDIUM-HIGH level
- **Empty ticket descriptions** are blocking 2 workstreams (Daniel's migration, Dean's testing)
- **Zero-point subtasks** are masking real effort (Gene's deploy gates, Nina's sub-tasks)

---

## Cross-Cutting Findings

### 1. Decomposition Quality Rankings

| Rank | Engineer | Score | Pattern | Example |
|------|----------|-------|---------|---------|
| 1 | **Ben Kittrell** | 9/10 | Sequential dependency chain: Design→Data→API→Integration | DF Retry: Tech Spec(2)→Table(2)→Endpoint(3)→Flow(2) |
| 2 | **Nina Ray** | 8/10 | Proper parent/sub-task with vertical slicing | Specific Provider: Table→DAO→Model→UI across sub-tasks |
| 3 | **Gene Tanaka** | 7/10 (fulfillment), 4/10 (DARCS) | Mixed: Good vertical slices for new features, poor for config/deploy | Custom Abstracts: Draft(4)→Tests(1)→CodeComplete(4)→E2E(5) |
| 4 | **Pryce Bevan** | 4/10 | Sequential waterfall, all stuck in CR | 6 tickets in chain, 0 completions |
| 5 | **Edward Tsao** | 6/10 | Reasonable caching decomp, but 5-pt audit ticket needs splitting | Cache: Baseline(3)→Portal(1)→DF(1)→Invalidation(2) |
| 6 | **Dean Trim** | 5/10 | Multi-service refactor in single ticket, vague testing AC | PDC-6541: RequestWorker+EIPServices+Audit in one 4-pt ticket |
| 7 | **Daniel Centore** | 3/10 | Empty descriptions, stalled 7+ weeks, placeholder tickets | PDC-6758/6759: 3pts each, 4-char descriptions, In Progress since 1.1 |

### 2. Sizing Consistency Analysis

**Consistent (±1 pt of expected):**
- Ben's DF Retry: 2-2-3-2 progression matches code surface area perfectly
- Nina's sub-tasks: 1-3 pts each, proportional to DAO/model/UI work
- Edd's caching policies: 1-pt tasks for pattern application ✅

**Inconsistent / Suspect:**
| Ticket | Assigned | Actual | Issue |
|--------|----------|--------|-------|
| PDC-6541 (Dean) | 4 pts | 5-6 pts | Multi-service refactor + audit API coupling. Undersized. |
| PDC-6542 (Dean) | 4 pts | 2-4 pts | "Manual testing" with no AC. Could be 2 or 6. |
| PDC-6708 (Gene) | 5 pts | 3-5 pts | E2E test plan — monolithic, needs subtask breakdown |
| PDC-6915 (Edd) | 5 pts | 5-7 pts | Audit log impl — Kafka scope TBD, could balloon |
| PDC-6758/6759 (Daniel) | 3+3 pts | Unknown | Empty descriptions make sizing unverifiable |

**Key Pattern:** 4-pt tickets are the most inconsistent size across the team. Some represent 150 LOC (config), others 600+ LOC (multi-service refactor). Team needs calibration at the 3-5 pt range.

### 3. Code Review Bottleneck (Systemic)

| Engineer | Items in CR | Days Stuck | Oldest |
|----------|------------|------------|--------|
| Dean Trim | 4 | 15-21 days | PDC-6540 (Jan 21) |
| Pryce Bevan | 5 | 6+ days | PDC-5111 (multiple sprints) |
| Gene Tanaka | 2 | 51+ days | PDC-6280 (Dec 30) |
| Edward Tsao | 1 | ~5 days | PDC-7050 |
| Ben Kittrell | 1 | ~3 days | PDC-6951 |
| **TOTAL** | **13** | | |

**Root Causes:**
1. No CR SLA — items sit indefinitely
2. No reviewer rotation — unclear who reviews what
3. Deploy gates mixed with code review (Gene's PDC-6644)
4. Sequential dependencies mean one stuck CR blocks entire chains

### 4. Empty/Vague Ticket Descriptions

| Ticket | Engineer | Points | Description Length | Impact |
|--------|----------|--------|--------------------|--------|
| PDC-6758 | Daniel | 3 | 4 chars | Cannot execute migration — no schema spec |
| PDC-6759 | Daniel | 3 | 4 chars | Cannot execute backfill — no logic spec |
| PDC-6542 | Dean | 4 | 213 chars | "Manual testing" — no test plan, no AC |
| PDC-6569 | Dean | 2 | 258 chars | "Check w edd" — informal, no formal AC |
| PDC-6852 | Daniel | 0 | 4 chars | Placeholder — valid but counts toward ticket noise |

**6 pts of committed work have essentially no specification.**

---

## Claude-Assistability Matrix

### By Workstream

| WS | Total Pts | HIGH | MED-HIGH | MEDIUM | LOW | % Assistable |
|----|-----------|------|----------|--------|-----|-------------|
| 1 (Caching/Admin) | 32 | 15 | 5 | 8 | 4 | 72% |
| 2 (DARCS) | 7 | 4 | 0 | 2 | 1 | 57% |
| 3 (Specific Provider) | 29 | 10 | 3 | 8 | 8 | 45% |
| 4 (Fulfillment) | 21 | 12 | 5 | 2 | 2 | 81% |
| 5 (Default Values) | 17 | 8 | 2 | 4 | 3 | 59% |
| 6 (DF Retry) | 14 | 6 | 3 | 5 | 0 | 64% |
| **TOTAL** | **120** | **55** | **18** | **29** | **18** | **~61%** |

### Highest-Value Claude Targets (Quick Wins)

| Ticket | Pts | Engineer | Claude Task | Effort Saved |
|--------|-----|----------|-------------|-------------|
| PDC-5111 | 1 | Pryce | Find-replace "location"→"site" across UI | 1-2h (unblocks 5113) |
| PDC-6952 | 2 | Ben | Generate Flyway migration + MyBatis mapper + POJO (schema given) | 70-80% |
| PDC-6539 | 4 | Dean | Generate DigitalFulfillmentService skeleton + test template | 2-3h |
| PDC-6641 | 2 | Pryce | Generate transparency tag HTML + CSS | 1-2h |
| PDC-6911 | 2 | Pryce | Apply tooltip pattern to logging screens | <1h |
| PDC-5974/75 | 2 | Edd | Apply cache policy pattern from PDC-6276 to new endpoints | 1h each |
| PDC-6706 | 4 | Gene | Generate DOSTable Angular component binding | 2-3h |
| PDC-6758 | 3 | Daniel | Generate migration DDL once schema spec is written | 70-80% |
| PDC-6759 | 3 | Daniel | Generate backfill script once logic is specified | 70-80% |
| PDC-6934 | 1 | Daniel | Generate SQL validation/audit queries | ~1h |

**Total quick-win potential: ~24 pts of work (20% of sprint) acceleratable by Claude.**

### Claude Workflow Categories

| Category | Tickets | Points | Claude Role |
|----------|---------|--------|-------------|
| **Code Generation** (scaffolds, boilerplate) | 6539, 6540, 6706, 6952, 6758, 6759 | 21 | Generate service/endpoint/migration from spec |
| **Test Writing** (unit, integration) | 6705, 6708, 6951 | 9 | Generate test suites from method signatures |
| **Code Review Acceleration** | 5111, 6641, 6911, 6912 | 6 | Review PRs, generate fix suggestions |
| **Tech Spec Drafting** | 6790, 6867, 6851 | 6 | Draft from template + codebase analysis |
| **Config/Deploy** | 5974, 5975, 6569, 7050 | 5 | Apply established patterns to new endpoints |
| **Migration/Backfill** | 6758, 6759, 6761, 6934 | 10 | DDL generation, backfill scripts, audit queries |

---

## Workstream Details

### WS1: RCS Caching + Platform Admin (Dean/Edd) — 32 pts, 3 done (9.4%)

**Key Files Found:**
- `services/eipservices/.../RequestServiceImpl.java` — checkForDFDigitalRules() line 10697, audit methods line 248-299
- `services/requestworker/.../WorkflowServiceImpl.java` — checkForDFDigitalRules() line 636
- `services/eipservices/.../RequestConfigDataCache.java` — existing cache infrastructure
- `services/requestworker/.../AuditTrailCache.java` — cache constants

**Critical Issues:**
1. PDC-6541 (4pts) combines RequestWorker + EIPServices refactor + audit API changes in ONE ticket → should be 5-6 pts or split
2. PDC-6542 (4pts) "manual testing" has no test plan AC
3. PDC-6569 (2pts) spec is "check w edd" — needs formalization
4. 4 PRs stuck 15-21 days in CR — #1 blocker

**Dependency Graph:**
```
PDC-6539 (CR) ──┐
PDC-6540 (CR) ──┼──→ PDC-6541 (CR) ──→ PDC-6542 (IP) ──→ PDC-6917 (Done)
                │
PDC-6569 (CR) ──┘ [needs Edd confirmation]

PDC-6276 (Done) ──→ PDC-5974 (TD) / PDC-5975 (TD) / PDC-7050 (CR)
PDC-6790 (IP) ──→ PDC-6915 (TD) [Kafka scope TBD]
```

### WS2: DARCS Subsite Selector (Gene) — 7 pts, 2 done

**Critical Finding:** Code completed Jan 12. Stuck 51 days in Code Review.
- PDC-6280 (5pts parent) has 3 sub-tasks, all 0-point
- Sub-tasks PDC-6493/6494 are Done but parent can't close
- PDC-6644 (deploy gate) stuck in CR since Jan 27
- Decomp rating: POOR (2/5) — 0-pt tickets mask deploy effort
- Points were revised 8→7→5 over time

**Recommendation:** Separate feature story from deployment gate. Add points to deploy tickets.

### WS3: Specific Provider (Nina) — 29 pts, 16 done (55%)

**Best performer on team.** 55% burn at midpoint.
- Well-structured parent/sub-task chains
- Done tickets: table creation, DAO, model, UI updates — proper vertical slicing
- Remaining To Do tickets are small UI polish (1-2 pts each)
- Claude-assistable: spacing fixes, hover states, radio button styling → HIGH for UI tickets

**Decomposition quality:** Exemplary alongside Ben. Each sub-task is a testable artifact.

### WS4: Partial Fulfillment + Transparency (Gene/Pryce) — 21 pts, 5 done

**Gene (fulfillment):** Good vertical slicing
- PDC-6704 (Draft, 4pts) vs PDC-6706 (Code Complete, 4pts) = sequential phases, NOT duplicates
- Controller logic → Component binding progression
- PDC-6708 (5pts E2E) should split into design/execute/report

**Pryce (transparency):** Stuck in waterfall
- 5 tickets in CR, 0 completions at midpoint
- Sequential dependency chain means one stuck PR blocks everything
- All are small UI changes (1-2pts) — Claude could implement/review quickly
- **Immediate action:** Unblock PDC-5111 (1pt rename) to cascade unblocks

### WS5: Default Values + IEX/AoD (Daniel) — 17 pts, 2.25 done

**CRITICAL RISK:**
- PDC-6758 (3pts migration) and PDC-6759 (3pts backfill) — **4-character descriptions, In Progress 7+ weeks**
- These tickets are unexecutable without specs
- PDC-6852 is a 0-point placeholder
- Tech specs (PDC-6867, 6851) are well-written but implementation is stalled

**Recommendation:**
1. Write descriptions for 6758/6759 TODAY
2. Migration + backfill are HIGHLY Claude-assistable once specs exist
3. SiteConnect (6851) should NOT block Q1 — Phase 2 is Q2+

### WS6: DF Retry + KTLO (Ben) — 14 pts, 7 done (50%)

**EXEMPLARY — Team pattern candidate.**
- Sequential: Tech Spec(2) → Tracking Table(2) → Eligibility Endpoint(3) → Modify Flow(2)
- Each ticket has SQL DDL, method signatures, clear input/output
- Schema provided in ticket description (EREQUEST_DF_RETRY table)
- 60-75% Claude-assistable overall
- Ben's decomposition should be the team standard

**Key Files (inferred):**
- `db/migration/V*.sql` — Flyway migrations
- `RequestServiceDAO.java/.xml` — MyBatis mapper
- `WorkflowWebService.java` — REST endpoints
- `AuditTrailCache.java` — Audit constants

---

## Recommendations

### Immediate (Next 48 Hours)

1. **Unblock Code Reviews** — 13 items stuck. Establish CR SLA (48h max).
   - Priority: PDC-6280 (51 days!), PDC-6539/6540/6541 (15-21 days), PDC-5111 (cascade unblock)

2. **Write Missing Descriptions** — PDC-6758, PDC-6759 need specs before any progress
   - Daniel should spend 1-2h documenting schema changes and backfill logic

3. **Clarify Informal ACs** — "check w edd" (PDC-6569), "manual testing" (PDC-6542)

### Short-Term (This Sprint)

4. **Adopt Ben's Decomposition Pattern** as team standard:
   - Design → Data Layer → API Layer → Integration
   - Each ticket = one testable artifact
   - Include SQL/pseudocode in AC

5. **Stop Zero-Point Subtasks** — Deploy gates and sub-tasks should carry points
   - PDC-6644: upgrade 0→2 pts
   - Nina's sub-tasks: already well-pointed, but some are 0-pt (6493, 6494)

6. **Introduce Claude Workflows** — Start with highest-value targets:
   - Migration/backfill scripts (Daniel's workstream)
   - Test generation (Ben/Gene's workstreams)
   - CR acceleration (Pryce's stuck items)

### Medium-Term (Next Sprint)

7. **Right-size the sprint** — 60 pts capacity, not 124
8. **Establish CR rotation** — Named reviewers per workstream
9. **Calibrate 3-5 pt range** — Most inconsistent size band. Team estimation session.
10. **Split monolithic tickets** — PDC-6541 (multi-service), PDC-6708 (E2E plan)

---

## Key Metrics

| Metric | Value | Target |
|--------|-------|--------|
| Sprint commitment | 124 pts | 60 pts |
| Completion at midpoint | 35 pts (28%) | 30 pts (50%) |
| Items in Code Review | 13 | <5 |
| Tickets w/ empty descriptions | 5 | 0 |
| Zero-point tickets | 8 | 0 (or explicit "tracking only") |
| Claude-assistable work | ~61% (73 pts) | Leverage to add 15-20 pts throughput |
| Avg decomposition quality | 5.9/10 | 7+/10 |

---

*Analysis based on Jira sprint 17065 data + codebase exploration of ~/code/healthsource and ~/code/idsb*
