# Jira Slack

Post any jira command output to Slack.

## Usage
```bash
/slack standup platform
/slack executive stakeholders
/slack burndown
```

## Quick Run
```bash
bash ~/code/management/scripts/jira-slack.sh <command> [channel]
```

## Commands
standup, risk, capacity, dependencies, burndown, executive, hygiene, velocity

## Setup
Add webhook to `jira-data/config.yaml`:
```yaml
slack:
  default: "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  platform: "https://hooks.slack.com/services/..."
  stakeholders: "https://hooks.slack.com/services/..."
```

Get webhook: https://api.slack.com/messaging/webhooks
