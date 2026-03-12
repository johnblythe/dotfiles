# Exploration Rabbithole

Living doc. Tracks threads, status, and how they connect to the metanarrative.

## Metanarrative (evolving)
> **The headline**: FTI's time study (Nov 2025) proved processors are fast — ~7 minutes of active work per request. Our Snowflake analysis shows those same requests take ~4 hours end-to-end. The **35x gap** between touch time and wall-clock time is queue waste, system delays, and rework loops. The telemetry proposal wants to re-measure how fast processors are. That's the wrong question.
>
> **The data story**: HealthSource's Snowflake already captures ~60% of proposed telemetry. 422 audit event types. 127M state-change events in 90 days. The real operational wins aren't more instrumentation — they're **acting on data we already have**.
>
> **The cost story**: Exception queues alone burn 3,222 FTE-equivalents annually. Rework adds 148 FTEs of active touch time. Weekend timing gaps waste 653K excess hours per quarter. These aren't hypothetical — they're measurable today.
>
> **The root cause story**: Worst sites are drowning in preventable data quality errors (missing requester IDs, incomplete requests). Best sites barely have these. It's not mix — it's upstream data hygiene. A pre-validation gate at intake could close this gap. FTI independently confirmed: 90% of processors need to fix STORK, 18% of requests can't be submitted, 68% of sessions involve rerouting.
>
> **The quick win story**: QC Verify's false positives are hilariously filterable — medical terms like "Von Willebrand", facility names like "OVERLAND PARK", common first names like "MICHAEL", and Spanish form text like "Dolor de garganta". A lookup table of ~200 known false positive strings could cut 50%+ of the 670K/quarter ignored conflicts.

---

## Thread 1: Cost Quantification
**Status**: 🟢 Complete
**Question**: What do queue hours, rework, and false positives cost in FTEs/dollars?
**Why it matters**: Makes every punchlist item budget-justifiable. Turns "interesting" into "urgent."
**Queries**:
- [x] Q32: Rework volume → 107K/90d, **427K annualized**, 1.07 avg redos, max 20
- [x] Q33: Exception queue hours → **3,222 FTEs** annual in exception wait time
- [x] Q34: QC Verify FP cost → 721K conflicts/90d, 92.9% ignored, 5.8 FTEs review, 814 max conflicts/request
- [x] Q35: Weekend gap → Weekend median 56.7h (4.8× biz hours), 842 FTEs annual
**Connects to**: PL-1, PL-2, PL-6, PL-8
**Findings**:
- Exception queues: **3,222 FTE-equivalents** annual (Fulfillment Exception = 1,601, Logging Exception = 1,422)
- Rework: 427K requests/yr × 1.5h active = **148 FTEs** touch time, plus 10.4h queue per rework
- QC Verify: 5.8 FTEs reviewing 2.9M conflicts/yr, 92.9% false positive. Pure waste.
- Weekend: 56.7h median vs 11.8h biz hours (4.8×). **653K excess hours/90d** from timing alone.
- **20% exception queue reduction = ~640 FTE-equivalents reclaimed**

---

## Thread 2: Site Root Cause (S32/V56)
**Status**: 🟢 Complete (merged with Thread 4)
**Question**: What makes the worst sites 10x worse? Mix? Config? EMR? Staffing?
**Why it matters**: If it's mix, it's expected. If it's process, it's fixable.
**Queries**:
- [x] Q36: Major class mix → **100% GOV** across all sites. Not the differentiator.
- [x] Q37/Q37b: Source+EMR → Worst sites have more UPLOAD/non-EMR but not dramatically different
- [x] Q38: Exception reasons (worst 5 vs pop) → **SMOKING GUN**
- [x] Q39: Exception reasons (best 5) → Confirms the pattern
**Connects to**: PL-2 (pre-validation), PL-7 (site intervention), Insight 14
**Findings**:
- **Major class is NOT the differentiator** — 100% GOV for human-worked requests
- **Exception profile IS the differentiator:**

| Reason | Worst 5 | Best 5 | Population |
|--------|---------|--------|------------|
| Req ID Missing | **33.3%** | 14.1% | 2.9% |
| Invalid/Incomplete | **25.0%** | 5.1% | 7.8% |
| Field Input Required | **22.6%** | 9.0% | 17.5% |
| Fulfillment Supervisor Review | 11.8% | **21.8%** | 8.4% |
| Clinic | 0.6% | 1.3% | 20.4% |

