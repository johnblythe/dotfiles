#!/bin/bash
# Jim's Claude Code Setup
# Run once to bootstrap Snowflake, plugins, skills, commands, and config.

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${BOLD}$1${NC}"; }

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ─── 1. Claude Code ─────────────────────────────────────────
step "1/8 — Checking Claude Code"
if command -v claude &>/dev/null; then
  ok "Claude Code installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
else
  fail "Claude Code not found."
  echo "    Install: https://docs.anthropic.com/en/docs/claude-code/getting-started"
  exit 1
fi

# ─── 2. Plugins ──────────────────────────────────────────────
step "2/8 — Installing plugins"

PLUGINS=(
  "superpowers"          # brainstorming, writing-plans, debugging
  "compound-engineering" # deepen-plan, plan_review, workflows
  "atlassian"            # Jira/Confluence MCP integration
  "document-skills"      # PDF, XLSX, PPTX, DOCX creation
)

for plugin in "${PLUGINS[@]}"; do
  echo "  Installing $plugin..."
  if claude plugins install "$plugin" 2>/dev/null; then
    ok "Plugin: $plugin"
  else
    warn "Plugin $plugin may already be installed or failed. Check: claude plugins list"
  fi
done

# ─── 3. SnowSQL ─────────────────────────────────────────────
step "3/8 — Checking SnowSQL"
SNOWSQL="/Applications/SnowSQL.app/Contents/MacOS/snowsql"

if [ -f "$SNOWSQL" ]; then
  ok "SnowSQL found at $SNOWSQL"
else
  warn "SnowSQL not found. Installing via brew..."
  if command -v brew &>/dev/null; then
    brew install --cask snowflake-snowsql
    if [ -f "$SNOWSQL" ]; then
      ok "SnowSQL installed"
    else
      fail "Install completed but binary not found at expected path. Check: brew info snowflake-snowsql"
    fi
  else
    fail "Homebrew not found. Install SnowSQL manually:"
    echo "    https://docs.snowflake.com/en/user-guide/snowsql-install-config"
    echo "    Or: brew install --cask snowflake-snowsql"
  fi
fi

# ─── 4. SnowSQL Config ──────────────────────────────────────
step "4/8 — Configuring SnowSQL"
SNOWSQL_CONFIG="$HOME/.snowsql/config"

if [ -f "$SNOWSQL_CONFIG" ] && grep -q "\[connections.datavant\]" "$SNOWSQL_CONFIG" 2>/dev/null; then
  ok "Datavant connection already configured"
else
  mkdir -p "$HOME/.snowsql"

  read -p "  Enter your Datavant email (e.g., jim.smith@datavant.com): " JIM_EMAIL

  if [ -f "$SNOWSQL_CONFIG" ]; then
    cat >> "$SNOWSQL_CONFIG" << EOF

[connections.datavant]
accountname = datavantorg-datavant
username = ${JIM_EMAIL}
authenticator = externalbrowser
dbname = HEALTHSOURCE
schemaname = CONNEX
warehousename = ENG_PROVIDER
rolename = ENG_PROVIDER

[options]
auto_completion = True
client_store_temporary_credential = True
timing = True
output_format = psql
EOF
  else
    cat > "$SNOWSQL_CONFIG" << EOF
[connections.datavant]
accountname = datavantorg-datavant
username = ${JIM_EMAIL}
authenticator = externalbrowser
dbname = HEALTHSOURCE
schemaname = CONNEX
warehousename = ENG_PROVIDER
rolename = ENG_PROVIDER

[options]
auto_completion = True
client_store_temporary_credential = True
timing = True
output_format = psql
EOF
  fi
  ok "Datavant connection configured in $SNOWSQL_CONFIG"
fi

# ─── 5. Test Snowflake Connection ────────────────────────────
step "5/8 — Testing Snowflake connection"
echo "  This will open a browser for SSO. Authenticate when prompted."
read -p "  Test connection now? (y/N): " TEST_SF

