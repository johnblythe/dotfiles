---
name: changelog-commit
description: Enforce CHANGELOG updates before commits. Use when committing code changes to ensure CHANGELOG.md is updated for features, fixes, and breaking changes.
---

# Commit with CHANGELOG Enforcement

Before creating any git commit, follow this checklist:

## Step 1: Check Staged Changes

```bash
git status
git diff --cached --stat
```

Categorize the changes:
- **Feature**: New functionality
- **Fix**: Bug fix
- **Refactor**: Code restructuring without behavior change
- **Chore**: Config, dependencies, tooling
- **Test**: Test-only changes
- **Docs**: Documentation-only changes

## Step 2: Determine if CHANGELOG Update Needed

**REQUIRES CHANGELOG update:**
- Any new feature
- Any bug fix
- Breaking changes
- Security fixes
- Removed functionality
- Significant refactors affecting user experience

**SKIP CHANGELOG for:**
- Test-only changes
- Comment-only changes
- Typo fixes in code
- Config/tooling changes (unless user-facing)
- Documentation-only changes

## Step 3: Update CHANGELOG (if needed)

If CHANGELOG update is needed AND a CHANGELOG.md exists in the project:

1. Read current CHANGELOG.md
2. Add entry under `## [Unreleased]` section (create if missing)
3. Use correct category: Added, Changed, Fixed, Removed, Security
4. Include issue/PR number if applicable: `(#123)`
5. Be concise but descriptive
6. Stage the CHANGELOG: `git add CHANGELOG.md`

Format example:
```markdown
## [Unreleased]

### Added
- **Feature name (#123)**: Brief description of what was added

### Fixed
- **Bug description (#456)**: What was broken and how it was fixed
```

## Step 4: Create Commit

Only AFTER completing steps 1-3:

```bash
git commit -m "$(cat <<'EOF'
<type>: <description>

<optional body>
EOF
)"
```

Types: feat, fix, refactor, chore, test, docs

## Step 5: Verify

```bash
git log -1 --stat
```

Confirm the commit includes all intended changes (and CHANGELOG if applicable).

---

**IMPORTANT**: When in doubt, add a CHANGELOG entry. Users appreciate knowing what changed.
