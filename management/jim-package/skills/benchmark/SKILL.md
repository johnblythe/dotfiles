---
name: benchmark
description: Pressure-test our approaches against industry standards. Web research → comparison table with cited sources → defensible talking points. Use when someone asks "why this way?"
---

# Benchmark

Research how the industry handles a given problem and compare against our approach. Produces a defensible brief with sources.

## Usage

```
/benchmark is our fulfillment SLA competitive?
/benchmark how do other HIM platforms handle intake classification?
/benchmark what's the standard approach to pre-fulfillment review?
/benchmark                    # interactive — what do you want to benchmark?
```

## Workflow

### Step 1: Frame the Question

Parse the user's question into:
- **Our approach**: What we currently do (or are proposing). Check codebase, PRDs in `~/code/management/ideas/`, CLAUDE.md architecture notes, or ask the user.
- **The benchmark question**: What specifically are we comparing? (SLA, architecture pattern, workflow design, technology choice, etc.)
- **Industry context**: Healthcare HIM, medical records, ROI (Release of Information) — narrow the search domain.

If the user's question is vague ("is this good?"), ask: "What specifically should I compare — the architecture, the SLA targets, the workflow design, or something else?"

### Step 2: Research

Use `WebSearch` to find:

1. **Industry standards & benchmarks** — AHIMA guidelines, HIM best practices, healthcare IT standards, HIPAA requirements
2. **Competitor approaches** — how other ROI/HIM platforms (Verisma, MRO, ScanSTAT, ChartSwap) handle the same problem
3. **Technology patterns** — how similar-scale systems in healthcare solve the technical challenge (architecture, tooling, performance benchmarks)
4. **Analyst reports** — Gartner, KLAS, Chilmark, Class Research on HIM/ROI if available

Run 3-5 searches with different angles. Example search patterns:
- `"release of information" <topic> best practices 2025`
- `healthcare HIM <topic> industry standard`
- `medical records <topic> SLA benchmark`
- `<competitor> <topic> approach`

Use `WebFetch` to pull details from promising results. Prioritize:
- Official standards bodies (AHIMA, ONC, CMS)
- Peer-reviewed or analyst content
- Vendor documentation that reveals implementation patterns
- Conference presentations (HIMSS, AHIMA) with concrete data

### Step 3: Compare

Build a comparison table:

```markdown
## Benchmark: [Topic]

### Our Approach
[2-3 sentence summary of what we do / are proposing]

### Industry Comparison

| Dimension | Our Approach | Industry Standard | Gap? |
|-----------|-------------|-------------------|------|
| [metric 1] | [what we do] | [what's typical] | [ahead/behind/aligned] |
| [metric 2] | ... | ... | ... |
| [metric 3] | ... | ... | ... |

### Key Findings
1. [Most important finding]
2. [Second finding]
3. [Third finding]

### Defensible Talking Points
When someone asks "why this way?":
- **Point 1**: "[Claim]" — supported by [source]
- **Point 2**: "[Claim]" — supported by [source]
- **Point 3**: "[Claim]" — supported by [source]

### Where We Could Improve
- [Gap 1]: [What the industry does better and what it would take to close]
- [Gap 2]: ...

### Sources
1. [Title](URL) — [one-line description of what it contributes]
2. [Title](URL) — ...
3. ...
```

### Step 4: Deliver

Present the comparison. Then ask:
- "Want me to dig deeper on any dimension?"
- "Should I turn this into a Confluence page or Jira ticket?"
- "Want the talking points formatted for a specific audience (leadership, engineering, stakeholders)?"

## Quality Rules

- **Always cite sources.** No unsourced claims. If you can't find a source, say "I couldn't find published benchmarks for X."
- **Be honest about gaps.** Don't spin weaknesses as strengths. The point is defensibility, which requires acknowledging where we're behind.
- **Distinguish standards from opinions.** AHIMA guidelines ≠ a random blog post. Label the authority level.
- **Date your sources.** Healthcare changes fast. A 2019 benchmark may be outdated.
- **Show your search terms.** If the user wants to do their own research, they should be able to pick up where you left off.

## Example

**User**: "Is our approach to request classification competitive?"

**Response**:

## Benchmark: Request Classification

### Our Approach
HealthSource uses STORK for automated classification of incoming medical record requests. Requests are classified by major class (CLIN, ATTY, PAT, INS, GOV, PAYD) and routed accordingly. Manual override available. Pull List option bypasses classification entirely.

### Industry Comparison

| Dimension | HealthSource | Industry Typical | Gap? |
|-----------|-------------|-----------------|------|
| Automation | STORK classifier (rule-based + ML) | Mix of rule-based and NLP; most still manual-heavy | Ahead |
| Classification categories | 6 major classes | 4-8 typical; AHIMA recommends purpose-based | Aligned |
| Override/bypass | Pull List toggle, manual override | Manual override standard; bypass less common | Ahead |
| Classification accuracy | (need data) | 85-92% for automated systems (AHIMA 2023) | Need data |
| Time to classify | (need data) | 2-5 min manual; <30s automated | Need data |

### Defensible Talking Points
- **"We're ahead on automation"** — most HIM platforms still rely heavily on manual classification (KLAS 2024 HIM report)
- **"Our category structure follows AHIMA guidance"** — purpose-based classification aligned with AHIMA Practice Brief on ROI
- **"Pull List bypass is a differentiator"** — reduces unnecessary classification overhead for known-good requests

### Where We Could Improve
- **Classification accuracy metrics**: We should measure and publish our accuracy rate to compare against the 85-92% industry range
- **NLP/LLM classification**: Emerging competitors are using LLMs for context-aware classification beyond rule-based approaches

### Sources
1. [AHIMA Practice Brief: Release of Information](URL) — classification category guidance
2. [KLAS HIM 2024 Report](URL) — automation adoption rates
3. ...
