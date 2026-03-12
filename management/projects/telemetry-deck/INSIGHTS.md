# Event Telemetry Analysis — Key Insights

## Source Data
- **Database**: Snowflake `HEALTHSOURCE.CONNEX`, last 90 days
- **Scope**: Human-worked requests (UPLOAD + CENTRAL INTAKE)
- **Queries**: `queries/q1-q53` (all reproducible, see `QUERY_INDEX.md`)
- **Reference docs**: `sources/` directory

---

## Insight 1: Two Populations Hide in Every Metric

Every TAT metric is bimodal. ~70% of request volume auto-transitions (ELECTRONIC, PULLLIST, MANUAL INTAKE) in under 3 seconds. The remaining ~30% (UPLOAD, CENTRAL INTAKE) requires human work.

**Blending these populations produces meaningless averages.** All analysis must filter to human-worked requests first.

| Channel | Median Logging | What's Happening |
|---------|---------------|-----------------|
| ELECTRONIC/PULLLIST/MANUAL | 1 sec | Auto-transition, no human |
| UPLOAD | 20-150 min | Human logging work |
| CENTRAL INTAKE | 15-135 min | Human logging work |

---

## Insight 2: source_type Is the #1 Variance Driver

Not EMR system. Not major_class alone. `source_type` (intake channel) is the primary predictor of TAT.

**EMR Surprise** (CLIN+UPLOAD fulfillment):
- With EMR: 2.7h median
- Without EMR: 3.0h median
- Only 10% difference — EMR is not the bottleneck the taxonomy assumes

**Major class matters within human-worked channels:**
- CLIN: fastest (structured request letters, ADE reads well)
- ATTY: 3.5-6.6x slower (legal language, broad dates, fee handling)
- Variance: 21x spread at P25 vs P75 across classes

---

## Insight 3: ~60% of Proposed Taxonomy Already Exists

422 distinct audit event types in `erequest_audit_trail_dynamic`. 15+ of the taxonomy's 24 "new" events map directly to existing events.

Key existing events:
- `RequestStateUpdated` (127M/90d) — all status transitions
- `AuditCamundaTaskEvent` (55M) — workflow task lifecycle
- `PatientLookupStarted/Finished/NotFound` (1.3M) — already instrumented
- `FulfillmentTaskFetched`, `FullfillmentSubmitTaskCompleted` — session boundaries

**Real gaps** (6-8 events, not 24):
- Intra-session form field timing
- STORK edit tracking (what ADE got wrong)
- Processor active/idle detection
- Exception root cause classification

---

## Insight 4: Rework Rate Is 4x Higher Than Reported

Blended rate: 3.2%. **Human-worked only: 13.3%** (1 in 7 requests).

| Journey | Count | % | Median Total |
|---------|-------|---|-------------|
| Clean pass | 658K | 81.4% | 2.8h |
| Had redo | 108K | 13.3% | 11.9h |
| Had exception | 90K | 11.1% | 18.5h |
| Sent back | 6.4K | 0.8% | 44.2h |

---

## Insight 5: ~65% of Rework TAT Is Queue Time, Not Work Time ⭐

**This is the single most important finding.**

For rework requests, actual hands-on-keyboard time is small. The majority of elapsed time is requests sitting in queues between stages.

### Clean Pass Decomposition
- Active logging: **2.8h** → Done. No wait.

### Redo Request Decomposition
- Initial logging: **0.9h** (active)
- Queue time (waiting to be picked up for redo): **~10h**
- Redo work: **0.6h** (active)
- **Total: 11.9h** — but only 1.5h of actual work

### Exception Request Decomposition
- Active logging before exception: **1.7h**
- Sitting in exception status: **7.4h** (hold/queue)
- Resolution + remaining work: varies
- **Total: 18.5h** — but 7.4h is pure wait

### Sent Back Decomposition
- Active logging: **12.4h** (these are genuinely complex)
- Hold time: **6.9h**
- Queue gaps: **~25h**
- **Total: 44.2h** (1.8 days)

### Per-Status Median Durations
| Status | Category | Median |
|--------|----------|--------|
| Logging | Active work | 2.1h |
| Redo Logging | Active work | 16 min |
| Back To Logging | Queue (waiting) | **6.6h** |
| Logging Exception | Hold | **6.9h** |
| Fulfillment | Active work | 18.6h |
| Fulfillment Exception | Hold | **20.1h** |
| Fulfillment Pend | Queue | **6.0h** |
| QC In Progress | Active work | 10 min |
| Digital Auth Review | Transit | 3.3h |

