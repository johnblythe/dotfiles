# Changelog

All notable changes to the Jira management tooling will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-06

### Added
- **Product Planning Docs** (`ideas/`, `references/`)
  - PDCR PRD documents: 167, 404, 406, 411, 422, BC-418
  - Jira style guide, PR review guide, tech spec templates
  - Athena project docs

- **CLAUDE.md - Epic & Spike Guides**
  - Epic creation via REST API with required fields (Capitalize)
  - Issue link types reference (Relates, Blocks, Implementation, Parent-Child)
  - Spike ticket format with structure, examples, and sizing guide

- **CLAUDE.md - Architecture Mapping**
  - HealthSource code paths for Q1 2026 initiatives
  - PDCR-404 (Search), PDCR-167 (Pre-Fulfillment), PDCR-422 (Telemetry)
  - PDCR-411 (Pull List), PDCR-406 (Intake Acceleration), PDCR-418 (PI MVP)

- **wow/code-review.md - Major Expansion**
  - Review roles: R1 (auto-assign), R2 (SME), RN (team opt-in)
  - PR description template and self-review checklist
  - Comment prefixes with required actions: Blocker, Required, Suggestion, Question, Nit, FYI
  - Comment quality examples (effective vs ineffective)
  - Code-specific review areas (DB, backend, frontend, general)
  - Exception handling: OOO, large PRs, hotfixes

- **wow/sprint-mechanics.md** - New doc (draft)

### Changed
- CLAUDE.md credentials section: use `jira-lib.sh` instead of inline sed parsing
- Added shell parsing warning for Claude sessions

## [1.0.1] - 2026-01-03

### Fixed
- Correct team field: `customfield_10910` (Team(s)) instead of `customfield_20973` (Scrum Team)
- JQL now uses `"Team(s)" = "HealthSource"` for filtering
- Added team configs: healthsource-app, newfire

## [1.0.0] - 2026-01-03

### Added
- **Interactive TUI Dashboard** (`lazyjira`)
  - gum-based interactive menu with typeahead filter
  - [1]-[5] hotkeys for quick panel drill-down
  - Styled drill-down output with borders and colored headers
  - Loading spinner during report fetch
  - Dashboard and per-report caching with [r] refresh
  - Clickable PDCR links using OSC 8 hyperlinks (Ghostty/iTerm2)
  - Color themes: default, ocean, forest, sunset, mono
  - Team switcher, ticket search, and help screen

- **Team-based filtering** (config update)
  - Single project with multiple teams via `Scrum Team` field
  - `team_value` config for JQL filtering
  - `jql_team_filter()` and `jql_base()` helpers in jira-lib.sh
  - Scrum Team field: `customfield_20973`

- **Core Scripts**
  - `jira-lib.sh` - Shared library with API functions, config parsing
  - `jira-dashboard.sh` - Main TUI dashboard
  - `jira-velocity.sh` - Sprint velocity reports
  - `jira-hygiene.sh` - Sprint hygiene audits
  - `jira-standup.sh` - Daily standup reports
  - `jira-burndown.sh` - Sprint burndown
  - `jira-risk.sh` - Risk assessment
  - `jira-roadmap.sh` - PDCR initiatives overview

- **Configuration**
  - `jira-data/config.yaml` - Teams, thresholds, custom fields
  - Slack webhook integration
  - Bash 3 compatibility (macOS default)

- **Launchers**
  - `~/bin/lazyjira` - Interactive TUI
  - `~/bin/lazyroi` - ROI-focused dashboard

### Technical Notes
- Uses Jira REST API v3 (POST `/rest/api/3/search/jql`)
- Custom field for story points: `customfield_10026`
- OSC 8 escape sequences require `$'\e]8;;'` syntax for bash 3
