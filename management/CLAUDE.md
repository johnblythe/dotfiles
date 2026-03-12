# Project Context

## Codebase
Primary codebase is at `~/code/healthsource`. Use search, grep, find, cat, etc. on that directory to understand technical details when discussing projects, sprints, or tickets.

## Conventions
- BC = Brett Clark's sprint estimates (vs original estimates)
- PDCR = Product Delivery Chart Retrieval (Jira project key)
- HealthSource = the main application
- Pods: Platform, KTLO, Intake & Logging, Fulfillment & QC, Newfire

### Our Team's Jira Projects
| Project | Key | Description |
|---------|-----|-------------|
| HealthSource Engineering | HEAL | Main engineering tickets, sprints |
| HealthSource App | HSA | Application-specific work |
| ROI Platform | ROIP | Platform/infrastructure work |
| ROI Operations | ROIO | Operational tasks |
| Product Delivery | PDCR | Ideas, PRDs, product planning |

Use these project keys to filter "our" tickets vs other teams.

## Commits
- Never include Claude attribution or co-authorship

---

## Jira

### Credentials
Stored in `~/.config/jiratui/config.yaml`. **acli reads these automatically** - no manual extraction needed.

⚠️ **Known Issue**: Shell parsing of sed commands for credential extraction fails in Claude sessions. Avoid inline credential parsing.

**Preferred approach**: Use `acli` commands directly (handles auth automatically):
```bash
acli jira workitem view PDCR-422
acli jira workitem search --jql 'project = HEAL' --csv
```

