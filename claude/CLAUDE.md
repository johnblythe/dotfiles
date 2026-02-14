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

## Plans
- End each plan with unresolved questions (extremely concise)

## Debugging
- 3+ failed attempts → STOP, find reference impl
- Check for relevant skills before iterating
- "Push and pray" = you don't understand the problem

## Context Management
- Never stop tasks early due to token budget
- Complete tasks fully even near context limit
