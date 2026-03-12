# PR Hygiene Proposal: From 120+ Open PRs to Sustainable Flow

**Problem**: 20+ engineers, 40+ services, 1 monorepo, 120+ open PRs, no clear ownership or cadence. Rebasing is a full-time job. Dependabot noise drowns real work. Review requests are ad hoc. It's a tragedy of the commons.

**Goal**: Get PR count under 30, keep it there, make reviews predictable.

---

## 1. Triage the Backlog (Week 1 — one-time cleanup)

Before process changes, burn down the pile.

### Action Items
- [ ] **Close all Dependabot PRs older than 14 days** — they're already stale. Dependabot will recreate what matters.
- [ ] **Close any human PR with no activity in 30+ days** — comment "Closing for hygiene. Reopen if still needed." Author can reopen.
- [ ] **Label remaining PRs by team/pod** — `roip-pod-1`, `roip-pod-2`, `intake-logging`, `fulfillment`, `platform`. This is the foundation for everything else.
- [ ] **Assign an owner to every open PR** — if it has no assignee, ping the author. If author is gone, close it.

**Expected result**: ~120 → ~40-50 PRs.

---

## 2. Dependabot: Automate or Kill the Noise

Dependabot is generating PRs nobody reviews. Two options:

### Option A: Auto-merge patch/minor (Recommended)
Add a GitHub Actions workflow that auto-approves and merges Dependabot PRs for patch and minor version bumps if CI passes.

```yaml
# .github/workflows/dependabot-auto-merge.yml
name: Auto-merge Dependabot
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - name: Fetch metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: "${{ secrets.GITHUB_TOKEN }}"
      - name: Auto-merge patch and minor
        if: steps.metadata.outputs.update-type != 'version-update:semver-major'
        run: gh pr merge "$PR_URL" --auto --squash
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Option B: Switch to Renovate
[Renovate](https://docs.renovatebot.com/) groups updates by dependency across directories — e.g., one PR for all `jackson-*` bumps across 40 services instead of 40 PRs. Much better for monorepos. Also supports auto-merge with more granular rules.

**Recommendation**: Start with Option A (30 min setup). Evaluate Renovate in Q2 if Dependabot volume is still painful.

---

## 3. CODEOWNERS: Route Reviews to the Right People

Stop relying on round-robin or "post in Slack and hope." Use GitHub's CODEOWNERS file to auto-assign reviewers by directory.

```gitignore
# .github/CODEOWNERS

# Default — catches anything not matched below
* @healthsource-org/platform-leads

# Per-service ownership (examples — adapt to your actual structure)
/services/intakeservices/    @healthsource-org/intake-logging
/services/fulfillment/       @healthsource-org/fulfillment-qc
/services/platformservices/  @healthsource-org/platform
/services/searchservices/    @healthsource-org/platform
/services/workflow/          @healthsource-org/fulfillment-qc

# Shared infra — require platform review
/infrastructure/             @healthsource-org/platform-leads
/buildSrc/                   @healthsource-org/platform-leads
/.github/                    @healthsource-org/platform-leads
/gradle/                     @healthsource-org/platform-leads
```

### Requirements
- Create GitHub Teams matching your pods (if they don't exist)
- Enable "Require review from Code Owners" in branch protection rules
- Set review count to 1 for service-specific dirs, 2 for shared infra

### Benefits
- PR opened touching `intakeservices/` → intake team auto-assigned, not the whole org
- No more "who should review this?" in Slack
- Cross-cutting PRs (touching multiple services) get multiple team reviews automatically

---

## 4. Slack Integration: Make PRs Visible

### Recommended: GitHub + Slack (Built-in, Free)
GitHub's official Slack integration is free and handles the basics:
```
/github subscribe owner/repo pulls
/github subscribe owner/repo comments reviews
```

Set up per-team channels:
- `#pr-intake-logging` — subscribes to PRs touching intake paths
- `#pr-fulfillment` — subscribes to PRs touching fulfillment paths
- `#pr-platform` — subscribes to PRs touching platform paths

