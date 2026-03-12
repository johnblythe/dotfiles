# Sprint Digest

Generate a sprint digest for stakeholders, published to Confluence.

## Usage
```bash
/sprint-digest
/sprint-digest Q1.S1
```

## Overview

Pulls Done tickets across all teams, groups by PDCR/Epic for impact-focused summary, interviews author for refinements, publishes to Confluence.

**Parent page:** `2316402689` (ROI Product & Engineering Updates)
**Naming:** `YYYY-MM-DD [Sprint] Update`

---

## Workflow

### Step 1: Sprint Resolution

If sprint not provided, detect active sprint from board 389:
```bash
acli jira board list-sprints --id 389 --state active
```

Confirm: "Generate digest for **[Sprint Name]** ([Start] → [End])?"

Capture `sprint_id`, `sprint_start`, `sprint_end` for queries.

### Step 2: Data Pull

Pull Done tickets for the sprint across all teams (exclude newfire):

```bash
source scripts/jira-lib.sh

# All Done tickets in sprint
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/search/jql" \
  -d '{
    "jql": "sprint = SPRINT_ID AND status = Done AND project in (HEAL, HSA, ROIP, ROIO, PDC)",
    "fields": ["key", "summary", "issuetype", "parent", "customfield_10014", "customfield_10910", "labels"],
    "maxResults": 200
  }'
```

Also pull:
- **Blocked tickets** (for Watch section)
- **Future sprint tickets** (for Looking Ahead)
- **AugEng epic tickets** (for AI Corner, if exists)

### Step 3: Group by PDCR/Epic

Organize Done tickets:
1. Find parent Epic for each ticket
2. Find PDCR linked to each Epic (via `60 Implementation` link)
3. Group: PDCR → Epic → Tickets
4. Assign to team based on `Team(s)` field or label

**Team mapping from config:**
- Platform: `HealthSource`
- ROIP 1/2: `ROIP 1`, `ROIP 2`
- Intake & Logging: `Intake & Logging` or `roi-intake-logging`
- Fulfillment & QC: `Fulfillment & QC` or `roi-fulfillment-qc`
- Digital Workflows: `Digital Workflows` (project PDC)

### Step 4: Draft Sections

Generate initial drafts for each section:

#### Headlines (Shipped / Watch)
- **Shipped:** Top 3-5 impact items from Done tickets (epic-level summaries)
- **Watch:** Any blocked tickets, incidents, or risks

#### Shipped by Team
For each team with activity:
```markdown
### [Team Name]

* [Epic/PDCR summary]: [brief description] ([TICKET-1](link), [TICKET-2](link))
* [Another epic]: [description] ([TICKET-3](link))
```

Summarize related tickets into single impact lines.

#### Looking Ahead
Pull from future sprint:
```bash
acli jira board list-sprints --id 389 --state future
# Then get tickets from first future sprint
```

Draft:
- **Next sprint focus:** Top items from future sprint backlog
- **Heads up:** (populated during interview)

#### AI Corner (if AugEng epic has Done tickets)
Draft from any Done tickets in Augmented Engineering epic.

### Step 5: Interview

Ask questions ONE AT A TIME using AskUserQuestion tool.

**Q1 - Headlines (required)**
Show draft Headlines, ask:
"Here's the draft Headlines:

**Shipped:** [draft]
**Watch:** [draft]

Edit, accept, or provide replacement?"

**Q2 - Shipped by Team (required)**
For each team with activity, show grouped draft:
"**[Team]** shipped items:
[draft bullets]

Refine wording? Highlight specific tickets? (Enter to accept)"

**Q3 - Initiative Spotlight (optional)**
"Spotlight an initiative this sprint? (Enter to skip)"
- If yes, ask which PDCR/topic and what to highlight

**Q4 - Team Wins (optional)**
"Any team wins? (new hires, shoutouts, milestones - Enter to skip)"

**Q5 - AI Corner (optional)**
If AugEng tickets found, show draft:
"AI Corner draft from AugEng epic:
[draft]

Add un-ticketed highlights? Edit? (Enter to skip section entirely)"

If no tickets: "Anything for AI Corner? (Enter to skip)"

**Q6 - Looking Ahead (required)**
Show draft from future sprint:
"**Next sprint focus:**
[draft from backlog]

**Heads up:**
[empty]

Add/edit focus items? Any heads-ups to include?"

**Q7 - Demo Link (optional)**
"Demo recording link? (Enter to skip, can add post-publish)"

### Step 6: Generate Final Draft

Assemble the digest with new layout:

**Section order:**
1. Headlines (with jump link to details)
2. Spotlight + AI Corner (two-column table)
3. Shipped by Team (details)
4. Looking Ahead

```markdown
### **[Sprint] | [Start Date] - [End Date], [Year]**

[Demo link if provided]

---

The Headlines
-------------

**Shipped:** [items]

**Watch:** [items]

[→ Jump to details](#shipped-by-team)

---

| Initiative Spotlight | AI Corner |
|---------------------|-----------|
| **[Title]** | **[Topic]** |
| [Content or "Coming Soon"] | [Content or skip] |

---

Shipped by Team
---------------

### [Team 1]

* [Impact line with ticket links]
* [Another impact line]

### [Team 2]

* [Impact lines...]

---

Looking Ahead
-------------

**Next sprint focus:**

* [Items]

**Heads up:**

* [Items]

---

*Questions? Concerns? Kudos? Reply or find us in #roi-zone-public*

\- John
```

**Notes:**
- Two-column layout uses markdown table for Spotlight + AI Corner
- Headlines includes anchor link `[→ Jump to details](#shipped-by-team)`
- Team Wins section removed (fold into Headlines or skip)
- Shipped by Team section has anchor `{#shipped-by-team}` for jump link

### Step 7: Review & Publish

Show complete draft and ask:
"Publish options:
1) Approve & publish to Confluence
2) Edit first, then publish
3) Save locally (you publish manually)

Choice?"

**If publish:**
- Create page under `2316402689`
- Title: `YYYY-MM-DD [Sprint] Update`
- Use `atlas_doc_format` (ADF) for new editor compatibility

**If save locally:**
- Save to `jira-data/drafts/sprint-digest-[sprint].md`

After publish: "Add demo recording link now? (Enter to skip)"

---

## Config Reference

Teams/pods from `jira-data/config.yaml`:

```yaml
teams:
  platform, healthsource-app, roio, roip, digital-workflows
  # skip: newfire

pods:
  intake-logging, roip-pod1, roip-pod2, fulfillment-qc
```

**Team(s) field:** `customfield_10910`

---

## JQL Patterns

```bash
# Done in sprint (all projects)
'sprint = SPRINT_ID AND status = Done AND project in (HEAL, HSA, ROIP, ROIO, PDC)'

# Blocked tickets
'sprint = SPRINT_ID AND status = Blocked'

# Future sprint items
'sprint = FUTURE_SPRINT_ID ORDER BY priority DESC'

# AugEng epic tickets
'parent = AUGENG_EPIC_KEY AND status = Done AND sprint = SPRINT_ID'
```

---

## Example Output

See: [2026-01-12 Q1.S0 Update](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2316271619)
