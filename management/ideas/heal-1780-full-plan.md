# HEAL-1780: Claude AI Read-Only Database Access — Full Plan

> Saved for follow-up ticket after quick & dirty PoC validates the approach.

## Context
Engineers want Claude Code to query HealthSource databases (mapping data, schema exploration) but currently face: (1) per-query permission prompts, (2) no schema awareness = expensive trial-and-error against information_schema. Slack consensus: read-only permission set, per-engineer users, no write/proc access.

## Architecture
- **PostgreSQL 15** — Docker locally (hs on :5434, hs_audit on :5435), Azure Flex in QA01
- **12 schemas** in hs: connex, platform_adm, asm, chase_processor, cms, ddls, dfil, erequest_upload_processor, hsil, hsrules, reports, abinitio_read
- **Local creds**: hstest/testpass (hs), hsaudittest/testpass (audit)
- **QA01 host**: ciox-eus1-hsclarity-qa01-postgres-flex-hs-01.postgres.database.azure.com

## Deliverables

All files in `~/code/healthsource-scripts/`:

### 1. SQL Role Scripts — `db-access/sql/`

**`create-readonly-role.sql`** (run once per env by admin)
- Create `claude_readonly` role: NOLOGIN, NOSUPERUSER, NOCREATEDB, NOCREATEROLE
- GRANT CONNECT ON DATABASE
- GRANT USAGE + SELECT ON ALL TABLES for each of the 12 schemas
- ALTER DEFAULT PRIVILEGES so future migration tables auto-grant
- SET statement_timeout=30s, lock_timeout=5s on role (safety net)
- Idempotent (DO $$ IF NOT EXISTS ... $$)

**`create-readonly-role-audit.sql`** — same for hs_audit (fewer schemas)

### 2. User Creation Script — `db-access/create-db-user.sh`

```
Usage: ./create-db-user.sh <username> [--env local|qa01]
```
- Generate random password via `openssl rand -base64 24`
- CREATE USER `claude_<username>` WITH LOGIN PASSWORD INHERIT
- GRANT claude_readonly TO claude_<username>
- Store creds in macOS Keychain (`security add-generic-password`)
- Print MCP registration commands

**Local** connects to localhost:5434 as hstest. **QA01** prompts for admin creds.

### 3. MCP Wrapper — `db-access/mcp-pg-wrapper.sh`

Keychain-aware launcher that resolves creds at runtime:
```bash
#!/bin/bash
# Usage: mcp-pg-wrapper.sh <local|qa01> <hs|hs_audit>
```
- Pulls user/password from Keychain entries
- Builds connection string with correct host/port/sslmode
- Execs `npx @modelcontextprotocol/server-postgres` with the conn string

This means `~/.claude/settings.json` never contains passwords.

**MCP registration:**
```bash
claude mcp add hs-db -- bash $REPO/db-access/mcp-pg-wrapper.sh local hs
claude mcp add hs-audit-db -- bash $REPO/db-access/mcp-pg-wrapper.sh local hs_audit
```

### 4. Extend setup.sh — `.claude/setup.sh`

Add **Step 3: Database MCP** after existing Step 2:
- Check if `hs-db` MCP is in settings.json
- If not: print self-service instructions (start Docker, run create-db-user.sh, add MCP)
- Add to `check_setup()`: verify Keychain entries + MCP server presence

### 5. Schema Snapshot — `db-access/snapshots/hs-schema.md`

**Generator**: `db-access/schema-snapshot.sh` — connects to DB, dumps compact markdown:
```
## connex (180 tables)
### erequest — erequest_id:bigint PK, created_dt:timestamp, status_id:int FK ...
```
- Committed to git (no sensitive data — just structure)
- Re-run after migrations
- ~50-80KB covering all 12 schemas

### 6. db-query Skill — `.claude/skills/db-query/SKILL.md`

Instructions for Claude to:
1. Load schema snapshot before querying (reduces information_schema round-trips)
2. Use MCP server tools for queries
3. Common query patterns (find request, count by status, etc.)
4. Rules: always LIMIT, prefer specific columns, 30s timeout enforced

### 7. README — `db-access/README.md`

Quick-start for engineers: prerequisites, setup steps, troubleshooting.

## File Map
```
healthsource-scripts/
  db-access/
    README.md
    sql/
      create-readonly-role.sql
      create-readonly-role-audit.sql
    create-db-user.sh
    mcp-pg-wrapper.sh
    schema-snapshot.sh
    snapshots/
      hs-schema.md
  .claude/
    setup.sh                          # MODIFY — add Step 3
    skills/
      db-query/
        SKILL.md
```

## Implementation Order

1. SQL scripts — create-readonly-role.sql + audit variant
2. create-db-user.sh — per-engineer user creation
3. mcp-pg-wrapper.sh — keychain-aware MCP launcher
4. Test locally — run role SQL against Docker, create user, register MCP, verify SELECT works and INSERT fails
5. schema-snapshot.sh + generate initial snapshot
6. db-query skill — SKILL.md
7. Extend setup.sh — Step 3 + check_setup additions
8. README — self-service docs
