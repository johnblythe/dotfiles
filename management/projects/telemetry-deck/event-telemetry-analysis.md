# Event-Driven Telemetry Analysis

## Context
Review of two docs proposing event telemetry for HealthSource time-on-task measurement:
1. **Joe Montero's spec** — "Event-Driven Telemetry Experiment: Infrastructure Design" (v1.0, 2026-01-13)
2. **Product taxonomy** — "MVP Event Taxonomy for ROI Workflow Time Measurement" (24 events, 6 stages)

Both reviewed against `~/code/healthsource` codebase and validated with Snowflake queries against production data.

---

## Source Documents
- `~/Downloads/Event Driven Telemetry Experiment.docx` — Joe's infra spec
- `~/Downloads/MVP Event Taxonomy for ROI Workflow Time Measurement.md` — Product taxonomy

---

## Review Summary

### Joe's Spec: Infrastructure Design
**What it is:** Python/FastAPI pipeline — frontend→backend→Azure Service Bus→consumer→analytics warehouse. 7-9 weeks, 2 pilot workflows.

**What's good:**
- Server-side timestamps (correct)
- Azure Service Bus partitioning by session_id
- Follows connex service patterns (Python/FastAPI is legit in this codebase)
- Validation dashboard in Phase 1

**Key issues:**
1. **Backend file paths reference `.py` for Java files** — eipservices and requestworker are Java/Spring Boot, not Python
2. **Session ID via localStorage** won't isolate browser tabs (sessionStorage or per-tab UUIDs needed)
3. **`modules/python/libs/telemetry/`** doesn't exist — new directory pattern, needs ownership model
4. **All business value deferred to Phase 2** — 7-9 weeks delivers plumbing, no time-on-task answers
5. **Ignores existing `deda-event-bus`** Java library and `AuditTrailCache` (30+ event types already tracked)
6. **PII enforcement is hand-wavy** — "no PII in metadata" enforced by schema validation that can't detect PII
7. **15-min abandoned timeout too aggressive** — fulfillment involves reading multi-page docs
8. **Warehouse decision (Synapse vs Redshift) is blocking**, not "open question"
9. **Should extend connex's `BaseQueueProcessor`** patterns, not build fresh consumer

### Product Taxonomy: 24 Events Across 6 Stages
**What it is:** Detailed event definitions for intake→logging→auth review→retrieval→QC→delivery. Claims ≤4 weeks.

**What's good:**
- Design principles (system-captured first, minimal friction)
- Stage 4 (Record Retrieval) correctly identifies the black box
- Page count bucketing is analytically smart
- Parking lot is honest about employee mapping gap

**Key issues:**
1. **~15 of 24 events already exist** as audit trail entries or status transitions
2. **Stage 3 (Auth Review) is a phantom workflow** — no discrete auth review step exists in Camunda BPMN. Auth validation happens within logging, not as a separate stage.
3. **EMR access events (Stage 4) are outside HealthSource** — processors open Epic/Cerner in separate browser windows
4. **Processor attributes (tenure, location, zone) don't exist** in HealthSource — requires HR data integration
5. **≤4 weeks is not credible** given Stage 3 requires workflow creation, Stage 4 requires EMR integration
6. **No reference to existing `AuditTrailCache`** — should start by mapping what's already captured
7. **Taxonomy assumes all 6 stages are human-driven** — data shows 2-3 stages auto-transition for most channels

### Spec vs Taxonomy Tension
Joe builds a pipeline with no events defined. Taxonomy defines events with no pipeline. Neither references what the system already captures. The ideal doc is the marriage: audit trail gap analysis → net-new event definitions → infrastructure to transport them.

---

## Snowflake Validation (Production Data)

