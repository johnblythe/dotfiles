# Intake Event Telemetry — POC Shape-Up

## TL;DR

The new `eventdriventelemetry` service (PRs 2577/2578/2586) gives us a Python FastAPI that validates events against a Pydantic schema and writes to `hs_audit.user_interaction_events_default`. The schema already defines 16 ROI event types + 4 generic workflow types. But the **intake audit trail already captures 30+ events per request** in `erequest_audit_trail_dynamic`.

**Strategy**: Don't re-instrument what audit trail already captures. Instead:
1. Bridge existing audit events → telemetry pipeline (structured metadata extraction)
2. Add the 4-5 events the audit trail genuinely misses (STORK edits, field timing, pre-validation)
3. Enrich every event with the segmentation dimensions the Taxonomy doc wants

---

## What Already Exists

### Event Telemetry Service (PRs 2577-2586)

```
services/eventdriventelemetry/
  ├── business/telemetry_processor.py   # Validates JSON → TelemetryEvent
  ├── data/audit_repository.py          # Writes to hs_audit PostgreSQL
  ├── services/telemetry_service.py     # Orchestrates validate → lookup app_id → persist
  ├── security/auth.py                  # JWT email domain check
  └── main.py                           # POST /api/telemetry/event
```

**Schema** (`hs_telemetry` lib):
- `event_id` (evt_UUID), `application_name`→`application_id`, `event_timestamp`, `partition_date`
- `user_id`, `session_id`, `event_type` (Literal enum), `workflow_name`
- `metadata` (JSONB): `request_id`, `task_id`, `workflow_instance_id`, `additional_context`

**Current EventType enum** (types.py):
```
roi.intake.request_opened          roi.qc.review_started
roi.intake.request_received        roi.qc.patient_verified
roi.requestcapture.started         roi.qc.scope_verified
roi.requestcapture.completed       roi.qc.review_completed
roi.auth_review.started            roi.delivery.method_selected
roi.auth_review.completed          roi.delivery.prep_started
roi.retrieval.started              roi.delivery.submitted
roi.retrieval.completed            roi.delivery.post_delivery_completed
workflow.start / .active / .complete / .abandoned
```

### Existing Audit Trail (AuditTrailCache.java → Snowflake)

Intake services already emit these to `erequest_audit_trail_dynamic`:

| Audit Event | Maps To | Gap? |
|------------|---------|------|
| `ExternalRoiRequestCreated` / `InternalRoiRequestCreated` | `roi.intake.request_received` | Covered — but freetext audit_message, not structured |
| `DigitalIntakeRequesterFound` / `NotFound` / `MultipleFound` | requester lookup step | **No telemetry equivalent** — rich context in message |
| `AuditElectronicRequestPatientInfo` | patient data extraction | **No telemetry equivalent** |
| `AuditElectronicRequestReasonInfo` / `AuditDefaultRequestReasonInfo` | request classification | **No telemetry equivalent** |
| `DeliveryMethodSelected` | `roi.delivery.method_selected` | Covered |
| `RequestedRecordTypes` | record type selection | **No telemetry equivalent** |
| `DueDateFoundSiteEnabled` / variants | due date calculation | **No telemetry equivalent** |
| `True BOC` / `SA BOC` / `Not True BOC` | requester classification | **No telemetry equivalent** |
| `AuditNpiLookupProviderFound` / `NotFound` | NPI lookup | **No telemetry equivalent** |
| `AttestationReceived` | attestation step | **No telemetry equivalent** |
| `SplitChildRequestSubmitted` | split workflow | **No telemetry equivalent** |
| `RequestStateUpdated` (127M/90d in Snowflake) | all status transitions | Covered by status table, not telemetry |
| `AuditCamundaTaskEvent` (55M/90d) | workflow task lifecycle | Covered by BPMN, not telemetry |
| `PatientLookupStarted/Finished/NotFound` (1.3M) | patient search | Maps to taxonomy 2.1/2.2 |

### What's Genuinely Missing (not in audit trail OR telemetry)

