#!/bin/bash
# Claude Code PreToolUse hook: Check if CHANGELOG.md needs updating before commits

# Only run for git commit commands
if [[ ! "$CLAUDE_TOOL_INPUT" =~ "git commit" ]]; then
    exit 0
fi

# Check if we're in a git repo with a CHANGELOG.md
if [[ ! -f "CHANGELOG.md" ]]; then
    exit 0
fi

# Get staged files (excluding CHANGELOG.md itself)
staged_files=$(git diff --cached --name-only 2>/dev/null | grep -v "CHANGELOG.md")

# If no meaningful staged files, exit
if [[ -z "$staged_files" ]]; then
    exit 0
fi

# Check if CHANGELOG.md is staged
changelog_staged=$(git diff --cached --name-only 2>/dev/null | grep "CHANGELOG.md")

# Count meaningful changes (src/, app/, lib/, components/, etc.)
code_changes=$(echo "$staged_files" | grep -E "^(src/|app/|lib/|components/|pages/|prisma/)" | wc -l | tr -d ' ')

# If there are code changes but CHANGELOG isn't staged, warn
if [[ "$code_changes" -gt 0 && -z "$changelog_staged" ]]; then
    echo "WARNING: You're committing $code_changes code file(s) but CHANGELOG.md is not staged."
    echo "Consider updating CHANGELOG.md with a summary of these changes."
    echo ""
    echo "Staged code files:"
    echo "$staged_files" | grep -E "^(src/|app/|lib/|components/|pages/|prisma/)" | head -5
    if [[ "$code_changes" -gt 5 ]]; then
        echo "... and $((code_changes - 5)) more"
    fi
fi
