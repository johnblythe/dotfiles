# Query Index

All queries run against `HEALTHSOURCE.CONNEX` via SnowSQL. 90-day window unless noted.

## Phase 1: Core TAT Analysis (q1-q11)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q1 | q1_logging_tat.sql | Logging TAT by channel × major_class | Bimodal: auto <1s vs human 20-150min |
| Q2 | q2_fulfill_tat.sql | Fulfillment TAT by channel × EMR | EMR only 10% faster |
| Q3 | q3_e2e.sql | End-to-end cycle time | — |
| Q4 | q4_audit_trail_logging.sql | Audit events during logging windows | 422 event types exist |
| Q5 | q5_rework.sql | Rework rates (all) | Blended: 3.2% |
| Q5b | q5b_rework_human_only.sql | Rework rates (human-worked) | **13.3%** — 4x higher |
| Q6 | q6_holds.sql | Hold/exception durations | — |
| Q7 | q7_human_logging.sql | Human logging time distribution | — |
| Q8 | q8_patient_lookup_coverage.sql | Patient lookup by channel | 11-26% coverage |
| Q9 | q9_patient_lookup_timing.sql | Lookup timing + failure rates | 22% NotFound on UPLOAD |
| Q10 | q10_all_audit_types.sql | Full audit type inventory | 422 distinct types |
| Q11 | q11_logging_tat_detailed.sql | Logging TAT with distribution buckets | — |

## Phase 2: Fulfillment & Exceptions (q12-q15)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q12 | q12_fulfill_detailed.sql | Fulfillment TAT by source×class×EMR | — |
| Q13 | q13_exception_reasons.sql | ❌ FAILED: wrong column name | Use Q13c instead |
| Q13b | q13b_exception_reasons_fixed.sql | Schema discovery for lookup tables | Found erequest_exception_reason |
| Q13c | q13c_exception_by_id.sql | Exception breakdown by reason_id | Top: Clinic 20.4%, Field Input 17.5% |
| Q13d | q13d_reason_lookup.sql | Reason ID→description mapping | 48 reason codes, 3 categories |
| Q14 | q14_exception_categories.sql | erequest_exception schema discovery | — |
| Q15 | q15_exception_tat_impact.sql | ❌ FAILED: wrong column | Use Q15b |
| Q15b | q15b_exception_tat_impact.sql | TAT impact by exception reason | Field Input = +176% TAT |

## Phase 3: Touch Time vs Wait Time (q16-q18)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q16 | q16_touch_vs_wait.sql | Per-status duration breakdown | Back To Logging = 6.6h queue |
| Q17 | q17_rework_journey_decomp.sql | Rework wall clock vs active time | ~65% is queue time |
| Q18 | q18_clean_vs_rework_decomp.sql | Clean vs redo vs exception vs sent-back | Redo: 1.5h work, 11.9h total |

## Phase 4: Rework Root Causes & QC (q19-q25)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q19 | q19_qc_redo_triggers.sql | Events before redo transitions | CamundaTaskEvent = backToLogEvent |
| Q20 | q20_exception_comment_patterns.sql | Exception comment keyword analysis | "missing" = 36-70% of top reasons |
| Q21 | q21_redo_what_changed.sql | Events during redo logging | (not yet run) |
| Q22 | q22_qc_event_types.sql | QC-related audit event types | QCInProgressStarted=3.8M, NewQCResults=85K |
| Q23 | q23_field_input_comments.sql | Field Input Required comment samples | "Requester address missing" = top |
| Q24 | q24_invalid_incomplete_comments.sql | Invalid/Incomplete comment samples | "address/patient info missing" |
| Q25 | q25_verify_potential_issues.sql | Verify system event details | event_comments empty; detail in QC tables |

## Phase 5: Deep Dives — Outliers & Temporal (q26-q31)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q26 | q26_site_outliers.sql | Site-level outlier analysis (original) | (superseded by Q30/Q31) |
| Q27 | q27_chart_rejection_deep.sql | Chart rejection by source×class | 99.99% = ELECTRONIC+PAYD |
| Q28 | q28_chart_rejection_events.sql | Events around chart rejections | Match In Progress → Patient Not Found |
| Q29 | q29_temporal_patterns.sql | Hour×DOW exception durations | Sat P75=64.7h, afternoon=10.9h median |
| Q30 | q30_site_best_worst.sql | Worst sites by issue rate | S32=30%, V56=19% |
| Q31 | q31_site_best.sql | Best sites by issue rate | V23=0.2%, S17=0.4% on 26K vol |

