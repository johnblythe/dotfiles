# Quality / UADs

Strategic initiative for quality improvements, user experience, and UAD (User Acceptance & Design) work.

## Active Projects

### PDCR-417: STORK - Reason for Request and Requester Improvements
- **Status:** Above the line
- **Size:** LG (4 sprints)
- **Pod:** Intake & Logging
- **What:** ML/DS project that parses request letters to prepopulate logging fields. You own Python pre/post processing, DS team owns ML.
- **Risk:** No description in Jira — scope undefined. Need sync with DS team/PM.
- **Related:** PDCR-253 (Done - DOS/RFR/Requester accuracy), PDCR-459 (FL766 statute classification)

### PDCR-167: Pre-Fulfillment Review Framework
- **Status:** Above the line
- **Size:** ~6 weeks, 2-3 engineers (pending final shaping)
- **Pod:** Fulfillment & QC
- **Owner:** John Blythe (Eng Lead), John Cusimano (PM), Vivian Lee (Design), Jennifer Martin (Ops)
- **PRD:** [Pre-fulfillment QC.pdf](./Pre-fulfillment%20QC.pdf)
- **Blocker:** Designs, scope, reqs need finishing before eng estimation locked
- **Phases:** Alpha (internal pilot) → Beta (expanded config) → GA (full rollout + dashboards)
- **Constraint:** Code freeze may push prod release to early Q1
- **Theme link:** Could emit events for audit state transitions → ties to event-driven architecture

### PDCR-411: Explicit "Pull List" Option in HealthSource Intake
- **Status:** Above the line
- **Size:** SM (1 sprint, 2 BC)
- **Pod:** Intake & Logging
- **What:** Add checkbox to upload form letting user indicate "this is a pull list" (batch of requests, not single). Routes to existing pull list ingestion/CDR flow.
- **Context:** System currently ignores cover sheets indicating multiple requests. Other parts of stack already handle pull lists — just need UI + routing wired up.
- **Risk:** Low — plumbing existing capabilities together

### PDCR-410: Alpha/Beta Test New Reason for Request Selection UX
- **Status:** Above the line
- **Size:** TBD
- **Pod:** Intake & Logging
- **PRD:** [Google Doc](https://docs.google.com/document/d/1adrgDX1bz0zJGobV0AL0p3l_ir_W5vV1HdEQ0z8ND58/edit)
- **What:** Guided UX for RfR selection. Reduces incorrect selections 30-40%, decision time ~20%.
- **Rollout:** Alpha (2 high-error states, attorney requests) → Beta (national, attorney) → GA (all request types)
- **Notes:** Feature-toggle controlled. Discuss sizing with Paul/Jen M

### PDCR-435: DISCOVERY - Verify Assist UI Updates
- **Status:** Above the line
- **Size:** TBD
- **Type:** UX Discovery
- **PRD:** [Google Doc](https://docs.google.com/document/d/11292kBez72P1nXc8tRXYEVgfFn09e1ocBeNVOXe0ARQ/edit)
- **What:** Guided conflict resolution UI for Verify Assist. Reduces time-on-task, cognitive load, UAD risk.
- **Rollout:** Experiment → Alpha → Beta → GA, feature-toggle controlled

## Below the Line

### PDCR-408: DAQARI Integration for HealthSource Users
- **Size:** XL (6 sprints)
- **Pod:** Fulfillment & QC, Platform
