# HealthSource Observability & SLO Framework — PRD

**Epic:** [HEAL-1699](https://datavant.atlassian.net/browse/HEAL-1699)
**PM:** Barto | **Eng Lead:** John Blythe
**Initiative:** [PDCR-449 — Business Continuity, DR Investments, & Support](https://datavant.atlassian.net/browse/PDCR-449)
**Feature Type:** Feature (multi-sprint, cross-team, stakeholder sign-off)

---

## Product Spec

### Opportunity Statement

HealthSource has ~15% observability coverage across 42 active services. We cannot reliably answer "is the system up?" — and when it's down, we learn from users before monitors.

**Business impact of the gap:**
- VPOs report 15-60 minute tolerance for full outages; 23% need resolution in <15 min
- Fulfillment downtime stops operations entirely (61% of stakeholders agree)
- No SLOs exist — "we need better uptime" is a feeling, not a number
- 6 of 8 customer journey domains have zero reliability contracts
- Active blind spots: OOM events go undetected (hs-proxyservices, Feb 9), 3 DLQ monitors currently in ALERT, 36 of 42 services lack error rate monitors

**What this unlocks:**
- A single answer to "what's our uptime?" for ELT and customers
- Error budgets that tell us when to shift from features to reliability
- Proactive alerting before users experience impact
- Data-driven prioritization of reliability investments

**Baseline metrics:**

| Category | Current | Q1 Target | Q2 Target |
|----------|---------|-----------|-----------|
| Overall observability score | ~15% | ~45% | ~65% |
| SLOs defined | 0 | 20% | 50% |
| Error rate monitors | 15% | 50% | 80% |
| Latency monitors | 0% | 30% | 60% |

---

### Prioritized Scope

**In scope:**
1. Close 50 identified monitoring gaps across 10 categories (error rates, latency, JVM, DB, SLOs, security, synthetics, queues, no-data, anomaly detection)
2. Define and measure SLOs for 8 domains (ACCESS, INTAKE, SEARCH, LOGGING, FULFILLMENT, DELIVERY, PLATFORM, INTEGRATION)
3. Expand uptime dashboard from intake-only to full customer journey
4. Establish error budget alerting and burn-rate tracking
5. Automate weekly gap analysis via Night Light

**Out of scope:**
- Application-level performance optimization (that's PDCR-404 Search Speed, PDCR-406 Intake Acceleration)
- RUM (Real User Monitoring) instrumentation — future phase
- Frontend synthetic tests beyond login + critical API (deeper user journey tests are Phase 3+)
- SLA commitments to external customers — SLOs are internal targets first

**Non-conditions:**
- This is NOT a replatforming effort — we're instrumenting the existing system, not rebuilding it
- This does NOT require code changes to HealthSource services (monitors are Terraform + Datadog config)
- SLO targets are starting points, not commitments — Phase 1 is measurement, not enforcement

---

### Acceptance Criteria

**Phase 1 — Measure (Q1.S1-S2):**
- [ ] Datadog SLOs created for all 6 customer journey domains using APM metrics
- [ ] 2 sprints of baseline data recorded in scorecard
- [ ] Error rate monitors deployed for all 42 services _(🟢 10 of 42 done via early exploration)_
- [ ] Uptime dashboard expanded to include ACCESS, SEARCH, DELIVERY sections

**Phase 2 — Alert (Q1.S3-S4):**
- [ ] SLO targets set based on observed baselines (at or slightly above actuals)
- [ ] Error budget alerts enabled: warn at 50% consumed, critical at 80%
- [ ] p95 latency monitors live for user-facing services
- [ ] JVM + database health monitors deployed
- [ ] No-data heartbeats covering all 42 services
- [ ] Overall observability score at 45%+

**Phase 3 — SLO Contracts (Q2):**
- [ ] SLO targets tightened based on reliability improvements
- [ ] Latency SLOs added (availability SLOs first, then latency)
- [ ] Synthetic login test for ACCESS domain
- [ ] Error budget policies documented — when budget exhausted, shift from features to reliability
- [ ] Executive dashboard showing: current status, time in state, affected segments, error budget remaining
- [ ] Overall observability score at 65%+

**Initiative-level done:**
- Every hs-* service has: error rate monitor + no-data heartbeat + p95 latency monitor
- Every domain has: at least one Datadog SLO with 30-day tracking
- The uptime dashboard answers "is HealthSource up?" with a single composite number
- Night Light enforces new-service monitoring minimum automatically

---

### Target Personas & User Needs

**ELT / VPOs:**
- Need: "What's our uptime?" answered with a number, not a guess
- Pain: Learn about outages from ops teams or customers, not monitors
- Success: Weekly scorecard email, executive dashboard, confidence in the answer

**On-Call Engineers:**
- Need: Know what's broken and where before users report it
- Pain: Current alerts are infrastructure-heavy; app-level blindness
- Success: Monitor fires → runbook → resolution, without guessing

**Internal Operations Teams (Fulfillment, Intake, Logging):**
- Need: System works when they sit down to work each morning
- Pain: Slowdowns, freezes, workarounds — with no ETA to resolution
- Success: 15-60 min max outage window, proactive communication during degradation

**Product (Barto + PMs):**
- Need: Data to prioritize reliability vs features
- Pain: No error budget framework — every incident is ad hoc prioritization
- Success: Error budget burn rate informs sprint planning; reliability gets dedicated capacity when needed

---

## Tech Spec

### System Context

HealthSource is a medical records request processing platform running ~42 microservices on Kubernetes (AKS). The observability stack is Datadog (APM, logs, metrics, monitors, SLOs, dashboards, synthetics).

Today, monitoring is heavily weighted toward infrastructure — pod health, queue depths, disk space — with near-zero coverage for application-level performance, reliability contracts, and security. The system processes medical records for provider organizations, requesters, and internal ops teams, making visibility into system health a compliance and operational necessity.

**What exists today:**
- 82 Datadog monitors (mostly infrastructure-level)
- 1 uptime dashboard covering INTAKE flows only (fax, email, upload)
- `/health` endpoints on 15+ services (not all wired to Helm readiness probes)
- APM trace annotations (`@Trace`) imported in 77+ source files, but `dd-java-agent` actively deployed on only 3 services
- `MetricsLogger` (StatsD → Datadog) in 2 services (requestworker, audittrailworker)

**What does not exist:**
- SLOs or error budgets for any domain
- Latency monitoring for any service
- JVM health monitoring (heap, GC, threads)
- Application-layer security monitors (401/403 spike detection on a PHI app)
- Synthetic user journey tests
- A composite "is the system up?" answer

**Proposed technical approach:** All monitors and SLOs will be defined as code in a Terraform module, applied via Atlantis CI/CD. No manual Datadog UI configuration. This enables version control, PR review, and consistent deployment across environments.

```
monitors/terraform/modules/datadog-hs-monitors-v2/
├── slo_monitors.tf
├── custom_application_monitors.tf
├── k8s_monitors.tf
├── datadog_monitors.tf
├── azure_monitors.tf
├── asm_monitors.tf
└── environments/prod/
```

> **🟢 Head start:** Engineering began exploratory work ahead of this PRD. The Terraform module structure above already exists with some initial definitions. Error rate monitors for 10 critical services have been written (2 PRs merged). SLO metric formulas have been drafted in `slo_monitors.tf` but not yet applied to production. An INTAKE-focused uptime dashboard exists from Joseph Montero's earlier work. This head start de-risks Phase 1 significantly but does not change the scope of this PRD — the full plan is documented here as if greenfield.

---

### Design Goals

1. **Measure before committing** — Set SLOs we can actually meet, then tighten. A 95% SLO we meet is better than 99.9% SLO we constantly violate.
2. **Automate over manual** — Monitor-as-code (Terraform), automated gap analysis (Night Light), automated scorecard updates. No spreadsheet upkeep.
3. **Customer-journey alignment** — Organize around what users experience (Can I log in? Can I submit? Can I search?) not what services run.
4. **Phased rollout** — Monitors ship in waves by category and priority. Each phase has a gate before the next. No big-bang deployment.
5. **Sustainable ownership** — Every new hs-* service ships with minimum monitors. Night Light enforces. No backsliding.

---

### Proposed Architecture

**Layer 1: Monitors (Terraform → Datadog)**

All monitors will be defined in a Terraform module and applied via Atlantis CI/CD. No manual Datadog UI configuration. Each monitor type maps to a specific gap category from the Night Light gap analysis.

Monitor types to deploy:
- **Error rate** — Per-service `trace.servlet.request` error rate > threshold
- **Latency p95** — Per-service request duration p95 > threshold
- **JVM health** — Heap utilization, GC pause time, thread count via `jvm.*` metrics
- **No-data heartbeat** — Alert when a service stops sending any metrics
- **Log-based** — Pattern matching for known error signatures (CDR unreachable, OOM, Camunda delegate failures)
- **Queue health** — Message age + Camunda job stuck detection
- **Anomaly detection** — Datadog anomaly algorithm on latency, throughput, error rate

**Layer 2: SLOs (Terraform → Datadog SLOs)**

Each domain gets a Datadog SLO using the formula: `(hits - errors) / hits` over a 30-day rolling window. SLOs are defined in Terraform alongside monitors.

Per-domain SLOs:
| Domain | SLO Target | Primary Metric |
|--------|-----------|----------------|
| ACCESS | 99% | `trace.servlet.request{service:hs-securityservices}` |
| INTAKE | 98-99% | Per-channel success rate (fax, email, upload) |
| SEARCH | 98% | `trace.servlet.request{service:hs-searchservices}` |
| LOGGING | 95-98% | Workflow trigger success, OCR processing rate |
| FULFILLMENT | 98-99% | Request worker processed success rate |
| DELIVERY | 99% | RSP + delivery services success rate |

Error budget alerts: warn at 50% consumed, critical at 80%.

**Layer 3: Dashboards (Datadog)**

Build a comprehensive uptime dashboard covering all 8 domains. An existing INTAKE-only dashboard (`d3n-yzt-phx`) will be expanded rather than rebuilt:
- Add ACCESS section: login success rate, CIPUI synthetic
- Add SEARCH section: availability, p95 latency
- Add LOGGING detail: OCR success, Camunda health, pipeline throughput
- Add FULFILLMENT section: request processing rate, completion velocity
- Add DELIVERY section: RSP, esMD, back office
- Add composite "System Up" widget: weighted average of domain SLOs

**Layer 4: Enforcement (Night Light)**

Weekly automated checks:
1. SLO existence — every domain has at least one DD SLO
2. SLO health — any SLO below target? Error budget burning?
3. Dashboard completeness — widgets for all 8 domains?
4. Monitor coverage — every SLI has underlying monitor?
5. Runbook coverage — every firing monitor has linked runbook?

Results → scorecard page auto-update.

---

### Size Estimate

| Phase | Scope | Effort | Team |
|-------|-------|--------|------|
| Phase 1: Measure | SLO creation, error rate monitors, dashboard expansion | ~2 sprints, 1-2 eng | Platform (Ivan + John) |
| Phase 2: Alert | Latency, JVM, DB, security, heartbeat monitors + error budget alerts | ~2 sprints, 1-2 eng | Platform |
| Phase 3: SLO Contracts | Synthetics, anomaly detection, SLO tightening, error budget policies | ~2-3 sprints, 1 eng | Platform |
| **Total** | | **~6-7 sprints** | **1-2 eng steady state** |

Most work is Terraform configuration, not application code. Tickets are small (1-2 pts each). The large number of tickets reflects breadth across 10 monitor categories, not depth — each is a distinct, independently deployable unit.

> **🟢 Head start:** Early exploration has already completed Phase 1 error rate monitors for 10 services (HEAL-1697, HEAL-1698) and an SLO definition spike is in progress (HEAL-1711). This effectively front-loads ~1 sprint of Phase 1 effort.

---

### Confidence

**High confidence on Phase 1-2.** The approach is well-understood: Terraform-defined monitors against Datadog APM trace metrics. The monitor-as-code pattern is proven in the HealthSource ecosystem. Each monitor is a small, independent unit testable in staging before prod.

> **🟢 Head start factor:** Exploratory engineering has already validated the Terraform module pattern, confirmed APM trace availability for key services, and shipped error rate monitors for 10 services. This increases Phase 1 confidence further.

**Medium confidence on Phase 3.** Synthetic tests require credentials/auth handling for CIPUI login. Anomaly detection requires tuning to avoid false positives (high initial noise is expected). Error budget policies are organizational, not just technical — require PM/eng alignment on "when do we stop features for reliability?"

---

### Risks/Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Alert fatigue — too many monitors fire simultaneously | High | Med | Phase in monitors gradually. Start with high thresholds, tighten. Use composite alerts. |
| SLO targets too aggressive — constant budget breach | Med | High | Phase 1 is measurement only. Set targets at/above observed baseline. |
| APM data gaps — some services don't emit traces | Med | Med | Validate trace availability per service before creating SLOs. Fall back to log-based metrics. |
| Night Light drift — automated scoring becomes stale | Low | Med | Weekly cadence. Scorecard shows "last updated" timestamp. |
| Team capacity — observability competes with feature work | High | High | Error budget framework explicitly allocates reliability time. Barto aligns with ELT. |
| False sense of security — "green dashboard" doesn't mean "good" | Med | Med | Start with conservative SLOs. Validate against real incidents retroactively. |

---

### Rollout Mechanics

**Phase 1: Measure (Q1.S1-S2)**
- Create and apply SLO definitions for all 6 customer journey domains via Terraform
- Deploy error rate monitors for all 42 services _(🟢 10 of 42 done via early exploration)_
- Expand uptime dashboard with ACCESS + SEARCH + DELIVERY sections
- Record 2 sprints of SLO baseline data
- **Gate to Phase 2:** Baselines recorded for all 6 customer domains

**Phase 2: Alert (Q1.S3-S4)**
- Set SLO targets based on observed baselines
- Enable error budget alerts (50% warn, 80% critical)
- Deploy latency, JVM, DB, security, no-data, queue monitors
- Wire alert routing: Slack channel + PagerDuty for P1+
- **Gate to Phase 3:** Overall observability at 45%+, no domain below 30% coverage

**Phase 3: SLO Contracts (Q2)**
- Synthetic login test (CIPUI)
- Anomaly detection tuning
- SLO target tightening based on 4+ weeks of data
- Error budget policies: when budget exhausted, sprint pivots to reliability
- Executive dashboard build
- **Gate to GA:** All domains have SLOs, error budgets tracked, scorecard at 65%+

Rollback: Monitors are additive — they can be disabled or threshold-adjusted without impacting HealthSource services. No feature toggle needed.

---

### Security Considerations

- Monitors observe existing metrics — no new data flows or PII exposure
- Synthetic tests will require service account credentials for CIPUI login test — coordinate with security for credential storage (Datadog Secrets)
- Security monitors (HEAL-1703) detect 401/403 spikes and login failures — this adds visibility into potential auth attacks on a PHI application
- No CASTLE review needed — infrastructure-only change, no application behavior change

---

### Monitoring, Alerting, and Measuring

This *is* the monitoring initiative. Meta-monitoring:

| What | Where | Severity |
|------|-------|----------|
| SLO error budget burn rate | Datadog SLO alerts | P1 (critical at 80% consumed) |
| New monitor creation | Night Light weekly gap check | Informational |
| Dashboard staleness | Night Light scorecard timestamp | P3 |
| Monitor in No Data state | Datadog no-data alerts per monitor | P2 |

---

### Testing

- **Terraform plan review** — All monitor changes via PR → Atlantis plan → review → apply
- **Staging validation** — Monitors deployed to staging first to verify metric availability and threshold sanity
- **Retroactive validation** — Compare SLO data against known past incidents to verify monitors would have fired
- **Alert routing test** — Verify Slack + PagerDuty routing for each severity tier before going live

---

### Dependencies

| Dependency | Owner | Status | Risk |
|------------|-------|--------|------|
| Datadog APM traces available per service | HealthSource services | Partial — 3 services fully instrumented, 77+ have @Trace imports | Med: may need to enable dd-java-agent for some services |
| Terraform Atlantis access for monitors repo | Platform / DevOps | Available | Low |
| Datadog Synthetic test runner | Datadog | Available in plan | Low |
| CIPUI service account for synthetic login | Security team | Not started | Med: need to coordinate |
| Night Light automation | John Blythe | Running | Low |
| Helm readiness probes wired to /health | Platform | Partial | Low: nice-to-have, not blocking |

---

## Release Strategy

### Maturity Level

**Feature** — This is a substantial change spanning 6-7 sprints with cross-team impact. Rollout is phased but doesn't follow the traditional alpha/beta/GA model since it's infrastructure, not user-facing functionality.

Instead, phases correspond to observability maturity:
- **Phase 1 (Measure)** ≈ Experiment — instrument and observe
- **Phase 2 (Alert)** ≈ Alpha — active alerting for on-call
- **Phase 3 (Contracts)** ≈ GA — SLO-driven reliability culture

### Rollout Toggles

Not applicable. Monitors are additive infrastructure. Individual monitors can be muted or disabled via Datadog or Terraform without affecting application behavior.

### Iterations

| Phase | Sprint | Scope | Business Value Delivered |
|-------|--------|-------|------------------------|
| 1 | Q1.S1-S2 | SLOs created, baselines measured, dashboard expanded | "Here's our actual uptime" — first real answer for ELT |
| 2 | Q1.S3-S4 | Full monitor coverage, error budget alerts | On-call knows before users; proactive incident response |
| 3 | Q2.S1-S3 | Synthetics, anomaly detection, error budget policies | Reliability culture — data-driven feature vs. reliability tradeoffs |

---

## Context & Links

| Resource | Link |
|----------|------|
| Epic | [HEAL-1699](https://datavant.atlassian.net/browse/HEAL-1699) |
| Initiative | [PDCR-449](https://datavant.atlassian.net/browse/PDCR-449) |
| Uptime Business Definition | [Confluence](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2495610881) |
| Observability Scorecard | [Confluence](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2531786791) |
| Uptime Dashboard | [Datadog](https://app.datadoghq.com/dashboard/d3n-yzt-phx/healthsource---up-time) |
| Monitor Terraform Module | `monitors/terraform/modules/datadog-hs-monitors-v2/` |
| SLO Framework | [Confluence](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2532540468) |
| Domain Model | [Confluence](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2532016252) |
| Gap Analysis | [Confluence](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2531983424) |
| VPO Uptime Survey | [Google Forms](https://docs.google.com/forms/d/1YWGpx2FFOq-EDw18Z2ZEJiAu5s8jYtC0gr4dnQr_F4k/edit#responses) |
