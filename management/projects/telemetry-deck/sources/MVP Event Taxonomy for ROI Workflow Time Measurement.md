# **MVP Event Taxonomy for ROI Workflow Time Measurement**

## **Executive Summary**

This MVP event taxonomy defines **24 critical instrumentation points** across the 6 major stages of the ROI workflow. These events are designed for rapid implementation (≤4 weeks) in HealthSource to begin capturing time-on-task data while minimizing development effort and processor disruption.

### **Baseline Context (From 2025 Time Study)**

* **Requests Measured**: 3,961 across 107 health systems, 558 sites  
* **Current 3-Phase Measurement**: Intake/Logging (\~120s), Fulfillment (\~180s), QC+Delivery (\~120s)  
* **Total Median Time**: 500 seconds (8.3 minutes)  
* **Key Finding**: High variance (3-10x) across EMR systems, delivery methods, and request types

### **MVP Design Principles**

1. **System-Captured Events First**: Prioritize automatic timestamp capture over manual tracking  
2. **Critical Path Focus**: Instrument workflow gates and high-variance activities  
3. **Minimal User Friction**: No manual timers; leverage existing user actions  
4. **Stratification Ready**: Capture context for segmentation analysis  
5. **Actionable Insights**: Focus on efficiency opportunities identified in prior study

---

## **Parking Lot for Questions**

- [ ] Include request intake processing as stage and ensure measurement for workflows upstream of healthsource  
- [ ] What is role of audit log vs. event log in the long run?  
- [ ] Employee mapping \- how do we connect HS users to DV people reliably?  
- Employees do not have unique DV ID associated in Healthsource. Sailpoint does not solve this. 

---

## **Stage 1: INTAKE (Request Receipt → Ready for Processing)**

**Current Baseline**: Median \~120 seconds | High variance by intake channel and authorization complexity

### **Events to Instrument**

#### **1.0 Request Received**

#### 

#### **1.1 Request Processing Complete**

* **Event Name**: `roi.intake.request_received`  
* **Trigger**: Request first appears in HealthSource system  
* **Timestamp Capture**: System-generated (automatic)  
* **Context Attributes**:  
* `request_id` (eRID)  
* `intake_channel` (electronic, upload, manual\_entry, fax, mail)  
* `request_type` (authorization, subpoena, court\_order, standard)  
  * Requestor Type  
  * Major Class  
  * Primary Reason  
  * Secondary Reason  
* `major_class` (ATTY, CLIN, INS, COPY, PAT, PAYD, etc.)  
* `health_system_id`  
* `emr_system` (Epic, Cerner, Meditech, Allscripts, etc.)  
* `record_type` (medical\_record, correspondence\_letter, billing)

#### **1.2 Request Opened for Review**

* **Event Name**: `roi.intake.request_opened`  
* **Trigger**: Processor clicks to open/view request in HealthSource  
* **Timestamp Capture**: System-generated (click event)  
* **Context Attributes**:  
* `processor_id`  
* `processor_location` (remote, onsite)  
* `processor_tenure_category` (\<1yr, 1-3yr, 3-5yr, 5-10yr, 10+yr)  
* `time_since_received` (calculated: opened\_ts \- received\_ts)

#### **1.3 Intake Data Entry Completed**

* **Event Name**: `roi.intake.data_entry_completed`  
* **Trigger**: Processor completes/saves intake form in HealthSource  
* **Timestamp Capture**: System-generated (form submit/save action)  
* **Context Attributes**:  
* `logging_method` (manual, stork\_assisted, fully\_automated)  
* `stork_edit_required` (true/false) \- if STORK pre-populated fields  
* `fields_edited_count` (number of fields processor corrected)  
* `intake_source_validated` (true/false)

---

## **Stage 2: DATA CAPTURE / LOGGING (Patient & Request Details Entry)**

**Current Baseline**: Implicitly captured within Intake time (\~30-60 seconds estimated)  
**Priority**: HIGH \- STORK automation impact measurement

### **Events to Instrument**

#### **2.1 Patient Lookup Initiated**

* **Event Name**: `roi.logging.patient_lookup_initiated`  
* **Trigger**: Processor opens patient search in HealthSource or EMR  
* **Timestamp Capture**: System-generated (search screen opened)  
* **Context Attributes**:  
* `lookup_system` (healthsource, emr, both)  
* `search_method` (name\_dob, mrn, advanced)

#### **2.2 Patient Matched**

* **Event Name**: `roi.logging.patient_matched`  
* **Trigger**: Processor selects matching patient from search results  
* **Timestamp Capture**: System-generated (patient record selected)  
* **Context Attributes**:  
* `search_result_count` (number of results returned)  
* `match_confidence` (exact, partial, manual\_verification\_required)  
* `time_to_match` (calculated: matched\_ts \- lookup\_initiated\_ts)  
* `duplicate_patient_flagged` (true/false)

#### **2.3 Request Logging Completed**