**Implication**: The telemetry ROI isn't in measuring how long logging takes (we know: 2.8h). It's in understanding why requests sit in exception for 7h before someone picks them up. That's a staffing/routing problem, not an instrumentation problem.

---

## Insight 6: Exception Reasons Are Now Decoded

385K exceptions on human-worked requests in 90 days. Top 3 = 62%.

| Reason | Count | % | TAT Impact | Skew |
|--------|-------|---|-----------|------|
| Clinic | 78.5K | 20.4% | 2.8h (faster!) | 93% CLIN, 83% Central |
| Field Input Required | 67.5K | 17.5% | 22.1h (+176%) | 58% Upload |
| Global Field Input | 45.5K | 11.8% | 18.9h (+136%) | 61% Upload |
| Internal Department | 45.4K | 11.8% | 18.5h (+131%) | 93% Upload, 66% ATTY |
| Supervisor Review | 32.5K | 8.4% | — | Mixed |
| Invalid/Incomplete | 30.0K | 7.8% | — | Mixed |

**"Clinic" exceptions are actually fast** (2.8h vs 8h clean) — known wait, short turnaround.

**"Field Input Required" is the killer** — 29.3% combined (reason 21 + 154), adds 14+ hours. The system literally cannot proceed because required data is missing. Tracking WHICH fields trigger this = the highest-value telemetry investment.

---

## Insight 7: Patient Lookup Already Instrumented

Taxonomy proposes `roi.logging.patient_lookup_initiated` as new. It already exists.

- 1.3M lookup events in 90 days
- **22% NotFound rate** on UPLOAD channel
- Lookup itself is fast (median 1 sec, P95 2-3 sec)
- Cost is in the retry loop when it fails

---

## Insight 8: Resubmission Reasons Are Semi-Structured and Categorizable

158K resubmissions to logging in 90 days. Comments are freetext but highly repetitive — clear categories emerge:

| Category | Count | % | Automatable? |
|----------|-------|---|-------------|
| Unclassified | 34.6K | 21.9% | Needs deeper analysis |
| Patient/MRN Issue | 21.4K | 13.6% | **YES** - MRN lookup/match |
| Site/Location Update | 20.7K | 13.1% | **YES** - routing rule |
| Continuity of Care | 15.8K | 10.0% | Partial - classification |
| DAR/Relog Required | 13.0K | 8.3% | **YES** - auto-reroute |
| Split / Multiple Items | 11.8K | 7.4% | Partial - detection |
| Short Code / ID Only | 11.0K | 7.0% | Unknown (numeric codes) |
| Billing/Fee/Cert | 6.9K | 4.4% | Partial |
| Second Review Needed | 5.8K | 3.7% | No - human judgment |
| No Reason Given | 3.5K | 2.2% | N/A |
| Pull List | 3.5K | 2.2% | **YES** - PDCR-411 |

**Key finding**: ~35% of resubmissions (Patient/MRN + Site/Location + DAR) are essentially data correction tasks that could be automated or prevented upstream.

Common resubmission comments (verbatim):
- "adding mrn", "ADD MRN", "mrn not assigned", "PT/MRN MATCH/LOOK UP NEEDED"
- "Updated site location", "Moving to CBO Landing Site"
- "please relog to allow for DAR process", "UPDATED SITE LOCATION RESUBMIT FOR DAR"
- "split", "multiple patients", "needs to be split"

---

## Insight 9: QC Verify System Already Produces Structured Conflict Data ⭐

The Verify system (automated QC) already catches and records structured conflicts in `EREQUEST_QC_CONFLICTS`:

**Conflict types detected:**
| Identifier | 90-day Count | Unique Requests |
|-----------|-------------|----------------|
| Patient Name | 524K | 137K |
| DOB | 272K | 108K |

**What happens to conflicts:**
- 762K conflicts **ignored** (99.1%) — reviewer marks as false positive
- 7.2K conflicts **deleted** (0.9%) — actual wrong patient