### Setup
- **Snowflake CLI**: `/Applications/SnowSQL.app/Contents/MacOS/snowsql -c datavant`
- **Config**: `~/.snowsql/config` — connection `datavant`, role `ENG_PROVIDER`, db `HEALTHSOURCE`, schema `CONNEX`
- **Auth**: SSO via externalbrowser (re-auths every invocation; `client_store_temporary_credential` doesn't help)
- **dbt models**: `~/code/data-warehouse/data_model/models/staging/healthsource/` — all connex tables available
- **Key existing model**: `int_provider_roi__erequest_status_analysis.sql` already computes time between status transitions

### Key Tables
| Table | Purpose |
|-------|---------|
| `connex.erequest_status_dynamic` | Every status transition with `state_timestamp` |
| `connex.request_status` | Status ID → description lookup |
| `connex.erequest_audit_trail_dynamic` | 30+ audit event types with timestamps |
| `connex.erequest_dynamic` | Request metadata (major_class, delivery_method, source_type, page counts, etc.) |

### Queries Run
SQL files stored at `/tmp/q1_logging_tat.sql`, `/tmp/q2_fulfill_tat.sql`, `/tmp/q3_e2e.sql`.

Pattern: join `erequest_status_dynamic` → `request_status` for status descriptions, use `lead()` window function to get next status timestamp, compute `datediff('second', ...)`, join to `erequest_dynamic` for stratification dimensions.

### Findings

#### Status Name Discovery (Q0)
The main workflow statuses are **`Logging`** (167M transitions) and **`Fulfillment`** (237M), NOT "Logging In Progress" (121K) or "Fulfillment In Progress" (7.5K). The "In Progress" variants are rare transitional states.

Full status frequency: see `~/Downloads/event TAT_2026-02-11-1956.csv`

#### Logging Time-on-Task (Q1)

Two completely different populations in the same status:

| Channel | Median | P95 | What's happening |
|---------|--------|-----|-----------------|
| MANUAL/ELECTRONIC/PULLLIST | **1 sec** | 2 sec | System auto-transitions — no human |
| UPLOAD | **20-150 min** | 18-23 hrs | Actual human work |
| CENTRAL INTAKE | **15-135 min** | 16-20 hrs | Actual human work |

Human logging work by major class (UPLOAD channel):
- CLIN: median **19 min**
- ATTY: median **142 min**
- GOV: median **82 min**
- INS: median **75 min**

Variance: 7.5x (CLIN→ATTY). Validates taxonomy's "3-10x" claim.

#### Fulfillment Time-on-Task (Q2)

Bimodal distribution — NOT normal:

| Segment | Median | P95 |
|---------|--------|-----|
| CLIN, MANUAL, non-EMR | **1.9 min** | 2.6 hrs |
| PAT, MANUAL, non-EMR | **1.5 min** | 30 min |
| CLIN, UPLOAD, non-EMR | **95 min** | 21 hrs |
| ATTY, UPLOAD, non-EMR | **4.7 hrs** | 22 hrs |
| PAYD, ELECTRONIC, EMR | **7.8 hrs** | 22 hrs |

MANUAL INTAKE fulfillment is near-instant (auto-fulfilled). UPLOAD/ELECTRONIC takes hours. Actual variance: ~500x (1 min to 8 hrs), not the taxonomy's "3-8x."

EMR vs non-EMR is NOT the differentiator (CLIN+UPLOAD: 90 min EMR vs 95 min non-EMR). `source_type` is the real driver.

#### End-to-End Cycle Time (Q3)

In minutes, converted to readable:

| Segment | Median |
|---------|--------|
| Fax-Continuing Care | **16 hrs** |
| CLIN+MANUAL+AutoFax | **17 hrs** |
| CLIN+UPLOAD+AutoFax | **34 hrs** |
| GOV+UPLOAD+Electronic | **3.6 days** |
| ATTY+UPLOAD+Electronic | **7.5 days** |
| PAYI+PULLLIST+Electronic | **10.5 days** |

---

## Key Takeaways

1. **~60% of the taxonomy is already answerable** from existing status transitions in Snowflake. No new instrumentation needed for the macro view.

2. **The taxonomy assumes 6 human stages. Reality is 2-3.** ELECTRONIC/PULLLIST intake auto-transitions through logging in 1 second. Most requests don't go through all 6 human-driven stages.

3. **The real gap is WITHIN the long stages.** What happens during a 95-minute UPLOAD fulfillment session? Patient lookup timing, EMR access latency, STORK edit tracking, record retrieval breakdowns — that's where new telemetry adds value. But that's 4-6 targeted events, not 24.

4. **`source_type` is the primary variance driver**, not EMR system or major_class alone. Any telemetry design should stratify by source_type first.

5. **Fulfillment is bimodal.** Some requests auto-fulfill (1-sec transitions), others take hours. Treating these as one population in analytics will produce meaningless averages.

## Recommendation
Start from the existing data baseline. Map `AuditTrailCache` events to the taxonomy. What's left after that mapping is the actual net-new instrumentation scope — probably 6-8 events focused on intra-stage granularity for UPLOAD and CENTRAL INTAKE channels where humans actually do the work.