**For REST API** (when acli doesn't support aggregation): Use the helper script:
```bash
source scripts/jira-lib.sh  # Sets JIRA_USER, JIRA_TOKEN, JIRA_URL
```

### Boards
- HEAL board: ID 389

### Sprints (naming convention)
- Q4.S5, Q4.S6, Q1.S0, etc.
- Use `acli jira board list-sprints --id 389 --state "active,future"` to find sprint IDs

### Custom Fields
- **Story Points**: `customfield_10026` (JQL name: "Story Points[Number]")
- **Epic Link**: `customfield_10014`
- **Sprint**: `customfield_10020` (value must be numeric ID, e.g., `20662` — NOT `{"id": 20662}`)
- **Team(s)**: `customfield_10910` (JQL name: "Team(s)[Select List (multiple choices)]")

### Teams (replacing labels)
Use the Team(s) field instead of labels for team assignment. Available teams:
| Team | Replaces Label |
|------|----------------|
| HealthSource | (parent/default) |
| ROIP 1 | roi-platform |
| ROIP 2 | roi-platform |
| Intake & Logging | roi-intake-logging |
| Fulfillment & QC | roi-fulfillment |

**Note:** Labels like `roi-platform` are being deprecated in favor of Team(s) field.

---

## REST API v3 (Preferred for Aggregation)

The old GET `/rest/api/3/search` endpoint is **deprecated**. Use POST:

### Search with JQL
```bash
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/search/jql" \
  -d '{
    "jql": "project = HEAL AND sprint = 10733",
    "fields": ["key", "summary", "status", "customfield_10026"],
    "maxResults": 200
  }'
```

### Sum Story Points
```bash
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/search/jql" \
  -d '{"jql": "project = HEAL AND sprint = 10733 AND status = Done", "fields": ["customfield_10026"], "maxResults": 200}' | \
  jq '[.issues[].fields.customfield_10026 // 0] | add'
```

### Update Custom Fields
```bash
curl -s -X PUT \
  -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/HEAL-123" \
  -d '{"fields":{"customfield_10026":2}}'
```

---

## acli (Simple Queries/Transitions)

Good for: listing, searching (without aggregation), transitions, viewing tickets.

```bash
# List sprints
acli jira board list-sprints --id 389 --state "active,future"

# Get sprint items
acli jira sprint list-workitems --sprint SPRINT_ID --board 389 --paginate

# Search with JQL (returns list, not aggregates)
acli jira workitem search --jql 'project = HEAL AND sprint in openSprints() AND assignee is EMPTY' --fields "key,summary,status" --csv

# Transition ticket
acli jira workitem transition --key "HEAL-123" --status "In Progress"
```

**Limitation:** `--fields` flag doesn't support custom fields. For story points, use REST API.

---

## Creating Epics & Linking

### Required Fields for Epics
Epics in HEAL project require the **Capitalize** field:
- Field ID: `customfield_12467`
- Value: `{"id": "15142"}` (Yes)

### Epic Creation via REST API
```bash
# Write JSON to file (avoids shell parsing issues)
cat > /tmp/epic.json << 'EOF'
{
  "fields": {
    "project": {"key": "HEAL"},
    "summary": "Epic Title",
    "description": {"type": "doc", "version": 1, "content": [...]},
    "issuetype": {"name": "Epic"},
    "labels": ["roi-platform"],
    "customfield_12467": {"id": "15142"}
  }
}
EOF

# Create via REST
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue" \
  -d @/tmp/epic.json
```

### Issue Link Types (Common)

**Use full names** — the API requires exact match including parenthetical suffixes.

| Short Name | Full API Name | Outward | Inward |
|------------|---------------|---------|--------|
| Relates | `01 Relates To (Named 01 to be at top of list for generic linking)` | relates to | relates to |
| Blocks | `20 Blocks` | blocks | is blocked by |
| Implementation | `60 Implementation` | implements | is implemented by |
| Parent Child | `99 Parent Child (this is a legacy workaround to force level 0s under level 0s. Many defended to save it.)` | is a child of | is a parent of |

**Tip**: Use MCP `jira_create_issue_link` tool — it handles the full names cleanly. REST API requires exact string match.

### Linking Epic to Idea (PDCR)
```bash
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issueLink" \
  -d '{
    "type": {"name": "60 Implementation"},
    "inwardIssue": {"key": "PDCR-404"},
    "outwardIssue": {"key": "HEAL-1336"}
  }'
```

---

## Spike Ticket Format

Use type `Spike` for investigation/discovery work. Follow Jira style guide (`references/jira-style-guide.pdf`).

**Formatting rules:**
- NO "Description" header - start directly with opening paragraph
- Use `###` for section headers (Problem Statement, Scope, AC, Artifacts)

### Structure
```markdown
[Opening paragraph - what we're investigating and why]

### Problem Statement
[User-facing pain points being addressed]

### Scope
[Specific investigation activities]

### Acceptance Criteria
[Concrete deliverables - AC Razor: can someone else understand DONE?]

### Artifacts
[Relevant code paths, support tickets, docs]
```

### Example Spike (2 pts)
**Summary:** Investigate site selection performance bottlenecks

Investigate root causes of site selection slowdowns reported during user shadows.

### Problem Statement
Users experience freezing and slowdowns when:
- Opening request search window from dashboard
- Having a single site assigned (30-40s load; workaround is adding demo site)

### Scope
- Profile site dropdown population API call
- Trace single-site user query path in RequestSearchDataMapper.xml
- Document query explain plans for representative scenarios

### Acceptance Criteria
- Site dropdown API profiled: response size and latency documented
- Single-site bug root cause identified
- Recommendation doc with fix options and effort estimates

### Artifacts
- Code: eipservices/.../RequestSearchDataMapper.xml

### Spike Sizing
- **2 pts** = Standard investigation (profile, analyze, recommend)
- **3 pts** = Investigation + prototype/PoC
- **4 pts** = Multi-system investigation or complex PoC (break down if possible)

---

## Jira Hygiene Tools

### Directory Structure
```
management/
├── jira-data/
│   ├── config.yaml              # Thresholds, team configs
│   ├── snapshots/               # Point-in-time reports
│   │   ├── YYYY-MM-DD-hygiene.md
│   │   └── YYYY-MM-DD-velocity.md
│   └── trends/
│       └── velocity.csv         # Historical data
├── scripts/
│   └── jira-velocity.sh         # Velocity calculator (REST API)
└── jira-hygiene-TODO.md         # Task tracking
```

### Commands
- `/hygiene` - Audit sprint for violations (missing points, stale items, unassigned)
- `/velocity` - Sprint velocity report (run `scripts/jira-velocity.sh`)

### Q4 Sprint IDs
| Sprint | ID |
|--------|-----|
| Q4.S0 | 9040 |
| Q4.S1 | 9110 |
| Q4.S2 | 10474 |
| Q4.S3 | 10731 |
| Q4.S4 | 10732 |
| Q4.S5 | 10733 |
| Q4.S6 | 11870 (active) |
| Q1.S0 | 13686 (future) |

---

## Common JQL Patterns

```bash
# Missing story points in sprint
'project = HEAL AND sprint in openSprints() AND "Story Points[Number]" is EMPTY AND issuetype in (Story, Task, Bug)'

# Stale In Progress (>5 days)
'project = HEAL AND status = "In Progress" AND updated < -5d'

# Unassigned in sprint
'project = HEAL AND sprint in openSprints() AND assignee is EMPTY'

# Done in specific sprint
'project = HEAL AND sprint = 10733 AND status = Done'
```

---

## Product Planning & Documentation

### Directory Structure
```
management/
├── ideas/                        # PDCR PRD documents (PDFs)
│   ├── _pdcr-167.pdf            # Pre-Fulfillment Review Framework
│   ├── _pdcr-404.pdf            # Search Speed Optimization
│   ├── _pdcr-406.pdf            # Intake Acceleration
│   ├── _pdcr-411.pdf            # Pull List Option
│   ├── _pdcr-422.pdf            # Event-based Logging
│   └── _bc-418.pdf              # Payment Integrity MVP (Business Case)
├── references/                   # Templates and reference docs
│   └── ROI Product_Tech Documentation Templates.pdf
└── TODO.md                       # Project enhancement tracking
```

### PRD/Tech Spec Template
Use `references/ROI Product_Tech Documentation Templates.pdf` when:
- Writing new PRDs or evaluating PRD completeness
- Creating tech specs for features
- Discussing "how should we document X" or "use our template for Y"

**Template Structure:**
1. **Research & Discovery** - Executive summary, opportunity, personas, discovery plan
2. **Product Spec** - Opportunity, scope, acceptance criteria, risks, data plan
3. **Tech Spec** - System context, design goals, architecture, size estimate, confidence, risks, rollout, security, monitoring, testing, dependencies
4. **Release Strategy** - Maturity levels (Experiment → Alpha → Beta → GA), toggles, iterations

### Key Process Notes
- **CASTLE**: Security review process. Tyler Beach must attend kickoff meetings.
- **Maturity Levels**: Experiment (<5 customers) → Alpha (10) → Beta (100) → GA (all)
- **Feature Toggles**: Should be labeled with ticket numbers for manageability

### When Discussing PDCR Ideas
- Fetch via: `acli jira workitem view PDCR-XXX`
- PRD PDFs are in `ideas/` directory
- Compare against template sections to identify gaps
- Tech specs are often empty - that's where engineering input is needed

---

## HealthSource Architecture (Q1 2026 Planning)

### PDCR-404: Search (services/searchservices/)
**Current**: MyBatis DAO → SQL queries (no Elasticsearch)
- Key config: `SearchServiceConfig.java` (limits, timeouts)
- Endpoints: `RequestSearchWebServiceV3`, `V4`
- Bottleneck: SQL on relational DB
- **Optimization paths**: Read replicas, Elasticsearch, Redis cache, query optimization

### PDCR-167: Pre-Fulfillment Review (services/workflow/)
**Hook point**: `PreFulfillmentApprovalRuleDelegate.java`
- Workflow: `fulfillment-subprocess.bpmn`
- Add new status: `AWAITING_PRE_FULFILLMENT_REVIEW` in `RequestStatus.java`
- Queue mgmt: `QueueServiceImpl`
- Config: `WorkflowConfigServiceImpl`
- Pattern: Camunda delegate + reservoir sampling

### PDCR-422: Event Telemetry (services/platformservices/)
**Existing**: `statusEvent/StatusEvent.java` - workflow status only
- Event handler: `EventHandler.java` (workflow events)
- Task events: `TaskEventData`, `TaskEventRequest`
- **Gap**: No time-on-task, no Kafka/Snowflake pipeline
- **New**: Event schema, Kafka producer, frontend SDK, Snowflake ingestion

### PDCR-411: Pull List Option (services/intakeservices/)
**Goal**: "This is a Pull List" toggle on print/scan/upload screens
- Bypasses STORK classification when checked
- Routes directly to Pull List queue
- **Tech needs**: Intake UI mods, routing bypass logic, audit logging

### PDCR-406: Intake Acceleration (platform performance)
**Goal**: Hours → minutes for e-request ID creation
- Extends Q3 fax/email work to upload/print paths
- DataDog telemetry with p95/p99 SLA alerts
- **Synergy**: Overlaps with PDCR-422 telemetry work

### PDCR-418: Payment Integrity MVP ⭐ TIER 1
**Type**: Business Case (Payer vertical collaboration)
**HealthSource scope**: 2 Eng FTE allocated
- Support PI request type + TAT handling
- Approval queue for Payment Integrity requests
- Integration with Payer's pre-match API
- **Different doc format** - not standard PRD template

---

## Confluence

### Space & Key Pages
- **Space Key**: `HealthSour`
- **Space ID**: `948109388`
- **Homepage ID**: `948109689`
- **Base URL**: `https://datavant.atlassian.net/wiki`

### Information Architecture
| Section | Page ID | Purpose |
|---------|---------|---------|
| 🏠 Teams | 2305720344 | Who we are, ways of working (sprints, estimates, leads) |
| 🚀 Initiatives | 2306703366 | Active projects/ideas |
| 🔧 Systems | 2306637848 | Templates, how-tos, architecture, ADRs |
| 🚨 Operations | 2306637867 | On-call, incidents, audits, compliance |
| 📦 Archives | 2306277392 | Historical/deprecated |
| 📣 Updates | 2316402689 | Stakeholder newsletters |

### API Patterns

⚠️ **Use `atlas_doc_format` (ADF) NOT `storage`** - `storage` format creates legacy pages that prompt users to convert.

```bash
# Create page (NEW EDITOR - use atlas_doc_format)
cat > /tmp/page.json << 'EOF'
{
  "spaceId": "948109388",
  "status": "current",
  "title": "Page Title",
  "parentId": "PARENT_PAGE_ID",
  "body": {
    "representation": "atlas_doc_format",
    "value": "{\"version\":1,\"type\":\"doc\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":\"Hello world\"}]}]}"
  }
}
EOF

curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/wiki/api/v2/pages" \
  -d @/tmp/page.json

# Move page (update ancestor)
curl -s -X PUT -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/wiki/rest/api/content/{pageId}" \
  -d '{"version":{"number":N+1},"ancestors":[{"id":"newParentId"}],"type":"page","title":"Title"}'

# Get page children
curl -s -X GET "${JIRA_URL}/wiki/rest/api/content/{pageId}/child/page?limit=50"
```

**ADF Quick Reference:**
- Paragraph: `{"type":"paragraph","content":[{"type":"text","text":"..."}]}`
- Heading: `{"type":"heading","attrs":{"level":2},"content":[{"type":"text","text":"..."}]}`
- Bullet list: `{"type":"bulletList","content":[{"type":"listItem","content":[...]}]}`
- Bold: `{"type":"text","text":"...","marks":[{"type":"strong"}]}`
- Link: `{"type":"text","text":"...","marks":[{"type":"link","attrs":{"href":"url"}}]}`

### Terminology
- **Idea** = PDCR ticket (product planning artifact)
- Use interchangeably with "PDCR"

### AI Workflow Documentation
Parent page: [AI Think, Therefore AI Am](https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/2294775821)

Structure:
```
AI Think, Therefore AI Am
├── 📚 Examples & Idea Generation (2506686474)
│   └── [Case study child pages]
├── 🎓 AgEng Upskilling (2485256263)
└── 🧰 Toolbox (2506097052)
    └── Night Light (2294185998)
```

---

## AI Workflow Case Studies

When documenting AI-assisted workflows for the team, create child pages under `📚 Examples & Idea Generation`.

### Formatting Rules
- Use fenced code blocks (triple backticks) with language hints, NOT inline code
- Keep case studies as separate child pages, not embedded in parent
- Include Resources Used section at bottom of every case study

### Case Study Structure
```markdown
# [Descriptive Title] Case Study

**Date:** [Date]
**Participants:** [Human + AI tool]
**Artifacts:** [Links to PR, ticket, etc.]

---

## 🔥 The Incident/Problem
[What happened, timeline if relevant]

## 🎯 The Goal
[Numbered list of objectives]

## 🤖 The AI Workflow
### Step 1: [Phase name] (Human/AI)
[Details with code blocks]
### Step 2: ...

## 📊 Division of Labor
| Step | Human | AI |
|------|:-----:|:--:|
| ... | ✅ | |
| ... | | ✅ |

## 🎁 Artifacts Produced
| Type | Link | Notes |
|------|------|-------|

## 🔑 Key Takeaways
[Numbered insights]

## 🔁 Replication Checklist
- [ ] Step 1
- [ ] Step 2

---

## 🛠️ Resources Used

### Tools & Integrations
| Resource | Purpose | Link |
|----------|---------|------|
| Atlassian MCP | Jira/Confluence via MCP | [mcp-atlassian](https://github.com/sooperset/mcp-atlassian) |
| GitHub CLI | PR creation | [cli.github.com](https://cli.github.com/) |

### Code References
| File | Location |
|------|----------|

### Related Documentation
- [External links]
```