if [[ "$TEST_SF" =~ ^[Yy]$ ]]; then
  echo "SELECT 'connected' AS status;" > /tmp/sf_test.sql
  if $SNOWSQL -c datavant -f /tmp/sf_test.sql 2>/dev/null | grep -q "connected"; then
    ok "Snowflake connection verified"
  else
    warn "Connection test inconclusive. You may need Snowflake access provisioned."
    echo "    Ask your manager or IT to grant ENG_PROVIDER role access."
  fi
  rm -f /tmp/sf_test.sql
else
  warn "Skipped. Test manually: $SNOWSQL -c datavant -q 'SELECT CURRENT_USER()'"
fi

# ─── 6. Install CLAUDE.md ───────────────────────────────────
step "6/8 — Installing CLAUDE.md"
mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  warn "Existing CLAUDE.md found. Backing up to CLAUDE.md.bak"
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
fi

cp "$PACKAGE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
ok "CLAUDE.md installed to $CLAUDE_DIR/CLAUDE.md"

# ─── 7. Install Skills ──────────────────────────────────────
step "7/8 — Installing skills"
SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"

# Skills from this package (snowflake-explorer, benchmark, playground)
for skill_dir in "$PACKAGE_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$SKILLS_DIR/$skill_name"
  cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
  ok "Installed skill: $skill_name"
done

# Shared skills from John's global toolkit
GLOBAL_SKILLS_SRC="$HOME/.claude/skills"
SHARED_GLOBAL=(shaping breadboarding create-ticket)

for skill in "${SHARED_GLOBAL[@]}"; do
  if [ -d "$GLOBAL_SKILLS_SRC/$skill" ] && [ ! -d "$SKILLS_DIR/$skill" ]; then
    cp -r "$GLOBAL_SKILLS_SRC/$skill" "$SKILLS_DIR/$skill"
    ok "Copied shared skill: $skill"
  elif [ -d "$SKILLS_DIR/$skill" ]; then
    ok "Skill already installed: $skill"
  else
    warn "Shared skill not found: $skill (ask John for a copy)"
  fi
done

# ─── 8. Install Commands ────────────────────────────────────
step "8/8 — Installing slash commands"
COMMANDS_DIR="$CLAUDE_DIR/commands"
mkdir -p "$COMMANDS_DIR"

# Commands from the management repo
MGMT_COMMANDS="$PACKAGE_DIR/../.claude/commands"
PM_COMMANDS=(
  sprint-digest
  executive
  project-status-update
  idea-overview
  idea-pulse
  risks
  portfolio
  hygiene
  standup
  triage
)

for cmd in "${PM_COMMANDS[@]}"; do
  if [ -f "$MGMT_COMMANDS/$cmd.md" ]; then
    cp "$MGMT_COMMANDS/$cmd.md" "$COMMANDS_DIR/$cmd.md"
    ok "Installed command: /$cmd"
  else
    warn "Command not found: $cmd.md"
  fi
done

# ─── Done ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Setup complete.${NC}"
echo ""
echo "Installed:"
echo "  - CLAUDE.md (foundation config)"
echo "  - Plugins: superpowers, compound-engineering, atlassian, document-skills"
echo "  - Skills: snowflake-explorer, benchmark, playground, shaping, breadboarding, create-ticket"
echo "  - Commands: sprint-digest, executive, project-status-update, idea-overview, idea-pulse, + more"
echo ""
echo "Next steps:"
echo "  1. Open a terminal and run: cd ~/code/healthsource && claude"
echo "  2. Try: /snowflake-explorer how many requests were created this week?"
echo "  3. Try: What does the fulfillment workflow do?"
echo "  4. Try: /benchmark is our intake SLA competitive?"
echo "  5. Try: /brainstorm approaches to reducing intake exceptions"
echo ""
echo "Full cheat sheet: $PACKAGE_DIR/README.md"
