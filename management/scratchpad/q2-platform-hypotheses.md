# ROI Platform — Q2'26 Draft Hypotheses

## 1. PDCR-490 — Operational Reliability & Business-Aligned Uptime
**Hypothesis:** Our observability posture is immature — gaps in SLOs, dashboards, alerting, and instrumentation mean we can't confidently report uptime or catch issues before they become incidents. By continuing the SLO/scorecard work started in Q1 (Confluence scorecards, Datadog improvements), we will establish business-aligned uptime reporting and close monitoring gaps, giving leadership reliable availability metrics and reducing mean-time-to-detect.

**Evidence:** Two quarters of conversation with minimal output until recently. Scorecards just launched in Confluence. Known monitoring gaps documented via observability reviews.

---

## 2. PDCR-491 — Database Capacity & Storage Risk Mitigation
**Hypothesis:** The DB separation work from PDCR-451 (Q1) will complete the migration and dual-pathing phase, but cleanup operations and strategic next steps remain. By continuing this work we can: (a) finish cleanup ops that spill from Q1, (b) begin domain-specific DB separation for better cost profiling and right-sized I/O/storage/memory tiers, (c) establish hot/warm/cold storage tiers (e.g., audit log DB piping to cold storage), and (d) improve disaster recovery through isolated, purpose-built databases.

The Q1 audit-log DB split proved the pattern. A prior domain analysis (`workbench/domains_analysis.md`) already maps HealthSource into bounded contexts — Search & Retrieval, PDF/Document Processing, Workflow Management, Security, Reporting — each with identified data ownership boundaries. This gives us a concrete roadmap for which domain-specific databases to carve out next, applying the same migration playbook (dual-path writes → cutover → cleanup) we validated this quarter.

**Evidence:** PDCR-451 already in Development. Cleanup may spill into Q2. Audit log DB created in Q1 has no cold-storage path yet. Domain analysis identifies 5 bounded contexts with clear data ownership boundaries. Current monolithic DB makes cost optimization and DR harder than it needs to be.

---

## 3. PDCR-492 — Search Performance & Scalability Optimization
**Hypothesis:** Search is architecturally constrained (MyBatis DAO, raw SQL, no Elasticsearch), but the scope of investment should be calibrated against what agentic workflows obviate. We should fix structural bottlenecks (bad indexes, architectural limits) that would block any consumer — human or agent — while deferring optimization of user-facing query patterns that agents may bypass entirely. Tiger team discoveries over the next 60 days will inform the boundary.

**Evidence:** 30-40s load times for single-site users. No caching layer. No ES. But agentic intake (PDCR-484) may reduce dependence on manual search UX. Need discovery to draw the line.

---

## 4. PDCR-493 — Intake Modernization & Throughput Acceleration
**Hypothesis:** Intake is the ceiling on everything downstream — if agentic workflows and fulfillment acceleration still depend on slow, unreliable entry methods, the weakest link caps all gains. TRAP processing and NLP web services are suspected bottlenecks but root causes are unconfirmed. Discovery is needed before committing to specific interventions.

**Evidence:** Extends PDCR-406 (intake acceleration, hours-to-minutes). Jim flagged NLP web services as a lag point (unverified). TRAP likely involved in print/scan path. Agentic workflows (PDCR-484) will amplify any intake bottleneck.

---

## 5. PDCR-414 — Improved File Management
**Hypothesis:** HealthSource's use of Azure File Shares ($36K/mo, 306 TiB provisioned) is overloaded — files serve as artifacts, state management, downstream notifications, and metadata carriers. By consolidating to CDR as the single storage pattern across all services and workflows, we get: one pattern, one capability, better cost profile (~$32K/mo savings on file shares alone), single source of truth, single source of observability, and elimination of architectural debt (opaque file-based service communication replaced with proper queue boundaries).

**Evidence:** RFC documents the problem thoroughly. $36K/mo Azure Files + $31K/mo Blob + $10K/mo Storage Queues = ~$77K/mo total storage cost. 1.4 PiB in blob containers needs cleanup. File shares are fixed-size (can't scale down) and have caused incidents when full. CDR migration is more work than Blob swap but fixes root cause.

---

## 6. PDCR-495 — Security, Audit & Compliance Readiness
**Hypothesis:** Variable-cost, fixed-commitment compliance work. Whatever security, audit, and compliance requirements are asked of us (beyond Sailpoint which is separate in PDCR-453), we need capacity reserved to respond. Not a hypothesis-driven initiative — it's a cost of doing business.

---

## 7. PDCR-496 — DAQARI/FQC Infrastructure
**Hypothesis:** Wired QC is inadequate and will be replaced by DAQARI/Verify Assist (data science model). Platform's role is building the integration infrastructure: event bus, messaging queue for bi-directional communication between HealthSource and the data science model. We process medical records, send to DAQARI, receive output, and route results through fulfillment workflows. Some intermediate Wired QC remediation may be needed as a bridge.

**Evidence:** Wired QC is a known pain point. DAQARI is an internally-built model. Platform owns the plumbing, data science owns the model.

---

## 8. PDCR-486 — Improve Request Processing Reliability and Recovery
**Hypothesis:** Request creation failures occur 3-5x per quarter, affecting 3,000-20,000 claims each time with $250K-$500K quarterly financial impact. Current architecture doesn't store request letters on receipt, making failed requests unrecoverable. No proactive alerting on null status_id states. By storing letters immediately, adding early detection, and addressing systemic root causes, we reduce incident frequency and SLA violations.

**Evidence:** Documented in ticket. Financial impact quantified. Architecture gap identified (no immediate letter storage). No alerting on failed states.

---

## 9. PDCR-498 — Payment Integrity Integration Testing
**Hypothesis:** TBD — Platform role unclear. Skipped pending clarification.

---

## 10. PDCR-497 — Provider Exchange Requests in HealthSource
**Hypothesis:** Small-to-medium enablement work extending the existing DEDA event bus pattern to support Provider Exchange request types. Platform provides the plumbing; Provider Exchange team owns the feature.

**Evidence:** DEDA event bus pattern already exists. This is extension, not net-new architecture.