- Worst sites: dominated by **preventable data quality errors** (81% of exceptions)
- Best sites: top reason is supervisor review (operational, not data quality)
- EMR: worst sites slightly less EMR but not extreme (S32: 24% EMR, V56: 10% EMR, pop: 23%)
- **Conclusion: it's upstream data hygiene, not mix/config**

---

## Thread 3: Unclassified Resubmissions
**Status**: 🟢 Complete
**Question**: What's hiding in the "Other" bucket?
**Why it matters**: New automatable categories or unknown failure modes.
**Queries**:
- [x] Q41b: Category coverage → event_comments 100% empty; comments live in audit_message
- [x] Q41c: audit_message top 30 → rich freetext resubmission reasons
- [x] Q41d: Full categorization → 72% categorized, 28% "Other"
- [x] Q41e: Other samples → several new categories found
**Connects to**: PL-3, PL-4, Insight 8
**Findings**:
- Resubmission comments are in `audit_message` (format: "Fulfillment request resubmitted to logging. Comment : {text}")
- Full category breakdown:

| Category | % | Automatable? |
|----------|---|-------------|
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
| OTHER | 28.0% | mixed |

- **New categories found in "Other":**
  1. **Numeric site codes** (570× "90509", 505× "26832") — site routing IDs
  2. **Epic integration** ("epic id", "epic release") — EMR workflow triggers
  3. **STAT corrections** ("not a stat", "remove stat") — priority mislabeling
  4. **Routing** ("moved", "needs roi", "PT FOUND")
  5. **Generic/meaningless** ("NA", "please log", "ok to do")
- ~45% of all resubmissions are **automatable** (data corrections + routing + process)

---

## Thread 4: Best-Site Practices (V23/S17)
**Status**: 🟢 Complete (merged into Thread 2 findings)
See Thread 2 for side-by-side comparison. Key insight: best sites' top exception reason is Fulfillment Supervisor Review (operational, quality-control oriented) not data quality errors.

---

## Thread 5: Verify Identifier Patterns (PL-1 Data)
**Status**: 🟢 Complete
**Question**: What do false positive conflicts actually look like? Can we build heuristic filters?
**Why it matters**: 99.1% FP rate. A filter saves massive reviewer time.
**Queries**:
- [x] Q49b: Medical terminology FP samples → medical terms, facility names, OCR garbage
- [x] Q50: Valid Name/DOB FP samples → common first names, Spanish form text, OCR artifacts
- [x] Q51: Length distribution → 87-93% ignore rate at all lengths; length not discriminating
- [x] Q53: Conflicts per request → 42% have 1, 0.2% have 100+ (max 4,046!)
**Connects to**: PL-1 (Verify FP reducer), Insight 9
**Findings**:

### Medical Terminology FPs (reason 7) — highly filterable
Top hits (thousands of occurrences each):
- **Medical terms as names**: "Graham Teasdale" (GCS), "Von Willebrand", "Hawkins Kennedy", "Holliday-Segar", "Ortolani and Barlow", "Candida Auris", "Midas Rex" (drill)
- **Facility/location names**: "OVERLAND PARK", "KINGWOOD-CLEVELAND", "OSCEOLA-TERRACE", "BLAKE-PALMETTO"
- **OCR garbage**: "fain Soale", "prefer tobe", "zipper storage", "bottles, needles"

### Valid Patient Name/DOB FPs (reason 5) — also filterable
- **Common first/last names**: MICHAEL (15K), JAMES (14K), JOHN (13K), SMITH (9K)
- **Spanish form text**: "segunda nombre", "Dolor de garganta", "favor de markar"
- **Same OCR artifacts**: "grave, avise" (22K!), "adel pecan", "wader penal"

### Filter strategy
A lookup table approach:
1. ~50 known medical terms/eponyms → filter medical terminology FPs
2. ~100 common first/last names (Census top-100 list) → filter name FPs
3. ~30 Spanish medical form phrases → filter bilingual chart FPs
4. ~50 known OCR artifacts (high-frequency garbage strings) → filter OCR noise
5. Facility name list (from site config) → filter location FPs

**Estimated impact**: 200-entry lookup table could filter **50-70% of false positives** = ~340K-470K fewer reviews per quarter

