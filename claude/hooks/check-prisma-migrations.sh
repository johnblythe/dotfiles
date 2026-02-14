#!/bin/bash
# Claude Code PreToolUse hook: Ensure prisma migrations exist before commits

# Only run for git commit commands
if [[ ! "$CLAUDE_TOOL_INPUT" =~ "git commit" ]]; then
    exit 0
fi

# Check if prisma schema is staged
schema_staged=$(git diff --cached --name-only 2>/dev/null | grep -E "prisma/schema\.prisma$")

if [[ -z "$schema_staged" ]]; then
    exit 0
fi

# Schema is staged - check if there's a new migration
migration_staged=$(git diff --cached --name-only 2>/dev/null | grep -E "prisma/migrations/.*/migration\.sql$")

if [[ -z "$migration_staged" ]]; then
    echo "BLOCKED: prisma/schema.prisma is staged but no migration file found."
    echo ""
    echo "You modified the Prisma schema but didn't create a migration."
    echo "This will break production deployments."
    echo ""
    echo "Run this BEFORE committing:"
    echo "  npx prisma migrate dev --name <describe_your_change>"
    echo ""
    echo "Then stage the new migration:"
    echo "  git add prisma/migrations/"
    exit 1
fi

echo "✓ Prisma migration found for schema changes"
exit 0
