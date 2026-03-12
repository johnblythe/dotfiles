Morning context refresh — scan yesterday's Claude sessions and summarize.

## Instructions

1. Run the scanner script to extract session data:
```bash
python3 scripts/morning-refresh.py 24
```
The argument is hours to look back (default 24). Use 48 for Monday mornings.

2. For each session with meaningful work (>5 user messages or substantial content), produce a summary card:

```
### [title] — [project] ([branch])
**Last active:** [mtime]
**What:** [1-2 sentence summary of what was being worked on, derived from user messages]
**Where left off:** [what was the last thing discussed/done]
**Resume:** `claude --resume [session_id]`
```

3. Group sessions by status:
- **Active work** — sessions with substantial progress, likely to resume
- **Quick tasks** — short sessions (few messages), probably done
- **Stale/done** — sessions that look completed

4. At the top, provide a **TL;DR** — 2-3 sentences covering the main threads of work across all sessions.

5. If any sessions share a common thread (e.g., multiple healthsource sessions about the same feature), call that out.

6. End with: "Run `claude --resume <id>` to pick up any session."

## Notes
- Skip sessions that are clearly just one-off questions (copywriting help, quick lookups)
- Focus on sessions where code was being written, investigations were happening, or plans were being made
- The `$ARGUMENTS` value can override the lookback window (e.g., `/morning-refresh 48`)
