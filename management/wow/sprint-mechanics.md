# Sprint Mechanics

> Predictable outcomes over ticket velocity.

---

## Dailies/Huddles

**Project movement, not person status.**

Some dailies will be synchronous while others are async. Regardless, the point is much the same: surfacing blockers and progress against goals—not reciting what any individual did.

### Async Format

- Post by [team defined time] in project channel
- Format: `[Project/Goal]: [Status] [Blocker if any]`
- No blockers called out by [time] = assume green
- Sync standup for active blockers or coordination needs

### What Belongs

- Progress toward sprint goals
- Blockers (real ones, not "I'm still working on it")
- Coordination needs ("need 30 min with X today")

### What Doesn't

- Activity logs
- "Same as yesterday" (if true for 2+ days, that's a signal)
- Anything that should be a Slack or Jira update

---

## Goals

**The tickets are not the work.**

Each sprint has goals. Not everything maps to the goals, but goals are what we map to success.

### Principles

- Goals are outcomes, not tasks
- 2-4 goals per sprint (enough to focus, few enough to remember)
- Goals are set collaboratively — PM/EM bring priorities, team shapes what's achievable
- A goal is "done" when it's demo-able or shipped, not when tickets close
- Done => Delivered, not Code Complete

### Goals vs. Workload

Aim for goals ≈ 70-80% of capacity. The remainder is buffer for:
- Bugs and KTLO
- Unexpected complexity
- Support requests

If goals = 100% of capacity, you're planning to fail.

---

## Completion

**Goals are what we aim to complete.** Ticket completion and velocity are proxies, not targets.

### What We Measure

| Metric | Purpose |
|--------|---------|
| Goal completion | Did we deliver what we said we would? |
| Ticket completion | Diagnostic — are we sizing right? Are we protecting focus work? |
| Velocity | Diagnostic — are we consistent? Overloaded? |

Velocity is never a target. It's a signal for capacity planning and identifying drag.

### When Goals Slip

Name it early. Options:
1. **Scope cut** — Reduce goal to what's achievable
2. **Swarm** — Pull others in to hit the goal
3. **Extend** — Carry to next sprint (rare, needs good reason)

The biggest failure isn't missing the goal. The biggest failure is hiding the miss.

---

## Empowerment

Teams own the how. We provide power through:
- **Context** — Why this matters, what's upstream/downstream
- **Vision** — Where we're headed, what good looks like
- **Clarity** — Unambiguous goals, defined done
- **Obstacle removal** — Clearing blockers they can't clear themselves

### Teams Can

- Break down work in ways that best fit the team members
- Trade work between members
- Pair, swarm, or work solo
- Pod together or split apart
- Push back on scope or timelines with reasoning

Related, teams/pods will be expected to commit to delivery windows.

### We Don't

- Dictate task breakdown
- Assign individuals to tickets
- Micromanage daily activity
- Change goals mid-sprint without team input or reasons

---

## Accountability

Empowerment comes with accountability. Teams own their commitments.

### The Deal

1. Team signs up for delivery — not just coding, not just "we'll try"
2. Team communicates progress toward delivery proactively
3. Team delivers, or communicates why not (early)

### Timelines Over Punch Bowls

Move away from "here's a pile of work for Q1" toward:
- Delivery windows: "Week of Feb 10"
- Milestones: "MVP by sprint 3, full release by sprint 5"
- Clear handoff points: "API ready for frontend by [date]"

### Accountability Without Blame

- Miss the date? We learn. What did we miss in planning?
- Hide the miss? Critical problem.
- Patterns of misses? Systemic issue — fix the system, not the people.

---

## Visibility

**Surprises are great for birthdays, terrible for orgs.**

We work in public, and aim to add signal amidst much organizational noise.

### Rituals

| Ritual | Cadence | Purpose |
|--------|---------|---------|
| Demo | End of sprint | Show what shipped, get feedback |
| Blog/update | Weekly or biweekly | Broadcast progress, decisions, learnings |
| Stakeholder sync | As needed | Proactive updates to dependent teams |

### Working in Public

- Project channels over DMs for technical discussions
- Decisions get recorded in Jira (ticket) and/or Confluence
- Specs and designs shared before implementation
- PRs posted for visibility (RN role from code review)
- Blockers raised loudly, not whispered

### Why It Matters

- Builds trust with stakeholders
- Generates opportunity for context-added
- Creates accountability without surveillance
- Catches misalignment early
- Documents decisions for future-us (and new hires, etc.)

---

## PM/Lead Role

With empowered teams, what do PMs and leads actually do?

### Daily

- Monitor goal progress (async check-ins)
- Clear blockers
- Answer questions, provide context
- Shield team from noise and disrupts

### Weekly

- Check goal health — on track, at risk, blocked?
- Stakeholder updates
- Surface cross-team dependencies

### Sprint Boundaries

- Facilitate, not dictate, goal-setting
- Run retros
- Adjust capacity expectations based on learnings

### Always

- Say no to scope creep mid-sprint
- Escalate systemic issues
- Celebrate wins, normalize learning from misses

---

## Retros

Where learning happens. Non-negotiable.

### Format

End of every sprint. 45-60 min. Highlight things such as:

1. **What went well** — Reinforce good patterns
2. **What didn't** — No blame, just observation
3. **What to try** — One or two experiments for next sprint

Note: teams can run variations on these themes.

### Rules

- Blameless. Always.
- Action items get owners and tickets
- Follow up on last retro's experiments

---

## Fail Modes

| Mode | Symptom | Fix |
|------|---------|-----|
| Goal drift | "We'll get to it" for 3 sprints | Fewer goals, protect focus |
| Velocity worship | Pressure to hit points | Reframe: goals > tickets |
| Silent slips | Find out goals missed at demo | Daily async check-ins, early warning culture |
| Empty empowerment | "You're empowered" while every decision escalates | Actually let them decide; accept imperfect outcomes |
| Accountability as blame | Team afraid to miss | Model learning from misses; reward transparency, not perfection |
| Invisible work | Surprises at the end | Demos, blogs, public channels |
