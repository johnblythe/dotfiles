# dotfiles

Personal shell config with bootstrap for new machines.

## Quick Start

```bash
git clone https://github.com/johnblythe/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./scripts/bootstrap.sh
```

## What's Included

- **shell/zshrc** - Zsh config with Oh My Zsh, nvm, aliases
- **git/gitconfig** - Git config with conditional includes
- **scripts/bootstrap.sh** - New machine setup (Homebrew, gh, symlinks)

## Custom Functions

### `idea "title" [body]`

Create GitHub issue in `johnblythe/ideas` repo:

```bash
idea "Add dark mode to app"
idea "Refactor auth" "Move to JWT tokens"
idea -l  # list recent ideas
```

### `get <branch>`

Quick checkout + pull: `get main`
