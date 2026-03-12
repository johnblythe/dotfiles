# Stabilize ROI

Strategic initiative focused on platform stability, cost management, and technical debt.

## Active Projects

### PDCR-451: Database Space Mitigation (Q4 Spillover)
- **Status:** Above the line — ACTIVE
- **Size:** MD (2 sprints) → likely January, 1.5 engineers
- **Pod:** Platform
- **What:** Breaking out audit log + history table (~30% of disk space) to separate DB. Almost ran out of disk.
- **Context:** Part of larger horizontal scaling strategy. Migration is slow, painful, dangerous.
- **Update:** Cloud access finally received after ~3 month wait. Now testing theories in cloud, prepping for Q1. Expect January focus.
- **Related:** PDCR-413 (DB Horizontal Strategy, below line), PDCR-404 (Search Speed, separate effort)

### PDCR-432: Tray App Certificate Update 2026
- **Status:** Above the line
- **Size:** MD (2 sprints, 3 BC) - fixed cost, TBD actual
- **Pod:** KTLO
- **Engineers:** Rama, Alosiyus
- **What:** Customer rollout - install/update executable with new cert
- **Notes:** Prep work done in Q4. Execution phase now.

## Below the Line

### PDCR-445: Monitoring and Uptime (Q4 Spillover)
- **Size:** LG (4 sprints)
- **Pod:** Platform
- **Notes:** Some Camunda monitoring + Change Failure Rate

### PDCR-423: esMD - Stability and FHIR enhancements
- **Size:** LG (4 sprints)
- **Notes:** Possibly defer or help from Delivery resources

### PDCR-413: DB Horizontal Strategy
- **Size:** XL (6 sprints)
- **Pod:** Platform

### PDCR-414: Improved File Management
- **Size:** LG (4 sprints)
- **Pod:** Platform

### PDCR-286: Instrumenting and Alerting on Transmission Errors
- **Size:** MD (2 sprints)
- **Pod:** Platform

## Fixed Allocations
- **Security (vulns, Sailpoint):** 2 sprints/wk, Platform
