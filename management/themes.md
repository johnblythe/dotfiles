# Emergent Themes

Strategic patterns that cut across projects. Use these to spot sequencing opportunities, shared infrastructure, and architectural leverage.

---

## Event-Driven Architecture / Pub-Sub Decoupling

**What:** Move toward pub/sub patterns, decouple our stack from others via events rather than direct integrations.

**Why:** Current integrations are frail/brittle. Filtering logic coupled in our code that should live in subscribers.

**Foundational Initiative:** PDCR-422 Event-based Logging for Time-on-Task
- Phase 1 (Experiment) builds the core: event schema, ingestion pipeline (Kafka/Snowflake), validation
- Business justification: time-on-task analytics
- Spillover value: event infra for other projects to leverage

**Projects that can leverage PDCR-422 infrastructure:**
- PDCR-405 Ontellus Phase 2 — emit status events, shift filtering to subscriber
- PDCR-167 Pre-Fulfillment Review — emit audit state transition events
- TBD-002 Provider Retrieval — has eventing component
- PDCR-409 Athena Phase 2 — could reduce polling pressure via status events (future)

**Sequencing Insight:**
- PDCR-422 Phase 1 early → other projects emit into existing pipe
- Avoids each project building one-off event solutions
- "Start slow to move fast" — invest in foundation, accelerate downstream

---

## Intake Consolidation / Unified Central Intake

**What:** Clean up and unify the multiple intake paths into a central intake system.

**Why:** Current intake paths are fragmented, tightly coupled to HealthSource app, brittle. Athena and other integrations need cleaner intake APIs.

**Related Projects:**
- PDCR-409 Athena Phase 2 — requires decoupled intake for embedded app
- PDCR-406 SPIKE: Intake Acceleration for e-Request ID Generation

**Opportunities:**
- If intake is unified, new integrations (beyond Athena) become easier
- Could leverage event-driven architecture for intake events

---

## Consolidated Architecture Patterns

**What:** Identify and reuse common patterns across the stack rather than one-off implementations.

**Why:** Reduces cognitive load, speeds up future work, improves maintainability.

**Related Projects:**
- (to be populated as patterns emerge)

**Opportunities:**
- (to be populated)

---

## DB / Search Performance

**What:** Database and query performance is a recurring bottleneck across multiple projects.

**Why:** Unbounded subqueries, bad indexing, queries timing out. Affects UI, API consumers, and new integrations.

**Related Projects:**
- PDCR-404 Improve Search Speed — direct attack on query/index issues
- PDCR-409 Athena Phase 2 — list retrieval perf critical for polling
- PDCR-451 DB Space Mitigation — audit log migration, part of horizontal strategy
- PDCR-413 DB Horizontal Strategy (below line)

**Opportunities:**
- Fix in PDCR-404 unlocks better perf for Athena and future integrations
- Consider read replicas for API consumers
- Event-driven approach could reduce polling pressure

---

## (Template for new themes)

**What:**

**Why:**

**Related Projects:**

**Opportunities:**
