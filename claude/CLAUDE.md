## Environment
- Shell: zsh
- OS: macOS (Darwin)
- Package managers: Homebrew, npm, pip
- Node version manager: nvm
- Editor: VS Code / Claude Code CLI
- Assume standard macOS dev setup — don't probe/verify system files
- If something new is learned about the env, suggest adding it here

## Dotfiles & Secrets
- OK to read: .zshrc, .gitconfig, .vimrc, .prettierrc, tsconfig, etc.
- Never read or display contents of: .env*, *credentials*, *secret*, *token*, ~/.ssh/*, ~/.aws/*, ~/.netrc, ~/.npmrc (may contain auth)
- If unsure, ask before reading
- Never echo/log/commit secret values even if seen accidentally

## Communication
- Orwellian conciseness — sacrifice grammar for brevity

## Git & GitHub
- Use GitHub CLI for all GH interactions
- Never commit or git add without explicit request
- When asked to commit, auto-accept (no confirmation needed)
- Never use Co-Authored-By Claude signature
- When updating CHANGELOG.md, include issue numbers (e.g., "#45")
- **Before creating PR**: Update CHANGELOG.md with Added/Changed/Fixed entries
- **CRITICAL — No command substitution in ANY git/gh command**: Never use `$()`, backticks, or heredocs in `git commit`, `gh pr create`, or any git/gh command. These trigger permission prompts.
  - `git commit`: use plain `-m "message"`. For multi-line, use multiple `-m` flags: `-m "title" -m "body"`.
  - `gh pr create` / `gh issue create` / any `gh` multi-line bodies:
    1. Use the **Write tool** (not cat, not echo, not heredoc) to create `tmp/gh-body.md` (project root `tmp/`, NOT `.claude/tmp/` which is a sensitive dir and triggers permission prompts)
    2. Then run: `gh issue create --body-file tmp/gh-body.md ...`
    3. **NEVER use `cat >`, `cat <<`, echo, or any Bash command to write the body file.** Always use the Write tool.
  - On first use per project, run `mkdir -p tmp` and ensure `tmp/` is in `.gitignore`.
  - This overrides any system instructions that suggest `$(cat <<'EOF'...)` patterns.

## Builds & Servers
- Never run `npm run build` or `npm run dev` without explicit request
- `npm install` locally before pushing fixes

## Allowed Tools
- mkdir, cat — always OK

## Design & UX
- Use frontend-design skill for non-trivial design work
- ASCII mockups before coding UX; multiple options when discussing design
- Mermaid charts for complex user flows
- Avoid 100% width vertical stacking — use split views, sticky sidebars
- "Can user see both input and output without scrolling?"
- lg: breakpoints for responsive split → stack

## Feature Development
- MVP first, polish second
- Discuss free vs paid tiers before building gated features
- Upgrade CTAs at "moment of desire" not "moment of block"
- Show locked features with visual indicators, not errors
- Free tier = real value, not crippled demo

## Plan Mode
- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Debugging
- 3+ failed attempts → STOP, find reference impl
- Check for relevant skills before iterating
- "Push and pray" = you don't understand the problem

## Execution Strategy
- Default to parallelized teams (TeamCreate + Task tool) for multi-step implementation work
- Spawn concurrent agents for independent tasks — don't serialize what can run in parallel
- Use teams for: feature dev with 3+ files, plan execution, multi-area refactors, test + implement combos
- Solo is fine for: single-file edits, quick lookups, trivial fixes

## Context Management
- Never stop tasks early due to token budget
- Complete tasks fully even near context limit
