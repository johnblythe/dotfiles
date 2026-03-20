---
name: retro-adr
description: Shared knowledge for retroactive ADR scanning and writing. Contains git archaeology patterns, scoring heuristics, the ADR template, and publishing conventions. Used by retro-adr-scan (finder) and future retro-adr-write (drafter) commands. PROACTIVELY suggest when conversation reveals an undocumented architectural decision.
---

# Retro-ADR Skill

Find undocumented architectural decisions buried in git history and produce retroactive ADRs.

## When to Use

- "We should document why we did X"
- "Why did we build it this way?"
- Post-incident reveals an undocumented architectural choice
- PROACTIVE: conversation reveals a significant decision with no ADR
- `/retro-adr-scan` for discovery, future `/retro-adr-write` for drafting

## ADR Directory

`~/code/healthsource/docs/healthsource_engineering_design_adrs/`

## Git Search Patterns

All commands run against `~/code/healthsource`. Replace `<since>` with the time range (default `6.months.ago`).

### Large Merge Commits
```bash
git -C ~/code/healthsource log --merges --oneline --shortstat --since="<since>" | \
  awk '/files? changed/{if($1>10) print prev" "$0} {prev=$0}'
```

### Dependency Changes
```bash
git -C ~/code/healthsource log --oneline --since="<since>" --diff-filter=M -- \
  "**/pom.xml" "**/build.gradle" "**/build.gradle.kts" "**/package.json" "**/package-lock.json"
```

### Architectural Keyword Commits
```bash
git -C ~/code/healthsource log --oneline --since="<since>" \
  --grep="refactor" --grep="migrate" --grep="replace" --grep="deprecate" \
  --grep="introduce" --grep="rework" --grep="redesign" --grep="switch" \
  --grep="upgrade" --all-match=false
```
Note: without `--all-match`, `--grep` flags are OR'd.

### Multi-Service Commits
```bash
git -C ~/code/healthsource log --oneline --since="<since>" --name-only | \
  awk '
    /^[0-9a-f]+ /{if(commit && length(services)>=3) print commit" ("length(services)" services: "join_services(services)")"; commit=$0; delete services; next}
    /^services\//{split($0,a,"/"); services[a[2]]=1}
    function join_services(arr, s,k){for(k in arr) s=s?s","k:k; return s}
    END{if(commit && length(services)>=3) print commit" ("length(services)" services)"}
  '
```
Simpler alternative — just get commit hashes, then inspect:
```bash
git -C ~/code/healthsource log --oneline --since="<since>" --stat | \
  grep -B1 "services/" | grep "^[0-9a-f]"
```

### Revert Detection
```bash
# Find reverts
git -C ~/code/healthsource log --oneline --since="<since>" --grep="[Rr]evert"

# For each revert, check if the original commit was later re-landed
# Extract the reverted hash from the commit message, then search for commits
# touching the same files after the revert date
```

### New Top-Level Packages/Directories
```bash
git -C ~/code/healthsource log --oneline --since="<since>" --diff-filter=A --name-only -- \
  "services/*/src/main/java/com/datavant/*" "services/*/src/main/java/com/ciox/*" | \
  grep -E "^services/" | awk -F/ '{print $1"/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | sort -u
```

### Feature Flag Introductions
```bash
git -C ~/code/healthsource log --oneline --since="<since>" -S "LaunchDarkly" --all
git -C ~/code/healthsource log --oneline --since="<since>" -S "featureToggle" --all
git -C ~/code/healthsource log --oneline --since="<since>" -S "feature_flag" --all
git -C ~/code/healthsource log --oneline --since="<since>" --grep="feature flag" --grep="feature toggle" --all-match=false
```

## Scoring Heuristic

Score each cluster of related commits to prioritize ADR-worthiness.

| Factor | Points | Condition |
|--------|--------|-----------|
| Services touched | +1 per service beyond 1 | Commit cluster modifies N services -> N-1 pts |
| Incident/revert history | +3 | Any revert, hotfix, or incident reference in the cluster |
| Single-author bus factor | +2 | All commits in cluster by one person |
| No existing documentation | +2 | No Jira ticket description, no Confluence page, no inline docs explaining WHY |
| Age > 6 months | +1 | Decision was made >6 months ago |
| Config/infra change | +1 | Touches CI/CD, Terraform, Docker, deployment configs, feature flags |

**Priority mapping:**
- **High (7+):** Almost certainly needs an ADR. Tribal knowledge at risk.
- **Medium (4-6):** Likely needs an ADR. Worth investigating context.
- **Low (1-3):** Maybe. Quick check — might be routine or already well-understood.

**Confidence level** (separate from priority):
- **Strong:** Clear architectural shift visible in diffs, multiple signals converge
- **Moderate:** Looks like a decision but could be routine refactoring
- **Weak:** Might be architectural, needs human confirmation