1. **STORK edit tracking** — STORK pre-populates fields via ADE. Processor then corrects. We don't know *which* fields or *how many*. This is the taxonomy's `stork_edit_required`, `fields_edited_count`.
2. **Intra-form field timing** — How long per field. Requires frontend instrumentation.
3. **Pre-validation failure specifics** — Structured "what's missing" before exception creation. Currently only freetext comments.
4. **Processor active vs idle** — Tab focus detection. Requires frontend JS.
5. **Request opened for review** — When a processor clicks into a request (taxonomy 1.2). Currently no click-level event.

---

## POC Scope: Intake Process (Stage 1+2)

### Approach: Two-Track

**Track A: Audit Trail Bridge** (backend, ~2 weeks)
Intercept existing audit trail writes and forward structured versions to telemetry service. Zero new UI work. Covers 70% of the taxonomy's intake events.

**Track B: New Frontend Events** (frontend, ~2 weeks parallel)
Add 4-5 new JS-level events for the genuine gaps. Targets the highest-value unknowns.

---

### Track A: Audit Trail → Telemetry Bridge

**Concept**: Add a `TelemetryBridge` that listens to audit trail writes in `RequestAuditTrail.createRequestAuditTrail()` and emits structured telemetry events.

**Hook point**: `RequestServiceImpl` or `RequestAuditTrail` interface — every audit entry passes through `createRequestAuditTrail(RequestAuditTrailEntry)`. Add a decorator/listener that:
1. Checks if the audit_type maps to a telemetry event
2. Extracts structured metadata from the audit_message (regex on known templates)
3. Posts to `POST /api/telemetry/event`

**Mapping table** (audit_type → telemetry event_type + extracted metadata):

| Audit Type | → Telemetry Event | Extracted Metadata |
|-----------|-------------------|-------------------|
| `ExternalRoiRequestCreated` | `roi.intake.request_received` | request_id (from msg), intake_channel (from source_type) |
| `InternalRoiRequestCreated` | `roi.intake.request_received` | request_id, requester_type (internal) |
| `DigitalIntakeRequesterFound` | `roi.intake.requester_resolved` (**new**) | requester_id, delivery_method, bill_address |
| `DigitalIntakeRequesterNotFound` | `roi.intake.requester_resolution_failed` (**new**) | (empty — signals pre-validation opportunity) |
| `AuditElectronicRequestPatientInfo` | `roi.intake.patient_info_extracted` (**new**) | first_name, last_name, dob (from msg template) |
| `AuditElectronicRequestReasonInfo` | `roi.intake.request_classified` (**new**) | reason_code (from msg) |
| `AuditDefaultRequestReasonInfo` | `roi.intake.request_classified` | api_code, primary_reason, source=default |
| `True BOC` / `SA BOC` / `Not True BOC` | `roi.intake.requester_classified` (**new**) | classification (true_boc/sa_boc/not_boc), requester_id |
| `RequestedRecordTypes` | `roi.intake.record_types_selected` (**new**) | record_types (from msg) |
| `DueDateFound*` / `DueDateNotFound*` | `roi.intake.due_date_calculated` (**new**) | due_date, site_enabled (bool), calculation_method |
| `PatientLookupStarted` | `roi.logging.patient_lookup_initiated` | lookup_system |
| `PatientLookupFinished` | `roi.logging.patient_matched` | (result info) |
| `PatientLookupNotFound` | `roi.logging.patient_not_found` (**new**) | (signals manual search needed) |
| `AttestationReceived` | `roi.intake.attestation_completed` (**new**) | attestation_text |
| `SplitChildRequestSubmitted` | `roi.intake.request_split` (**new**) | parent_request_id, child_request_id |
| `RequestStateUpdated` (to Logging) | `roi.requestcapture.started` | (status transition = logging task claimed) |
| `RequestStateUpdated` (to Fulfillment) | `roi.requestcapture.completed` | (status transition = logging done) |

**New event types needed in `types.py`** (13 additions for intake):
```python
# Intake detail events (bridge from audit trail)
"roi.intake.requester_resolved",
"roi.intake.requester_resolution_failed",
"roi.intake.patient_info_extracted",
"roi.intake.request_classified",
"roi.intake.requester_classified",
"roi.intake.record_types_selected",
"roi.intake.due_date_calculated",
"roi.intake.attestation_completed",
"roi.intake.request_split",
"roi.intake.validation_failed",        # pre-validation gate (PL-2)
"roi.logging.patient_lookup_initiated",
"roi.logging.patient_matched",
"roi.logging.patient_not_found",
```

