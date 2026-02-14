#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "==> Installing dotfiles from $DOTFILES_DIR"

# Install Homebrew if missing
if ! command -v brew &> /dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install essentials
echo "==> Installing essentials via Homebrew..."
brew install gh git nvm zellij

# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Backup existing configs
backup_if_exists() {
  if [ -f "$1" ] && [ ! -L "$1" ]; then
    echo "==> Backing up $1 to $1.bak"
    mv "$1" "$1.bak"
  fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.gitconfig"

# Create config directories
mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks"
mkdir -p "$HOME/.config/zellij"
mkdir -p "$HOME/.config/ghostty"

# Create symlinks
echo "==> Creating symlinks..."
ln -sf "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Claude Code
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
for cmd in "$DOTFILES_DIR/claude/commands"/*.md; do
  ln -sf "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done
for hook in "$DOTFILES_DIR/claude/hooks"/*; do
  ln -sf "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
done

# Ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# Zellij template
ln -sf "$DOTFILES_DIR/zellij/project.kdl.template" "$HOME/.config/zellij/project.kdl.template"
ln -sf "$DOTFILES_DIR/zellij/new-project.sh" "$HOME/.config/zellij/new-project.sh"

# Authenticate GitHub CLI if needed
if ! gh auth status &> /dev/null; then
  echo "==> Authenticating GitHub CLI..."
  gh auth login
fi

# Create ideas repo if it doesn't exist
if ! gh repo view johnblythe/ideas &> /dev/null; then
  echo "==> Creating ideas repo..."
  gh repo create ideas --private --description "Quick ideas captured via CLI"
fi

echo "==> Done! Restart your shell or run: source ~/.zshrc"