### Conflict distribution
- 42% of requests have just 1 conflict (quick to review)
- 0.2% have 100+ conflicts (12K requests, avg 187, max **4,046** — humanly unreviewable)
- **Length is not a discriminator** — ignore rate 87-93% at all string lengths

---

## Thread 6: FTI Time Study Cross-Reference
**Status**: 🟢 Complete
**Question**: How does FTI's manual time study compare to our Snowflake analysis?
**Why it matters**: FTI is an external, credible baseline. Alignment = validation. Divergence = new insight.
**Source**: `sources/FTI_Provider Business Optimization_ Time Study Analysis_vF.pdf` (Nov 2025, 20 pages)
**Connects to**: Insight 5 (queue time), Insight 20, all Punchlist items
**Findings**:
- FTI measured **touch time** (stopwatch), we measured **wall-clock** (status transitions)
- ~7 min active work vs ~4h elapsed = **35x gap** = queue/idle/system waste
- FTI confirms: 90% STORK needs fixes, 62% duplicate FPs, 68% rerouting, 70% multi-processor
- FTI can't see: queue time between sessions, exception queue cost, site root cause, scale (3K vs 800K)
- Key divergence: ATTY is fastest-ish in touch time but slowest in wall-clock (long exception queues)
- **Narrative**: "FTI proved processors are fast. The system around them is slow."

---

## Thread 7: Bonus Rabbitholes (emerged during exploration)
- [ ] Q21 still unrun — what changes during redo logging?
- [ ] Camunda task event structure — can we extract structured reasons from backToLogEvent?
- [ ] ChartFast pipeline errors — is the 377K/mo rejection rate normal or a bug?
- [ ] Delete conflict reasons (table exists, never explored)
- [ ] EMR count segmentation — FTI says multiple EMRs = 2x. Can we validate at scale?
- [x] ~~Unclassified resubmissions~~ → resolved in Thread 3

---

## Narrative Weave Map

```
Thread 6 (FTI) ───────────────────── "Processors are fast (7 min)"
    │                                  FTI stopwatch: 5-10 min active work
    │                                  Our wall-clock: 2-8 hours elapsed
    │                                  35x gap = queue + idle + system
    │
Thread 1 (Cost) ──────────────────── "The system around them is slow"
    │                                  3,222 FTE-equivalents in exception queues
    │                                  148 FTEs rework touch time
    │                                  653K excess hours/90d from timing
    │
Thread 2 (Worst Sites) ──┐
    │                     ├────────── "Here's where it hurts most"
Thread 4 (Best Sites) ───┘            Worst sites: 81% data quality exceptions
    │                                 Best sites: top reason = supervisor review
    │                                 It's NOT mix — it's upstream hygiene
    │
Thread 3 (Other Bucket) ─┐
    │                     ├────────── "Here's what causes it"
Thread 5 (Verify FPs) ───┘            45% of resubmissions automatable
    │                                 FPs = medical terms + common names + OCR garbage
    │                                 200-entry lookup → 50-70% FP reduction
    │
    └──────────────────────────────── "Here's how to fix it"
                                     Phase 1: Pre-validation gate (sites)
                                     Phase 2: FP filter (Verify)
                                     Phase 3: Auto-route resubmissions
                                     Phase 4: Weekend coverage model
```

## Stakeholder Comments Analysis (from taxonomy doc)
Key voices and what they care about:
- **Natalie Del Rossi**: Deep in audit trail, has Lucidchart, found out-of-order events. Ally.
- **Emily Denenberg**: Wants visual workflow, wait time between steps. **We answer her question directly.**
- **Bomi Kim**: Rework frequency + duration, multi-user attribution. **We have her data.**
- **Jenny Wang**: "Broadly instrument then dig into wildly high buckets." **Our exact approach.**
- **Paul McCready**: processor_id → Oracle mapping, end-to-end lifecycle. Systems thinker.
- **Savanah Bennett**: Employee tracking at every step.
- **John Cusimano**: Edge cases, non-happy-path gaps.
- **Jim Bartolotta**: Channel mapping, service worker distinction.

## Running Query Counter
- Queries run: q1–q53 (with gaps: q40, q42-48, q52 not needed/deferred)
- Active queries: q32–q39, q41b–q41e, q49b, q50, q51, q53
- External data: FTI Time Study (Nov 2025, n=3,005)
- Next available: q54
