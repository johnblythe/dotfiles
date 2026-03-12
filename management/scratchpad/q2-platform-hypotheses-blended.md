# ROI Platform — Q2'26 Hypotheses (Blended)

## 1. PDCR-414 — Improved File Management

**Hypothesis:** HealthSource's file share architecture is a $36K/month liability with a fixed-size ceiling — when it fills up, it causes incidents, and every size increase is a one-way door. But the underlying problem is deeper: files are doing too many jobs at once — artifacts, state management, service notifications, metadata storage. Swapping to Blob Storage captures cost savings but leaves the architectural rot intact. In Q2, we go straight to CDR as the single storage pattern across all services and workflows — one pattern, one capability, single source of truth, single source of observability.

**What We Get:**
- ~$32K/month savings ($384K annualized) by eliminating file shares entirely
- Eliminates an entire class of capacity-driven incidents
- Fixes the root cause: files stop being overloaded for state management, notifications, and metadata
- Opaque file-based service communication replaced with observable, well-understood queue boundaries
- Single storage pattern across all services — CDR becomes the answer, not one of several answers
- Potential to reclaim additional spend from 1.4 PiB of likely-archived Blob data

**Q2 Framing:** "Migrate HealthSource services from file shares to CDR, service by service. By end of Q2, we've proven the pattern on high-value services, eliminated capacity-driven incident risk, and established CDR as the single storage standard — not an intermediate Blob layer we'd have to migrate off of later."

---

## 2. PDCR-490 — Operational Reliability & Business-Aligned Uptime

**Hypothesis:** HealthSource has an uptime definition on paper but no enforcement, no business-facing visibility, and alerting that tells engineers something is wrong without telling anyone who is impacted. Customers learn about outages before we do. By building SLO tracking and business-aligned alerting in Q2, we turn uptime from a concept into a measurable commitment.

**What We Get:**
- SLAs with teeth — uptime becomes a tracked metric, not a document
- Faster incident response — customer-impact-aware alerts replace noisy technical ones
- We know about degradation before customers call us
- Gives sales/CS real data to back uptime commitments
- Continues the observability maturity work (Confluence scorecards, Datadog improvements) that has been in conversation for two quarters and is just now getting off the ground

**Q2 Framing:** "Define, instrument, and report on business-aligned uptime. By end of Q2, HealthSource has a dashboard that answers 'are customers being impacted right now?' in plain terms."

---

## 3. PDCR-491 — Database Capacity & Storage Risk Mitigation

**Hypothesis:** We're growing fast but flying blind on capacity — the first sign of a problem is an incident, not a planned intervention. And beyond visibility, our monolithic database architecture limits our ability to right-size costs, isolate failures, and recover from disasters. The Q1 audit-log DB split (PDCR-451) proved the pattern for domain-specific separation. In Q2, we instrument capacity visibility AND continue the architectural separation — turning reactive firefighting into planned, domain-aware infrastructure.

**What We Get:**
- Capacity dashboards and growth projections for all critical databases and storage layers
- Alerting thresholds so we know at 70% before we hit 100%
- Growth projections enable planned provisioning, not emergency spend
- Domain-specific DB separation enables right-sized I/O, storage, and memory tiers per workload
- Better disaster recovery through isolated, purpose-built databases
- Hot/warm/cold storage tiers (e.g., audit log DB piping to cold storage)
- Complements the file share → CDR migration work (PDCR-414)

**Where to Start Next (domain candidates from prior analysis):**
- **Search & Retrieval** — high read volume, distinct query patterns, benefits from independent scaling
- **PDF/Document Processing** — heavy I/O, ephemeral storage needs, largely self-contained
- **Workflow Management** — Camunda BPM state, distinct transaction patterns
- Each has identified data ownership boundaries (see `workbench/domains_analysis.md`)

**Q2 Framing:** "Build capacity dashboards so we can answer 'when do we run out of runway?' for every major data store. In parallel, apply the proven Q1 migration playbook to carve out the next domain-specific database — deepening cost optimization, DR readiness, and operational maturity."

---

## 4. PDCR-492 — Search Performance & Scalability Optimization

**Hypothesis:** Search latency is a customer-facing SLA risk today. As data volume grows, slow queries get slower — and we're on a path where search becomes the bottleneck for HealthSource's ability to scale. In Q2, we benchmark, identify the worst structural offenders, and ship targeted fixes — while being deliberate about what we invest in given the emerging agentic workflows that may change how search is consumed.

