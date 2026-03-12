---
name: playground
description: Create visual artifacts to prove out ideas — Mermaid diagrams rendered in HTML, interactive data playgrounds, ASCII system sketches, and comparison layouts. Use when you need something tangible to show in a meeting or paste in a ticket.
---

# Playground

Create visual proof-of-concept artifacts. One command → open in browser → walk into the meeting armed.

## Usage

```
/playground mermaid sequence diagram of the intake flow
/playground dashboard showing queue distribution by team
/playground compare before/after for the new fulfillment workflow
/playground ascii diagram of request routing
/playground                    # interactive — what do you want to visualize?
```

## Artifact Types

### 1. Mermaid Diagrams (rendered in HTML)

For flowcharts, sequence diagrams, ER diagrams, state machines, Gantt charts.

**When to use:** System flows, API sequences, data relationships, workflow states.

Generate a self-contained HTML file that renders Mermaid via CDN:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Diagram Title]</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    background: #faf6f0;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 2rem;
    color: #1c1917;
  }
  h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
  .subtitle { color: #78716c; margin-bottom: 2rem; font-size: 0.9rem; }
  .mermaid { background: white; padding: 2rem; border-radius: 12px; border: 2px solid #e7e5e4; max-width: 100%; overflow-x: auto; }
  .legend { margin-top: 1.5rem; font-size: 0.85rem; color: #44403c; max-width: 700px; }
  .legend dt { font-weight: 600; margin-top: 0.5rem; }
  .legend dd { margin-left: 1rem; }
</style>
</head>
<body>
  <h1>[Title]</h1>
  <p class="subtitle">[One-line description]</p>
  <div class="mermaid">
    [mermaid diagram code]
  </div>
  <dl class="legend">
    [optional legend entries]
  </dl>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({ startOnLoad: true, theme: 'neutral' });</script>
</body>
</html>
```

**Mermaid quick reference:**

```
%% Flowchart
graph TD
  A[Start] --> B{Decision}
  B -->|Yes| C[Action]
  B -->|No| D[Other]

%% Sequence
sequenceDiagram
  User->>Service: Request
  Service->>DB: Query
  DB-->>Service: Results
  Service-->>User: Response

%% State
stateDiagram-v2
  [*] --> Logging
  Logging --> Fulfillment: Complete
  Logging --> LoggingException: Error
  LoggingException --> Logging: Resolved

%% ER Diagram
erDiagram
  EREQUEST ||--o{ STATUS : has
  EREQUEST ||--o{ EXCEPTION : has
  EXCEPTION }o--|| REASON : references
```

### 2. Interactive Data Playgrounds

For dashboards, data comparisons, heatmaps, charts.

**When to use:** Presenting data patterns, queue distributions, trend analysis, capacity planning.

Generate a self-contained HTML file with inline data and Chart.js (or pure CSS/SVG for simpler viz):

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[Dashboard Title]</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    background: #0f172a;
    color: #e2e8f0;
    padding: 2rem;
  }
  h1 { font-size: 1.5rem; margin-bottom: 0.25rem; }
  .subtitle { color: #94a3b8; margin-bottom: 2rem; font-size: 0.85rem; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
  .panel {
    background: #1e293b;
    border: 1px solid #334155;
    border-radius: 12px;
    padding: 1.5rem;
  }
  .panel h3 { font-size: 0.9rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; }
  .big-num { font-size: 3rem; font-weight: 800; line-height: 1; }
  .big-label { font-size: 0.8rem; color: #64748b; margin-top: 0.25rem; }
</style>
</head>
<body>
  <h1>[Title]</h1>
  <p class="subtitle">[Description] — Generated [date]</p>
  <div class="grid">
    <!-- panels with charts, numbers, tables -->
  </div>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
  <script>
    // Chart.js instances with inline data
  </script>
</body>
</html>
```

**Design rules for playgrounds:**
- Dark theme by default (looks better on projector, feels "dashboard-y")
- Big numbers for KPIs at top
- Grid layout with panels
- Chart.js for bar/line/pie/doughnut charts
- Pure CSS bars for simple distributions (no library needed)
- Data inline in the HTML (no external fetches)
- Add a "Generated [date]" subtitle so it's clear this is a snapshot

### 3. ASCII Diagrams

For quick inline visuals — Slack, Jira comments, terminal conversations.

**When to use:** Quick system sketches during conversation, too simple for a full HTML file.

**Style rules:**
- Use box-drawing characters: `┌ ┐ └ ┘ │ ─ ├ ┤ ┬ ┴ ┼ ▶ ▼ ◀ ▲`
- Arrows: `→ ← ↓ ↑ ↔`
- Keep width under 70 chars (fits Slack without wrapping)
- Label every box and arrow
- Use indentation to show hierarchy

```
┌─────────────┐     ┌──────────┐     ┌──────────┐
│  Intake      │────▶│  STORK   │────▶│  Queue   │
│  (fax/email) │     │ Classify │     │  Router  │
└─────────────┘     └──────────┘     └────┬─────┘
                                          │
                    ┌─────────────────────┼────────────┐
                    ▼                     ▼            ▼
              ┌──────────┐        ┌──────────┐  ┌──────────┐
              │  Logging  │        │  Fulfill │  │    QC    │
              │  Queue    │        │  Queue   │  │  Queue   │
              └──────────┘        └──────────┘  └──────────┘
```

### 4. Comparison Layouts

For before/after, option A vs B vs C, current vs proposed.

**When to use:** Decision slides, architecture proposals, process changes.

Generate HTML with side-by-side panels:

```html
<div class="comparison">
  <div class="panel before">
    <h3>Current</h3>
    <!-- content -->
  </div>
  <div class="panel after">
    <h3>Proposed</h3>
    <!-- content -->
  </div>
</div>
```

Use red/amber tones for "before" and green/teal for "after". Include callout arrows or annotations for key differences.

## Workflow

### Step 1: Understand the Ask

What are they trying to show? Parse into:
- **Subject**: What system/data/workflow?
- **Type**: Mermaid, playground, ASCII, or comparison?
- **Audience**: Is this for a Jira comment (ASCII), a meeting (HTML), or Confluence (Mermaid)?
- **Data**: Do they have numbers, or do we need to pull from Snowflake/Jira?

If data is needed, use `/snowflake-explorer` or Jira MCP to pull it first, then visualize.

### Step 2: Build

Generate the artifact. For HTML files:
- Save to `/tmp/playground-[slug].html` (ephemeral) unless user specifies a location
- Use descriptive filenames: `queue-distribution.html`, `intake-flow.html`

### Step 3: Open & Iterate

```bash
open /tmp/playground-[slug].html
```

Ask: "How's that look? Want to adjust anything?"

For ASCII diagrams, just output inline — no file needed.

## Output Conventions

| Type | Default location | Format |
|------|-----------------|--------|
| Mermaid HTML | `/tmp/playground-[slug].html` | Self-contained HTML with CDN |
| Data playground | `/tmp/playground-[slug].html` | Self-contained HTML with Chart.js |
| ASCII | Inline in conversation | Plain text |
| Comparison | `/tmp/playground-[slug].html` | Self-contained HTML |

If the user wants to keep the file permanently, suggest saving to `~/code/management/scratchpad/` or their project directory.

## Examples

**"Show me the request lifecycle as a state diagram"**
→ Mermaid stateDiagram-v2 in HTML, showing all statuses and transitions from `request_status` table

**"What does the queue distribution look like right now?"**
→ Pull data via snowflake-explorer, render as dark-themed dashboard with bar charts per queue

**"Draw the intake routing for a Jira comment"**
→ ASCII diagram, under 70 chars wide, with box-drawing characters

**"Compare the current fulfillment flow vs the proposed pre-review flow"**
→ Side-by-side HTML with red/green panels, annotated differences
