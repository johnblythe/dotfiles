# Retroactive ADR from Git History

Generate an Architectural Decision Record by reconstructing what happened from commits, code, and Jira — not from planning docs.

## Usage
- `/retro-adr <topic>` — e.g., "audit trail queue migration", "structured logging", "ROIP-372"

## Arguments
$ARGUMENTS

## Skill Reference
Full template, naming convention, and publishing details: `.claude/skills/retro-adr/SKILL.md`

## Phase 1: Research (3 parallel subagents)

Dispatch all 3 simultaneously. The codebase is `~/code/healthsource`.

### Agent 1: Commit Archaeology

Search git history in `~/code/healthsource` for all commits related to $ARGUMENTS.

```
For each relevant commit: full message, author, date, diff stat.
Key file diffs for non-test files.
Find reverts, fixes, follow-up commits.
Detect the before/after boundary — what did the code look like before vs after.
Map the full timeline: first commit → last commit.
Identify which services were affected and in what order.
Extract ticket keys from commit messages (HEAL-*, ROIP-*, HSA-*).

Search strategies (use multiple):
- git log --all --oneline --grep="<topic keywords>"
- git log --all --oneline --grep="<ticket key>" (if topic is a ticket)
- git log --all -- <suspected file paths>
- git log --all -S "<distinctive string>" (pickaxe for code changes)

For each commit found, get: git show --stat <sha> and git show <sha> for key files.
```

### Agent 2: Code Architecture

Analyze current state of the relevant code in `~/code/healthsource`.

```
Find the current implementation — the "after" state.
Find remnants of the old pattern (commented-out code, deprecated classes, TODO comments, feature flags).
Read key files to understand the new architecture.
Map the message/data flow end-to-end.
Identify configuration properties, feature flags, LaunchDarkly references.
Check for incomplete migrations or holdouts (services still using the old pattern).
Look for the abstraction boundary — where is the new pattern encapsulated?
```

### Agent 3: Jira Context

Look up all related tickets from commit messages + the topic itself.

```
For each ticket key found by Agent 1:
- Fetch ticket: summary, description, status, assignee, reporter
- Fetch comments (especially decision-making discussions)
- Fetch linked issues (parent epics, blocks/blocked-by, related)

For the parent epic (if found):
- Get epic description for broader motivation
- Get child tickets for scope understanding

Extract:
- Who worked on this and what was their role
- Decision rationale from comments ("we decided to...", "after discussion...", "the tradeoff is...")
- Any incidents or bugs related to the change
- Timeline from ticket creation to resolution
```

## Phase 2: Synthesis

Merge findings from all 3 agents. Produce a structured analysis:

1. **Key decisions** — there may be multiple per topic. Each gets its own "Decision" entry.
2. **Reconstruct the WHY** — from Jira comments + commit patterns + code structure.
3. **Evidence classification** — for each claim, mark whether it's:
   - **Direct evidence**: found in commit message, Jira comment, or code comment
   - **Strong inference**: implied by code changes, timing, or ticket relationships
   - **Editorial inference**: reasonable interpretation but not directly supported
4. **Alternatives** — check if alternatives were discussed in Jira comments or PR reviews. If not found, note "no alternatives found in artifacts" rather than inventing them.
5. **Consequences** — document both benefits AND problems observed (bugs, incidents, follow-up work).

### Interview Fallback Check

If the evidence level for **Context** or **Rationale** would be "Editorial" (no direct evidence for WHY the decision was made), suggest an intent interview before publishing:

```
📋 The rationale couldn't be fully reconstructed from artifacts.
   Before publishing, consider interviewing:
   - <name> (primary author, N commits)
   - <name> (PR reviewer, approved key changes)

   Generate questionnaire: ~/code/management/intent-interviewer/generate-questionnaire.sh <service>
   Live interview:         ~/code/management/intent-interviewer/interview.sh <service>
```

Also check: does the primary service have a CLAUDE.md? If not, suggest the interview will capture both the ADR context AND broader operational knowledge for the service.

## Phase 3: Draft

Write the ADR following the template and conventions in `.claude/skills/retro-adr/SKILL.md`.

Key rules:
- **Date** = when the decision was made (from commit/ticket timeline), not today
- **Documented** = today's date
- **Status** = "Accepted (retroactive)" for completed work; "Proposed (retroactive)" if still in-progress
- **Filename**: `YYYY-MM-DD-slug.md` where date = decision date
- **Save to**: `~/code/healthsource/docs/healthsource_engineering_design_adrs/`
- Do NOT read planning docs, PRDs, or project files from the management repo — the skill's value is reconstruction from code artifacts only
- Mark editorial inferences clearly in a "Confidence" annotation at the bottom
- Include a note that the ADR should be vetted by an involved engineer

After writing, show the user the full draft and ask for feedback.

## Phase 4: Publish (on user approval)

Ask: "Want me to publish this to Confluence?"

If yes:
1. Convert the ADR to ADF format
2. Create page under ADR parent (page ID `2432270388`) using REST API with `atlas_doc_format`
3. Set `content-appearance-published` and `content-appearance-draft` properties to `"fixed-width"`
4. Linkify all Jira ticket references (e.g., ROIP-372 → `https://datavant.atlassian.net/browse/ROIP-372`)
5. Return the Confluence URL

## Important Constraints

- **No planning docs.** Do not read PRDs, specs, or management repo project files. Reconstruct from code + commits + Jira only.
- **Draft, not gospel.** Always include: "This ADR was reconstructed retroactively from git history and Jira artifacts. It should be reviewed by an engineer who was involved in the decision."
- **Multiple decisions are OK.** A single topic (e.g., "audit trail migration") may contain 3-4 distinct architectural decisions. Document them all in one ADR if they're tightly coupled, or suggest splitting if they're independent.
- **Holdouts matter.** If the migration/change is incomplete, document what's left. This is some of the most valuable content in a retroactive ADR.
