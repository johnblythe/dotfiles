# Jim's Claude Code Config

## Who I Am
PM on HealthSource. Goal: technical PM who can explore data, read code, and walk into conversations already close to root cause.

## Repos
- **HealthSource app**: `~/code/healthsource` — main Java/Spring codebase
- **Scripts**: `~/code/healthsource-scripts` — deploy scripts, tooling
- **Data Warehouse**: `~/code/data-warehouse` — dbt models, Snowflake transformations

Search, grep, read any file in these repos freely. No need to ask.

## Snowflake
- CLI: `/Applications/SnowSQL.app/Contents/MacOS/snowsql -c datavant`
- DB: `HEALTHSOURCE`, Schema: `CONNEX`, Role: `ENG_PROVIDER`
- SSO re-authenticates each invocation (browser popup)
- **Schema reference**: `~/code/management/projects/telemetry-deck/SCHEMA.md`
- **dbt models**: `~/code/data-warehouse/data_model/models/staging/healthsource/`
- **Column gotchas**: audit trail uses `EVENT_DT` not audit_timestamp, `AUDIT_MESSAGE` not audit_description; exception uses `EXCEPTION_REASON_ID` FK not text; site is `DDS_SITE_ID` not site_id
- `!=` in inline snowsql queries fails (shell parsing). Write SQL to a temp file and use `-f filename.sql` instead.

**Always show me the SQL you generate** — I want to learn the patterns.

## Jira
Auth handled by Atlassian MCP server automatically.

### Our Projects
| Project | Key | Description |
|---------|-----|-------------|
| HealthSource Engineering | HEAL | Main engineering tickets, sprints |
| HealthSource App | HSA | Application-specific work |
| ROI Platform | ROIP | Platform/infrastructure work |
| ROI Operations | ROIO | Operational tasks |
| Product Delivery | PDCR | Ideas, PRDs, product planning |

### Key Fields
- **Story Points**: `customfield_10026` (JQL: `"Story Points[Number]"`)
- **Epic Link**: `customfield_10014`
- **Sprint**: `customfield_10020`

### Teams
| Team | Field Value |
|------|-------------|
| HealthSource | (parent/default) |
| ROIP 1 | roi-platform |
| ROIP 2 | roi-platform |
| Intake & Logging | roi-intake-logging |
| Fulfillment & QC | roi-fulfillment |

### Common JQL
```
# My open tickets
assignee = currentUser() AND status != Done

# Sprint work missing points
project = HEAL AND sprint in openSprints() AND "Story Points[Number]" is EMPTY

# Stale in-progress
project = HEAL AND status = "In Progress" AND updated < -5d

# Everything in an epic
"Epic Link" = HEAL-XXXX ORDER BY status
```

## HealthSource Reference
- **User Manual**: `~/Downloads/HealthSource_User_Manual_6.13.22__1_.pdf` (184 pages)
- **PRDs/Ideas**: `~/code/management/ideas/` (PDCR PDFs)
- **Architecture notes**: `~/code/management/CLAUDE.md` (PDCR-404 search, PDCR-167 pre-fulfillment, PDCR-422 telemetry, etc.)

## What You Can Do

### Ask the Code Questions
Just ask. "What does the fulfillment workflow do?" "Where does site selection happen?" "How does the intake service route requests?" — I'll search the codebase and explain in plain English with file references.

### Explore Snowflake
Use `/snowflake-explorer` for guided exploration, or just ask questions like "how many requests were created last week?" and I'll generate + run the SQL and show you the results alongside the query.

### Jira & Reporting
- `/create-ticket` — describe what you need, handles all Jira ceremony
- `/sprint-digest` — auto-generate stakeholder sprint updates
- `/project-status-update` — project running-log entries
- `/executive` — high-level stakeholder summary
- `/idea-overview PDCR-XXX` — full overview of a PDCR idea with linked epics
- `/idea-pulse PDCR-XXX` — weekly movement/activity for an idea
- `/risks` — surface risks across the portfolio
- `/portfolio` — cross-initiative status view
- `/hygiene` — sprint hygiene audit

### Shape & Deepen Ideas
- `/shaping` — structured problem definition + solution options (requirements, shapes, fit checks)
- Ask me to **brainstorm** before jumping to solutions — explore the problem space first
- Ask me to **write a plan** from a spec — structured implementation breakdown
- `/breadboarding` — map existing systems or design new workflows as affordance tables

### Benchmark & Research
- `/benchmark` — "is our approach standard?" → web research → comparison table with sources
- Ask any "how does the industry do X?" question — I'll search, compare, and cite

### Visualize & Prove Out Ideas
Ask me to create:
- **ASCII diagrams** — quick system sketches inline
- **Mermaid charts** — flowcharts, sequence diagrams, entity relationships
- **HTML playground files** — interactive proofs-of-concept you can open in a browser (like dashboards, data viz, workflow mockups)

These are great for walking into a meeting with something tangible instead of just words.

### Summarize Anything
Paste a Slack thread, email chain, meeting notes, or messy doc and ask me to turn it into:
- A Jira comment
- Leadership bullet points
- A Confluence-ready summary
- A structured brief with risks/blockers/decisions extracted

## Conventions
- Be direct. Skip pleasantries.
- Show your work — especially SQL and file references.
- When I ask "why does X happen?" — trace the code path, don't speculate.
- Default to read-only for Snowflake. Never run DDL/DML.
