---
name: jj-workspaces
description: Manage jj workspaces for parallel feature development. Use when creating, working in, or cleaning up jj workspaces. Covers the full lifecycle — create, symlink, work, push, cleanup.
---

# jj Workspaces for Parallel Feature Work

**Announce:** "Using jj-workspaces skill for workspace [create|cleanup|management]."

## How jj Workspaces Work

`jj workspace add` does NOT copy the repo. It creates a new working directory that shares the same `.jj` store (like `git worktree add`). All workspaces see the same history, bookmarks, and commits. Each workspace just gets its own checked-out files.

**Key implication:** `jj git fetch` from ANY workspace updates ALL workspaces' view of remote state.

## When to Spawn a Workspace

Brainstorm, plan, and explore in basecamp (default workspace). Spawn a workspace when you're ready to write source code.

| Activity | Where | Why |
|----------|-------|-----|
| `/brainstorm`, `/plan` | Basecamp | Output is docs — no isolation needed |
| Read code, grep, explore | Basecamp | Read-only, no side effects |
| Write `docs/plans/*.md` | Basecamp | Docs commit with feature branch later or independently |
| Create/edit source files | **Workspace** | Needs npm install, dev server, isolation |
| `/dev/*` exploration pages | **Workspace** | Touches source + needs running app |
| Tests, builds, migrations | **Workspace** | Env-dependent, port conflicts |

**The trigger:** "I'm about to touch source code" → spawn workspace.

## Default Workspace = Control Room

Keep the default workspace parked on `main`. Don't do feature work there.

Why:
- `jj git fetch` + auto-rebase in default can create surprise conflicts if you have in-progress work
- Workspace creation, bookmark management, and cleanup are cleanest from a neutral base
- Avoids "which workspace am I in?" confusion

If the user IS working in default on a feature, warn them but don't block — it works, it's just riskier for multi-workspace flows.

## Create a Workspace

### 1. Name convention

Directory: `<project>-<feature-short-name>` as sibling to main repo.
Bookmark: `feat/<feature-name-issue>` or `fix/<name-issue>`.

Example: repo at `~/code/jb/travel` → workspace at `~/code/jb/travel-vet-itin`.

### 2. Create

```bash
# From the default workspace (control room)
cd ~/code/jb/travel
jj workspace add ../travel-my-feature --name my-feature
cd ../travel-my-feature
```

### 3. Set up working commit + bookmark

```bash
jj new main                              # fresh commit off main
jj bookmark create feat/my-feature-123   # trackable name for push/PR
jj describe -m "feat: short description (#123)"
```

### 4. Symlink env files (REQUIRED — app won't run without this)

Env files are .gitignored so jj doesn't track them. The new workspace has NO env files. You MUST symlink them before `npm run dev` or tests will work.

```bash
# Always do this — non-negotiable
ln -s ../travel/.env.local .env.local 2>/dev/null
ln -s ../travel/.env .env 2>/dev/null

# Check for any others the project needs
ls ../travel/.env* 2>/dev/null
# Symlink each one that exists:
# ln -s ../travel/.env.development.local .env.development.local
```

**Verify:** `ls -la .env*` should show symlinks pointing to the main repo.

### 5. Install dependencies

```bash
npm install   # or bun install, yarn, etc.
```

### 6. Verify

```bash
jj status          # should show clean working copy
jj workspace list  # should show both default and new workspace
```

## Work in a Workspace

Normal jj workflow. Nothing special.

```bash
# Edit files, jj tracks automatically
jj describe -m "feat: updated description (#123)"
jj git push --bookmark feat/my-feature-123
```

### Staying current with main

```bash
jj git fetch              # updates shared repo (affects all workspaces)
jj rebase -d main         # rebase current workspace's commit onto latest main
# Resolve conflicts if any, then push
jj git push --bookmark feat/my-feature-123
```

### Multiple commits (rare in jj, but possible)

```bash
jj new                    # creates new commit on top of current
jj describe -m "fix: address review feedback"
```

## Push + PR

```bash
jj git push --bookmark feat/my-feature-123

# Create PR (from any directory, gh doesn't care)
gh pr create --repo owner/repo --head feat/my-feature-123 \
  --title "feat: title" --body "..."
```

## Cleanup After Merge

**Order matters: forget before rm.**

```bash
# 1. Go to default workspace (control room)
cd ~/code/jb/travel

# 2. Forget the workspace (tells jj to stop tracking it)
jj workspace forget my-feature

# 3. Remove the directory
rm -rf ../travel-my-feature

# 4. Clean up stale bookmarks (if not auto-deleted by GitHub)
jj bookmark delete feat/my-feature-123 2>/dev/null

# 5. Fetch to sync state
jj git fetch
```

**Why this order:**
- `forget` before `rm -rf` — if you rm first, jj gets confused trying to update a missing dir
- `bookmark delete` after forget — the bookmark may have been auto-pruned by fetch, but clean up explicitly to be safe
- `fetch` last — pulls any remote bookmark deletions from merged PRs

## Quick Reference

| Task | Command |
|------|---------|
| List workspaces | `jj workspace list` |
| Create workspace | `jj workspace add ../path --name short-name` |
| Forget workspace | `jj workspace forget short-name` |
| List bookmarks | `jj bookmark list` |
| Delete stale bookmark | `jj bookmark delete name` |
| Check conflicts | `jj status` (look for `(conflict)`) |
| Resolve conflicts | Edit conflict markers in file, then `jj` auto-detects resolution |

## Sharp Edges

### Conflict markers are different from git
jj uses `<<<<<<<`, `%%%%%%%` (diff), `+++++++` (content), `>>>>>>>`. Read the labels — they tell you which side is which. The `%%%%%%%` section shows a diff to apply, not raw content.

### `jj git fetch` is global
Running it in any workspace updates the shared repo. If another workspace has in-progress work, its commit may get rebased and conflict. This is usually fine — jj handles it — but be aware.

### Bookmarks with conflicts
After fetch, you may see "These bookmarks have conflicts." This means local and remote diverged. Fix with:
```bash
jj bookmark set <name> -r <rev>   # point it where you want
# or just delete if the branch is merged:
jj bookmark delete <name>
```

### node_modules is per-workspace
Each workspace needs its own `npm install`. The directory isn't shared.

### .env.local must be symlinked
It's .gitignored so jj doesn't track it. Every new workspace needs the symlink.

## Anti-patterns

| Don't | Do instead |
|-------|------------|
| Work on features in default workspace | Spawn a workspace, keep default on main |
| `rm -rf` before `jj workspace forget` | Always forget first, rm second |
| Forget to symlink .env.local | Symlink immediately after workspace creation |
| Leave merged workspaces around | Clean up after each merge |
| Run `jj git fetch` while mid-conflict-resolution | Finish resolving first, then fetch |
