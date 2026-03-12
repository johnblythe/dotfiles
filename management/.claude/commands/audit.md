# Jira Audit

Single ticket style guide compliance check.

## Usage
```bash
/audit HEAL-123
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-audit.sh HEAL-123
```

## What It Checks

| Check | Pass Criteria |
|-------|---------------|
| Has story points | Points > 0 |
| Points <= 4 | Per style guide max |
| Has assignee | Not unassigned |
| Has epic link | Linked to parent epic |
| Has acceptance criteria | Description contains AC keywords |
| Summary quality | 3+ words, not vague |

## Output
- Compliance table (PASS/FAIL/WARN)
- Recommendations for fixes