* **Event Name**: `roi.logging.completed`  
* **Trigger**: All required fields populated and saved in HealthSource  
* **Timestamp Capture**: System-generated (logging form submitted)  
* **Context Attributes**:  
* `total_fields_completed`  
* `required_fields_auto_populated` (count from STORK or other automation)  
* `manual_entry_fields` (count requiring processor input)  
* `logging_time` (calculated: completed\_ts \- request\_opened\_ts)

---

## **Stage 3: AUTH REVIEW (Authorization Validation & Compliance Check)**

**Current Baseline**: Implicitly captured within Intake time (\~30-90 seconds estimated)  
**Priority**: HIGH \- Digital Authorization Review (DAR) optimization opportunity

### **Events to Instrument**

#### **3.1 Authorization Review Started**

* **Event Name**: `roi.auth_review.started`  
* **Trigger**: Processor begins authorization validation workflow  
* **Timestamp Capture**: System-generated (auth review screen opened or checklist initiated)  
* **Context Attributes**:  
* `authorization_type` (signed\_auth, subpoena, court\_order, dar\_eligible)  
* `review_method` (manual, dar\_assisted, fully\_automated)  
* `authorization_complexity` (simple, standard, complex) \- based on scope/elements

#### **3.2 HIPAA Elements Validated**

* **Event Name**: `roi.auth_review.hipaa_validated`  
* **Trigger**: Processor completes HIPAA element checklist (7+3 elements)  
* **Timestamp Capture**: System-generated (validation checklist submitted)  
* **Context Attributes**:  
* `validation_method` (manual\_review, dar\_system\_check)  
* `elements_missing_count` (0 \= all present)  
* `signature_present` (true/false)  
* `date_valid` (true/false)  
* `scope_defined` (true/false)

#### **3.3 Authorization Review Completed**

* **Event Name**: `roi.auth_review.completed`  
* **Trigger**: Processor finalizes authorization decision  
* **Timestamp Capture**: System-generated (decision saved: approved/denied/clarification\_needed)  
* **Context Attributes**:  
* `authorization_status` (approved, denied, needs\_clarification, escalated)  
* `review_time` (calculated: completed\_ts \- started\_ts)  
* `requester_contact_required` (true/false)  
* `denial_reason` (if denied)

---

## **Stage 4: RECORD RETRIEVAL (Locate & Gather Medical Records)**

**Current Baseline**: Median \~180 seconds (core of Fulfillment phase)  
**Priority**: CRITICAL \- Highest variance (3-8x) by EMR system, page count, and location type

### **Events to Instrument**

#### **4.1 EMR Access Initiated**

* **Event Name**: `roi.retrieval.emr_access_initiated`  
* **Trigger**: Processor opens patient record in EMR system  
* **Timestamp Capture**: System-generated (EMR patient chart opened) \- may require EMR integration or user action logging  
* **Context Attributes**:  
* `emr_system` (Epic, Cerner, Meditech, Allscripts, NextGen, Athena, other)  
* `access_method` (direct\_login, sso, healthsource\_integration)  
* `emr_response_time` (system latency if measurable)

#### **4.2 Record Location Identified**

* **Event Name**: `roi.retrieval.record_located`  
* **Trigger**: Processor identifies where requested records are stored  
* **Timestamp Capture**: Manual flag or system-generated (processor indicates location found)  
* **Context Attributes**:  
* `record_location_type` (emr\_digital, physical\_onsite, physical\_offsite, archive)  
* `records_availability` (immediately\_available, archive\_request\_needed, not\_found)  
* `multiple_locations` (true/false)

#### **4.3 Record Retrieval Started**

* **Event Name**: `roi.retrieval.started`  
* **Trigger**: Processor begins downloading/pulling/scanning records  
* **Timestamp Capture**: System-generated (first download initiated, scanning started, or manual flag)  
* **Context Attributes**:  
* `retrieval_method` (emr\_download, paper\_scan, bulk\_export, archive\_pull)  
* `estimated_page_count` (processor estimate or initial count)

#### **4.4 Record Retrieval Completed**

* **Event Name**: `roi.retrieval.completed`  
* **Trigger**: All records captured and ready for scope review  
* **Timestamp Capture**: System-generated (processor marks retrieval complete or uploads final batch)  
* **Context Attributes**:  
* `actual_page_count` (final count)  
* `page_count_bucket` (0-49, 50-99, 100-149, 150-249, 250-649, 650+)  
* `retrieval_time` (calculated: completed\_ts \- started\_ts)  
* `scan_quality_issues` (true/false)  
* `duplicate_pages_removed` (count)  
* `sensitive_content_flagged` (true/false) \- for redaction needs

---

## **Stage 5: QC (Quality Control & Verification)**

**Current Baseline**: Median \~60-90 seconds (part of QC+Delivery phase)  
**Priority**: HIGH \- Compliance-critical, every-page verification required

### **Events to Instrument**

#### **5.1 QC Review Started**

* **Event Name**: `roi.qc.review_started`  
* **Trigger**: Processor opens record set for quality review  
* **Timestamp Capture**: System-generated (QC workflow initiated or review screen opened)  
* **Context Attributes**:  
* `qc_type` (full\_review, spot\_check, automated\_assist)  
* `record_page_count` (pages to verify)

