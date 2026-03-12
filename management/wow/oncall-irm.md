# Incident Response

> Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand.

---

## Escalation vs Incident

**Not everything is an incident.**

```
Is it hurting us right now? → SEV1
Will it hurt us soon if we ignore it? → SEV2
Is there a workaround? → Escalation
```

**Escalation:** Ping the right person/channel, create a ticket, work the queue. Not an incident.
**Incident:** `/incident` in Slack. You are now Incident Lead.

---

## Severity

Two levels. That's it. We'll split further when we have SLO data to justify it.

| Level | Name | Definition | Response |
|-------|------|------------|----------|
| SEV1 | Active harm | Hard down OR known financial/operational impact happening NOW | Immediate, all-hands |
| SEV2 | Imminent harm | Will become SEV1 if ignored, but we can get ahead of it | Within 1 hour, pull in help |

### Examples

**SEV1:**
- Intake stopped (email, fax, API, uploads)
- Requests skipping critical workflow stages
- Multiple health systems reporting failures
- Feature fully broken, no workaround

**SEV2:**
- Error rates climbing but not yet critical
- One system degraded, others fine
- Monitoring shows something wrong, users haven't noticed yet

**Escalation (not an incident):**
- Single user, single request, single system
- Workaround exists and is communicated
- Annoying but not blocking work
- Can wait until tomorrow without material harm

**When in doubt, go higher.** Easier to downgrade than to catch up.

---

## When Incident Is Declared

The person who declares becomes **Incident Lead**. Hierarchy shifts—everyone in the incident works for the IL until resolved.

### Incident Lead Does:
- Own the incident until resolved or handed off
- Set severity (can adjust as info comes in)
- Decide who's needed, dismiss who's not
- Post updates every 15 min (SEV1) or 30 min (SEV2)
- Call "resolved" or "monitoring"

### Incident Lead Does NOT:
- Debug the code themselves (unless they're the only one who can)
- Get pulled into side conversations
- Disappear without handoff

---

## Roles During Incident

| Role | Who | Does |
|------|-----|------|
| Incident Lead | Whoever declared (or handed off to) | Coordinates, communicates, decides |
| Responders | Engineers pulled in | Investigate, fix, report findings to IL |
| Comms | Digital Ops or designated | Stakeholder updates, field questions |
| Observers | Everyone else | Stay out of the way. Read, don't type. |

**Active ≠ Helpful.** 17 people debugging is chaos. 3 people debugging + 1 coordinating + 1 communicating is response.

---

## Response Flow

```
Declare → Assess → Mitigate → Resolve → Document
```

### 1. Declare
- `/incident` in Slack
- Set initial severity
- State what you know: "Requests skipping DAR, investigating"

### 2. Assess
- Blast radius? One system or many?
- When did it start? Correlate with deploys, changes.
- Who's needed? Pull them in explicitly.

### 3. Mitigate
**Restore first. Investigate second.**

Priority order:
1. Rollback (fastest)
2. Hotfix (if rollback not possible)
3. Debug in prod (last resort)

### 4. Resolve
- Confirm service restored
- Update stakeholders
- Move to "Monitoring" before closing

### 5. Document
- incident.io handles the timeline
- Fill in Contributors, Mitigators, Learnings
- Tie corrective actions to Jira tickets

---

## On the "Chaos"

Fast, aggressive response to a fragile system isn't chaos—it's appropriate.

When you inherit a system with:
- No documentation
- No monitoring
- Issues that surface only after hitting thousands of requests

You respond with many eyes and fast hands. That's not panic. That's pattern-matching across a codebase no one fully understands yet.

**What looks like chaos from outside:**
- 15 people in a channel
- Multiple theories flying
- Rapid-fire messages

**What it actually is:**
- Parallel investigation
- Knowledge sharing under pressure
- Fast convergence on root cause

The goal is not to look calm. The goal is to restore service.

As the system stabilizes and knowledge spreads, response will naturally tighten. Until then: respond hard, document everything, don't apologize for urgency.

---

## Post-Mortems

**Purpose:** Learn, don't blame.

**Required for:** SEV1, SEV2 with significant impact.

**Format:**
1. Timeline (incident.io generates this)
2. Contributors (what made it happen/worse)
3. Mitigators (what made it better than it could've been)
4. Root cause (5 whys—and "human error" is never the answer)
5. Corrective actions with owners and Jira tickets

---

## Fail Modes

| Mode | Symptom | Fix |
|------|---------|-----|
| Hesitation | "Should we declare?" for 20 min | When in doubt, declare. Can always downgrade. |
| Hero responder | One person debugs alone | IL pulls in help explicitly |
| Crowded channel | 20 people typing theories | IL assigns roles, asks observers to mute |
| Restore later | Debugging while users wait | Rollback first, always |
| No updates | Stakeholders pinging for status | IL posts every 15 min even if "still investigating" |
| Orphan actions | Post-mortem done, fixes never tracked | Corrective actions → Jira → sprint |
| Blame game | "Who deployed this?" | Systems prevent human error. Fix the system. |

---

## TODO

- [ ] Define SLO/SLA matrix for HealthSource
- [ ] Establish on-call rotation (length, handoff, PTO coverage)
- [ ] Runbook index by failure mode