**Why conflicts are ignored (structured reasons):**
| Reason | % |
|--------|---|
| Valid Patient Name/DOB/DOS | 44.1% |
| Medical terminology/verbiage | 25.3% |
| Other | 11.0% |
| Doctor/Nurse name | 9.6% |
| Not a DOB | 9.0% |
| Maiden name | 0.6% |

**Implication**: The Verify system is flagging ~800K conflicts per quarter but **99% are false positives**. The top ignore reasons (valid name, medical terminology, doctor/nurse names) suggest the conflict detection algorithm needs tuning, not more telemetry. Reducing false positives would save enormous QC reviewer time.

---

## Insight 10: Exception Comments Reveal Field-Level Gaps

Exception comments across top reasons contain structured keywords that identify exactly what's missing:

### "Field Input Required" (67.5K exceptions)
Top comments (verbatim):
- "Requester address is missing" (5.5K+ across variants)
- "Not a coc" / "NOT A COC" (6.4K — miscategorized requests)
- "Pt name missing" / "PAT NAME MISSING" (1K+)
- "Request pages missing" / "Blank page"
- "kindly assist bill to shipped to address" (2.5K)

**Keyword analysis across all exception comments:**
| Keyword | Field Input Required | Invalid/Incomplete | Global Field Input |
|---------|---------------------|-------------------|-------------------|
| "missing" | 24K (36%) | 21K (70%) | 2.3K (5%) |
| "name" | 3.5K | 2.6K | 1.6K |
| "date" | 1.1K | 200 | 2.4K |
| "auth" | 261 | 214 | 2.1K |
| "DOB" | 69 | 293 | 882 |
| "page" | 1.9K | 395 | 972 |
| "MRN" | — | — | — |

**"Missing" is the dominant signal** — 36% of Field Input Required and 70% of Invalid/Incomplete exceptions explicitly mention something missing. This is a pre-validation opportunity: check for required fields BEFORE the request enters the workflow.

---

## Insight 11: QC Lifecycle Is Fully Traceable in Audit Trail

The full QC lifecycle exists in audit events (30-day counts):

| Event | Count | What It Means |
|-------|-------|--------------|
| QCInProgressStarted | 3.8M | QC review begins |
| NotifyQCRequest | 3.8M | QC notification sent |
| NewQCResults | 85K | Verify results received |
| AuditFulfillmentSubmitNoPotentialIssue | 729K | Clean pass |
| AuditFulfillmentSubmitPotentialIssue | 165K | Issues flagged |
| AuditFulfillmentQcSubmit (passed) | 86K | QC approved |
| RequestRejectedInCf | 377K | Chart image rejected |
| RequestResubmittedToLogging | 57K | Sent back for rework |
| Redo LoggingTaskFetched | 33K | Redo picked up |
| AuditAuthValidationReviewApproved | 649K | Auth validation pass |
| AuditAuthValidationReviewRejected | 28K | Auth validation fail |

**Key ratio**: 649K auth approvals vs 28K rejections = 4.1% auth rejection rate.

**RequestRejectedInCf** (377K/month) — "chart image rejected by QA reviewer" is the single largest rejection event. This is a chart-image quality issue, not a data entry issue.

---

## Insight 12: Chart Image Rejection Is a ChartFast/PAYD Pipeline Issue, Not Human Work

377K/month `RequestRejectedInCf` events are **almost exclusively ELECTRONIC INTAKE + PAYD** (audit/pay-on-delivery) — not human-worked requests at all.

| Source Type | Major Class | Rejections | Unique Requests |
|------------|-------------|-----------|----------------|
| ELECTRONIC INTAKE | PAYD | 377,586 | 377,348 |
| MANUAL INTAKE | PAYD | 36 | 36 |
| Everything else | — | 5 | 5 |

**Each request is rejected exactly once** (377K rejections ≈ 377K unique requests). This is a batch automated process where the ChartFast integration rejects chart images it can't match to patients.

Surrounding events reveal the pipeline: QC → Match In Progress → "chart image rejected" → "Delivered to CF" → workflow complete. The most common associated event is `FulfillmentCorrespondenceTaskCompleted` with reason "Patient Not Found."

**This is NOT a logging quality issue.** It's a ChartFast image-to-patient matching problem in the automated audit pipeline. Irrelevant to human-worked TAT analysis, but worth monitoring as a separate operational metric.

---

