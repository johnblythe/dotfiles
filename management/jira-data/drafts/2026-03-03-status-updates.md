# Status Update Drafts — 2026-03-03
# Covering gap from 02.09 → 03.02 (End of Q1.S2 + Full Q1.S3)

---
---

# PROJECT 1: DB Scaling (PDCR-294)
# Confluence page: 2316009473

---

## Sprint Q1.S3 (02.16 → 03.02)

### Status

|  |  |
| --- | --- |
| **Health** | ✅ On Track |
| **Progress** | 22 done, 1 in flight, 10 to do |
| **Next Milestone** | PROD backfill completion + FDW validation |

### TL;DR

TRY backfill complete. PROD backfill initiated but running slow — processing ~4K records/sec across 5 parallel year-based runs (2025_q1 synced, 2024 at 64%, others in progress). FDW feature flags fully deployed across eipservices, requestworker, and requeststatushandler. FDW query performance testing complete. Reportservices FDW flag in progress. Open question: ASM script writes directly to DB bypassing message bus — need to determine handling approach.

---

#### Shipped ✅

* **[PR #2697](https://github.com/datavant/healthsource/pull/2697):** Replica FDW, SSL retry, skip-delete, circuit breaker removal (backfill optimizations)
* **[PR #2633](https://github.com/datavant/healthsource/pull/2633):** Direct-connection source hash optimization (backfill)
* **[PR #2651](https://github.com/datavant/healthsource/pull/2651):** ROIP-438 — Complete FDW feature flag for remaining eipservices audit queries
* **[PR #2667](https://github.com/datavant/healthsource/pull/2667):** ROIP-439 — FDW read updates for requestworker
* **[PR #2698](https://github.com/datavant/healthsource/pull/2698):** ROIP-440 — FDW audit trail feature flag for requeststatushandler
* **[PR #2782](https://github.com/datavant/healthsource/pull/2782):** Batch and truncate audit trail queue messages (requeststatushandler)
* **[PR #2615](https://github.com/datavant/healthsource/pull/2615):** Remove unnecessary log lines from audittrailworker
* **[PR #2806](https://github.com/datavant/healthsource/pull/2806):** Removing audit db tables and indices (Snowflake replacement)

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [ROIP-424](https://datavant.atlassian.net/browse/ROIP-424) | Run backfill in TRY | Michael S. |
| ✅ Done | [ROIP-425](https://datavant.atlassian.net/browse/ROIP-425) | Run backfill in PROD | Michael S. |
| ✅ Done | [ROIP-434](https://datavant.atlassian.net/browse/ROIP-434) | FDW Query Performance Testing & Optimization | Michael S. |
| ✅ Done | [ROIP-438](https://datavant.atlassian.net/browse/ROIP-438) | Complete FDW feature flag for remaining eipservices queries | Jeff N. |
| ✅ Done | [ROIP-439](https://datavant.atlassian.net/browse/ROIP-439) | FDW feature flag for requestworker | Jeff N. |
| ✅ Done | [ROIP-440](https://datavant.atlassian.net/browse/ROIP-440) | FDW feature flag for requeststatushandler | Jeff N. |
| 🔄 In Progress | [ROIP-437](https://datavant.atlassian.net/browse/ROIP-437) | FDW feature flag for reportservices | Michael S. |
| ⏳ To Do | [ROIP-423](https://datavant.atlassian.net/browse/ROIP-423) | Re-enable dual-write in QA01 | — |
| ⏳ To Do | [ROIP-435](https://datavant.atlassian.net/browse/ROIP-435) | Add audit backfill Datadog metrics/dashboard | Michael S. |
| ⏳ To Do | [ROIP-436](https://datavant.atlassian.net/browse/ROIP-436) | Modulize Audit Trail interactions | — |
| ⏳ To Do | [ROIP-441](https://datavant.atlassian.net/browse/ROIP-441) | Script post-migration audit table cleanup | — |

---

### Risks & Callouts

* **PROD backfill is slow**: ~4K records/sec across 5 parallel year runs. 2025_q1 synced, 2024 at 64%, 2025_q2 at 35%, 2023 at 23%, 2022 at 0%. Running for ~1 week.
* **ASM script**: Writes directly to the database rather than using the message bus — need to determine how to handle during/after migration
* Legacy table drop (ROIP-406) and reindex/vacuum (ROIP-407) moved to Won't Do — replaced with Snowflake approach

---

### New Tickets Created

* [ROIP-434](https://datavant.atlassian.net/browse/ROIP-434) - FDW Query Performance Testing and Optimization
* [ROIP-435](https://datavant.atlassian.net/browse/ROIP-435) - Add audit backfill Datadog metrics and dashboard
* [ROIP-436](https://datavant.atlassian.net/browse/ROIP-436) - Modulize Audit Trail interactions
* [ROIP-437](https://datavant.atlassian.net/browse/ROIP-437) - Add FDW feature flag to reportservices audit trail queries
* [ROIP-438](https://datavant.atlassian.net/browse/ROIP-438) - Complete FDW feature flag for remaining eipservices audit trail queries
* [ROIP-439](https://datavant.atlassian.net/browse/ROIP-439) - Add FDW feature flag to requestworker audit trail queries
* [ROIP-440](https://datavant.atlassian.net/browse/ROIP-440) - Add FDW feature flag to requeststatushandler audit trail queries
* [ROIP-441](https://datavant.atlassian.net/browse/ROIP-441) - Script post-migration audit table cleanup

---

## End of Sprint Q1.S2 (02.10 → 02.16)

### Status

|  |  |
| --- | --- |
| **Health** | ✅ On Track |
| **Progress** | 20 done, 1 in flight, 8 to do |

### TL;DR

Audit trail queue retry and observability shipped. Backfill view regression fixed. Audit trail batching/truncation for large entries deployed. Preparing for TRY environment rollout.

---

#### Shipped ✅

* **[PR #2533](https://github.com/datavant/healthsource/pull/2533):** Batching and truncation for audit trail entries
* **[PR #2603](https://github.com/datavant/healthsource/pull/2603):** Fix audit backfill view regression and orphaned runs on k8s restart

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [ROIP-432](https://datavant.atlassian.net/browse/ROIP-432) | Audit Trail Queue retry + observability | Jeff N. |
| 🔄 In Progress | [ROIP-406](https://datavant.atlassian.net/browse/ROIP-406) | Drop Legacy Audit Tables | Joshua Y. |
| ⏳ To Do | [ROIP-423](https://datavant.atlassian.net/browse/ROIP-423) | Re-enable dual-write in QA01 | — |
| ⏳ To Do | [ROIP-424](https://datavant.atlassian.net/browse/ROIP-424) | Run backfill in TRY | — |
| ⏳ To Do | [ROIP-425](https://datavant.atlassian.net/browse/ROIP-425) | Run backfill in PROD | — |

---

---
---

# PROJECT 2: Search Optimization (PDCR-404)
# Confluence page: 2296578060

---

## Sprint Q1.S3 (02.16 → 03.02)

### Status

|  |  |
| --- | --- |
| **Health** | ⚠️ At Risk |
| **Progress** | 3 done, 4 in flight, 9 to do |
| **Context** | Intentionally deprioritized behind Athena |

### TL;DR

Intentionally deprioritized this sprint as Athena takes priority. However, new contributors making real progress when capacity allows. Shadow query system (HEAL-1504) completed by Dillon. Name search optimization and API-level tests in code review. Instrumentation work picked up by Stephen. New searchservices optimization tickets created for parallel track.

---

#### Shipped ✅

* **[PR #2659](https://github.com/datavant/healthsource/pull/2659):** HEAL-1504 — Add shadow query system to eipservices search

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [HEAL-1340](https://datavant.atlassian.net/browse/HEAL-1340) | Investigate search execution bottlenecks | Ivan P. |
| ✅ Done | [HEAL-1504](https://datavant.atlassian.net/browse/HEAL-1504) | Alternative query execution path w/ results comparison | Dillon L. |
| 🔄 Code Review | [HEAL-1505](https://datavant.atlassian.net/browse/HEAL-1505) | Query optimization 1: Deal with name searches | Dillon L. |
| 🔄 Code Review | [HEAL-1604](https://datavant.atlassian.net/browse/HEAL-1604) | Add API level tests | Ivan P. |
| 🔄 In Progress | [HEAL-1503](https://datavant.atlassian.net/browse/HEAL-1503) | Add instrumentation to search | Stephen G. |
| 🔄 In Progress | [HEAL-1507](https://datavant.atlassian.net/browse/HEAL-1507) | Query optimization 2: Eliminate unnecessary union | Dillon L. |
| ⏳ To Do | [HEAL-1506](https://datavant.atlassian.net/browse/HEAL-1506) | Run searches off read replica | — |
| ⏳ To Do | [HEAL-1508](https://datavant.atlassian.net/browse/HEAL-1508) | Query optimization 3: Reduce joins | Ivan P. |
| ⏳ To Do | [HEAL-1664](https://datavant.atlassian.net/browse/HEAL-1664) | Spike: medium-to-long-term search approach | Ivan P. |

---

### Risks & Callouts

* **Intentionally deprioritized**: Athena is higher priority; search work happening opportunistically
* New contributors Dillon Lareau and Stephen Galliver bringing capacity — momentum building

---

### New Tickets Created

* [HEAL-1926](https://datavant.atlassian.net/browse/HEAL-1926) - [searchservices] Alternative query execution path w/ results comparison
* [HEAL-1927](https://datavant.atlassian.net/browse/HEAL-1927) - [searchservices] Run searches off read replica
* [HEAL-1928](https://datavant.atlassian.net/browse/HEAL-1928) - [searchservices] Query optimization 3: Reduce joins
* [HEAL-1929](https://datavant.atlassian.net/browse/HEAL-1929) - [searchservices] Add API level tests

---

## End of Sprint Q1.S2 (02.10 → 02.16)

### Status

|  |  |
| --- | --- |
| **Health** | ⚠️ At Risk |
| **Blocker** | Team bandwidth consumed by Athena |

### TL;DR

Minimal movement. API-level tests (HEAL-1604) continuing in code review. Search work remains deprioritized behind Athena — no change from previous week.

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [HEAL-1340](https://datavant.atlassian.net/browse/HEAL-1340) | Investigate search execution bottlenecks | Ivan P. |
| 🔄 In Progress | [HEAL-1604](https://datavant.atlassian.net/browse/HEAL-1604) | Add API level tests | Ivan P. |
| ⏳ To Do | [HEAL-1503](https://datavant.atlassian.net/browse/HEAL-1503) | Add instrumentation to search | Ivan P. |
| ⏳ To Do | [HEAL-1505](https://datavant.atlassian.net/browse/HEAL-1505) | Query optimization 1: name searches | Ivan P. |

---

---
---

# PROJECT 3: Athena Phase 2 (PDCR-409)
# Confluence page: 2271281164

---

## Sprint Q1.S3 (02.16 → 03.02)

### Status

|  |  |
| --- | --- |
| **Health** | ⚠️ At Risk |
| **Progress** | 26 done, 3 in flight, ~10 to do |
| **Concern** | UAT-discovered scope expansion + timeline pressure |

### TL;DR

Major milestone sprint. Request List API, Request Detail API, Workflow Management, Audit Trail, Auth, and Infrastructure epics all completed. Document Upload in UAT. Observability and monitoring work in progress. However, UAT testing exposed unforeseen concerns around Practice Completion and Approval workflows that expand scope beyond initial requirements reading. New implementation plan tickets created. Timeline pressure has returned — thought we were past it, but additional scope pushes delivery dates out.

---

#### Shipped ✅

* **[PR #2607](https://github.com/datavant/healthsource/pull/2607):** HEAL-1724 — JWT validation, disable swagger in prod
* **[PR #2640](https://github.com/datavant/healthsource/pull/2640):** HEAL-1936 — eRequest locking for workflow endpoints
* **[PR #2637](https://github.com/datavant/healthsource/pull/2637):** HEAL-1936 — taskHasAssignee field + NPE fix in workflow error handling
* **[PR #2656](https://github.com/datavant/healthsource/pull/2656):** HEAL-1791 — Fix certification approval workflow transition
* **[PR #2692](https://github.com/datavant/healthsource/pull/2692):** HEAL-1791 — Fix certification decline workflow transition
* **[PR #2708](https://github.com/datavant/healthsource/pull/2708):** HEAL-1791 — Add Fulfillment permission to ROI API role
* **[PR #2634](https://github.com/datavant/healthsource/pull/2634):** HEAL-1551 — Structured logging with Datadog attributes for roiapi
* **[PR #2780](https://github.com/datavant/healthsource/pull/2780):** HEAL-1560 — Correlation ID header + submit permission to ROI API
* **[PR #2568](https://github.com/datavant/healthsource/pull/2568):** HEAL-1722 — Swagger docs for workflow endpoints
* **[PR #2614](https://github.com/datavant/healthsource/pull/2614):** HEAL-1537 — Add certify permission to ROI API

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [HEAL-1537](https://datavant.atlassian.net/browse/HEAL-1537) | Foundation: API Auth & Authorization | Ivan P. |
| ✅ Done | [HEAL-1546](https://datavant.atlassian.net/browse/HEAL-1546) | Foundation: Network & Helm Ingress | Ivan P. |
| ✅ Done | [HEAL-1541](https://datavant.atlassian.net/browse/HEAL-1541) | Backend: Request List API Updates | Alagu E. |
| ✅ Done | [HEAL-1550](https://datavant.atlassian.net/browse/HEAL-1550) | API: Document Upload APIs | Jonathan F. |
| ✅ Done | [HEAL-1551](https://datavant.atlassian.net/browse/HEAL-1551) | Integration: API Logging | Jonathan F. |
| ✅ Done | [HEAL-1558](https://datavant.atlassian.net/browse/HEAL-1558) | Workflow: Certification Workflow | Jonathan F. |
| ✅ Done | [HEAL-1559](https://datavant.atlassian.net/browse/HEAL-1559) | Workflow: Practice Completion Workflow | Jonathan F. |
| ✅ Done | [HEAL-1560](https://datavant.atlassian.net/browse/HEAL-1560) | Integration: Validation & Bug Fixes | Jonathan F. |
| ✅ Done | [HEAL-1722](https://datavant.atlassian.net/browse/HEAL-1722) | Swagger documentation for workflow endpoints | Jonathan F. |
| ✅ Done | [HEAL-1724](https://datavant.atlassian.net/browse/HEAL-1724) | Verify JWT tokens in the API layer | Ivan P. |
| ✅ Done | [HEAL-1781](https://datavant.atlassian.net/browse/HEAL-1781) | Research: eRequest locking for workflow changes | Jonathan F. |
| ✅ Done | [HEAL-1791](https://datavant.atlassian.net/browse/HEAL-1791) | Test and resolve bugs with workflow endpoints | Jonathan F. |
| ✅ Done | [HEAL-1936](https://datavant.atlassian.net/browse/HEAL-1936) | Implement eRequest locking — fast rejection | Jonathan F. |
| 🔄 In Progress | [HEAL-1545](https://datavant.atlassian.net/browse/HEAL-1545) | Research & Planning: Observability | Jonathan F. |
| 🔄 In Progress | [HEAL-1552](https://datavant.atlassian.net/browse/HEAL-1552) | Integration: Metrics Implementation | Jonathan F. |
| 🔄 In Progress | [HEAL-1553](https://datavant.atlassian.net/browse/HEAL-1553) | Integration: DataDog APM Instrumentation | Jonathan F. |
| ⏳ To Do | [HEAL-1549](https://datavant.atlassian.net/browse/HEAL-1549) | API: IntakeService Integration | — |
| ⏳ To Do | [HEAL-1556](https://datavant.atlassian.net/browse/HEAL-1556) | Integration: DataDog Monitoring Dashboard | — |
| ⏳ To Do | [HEAL-1557](https://datavant.atlassian.net/browse/HEAL-1557) | Integration: DataDog Monitors & Alerting | — |
| ⏳ To Do | [HEAL-1782](https://datavant.atlassian.net/browse/HEAL-1782) | Request status notification | Ivan P. |
| ⏳ To Do | [HEAL-2425](https://datavant.atlassian.net/browse/HEAL-2425) | Plan: Implementation for Practice Completion | Jonathan F. |
| ⏳ To Do | [HEAL-2426](https://datavant.atlassian.net/browse/HEAL-2426) | Plan: Implementation for Practice Approval | Jonathan F. |
| 🔬 Scoping | [HEAL-2427](https://datavant.atlassian.net/browse/HEAL-2427) | Implement new plan for Practice Completion | — |
| 🔬 Scoping | [HEAL-2428](https://datavant.atlassian.net/browse/HEAL-2428) | Implement new plan for Practice Approval | — |

---

### Risks & Callouts

* **UAT-discovered scope expansion**: Testing exposed concerns around Practice Completion and Practice Approval workflows that weren't apparent from initial face-value requirements. Not exactly scope creep, but unforeseen expansion.
* **Timeline pressure returning**: Thought we were past it after the foundation sprint, but additional scope from UAT findings reintroduces delivery timeline concerns.
* **Waiting on Athena partner team**: External coordination dependency for UAT and integration validation.

---

### Epic Status Summary

| Epic | Status |
| --- | --- |
| [HEAL-1563](https://datavant.atlassian.net/browse/HEAL-1563) API Scaffolding & Infrastructure | ✅ Done |
| [HEAL-1562](https://datavant.atlassian.net/browse/HEAL-1562) Authentication & Authorization | ✅ Done |
| [HEAL-1342](https://datavant.atlassian.net/browse/HEAL-1342) Request List API | ✅ Done |
| [HEAL-1343](https://datavant.atlassian.net/browse/HEAL-1343) Request Detail API | ✅ Done |
| [HEAL-1344](https://datavant.atlassian.net/browse/HEAL-1344) Workflow Management | ✅ Done |
| [HEAL-1345](https://datavant.atlassian.net/browse/HEAL-1345) Audit Trail | ✅ Done |
| [HEAL-1585](https://datavant.atlassian.net/browse/HEAL-1585) Document Upload API | 🧪 UAT |
| [HEAL-1564](https://datavant.atlassian.net/browse/HEAL-1564) Observability & Monitoring | 🔄 In Progress |
| [HEAL-1586](https://datavant.atlassian.net/browse/HEAL-1586) Post-Delivery Bugfixes | 🔄 In Progress |
| [HEAL-1582](https://datavant.atlassian.net/browse/HEAL-1582) Document Download API | ❌ Won't Do |

---

### New Tickets Created

* [HEAL-1936](https://datavant.atlassian.net/browse/HEAL-1936) - Implement eRequest locking — fast rejection strategy
* [HEAL-2425](https://datavant.atlassian.net/browse/HEAL-2425) - Plan: Implementation for Practice Completion
* [HEAL-2426](https://datavant.atlassian.net/browse/HEAL-2426) - Plan: Implementation for Practice Approval
* [HEAL-2427](https://datavant.atlassian.net/browse/HEAL-2427) - Implement new plan for Practice Completion
* [HEAL-2428](https://datavant.atlassian.net/browse/HEAL-2428) - Implement new plan for Practice Approval

---

## End of Sprint Q1.S2 (02.10 → 02.16)

### Status

|  |  |
| --- | --- |
| **Health** | ✅ On Track |
| **Progress** | 18 done, 6 in flight, ~15 to do |

### TL;DR

Strong week. Audit trail emission for Request Detail API shipped. Certification workflow fixes merged. Upload redirect config deployed. roiapi additional fields added. Multiple auth permissions wired up. Foundation work nearing completion — auth, infrastructure, and request list all converging.

---

#### Shipped ✅

* **[PR #2534](https://github.com/datavant/healthsource/pull/2534):** HEAL-1605 — Audit trail events for request details endpoint
* **[PR #2554](https://github.com/datavant/healthsource/pull/2554):** HEAL-1558 — Fix certification decline to reject then pend
* **[PR #2555](https://github.com/datavant/healthsource/pull/2555):** HEAL-1543 — External URL config for 307 redirect targets
* **[PR #2572](https://github.com/datavant/healthsource/pull/2572):** HEAL-1548 — roiapi additional fields
* **[PR #2591](https://github.com/datavant/healthsource/pull/2591):** HEAL-1537 — Add pend permission to ROI API
* **[PR #2596](https://github.com/datavant/healthsource/pull/2596):** HEAL-1741 — Use request ID as sub-folder

---

| Status | Key | Summary | Owner |
| --- | --- | --- | --- |
| ✅ Done | [HEAL-1605](https://datavant.atlassian.net/browse/HEAL-1605) | Audit trail emission for Request Detail API | Jonathan F. |
| ✅ Done | [HEAL-1601](https://datavant.atlassian.net/browse/HEAL-1601) | SearchService with filters, pagination, read-replica | Alagu E. |
| ✅ Done | [HEAL-1602](https://datavant.atlassian.net/browse/HEAL-1602) | Integrate searchservice into roiapi | Alagu E. |
| 🔄 Code Review | [HEAL-1550](https://datavant.atlassian.net/browse/HEAL-1550) | API: Document Upload APIs | Jonathan F. |
| 🔄 Code Review | [HEAL-1558](https://datavant.atlassian.net/browse/HEAL-1558) | Workflow: Certification Workflow | Jonathan F. |
| 🔄 Code Review | [HEAL-1559](https://datavant.atlassian.net/browse/HEAL-1559) | Workflow: Practice Completion Workflow | Jonathan F. |
| 🔄 In Progress | [HEAL-1537](https://datavant.atlassian.net/browse/HEAL-1537) | Foundation: API Auth & Authorization | Ivan P. |
| 🔄 In Progress | [HEAL-1546](https://datavant.atlassian.net/browse/HEAL-1546) | Foundation: Network & Helm Ingress | Ivan P. |

---