## ADR Template (Retroactive)

Matches convention in `~/code/healthsource/docs/healthsource_engineering_design_adrs/`. File naming: `YYYY-MM-DD-snake_case_title.md` where date is the *decision date* (when the change landed), not documentation date.

```markdown
# ADR: [Title — describes the decision, not the problem]

| | |
|---|---|
| **Decision Date** | YYYY-MM-DD |
| **Documented** | YYYY-MM-DD |
| **Status** | Accepted (retroactive) |
| **Deciders** | [Names — from git blame, PR reviewers, Jira assignees] |

---

## 1. Context / Problem Statement

[What problem existed? What pressure or trigger caused the decision?]
[Who/what was affected?]
[Include metrics, incident references, or user complaints if available.]

### How this was discovered
[If the problem was found incrementally, document the discovery timeline]

## 2. Decision

[What was decided. Be specific about what changed.]
[Reference key commits, PRs, or Jira tickets.]

### Key Artifacts

| Ticket | Description |
|--------|-------------|
| HEAL-XXXX | [title] |
| PR #NNN | [title] |

## 3. Rationale and Tradeoffs

[Why this approach was chosen over alternatives.]
[What tradeoffs were accepted?]

### Alternatives Considered

| Alternative | Why not |
|-------------|---------|
| [Option A] | [reason] |
| [Option B] | [reason] |

> **Retroactive note:** Alternatives are reconstructed from code review comments,
> Jira discussions, and commit history. If an alternative is listed here,
> there is evidence it was discussed. We do not fabricate alternatives.

## 4. Consequences (Observed)

[Since this is retroactive, we can document actual outcomes, not predictions.]

### Benefits realized
- [concrete benefit with evidence]

### Problems encountered
- [concrete problem with evidence]

## 5. Revisiting Conditions

[When should this decision be revisited?]
[What would signal it's time to change course?]

---

## Appendix: Timeline

| Phase | Date | What |
|-------|------|------|
| [phase] | [date] | [description] |

## Confidence

| Section | Evidence Level |
|---------|---------------|
| Context | [Direct / Strong inference / Editorial] |
| Decision | [Direct / Strong inference / Editorial] |
| Rationale | [Direct / Strong inference / Editorial] |
| Alternatives | [Direct / Strong inference / Editorial] |
| Consequences | [Direct / Strong inference / Editorial] |

> This ADR was reconstructed retroactively from git history and Jira artifacts.
> It should be reviewed by an engineer who was involved in the decision.
```

### Retroactive-Specific Conventions

- Status is always `Accepted (retroactive)` unless the decision is still in flux (`Proposed (retroactive)`)
- **Decision Date** = when the change merged (from git). **Documented** = today's date.
- Deciders come from: PR author, PR approvers, Jira assignee, commit authors. List real names.
- Section 4 (Consequences) should describe *observed* outcomes, not hypothetical ones. Key advantage of retroactive ADRs.
- If alternatives can't be reconstructed from evidence, say "No alternatives found in the historical record" — do NOT invent them.

### Evidence Levels

Use these consistently in the Confidence table:
- **Direct**: Found verbatim in commit message, Jira comment, code comment, or PR review
- **Strong inference**: Implied by code changes, timing, ticket relationships, or consistent patterns
- **Editorial**: Reasonable interpretation but not directly supported by artifacts

## Confluence Publishing

ADRs live in Confluence under the Architecture section.

- **Parent page ID:** `2432270388` (ADRs under Systems > Architecture)
- **Space ID:** `948109388`
- **Title format:** `ADR: [Same title as the markdown H1]`

### Publishing Steps

1. Convert markdown ADR to ADF (atlas_doc_format) — use REST API, NOT MCP markdown tool
2. Create the page:
```bash
source scripts/jira-lib.sh

cat > /tmp/adr-page.json << 'ADREOF'
{
  "spaceId": "948109388",
  "status": "current",
  "title": "ADR: [Title]",
  "parentId": "2432270388",
  "body": {
    "representation": "atlas_doc_format",
    "value": "<ADF JSON string>"
  }
}
ADREOF

curl -s -X POST -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/wiki/api/v2/pages" \
  -d @/tmp/adr-page.json
```

3. Set fixed-width layout (API defaults to full-width):
```bash
# Published view
curl -s -X PUT -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/wiki/rest/api/content/${PAGE_ID}/property/content-appearance-published" \
  -d '{"key":"content-appearance-published","value":"fixed-width"}'

# Draft view
curl -s -X PUT -H "Content-Type: application/json" \
  -u "${JIRA_USER}:${JIRA_TOKEN}" \
  "${JIRA_URL}/wiki/rest/api/content/${PAGE_ID}/property/content-appearance-draft" \
  -d '{"key":"content-appearance-draft","value":"fixed-width"}'
```