## Insight 13: Temporal Patterns — Afternoon & Weekend Exceptions Sit Longest

Exception queue duration varies dramatically by when the exception is created:

| Shift | Exceptions | Median Wait | P75 Wait | P95 Wait |
|-------|-----------|------------|---------|---------|
| Morning (8a-2p) | 7,749 | **3.7h** | 15.8h | 46.0h |
| Overnight (12a-8a) | 2,525 | 6.0h | 12.3h | 57.2h |
| Evening (6p-12a) | 2,234 | 6.4h | 10.9h | 39.9h |
| Weekend | 3,926 | 6.6h | **64.7h** | **94.1h** |
| Afternoon (2p-6p) | 5,120 | **10.9h** | 19.2h | 45.7h |

**Key patterns:**
- **Afternoon is worst on weekdays**: Exceptions created 2-6pm ET sit 10.9h median — likely created end-of-shift, not picked up until next morning.
- **Weekend is catastrophic at P75**: 64.7h at P75 = exceptions created Saturday afternoon don't get touched until Monday. P95 = 94h (nearly 4 days).
- **Morning is fastest**: Exceptions created during morning shift get resolved same day (3.7h median).
- **Thursday/Friday afternoon spike**: Median 14.7h (Thu 3pm) to 18.2h (Fri 3pm) — end-of-week exceptions bleed into weekend.

**Day of week summary:**
| Day | Exceptions | Median | P75 |
|-----|-----------|--------|-----|
| Mon | 399 | 6.0h | 11.8h |
| Tue | 4,551 | 6.3h | 14.6h |
| Wed | 4,625 | 5.7h | 17.4h |
| Thu | 4,623 | 6.6h | 18.1h |
| Fri | 3,430 | 7.0h | 17.9h |
| Sat | 3,886 | 6.2h | **64.7h** |
| Sun | 40 | **33.1h** | 36.6h |

Note: Monday's low count (399) suggests data is UTC-shifted — "Monday" events may actually be late Sunday/early Monday.

---

## Insight 14: 10x Site Variance — Worst Sites Have 30% Issue Rates

102 sites with 100+ human-worked requests in 90 days. Issue rates range from **0.2% to 45%**.

**Distribution:**
| Issue Rate Band | Sites | Volume | Avg Issue % |
|----------------|-------|--------|-------------|
| < 1% | 44 | 158K | 0.6% |
| 1-2% | 29 | 127K | 1.4% |
| 2-5% | 23 | 4.2M | 3.1% |
| 5-10% | 3 | 18K | 6.9% |
| 10-20% | 1 | 815 | 19.0% |
| 20%+ | 2 | 1.2K | 45.0% |

**Worst sites (500+ requests):**
| Site | Requests | Redo % | Exception % | Combined |
|------|----------|--------|------------|----------|
| S32 | 991 | 0.5% | **29.5%** | **30.0%** |
| V56 | 815 | 1.5% | **17.5%** | **19.0%** |
| S66 | 5,597 | 3.7% | 5.4% | 9.1% |
| S48 | 11,180 | 0.7% | 4.9% | 5.6% |
| S38 | 10,556 | **4.5%** | 0.2% | 4.7% |

**Best sites (500+ requests):**
| Site | Requests | Redo % | Exception % | Combined |
|------|----------|--------|------------|----------|
| V23 | 855 | 0.0% | 0.2% | 0.2% |
| V14 | 2,432 | 0.1% | 0.0% | 0.2% |
| S62 | 1,286 | 0.1% | 0.1% | 0.2% |
| S17 | **25,969** | 0.4% | 0.1% | 0.4% |
| S0J | **11,776** | 0.4% | 0.2% | 0.6% |

**Key observation**: S32 has a 29.5% exception rate — nearly 1 in 3 requests hits an exception. Compare to V23 at 0.2%. The high-volume best performers (S17 at 26K requests, 0.4%) prove that low issue rates are achievable at scale. The worst sites may have workflow, staffing, or configuration issues worth investigating.

---

## Insight 15: The Cost of Inaction — 3,222 FTE-Equivalents in Queue Time Alone

Exception queues consume staggering time:

| Status | Annual Events | Median Wait | Annual Hours | FTEs |
|--------|--------------|-------------|-------------|------|
| Fulfillment Exception | 46.6K | **31.7h** | 3.3M | **1,601** |
| Logging Exception | 106.6K | 8.0h | 3.0M | **1,422** |
| Fulfillment On Hold | 8.4K | 15.7h | 376K | 181 |
| Logging On Hold | 14.1K | 0.0h | 40K | 19 |
| **Total** | | | **6.7M** | **3,222** |

Rework adds 427K requests/yr × 1.5h active touch = **148 FTEs** of rework touch time.
QC Verify: 5.8 FTEs reviewing 2.9M conflicts/yr, 92.9% are false positives.
**A 20% reduction in exception queue time alone = ~640 FTE-equivalents reclaimed.**

---

## Insight 16: Weekend Exceptions Wait 4.8× Longer

| Shift | 90d Events | Median | P75 | Annual FTEs |
|-------|-----------|--------|-----|-------------|
| Weekend | 7,632 | **56.7h** | 74.1h | 842 |
| Business Hours | 25,117 | 11.8h | 24.7h | 1,673 |
| Off-Hours | 7,476 | 10.6h | 33.7h | 509 |

Weekend exceptions sit **4.8× longer** than business hours. The excess vs business-hour median = **653K hours per quarter** from timing alone.

---

## Insight 17: Worst Sites = Data Quality Failures, Not Mix

All human-worked requests are 100% GOV major_class. The differentiator isn't request mix — it's **exception profile**.

| Reason | Worst 5 Sites | Best 5 Sites | Population |
|--------|--------------|-------------|------------|
| Required Requester ID: Missing | **33.3%** | 14.1% | 2.9% |
| Invalid/Incomplete Request | **25.0%** | 5.1% | 7.8% |
| Field Input Required | **22.6%** | 9.0% | 17.5% |
| Fulfillment Supervisor Review | 11.8% | **21.8%** | 8.4% |
| Clinic | 0.6% | 1.3% | 20.4% |

**81% of worst-site exceptions are preventable data quality errors.** Best sites' top reason is supervisor review (quality-oriented, not data quality). This is a pre-validation story: worst sites are submitting incomplete requests that don't get caught until they're in the workflow.

---

## Insight 18: Resubmission Categories — 45% Automatable

Full categorization of 157K resubmission comments (from `audit_message`):

| Category | % | Automatable? |
|----------|---|-------------|
| OTHER (uncategorized) | 28.0% | mixed |
| SITE_CHANGE | 14.7% | ✅ routing |
| COC/BOC | 10.2% | ⚠️ classification |
| SPLIT | 8.5% | ⚠️ workflow |
| PATIENT_ISSUE | 7.2% | ❌ manual |
| DAR_RELOG | 6.6% | ✅ process |
| SECOND_REVIEW | 4.1% | ❌ manual |
| BILLING | 3.7% | ⚠️ routing |
| EDIT/UPDATE | 3.5% | ✅ data correction |
| DATE_CORRECTION | 3.1% | ✅ data correction |
| MRN_CORRECTION | 2.7% | ✅ data correction |
| PULL_LIST | 2.6% | ✅ routing |
| NO_REASON | 2.0% | ? |
| REQUESTER_INFO | 1.5% | ✅ pre-validation |

Within the 28% "Other": numeric site codes, Epic integration triggers, STAT corrections, generic routing. ~45% of all resubmissions involve automatable operations.

---

## Insight 19: Verify FP Filter — A 200-Entry Lookup Table Could Cut 50-70%

What Verify flags as "patient name conflicts" falls into highly repetitive, filterable patterns:

**Medical terminology** (reason 7): "Graham Teasdale" (GCS inventor, 8.3K hits), "Von Willebrand" (2.6K), "Midas Rex" (surgical drill, 3.9K), "Candida Auris" (2.1K), "Hawkins Kennedy" (2.4K)

**Common first/last names** (reason 5): MICHAEL (15K), JAMES (14K), JOHN (13K), SMITH (9K) — OCR picks up names scattered through chart pages and flags them as "potential patient conflicts"

**Spanish form text**: "segunda nombre" (6.5K), "Dolor de garganta" (4.4K = "sore throat"), "favor de markar" (5K)

**OCR garbage**: "fain Soale" (8.3K), "grave, avise" (22K), "adel pecan" (6.3K), "zipper storage" (3.5K)

