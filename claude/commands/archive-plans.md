---
description: Archive completed plan files when their linked issues are closed
---

Archive plan files whose linked GitHub issues have been closed.

**Prerequisites:**
- `.issues.json` exists in project root (run `/sync-issues` first if not)
- `plans/` directory exists

**Steps:**

1. **Load closed issues:**
   ```bash
   # Get list of closed issue numbers from .issues.json
   ```
   Extract all `number` values where `status === "closed"`

2. **Ensure archive dir exists:**
   ```bash
   mkdir -p plans/archived
   ```

3. **Scan plans/ for .md files (excluding archived/):**
   ```bash
   find plans -maxdepth 1 -name "*.md" -type f
   ```

4. **For each plan file, extract linked issue:**

   **Step A - Check filename first (fewer tokens):**
   ```
   Pattern: ^\d+-.+\.md$
   Example: 108-reassess-travel-time.md → issue #108
   ```

   **Step B - If no filename match, check frontmatter:**
   Read first 30 lines, look for patterns (case-insensitive):
   ```
   Issue: #123
   Issue #123
   issue: 123
   Related: #123
   **Issue:** #123
   Closes #123
   ```
   Regex: `/(?:issue|related|closes)[:\s#]*(\d+)/i`

5. **For each plan with a linked issue:**
   - If issue number is in closed list → archive it:
     ```bash
     mv plans/FILENAME plans/archived/FILENAME
     ```
   - If issue number NOT in closed list → skip (still open)
   - If issue number not found in .issues.json → warn (unknown issue)

6. **Handle orphan plans (no issue link found):**

   **Attempt git log recovery:**
   ```bash
   git log --oneline --all --grep="PLAN_FILENAME_WITHOUT_EXT" | head -5
   ```
   Look for `Closes #XXX` or `(#XXX)` in commit messages.

   **If still no link, prompt user:**
   ```
   Orphan plan: budget-estimator.md
   No linked issue found.

   [L] Link to issue (enter issue #)
   [A] Archive anyway (completed but no issue)
   [S] Skip for now
   [I] Ignore forever (add to .archiveignore)
   ```

   - **L**: Add `Issue: #XXX` to frontmatter, re-evaluate
   - **A**: Move to `plans/archived/`
   - **S**: Do nothing this run
   - **I**: Append filename to `plans/.archiveignore`, skip in future

7. **Report:**
   ```
   Archive complete:
   - Archived: 3 plans (linked to closed issues)
   - Skipped: 2 plans (issues still open)
   - Orphans: 1 plan (prompted)
   ```

**Notes:**
- Plans in `plans/archived/` are never re-scanned
- `.archiveignore` is a simple newline-delimited list of filenames to skip
- This command can be run standalone or is called automatically by `/sync-issues`
