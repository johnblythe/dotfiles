# dotfiles

Dev environment + Claude Code workflow for new machines and team onboarding.

## Quick Start

```bash
git clone https://github.com/johnblythe/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./scripts/bootstrap.sh
```

## What's Included

```
dotfiles/
├── claude/
│   ├── CLAUDE.md         # Global instructions — principles, not procedures
│   ├── commands/         # Custom slash commands
│   └── hooks/            # Pre-commit guardrails
├── shell/zshrc           # Zsh + Oh My Zsh, nvm, aliases
├── git/gitconfig          # Git config with conditional includes
├── zellij/               # Terminal multiplexer configs
├── ghostty/config        # Terminal theme
└── scripts/bootstrap.sh  # New machine setup
```

## The Workflow

The full workflow uses custom commands + plugins together. Custom pieces are in this repo; plugins are installed separately.

### Issue → Ship Pipeline

```
/issue log "feature name"     ← create GitHub issue
/branch-start 123             ← branch from issue, fetch context
  ... build ...
/commit                       ← changelog-enforced commit
/create-pr                    ← PR with summary + test plan
/pr-review 456                ← fetch PR comments → todos
```

### Context Management

```
/clean-handoff                ← save context/HANDOFF.md, archive previous, prompt /clear
/smart-handoff                ← legacy: save context/WORKING.md, suggest /compact
```

`/clean-handoff` writes a complete snapshot to `context/HANDOFF.md` — the sole context carrier for the next session. Previous handoffs archive to `context/archive/{date}-{NNN}.md`. SessionStart hook auto-injects the handoff file.

### Quality Gates

```
/rams [file]                  ← WCAG 2.1 accessibility + visual design audit
/ui-skills                    ← opinionated UI constraints (Tailwind, a11y, animation)
```

### Idea Capture

```
/idea explore                 ← deep-dive an idea from the ideas repo
/idea triage                  ← review and prioritize stale ideas
idea "quick thought"          ← shell function → GitHub issue in ideas repo
```

## Commands

| Command | Purpose |
|---------|---------|
| `/branch-start` | Checkout issue branch, fetch context, detect related work |
| `/commit` | Commit with changelog enforcement, HEREDOC format |
| `/create-pr` | PR from branch with summary + test plan |
| `/pr-review` | Fetch PR comments → actionable todos |
| `/issue` | List, log, close, sync GitHub issues |
| `/idea` | Explore, triage, promote ideas |
| `/clean-handoff` | Save HANDOFF.md + archive + prompt /clear |
| `/smart-handoff` | Legacy: save WORKING.md + suggest /compact |
| `/rams` | Accessibility + visual design audit |
| `/ui-skills` | UI constraints (Tailwind, Framer Motion, a11y) |

### `/issue` subcommands

```bash
/issue              # list open issues
/issue log <title>  # create issue
/issue close <num>  # close issue
/issue sync         # sync with GitHub + archive plans
```

## Hooks

Guardrails that run before commits via Claude Code's PreToolUse hooks.

- **check-changelog.sh** — warns if code staged without CHANGELOG update
- **check-prisma-migrations.sh** — blocks commits when schema.prisma changed without a migration file

## Plugins

These aren't in this repo but are part of the workflow. Install via Claude Code plugin system.

| Plugin | Source | Purpose |
|--------|--------|---------|
| **compound-engineering** | every-marketplace | Plan reviews, workflows (/workflows:work, /workflows:plan, /workflows:brainstorm), multi-agent code review, design iteration |
| **superpowers** | superpowers-marketplace | Skills system, TDD enforcement, systematic debugging, parallel agent dispatch |
| **pr-review-toolkit** | claude-code-plugins | Multi-agent PR review (security, performance, types, patterns) |
| **feature-dev** | claude-code-plugins | Guided feature development with architecture focus |
| **frontend-design** | claude-plugins-official | Production-grade UI/component design |
| **dev-browser** | dev-browser-marketplace | Browser automation with persistent page state |
| **document-skills** | anthropic-agent-skills | PDF, PPTX, DOCX, XLSX generation |

## CLAUDE.md Philosophy

The global `CLAUDE.md` sets principles, not step-by-step procedures:

- **Conciseness** — "Orwellian conciseness — sacrifice grammar for brevity"
- **Git safety** — never commit without ask, always use gh CLI, no Co-Authored-By
- **Design** — ASCII mockups before code, split views over full-width stacking
- **Debugging** — 3+ failed attempts → stop, find reference impl
- **Execution** — default to parallelized teams for multi-step work
- **MVP first** — polish second, discuss tiers before building gates

Each project gets its own `CLAUDE.md` for project-specific rules (migrations, build commands, etc.).

## Shell Functions

### `idea "title" [body]`

```bash
idea "Add dark mode"
idea "Refactor auth" "Move to JWT"
idea -l  # list recent
```

### `get <branch>`

Quick checkout + pull: `get main`

## Zellij

Create new project config:

```bash
~/.config/zellij/new-project.sh myapp ~/code/myapp
```
