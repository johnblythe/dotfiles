# dotfiles

Personal dev environment with bootstrap for new machines.

## Quick Start

```bash
git clone https://github.com/johnblythe/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./scripts/bootstrap.sh
```

## What's Included

```
dotfiles/
├── shell/zshrc          # Zsh + Oh My Zsh, nvm, aliases
├── git/gitconfig         # Git config with conditional includes
├── claude/
│   ├── CLAUDE.md         # Global Claude Code instructions
│   ├── commands/         # 8 custom slash commands
│   └── hooks/            # Pre-commit hooks
├── zellij/
│   ├── project.kdl.template
│   └── new-project.sh    # Create project configs
├── ghostty/config        # Terminal theme
└── scripts/bootstrap.sh  # New machine setup
```

## Claude Code Commands

| Command | Purpose |
|---------|---------|
| `/commit` | Commit with changelog, HEREDOC format |
| `/create-pr` | PR from branch with summary + test plan |
| `/branch-start` | Checkout issue branch, fetch latest |
| `/issue` | List, log, close, sync issues (unified) |
| `/pr-review` | Fetch PR comments → todos |
| `/rams` | Accessibility + design audit |
| `/ui-skills` | UI constraints (Tailwind, a11y) |
| `/smart-handoff` | Save session context for `/compact` |

### `/issue` subcommands

```bash
/issue              # list open issues
/issue log <title>  # create issue
/issue close <num>  # close issue
/issue sync         # sync with GitHub + archive plans
```

## Hooks

- `check-changelog.sh` - Warns if code staged without CHANGELOG
- `check-prisma-migrations.sh` - Blocks commits without migrations

## Shell Functions

### `idea "title" [body]`

Create GitHub issue in `johnblythe/ideas`:

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
