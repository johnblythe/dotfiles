# NIGHT LIGHT ANALYSIS - Sample Incident

**Generated:** 2026-01-14 17:15 UTC
**Analysis Window:** 12 hours (05:12 - 17:12 UTC)
**Trigger:** Morning incident investigation

---

## TIER 0: ACTIVE INCIDENTS

Monitors currently in Alert state:

| Monitor | Status | Relevance |
|---------|--------|-----------|
| Endpoint Error Rate is High | Alert | Direct |
| Containers in CrashLoopBackoff | Alert | Direct |
| Intake Queue Processing Failed | Alert | Direct |
| Kubernetes Pods Restart | Alert | Infra |
| Kubernetes Deployments | Alert | Infra |

---

## TIER 1: ANOMALY DETECTION

**Services analyzed:** 6
**Anomalies detected:** 13 events across 5 services

### ANO-1: auth-service - Traffic Spike
- **Severity:** CRITICAL (3.2σ)
- **Time:** 15:36 - 16:06 UTC (40 min)
- **Peak:** 444 hits (+233% from mean of 133)
- **Threshold:** >326 hits (mean + 2σ)
- **Status:** ACTIVE (last anomaly 7 min ago)

### ANO-2: search-service - Traffic Spike
- **Severity:** WARNING (3.0σ)
- **Time:** 14:08 - 15:10 UTC (72 min)
- **Peak:** 652 hits (+326% from mean of 153)
- **Threshold:** >488 hits (mean + 2σ)
- **Status:** ACTIVE (last anomaly 3 min ago)
- **Note:** EARLIEST ANOMALY - potential leading indicator

### ANO-3: intake-service - Traffic Spike
- **Severity:** WARNING (2.6σ)
- **Time:** 15:36 - 16:04 UTC (38 min)
- **Peak:** 895 hits (+303% from mean of 222)
- **Threshold:** >732 hits (mean + 2σ)
- **Status:** ACTIVE (last anomaly 9 min ago)

### ANO-4: workflow-service - Traffic Spike
- **Severity:** WARNING (2.3σ)
- **Time:** 16:32 - 17:02 UTC (40 min)
- **Peak:** 7079 hits (+228% from mean of 2159)
- **Threshold:** >6437 hits (mean + 2σ)
- **Status:** ACTIVE (last anomaly 11 min ago)

### ANO-5: platform-service - Traffic Spike
- **Severity:** WARNING (2.1σ)
- **Time:** 16:42 UTC (10 min)
- **Peak:** 27102 hits (+197% from mean of 9110)
- **Threshold:** >26520 hits (mean + 2σ)
- **Status:** Resolved (31 min ago)

---

## TIER 1.5: ERROR LOG ANALYSIS

**Time Window:** Last 6 hours
**Total Errors:** 1000+ (truncated)

### High-Volume Error Patterns

| Service | Error Pattern | Volume |
|---------|--------------|--------|
| integration-service | "Error while updating request state" | Dozens/min |
| workflow-service | "UnassignUserDelegate: Exception occurred" | High |
| intake-queue | "CREATE_REQUEST_FAILED" | Moderate |
| document-service | "ERROR_UPLOADING_CHUNKS" | Moderate |
| auth-service | "Failed in platform validateUserInfo" | 322 total |

### auth-service Error Breakdown (322 errors in 6h)

- `Failed in platform validateUserInfo` - authentication validation failures
- `Token authentication failed HTTP 401 Unauthorized` - token validation issues
- `User Not found` - user lookup failures

---

## CASCADE TIMELINE

```
14:08 UTC  search-service       First anomaly spike (2.8σ)
           └── Potential trigger event

15:36 UTC  auth-service          CRITICAL spike begins (3.2σ)
           intake-service        WARNING spike begins (2.6σ)
           └── Cascade propagation

16:32 UTC  workflow-service      WARNING spike begins (2.3σ)
           └── Downstream impact

16:42 UTC  platform-service      WARNING spike (2.1σ)
           └── Platform-wide stress

Current    Multiple monitors in Alert state
           Cascading errors across services
```

---

## EARLY WARNING ASSESSMENT

### Would Night Light Have Detected This Early?

**YES** - Phase 1 anomaly detection would have flagged this ~2 hours before escalation.

| Detection Point | Time | Lead Time |
|-----------------|------|-----------|
| search-service WARNING (2.8σ) | 14:08 UTC | +88 min before CRITICAL |
| auth-service CRITICAL (3.2σ) | 15:36 UTC | Incident threshold |

### What Night Light Would Have Reported at ~14:30 UTC

> **ANO-1: search-service - Traffic anomaly**
> - Severity: WARNING (2.8σ, +309% from baseline)
> - Time: 14:08 - ongoing
> - Peak: 625 hits (baseline: ~153)
> - Action: Investigating for correlated service impact...