4. Linkify Jira references — in ADF, use inlineCard nodes:
```json
{"type":"inlineCard","attrs":{"url":"https://datavant.atlassian.net/browse/HEAL-XXXX"}}
```

## Anti-Patterns

What makes a BAD retroactive ADR — avoid these:

| Anti-Pattern | Why It's Bad | How to Avoid |
|--------------|-------------|--------------|
| **Diff narration** | Restates WHAT changed without explaining WHY. Reader can get the "what" from git. | Anchor in the problem/pressure that triggered the decision. |
| **Fabricated alternatives** | Lists options never actually discussed, making the ADR fiction. | Only list alternatives with evidence (PR comments, Jira, Slack). Say "no alternatives found" if none. |
| **Marketing language** | Sells the decision instead of documenting it. | Use neutral, factual language. State tradeoffs honestly. |
| **Consequences-free** | Lists only benefits, ignores problems. Every decision has costs. | Section 4 MUST include problems encountered. If none visible, say "no negative consequences observed to date." |
| **Missing deciders** | Says "the team decided" without naming anyone. | Name real people from git blame, PR reviews, Jira. |
| **Over-scoping** | Tries to document 5 decisions in one ADR. | One decision per ADR. Split clusters with multiple decisions. |
| **Speculative context** | Invents motivations not evidenced anywhere. | Stick to what's in the record. Flag gaps: "Motivation unclear from available evidence." |

## Source Priority

When reconstructing the WHY behind a decision, prioritize sources in this order:

1. **Git commits/diffs** — always available, objective, shows what actually happened
2. **Jira tickets + comments** — rich decision context, often has the WHY and discussion
3. **PR comments/reviews** — debate reveals tradeoffs considered, objections raised
4. **Current code state** — shows what was chosen but rarely why
5. **Datadog/observability** — validates claimed consequences, reveals incidents
6. **DO NOT USE:** planning docs, PRDs, or project files from the management repo — these reflect intent, not decisions made. ADRs document what was actually decided, not what was planned.

## Intent Interviewer Integration

The **intent-interviewer** (`~/code/management/intent-interviewer/`) captures implicit operational knowledge from SMEs via interviews or async questionnaires. It produces service-level CLAUDE.md files. The retro-adr workflow connects to it in three ways:

### 1. Scan → Interview Suggestion

When `/retro-adr-scan` produces a result with **low evidence** (score ≥4 but confidence = Weak), suggest generating an intent interview questionnaire for the relevant service/engineer:

```
⚠️ Low evidence for this item. Consider running an intent interview:
   ~/code/management/intent-interviewer/generate-questionnaire.sh <service>
   Then have <author> (from git blame) fill it in.
```

Trigger conditions:
- Single author (bus factor risk) AND no Jira description/comments with rationale
- Decision touches a service that has no CLAUDE.md yet
- The "History & War Stories" questions in the interview would directly surface the missing context

### 2. Write → Interview Fallback

During `/retro-adr` Phase 2 (Synthesis), if the evidence level for **Context** or **Rationale** sections would be "Editorial" (no direct evidence for WHY), suggest an interview before publishing:

```
📋 The rationale for this decision couldn't be fully reconstructed from artifacts.
   Before publishing, consider interviewing one of:
   - <name> (primary author, N commits)
   - <name> (PR reviewer, approved key changes)

   Quick option: ~/code/management/intent-interviewer/generate-questionnaire.sh <service>
   Live option: ~/code/management/intent-interviewer/interview.sh <service>
```

The interview's "history" and "gotchas" questions often surface exactly the missing WHY.

### 3. Interview → ADR Feed-Forward

When processing a filled questionnaire (`process-questionnaire.sh`), the answers to these questions may reveal ADR-worthy decisions:

- **history.major_refactors**: "What major refactors or rewrites have happened?"
- **history.incidents**: "What incidents has this service caused?"
- **patterns.right_way**: "What's the 'right way' to add a new feature?"
- **gotchas.haunted_areas**: "Are there 'haunted' areas everyone avoids touching?"

If these answers describe significant architectural changes, suggest: "This sounds like it could be an ADR. Run `/retro-adr <topic>` to draft one."

### CLAUDE.md Coverage Check

During `/retro-adr-scan`, also check which services touched by the scan results have CLAUDE.md files:

```bash
for svc in $(ls ~/code/healthsource/services/); do
  if [ ! -f ~/code/healthsource/services/$svc/CLAUDE.md ]; then
    echo "MISSING: $svc"
  fi
done
```

Services with ADR-worthy decisions but no CLAUDE.md are strong candidates for intent interviews.
