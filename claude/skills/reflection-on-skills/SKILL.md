---
name: reflecting-on-skills
description: Analyzes skill usage and suggests improvements. Automatically invoked after other skills via PostToolUse hook. Enables continuous improvement through self-reflection on errors, inefficiencies, and gaps.
---

# Reflecting on Skills

This skill is automatically triggered after any other skill completes (via a PostToolUse hook).

## Instructions

When invoked after another skill completes:

1. **Identify the skill** - Determine which skill was just used from conversation context

2. **Launch background analysis** - Use the Task tool:
   ```
   Task tool with:
     subagent_type: "general-purpose"
     run_in_background: true
     prompt: [see below]
   ```

3. **Subagent prompt template**:
   ```
   Analyze the skill that was just used in this conversation.

   1. Read the skill's SKILL.md file at: ~/.claude/skills/[skill-name]/SKILL.md
   2. Review the conversation to identify:
      - Errors or exceptions encountered
      - Unclear or missing instructions that caused confusion
      - Edge cases the skill didn't handle
      - Inefficiencies or unnecessary steps
      - Deviations from the skill's guidance (may indicate gaps)

   3. If issues found, draft SPECIFIC improvements:
      - Exact text to add/change in SKILL.md
      - Keep changes minimal and focused
      - Only address observed issues, not hypotheticals

   4. If improvements warranted, use AskUserQuestion:
      - Present the issue observed
      - Show the proposed change
      - Ask: "Apply this improvement to [skill-name]?"

   5. If approved, use Edit tool to update the skill's SKILL.md

   If no issues observed, complete silently without prompting.
   ```

4. **Continue conversation** - Don't wait for reflection to complete

## Hook Configuration

This skill is triggered by a PostToolUse hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/post-skill-reflect.py"
          }
        ]
      }
    ]
  }
}
```

The hook script at `~/.claude/hooks/post-skill-reflect.py` excludes this skill to prevent infinite loops.

## What Makes a Good Suggestion

**Good** (observed issue):
- "User got FileNotFoundError - add note about checking file exists"
- "Instructions said X but user needed Y - clarify the step"

**Bad** (hypothetical):
- "Might be nice to add error handling for edge cases"
- "Could improve by adding more examples"