**Facility names**: "OVERLAND PARK" (5.6K), "OSCEOLA-TERRACE" (2.5K+), "KINGWOOD-CLEVELAND" (5.5K)

A lookup table of ~200 entries (50 medical terms + 100 common names + 30 Spanish phrases + 20 OCR artifacts) could filter **50-70% of the 670K/quarter false positives** = 340K-470K fewer human reviews.

**Conflict distribution per request:**
- 42% have 1 conflict, 0.2% have 100+ (max **4,046** per request)
- The 12K requests with 100+ conflicts are humanly unreviewable at any speed

---

## Insight 20: FTI Time Study Validates — Processors Are Fast, The System Is Slow ⭐

**Source**: FTI Consulting "Provider Business Optimization: Time Study Analysis" (Nov 2025). 14 consultants observed 190 processors across 560 sites, stopwatch-timing ~4,000 requests.

### The 7-Minute vs 4-Hour Gap

FTI measured **active touch time** (hands on keyboard). We measured **wall-clock elapsed time** (status transitions in Snowflake). Same requests, radically different numbers:

| Major Class | FTI Touch Time | Our Wall-Clock (median) | Ratio |
|---|---|---|---|
| CLIN | 5:15 | 2.4h | ~27x |
| GOV | 7:49 | 5.5h | ~42x |
| ATTY | 8:24 | 8.3h | ~59x |
| PAT | 9:24 | 3.0h | ~19x |
| **Average** | **6:52** | **~4h** | **~35x** |

**A request takes ~7 minutes of active work but ~4 hours of wall-clock time.** The 3h53m gap = queue time + idle time + context switching + system delays. This independently validates Insight 5 (65% queue time).

### FTI Findings That Align With Ours

