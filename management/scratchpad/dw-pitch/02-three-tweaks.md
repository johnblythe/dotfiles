# The Three Tweaks — Framework

## Framing
These aren't new processes. They're guardrails around what the best engineers on this team already do. The ask is small. The unlock is big.

---

## Tweak 1: Write It Down

### What
Every ticket moving to In Progress has:
- **Input:** What data/state does this start with?
- **Output:** What does "done" look like concretely?
- **Touchpoints:** Which files/services/tables get modified?

Not a novel. A recipe card.

### The Pattern (Ben's actual tickets)
```
PDC-6952: Create DF Retry Tracking Table (2 pts)

Input:  Schema DDL for EREQUEST_DF_RETRY table (included below)
Output: Flyway migration + MyBatis mapper + POJO
Files:  db/migration/V*.sql, RequestServiceDAO.java/.xml

CREATE TABLE EREQUEST_DF_RETRY (
  ID NUMBER PRIMARY KEY,
  REQUEST_ID NUMBER NOT NULL,
  RETRY_COUNT NUMBER DEFAULT 0,
  ...
);
```

### The Anti-Pattern (anonymized)
```
Ticket X: Migration work (3 pts)

Description: "TBD"
In Progress: 7 weeks
```

### Why It Matters
- 61% of team's work is Claude-assistable — but only with specs
- Peers can't review what they can't understand
- "Write it down" doesn't mean more ceremony — it means the ticket IS the spec
- Ben spends maybe 15 min extra per ticket. Saves hours downstream.

### The Ask
- Before dragging to In Progress: input, output, touchpoints defined
- Use Ben's DF Retry chain as the template
- Doesn't need to be perfect. Needs to be pickupable.

### What It Unlocks
- ~24 pts/sprint becomes Claude-assistable (migration DDL, test scaffolds, service skeletons)
- Code reviews get faster (reviewer knows what to look for)
- Onboarding gets easier (new engineer can read the ticket and contribute)

---

## Tweak 2: Review It Fast

### What
48-hour code review SLA. Not merged in 48h — *reviewed* in 48h. First pass, comments posted.

### The Current Pain
- 13 items in code review right now
- Oldest: 51 days
- 4 items stuck 15-21 days
- One stuck review blocks the next 2-3 tickets in a dependency chain

### Why It Piles Up
- No defined reviewer per workstream
- No visibility into who's waiting
- Easy to miss in the noise of 65 tickets
- "I'll get to it" → 3 weeks later

### The Ask
- **Pair up:** Each workstream gets a named reviewer (not the author)
- **Timebox:** If your PR hasn't been reviewed in 48h, call it out in standup
- **Small PRs:** Tweak 1 naturally produces smaller, focused PRs (one artifact per ticket)

### What It Unlocks
- Dependency chains flow instead of stalling
- WIP drops (finished work stops piling up in review)
- Sprint burns become predictable (no more "90% done but stuck in CR")
- Engineers feel momentum instead of waiting

### Implementation
| Workstream | Author(s) | Reviewer |
|------------|-----------|----------|
| Caching/Admin | Dean, Edd | Cross-review each other |
| DARCS | Gene | [TBD — needs external reviewer] |
| Specific Provider | Nina | [TBD] |
| Fulfillment | Gene, Pryce | Cross-review each other |
| Default Values | Daniel | [TBD] |
| DF Retry | Ben | [TBD] |

*Fill in together with the team — don't assign, let them pick.*

---

## Tweak 3: Let Claude Handle the Boilerplate

### What
Use Claude for the mechanical parts of tickets where the spec is clear. Engineers stay on design decisions, integration logic, and review.

### Where It Fits (real examples from this sprint)

| Work Type | Example | Claude Does | Engineer Does |
|-----------|---------|-------------|---------------|
| Migration DDL | PDC-6952 (tracking table) | Generate Flyway SQL + MyBatis mapper from schema | Review, adjust constraints, test |
| Test scaffolds | PDC-6708 (E2E tests) | Generate test suite from method signatures | Define scenarios, validate coverage |
| Service skeleton | PDC-6539 (DF service) | Generate class structure + method stubs | Implement business logic |
| Config patterns | PDC-5974/5975 (cache policy) | Apply existing pattern to new endpoints | Verify behavior, edge cases |
| UI components | PDC-6706 (DOSTable binding) | Generate Angular component boilerplate | Wire up data, polish UX |
| Find-replace | PDC-5111 (location→site rename) | Systematic rename across codebase | Verify no semantic changes |

### Why Now
- Tweak 1 (Write It Down) produces the specs Claude needs
- 61% of sprint work scores MEDIUM or higher on Claude-assistability
- ~24 pts per sprint of quick-win acceleration
- The team already writes the hard parts — let Claude write the tedious parts

### The Ask
- Try it on 2-3 tickets this sprint
- I'll provide starter workflow templates (migration generator, test scaffolder, review helper)
- Engineers own the output — Claude drafts, you ship

### What NOT to Expect
- Claude won't replace design thinking
- Claude won't handle novel business logic
- Claude won't review for architectural fit
- Claude WILL handle: boilerplate, repetitive patterns, scaffolding, find-replace, test stubs

### What It Unlocks
- 15-20 pts/sprint of engineer time freed for design + integration work
- Faster ticket completion on the "boring" middle of the stack
- Engineers spend time on the parts that need human judgment

---

## The Compound Effect

```
Tweak 1 (Write It Down)
  → enables Tweak 3 (Claude needs specs)
  → accelerates Tweak 2 (reviewers understand PRs faster)

Tweak 2 (Review Fast)
  → unblocks dependency chains
  → reduces WIP
  → makes sprint burns predictable

Tweak 3 (Claude Boilerplate)
  → frees engineer time for design
  → produces smaller, focused PRs (easier to review → Tweak 2)
  → templates reinforce Tweak 1 patterns
```

**They're a flywheel.** Each one makes the others easier.
