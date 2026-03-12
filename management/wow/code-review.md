# Code Review

> Go fast? Go alone. Go far? Go together.

Code review is **collaboration**, not a gate.

Goals: catch bugs, share knowledge, maintain quality, mentor.

---

## Review Roles

| Role | How | Purpose | SLA |
|------|-----|---------|-----|
| **R1** | Auto-assigned (Round Robin) | Load distribution, first-pass | 1 business day |
| **R2 (SME)** | Called in by Author or R1 | Deeper domain/tech expertise | 1-2 business days |
| **RN (Team)** | Author posts to channel | Opt-in learning, crowd context | N/A |

**R1** can approve if confident, or defer to R2 if needing further expertise.

**RN** follows along—only adds if high value and missed by other reviewers. Fail mode to avoid: too many cooks, dogpiling.

---

## For Authors

- Small PRs (<400 lines). >500 LOC? Discuss timeline with reviewer first.
- Self-review first
- Context in description, link to ticket
- Tests included or explained
- Respond promptly to reviewer comments (same 1-2 day TAT)

### PR Description Template

```
## Overview
[Brief description of the changes]

## Problem
[What issue does this solve?]

## Solution
[How does this PR solve the problem?]

## Testing
[How was this tested?]

## Screenshots/Logs
[If applicable]

## Related PRs
[If applicable]
```

### Self-Review Checklist

- [ ] Code follows team coding standards
- [ ] Tests added/updated
- [ ] Documentation updated as needed
- [ ] No unnecessary commented code
- [ ] No debug print statements

---

## For Reviewers

- First pass within 24h (same day for small PRs)
- Start with overall assessment: general impression, major concerns, areas of praise
- Be specific: "Consider X because Y"
- Distinguish blocking vs nit vs question
- Approve when good enough—perfect is enemy of shipped

### Approval Statuses

- **Approve:** No issues or only minor suggestions
- **Comment:** Questions or suggestions that don't block
- **Request Changes:** Blockers or required changes identified

---

## Comment Prefixes

| Prefix | Meaning | Action Required |
|--------|---------|-----------------|
| `[Blocker]` | Critical, must fix before merge | Yes |
| `[Required]` | Important change needed before approval | Yes |
| `[Suggestion]` | Recommended improvement | No |
| `[Question]` | Request for clarification | Response needed |
| `[Nit]` | Minor stylistic/cosmetic | No |
| `[FYI]` | Educational, no action needed | No |

---

## Comment Quality

### Effective
- Explain **why**, not just what
- Provide examples
- Link to resources
- Ask clarifying questions

```
[Suggestion] Consider using a prepared statement here instead of
string concatenation to prevent SQL injection vulnerabilities.
```

```
[Required] This query might cause performance issues with large
datasets. Consider adding an index on `correspondence_date`.
```

```
[Question] Was there a specific reason for choosing JSONB over
a structured column here? Help me understand.
```

### Ineffective
- "This doesn't look right."
- "I prefer a different approach here."
- "Move this variable declaration up 3 lines." (unmarked nit)
- "You didn't test this, did you?" (assumptive)
- "No."

---

## What to Look For

**Always:** Logic errors, security issues, breaking changes, missing tests, unclear code.

**Sometimes:** Performance, pattern consistency, doc updates.

**Rarely (bigger discussion):** Architectural disagreements, style not in linter.

### Code-Specific Reminders

| Area | Check For |
|------|-----------|
| **Database** | Indexes, transactions, migration rollbacks, permissions, injection risks, validation |
| **Backend** | Error handling, input validation, security, performance, logging |
| **Frontend** | Accessibility, responsive design, error/loading states, browser compat |
| **General** | Clear > clever, docs, tests, comments where needed, pattern consistency, linting |

---

## Exceptions

| Scenario | Handling |
|----------|----------|
| **OOO/PTO** | Auto-skip in rotation, author reassigns R2 |
| **Large PRs (>500 LOC)** | Discuss timeline with reviewer first |
| **Hotfixes** | Flag in Slack for immediate attention (<2hrs) |

---

## Fail Modes

| Mode | Symptom | Fix |
|------|---------|-----|
| Rubber stamp | Approve without reading | Require substantive comment |
| Review hoarding | One person reviews all | Round robin rotation |
| Nitpick wars | 15 comments on semicolons | Add to linter, move on |
| Stale PRs | Sitting for days | Author pings, bump in Slack, ask for sub |
| Ego battle | "My way is better" | Focus on outcomes, escalate if stuck |
| Giant PRs | 2000-line diff | Break up before review, or review in stages |
| Silent reviewer | No response for 48h+ | "Can't review until X" > silence |
| Dogpiling | 10 reviewers commenting same thing | RN follows, only adds if missed |

---

## Tooling

- GitHub Round Robin for R1 assignment
- Post to #roi-zone-all or project channel for RN visibility
- [TODO: CODEOWNERS, CI requirements]
