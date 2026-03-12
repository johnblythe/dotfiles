# ADR-001: Standardize Request Event Publishing via EventBridge

**Status:** Accepted
**Date:** 2026-01-06
**Deciders:** Ivan Pantuyev, Platform team
**Supersedes:** N/A

> **Background:** [DEDA Event Bus (Confluence)](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2329215015/DEDA+Event+Bus) contains detailed design notes and architecture diagrams.

---

## Context

HealthSource sends request status updates to multiple external systems (Rhapsody, SmartRequest, ChartSwap, DAQARI). Each integration has bespoke code scattered across the codebase with ad-hoc packaging, filtering, and delivery logic. Adding new consumers requires modifying HealthSource core services.

Upcoming integrations (DAQARI, ChartSwap modifications) would compound this tech debt.

## Decision

Publish all request status events to AWS EventBridge via a shared `deda-event-bus` library. External systems subscribe to the events they need and fetch additional data via existing APIs.

**Implementation:**
- New `deda-event-bus` Java library in `modules/java/libs/`
- Single publish point in `RequestTrackingService`
- Consumers create their own EventBridge rules/targets
- Terraform manages queue distribution per recipient

**Key PRs:**
- [#2155 - HSA-229 Deda request status](https://github.com/datavant/healthsource/pull/2155) - Core library and integration
- [#2227 - HEAL-1254 deda secrets](https://github.com/datavant/healthsource/pull/2227) - Environment config
- [#2262 - HEAL-1254 Add more data to deda events](https://github.com/datavant/healthsource/pull/2262) - Payload enrichment (in progress)

## Consequences

### Benefits
- Adding new consumers requires zero HealthSource code changes
- Business logic ownership shifts to consuming systems
- Single, auditable event stream
- Decouples release cycles between teams

### Tradeoffs
- Consumers must implement their own filtering logic
- Additional AWS infrastructure (EventBridge, IAM, secrets)
- Slight latency increase vs direct integration

### Risks
- **Event schema changes** could break consumers → Mitigation: version payload schema, communicate changes
- **Secret management** complexity across environments → Mitigation: standardized config in `chart/config/`

---

## Alternatives Considered

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| Keep ad-hoc integrations | No migration effort | Unsustainable, growing tech debt | Blocked new work |
| Kafka | Battle-tested, high throughput | Operational overhead, overkill for volume | EventBridge simpler for our scale |
| Direct webhook calls | Simple, synchronous | Tight coupling, retry complexity | Doesn't solve core problem |

---

## Review Trigger

- When event volume exceeds 10k/day
- When >5 consumers are onboarded
- Q2 2026 or 6 months post-GA