| FTI Finding | Our Snowflake Data | Status |
|---|---|---|
| 18% non-submission rate | 13.3% rework + 11.1% exception ≈ 24% non-clean | Directionally aligned |
| 90% of processors update STORK fields | "missing" in 36-70% of exception comments | Same root cause |
| 62% of duplicate flags = false positive | 99.1% of QC Verify conflicts = FP | We're even worse |
| 68% of observers saw rerouting | SITE_CHANGE = 14.7% of resubmissions | Confirmed |
| 70% of requests handled by 2+ processors | avg 1.07 redos per rework request | Confirmed (Bomi's question) |
| 27% require manual STORK updates | STORK edit tracking = identified gap | Validated |
| Multiple EMRs = 2x lead time | EMR only 10% faster overall | We missed EMR-count nuance |

### FTI Findings We Can't Replicate (qualitative, observation-only)

- **Non-productive time**: walk-ins, phone calls, mail sorting (~1h/day onsite)
- **Onsite vs remote**: personal Wi-Fi slows EMR downloads
- **STORK accuracy**: 90% need correction (we know the gap, not the rate)
- **Physical overhead**: 900-page prints (40 min), FedEx trips, multi-floor offices
- **Work assignment dysfunction**: "assigned 15 requests, half already completed"
- **UX friction**: 40% waste time resetting search params between requests

### Our Findings FTI Can't See (systemic, data-at-scale)

- **Queue time decomposition**: 6.6h median in Back To Logging — invisible to stopwatch
- **Exception queue cost**: 3,222 FTE-equivalents — FTI doesn't quantify between-session waste
- **Site root cause**: worst = data quality errors (81%), not config/mix — FTI notes variance but doesn't diagnose
- **Scale**: 800K requests vs 3K (250x)
- **Verify FP patterns**: specific identifier_values at frequency level
- **Resubmission categorization**: 45% automatable
- **Weekend/temporal patterns**: 4.8x longer

### Directional Differences

1. **ATTY speed ranking**: FTI says FAC (9:31) and PAT (9:24) are slower than ATTY (8:24) in touch time. We show ATTY as clearly slowest in wall-clock. Why: ATTY's active work is fast-ish, but ATTY requests sit in exception queues far longer due to legal complexity.
2. **MAP factors were way too high**: Original MAP had ATTY at 40:00, FTI observed 8:24. Three scales exist: MAP (10-40 min) → FTI (4-10 min) → Snowflake wall-clock (2-8h). The telemetry proposal wants to re-measure something FTI already measured.
3. **QC effort**: FTI says QC = 30-60% of lead time and 11% not properly QC'd. Our QC In Progress median = 10 min. FTI includes manual QC steps (scrolling pages, cross-referencing) that don't surface in status transitions.

### The Narrative

> FTI proved processors are fast (~7 min per request). The telemetry proposal wants to re-measure that. But Snowflake shows those same requests take ~4 hours end-to-end. The 3h53m gap between "7 minutes of work" and "4 hours of lifecycle" is where the real money is — and it's a routing, queue management, and data quality problem, not an instrumentation problem.

**Data**: FTI report in `sources/FTI_Provider Business Optimization_ Time Study Analysis_vF.pdf`

---

## Open Questions (Remaining)

1. **Q21 unrun** — What changes during redo logging windows?
2. **Camunda task events** — Can we extract structured reasons from backToLogEvent?
3. **Delete conflict reasons** — Table exists but unexplored
4. **Dollar conversion** — Need $/FTE assumption to convert FTE-equivalents to budget impact
5. **EMR count impact** — FTI found multiple EMRs = 2x lead time. Can we segment by EMR count in Snowflake?
6. **FTI XLS** — User mentioned a companion spreadsheet; only PDF found

---

## Punchlist: Actionable Work Threads

### PL-1: Verify False Positive Reducer (Scrappy/Hacky) ⭐ DATA READY
**Insight**: 92.9% of Verify conflicts are false positives. Can't tune WiredQC directly (vendor-owned).
**Approach**: Post-analysis override layer using a **200-entry lookup table**:
1. ~50 known medical terms/eponyms: "Graham Teasdale" (8.3K hits), "Von Willebrand" (2.6K), "Midas Rex" (3.9K), "Candida Auris" (2.1K)
2. ~100 common first/last names (Census top-100): MICHAEL (15K), JAMES (14K), JOHN (13K), SMITH (9K)
3. ~30 Spanish medical form phrases: "segunda nombre" (6.5K), "Dolor de garganta" (4.4K), "favor de markar" (5K)
4. ~20 high-frequency OCR artifacts: "grave, avise" (22K), "fain Soale" (8.3K), "adel pecan" (6.3K)
5. Facility name list from site config: "OVERLAND PARK" (5.6K), "OSCEOLA-TERRACE" (2.5K+)
**Impact**: 50-70% of 670K/quarter false positives filtered → **340K-470K fewer reviews**. Plus: 12K requests with 100+ conflicts (max 4,046) could get bulk auto-resolution.
**Effort**: Small. Lookup table + Camunda delegate or post-QC filter. No WiredQC changes.
**Data**: Q49b, Q50, Q51, Q53 — all identifier_value patterns analyzed.

### PL-2: Pre-Validation Gate
**Insight**: 36% of Field Input Required and 70% of Invalid/Incomplete exceptions mention "missing" — address, patient name, pages.
**Approach**: Validation rules at intake submission:
- Requester address populated? (covers ~12K+ exceptions/quarter)
- Patient name present? (covers ~5K+)
- Request letter/pages attached? (covers blank page issues)
**Impact**: Prevents exceptions from being created → eliminates the 6.9h median queue time for each.
**Effort**: Medium. Frontend validation + backend guard in intake services.
**Synergy**: Aligns with PDCR-406 Intake Acceleration goals.

### PL-3: Auto-Route for Known Rework Patterns
**Insight**: 35% of resubmissions are data corrections (MRN add, site move, DAR relog).
**Approach**:
- MRN missing at fulfillment? Auto-trigger patient lookup retry instead of resubmitting to logging queue.
- Site needs to move? Auto-route via site mapping rules, no human re-logging.
- DAR relog needed? Auto-flag and reroute without queue wait.
**Impact**: Each avoided resubmission saves ~10h of queue time. At 55K/quarter = 550K queue-hours saved.
**Effort**: Medium-high. Requires Camunda workflow modification + routing rules.

### PL-4: Resubmission Comment Standardization
**Insight**: Comments are freetext but highly repetitive. Same meaning expressed 20+ ways ("adding mrn", "ADD MRN", "mrn not assigned", etc.)
**Approach**: Replace freetext with structured dropdown + optional notes:
- Category picklist: MRN, Site, CoC, Split, DAR, Billing, Review, Other
- Required field: "What needs to change?"
**Impact**: Makes all resubmissions machine-parseable for PL-3. Also enables dashboards.
**Effort**: Low. UI change to resubmission form.

### PL-5: Chart Image Rejection — RESOLVED (Not Our Problem)
**Insight**: 377K/month `RequestRejectedInCf` events — investigated in Q27/Q28.
**Finding**: 99.99% are ELECTRONIC INTAKE + PAYD (automated audit pipeline). Not human-worked requests. It's a ChartFast image-to-patient matching issue in the batch process. Each request rejected exactly once. Pipeline: QC → Match In Progress → rejected → "Patient Not Found" → Delivered to CF.
**Status**: CLOSED for human-worked TAT analysis. Separate operational concern if PAYD team wants to optimize match rates.

### PL-6: Weekend/Afternoon Exception Triage
**Insight**: Exceptions created after 2pm sit 10.9h median (vs 3.7h morning). Weekend P75 = 64.7h.
**Approach**:
- Afternoon exception priority bump — auto-escalate if not picked up within 2h of creation
- Weekend on-call exception resolver — even 1 person clearing exceptions Saturday could cut weekend P75 by 50%+
- End-of-week exception sprint — clear exception queue before Friday 3pm to prevent weekend bleed
**Impact**: 5,120 afternoon exceptions × 7h saved = 35K hours/quarter. Weekend: 3,926 × 30h saved = 118K hours/quarter.
**Effort**: Low (process change) to Medium (alerting infrastructure).

### PL-7: Site-Level Intervention for Outliers ⭐ ROOT CAUSE IDENTIFIED
**Insight**: Worst sites' exception profile is dominated by preventable data quality errors (81%), not operational issues.
**Root cause** (Q36-Q39):
- S32 (30% issue rate): 33% Req ID Missing, 25% Invalid/Incomplete, 23% Field Input — all upstream data problems
- Best sites (V23/S17): top reason is Fulfillment Supervisor Review (quality-oriented, not data quality)
- NOT a mix issue (100% GOV across all sites), NOT an EMR issue (worst sites only slightly less EMR)
**Approach**:
- Dashboard per-site exception reason breakdown (Phase 0) — show sites their own data
- Pre-validation gate targeting worst-site patterns: requester ID check, completeness check
- Site-specific training for S32/V56/S09/S66 on request submission quality
**Impact**: Moving worst 5 sites to fleet median = ~2K fewer exceptions/quarter. Pre-validation gate benefits ALL sites.
**Effort**: Low for dashboards, Medium for pre-validation, Low for training.

### PL-8: Exception Queue Time Optimizer
**Insight**: Exceptions sit 6.9h in Logging Exception and 20.1h in Fulfillment Exception before pickup.
**Approach**: Priority queue for exception resolution. When an exception is created:
- High-priority if "Field Input Required" (highest TAT impact)
- Auto-assign to exception specialists rather than general queue
- SLA alert if exception age > 4h
**Impact**: Cutting exception queue time by 50% saves ~3.5h per exception. At 385K exceptions/quarter = 1.3M hours saved.
**Effort**: Medium. Queue priority rules + alerting.

---

## Recommendations

### Phase 0: Dashboards (Now, 1-2 weeks)
Build on existing data, zero instrumentation:
- Logging TAT by channel × major class
- Rework rates (human-worked only)
- Exception reason breakdown with TAT impact
- Queue time vs active time decomposition
- Patient lookup NotFound rates
- Resubmission reason categorization dashboard
- QC Verify false positive rate tracking

### Phase 1: Quick Wins (2-4 weeks)
No new telemetry needed — fix known issues:
- **Pre-validation**: Check requester address + patient name before entering workflow (addresses 36-70% of Field Input Required / Invalid Incomplete exceptions)
- **Verify tuning**: Filter doctor/nurse names, medical terminology from patient name matching (reduces 69% of false positives)
- **Auto-routing**: DAR relog, site moves, pull list routing (addresses ~24% of resubmissions)

### Phase 2: Targeted Gaps (2-3 weeks)
6-8 net-new events for actual gaps:
- Which fields trigger "Field Input Required" exceptions (specific field IDs, not just comments)
- STORK edit tracking (what ADE got wrong that humans fix)
- Processor active/idle time (tab focus)
- Chart image rejection root causes (377K/month)

### Phase 3: Infrastructure (If Earned)
Build pipeline only when Phase 0-2 prove value.
