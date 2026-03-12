# Jira Hygiene Framework - TODO

## Batch 1: Foundation (In Progress)

### 1. Polish Existing Commands ✅ DONE
- [x] Created shared library `scripts/jira-lib.sh`
- [x] Both scripts use consistent REST API v3 for point aggregation
- [x] Tested against multiple boards (HEAL, ROIO, ROIP)
- [x] Scripts: `jira-velocity.sh`, `jira-hygiene.sh`

### 2. Multi-Board Configuration ✅ DONE
- [x] `jira-data/config.yaml` with team definitions
- [x] CLI overrides: `--team NAME` or `--board ID --project KEY`
- [x] Teams configured:
  - platform (HEAL board 389)
  - roio (ROIO board 2696)
  - roip (ROIP board 2695)
- [ ] Add remaining teams when board IDs known (KTLO, Intake, Fulfillment, Newfire)

### 3. Update CLAUDE.md ✅ DONE
- [x] Document REST API v3 pattern (POST /rest/api/3/search/jql)
- [x] Document custom field IDs
- [x] Add jira-data/ structure
- [x] Add script locations
- [x] Add credential reading pattern (no yq dependency)
- [x] Add Q4 sprint ID reference table

### 4. Add Bottlenecks Command
- [ ] `/bottlenecks` - Pipeline analysis, time-in-status
- [ ] Research: Does Jira API expose status change history?
- [ ] Design output format first, then implement

### 5. Add Team Command
- [ ] `/team` - Per-person workload and delivery rates
- [ ] Current sprint: assigned/done/in-progress by person
- [ ] Historical: 5-sprint avg delivery % per person
- [ ] Use case: capacity planning, spotting overloaded people

### 6. Add Audit Command
- [ ] `/audit HEAL-123` - Single ticket style guide check
- [ ] Checks: story points, <=4 pts, acceptance criteria, assignee, epic link
- [ ] Suggests specific fixes (not just flags problems)

### 7. Add Initiative Command
- [ ] `/initiative PDCR-294` - Single initiative/project status
- [ ] JQL: `(issue in linkedIssues(PDCR-X) or parent in linkedIssues(PDCR-X)) and issuetype not in (Epic, Initiative, Theme)`
- [ ] Shows: epic breakdown, ticket status rollup, % complete
- [ ] Flags: thin backlog (not enough broken-down work), stale epics, no recent activity
- [ ] Links to drill-down: list child tickets, show blockers

### 8. Add Roadmap/Portfolio Command
- [ ] `/roadmap` or `/portfolio` - All active PDCR initiatives
- [ ] Shows per-initiative: progress %, health, # epics, # open tickets
- [ ] Quarterly view: what's on track, at risk, blocked
- [ ] Drill-down prompt: "Run /initiative PDCR-X for details"
- [ ] Source: PDCR project items (Initiatives/Themes)

### 9. Automation
- [ ] Daily hygiene cron script
- [ ] Weekly velocity capture
- [ ] Alert thresholds (Slack webhook?)
- [ ] launchd plist for macOS

---

## Skipped (intentionally)
- `/spillover` - Not valuable enough

## Related Skills
- `agile-product-owner` - Story generation, INVEST templates (complementary to hygiene monitoring)

---

## Config Structure (Planned)

```yaml
# jira-data/config.yaml
defaults:
  board_id: 389
  project: HEAL

teams:
  platform:
    board_id: 389
    project: HEAL
    sprint_prefix: "Q"

  ktlo:
    board_id: TBD
    project: TBD

  newfire:
    board_id: TBD
    project: TBD
    sprint_prefix: "Q4.S"  # if different naming

thresholds:
  stale_in_progress_days: 5
  stale_code_review_days: 3
  max_story_points: 4
```

## Command Override Examples

```bash
# Use default (platform)
/hygiene

# Override team
/hygiene --team newfire

# Override specific board
/hygiene --board 123 --project NEWF

# Velocity for specific team
/velocity --team ktlo
```

---

## Notes

- REST API v3: `POST /rest/api/3/search/jql` (old GET endpoint deprecated)
- Story points: `customfield_10026`
- Epic link: `customfield_10014`
- Creds: `~/.config/jiratui/config.yaml`
