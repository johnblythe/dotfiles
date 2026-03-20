Scan a git repo for undocumented architectural decisions that should have ADRs.

Args: $ARGUMENTS
- Format: `[time-range] [focus-area]`
- time-range: git `--since` value, default `6.months.ago` (e.g. `3.months.ago`, `2025-01-01`)
- focus-area: optional filter keyword (e.g. `logging`, `auth`, `database`, `intake`, `fulfillment`)

Reference: `~/.claude/skills/retro-adr/SKILL.md` for patterns, scoring, and ADR template.

## Workflow

### 1. Load Existing ADRs

Read all files in `~/code/healthsource/docs/healthsource_engineering_design_adrs/`. Extract the title and core decision from each. These are the "already documented" set — do NOT recommend them again.

### 2. Git Archaeology (run in parallel)

All commands target `~/code/healthsource`. Parse time range and focus area from args. Default since=`6.months.ago`.

Run these searches in parallel (see SKILL.md for exact commands):

a. **Large merge commits** — merges touching >10 files
b. **Dependency changes** — modifications to `pom.xml`, `build.gradle`, `package.json`, `*.gradle`
c. **Architectural keyword commits** — grep for: refactor, migrate, replace, deprecate, introduce, rework, redesign, switch, upgrade
d. **Multi-service commits** — commits touching 3+ directories under `services/`
e. **Reverts + re-lands** — `git log --grep="[Rr]evert"`, then check if the reverted commit was later re-applied
f. **New top-level packages** — `--diff-filter=A` on directories under `services/*/src/main/java/`
g. **Feature flag introductions** — grep for LaunchDarkly, feature toggle, feature flag patterns in diffs

If focus-area is set, add `-- "*<focus-area>*"` path filters where applicable.

### 3. Cluster

Group related commits by:
1. Jira ticket key extracted from branch name or commit message (HEAL-\d+, HSA-\d+, ROIP-\d+)
2. Same branch name
3. Same author within a 2-week window touching the same files

Merge clusters that share a Jira ticket. Name each cluster by its apparent decision.

### 4. Score

Apply the scoring heuristic from SKILL.md to each cluster. Calculate total score and map to priority:
- High (7+): almost certainly needs an ADR
- Medium (4-6): likely needs an ADR
- Low (1-3): maybe, worth a quick check

### 5. Deduplicate

Compare each cluster against the existing ADRs from step 1. If a cluster's core decision is already documented, remove it. If it partially overlaps, note the gap.

### 6. Output

Print a ranked table:

```
## Retro-ADR Scan Results

Scanned: ~/code/healthsource | Range: <range> | Focus: <focus or "all">
Existing ADRs: <count> loaded, <count> clusters deduplicated

| # | Priority | Title | Services/Scope | Date Range | Key Commits | Confidence |
|---|----------|-------|---------------|------------|-------------|------------|
| 1 | HIGH | ... | ... | ... | ... | ... |
```

Below the table, for each High/Medium item, print a 2-3 sentence description of what the architectural decision appears to be, who was involved, and what context exists (Jira tickets, PR descriptions, etc.).

Below the results, add two follow-up sections:

### CLAUDE.md Coverage

Check which services touched by scan results have CLAUDE.md files. List any missing ones:

```
Services touched by scan results missing CLAUDE.md:
- intakeservices — consider: ~/code/management/intent-interviewer/generate-questionnaire.sh intakeservices
- deliveryservices — consider: ~/code/management/intent-interviewer/generate-questionnaire.sh deliveryservices
```

### Suggested Next Steps

For each HIGH priority item:
- If evidence is strong: "Run `/retro-adr <title>` to draft an ADR"
- If evidence is weak (single author, no Jira context): "Consider an intent interview first — `~/code/management/intent-interviewer/generate-questionnaire.sh <service>` — then `/retro-adr <title>`"
- If the service has no CLAUDE.md: "This service would also benefit from an intent interview to capture broader operational knowledge"
