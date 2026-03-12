# Partnerships & Integrations

External partner integrations and strategic partnerships.

## Active Projects

### PDCR-409: Athena Phase 2
- **Status:** Above the line
- **Size:** LG (4 sprints, 3 BC)
- **Pod:** Platform, Intake & Logging
- **Fixed Allocation:** 0.5
- **Owner:** Alegu (eng), Ian (former, left Q3/Q4)
- **Deadlines:**
  - **Mid-Feb:** HS API endpoints ready for integration testing
  - **Early Mar:** 2 weeks integration testing complete, hand off to Athena validation
  - **End of Mar:** Production live, begin customer testing
  - Note: Athena requires ~4 weeks for solution validation before go-live
- **Reqs doc:** [athena-phase2-reqs.pdf](./athena-phase2-reqs.pdf)
- **What:** Embedded SMART app in Athena EHR. Bi-directional integration.
- **HS must provide:**
  - Request list retrieval (search, filter, frequent polling)
  - Request detail + documents
  - Exception management actions (approve/decline/upload)
  - Audit trail for Athena user actions
  - Practice ↔ Site ID mapping (1:1, 1:N, or N:N — TBD where this lives)
- **Theme links:**
  - Search speed (PDCR-404) — list retrieval perf critical
  - Event-driven — polling vs events for status updates
  - Audit log (PDCR-451)
  - Intake consolidation
- **Open questions:** 11 items in reqs doc including new pend statuses, rate limits, CDR access, site mapping location

## At Risk

### PDCR-405: Ontellus Phase 2
- **Status:** At Risk - Scope Questions
- **Size:** MD (2 sprints, 9 BC)
- **Pod:** Platform
- **Fixed Allocation:** 1.5
- **Risk:** Scope unknown - significant delta between estimate (2) and BC (9). Allocate budget.
