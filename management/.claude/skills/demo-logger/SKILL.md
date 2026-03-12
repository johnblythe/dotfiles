---
name: demo-logger
description: Logs demo ideas for sprint demos. PROACTIVELY suggest logging when conversation mentions showing something to stakeholders, demoing a feature, impressive results, cool visualizations, workflow improvements, or anything demo-worthy. Invoke via /demo or proactively when detecting demo opportunities.
---

# Demo Logger Skill

Capture demo ideas as they come up - explicitly via `/demo` or proactively when you notice demo-worthy topics.

## Proactive Triggers

Watch for these signals and suggest logging:
- "this would be cool to show..."
- "stakeholders would love..."
- "we should demo this"
- "impressive results" / "big improvement"
- New feature completions
- Performance wins with metrics
- Workflow/UX improvements
- Visualizations or dashboards
- Automation that saves time
- Bug fixes with visible impact

When detected, ask: **"Want me to log this as a demo idea for this sprint?"**

## Explicit Usage

```
/demo <idea description>
```

## Logging Behavior

1. **Get active sprint** from Jira:
   ```bash
   acli jira board list-sprints --id 389 --state active --csv | tail -1 | cut -d',' -f2
   ```

2. **Check/create sprint file** at `demos/<sprint-name>.md`
   - If file doesn't exist, create with header:
     ```md
     # <Sprint Name> Demo Ideas

     Status: active

     ## Ideas
     ```

3. **Determine pod** from context:
   - Platform, Intake-Logging, Fulfillment-QC, KTLO, Newfire
   - Infer from topic (search/perf = Platform, intake/upload = Intake-Logging, etc.)
   - If unclear, ask user

4. **Append entry**:
   ```md
   - [YYYY-MM-DD] [Pod] <idea description>
   ```

5. **Confirm** what was logged

## Sprint Lifecycle

- New sprint file created automatically when first idea logged
- When sprint ends, change `Status: active` → `Status: demoed`
- Old sprint files remain as archive

## File Structure

```
demos/
├── Q4.S6.md      # Status: active
├── Q4.S5.md      # Status: demoed
├── Q4.S4.md      # Status: demoed
└── ...
```

## Pod Mapping

Infer pod from topic:
- **Platform**: search, performance, infrastructure, caching, DB optimization
- **Intake-Logging**: intake, upload, fax, email, logging, telemetry, STORK
- **Fulfillment-QC**: fulfillment, QC, queues, workflow, pre-fulfillment
- **KTLO**: bugs, maintenance, tech debt
- **Newfire**: (external team items)

## Example Sprint File

```md
# Q1.S1 Demo Ideas

Status: active

## Ideas
- [2026-01-11] [Platform] Search performance: 3s → 400ms on large result sets
- [2026-01-11] [Intake-Logging] New intake acceleration dashboard with p95 metrics
- [2026-01-13] [Fulfillment-QC] Pre-fulfillment queue filtering by site
- [2026-01-14] [KTLO] Fixed site selection freeze bug affecting single-site users
```
