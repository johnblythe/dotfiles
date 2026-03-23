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

# Install packages from Brewfile
echo "==> Installing Homebrew packages..."
xargs brew install < "$DOTFILES_DIR/Brewfile"

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
backup_if_exists "$HOME/.zprofile"
backup_if_exists "$HOME/.zshenv"
backup_if_exists "$HOME/.bash_profile"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.gitconfig"

# Create config directories
mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills" "$HOME/.claude/agents"
mkdir -p "$HOME/.config/zellij"
mkdir -p "$HOME/.config/ghostty"

# Create symlinks — shell
echo "==> Creating shell symlinks..."
ln -sf "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/shell/zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/shell/zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/shell/bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"

# Git
ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Claude Code
echo "==> Creating Claude Code symlinks..."
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"

for cmd in "$DOTFILES_DIR/claude/commands"/*.md; do
  ln -sf "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done
for hook in "$DOTFILES_DIR/claude/hooks"/*; do
  ln -sf "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
done
for agent in "$DOTFILES_DIR/claude/agents"/*; do
  ln -sf "$agent" "$HOME/.claude/agents/$(basename "$agent")"
done
for skill in "$DOTFILES_DIR/claude/skills"/*/; do
  skill_name=$(basename "$skill")
  ln -sf "$DOTFILES_DIR/claude/skills/$skill_name" "$HOME/.claude/skills/$skill_name"
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

# Install Claude Code if needed
if ! command -v claude &> /dev/null; then
  echo "==> Install Claude Code: npm install -g @anthropic-ai/claude-code"
fi

# Install nvm if needed
if [ ! -d "$HOME/.nvm" ]; then
  echo "==> Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

echo ""
echo "==> Done! Next steps:"
echo "    1. Restart your shell or run: source ~/.zshrc"
echo "    2. Run: nvm install --lts"
echo "    3. Run: npm install -g @anthropic-ai/claude-code"
echo "    4. Copy ~/.claude/settings.local.json from secure backup (API keys)"
echo "    5. Copy ~/.claude/projects/*/memory/ from backup (Claude memory)"
