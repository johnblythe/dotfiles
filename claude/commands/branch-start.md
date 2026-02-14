---
description: Start work on an issue - branch, context, related work check
---

# Branch Start

Start working on an issue properly. Prevents the "oops committed to develop" mistake.

## Usage

```
/branch-start 123
/branch-start 123 custom-slug
```

## Steps

### 1. Validate Current State

```bash
# Check we're not mid-work
git status --porcelain
```

If uncommitted changes exist, STOP and ask:
- Stash changes?
- Commit first?
- Abort?

### 2. Ensure Clean Base

```bash
# Get latest from main/develop
git fetch origin
git checkout develop 2>/dev/null || git checkout main
git pull
```

### 3. Fetch Issue Details

```bash
gh issue view {issue_number} --json number,title,body,labels
```

Extract:
- Issue number
- Title (for branch slug)
- Labels (bug/feature/chore)
- Body (for context)

### 4. Create Branch

Generate slug from title (lowercase, hyphens, max 30 chars):

```bash
git checkout -b jb/{issue_number}-{slug}
```

Examples:
- `jb/104-nutrition-display`
- `jb/68-gap-concept`

### 5. Check Related Work

```bash
# Find related open issues
gh issue list --state open --json number,title,labels | jq -r '.[] | select(.title | test("keyword"; "i"))'

# Check for existing branches
git branch -r | grep -i "keyword"

# Check recent commits mentioning this area
git log --oneline -20 | grep -i "keyword"
```

Show related items if found. Ask if any should be addressed together.

### 6. Init Context

Check if `.issues.json` exists and update status:

```json
{
  "id": "{issue_number}",
  "status": "in_progress",
  "branch": "jb/{issue_number}-{slug}",
  "startedAt": "{ISO timestamp}"
}
```

### 7. Output Summary

```
✅ Ready to work on #{issue_number}

Branch: jb/{issue_number}-{slug}
Issue: {title}
Labels: {labels}

{issue body - first 500 chars}

Related:
- #{related1} - {title}
- Branch: origin/jb/related-work

Next: Start coding or `/log-issue` to break down further
```

## Rules

- NEVER start work without branching first
- Branch naming: `jb/{number}-{slug}` (consistent)
- Always fetch latest before branching
- Show related work to avoid duplicate effort
- Update .issues.json if it exists
