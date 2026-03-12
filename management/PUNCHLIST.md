# Finish Strong — Punch List
**Timeline**: Mar 4 – Mar 21 (~2.5 weeks)

---

## Week 1 (Mar 4–7)

### 0. Hiring (Done / In Flight)
- [x] **EM for Digital Workflows** — hired
- [x] **P3 backfill (Gene's role, Digital Workflows)** — hired, starts 3/16
- [x] **P5 backfill (open since Jan)** — offer made, starts 4/16
- EM starts 4/13
- **Implication**: P3 arrives with ~5 days of your overlap. EM and P5 arrive after you're gone — onboarding docs are critical.

### 1. Ted Reviews
- [ ] Draft reviews for all direct reports
- [ ] Calibrate ratings / identify themes
- [ ] Submit / deliver reviews
- **Notes**: _List names here as you go_

### 2. Q2 Planning — Platform
- [ ] Finalize `scratchpad/q2-platform-hypotheses-blended.md` (10 hypotheses drafted)
- [ ] Prioritize / stack-rank for capacity — what fits, what's stretch
- [ ] Identify TLs per initiative
- [ ] Write sprint-level guidance for Q2.S0–S1 (first 2 sprints)
- **Existing work**: hypotheses doc is solid; needs sizing + sequencing pass

### 3. Q2 Planning — Digital
- [ ] Draft equivalent Q2 guidance for Digital team
- [ ] Identify key initiatives and TL assignments
- [ ] Sprint-level guidance for Q2.S0–S1

---

## Week 2 (Mar 10–14)

### 4. Onboarding Docs
- [ ] **New P5** — role expectations, current initiatives, key contacts, tools
- [ ] **New P3** — same structure, team-specific context
- [ ] **New EM** — org context, team dynamics, process docs, where things live
- [ ] Link to existing Confluence (Teams page, Systems page) where possible
- [ ] Include "first 30 days" suggested focus areas for each

### 5. TL Best Practices & Q2 Assignments
- [ ] Document TL expectations (what "good" looks like)
- [ ] Review Q1 TL assignments — who stays, who rotates
- [ ] Propose Q2 TL roster for both teams
- [ ] Get alignment with EM / leadership

### 6. PR Hygiene Resolution
- [ ] Finalize `ideas/pr-hygiene-proposal.md` (comprehensive draft exists)
- [ ] Decide: what can be implemented NOW vs handed off
- [ ] Implement quick wins (Dependabot auto-merge, stale PR action, PR template)
- [ ] Write CODEOWNERS file (or draft + hand off)
- [ ] Socialize with team — get buy-in on lifecycle rules
- **Existing work**: full proposal with implementation roadmap ready

---

## Week 2–3 (Mar 14–21)

### 7. 2026+ Vision Document
- [ ] Synthesize from: Q2 hypotheses, deep plans, telemetry insights, architecture notes
- [ ] Frame as "where we're headed" — themes, not tasks
- [ ] Include: file management, PDF capabilities, DB domain separation, observability maturity
- [ ] Make it useful for the new EM and incoming leadership
- [ ] Publish to Confluence (Initiatives section)

### 8. Deep Plans (Feed into Vision)
- [ ] **File Management** — CDR migration path, service-by-service plan (extends PDCR-414)
- [ ] **PDF Capabilities** — current state, domain isolation, processing improvements
- [ ] **Database Domain Registry** — continuation of Q1 audit-log split pattern, candidate domains
- [ ] Each plan: problem statement, current state, target state, sequencing, risks
- **Existing work**: `q2-platform-hypotheses-blended.md` has framing for all three

### 9. Datadog Monitoring Coverage
- [ ] Run `/observability-review` to get current scorecard
- [ ] Identify top coverage gaps
- [ ] Create monitors or Terraform entries for highest-priority gaps
- [ ] Document monitoring philosophy / gap-fill approach for successor
- **Existing work**: observability-review skill, monitoring-gap skill, alert-triage skill all available

---

## Showcase / Portfolio Projects

### 10. Deploy Night Light (Overnight Agent)
- [ ] Get cron running nightly (6am via `scripts/cron-night-light.sh`)
- [ ] Validate `dd.py` anomaly detection still works end-to-end
- [ ] Run a few live (non-dry-run) cycles, verify Jira ticket creation
- [ ] Document results — at least 3-5 overnight runs with real findings
- **Existing work**: shell script, prompt, services.yaml, dry-run history all exist
- **Value**: proves autonomous overnight monitoring before you leave

### 11. Slack Bot — Q&A / Ticket Helper
- [ ] Define scope: Q&A about HS systems? Ticket creation? Status lookups? All three?
- [ ] Pick approach: Claude API + Slack Events API, or MCP-based
- [ ] MVP: respond to DMs or channel mentions with HS knowledge + Jira integration
- [ ] Stretch: ticket creation/update from Slack thread context
- [ ] Deploy somewhere it can run after you leave (or hand off runbook)

### 12. Automated TPM Agent — Jira/Confluence/Reporting
- [ ] Define recurring tasks: sprint hygiene, velocity reports, status updates, doc sync
- [ ] Wire up existing skills: `/hygiene`, `/velocity`, `/sprint-digest`, `/project-status-update`
- [ ] Schedule: daily hygiene check, weekly velocity + sprint digest, bi-weekly status report
- [ ] Output: Confluence page updates and/or Slack posts
- [ ] Package as cron jobs or persistent agent loop

### 15. HealthSource Changelog Automation
- [ ] Define what "changelog" means here: per-release? per-sprint? per-service?
- [ ] Script: pull merged PRs from HealthSource repo since last tag/date, format as changelog
- [ ] Categorize entries (feature, bugfix, infra, security, deps) — auto-label from PR labels or commit prefixes
- [ ] Output: markdown changelog committed to repo or posted to Confluence
- [ ] Automate: GitHub Action on release/tag or scheduled weekly
- [ ] **Brett asked for this** — leave it working before you go
- **Approach**: `gh pr list --state merged --base main --json title,labels,mergedAt,number` + formatting script

---

## Repo Cleanup & Portfolio

### 13. Sanitize Management Repo for Personal GitHub
- [ ] Audit for sensitive data: names, credentials, org-specific config
- [ ] Update `.gitignore` — add: `jira-data/snapshots/`, `jira-data/trends/`, `jira-data/config.yaml`
- [ ] Strip or genericize: CLAUDE.md Jira credentials references, board IDs, custom field IDs
- [ ] Remove or redact: any files with employee names, performance notes, griping
- [ ] Create a clean branch or fork for `johnblythe` personal account
- [ ] Push to personal GitHub as portfolio piece
- **Key dirs to audit**: `jira-data/`, `ideas/`, `scratchpad/`, `context/`, `interviews/`

### 14. Google Docs Audit & Protection
- [ ] Review all Google Docs/Sheets/Slides in work account
- [ ] Delete: anything with sensitive feedback, 1:1 notes, people complaints
- [ ] Transfer ownership or download: anything you want to keep for portfolio
- [ ] Check shared drives / team drives for docs you authored
- [ ] Clear Google Keep, Bookmarks, browser saved passwords if applicable
- **Rule of thumb**: if you wouldn't want your manager reading it aloud in a meeting, delete it

---

## Running Notes
_Use this section for daily progress, blockers, decisions_

### Mar 4

---

## Handoff Artifacts Checklist
When you're done, these should exist and be findable:
- [ ] Ted reviews submitted
- [ ] Q2 planning docs (both teams) in Confluence or management repo
- [ ] Onboarding docs for P5, P3, EM
- [ ] TL roster + best practices doc
- [ ] PR hygiene: implemented quick wins + documented roadmap
- [ ] 2026+ vision doc in Confluence
- [ ] Deep plans (file mgmt, PDF, DB domains) written up
- [ ] Monitoring coverage improved + documented
- [ ] Night Light running nightly with documented results
- [ ] Slack bot MVP deployed or runbook written
- [ ] TPM automation scheduled (hygiene, velocity, status reports)
- [ ] Management repo sanitized + pushed to personal GitHub
- [ ] Google Docs cleaned up
- [ ] HealthSource changelog automation running (Brett's ask)