## Phase 6: Cost Quantification (q32-q35)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q32 | q32_rework_cost.sql | Rework volume + annualized | 107K/90d → 427K/yr, max 20 redos |
| Q33 | q33_exception_queue_cost.sql | Exception queue hours → FTEs | **3,222 FTEs** annual in exception queues |
| Q34 | q34_verify_fp_cost.sql | QC Verify FP review cost | 721K conflicts/90d, 92.9% ignored, 5.8 FTEs |
| Q35 | q35_weekend_gap.sql | Weekend/off-hours queue gap | Weekend 56.7h median (4.8× biz hours) |

## Phase 7: Site Root Cause & Best Practices (q36-q39)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q36 | q36_worst_site_profile.sql | Worst sites major_class mix | 100% GOV — not the differentiator |
| Q37 | q37_worst_site_source_emr.sql | Worst sites source+EMR | Slightly more UPLOAD/non-EMR, not extreme |
| Q37b | q37b_pop_source_emr.sql | Population source+EMR baseline | 54% UPLOAD/non-EMR, 23% EMR |
| Q38 | q38_worst_site_exceptions.sql | Worst 5 exception reasons vs pop | **SMOKING GUN**: 81% data quality errors |
| Q39 | q39_best_site_exceptions.sql | Best 5 exception reasons | Top = Supervisor Review (operational) |

## Phase 8: Resubmission Deep Dive (q41-q41e)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q41 | q41_other_resubmission_comments.sql | ❌ Empty — event_comments blank | Comments in audit_message instead |
| Q41b | q41b_resubmission_comment_coverage.sql | Category coverage check | 100% NO_COMMENT in event_comments |
| Q41c | q41c_resub_audit_message.sql | audit_message top 30 | Rich freetext in audit_message |
| Q41d | q41d_resub_categories_full.sql | Full categorization from audit_message | 72% categorized, 28% "Other" |
| Q41e | q41e_other_samples.sql | Sample remaining "Other" | Site codes, Epic, STAT corrections |

## Phase 9: Verify Identifier Patterns (q49-q53)
| Query | File | Purpose | Key Finding |
|-------|------|---------|-------------|
| Q49b | q49b_verify_fp_samples_simple.sql | Medical terminology FP samples | Medical terms, facility names, OCR garbage |
| Q50 | q50_verify_valid_name_samples.sql | Valid Name/DOB FP samples | Common names, Spanish text, OCR artifacts |
| Q51 | q51_conflict_length_distribution.sql | Identifier length vs ignore rate | 87-93% ignore at all lengths; not discriminating |
| Q53 | q53_conflicts_per_request.sql | Conflicts per request distribution | 42% have 1, 0.2% have 100+ (max 4,046) |

## Schema Notes

### Key column name gotchas
- `erequest_audit_trail_dynamic`: timestamp is `EVENT_DT` (not audit_timestamp), description is `AUDIT_MESSAGE` (not audit_description)
- `erequest_exception`: uses `EXCEPTION_REASON_ID` (FK, not text), join to `erequest_exception_reason` on `EREQUEST_EXCEPTION_REASON_ID`
- `erequest_dynamic`: site column is `DDS_SITE_ID` (not site_id)
- Shell: `!=` fails in inline snowsql queries (shell parsing). Use files for queries with `!=`.

### QC Tables (discovered in Phase 4)
- `EREQUEST_QC_CONFLICTS` — structured conflict data (IDENTIFIER, IDENTIFIER_VALUE, PAGES)
- `EREQUEST_QCREALTIME_CONFLICTS` — realtime conflicts (QC_CONFLICT_PAGE_NO, VERIFY_UNAVAILABLE)
- `EREQUEST_QC_ACTION` — reviewer actions (IGNORED, DELETED, IGNORED_REASON_ID, COMMENTS)
- `IGNORE_CONFLICT_REASONS` — 7 reason codes (Valid Name/DOB/DOS, Medical terminology, etc.)
- `DELETE_CONFLICT_PAGE_REASONS` — deletion reasons (not explored)
