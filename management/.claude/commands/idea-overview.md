# Idea Overview

Generate a comprehensive overview of a PDCR Idea with all linked epics and tickets, formatted for Confluence.

## Usage

```
/idea-overview PDCR-XXX
```

Or describe the idea if you don't know the key:
```
/idea-overview database migration
```

## Workflow

### 1. Find the Idea
```bash
acli jira workitem view PDCR-XXX
```

Or search:
```bash
acli jira workitem search --jql 'project = PDCR AND summary ~ "keyword"' --fields "key,summary,status" --csv
```

### 2. Check Existing Links
```bash
source scripts/jira-lib.sh
curl -s -X GET -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/PDCR-XXX?fields=issuelinks" | jq -r '.fields.issuelinks[] | "\(.type.name): \(.outwardIssue.key // .inwardIssue.key)"'
```

### 3. Find Implementing Epics
If not linked, search by naming convention or labels:
```bash
# By project (ROIP, HEAL, PDC)
acli jira workitem search --jql 'project = ROIP AND issuetype = Epic AND summary ~ "keyword"' --fields "key,summary,status" --csv

# By label
acli jira workitem search --jql 'project = ROIP AND issuetype = Epic AND labels = "roi-platform"' --fields "key,summary,status" --csv
```

### 4. Get Tickets Under Epics
```bash
acli jira workitem search --jql '"Epic Link" in (ROIP-XXX, ROIP-YYY)' --fields "key,summary,status,issuetype" --csv
```

### 5. Link Epics to Idea (if not already linked)
```bash
source scripts/jira-lib.sh
curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issueLink" \
  -d '{"type":{"name":"60 Implementation"},"inwardIssue":{"key":"PDCR-XXX"},"outwardIssue":{"key":"ROIP-YYY"}}'
```

### 6. Label Everything
Add consistent label to all epics and tickets:
```bash
curl -s -X PUT -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/rest/api/3/issue/ROIP-XXX" \
  -d '{"update":{"labels":[{"add":"roi-platform"}]}}'
```

### 7. Generate Markdown Overview
Create file at `context/pdcr-XXX-slug.md` with:

1. **Header** - Idea link, status, label
2. **Scope** - From idea description
3. **Epic Overview Table** - Rollup of done/in-flight/to-do per epic
4. **Epic Details** - Per-epic ticket tables with status icons
5. **Summary Metrics** - Total counts and percentages
6. **Active Work** - Currently in-progress items
7. **Blockers** - Blocked items needing attention
8. **Execution Order** - Recommended sequence (optional)

## Output Template

```markdown
# PDCR-XXX: [Title]

**Idea:** [PDCR-XXX](https://datavant.atlassian.net/browse/PDCR-XXX)
**Status:** [Status]
**Label:** `label-name`

## Scope
[From idea description]

---

## Epic Overview

| Epic | Summary | Done | In Flight | To Do | Blocked |
|------|---------|------|-----------|-------|---------|
| [ROIP-XXX](link) | Title | X | X | X | X |

---

## Epic Details

### ROIP-XXX: [Title]

| Status | Key | Summary |
|--------|-----|---------|
| :white_check_mark: Done | [ROIP-YYY](link) | Summary |
| :arrow_forward: In Progress | [ROIP-ZZZ](link) | Summary |
| :hourglass: To Do | [ROIP-AAA](link) | Summary |
| :x: Blocked | [ROIP-BBB](link) | Summary |

---

## Summary

| Metric | Count |
|--------|-------|
| Total Epics | X |
| Total Tickets | X |
| Done | X (XX%) |
| In Flight | X (XX%) |
| To Do | X (XX%) |
| Blocked | X (XX%) |

### Active Work
[Table of in-progress items]

### Blockers
[Table of blocked items with reasons]

---

*Last updated: YYYY-MM-DD*
```

## Status Icons for Confluence

| Status | Emoji | Confluence |
|--------|-------|------------|
| Done | :white_check_mark: | ✅ |
| In Progress | :arrow_forward: | ▶️ |
| Code Review | :arrows_counterclockwise: | 🔄 |
| To Do | :hourglass: | ⏳ |
| Blocked | :x: | ❌ |
| Won't Do | :no_entry_sign: | 🚫 |

## Tips

- Always check for existing links before creating new ones
- Use consistent labels across epics and tickets for filtering
- Group epics by execution order when there are dependencies
- Highlight blockers prominently - these need attention
- Update the "Last updated" date when regenerating
