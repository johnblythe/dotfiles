# Project Status Update

Generate a sprint status entry for a project's Confluence running-log page.

## Overview

Pulls Jira data from PDCR hierarchy (PDCR → epics → tickets), auto-discovers PRs and new tickets, interviews the Project Lead for context, drafts the entry, and publishes after approval.

## Workflow

### Step 1: Project Resolution

If `$ARGUMENTS` provided, look up in `jira-data/config.yaml` projects section. Otherwise prompt:

"Which project? (Enter name from config or PDCR key like PDCR-294)"

If PDCR key given but not in config, ask for Confluence page ID.

### Step 2: Data Pull

1. Query PDCR ticket for linked epics (via `60 Implementation` link type)
2. For each epic, get child tickets with current status
3. Auto-detect active sprint from board 389
4. Calculate metrics:
   - Epic completion % (done / total)
   - Tickets by status: Done, In Progress, Code Review, UAT, Blocked, To Do
   - Story points if available (customfield_10026)

Present sprint detected and ask: "Report on [Sprint Name]? (or specify different sprint)"

Once sprint confirmed, capture `sprint_start_date` and `sprint_end_date` for subsequent queries.

### Step 2b: Discover PRs (Interview-based)

**Note:** GitHub search by ticket key is unreliable — PRs may not reference tickets in title/branch. Instead, ask the PL directly:

"Any PRs merged this sprint for this project? (Enter PR numbers or 'none')"

If PL provides PR numbers, fetch details:
```bash
gh pr view 1234 --repo datavant/healthsource --json number,title,url,mergedAt
```

Only include PRs that the PL confirms are relevant.

### Step 2c: Auto-discover New Tickets

Query for tickets created during the sprint:

```bash
# JQL: tickets in epic hierarchy created after sprint start
parent in (EPIC-1, EPIC-2) AND created >= "YYYY-MM-DD" ORDER BY created DESC
```

These go in the "New Tickets Created" section automatically.

### Step 3: Interview

Ask these questions ONE AT A TIME. Use AskUserQuestion tool.

**Q1 - Status (required)**
"Overall initiative health?"
- Options: 1) On Track, 2) At Risk, 3) Blocked
- Follow-up: "Any context to add?" (optional free text for the "because...")

**Q2 - TL;DR (required)**
Pre-generate a draft summary from ticket data, then ask:
"Here's a draft TL;DR based on ticket movement: [draft]. Edit or accept?"

**Q3 - Risks (optional)**
"Any risks or blockers not visible in Jira? (Enter to skip)"
- Hint: show any Blocked tickets as starting point

**Q4 - Scope (optional)**
"Scope changes since last update?"
- Options: 1) None, 2) Expanded, 3) Reduced
- If not None, ask for details

**Q5 - External deps (optional)**
"Waiting on other teams or external dependencies? (Enter to skip)"

**Q6 - Next milestone (optional)**
"What's the next key milestone?"

### Step 4: Generate Draft

Format the status update entry (matching DB Scaling format):

```markdown
---

## [Sprint Name] ([Start Date] → [End Date])

### TL;DR

[Status emoji + text: 🟢 On track / 🟡 At risk / 🔴 Blocked]

[Narrative summary paragraph]

---

#### Shipped ✅

* **[PR #1234](link):** Description of what shipped
* **[PR #1235](link):** Another PR description
* **Key improvements:** Summary bullets if multiple related PRs

---

| Status | Key | Summary | Notes |
|--------|-----|---------|-------|
| ✅ Done | [KEY](link) | Summary | PR #1234 merged |
| 🔄 In Progress | [KEY](link) | Summary | |
| 🔄 Code Review | [KEY](link) | Summary | PR #1236 open |
| ❌ Blocked | [KEY](link) | Summary | [reason] |

---

### Risks & Callouts

* [Risk items from interview]
* [External deps if any]

---

### New Tickets Created

* [KEY](link) - Summary (if any created during sprint)

```

**Status (with emoji):**
- 🟢 On track
- 🟡 At risk — [context]
- 🔴 Blocked — [context]

