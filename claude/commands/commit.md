# Create Git Commit with Changelog

Review all changes and create a git commit:

1. Run `git status` and `git diff` to see all changes
2. Review the changes carefully
3. Analyze the nature of changes (feature, fix, refactor, docs, etc.)

## Update CHANGELOG.md

4. Check if CHANGELOG.md exists in the project root
   - If it doesn't exist, create it with this structure:
   ```markdown
   # Changelog

   All notable changes to this project will be documented in this file.

   ## [Unreleased]
   ```

5. Add an entry under `## [Unreleased]` with:
   - Category: Added, Changed, Fixed, Removed, Security, or Deprecated
   - Brief but descriptive summary of what changed and why
   - More detail than the commit message is okay here when helpful
   - Format:
   ```markdown
   ### Added/Changed/Fixed/etc
   - Description of change
   ```

## Create Commit

6. Stage all relevant files INCLUDING the updated CHANGELOG.md
7. Write a commit message that:
   - Is concise but descriptive (1-2 sentences max)
   - Focuses on the "why" not just the "what"
   - Uses imperative mood ("Add feature" not "Added feature")
   - Does NOT include any Co-authored-by lines
   - Does NOT include Claude signatures or attribution
8. Create the commit using HEREDOC format:
   ```bash
   git commit -m "$(cat <<'EOF'
   Commit message here
   EOF
   )"
   ```
9. Verify the commit was created successfully with `git status`

## Important Rules

- NEVER add Co-authored-by, Signed-off-by, or any attribution to Claude
- Keep commit messages short and direct - no fluff
- If there is a GitHub Issue number, include it in the commit message
- Changelog entries can be slightly more detailed when context helps
- Do NOT push unless explicitly requested
- If pre-commit hooks modify files, amend the commit (after checking authorship)
