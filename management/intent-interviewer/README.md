# Intent Interviewer

Generate CLAUDE.md files through SME knowledge capture.

## What It Does

Captures the **Intent Layer** - knowledge that isn't in the code:
- What the service owns vs what people wrongly assume
- Entry points and contracts
- Patterns and anti-patterns
- Gotchas and "haunted" areas
- External dependency pain points

## Two Modes

### Mode 1: Async Questionnaire (No CLI Required)

For SMEs without Claude Code installed:

```bash
# 1. Generate questionnaire
./generate-questionnaire.sh intakeservices

# 2. Send to SME - they fill it out in any text editor
#    Output: questionnaires/intakeservices-questionnaire-2026-01-07.md

# 3. Process the filled questionnaire
./process-questionnaire.sh questionnaires/intakeservices-questionnaire-filled.md
```

### Mode 2: Live Interview (Requires Claude CLI)

For SMEs with Claude Code:

```bash
./interview.sh intakeservices
```

Interactive Q&A session, ~15 minutes.

## Pilot Services

- `intakeservices`
- `workflow`
- `searchservices`
- `securityservices`

## Files

```
intent-interviewer/
├── generate-questionnaire.sh  # Create async questionnaire
├── process-questionnaire.sh   # Process filled questionnaire → CLAUDE.md
├── interview.sh               # Live interview (requires CLI)
├── PROMPT.md                  # Agent instructions
├── questions.yaml             # Stock question bank
├── questionnaires/            # Generated questionnaires
└── README.md
```

## Output

Creates `CLAUDE.md` in the service directory:
```
healthsource/services/intakeservices/CLAUDE.md
```

## Question Categories

1. **Scope & Boundaries** - What it owns, what it doesn't
2. **Entry Points** - Where to start, back doors
3. **Patterns** - The "right way" to do things
4. **Gotchas** - Top mistakes, hidden dangers
5. **State & Data** - Shared state, caching, source of truth
6. **External Dependencies** - Flaky APIs, critical configs
7. **Testing** - What's hard, what setup is needed
8. **History** - Incidents, refactors, war stories
