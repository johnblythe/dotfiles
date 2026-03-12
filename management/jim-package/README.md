# PM Power Tools — Claude Code for Product Managers

## Setup
```bash
cd ~/code/management/jim-package
./setup.sh
```

## Quick Reference

### Data & Code (becoming technical)

| Want to... | Do this |
|---|---|
| Query Snowflake in English | `/snowflake-explorer how many requests this week?` |
| Understand code | "What does the fulfillment workflow do?" |
| Trace a bug | "Why would a request get stuck in Logging Exception?" |
| Check architecture | "How does site selection work end-to-end?" |
| Explore a service | "Walk me through intakeservices request routing" |

### Jira & Reporting (staying on top)

| Want to... | Do this |
|---|---|
| Create a ticket | `/create-ticket fix the login timeout bug` |
| Sprint update for stakeholders | `/sprint-digest` |
| Project running-log entry | `/project-status-update` |
| Executive summary | `/executive` |
| Idea deep-dive | `/idea-overview PDCR-404` |
| Idea weekly pulse | `/idea-pulse PDCR-404` |
| Risk scan | `/risks` |
| Portfolio view | `/portfolio` |
| Sprint hygiene audit | `/hygiene` |

### Thinking & Shaping (going deeper)

| Want to... | Do this |
|---|---|
| Shape a problem + solution | `/shaping` |
| Brainstorm before jumping in | "Let's brainstorm approaches to X" |
| Write an implementation plan | "Write a plan for this spec: ..." |
| Map a system workflow | `/breadboarding` |
| Benchmark against industry | `/benchmark is our approach standard?` |

### Proving & Communicating (showing the work)

| Want to... | Do this |
|---|---|
| ASCII diagram | "Draw an ASCII diagram of the intake flow" |
| Mermaid flowchart | "Create a mermaid sequence diagram for request routing" |
| Interactive HTML proof | "Build an HTML playground showing the queue distribution" |
| Summarize a Slack thread | Paste it + "Turn this into leadership bullet points" |
| Turn meeting notes into tickets | Paste notes + "Extract action items as Jira tickets" |

## Tips

- **Ask the code questions directly.** No special syntax needed. "Where does X happen?" and "How does Y work?" just work.
- **Always get the SQL.** Snowflake explorer shows every query it runs. Copy and tune them to build your own SQL fluency.
- **Shape before solutioning.** Use `/shaping` to explore the problem space before jumping to implementation.
- **Prove it visually.** Ask for HTML playgrounds, mermaid charts, or ASCII diagrams to walk into meetings with something tangible.
- **Benchmark when challenged.** When someone asks "why this way?" — run `/benchmark` and come back with cited sources.
