# Communication

> Always remember that it is impossible to speak in such a way that you cannot be misunderstood.
> — Karl Popper

Communication must move fast enough for momentum AND slow enough for synthesis.

We use: **hot, warm, cold.**

---

## Hot

Real-time, ephemeral: Slack, huddles, video calls, whiteboard sessions.

**Purpose:** Close gaps, sharpen thinking, educate.

**Stays hot if:** Only matters to people in the conversation right now.

---

## Warm

Durable-enough for the group: Jira discussions, decision threads, kickoff Q&A.

**Purpose:** Enable "replay" when we need to try again. Make decision paths accessible.

**Warm it up if:** Other team members need visibility into this decision path.

---

## Cold

Persistent, archival: Final specs, ADRs, post-mortems.

**Purpose:** Understand 6 months from now why the system is what it is.

**Freeze it if:** Future-you needs to understand this decision/outcome.

---

## Fail Modes

| Mode | Symptom | Fix |
|------|---------|-----|
| Stuck hot | 89-reply Slack thread on architecture | Move to Jira/doc before reply 10 |
| Never frozen | Spec doesn't match deployed system | Update doc when shipping |
| Born cold | Jira ticket with zero context | Warm it up with decision trail |
| Dead cold | Confluence page no one reads | Archive or assign owner |
| Wrong temp | Deep technical debate in all-hands | Take it to appropriate forum |
