# DW Retro Analysis — 2026-02-25

## TL;DR

5 production incidents in ~7 days across one team. Root causes cluster into two buckets: **(1) requirement ambiguity** (everyone agrees on words but not meaning) and **(2) system complexity blindness** (features touch HS, RCS, and Intake in ways nobody fully maps beforehand). The team is collaborative and psychologically safe, but that safety may be masking a reluctance to name individual accountability or challenge team velocity.

---

## The 5 Incidents

| # | Incident | What Broke | Detection | Severity |
|---|----------|-----------|-----------|----------|
| 1 | **Specific Provider GA** | Radio buttons hidden for RCS-disabled sites; Ops expected them visible | Ops via Slack, next day | Rollback |
| 2 | **Custom Abstract (Pilot)** | Gold standard abstract couldn't be trashed for custom abstract | Ops via Slack, next day | Fixed forward |
| 3 | **RCS 50x Errors** | RCS deploys cause 502s to all HS endpoints consuming RCS | Alert (Datadog) | 5 biz days to mitigate, still WIP |
| 4 | **DAR Subsite Validation** | Async bug enabled submit button prematurely; fix then broke logging submission | Slack, next day | Fixed forward |
| 5 | **Cerner Subsites** | Subsite dropdown only coded for Epic config key, Cerner broken | Slack | Fixed forward |

**Detection pattern**: 4 of 5 found by Ops/users via Slack the *next day*. Only RCS 50x had an automated alert. That's a monitoring problem.

---

## Root Cause Taxonomy

| Root Cause | Incidents Affected | Frequency |
|------------|-------------------|-----------|
| Unclear/misaligned requirements | #1, #2, #4 | 3/5 |
| Testing gap (scenarios not covered) | #3, #4, #5 | 3/5 |
| System interdependency not mapped | #1, #3, #4 | 3/5 |
| Environment parity (UAT != prod) | #3 | 1/5 |
| Monitoring gap | #5 | 1/5 |
| PR review shared same wrong assumption | #1, #4 | 2/5 |

The **dominant pattern**: Features are scoped to one screen (DAR), but Ops now expects behavior across DAR + Logging + Fulfillment. The team keeps getting surprised by this. Bomi named it well: *"I just assumed if it's on the request and that request moves forward, we inherit whatever existed in the previous step. But that's not what happens."*

---

## Noteworthy Observations

### 1. The "Fast Follow" Trap
Bomi and Nina both articulated a recurring anti-pattern:
- MVP ships for DAR only ("just a toggle")
- Expansion to logging/fulfillment assumed to be trivial
- Turns out to be complex, but scope already committed
- Requirements get fuzzy under pressure

This is a **planning debt** issue, not an execution issue. The team is executing what they're told — the problem is upstream.

### 2. Assumption Propagation Through Review
Pryce noted his PR review didn't catch the Specific Provider issue because *he shared the same wrong assumption* as the author. When reviewer and author have identical mental models, code review provides zero safety net. This suggests the team needs **adversarial review** (someone asking "what would Ops expect here?") not just technical review.

### 3. Bomi's Self-Flag
Bomi wrote: *"Nina also mentioned Specific Provider toggle would hide the whole confirmation but I skimmed the message and didn't catch it."* This is honest and valuable — but nobody explored it further. Was it a one-off, or is Slack a structurally unreliable channel for requirement alignment? (Spoiler: it is.)

### 4. RCS Dependency Is Uncharted Territory
The team has no answer to "What if RCS is down?" Dean's point about defaulting to the *safest* behavior for compliance is the right frame, but Danylo correctly noted there are multiple "safe" approaches (show controls vs. block submission). This needs a **decision**, not more discussion.

### 5. LaunchDarkly — Unanimous, Unresolved
Every engineer wants feature flags. Nobody has them. The dependency is on eSRE/Cloud Platform, and the timeline is "TBD." This is the single highest-leverage fix for reducing blast radius.

---

## Commitments Assessment

| Commitment | Owner | When | Strength |
|-----------|-------|------|----------|
| Workflow training / shadowing | John | "Sprint X" | Weak — no date, no format defined |
| LaunchDarkly | Edward/Dean, John to push eSRE | "TBD" | Medium — external dependency, but right people identified |
| Best practices guide(s) | Nina | Next sprint | Medium — Nina is capable, but scope is vague |

