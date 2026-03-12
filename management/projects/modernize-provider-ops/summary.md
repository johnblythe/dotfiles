# Modernize Provider Ops

Strategic initiative to improve operational efficiency, workflow modernization, and provider experience.

## Active Projects

### PDCR-422: Event-based Logging for Time-on-Task ⭐ FOUNDATIONAL
- **Status:** Above the line
- **Size:** XL (6 sprints) — fuzzy, waiting on scoping
- **Pod:** Intake & Logging, Fulfillment & QC
- **Owner:** J-Welch on point for scope of events/subtasks
- **Dependencies:** Platform Engineering (pipeline), Analytics Engineering (schema), Security (compliance)
- **What:** Build event-driven logging infrastructure for time-on-task analytics. Captures discrete user interactions (start, active, complete) with standardized schema.
- **Tech:** Event schema (event_id, timestamp, user_id, session_id, event_type, metadata), ingestion pipeline (Kafka/Snowflake), <5min latency
- **Phases:**
  - Phase 1 (Experiment): 2 pilot workflows, validate pipeline
  - Phase 2 (Alpha): Expand surfaces, finalize schema
  - Phase 3 (GA): Standardize across all workflows
- **Blocker:** Waiting on J-Welch scoping/reqs
- **⭐ Strategic Value:** Phase 1 builds event infrastructure that 4+ other projects can leverage (Ontellus, Pre-Fulfillment, Provider Retrieval, eventually Athena). "Start slow to move fast" — foundational investment.

### PDCR-404: Improve Search Speed in HealthSource
- **Status:** Above the line
- **Size:** LG (4 sprints, 8 BC)
- **Pod:** Intake & Logging, Fulfillment & QC
- **What:** Query performance is terrible — unbounded subqueries causing massive scans, bad indexing, queries timing out after 1hr+
- **Impact:** Affects UI customers, HealthSource users, and API consumers
- **Approach:** Multiple strands — query optimization, indexing fixes, possibly read replicas
- **Note:** Well-understood problem, just needs execution. Should be targeted fixes (indexes, query rewrites), NOT architectural changes.
- **Related:** PDCR-451 (DB Space Mitigation), PDCR-413 (DB Horizontal Strategy) — separate efforts

### PDCR-406: SPIKE - Intake Acceleration for e-Request ID Generation
- **Status:** Above the line (Parking Lot in Jira — confirm status)
- **Size:** LG (4 sprints, 1 BC)
- **Pod:** Platform
- **PRD:** [Google Doc](https://docs.google.com/document/d/1k4vRDniWMP_AoraONkn2gIfiRVTjKJY2B9bbhzJUjqw/edit)
- **What:** Reduce intake latency from hours → minutes across all sources (print/scan, upload). DataDog telemetry, SLA alerting, optimize orchestration/NLP flows.
- **Theme link:** Intake Consolidation (core), Event-Driven Architecture (observability)
- **Risk:** Tray App is the unknown. Server-side intake work is tractable, but Tray App (customer-installed print/scan queue) is:
  - Legacy code, poorly understood internally
  - Hard to modify
  - Change management burden on customers
- **Related:** PDCR-432 (Tray App Cert) — same codebase/customer touchpoint

### PDCR-412: Strategic Connection AWS IAM Integration
- **Status:** Above the line (Parking Lot in Jira — confirm status)
- **Size:** TBD (0.5 BC)
- **Pod:** Fulfillment & QC
- **What:** Enable HealthSource to call Strategic Connections intake API via AWS SigV4 auth. IAM role setup + signing implementation.
- **Action:** ⚠️ Sync with Michael & Jenny to clarify scope and confirm status

### PDCR-444: Site Specific Configurable Correspondence Reasons (Q4 Spillover)
- **Status:** Above the line
- **Size:** MD (2 sprints, 3 BC)
- **Pod:** Fulfillment & QC
- **Action:** ⚠️ No Jira description — need to clarify scope

### PDCR-433: Duplicate Logic Update (Q4 Spillover)
- **Status:** Above the line
- **Size:** SM (1 sprint)
- **Pod:** Newfire
- **Notes:** Low-touch, Newfire handling independently

### PDCR-443: Embedded Reporting (Q4 Spillover)
- **Status:** Above the line
- **Size:** SM (1-2 sprints, 1 eng)
- **Pod:** KTLO
- **What:** Embedding Sigma BI reports. Already in motion, just integration work.

## At Risk

### PDCR-434: Indirect Chase Redesign (Q4 Spillover)
- **Size:** SM (1 sprint) — low investment expected
- **Pod:** Intake & Logging
- **Status:** Piloting early January
- **Notes:** Rewrite done, in good shape. Minimal remaining investment.

### PDCR-418: Payment Integrity MVP with Payer Team
- **Size:** LG (4 sprints)
- **Pod:** KTLO, Platform
- **Risk:** No Jira description — scope unknown
- **Action:** ⚠️ Need to clarify what this actually involves

### PDCR-446: Reskin HealthSource
- **Size:** XXL (10 sprints)
- **Pod:** Newfire
- **Fixed Allocation:** 2 + NewFire
- **Risk:** Scope unknown - allocate budget

## Below the Line

### PDCR-436: Site Configured Forms per Corr Reason (Q4 Spillover)
- **Size:** MD (2 sprints)
- **Pod:** Fulfillment & QC

### PDCR-407: SOP-A Integration for HealthSource Users
- **Size:** TBD
- **Pod:** Fulfillment & QC

## Fixed Allocations
- **Reactive Work:** 7 sprints (based on Q4 actuals)
