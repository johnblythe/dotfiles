# Concrete Examples — Pull from Analysis

## Act 2: "What's Already Great"

### Ben's Decomposition (Gold Standard)
**Workstream:** DF Retry (WS6) — 14 pts, 50% burn at midpoint

The chain:
```
PDC-6950: Tech Spec (2 pts) ✅ Done
  ↓
PDC-6952: Tracking Table (2 pts) — To Do
  - Flyway migration V*.sql
  - MyBatis mapper (RequestServiceDAO.java/.xml)
  - POJO for EREQUEST_DF_RETRY table
  - Schema DDL is IN the ticket description
  ↓
PDC-6951: Eligibility Endpoint (3 pts) — Code Review
  - REST endpoint in WorkflowWebService.java
  - Method signatures defined in ticket
  ↓
PDC-6953: Modify DF Flow (2 pts) — To Do
  - Integration into existing workflow
  - Clear input/output contract
```

**Why this is great:**
- 2-2-3-2 progression matches actual code surface area
- Each ticket = one deployable/testable artifact
- Any engineer could pick up PDC-6952 cold and know exactly what to build
- Claude could generate 70-80% of PDC-6952 from the spec alone

**Slide quote:** "Ben's tickets read like a recipe. Ingredients, steps, done."

---

### Nina's Vertical Slicing (Velocity Leader)
**Workstream:** Specific Provider (WS3) — 29 pts, 55% burn at midpoint (best on team)

Pattern:
```
Parent Epic
  ├── Table Creation (sub-task) ✅
  ├── DAO Layer (sub-task) ✅
  ├── Model Updates (sub-task) ✅
  ├── UI Integration (sub-task) ✅
  ├── Spacing/Polish (1-2 pts) — To Do
  └── Hover States (1-2 pts) — To Do
```

**Why this is great:**
- Each sub-task is a vertical slice through the stack
- Done items prove the pattern works — she's shipping
- Remaining work is small UI polish, low-risk
- 8/10 decomposition score

**Slide quote:** "Nina ships because every ticket touches one layer, start to finish."

---

### Team Throughput (Collective Win)
- 6 sprints analyzed: throughput stabilized at ~60 pts
- Pointing discipline improved from ~60% (Q4) to 82-88% (Q1)
- This happened organically — no mandate, no process change

**Slide quote:** "You found your rhythm without anyone telling you to. That's the hardest part."

---

## Act 3: "What Everyone Already Feels"

### The Code Review Wall (systemic, blameless)

| Stuck Duration | Count | Impact |
|---------------|-------|--------|
| 50+ days | 1 | Entire DARCS workstream blocked |
| 15-21 days | 4 | Caching/Admin chain frozen |
| 6+ days | 5 | Fulfillment/Transparency stalled |
| 3-5 days | 3 | Normal-ish but adds up |
| **Total** | **13** | **~30 pts of work waiting on eyeballs** |

**How to present this:**
- Don't show names. Show the wall.
- "13 items waiting for review. That's 30 points of finished work sitting on a shelf."
- "One stuck review blocks the next 3 tickets in the chain."
- Everyone in the room has felt this. Let them nod.

**Visual idea:** A pipeline diagram showing work flowing into a "Code Review" bottleneck and piling up.

---

### The Overcommitment Illusion

```
Committed:  ████████████████████████ 124 pts
Capacity:   ████████████             60 pts
Midpoint:   ███████                  35 pts done (28%)
```

**How to present this:**
- "We say yes to 124 points. We finish 60. Every sprint."
- "That's not a performance problem — it's a signal-to-noise problem."
- "When everything's in sprint, nothing's prioritized."
- Frame as: right-sizing commitment = clarity, not less ambition

---

### The Empty Ticket Problem (systemic, blameless)

Show anonymized:
```
Ticket A: 3 pts | Description: 4 characters | In Progress: 7+ weeks
Ticket B: 3 pts | Description: 4 characters | In Progress: 7+ weeks
Ticket C: 4 pts | Description: "manual testing" | No test plan
Ticket D: 2 pts | Description: "check w [name]" | Informal
```

**How to present this:**
- "6 points of work that nobody can start, review, or help with"
- "Not because the engineer doesn't know what to do — but because the ticket doesn't say"
- "Claude can generate 70% of a migration script... if it knows the schema"
- This connects directly to Tweak 1

---

## Act 5: "What This Adds Up To"

### Before/After Table

| Dimension | Today | After 2 Sprints |
|-----------|-------|-----------------|
| Sprint commitment | 124 pts (2x capacity) | ~65 pts (right-sized) |
| Midpoint burn | 28% | ~45-50% |
| Code Review queue | 13 items, 51 day max | <5 items, 48h SLA |
| Empty descriptions | 5 tickets (6 pts) | 0 |
| Claude-assisted work | 0 pts | 15-20 pts/sprint |
| Decomposition avg | 5.9/10 | 7+/10 |

**Slide quote:** "Same team. Same hours. More clarity. More shipped."