### Level Up: Axolo ($8-16/user/mo)
[Axolo](https://axolo.co/) creates a temporary Slack channel per PR. All comments, CI status, and review requests flow there. Channel dies when PR merges. This is likely what you used before.

**Pros**: Dramatically reduces context switching. Review from Slack. Daily PR reminders.
**Cons**: Not free ($8-16/user/mo). Can be noisy at scale.

### Free Alternative: ReviewNudgeBot
[ReviewNudgeBot](https://slack.com/marketplace/A071DEUQXFB-reviewnudgebot-for-github-bitbucket) — free tier lets you manually share PR URLs in Slack channels and it manages reminders. Not as slick as Axolo but $0.

### DIY: GitHub Actions → Slack Webhook
If budget is $0, a simple GitHub Action can post to Slack when a PR is opened, approved, or stale:

```yaml
# .github/workflows/pr-slack-notify.yml
name: PR Notifications
on:
  pull_request:
    types: [opened, ready_for_review]

jobs:
  notify:
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      - name: Post to Slack
        uses: slackapi/slack-github-action@v2
        with:
          webhook: ${{ secrets.SLACK_PR_WEBHOOK }}
          webhook-type: incoming-webhook
          payload: |
            {
              "text": "🔍 *New PR ready for review*\n<${{ github.event.pull_request.html_url }}|${{ github.event.pull_request.title }}>\nby ${{ github.event.pull_request.user.login }} · ${{ github.event.pull_request.changed_files }} files changed"
            }
```

---

## 5. PR Lifecycle Rules (The Process Part)

Post these in your engineering wiki and `CONTRIBUTING.md`. Enforce socially first, automate later.

### Size Limits
| Metric | Target | Hard Limit |
|--------|--------|------------|
| Files changed | < 10 | 25 |
| Lines changed | < 300 | 800 |
| Services touched | 1 | 3 (requires 2nd reviewer) |

PRs over hard limits get labeled `needs-split` and blocked until broken up. Exception: generated files, migrations, version bumps.

### SLAs
| Action | SLA |
|--------|-----|
| First review | 4 business hours |
| Address review comments | 1 business day |
| Final approval → merge | Same day |
| Stale PR (no activity) | Auto-labeled at 5 days, auto-closed at 14 days |

### Draft PR Convention
- **Draft** = WIP, not ready, don't review yet
- **Ready for Review** = CI passing, tested locally, description complete
- Moving from Draft → Ready triggers Slack notification + reviewer assignment

### PR Description Template
```markdown
## What
<!-- One sentence: what does this change? -->

## Why
<!-- Link to ticket. Why is this needed? -->

## How
<!-- Brief technical approach. Call out anything non-obvious. -->

## Testing
<!-- How did you verify? What should reviewers check? -->

## Services Affected
<!-- List services touched. Helps reviewers scope their review. -->

## Rollback
<!-- How to revert if this breaks prod? -->
```

---

## 6. Merge Queue (Medium-term)

GitHub Merge Queue eliminates the "rebase 13 times" problem. Once a PR is approved, it enters the queue. GitHub rebases, runs CI, and merges automatically. No more manual rebase races.

### When to Enable
- After CODEOWNERS and review SLAs are in place (otherwise queue backs up)
- After CI is reasonably fast (< 20 min ideally)
- After flaky tests are fixed (flaky = queue poison)

### Configuration
```
Branch protection → Require merge queue
- Max queue size: 20
- Min group size: 1
- Max group size: 5 (batch CIs together)
- Timeout: 60 min
- Require branches to be up to date: YES (this is the whole point)
```

### Priority Labels
- `merge-priority:high` — hotfixes skip to front of queue
- `merge-priority:normal` — default FIFO

### References
- [How GitHub uses merge queue](https://github.blog/engineering/engineering-principles/how-github-uses-merge-queue-to-ship-hundreds-of-changes-every-day/)
- [Merge queues for large monorepos (Aviator)](https://www.aviator.co/blog/merge-queues-for-large-monorepos/)

---

## 7. Stale PR Automation

Use [actions/stale](https://github.com/actions/stale) to auto-manage PR lifecycle:

```yaml
# .github/workflows/stale-prs.yml
name: Close stale PRs
on:
  schedule:
    - cron: '0 9 * * 1-5'  # Weekdays 9 AM UTC

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          stale-pr-message: >
            This PR has been inactive for 7 days. It will be closed in 7 more days
            if there's no activity. If this is still needed, push an update or comment.
          close-pr-message: >
            Closed due to inactivity. Reopen if still needed.
          days-before-pr-stale: 7
          days-before-pr-close: 14
          exempt-pr-labels: 'do-not-close,in-progress'
          # Don't touch issues
          days-before-issue-stale: -1
          days-before-issue-close: -1
```

---

## 8. Weekly PR Review Ceremony (5 min)

Add to existing standup or retro:

**Every Monday, one person reviews the PR dashboard:**
1. How many open PRs? Trending up or down?
2. Any PRs > 7 days old? Why?
3. Any PRs with 0 reviewers assigned?
4. Shout out fastest reviewer of the week (gamify it)

Dashboard: `https://github.com/pulls?q=is:open+is:pr+repo:YOUR_REPO+sort:updated-asc`

---

## Implementation Roadmap

| Phase | Timeline | Effort | Impact |
|-------|----------|--------|--------|
| **Backlog triage** | Week 1 | 2-3 hrs | High — immediate PR count reduction |
| **Dependabot auto-merge** | Week 1 | 30 min | High — eliminates noise |
| **Stale PR automation** | Week 1 | 15 min | Medium — prevents future pile-up |
| **CODEOWNERS file** | Week 2 | 2-3 hrs | High — fixes review routing |
| **PR template** | Week 2 | 15 min | Medium — improves review quality |
| **Slack notifications** | Week 2 | 1 hr | Medium — visibility |
| **PR lifecycle rules** | Week 2 | Team discussion | High — shared expectations |
| **Weekly PR ceremony** | Week 3 | 5 min/week | Medium — accountability |
| **Merge queue** | Week 4-6 | Half day + tuning | Very High — eliminates rebase hell |

---

## Success Metrics

| Metric | Current | 30-day Target | 90-day Target |
|--------|---------|---------------|---------------|
| Open PRs | 120+ | < 50 | < 30 |
| Median time to first review | Unknown | < 8 hrs | < 4 hrs |
| Median PR age at merge | Unknown | < 3 days | < 2 days |
| PRs closed as stale/month | 0 | < 10 | < 5 |
| Dependabot PRs needing human review | All | Majors only | Majors only |

---

## Sources & Tools

| Tool | Cost | Purpose |
|------|------|---------|
| [GitHub CODEOWNERS](https://docs.github.com/articles/about-code-owners) | Free | Auto-assign reviewers by path |
| [GitHub Merge Queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue) | Free (with GH Enterprise) | Eliminate rebase races |
| [actions/stale](https://github.com/actions/stale) | Free | Auto-close inactive PRs |
| [Dependabot auto-merge](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/automating-dependabot-with-github-actions) | Free | Auto-merge patch/minor deps |
| [GitHub Slack Integration](https://github.com/integrations/slack) | Free | PR notifications in Slack |
| [Axolo](https://axolo.co/) | $8-16/user/mo | Per-PR Slack channels, reminders |
| [ReviewNudgeBot](https://slack.com/marketplace/A071DEUQXFB-reviewnudgebot-for-github-bitbucket) | Free tier | PR review reminders |
| [Renovate](https://docs.renovatebot.com/) | Free (self-hosted) | Better dependency grouping than Dependabot |
