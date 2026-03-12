# NIGHT LIGHT REPORT - Sample (Tiered Format)

**Lookback:** 4 hours | **Mode:** Dry Run

═══════════════════════════════════════════════════════════════════
                         TIER 0: ACTIVE INCIDENTS
═══════════════════════════════════════════════════════════════════

48 monitors in Alert state. Key application-related:

| Monitor | Status | Relevance |
|---------|--------|-----------|
| Endpoint Error Rate is High | ALERT | Direct |
| Service Bus deadletter count | ALERT | Direct |
| Deployment Replica Count is 0 | ALERT | Direct |
| Slow Database Queries | ALERT | Related |
| Kubernetes Pods in Bad State | ALERT | Infra |

**Assessment:** Multiple monitors alerting - warrants investigation.

═══════════════════════════════════════════════════════════════════
                         TIER 1: ANOMALY DETECTION
═══════════════════════════════════════════════════════════════════

Services analyzed: 2 (sample run)
Anomalies detected: 3

### ANO-1: auth-service - Traffic spike (ACTIVE)
- **Severity:** CRITICAL (4.3σ, +230% from baseline)
- **Time:** 13:30 - 13:57 UTC (37 min)
- **Peak:** 209 hits (baseline: ~63)
- **Status:** ACTIVE - last anomaly 3 minutes ago
- **Correlation:** Coincides with endpoint error rate monitor alert

### ANO-2: auth-service - Earlier spike
- **Severity:** CRITICAL (3.4σ, +186% from baseline)
- **Time:** 13:00 - 13:05 UTC (15 min)
- **Peak:** 181 hits

### ANO-3: platform-service - Traffic spike (ACTIVE)
- **Severity:** WARNING (2.9σ, +180% from baseline)
- **Time:** 13:39 - 13:53 UTC (24 min)
- **Peak:** 10,835 hits (baseline: ~3,876)
- **Status:** ACTIVE - last anomaly 7 minutes ago

**Ticket:** WOULD CREATE ticket for ANO-1 investigation
**PR:** None (needs investigation first)

═══════════════════════════════════════════════════════════════════
                         TIER 2: OPERATIONAL HYGIENE
═══════════════════════════════════════════════════════════════════

### NPE-1: NullPointerException in bulk-request-worker
- **Count:** 4 occurrences (4h window)
- **Service:** bulk-request-worker
- **Category:** code_quality
- **Sample:** `java.lang.NullPointerException` in bulk request processing
- **Effort:** Small
- **Action:** Investigate null check in bulk processor

### TIMEOUT-1: Request Search timeouts in integration-service
- **Count:** 100+ occurrences (4h window, capped query)
- **Service:** integration-service
- **Category:** performance
- **Pattern:** `Request Search timed out for cause: class org.postgresql...`
- **Frequency:** ~25/hour sustained
- **Effort:** Medium
- **Suggested fix:** Review search query performance, add timeout handling, consider async pattern
- **Note:** This is a steady drip, not a spike - classic hygiene issue

### ORA-1: Database connection timeouts in status-poller-service
- **Count:** 75 occurrences (4h window)
- **Service:** status-poller-service
- **Category:** infrastructure
- **Pattern:** `ORA-12170: Cannot connect. TCP connect timeout`
- **Frequency:** ~19/hour sustained
- **Effort:** Medium
- **Suggested fix:** Check connection pool, firewall rules, or DB health
- **Note:** Consistent rate suggests config issue, not transient

### WORKFLOW-1: Workflow engine errors
- **Count:** 436 logs matching ENGINE-* pattern (4h window)
- **Service:** workflow-service, integration-service
- **Category:** workflow
- **Pattern:** `ENGINE-03005 Execution listener failed`, `UnassignTask Failed`
- **Effort:** Medium
- **Suggested fix:** Review workflow delegate implementations
- **Note:** High volume - may correlate with Tier 1 anomalies

═══════════════════════════════════════════════════════════════════
                         TIER 3: OBSERVABILITY GAPS
═══════════════════════════════════════════════════════════════════

### GAP-1: No dedicated monitor for Request Search timeouts
- **Pattern detected:** 100+ timeouts in 4h with no alert
- **Recommendation:** Add monitor for integration-service "Request Search timed out"
- **Suggested threshold:** >10/hour WARNING, >50/hour CRITICAL

### GAP-2: Database connection timeout not monitored
- **Pattern detected:** Steady ORA-12170 errors
- **Recommendation:** Add monitor for status-poller-service "ORA-"
- **Suggested threshold:** >5/hour WARNING

### GAP-3: auth-service anomaly threshold
- **Current:** Monitor may not exist or threshold too high
- **Detected:** 4.3σ spike not caught by existing monitors
- **Suggested threshold:** >132 hits/5m (mean + 2σ)

═══════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════

| Tier | Status | Count | Action |
|------|--------|-------|--------|
| 0 - Incidents | ALERT | 5+ | Active monitors alerting |
| 1 - Anomalies | CRITICAL | 3 | Investigation needed |
| 2 - Hygiene | WARNING | 4 | Small PRs / config fixes |
| 3 - Observability | INFO | 3 | Add to monitoring backlog |

---

## Key Insight: Tier 2 Value Demonstrated

Even if Tier 1 showed "all clear", Tier 2 would have surfaced:
- **TIMEOUT-1**: 100+ search timeouts (not spiking, just steady noise)
- **ORA-1**: 75 database connection failures (consistent, not anomalous)
- **NPE-1**: 4 NullPointers (low volume, but fixable)

These wouldn't trigger anomaly detection because they're **steady-state degradation**,
not statistical outliers. That's exactly the Tier 2 value proposition.

---

*Report generated by Night Light v3 (tiered)*
