---
name: pm-scope
description: Analyze feature requests for scope creep, MVP boundaries, and deferred items. Use before implementing any non-trivial feature.
---

# PM Scope Analysis

Decompose feature requests into actionable phases. Catch scope creep before it catches you.

## When to Use

- User describes a new feature
- Issue body contains vague terms ("parse from files", "integrate with", "support all")
- Feature touches multiple systems
- You're unsure where to start

## Analysis Framework

### 1. Extract Requirements

From the feature description, identify:

**Explicit asks** - What user literally said
**Implicit needs** - What they probably also need
**Vague terms** - Dangerous scope bombs

Example danger phrases:
| Phrase | Why Dangerous | Question to Ask |
|--------|---------------|-----------------|
| "Parse from files" | Which formats? OCR? AI? | "Which specific file types?" |
| "Integrate with X" | API? Import? Realtime sync? | "One-way or bidirectional?" |
| "Support all" | Infinite scope | "Top 3 most important?" |
| "Like [competitor]" | 2 years of work | "Which specific feature?" |
| "Simple" | Famous last words | "Walk me through the flow" |

### 2. Phase Decomposition

Break into 3 phases:

```
## MVP (This PR)
- Core functionality only
- Happy path works
- Manual fallbacks acceptable
- ~1-3 day effort

## v2 (Next iteration)
- Edge case handling
- Polish and UX improvements
- Automation of manual steps
- ~1 week effort

## Someday (Backlog)
- Nice-to-haves
- Integrations
- Advanced features
- Effort TBD
```

### 3. Scope Table Output

Always produce this table:

```markdown
| Requirement | Phase | Effort | Risk | Notes |
|-------------|-------|--------|------|-------|
| Daily macro entry form | MVP | S | Low | 4 fields, straightforward |
| 7-day rolling view | MVP | M | Low | Chart component needed |
| Parse CSV uploads | v2 | M | Med | Format validation required |
| Parse MyFitnessPal | v2 | L | High | API changes frequently |
| Photo/OCR parsing | Someday | XL | High | AI accuracy uncertain |
| Meal timing integration | Someday | M | Med | Requires workout data |
```

Effort: S (hours) / M (1-2 days) / L (3-5 days) / XL (week+)
Risk: Low / Med / High

### 4. UX Friction Points

Identify where users might struggle:

```markdown
| Friction Point | Risk Level | Mitigation |
|----------------|------------|------------|
| Daily logging tedious | High abandonment | "Quick log" - totals only |
| Users don't know macros | Entry friction | Link to calculator |
| Duplicate data entry | Already use MFP | Import (expensive) or skip |
```

### 5. Open Questions

End with concise questions (per CLAUDE.md - sacrifice grammar for concision):

```markdown
## Open Questions
1. Target user: casual tracker or macro-obsessed?
2. Daily log mandatory in check-ins?
3. Show red when over/under? (shame risk)
4. Meal-by-meal or daily totals?
5. History: how far back to display?
```

## Output Format

```markdown
# PM Scope: {Feature Name}

## Summary
{1-2 sentence feature description}

## Scope Analysis

### Danger Phrases Found
- "{phrase}" → {why dangerous}

### Phase Breakdown

**MVP (This PR):**
- {item 1}
- {item 2}

**v2 (Next iteration):**
- {item 1}

**Someday:**
- {item 1}

### Scope Table
| Requirement | Phase | Effort | Risk | Notes |
|-------------|-------|--------|------|-------|
| ... | ... | ... | ... | ... |

### UX Friction Points
| Friction Point | Risk Level | Mitigation |
|----------------|------------|------------|
| ... | ... | ... |

## Open Questions
1. {question}?
2. {question}?

## Recommendation
{MVP recommendation - what to build first and why}
```

## Rules

- ALWAYS identify vague terms before agreeing to scope
- MVP = smallest useful increment, not smallest possible
- If feature touches 3+ systems, it's probably too big
- Ask questions BEFORE implementation, not during
- User decides scope, you surface trade-offs