**Metadata schema additions** (extend `TelemetryEventMetadata`):
```python
# Intake-specific metadata fields (in additional_context JSONB)
{
    "intake_channel": "upload|central_intake|electronic|fax|mail",
    "source_type": "UPLOAD|CENTRAL INTAKE|ELECTRONIC INTAKE|...",
    "major_class": "CLIN|ATTY|GOV|PAT|INS|PAYD|...",
    "requester_type": "internal|external",
    "requester_id": "12345",
    "site_id": "S32",
    "health_system_id": "...",
    "emr_system": "Epic|Cerner|Meditech|...",
    "is_emr": true,
    "record_types": ["medical_record", "billing"],
    "reason_code": "...",
    "boc_classification": "true_boc|sa_boc|not_boc|none",
    "due_date": "2026-03-15",
    "due_date_method": "site_enabled|calculated|not_provided",
    "validation_failures": ["requester_address_missing", "patient_name_missing"],
    "stork_used": true,
    "fields_auto_populated": 5,
    "fields_manually_edited": 2,
}
```

### Track B: New Frontend Events (Genuine Gaps)

These require JS instrumentation in the HealthSource UI. Prioritized by value from our Snowflake analysis.

#### B1: `roi.intake.request_opened` (Taxonomy 1.2)
**Where**: Logging task screen — when processor clicks to open a request from the queue.
**Hook**: `LoggingTaskFetched` event exists in Camunda. Could instrument the JS click handler on the task list, or catch the Camunda task claim event.
**Value**: Measures queue-to-pickup time (the "how long did it sit before someone looked at it"). Our data shows this is where weekend/afternoon gaps live.
**Metadata**: `processor_id`, `time_since_received` (calculated), `queue_name`