This would have provided **~1.5 hours of lead time** before the auth-service CRITICAL spike at 15:36 UTC.

---

## ROOT CAUSE INVESTIGATION

### Timeline Reconstruction

```
13:41 UTC  Kubernetes HPA events fire
           - audit-poller HorizontalPodAutoscaler
           - request-worker HorizontalPodAutoscaler
           - Multiple pod events: ocr-worker, transform-worker
           └── TRIGGER: K8s scaling/restart activity

14:08 UTC  search-service traffic anomaly begins (2.8σ)
           └── First statistical anomaly detected

15:36 UTC  auth-service CRITICAL (3.2σ)
           intake-service WARNING (2.6σ)
           └── Cascade propagation begins

Current    Ongoing cascade with high error volumes
```

### Key Error Patterns Identified

| Error Pattern | Service | Volume | Root Cause |
|---------------|---------|--------|------------|
| `UnassignUserDelegate: Exception` | workflow-service | 1000+/hr | Workflow state corruption |
| `Workflow FireEvent Failed: 404` | integration-service | 543 events | Workflow processes not found |
| `Error updating request state` | integration-service | Dozens/min | Downstream of workflow failures |
| `Unable to decrypt the token` | search-service | 21 events | Token validation cascade |
| `Failed validateUserInfo` | auth-service | 322 events | Auth validation overload |

### Cascade Chain Analysis

```
┌─────────────────────────────────────────────────────────────────┐
│  1. TRIGGER: Kubernetes HPA scaling events (13:41 UTC)          │
│     - Pod restarts/scaling in worker namespace                  │
│     - audit-poller and request-worker HPA activity              │
└────────────────────────┬────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. PROPAGATION: Workflow state issues begin                    │
│     - UnassignUserDelegate exceptions cascade                   │
│     - Workflow engine can't find processes (404)                │
│     - Request state updates fail                                │
└────────────────────────┬────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. AMPLIFICATION: Service retry storms                         │
│     - search-service shows traffic spike (14:08 UTC)            │
│     - Token decryption errors appear                            │
│     - Auth validation requests increase                         │
└────────────────────────┬────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. SATURATION: Critical services overwhelmed (15:36+ UTC)      │
│     - auth-service CRITICAL spike                               │
│     - intake, workflow, platform all affected                   │
│     - Multiple monitors enter Alert state                       │
└─────────────────────────────────────────────────────────────────┘
```

### Root Cause Hypothesis

**Primary:** Kubernetes scaling/restart activity at 13:41 UTC disrupted workflow state. The `UnassignUserDelegate` started throwing exceptions, causing workflow processes to become orphaned (404 errors). This created a cascade of retry traffic as services attempted to re-validate tokens and update request states.

**Contributing factors:**
1. HPA scaling may have caused workflow pods to restart mid-process
2. Workflow process instances lost their correlation to pods
3. No circuit breaker on workflow-dependent services
4. Token validation retries amplified the traffic spike

### Evidence

1. **Kubernetes events at 13:41 UTC** - HPA activity for audit-poller, request-worker
2. **Workflow 404 errors** - 543 instances of `FireEvent Failed: ErrorCode: 404`
3. **UnassignUserDelegate exceptions** - Continuous high-volume errors in workflow-service
4. **Correlated traffic spikes** - 5 services showing anomalies within 2-hour window

---

## OBSERVABILITY GAPS

### Gap 1: No early warning for workflow exceptions
- **Finding:** `UnassignUserDelegate` exceptions started before the traffic spikes
- **Gap:** No monitor triggers on workflow engine error rate
- **Recommendation:** Add monitor for workflow `FireEvent Failed` error rate > 10/5min

### Gap 2: Search service anomaly not monitored
- **Finding:** Night Light detected 2.8σ anomaly at 14:08, but no alert fired
- **Gap:** No statistical anomaly detection on search-service traffic
- **Recommendation:** Add outlier monitor on search-service request rate

### Gap 3: Cascade detection missing
- **Finding:** 5 services showed correlated anomalies, but no correlation alert
- **Gap:** Individual service monitors don't detect multi-service cascades
- **Recommendation:** Add composite monitor checking for >2 services anomalous simultaneously

---

## NEXT STEPS

1. ~~**Investigate 14:00 UTC**~~ - Identified K8s HPA events at 13:41 as trigger
2. ~~**Root cause analysis**~~ - Workflow state corruption from pod scaling
3. **Monitor gap analysis** - 3 gaps identified above
4. **Remediation:** Investigate why HPA scaling disrupted workflow engine state

---

## SUMMARY

| Tier | Status | Count | Action |
|------|--------|-------|--------|
| 0 - Active Incidents | Alert | 5 | Ongoing response |
| 1 - Anomalies | CRITICAL | 13 events / 5 services | Investigate cascade |
| 2 - Hygiene | -- | Not run | Deferred |
| 3 - Observability | Gap | 3 | Add early warning monitors |
