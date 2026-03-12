# DW "Better Practices" Pitch — Narrative Outline

## Premise
The team already has strong engineering instincts. Two engineers independently developed decomposition patterns that are best-in-class. The gap isn't skill — it's consistency and a few missing guardrails. This pitch names what's working, makes it visible, and proposes 3 lightweight changes.

## Tone
Celebratory → Relatable → Actionable. Never corrective. "Here's what great looks like on THIS team."

---

## Story Arc

### Act 1: "I Looked Under the Hood" (2 min)
**Goal:** Establish credibility, show you did the work.

- Analyzed all 65 tickets across 6 workstreams
- Cross-referenced with actual codebase (healthsource, idsb)
- Looked at 6 sprints of history, not just this one
- **Punchline:** "The data tells a clear story — and most of it is good."

**Data:** 65 tickets, 124 pts committed, 7 engineers, 6 workstreams

### Act 2: "What's Already Great" (3 min)
**Goal:** Name the heroes. Make the good patterns visible.

Beat 2a — **Ben's decomposition is textbook**
- Sequential dependency chain: Tech Spec → Data Layer → API → Integration
- Each ticket has SQL DDL, method signatures, clear I/O
- Any engineer (or Claude) could pick up a ticket and know exactly what to build
- "This is what a 9/10 looks like."

Beat 2b — **Nina's vertical slicing ships**
- 55% burn at sprint midpoint — best on the team
- Table → DAO → Model → UI progression across sub-tasks
- Each sub-task is independently testable
- "This is what velocity looks like."

Beat 2c — **Pre-assignment during planning works**
- Brett confirms: all work gets assigned during planning, not ad-hoc
- This is uncommon — most teams have unassigned tickets mid-sprint
- Shows planning discipline and ownership culture

Beat 2d — **The team has a real throughput number**
- ~60 pts/sprint, validated across 6 sprints
- 82-88% pointing discipline (up from ~60% in Q4)
- "You know your capacity. That's rare."

**Transition:** "So what's getting in the way?"

### Act 3: "What Everyone Already Feels" (3 min)
**Goal:** Name the pain without blaming anyone. The system is the problem, not people.

Beat 3a — **Code reviews are stuck**
- 13 items in code review right now
- Some sitting 51+ days
- One stuck review blocks entire dependency chains
- "You've all felt this. PR goes up, crickets for 2 weeks."

Beat 3b — **We commit 2x what we can finish**
- 124 pts committed vs ~60 pt capacity
- This isn't ambition — it's noise. Hard to prioritize when everything's "in sprint"
- "Not a discipline problem. A visibility problem."

Beat 3c — **Too specialized — bus factor risk**
- Each workstream is owned by 1-2 people with no cross-training
- When someone's out, it's not "second string steps in" — it's "running back plays wide receiver"
- This ALSO explains stuck code reviews: nobody else can review what they don't understand
- Not a blame thing — it's how the work naturally siloed over time

Beat 3d — **Some tickets can't be started**
- 6 pts of committed work have essentially no specification
- Not anyone's fault — but Claude can't help, peers can't review, nobody can unblock it
- "The ticket IS the spec. If it's empty, we're stuck."

**Transition:** "The gap between where you are and where you could be is small. Three things."

### Act 4: "Three Tweaks" (5 min)
**Goal:** Each tweak is lightweight, has a champion already on the team, and unlocks measurable throughput.

**Tweak 1: Write It Down (Ben's Way)**
- What: Ticket descriptions include schema/pseudocode/method signatures
- Why: 61% of your work is Claude-assistable — but only if the spec exists
- Champion: Ben already does this. Nina's close.
- Ask: Before moving a ticket to In Progress, it needs I/O defined
- Unlock: ~24 pts of work becomes acceleratable per sprint

**Tweak 2: Review It Fast (48h SLA)**
- What: Code reviews get eyes within 48 hours. Not merged — just reviewed.
- Why: 13 items stuck right now. One 51-day-old review is blocking an entire workstream.
- Champion: Everyone benefits. This is the #1 thing slowing you all down.
- Ask: Pair up reviewers per workstream. If your review sits 48h, ping in standup.
- Unlock: Unblocks dependency chains, reduces WIP, makes sprint burns predictable

**Tweak 3: Let Claude Handle the Boilerplate**
- What: Use Claude for migration DDL, test scaffolds, service skeletons, config patterns
- Why: ~24 pts per sprint of work that's mechanical once the spec exists
- Champion: Links to Tweak 1 — good specs make Claude effective
- Ask: Try it on 2-3 tickets this sprint. I'll provide starter templates.
- Unlock: Engineers focus on design decisions, not copy-paste-modify

### Act 5: "What This Adds Up To" (2 min)
**Goal:** Paint the after picture.

- 60 pts capacity stays the same — but 15-20 pts are Claude-assisted
- Code reviews flow in 48h instead of 15-51 days
- Sprint commitment matches capacity (~60 pts, not 124)
- Decomposition quality goes from 5.9/10 → 7+/10 average
- "Same team. Same hours. More shipped."

---

## Supporting Data (for slides/appendix)

| Metric | Current | Target |
|--------|---------|--------|
| Sprint commitment | 124 pts | ~60 pts |
| Completion at midpoint | 28% | 50% |
| Items in Code Review | 13 | <5 |
| Tickets w/ empty descriptions | 5 | 0 |
| Avg decomposition quality | 5.9/10 | 7+/10 |
| Claude-assistable work leveraged | 0% | 61% (73 pts) |

## Cast (who gets named, positively)
- **Ben** — decomposition gold standard, cited by name as the pattern to follow
- **Nina** — velocity leader, vertical slicing exemplar
- **The whole team** — pointing discipline improvement (60% → 88%), sustainable throughput identification

## What NOT to say
- Don't name individuals for anti-patterns (Daniel's empty tickets, Dean's stuck reviews)
- Don't frame overcommitment as a planning failure — frame as a visibility problem
- Don't position Claude as replacing anyone — position as "handles the boring parts"
- Don't make this about new process — make it about making implicit knowledge explicit