#### B2: `roi.intake.data_entry_completed` (Taxonomy 1.3)
**Where**: Logging form submit/save action.
**Hook**: Form submission handler in HealthSource logging UI.
**Value**: Measures actual data entry time (taxonomy's core ask). Combined with B1, gives us `time_to_log = data_entry_completed - request_opened`.
**Metadata**: `logging_method` (manual/stork_assisted), `stork_edit_required` (bool), `fields_edited_count`

#### B3: `roi.intake.stork_fields_edited` (**new, not in taxonomy**)
**Where**: After STORK populates fields, track which ones the processor changes.
**Hook**: Compare STORK auto-populated values vs. final submitted values. Diff at form submit time.
**Value**: **This is the single most valuable new event.** FTI found 90% of processors need to fix STORK. This tells us *what* STORK gets wrong, enabling targeted ADE improvement. Currently a complete blind spot.
**Metadata**: `fields_changed` (list of field names), `field_change_count`, `stork_confidence_score` (if available)

#### B4: `roi.intake.validation_failed` (**new, not in taxonomy**)
**Where**: At intake submission, when request would fail validation but currently creates an exception instead.
**Hook**: Pre-submit validation in `RequestValidator` chain. Currently validators exist but failures flow to exceptions. Add telemetry at the validation failure point.
**Value**: Directly enables PL-2 (Pre-Validation Gate). Our data shows 36% of "Field Input Required" and 70% of "Invalid/Incomplete" exceptions explicitly mention missing fields. Structured capture of *what's missing* replaces freetext exception comments with machine-parseable data.
**Metadata**: `validation_type` (requester_address|patient_name|pages|auth), `missing_fields` (list), `site_id`, `source_type`

#### B5: `roi.intake.processor_active` / `roi.intake.processor_idle` (Taxonomy gap)
**Where**: Browser tab focus/blur events during logging workflow.
**Hook**: `document.addEventListener('visibilitychange', ...)` on logging screens.
**Value**: The 35x gap between touch time and wall-clock time. This is the only way to get actual active-time measurement without stopwatch observers like FTI. Low priority for POC — nice-to-have.
**Metadata**: `active_duration_ms`, `idle_duration_ms`, `idle_reason` (tab_switch|window_blur)

---

## Architecture: How It Fits Together

```
                    HealthSource (Java)                              Telemetry Service (Python)
┌─────────────────────────────────────────────┐    ┌──────────────────────────────────────┐
│                                             │    │                                      │
│  intakeservices/                            │    │  eventdriventelemetry/                │
│  ├── RequestAuditTrail                      │    │  ├── POST /api/telemetry/event        │
│  │   └── createRequestAuditTrail()          │    │  ├── TelemetryProcessor (validate)    │
│  │       ├── write to audit DB (existing)   │    │  ├── AuditRepository (persist)        │
│  │       └── → TelemetryBridge.emit() [NEW] ──────→ │  └── hs_audit.user_interaction_     │
│  │                                          │    │       events_default (PostgreSQL)     │
│  ├── Validators                             │    │                                      │
│  │   └── validation failure [NEW] ──────────────→│                    │                  │
│  │                                          │    │                    ↓                  │
│  └── JS Frontend                            │    │           Snowflake (existing ETL)    │
│      ├── request_opened [NEW B1] ───────────────→│                                      │
│      ├── data_entry_completed [NEW B2] ─────────→│                                      │
│      ├── stork_fields_edited [NEW B3] ──────────→│                                      │
│      └── processor_active [NEW B5] ─────────────→│                                      │
│                                             │    │                                      │
│  intakequeueservices/                       │    │                                      │
│  └── STORK integration                      │    │                                      │
│      └── stork result received [bridge] ────────→│                                      │
│                                             │    │                                      │
│  workflow/ (Camunda BPMN)                   │    │                                      │
│  └── logging-subprocess.bpmn               │    │                                      │
│      ├── loggingTask claimed → bridge ──────────→│                                      │
│      └── loggingTask completed → bridge ────────→│                                      │
│                                             │    │                                      │
└─────────────────────────────────────────────┘    └──────────────────────────────────────┘
```

### Bridge Implementation Options

**Option A: In-process listener** (recommended for POC)
Add async HTTP call to telemetry service from within `RequestAuditTrail` implementation.
- Pro: No new infrastructure. Uses existing audit trail hook.
- Con: Adds latency to audit trail writes (mitigate with async/fire-and-forget).
- Files: `RequestServiceImpl.java`, `RequestAuditTrail.java`

**Option B: Database trigger / CDC**
Watch `erequest_audit_trail` table for INSERTs, forward to telemetry service.
- Pro: Zero code changes to intake services.
- Con: Adds DB trigger complexity; harder to extract structured metadata from freetext.

**Option C: Camunda task listener**
Register task listeners on BPMN events to emit telemetry.
- Pro: Clean separation. Catches workflow transitions precisely.
- Con: Only covers Camunda-managed events, not intake service logic.

**Recommendation**: **Option A for POC** (fastest, highest coverage), then migrate high-volume events to Option C for production.

---

## POC Rollout Plan

### Week 1-2: Foundation
- [ ] Extend `EventType` enum with 13 intake events
- [ ] Extend `TelemetryEventMetadata` with intake-specific `additional_context` schema
- [ ] Build `TelemetryBridge` class in intakeservices that:
  - Maps audit_type → telemetry event_type
  - Extracts structured metadata from audit_message templates (regex)
  - POSTs to telemetry service async
- [ ] Wire bridge into `RequestAuditTrail.createRequestAuditTrail()`
- [ ] Unit tests for bridge mapping + metadata extraction

### Week 3: Frontend Events
- [ ] B1: Add `roi.intake.request_opened` on logging task click
- [ ] B2: Add `roi.intake.data_entry_completed` on form submit
- [ ] B3: Add `roi.intake.stork_fields_edited` — diff STORK values vs submitted
- [ ] B4: Add `roi.intake.validation_failed` in validator chain

### Week 4: Validation + Dashboards
- [ ] Verify events flowing to PostgreSQL
- [ ] Verify Snowflake ETL picks up `user_interaction_events_default`
- [ ] Build initial Snowflake dashboard: intake events by site, channel, major_class
- [ ] Compare telemetry timestamps to existing audit trail timestamps (sanity check)
- [ ] Document findings, propose Phase 2 (fulfillment + QC events)

---

## What This POC Answers

With just intake events, we can measure:

1. **Queue-to-pickup time** (request_received → request_opened) — validates our Snowflake finding of 35x gap
2. **Actual logging time** (request_opened → data_entry_completed) — comparable to FTI's stopwatch data
3. **STORK accuracy** (stork_fields_edited) — which fields ADE gets wrong, how often
4. **Pre-validation failure patterns** (validation_failed) — structured version of our "36% missing" finding
5. **Requester lookup success rate** (requester_resolved vs failed) — already in audit trail but now structured
6. **Patient match rate** (patient_matched vs not_found) — already 22% NotFound on UPLOAD
7. **Site-level intake quality** — by enriching every event with site_id + source_type

### Value from Snowflake Analysis (what we can now automate detection of)

| Our Finding | Telemetry Event That Detects It |
|------------|-------------------------------|
| 35x touch-to-wall-clock gap | `request_opened` - `request_received` delta |
| 13.3% rework rate | `requestcapture.completed` → later `requestcapture.started` on same request |
| Worst sites = data quality errors | `validation_failed` by site_id |
| STORK needs 90% correction (FTI) | `stork_fields_edited.field_change_count > 0` rate |
| "Missing" in 36-70% of exceptions | `validation_failed.missing_fields` |
| Weekend 4.8x queue gap | `request_opened` - `request_received` by day_of_week |
| 82K "non-approved site" fulfillment exceptions | `requester_classified` + site routing metadata |

---

## Event Volume Estimate (90 days, intake only)

Based on Snowflake audit trail counts:
- `RequestStateUpdated` to Logging: ~800K (all) / ~250K (human-worked)
- Requester lookups: ~250K
- Patient lookups: ~1.3M (across 3 events)
- Record type selections: ~250K
- BOC classifications: ~250K

**Estimated telemetry volume**: ~3M events/quarter for intake alone. At ~500 bytes/event average = ~1.5 GB/quarter. Well within PostgreSQL + Snowflake capacity.

---

## Key Files to Modify

### Python (telemetry lib + service)
| File | Change |
|------|--------|
| `modules/python/libs/telemetry/src/hs_telemetry/types.py` | Add 13 intake event types |
| `modules/python/libs/telemetry/src/hs_telemetry/metadata.py` | Add intake metadata fields |
| `modules/python/libs/telemetry/generate_schema.py` | Regenerate schemas |

### Java (intake services)
| File | Change |
|------|--------|
| `services/intakeservices/.../service/impl/RequestServiceImpl.java` | Wire TelemetryBridge |
| `services/intakeservices/.../service/RequestAuditTrail.java` | Add bridge call after audit write |
| `services/intakeservices/.../cache/AuditTrailCache.java` | Reference only (mapping source) |
| `services/intakeservices/.../validator/service/impl/*.java` | Emit validation_failed events |

### Java (workflow — later)
| File | Change |
|------|--------|
| `services/workflow/hs-workflow-logging/.../logging-subprocess.bpmn` | Add task listeners |

### JavaScript (frontend)
| File | Change |
|------|--------|
| Logging task list click handler | Emit request_opened |
| Logging form submit handler | Emit data_entry_completed + stork diff |

---

## Open Questions

1. **Snowflake ETL**: Does the existing ETL from `hs_audit` PostgreSQL → Snowflake already cover the `user_interaction_events_default` table, or does it need to be added?
2. **Async bridge**: Should the Java→Python bridge use a message queue (Azure Service Bus already exists for intake) or direct HTTP? For POC, HTTP is simpler. For prod, queue is safer.
3. **Session ID generation**: The schema requires `sess_UUID`. Where does session tracking live in HealthSource's Java frontend? Is there an existing session concept we can reuse?
4. **Processor ID → person mapping**: Taxonomy wants processor_tenure_category and location. Where does HR data live? Is there a Sailpoint or Oracle mapping available? (Parking lot item from taxonomy doc says no.)
5. **STORK field diff**: Can we get the STORK auto-populated values *before* processor edits, or only the final submitted values? Need to check if the STORK response is persisted anywhere.
