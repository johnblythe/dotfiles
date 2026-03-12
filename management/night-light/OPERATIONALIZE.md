# Night Light — Operationalization Plan

## Current State

What exists:
- `night-light.sh` — main runner (dry-run/live, lookback window, replay mode)
- `PROMPT.md` — 6-phase agent prompt (detect, score, investigate, gap analysis, ticket, PR)
- `services.yaml` — 40+ service definitions, hygiene patterns, incident patterns
- `scripts/cron-night-light.sh` — wrapper with macOS notification
- `dd.py` — Datadog CLI tool (anomalies, logs, investigate, monitors)
- 3 dry runs + 1 real incident analysis (Jan 14, found 13 anomalies across 5 services)

What's missing:
- Never run on a real schedule (cron was never activated)
- Reports write to `~/code/healthsource/night-light-runs/` (sandbox workaround) — messy
- `cron-night-light.sh` hardcodes `--hours 4` and always dry-run
- No Slack/email notification — only macOS `osascript`
- No way to run headless (requires local machine, Zscaler certs, DD API keys)
- `claude --print` doesn't support `--dangerously-skip-permissions` cleanly in cron

---

## Cleanup First

### 1. Fix report output path
Reports should land in `night-light/runs/` (management repo), not scattered in healthsource.

```diff
# night-light.sh
- LOG_DIR="$HEALTHSOURCE_DIR/night-light-runs"
+ LOG_DIR="$SCRIPT_DIR/runs"
```

### 2. Make cron wrapper configurable
```diff
# scripts/cron-night-light.sh
- ./night-light.sh --hours 4
+ MODE="${1:---hours 8}"  # default: 8h lookback for overnight
+ ./night-light.sh $MODE
```

### 3. Add `--live` path to cron
Currently cron always runs dry. Add a flag:
```bash
# scripts/cron-night-light.sh
LIVE_FLAG=""
if [ "${NIGHT_LIGHT_LIVE:-false}" = "true" ]; then
  LIVE_FLAG="--live"
fi
./night-light.sh --hours 8 $LIVE_FLAG
```

### 4. Notification upgrade — Slack webhook
Replace macOS osascript with Slack incoming webhook (works headless):

```bash
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
if [ -n "$SLACK_WEBHOOK" ]; then
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"Night Light Report - $TIMESTAMP\n$SUMMARY\nReport: $LATEST_REPORT\"}"
fi
```

### 5. Clean up old runs
Move/delete the 3 dry runs from Jan 6 — they're test artifacts, not real data.

---

## Deployment Options

### Option A: Local Cron (Simplest, This Week)

**Pros**: Works today, no infra needed, uses existing DD API keys + Zscaler certs
**Cons**: Requires laptop open/awake, dies when you leave

#### Setup
```bash
# 1. Ensure Claude CLI is in PATH for cron
which claude  # /usr/local/bin/claude or similar

# 2. Set up env vars cron needs
cat > ~/.night-light-env << 'EOF'
export SSL_CERT_FILE="$HOME/Documents/combined-ca-bundle.pem"
export REQUESTS_CA_BUNDLE="$HOME/Documents/combined-ca-bundle.pem"
export NODE_EXTRA_CA_CERTS="$HOME/Documents/combined-ca-bundle.pem"
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
export NIGHT_LIGHT_LIVE=false
EOF

# 3. Add cron entry
crontab -e
# Run at 6am Mon-Fri, 8h lookback covers overnight
0 6 * * 1-5 source ~/.night-light-env && ~/code/management/scripts/cron-night-light.sh >> ~/night-light-cron.log 2>&1
```

#### Validation steps
1. Run manually: `./night-light.sh --hours 2` (dry run, 2h lookback)
2. Verify report lands in `night-light/runs/`
3. Run `scripts/cron-night-light.sh` to test wrapper
4. Check `dd.py` still works: `cd ~/.claude/skills/investigating-datadog/scripts && uv run dd.py monitors --status alert`

**Timeline**: 1-2 hours to clean up + validate. Can run starting tonight.

---

### Option B: GitHub Actions (Portable, Survives You)

**Pros**: Runs after you leave, no laptop dependency, team can maintain
**Cons**: Needs secrets setup, Claude API key, DD API keys in GitHub

#### Architecture
```
GitHub Actions (scheduled) → Claude API → Datadog API → Report
                                       → Jira API → Tickets
                                       → Slack webhook → Notification
```

#### Implementation
```yaml
# .github/workflows/night-light.yml
name: Night Light
on:
  schedule:
    - cron: '0 11 * * 1-5'  # 6am ET (UTC-5)
  workflow_dispatch:  # manual trigger

jobs:
  night-light:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Claude CLI
        run: |
          npm install -g @anthropic-ai/claude-code
          # Or use Claude API directly via curl/python

      - name: Run Night Light
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          DD_API_KEY: ${{ secrets.DD_API_KEY }}
          DD_APP_KEY: ${{ secrets.DD_APP_KEY }}
          JIRA_USER: ${{ secrets.JIRA_USER }}
          JIRA_TOKEN: ${{ secrets.JIRA_TOKEN }}
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
        run: |
          # Adapted night-light that uses Claude API instead of local CLI
          python scripts/night-light-ci.py --hours 8

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: night-light-${{ github.run_id }}
          path: night-light/runs/*.md
```

#### Key differences from local
- Can't use `claude --print` (no local CLI in CI) — need to either:
  - Use Claude API directly (python script wrapping the prompt)
  - Use `claude-code` npm package in headless mode
- `dd.py` needs DD API keys as env vars (already supports this)
- No Zscaler cert needed (not going through corporate proxy)
- Reports committed back to repo or uploaded as artifacts

**Timeline**: Half day to build `night-light-ci.py` wrapper + secrets setup. Could prototype by end of week.

---

### Option C: Kubernetes CronJob (Most Robust)

**Pros**: Runs in your infra, close to services, team already manages K8s
**Cons**: Most setup effort, needs container image, K8s access

#### Architecture
```yaml
# k8s/night-light-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: night-light
  namespace: tooling
spec:
  schedule: "0 11 * * 1-5"  # 6am ET
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: night-light
              image: ghcr.io/your-org/night-light:latest
              envFrom:
                - secretRef:
                    name: night-light-secrets
          restartPolicy: OnFailure
```

**Timeline**: 1-2 days including container build + secrets + deploy. Overkill for a 2.5-week runway.

---

## Recommended Path

**This week**: Option A (local cron). Get it running tonight. Collect 3-5 real overnight reports as proof of value.

**Before you leave**: Option B (GitHub Actions). Takes a half day to build. This is what survives your departure. Push the workflow to the management repo (or a dedicated `night-light` repo on the team org). Hand off the secrets to the new EM.

**Skip Option C** unless someone on the team actively wants to own it in K8s.

---

## Validation Checklist

Before declaring "operational":
- [ ] `dd.py anomalies` works for all 6 critical services
- [ ] `dd.py logs` returns results
- [ ] `dd.py monitors` returns current state
- [ ] Dry run produces a complete tiered report
- [ ] Live run creates a real Jira ticket (test with a throwaway)
- [ ] Report saves to `night-light/runs/` with correct naming
- [ ] Slack notification fires (if webhook configured)
- [ ] Cron runs unattended at least once
- [ ] At least 3 overnight reports collected with real findings

## Handoff Package

What the new EM needs:
1. This doc
2. `OVERVIEW.md` (how it works)
3. `PROMPT.md` (the agent instructions)
4. `services.yaml` (service catalog — update as services change)
5. DD API keys location
6. GitHub Actions workflow (if Option B deployed)
7. 3-5 sample reports showing real findings
