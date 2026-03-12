# Snowflake Schema Reference — HEALTHSOURCE.CONNEX

Quick reference for the tables used in this analysis. Column names are UPPERCASE in Snowflake.

## Core Tables

### erequest_dynamic
Request metadata. One row per request.
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_ID | NUMBER | PK |
| SOURCE_TYPE | TEXT | **Key filter**: UPLOAD, CENTRAL INTAKE = human-worked |
| MAJOR_CLASS | TEXT | CLIN, ATTY, PAT, INS, GOV, PAYD |
| IS_EMR | TEXT/BOOL | Whether site has EMR integration |
| DDS_SITE_ID | TEXT | Site identifier (NOT `site_id`) |
| CREATED_DT | TIMESTAMP | Request creation date |
| ONSITE_JOB | TEXT | — |

### erequest_status_dynamic
Every status transition. Multiple rows per request.
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_ID | NUMBER | FK to erequest_dynamic |
| STATUS_ID | NUMBER | FK to request_status |
| STATE_TIMESTAMP | TIMESTAMP | When the transition happened |

### request_status
Status lookup table.
| Column | Type | Notes |
|--------|------|-------|
| STATUS_ID | NUMBER | PK |
| STATUS_DESC | TEXT | e.g., "Logging", "Redo Logging", "Fulfillment", "QC In Progress" |

Key statuses for TAT analysis:
- **Active work**: Logging, Redo Logging, Fulfillment, QC In Progress
- **Queue/wait**: Back To Logging, Back To Fulfillment, Fulfillment Pend
- **Hold**: Logging Exception, Logging On Hold, Logging Correspondence, Fulfillment Exception, Fulfillment On Hold
- **Transit**: Digital Auth Review

### erequest_audit_trail_dynamic
422 distinct audit event types. High volume (~200M+/90d).
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_ID | NUMBER | FK |
| AUDIT_TYPE | TEXT | Event type (e.g., "RequestStateUpdated", "QCInProgressStarted") |
| AUDIT_MESSAGE | TEXT | Human-readable description (NOT `audit_description`) |
| EVENT_DT | TIMESTAMP | When the event occurred (NOT `audit_timestamp`) |
| EVENT_COMMENTS | TEXT | Additional structured data (often empty) |
| USER_ID | TEXT | Who triggered the event |
| CREATED_BY | TEXT | — |
| TASK_ID | TEXT | Camunda task reference |

Top audit types by 30-day volume:
1. RequestStateUpdated (51M)
2. AuditCamundaTaskEvent (22M)
3. AuditExternalIntegrationStatusCallback (17M)
4. RequestedRecordTypes (14M)
5. RetrievedRecordTypes (13M)

## Exception Tables

### erequest_exception
Exception records. One row per exception event.
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_ID | NUMBER | FK |
| EXCEPTION_REASON_ID | NUMBER | FK to erequest_exception_reason (NOT text field) |
| EXCEPTION_COMMENT | TEXT | Freetext comment from processor |
| IS_REMOVED | NUMBER | 1 = resolved |
| CREATED_DT | TIMESTAMP | When exception was created |

### erequest_exception_reason
48 reason codes in 3 categories.
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_EXCEPTION_REASON_ID | NUMBER | PK |
| EXCEPTION_REASON_CODE | TEXT | Short code |
| EXCEPTION_REASON_DESC | TEXT | e.g., "Field Input Required", "Clinic", "Invalid/Incomplete Request" |
| EXCEPTION_REASON_PARENT_ID | NUMBER | FK to category |

### erequest_exception_category
3 categories: LFEC (logging), FFEC (fulfillment), NFEC (new/intake).

## QC Tables

### erequest_qc_conflicts
Structured conflict data from Verify system. Two identifier types: "Patient Name" and "DOB".
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_QC_CONFLICTS_ID | NUMBER | PK |
| EREQUEST_ID | NUMBER | FK |
| EREQUEST_QC_ID | NUMBER | FK to erequest_qc |
| IDENTIFIER | TEXT | "Patient Name" or "DOB" |
| IDENTIFIER_VALUE | TEXT | The conflicting value found on chart |
| PAGES | TEXT | JSON array of page numbers |

### erequest_qc_action
What reviewers do with conflicts. 99.1% ignored, 0.9% deleted.
| Column | Type | Notes |
|--------|------|-------|
| EREQUEST_QC_ACTION_ID | NUMBER | PK |
| EREQUEST_ID | NUMBER | FK |
| EREQUEST_QC_CONFLICTS_ID | NUMBER | FK |
| IGNORED | TEXT | "Y"/"N" |
| DELETED | TEXT | "Y"/"N" |
| IGNORED_REASON_ID | NUMBER | FK to ignore_conflict_reasons |
| DELETED_REASON_ID | NUMBER | FK to delete_conflict_page_reasons |
| COMMENTS | TEXT | Reviewer freetext |

### ignore_conflict_reasons
7 reasons why reviewers ignore conflicts:
| ID | Reason |
|----|--------|
| 1 | Doctor/Nurse |
| 2 | Maiden name |
| 3 | Not a DOB |
| 4 | Not a DOS |
| 5 | Valid Patient Name/DOB/DOS |
| 6 | Other |
| 7 | Medical terminology/verbiage |

## Connection
```bash
/Applications/SnowSQL.app/Contents/MacOS/snowsql -c datavant
# Role: ENG_PROVIDER, DB: HEALTHSOURCE, Schema: CONNEX
# SSO re-auths every invocation (no session caching)
```
