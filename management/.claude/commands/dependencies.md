# Jira Dependencies

Cross-team blockers and waiting items.

## Usage
```bash
/dependencies
/dependencies --team roio
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-dependencies.sh
```

## Sections
- 🚫 Blocked items (status or label)
- 🔗 Items with blocker links
- 🌐 Cross-project dependencies (HEAL→ROIO, etc.)
- ⏳ Potentially waiting (stale In Progress)