**What We Get:**
- Reduce/eliminate search latency as a source of customer escalations
- P50/P95 benchmarks catch regressions before they ship
- Structural fixes (bad indexes, architectural limits) benefit any consumer — human or agent
- Faster search = faster workflows for end users today
- Benchmarking data becomes the discovery mechanism: tiger team results over the next 60 days will show which query patterns agents bypass vs. which remain critical

**What We Don't Do:** Over-invest in optimizing user-facing query patterns that agentic workflows (PDCR-484) may obviate. Fix the structural floor, not the cosmetic ceiling. Let discovery inform H2 scope.

**Q2 Framing:** "Benchmark search performance, identify top latency offenders, and ship targeted structural fixes. By end of Q2, we have a defined SLO for search and a trend line moving in the right direction — with clear data on what matters for H2 investment."

---

## 5. PDCR-493 — Intake Modernization & Throughput Acceleration

**Hypothesis:** Intake is the ceiling on everything downstream — if agentic workflows and fulfillment acceleration still depend on slow, unreliable entry methods, the weakest link caps all gains. TRAP processing and NLP web services are suspected bottlenecks but root causes are unconfirmed. Discovery is needed before committing to specific interventions.

**What We Get:**
- Unblock downstream improvements by removing the intake bottleneck
- Faster turnaround times for request creation (extends PDCR-406 hours-to-minutes work)
- Agentic workflows (PDCR-484) amplify any intake improvement — and expose any intake weakness

**Q2 Framing:** "Investigate and baseline intake throughput, identifying root causes (TRAP, NLP web services, or other). By mid-Q2, we have a clear picture of where the bottleneck actually is. By end of Q2, we're executing against the top offenders."

---

## 6. PDCR-496 — DAQARI/FQC Infrastructure

**Hypothesis:** DAQARI/FQC is a cross-team dependency — data science and a partner pod are building on top of it, and if the infrastructure isn't ready, it becomes a blocker that slips timelines outside our control. Platform's role is specific: build the event bus and messaging queue for bi-directional communication between HealthSource and the DAQARI model, process medical records, receive data science output, and route results through fulfillment workflows. Some intermediate Wired QC remediation may be needed as a bridge.

**What We Get:**
- Data science and partner pod can ship without infra being the constraint
- Infrastructure gaps found later are expensive; found in Q2 they're plannable
- Establishes who maintains what as the project scales
- Engineering delivers on a cross-team commitment
- Wired QC pain starts to be addressed with a clear replacement path

**Q2 Framing:** "Build and validate the DAQARI integration infrastructure (event bus, message queue, routing logic) so dependent teams can build on a solid foundation. By end of Q2, infra is a solved problem — not an open question."

---

## 7. PDCR-486 — Improve Request Processing Reliability and Recovery

**Hypothesis:** Request creation failures occur 3-5x per quarter, affecting 3,000-20,000 claims each time with $250K-$500K quarterly financial impact. Current architecture doesn't store request letters on receipt, making failed requests unrecoverable. No proactive alerting on null status_id states.

**What We Get:**
- Prevent data loss: store request letters immediately upon receipt to enable reprocessing
- Early detection: alert on requests stuck in bad states before customer impact
- Reduce incident frequency by addressing systemic root causes
- Improve SLA compliance: minimize 10-day SLA violations

**Q2 Framing:** "Make request intake resilient. By end of Q2, request letters are stored on receipt (failures are recoverable), alerting catches bad states before customer impact, and the systemic causes of 3-5x/quarter failures are addressed."

---

## 8. PDCR-495 — Security, Audit & Compliance Readiness

**Hypothesis:** Variable-cost, fixed-commitment compliance work. Whatever security, audit, and compliance requirements are asked of us (beyond Sailpoint/PDCR-453), we need capacity reserved to respond. Not hypothesis-driven — cost of doing business.

**Q2 Framing:** "Reserve capacity for security and compliance requirements as they arise. Scope TBD based on incoming asks."

---

## 9. PDCR-498 — Payment Integrity Integration Testing

**Hypothesis:** TBD — Platform role unclear. Skipped pending clarification.

---

## 10. PDCR-497 — Provider Exchange Requests in HealthSource

**Hypothesis:** Small-to-medium enablement work extending the existing DEDA event bus pattern to support Provider Exchange request types. Platform provides the plumbing; Provider Exchange team owns the feature.

**Q2 Framing:** "Extend DEDA event bus to support Provider Exchange request types. Enablement work, not a standalone initiative."