**Honest take**: For 5 incidents in a week, 3 commitments (two of which are vague) feels light. The rule at the bottom of the doc is good — *"If we can't name an owner and a start date, it's not a commitment — it's a wish"* — but it wasn't fully applied.

---

## Meta-Analysis: Team Dynamics

### Psychological Safety: High (maybe too comfortable)
The food banter at the top is charming and signals genuine rapport. Nobody was defensive during the retro. But high safety can also mean **low challenge**. Nobody said:
- "5 broken releases in a week is unacceptable"
- "Why wasn't X tested before merge?"
- "This is the third time we've had this class of problem"

The retro was *descriptive* (what happened) but not *evaluative* (was this okay?).

### Who Carries the Conversation

| Person | Role in Retro | Signal |
|--------|--------------|--------|
| **Nina** | Did 60%+ of analytical heavy lifting. Named patterns, proposed frameworks, connected dots across incidents. | Team's systems thinker. |
| **Bomi** | Asked the hard question nobody else did — *"do we work on too many things at once?"* Self-flagged her own miss. | Strong product instincts, hedges delivery ("I wonder...", "I don't know if that's legitimate..."). |
| **Danylo** | Most direct/practical voice. LaunchDarkly, E2E tests, "block the submit button." | Cuts through discussion to solutions. |
| **Dean** | Single best insight of the meeting (workflow knowledge gap → shadow users). Quiet but high-signal. | Worth drawing out more. |
| **Pryce** | Factual, measured. Explained his incidents clearly. | Didn't volunteer patterns or solutions unprompted. |
| **Ed** | Transparent about his own knowledge gaps. Good instinct around documentation/best practices. | Honest self-assessor. |
| **Joshua** | Present but essentially absent from retro discussion. | Worth a check-in. |

### Difficult Conversations Being Avoided

**1. Velocity vs. Quality tradeoff**
John asked "if we lowered the pace, would some of these emerge naturally?" The team pivoted to requirement quality rather than answering directly. Nobody said "yes, we're shipping too much too fast." That might be true, or it might not — but the question deserves a direct answer.

**2. Individual accountability**
The retro is admirably blameless but verges on *ownerless*. Everything is framed as systemic. Systemic fixes are good, but "unclear requirements" as a root cause for 3/5 incidents begs the question: whose job is it to *make* requirements clear? That boundary between product and engineering isn't being interrogated.

**3. Bomi's WIP question went unanswered**
*"Do we work on too many different things at once?"* is one of the most important questions a PM can ask. The team discussed knowledge-sharing and documentation instead. The answer might be "yes, we have too much concurrent WIP in the same codebase areas," which is a planning/prioritization issue, not a documentation issue.

**4. Repeat patterns not called out as repeat**
Nina said "we're probably all running into the exact same problems, just on different timelines." This has apparently been happening for a while. Nobody asked "why haven't we fixed this pattern before now?"

---

## Threads to Pull (Manager Action Items)

### Immediate (This Sprint)
1. **Answer Bomi's WIP question** — Look at the last 2-3 sprints. How many concurrent DARCS-area features were in flight? If >2, that's your answer.
2. **Force the RCS-down decision** — Get Nina, Dean, and Danylo in a 30-min session. Output: a one-pager that says "when RCS is unavailable, here is the default behavior per screen." No more open question.
3. **Make the LaunchDarkly ask concrete** — Write the eSRE request before Monday. Specify what you need (relay proxy), which services, and urgency framing (5 incidents in 1 week).

### Near-Term (Next 1-2 Sprints)
4. **Institute "Ops Lens" review** — Before any DARCS feature merges, someone (could rotate) asks: "What does Ops expect on every screen?" This is a 5-minute checklist, not a process overhaul.
5. **Follow through on workflow shadowing** — Dean's idea is excellent. Schedule one session. Even one 30-min shadow with a logging operator will pay dividends.
6. **Nina's best practices doc** — Give it a clear scope: "DARCS feature implementation checklist" not a general best practices tome. Should fit on one page.

### Strategic (Next Quarter)
7. **E2E test investment** — Danylo flagged no integration test capability. This won't fix itself. Needs a spike ticket and capacity allocation.
8. **Watch Nina for burnout** — She's carrying the analytical load for the team. Great engineer-thinker, but if she's also writing the best practices guide, leading requirement clarity, AND building features, that's a lot.
9. **Joshua's engagement** — Nearly zero contribution to the retro. Worth a 1:1 check-in on engagement.