#### **5.2 Patient Identity Verification Completed**

* **Event Name**: `roi.qc.patient_verified`  
* **Trigger**: Processor completes name/DOB verification on all pages  
* **Timestamp Capture**: System-generated (verification checklist completed or manual flag)  
* **Context Attributes**:  
* `verification_method` (manual\_every\_page, automated\_assist, sampling)  
* `verification_failures_count` (pages with name/DOB mismatch)  
* `verification_time` (calculated: verified\_ts \- review\_started\_ts)

#### **5.3 Scope Compliance Verified**

* **Event Name**: `roi.qc.scope_verified`  
* **Trigger**: Processor confirms retrieved records match authorization scope  
* **Timestamp Capture**: System-generated (scope checklist completed)  
* **Context Attributes**:  
* `scope_match` (full\_match, partial\_match, over\_retrieval, under\_retrieval)  
* `redaction_required` (true/false)  
* `pages_excluded` (count of pages removed due to scope mismatch)

#### **5.4 QC Review Completed**

* **Event Name**: `roi.qc.review_completed`  
* **Trigger**: Processor approves record set as QC-passed and ready for delivery  
* **Timestamp Capture**: System-generated (QC approval submitted)  
* **Context Attributes**:  
* `qc_status` (passed, failed, needs\_rework)  
* `qc_total_time` (calculated: review\_completed\_ts \- review\_started\_ts)  
* `issues_identified_count`  
* `rework_required` (true/false)

---

## **Stage 6: DELIVERY (Packaging & Transmission to Requester)**

**Current Baseline**: Median \~30-60 seconds (remainder of QC+Delivery phase)  
**Priority**: CRITICAL \- Highest variance (6-10x) by delivery method

### **Events to Instrument**

#### **6.1 Delivery Method Selected**

* **Event Name**: `roi.delivery.method_selected`  
* **Trigger**: Processor selects how records will be delivered  
* **Timestamp Capture**: System-generated (delivery method dropdown selected)  
* **Context Attributes**:  
* `delivery_method` (electronic, fax, auto\_fax, mail, cd\_dvd, portal, walk\_in, other)  
* `delivery_preference_source` (requester\_specified, system\_default, processor\_selected)  
* `electronic_eligible` (true/false) \- if electronic was an option

#### **6.2 Delivery Preparation Started**

* **Event Name**: `roi.delivery.prep_started`  
* **Trigger**: Processor begins preparing delivery package  
* **Timestamp Capture**: System-generated (delivery workflow initiated)  
* **Context Attributes**:  
* `prep_activities` (address\_label, cd\_burn, encryption, cover\_letter, packaging)

#### **6.3 Request Submitted/Delivered**

* **Event Name**: `roi.delivery.submitted`  
* **Trigger**: Request marked as completed and delivered  
* **Timestamp Capture**: System-generated (final submit button clicked in HealthSource)  
* **Context Attributes**:  
* `submission_status` (delivered, failed, pending)  
* `delivery_time` (calculated: submitted\_ts \- prep\_started\_ts)  
* `delivery_confirmation` (tracking\_number, email\_receipt, system\_log)  
* `total_request_time` (calculated: submitted\_ts \- request\_received\_ts)

#### **6.4 Post-Delivery Activities Completed (Optional \- Future)**

* **Event Name**: `roi.delivery.post_delivery_completed`  
* **Trigger**: AOD logged, tracking updated, files archived  
* **Timestamp Capture**: System-generated (post-delivery checklist completed)  
* **Context Attributes**:  
* `aod_logged` (true/false) \- Accounting of Disclosure  
* `tracking_updated` (true/false)  
* `files_archived` (true/false)

---

## **Critical Segmentation Dimensions**

To enable stratified analysis and identify efficiency opportunities, **every event** must capture these core dimensions:

### **Request Attributes**

* `request_id` (eRID)  
* ~~`major_class` (ATTY, CLIN, INS, COPY, PAT, PAYD, FAC, GOV, PRO, other)~~  
* ~~`primary_reason` (detailed reason code)~~  
* ~~`request_type` (Concare, Standard, Audit, Patient, BOC, DDS)~~  
* `request_type`   
  * Requestor Type  
  * Major Class  
  * Primary Reason  
  * Secondary Reason  
* `record_type` (medical\_record, correspondence\_letter, billing)  
* `page_count_bucket`

### **System/Environment Attributes**

* `health_system_id`  
* `site_id`  
* `emr_system` (Epic, Cerner, Meditech, Allscripts, NextGen, Athena, other)  
* `healthsource_version`

### **Processor Attributes**

* `processor_id`  
* `processor_tenure_category`  
* `processor_location` (remote, onsite)  
* `processor_zone` (geographic)

### **Timing Context**

* `timestamp_utc`  
* `day_of_week`  
* `hour_of_day`  
* `time_since_prior_event` (workflow progression tracking)

---