**Ticket status icons:**
- ✅ Done
- 🔄 In Progress / Code Review / UAT
- ❌ Blocked
- ⬚ To Do (omit unless specifically requested)

**Section rules:**
- **Shipped ✅**: Only include if PRs were merged. List PRs with descriptions.
- **New Tickets Created**: Only include if tickets created >= sprint_start_date. Auto-populated.
- **Risks & Callouts**: Only include if risks/deps provided in interview.

### Step 5: Review & Publish

Show draft and ask: "Publish to Confluence? (y/edit/n)"

- **y**: Prepend to the project's Confluence page (most recent at top)
- **edit**: Let PL make changes, then confirm again
- **n**: Save draft locally to `jira-data/drafts/[project]-[sprint].md`

After publish, update the "Last Updated" timestamp if the page has one.

## Config Reference

Projects defined in `jira-data/config.yaml`:

```yaml
projects:
  project-name:
    pdcr: PDCR-XXX           # Required: Idea ticket
    confluence_page_id: "123" # Required for auto-publish
    github_repo: "datavant/healthsource"  # Optional, defaults to datavant/healthsource
    description: "..."        # Optional
```

## Jira Queries

**Get epics linked to PDCR:**
Use `60 Implementation` link type - PDCR is inward, epics are outward.

**Get epic children:**
`parent = EPIC-KEY`

**Get new tickets (created during sprint):**
`parent in (EPIC-1, EPIC-2) AND created >= "YYYY-MM-DD"`

**Active sprint:**
`acli jira board list-sprints --id 389 --state active`

**Sprint date range:**
Parse from sprint object's startDate/endDate fields.

## GitHub Queries

**Find PRs by ticket key:**
```bash
gh pr list --repo datavant/healthsource --state merged --search "HEAL-1234" --json number,title,url,mergedAt
```

**Find PRs by date range:**
```bash
gh pr list --repo datavant/healthsource --state merged --json number,title,url,mergedAt,headRefName | \
  jq --arg start "2026-01-20" --arg end "2026-02-02" \
  '[.[] | select(.mergedAt >= $start and .mergedAt <= $end)]'
```

## Example Output

```markdown
---

## Q1.S1 (2026-01-17 → 2026-01-30)

### TL;DR

On track

QA01 backfill completed successfully (2021-05-10 to present, ~4.5 years). Performance optimizations shipped. Next: re-enable dual-write and final sync.

---

#### Shipped ✅

* **[PR #2407](https://github.com/datavant/healthsource/pull/2407):** Direct SQL sync, FDW optimizations, reporting index
* **[PR #2381](https://github.com/datavant/healthsource/pull/2381):** Workflow fixes + FDW/partitioning migrations
* **[PR #2363](https://github.com/datavant/healthsource/pull/2363):** Ext table hash verification, demo mode, progress UI
* **Key improvements:** FDW 10x faster, Direct SQL 50x faster, automated Slack notifications

---

| Status | Key | Summary | Notes |
|--------|-----|---------|-------|
| ✅ Done | [ROIP-403](https://datavant.atlassian.net/browse/ROIP-403) | Backfill: Backup + Script + Checksum | PR #2407 merged |
| ✅ Done | [ROIP-414](https://datavant.atlassian.net/browse/ROIP-414) | Deploy & Validate in Remote Env | QA01 backfill complete |
| 🔄 In Progress | [ROIP-401](https://datavant.atlassian.net/browse/ROIP-401) | FDW Query Path Wiring | PR #2258 ready, unblocked |

---

### Risks & Callouts

* Need to re-enable dual-write in QA01 after backfill
* Final sync required to catch up records written during backfill

---

### New Tickets Created

* [ROIP-423](https://datavant.atlassian.net/browse/ROIP-423) - Re-enable dual-write in QA01
* [ROIP-424](https://datavant.atlassian.net/browse/ROIP-424) - Run backfill in TRY
* [ROIP-425](https://datavant.atlassian.net/browse/ROIP-425) - Run backfill in PROD
* [ROIP-426](https://datavant.atlassian.net/browse/ROIP-426) - Final sync + cutover validation in QA01
```
