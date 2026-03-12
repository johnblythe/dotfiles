# Raycast Jira Commands

Quick launcher access to Jira command center.

## Setup

1. Open Raycast
2. Go to Extensions → Script Commands
3. Click "Add Script Directory"
4. Select this folder: `~/code/management/raycast`

## Available Commands

Type in Raycast:

| Command | Icon | Description |
|---------|------|-------------|
| `jira dashboard` | 📊 | Full command center view |
| `jira standup` | ☀️ | Daily standup summary |
| `jira risk` | ⚠️ | At-risk items |
| `jira burndown` | 📉 | Sprint progress |
| `jira executive` | 👔 | Stakeholder summary |
| `jira capacity` | 👥 | Team load |
| `jira hygiene` | 🧹 | Sprint audit |
| `jira velocity` | 🚀 | Velocity report |

## Usage

Each command accepts an optional team argument:
- Default: `platform`
- Options: `platform`, `roio`, `roip`

Example: Type "jira standup" then "roio" to see ROIO standup.
