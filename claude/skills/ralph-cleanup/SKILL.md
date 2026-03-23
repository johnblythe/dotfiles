---
name: ralph-cleanup
description: Clean up merged ralph/* branches locally and remotely. Lists branches, shows merge status, deletes merged ones.
---

# Ralph Cleanup

Clean up ralph/* branches that have been merged or are no longer needed.

## Execution

Run these commands to analyze and clean ralph branches:

### 1. List all ralph branches with merge status

```bash
echo "=== Ralph Branches ===" && \
echo "" && \
echo "LOCAL:" && \
for branch in $(git branch | grep 'ralph/' | sed 's/^[* ]*//'); do
  if git branch --merged main | grep -q "$branch"; then
    echo "  [MERGED]   $branch"
  else
    echo "  [UNMERGED] $branch"
  fi
done && \
echo "" && \
echo "REMOTE:" && \
for branch in $(git branch -r | grep 'origin/ralph/' | sed 's/^[* ]*//'); do
  local_name=$(echo "$branch" | sed 's|origin/||')
  if git branch --merged main | grep -q "$local_name" 2>/dev/null || \
     git log main.."$branch" --oneline 2>/dev/null | head -1 | grep -q '^$'; then
    echo "  [MERGED]   $branch"
  else
    echo "  [UNMERGED] $branch"
  fi
done
```

### 2. Delete merged local branches

```bash
echo "Deleting merged local ralph/* branches..." && \
for branch in $(git branch --merged main | grep 'ralph/' | sed 's/^[* ]*//'); do
  echo "  Deleting: $branch"
  git branch -d "$branch"
done && \
echo "Done."
```

### 3. Delete merged remote branches

```bash
echo "Deleting merged remote ralph/* branches..." && \
for branch in $(git branch -r --merged main | grep 'origin/ralph/' | sed 's|origin/||'); do
  echo "  Deleting: origin/$branch"
  git push origin --delete "$branch" 2>/dev/null || echo "    (already deleted or protected)"
done && \
echo "Done."
```

### 4. Prune stale remote tracking branches

```bash
git fetch --prune
```

## Interactive Mode

When user runs `/ralph-cleanup`, execute in this order:

1. **Show status first** (step 1) - list all branches with merge status
2. **Ask user** which to delete:
   - "Delete all merged branches (local + remote)?"
   - "Delete only local merged?"
   - "Skip deletion, just showing status"
3. Execute chosen option

## Safety

- NEVER delete unmerged branches without explicit user confirmation
- NEVER delete `main` or `master`
- Show what will be deleted BEFORE deleting
- Use `-d` (safe delete) not `-D` (force delete) for local branches
