---
shaping: true
---

# Intake Event Telemetry POC — TL;DR

> Full shaping doc: `shaping.md`

## What We're Building

A telemetry layer for intake/logging that piggybacks on the existing audit trail and adds 4 new events for genuine gaps. Emits structured events to the new `eventdriventelemetry` service (PRs 2577-2586).

## Why

- 35x gap between touch time (~7min) and wall-clock (~4hr) per request
- 422 audit event types already exist but are freetext — can't aggregate or alert
- STORK accuracy, pre-validation failures, and queue-to-pickup time are blind spots
- 82K fulfillment exceptions/qtr from "non-approved site" alone — detectable at intake

## Selected Shape: A (Audit Trail Bridge + Targeted New Events)

**Don't re-instrument. Bridge what exists, fill the gaps.**

### New Components

| Component | What It Does | Where |
|-----------|-------------|-------|
| **TelemetryBridge** | Intercepts existing audit trail writes, extracts structured metadata, forwards to telemetry service | Java — `RequestAuditTrail` listener |
| **StorkDiffService** | Loads persisted STORK response, diffs against submitted form values | Java — server-side at form submit |
| **SegmentationEnricher** | Stamps every event with site_id, source_type, major_class, is_emr | Java — lookup from erequest_dynamic |
| **TelemetryClient** | Async HTTP POST to Python telemetry service | Java — fire-and-forget |
| **2 JS emitters** | `requestOpened` (task click), `dataEntryCompleted` (form submit) | Frontend — existing handlers |
| **Validation emitter** | Structured `validation_failed` before exception creation | Java — RequestValidator chain |

### What This Enables (automated detection of)

| Problem | How We Detect It |
|---------|-----------------|
| Queue-to-pickup time | `request_opened` timestamp - `request_received` timestamp |
| Actual logging time | `data_entry_completed` - `request_opened` |
| STORK accuracy | `stork_fields_edited.field_change_count > 0` rate |
| Pre-validation gaps | `validation_failed.missing_fields[]` by site |
| Weekend/afternoon queue gaps | Time deltas by day_of_week, hour_of_day |
| Site-level data quality | All events segmented by site_id |

## Build Plan

| Slice | Week | What | Demo |
|-------|------|------|------|
| **V1** | 1-2 | Audit trail bridge + event types + enrichment | Requester lookup → structured event in telemetry table |
| **V2** | 3 | Request opened + data entry timing (JS) | Open request, submit → two time-bracketed events |
| **V3** | 3 | STORK field diff | Correct a STORK field → `fields_changed: ["patient.firstName"]` |
| **V4** | 4 | Validation failure events | Missing address → structured `validation_failed` event |
| **V5** | 4 | Snowflake ETL + dashboard | Query: STORK edit rates, validation failures by site |

## Key Code Touchpoints

| File | Change |
|------|--------|
| `intakeservices/.../RequestAuditTrail.java` | Add 1 call → TelemetryBridge after existing audit write |
| `intakeservices/.../RequestValidator*.java` | Emit validation_failed on failure |
| `modules/python/libs/telemetry/.../types.py` | Add ~13 intake event types to enum |
| `modules/python/libs/telemetry/.../metadata.py` | Extend metadata with intake fields |
| Logging queue JS (task list click handler) | Emit requestOpened |
| Logging form JS (submit handler) | Emit dataEntryCompleted |
| **New**: `TelemetryBridge.java` | Core bridge: map audit_type → event_type, extract metadata |
| **New**: `StorkDiffService.java` | Load `parser_callback_response`, diff vs submitted |
| **New**: `SegmentationEnricher.java` | Lookup request context for every event |

## Open Questions

1. Does Snowflake ETL already cover `hs_audit.user_interaction_events_default`?
2. Where does session ID (`sess_UUID`) come from in HealthSource?
3. Does every intake channel go through STORK? (affects A5 coverage)
4. HTTP vs Azure Service Bus for bridge transport?
