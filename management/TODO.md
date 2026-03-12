# Project TODOs & Enhancements

## Tooling / Workflow

### [ ] Add Confluence MCP Server (Official Atlassian)
**Priority:** High - simple setup, immediate value

```bash
claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse
```

- OAuth 2.0 flow, respects existing permissions
- [Official docs](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/setting-up-clients/)
- [GitHub](https://github.com/atlassian/atlassian-mcp-server)

### [ ] Add Google Docs MCP Server
**Priority:** High - more setup than Confluence

- Best option: [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp)
- Requires: Node 18+, Google Cloud Console OAuth credentials
- Features: Read/write/format docs, Drive file management, Sheets support

---

## Manager Wishlist

*Ranked by Impact × Complexity. 🟢 = quick wins, 🟡 = moderate effort, 🟠 = worth it but plan carefully, 🔴 = long-term/deprioritize*

### 🟢 Quick Wins (High Impact, Low Complexity)

| # | Item | Impact | Complexity |
|---|------|--------|------------|
| 1 | **Datadog analysis** - insights from metrics, logs, traces | HIGH | LOW |
| 2 | **Ticket creation from code** - explore code, discuss, generate tickets following conventions | HIGH | LOW |
| 3 | **Local dev health check** - "your setup is 3 versions behind, here's a fix script" | MED-HIGH | LOW |
| 4 | **Sprint pattern insights** - surface retro themes from velocity/completion data | MED | LOW |
| 5 | **DD alerts → tickets overnight** - alerts that fire while we sleep become tickets | HIGH | MED |
| 6 | **On-call handoff briefings** - auto-generated context for shift changes | MED-HIGH | LOW-MED |

### 🟡 Moderate Effort (Worth Doing)

| # | Item | Impact | Complexity |
|---|------|--------|------------|
| 7 | **Performance regression detection** - DD metrics trend analysis → tickets when p99 creeps | HIGH | MED |
| 8 | **Feature flag hygiene** - stale flags get cleanup tickets with removal PRs ready | MED | LOW-MED |
| 9 | **Incident postmortem drafts** - DD incidents auto-generate postmortem templates | MED | LOW-MED |
| 10 | **Dependency updates w/ context** - smarter than Dependabot, reads changelogs, flags breaking | MED-HIGH | MED |
| 11 | **PR auto-fix** - lint/format/type failures get fix PRs automatically | MED | MED |
| 12 | **Test flakiness quarantine** - auto-detect, quarantine, create fix tickets | MED-HIGH | MED |
| 13 | **Code review load balancing** - fair PR distribution based on capacity/expertise | MED | MED |
| 14 | **Environment drift checker** - staging/prod config parity alerts | MED | MED |
| 15 | **Cost anomaly alerts** - cloud spend spikes get investigated and ticketed | MED | MED |

### 🟠 High Value, High Effort (Plan Carefully)

| # | Item | Impact | Complexity |
|---|------|--------|------------|
| 16 | **Onboarding scavenger hunt** - 101/201/301 levels, Claude handholding, anchored to roadmap + DD hotspots | HIGH | HIGH |
| 17 | **Midnight snacks mode** - accumulated small improvements run overnight in batches | HIGH | HIGH |
| 18 | **DD alerts → tickets → PRs** (v2) - auto-fix PRs waiting for review | VERY HIGH | HIGH |
| 19 | **API contract testing** - breaking changes caught pre-deploy | HIGH | MED-HIGH |

### 🔴 Long-Term / Deprioritize

| # | Item | Impact | Complexity |
|---|------|--------|------------|
| 20 | **Security/CVE auto-remediation** - Wiz + Chainguard alerts solved automatically | HIGH | VERY HIGH |
| 21 | **Knowledge graph** - who owns what, who touched what, tribal knowledge capture | MED-HIGH | HIGH |
| 22 | **Runbook execution** - turn static runbooks into executable workflows | MED-HIGH | HIGH |
| 23 | **Tech debt tracking** - auto-detect and categorize, tie to business impact | MED | HIGH |
| 24 | **Doc drift detection** - code changes flag stale docs for update | LOW-MED | MED |

### In Progress

- [x] **Jira management TUI** - basic TUI exists, iterating
