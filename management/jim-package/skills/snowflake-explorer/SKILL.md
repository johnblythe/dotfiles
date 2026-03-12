---
name: snowflake-explorer
description: Ask questions of Snowflake data in plain English. Generates SQL, runs it, returns results alongside the query so you learn the patterns. Read-only enforced.
---

# Snowflake Explorer

Turn plain-English questions into Snowflake SQL, execute safely, and return results with the query visible.

## Usage

```
/snowflake-explorer how many requests were created last week?
/snowflake-explorer what's the average time in fulfillment by site?
/snowflake-explorer top 10 exception reasons this month
/snowflake-explorer                    # interactive — ask what you want to know
```

## Workflow

### Step 1: Load Schema Context

Read the schema reference to understand available tables and columns:

```
File: ~/code/management/projects/telemetry-deck/SCHEMA.md
```

If the question involves tables not in SCHEMA.md, check dbt staging models:

```
Directory: ~/code/data-warehouse/data_model/models/staging/healthsource/
```

Look at the `.yaml` files first (connex.yaml, healthsource.yaml) for table/column definitions, then individual `.sql` models for transformation logic.

### Step 2: Understand the Question

Parse the user's plain-English question. Identify:
- **What** they want to measure (counts, averages, distributions, trends)
- **Which tables** are involved
- **Filters** (time ranges, site, status, source type, etc.)
- **Groupings** (by site, by status, by day/week/month, etc.)

If the question is ambiguous, ask ONE clarifying question before generating SQL. Don't over-ask — make reasonable assumptions and note them.

### Step 3: Generate SQL

Write the SQL query following these rules:

**Safety — NON-NEGOTIABLE:**
- SELECT statements ONLY. Never generate INSERT, UPDATE, DELETE, DROP, CREATE, ALTER, TRUNCATE, MERGE, or any DDL/DML.
- If a question would require a write operation, explain what you'd need to do and stop.
- Always include a LIMIT clause (default 100, max 1000) unless doing aggregation.
- Use `CURRENT_DATE`, `DATEADD`, `DATEDIFF` for time calculations.

**Column gotchas:**
- Audit trail: `EVENT_DT` (not audit_timestamp), `AUDIT_MESSAGE` (not audit_description)
- Exception: `EXCEPTION_REASON_ID` is a FK (join to `erequest_exception_reason`), not text
- Site: `DDS_SITE_ID` (not site_id)
- All column names are UPPERCASE in Snowflake

**Style:**
- Use CTEs for readability when queries have multiple steps
- Add brief inline comments explaining non-obvious joins or filters
- Format for readability (indentation, line breaks)
- Alias tables with short meaningful names (e.g., `er` for erequest_dynamic, `es` for erequest_status_dynamic)

**Common patterns:**

```sql
-- Time in a status (dwell time)
SELECT er.EREQUEST_ID,
       es1.STATE_TIMESTAMP AS entered_status,
       COALESCE(es2.STATE_TIMESTAMP, CURRENT_TIMESTAMP) AS left_status,
       DATEDIFF('minute', es1.STATE_TIMESTAMP, COALESCE(es2.STATE_TIMESTAMP, CURRENT_TIMESTAMP)) AS minutes_in_status
FROM erequest_status_dynamic es1
LEFT JOIN erequest_status_dynamic es2
  ON es1.EREQUEST_ID = es2.EREQUEST_ID
  AND es2.STATE_TIMESTAMP > es1.STATE_TIMESTAMP
  -- next status transition for this request
JOIN erequest_dynamic er ON er.EREQUEST_ID = es1.EREQUEST_ID
WHERE es1.STATUS_ID = <target_status_id>

-- Request volume by day
SELECT DATE_TRUNC('day', CREATED_DT) AS day,
       COUNT(*) AS request_count
FROM erequest_dynamic
WHERE CREATED_DT >= DATEADD('day', -30, CURRENT_DATE)
GROUP BY 1
ORDER BY 1

-- Exception breakdown
SELECT eer.EXCEPTION_REASON_DESC, COUNT(*) AS cnt
FROM erequest_exception ee
JOIN erequest_exception_reason eer
  ON ee.EXCEPTION_REASON_ID = eer.EREQUEST_EXCEPTION_REASON_ID
WHERE ee.IS_REMOVED = 0
  AND ee.CREATED_DT >= DATEADD('day', -30, CURRENT_DATE)
GROUP BY 1
ORDER BY 2 DESC
```

### Step 4: Show the SQL First

Before executing, display the query in a fenced code block:

```
Here's what I'll run:
```sql
<the query>
```

This does: <one-sentence plain-English description>
```

Wait for confirmation ONLY if the query is complex (3+ joins, subqueries) or if you made assumptions the user should verify. For straightforward queries, proceed directly.

### Step 5: Execute

Write the SQL to a temp file and execute via snowsql:

```bash
cat > /tmp/sf_query.sql << 'EOSQL'
<the query>
EOSQL
/Applications/SnowSQL.app/Contents/MacOS/snowsql -c datavant -f /tmp/sf_query.sql
```

**Never use inline SQL** — shell parsing breaks on `!=`, quotes, and special chars.

### Step 6: Present Results

Format the output clearly:
1. **Answer** — plain-English answer to their question (the headline)
2. **Data** — results table (clean up snowsql formatting if needed)
3. **SQL** — the query again in a fenced block labeled "The SQL" so they can copy/tune it
4. **Next questions** — suggest 1-2 follow-up questions they might want to explore

### Error Handling

- **Auth popup**: "SnowSQL will open a browser window for SSO. Authenticate and I'll continue."
- **Table not found**: Check SCHEMA.md and dbt models for the correct table name. Suggest alternatives.
- **Timeout**: Suggest adding tighter date filters or LIMIT.
- **No results**: Explain why (filters too tight, data doesn't exist for that range) and suggest loosening.

## Example Session

**User**: "How many requests came in through central intake vs upload last month?"

**Response**:

Here's what I'll run:

```sql
SELECT SOURCE_TYPE,
       COUNT(*) AS request_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM erequest_dynamic
WHERE CREATED_DT >= DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE))
  AND CREATED_DT < DATE_TRUNC('month', CURRENT_DATE)
  AND SOURCE_TYPE IN ('CENTRAL INTAKE', 'UPLOAD')
GROUP BY 1
ORDER BY 2 DESC;
```

*Executing...*

**Answer**: Last month, Central Intake brought in 45,231 requests (62%) vs Upload with 27,890 (38%).

| SOURCE_TYPE | request_count | pct |
|---|---|---|
| CENTRAL INTAKE | 45,231 | 62.0 |
| UPLOAD | 27,890 | 38.0 |

<details>
<summary>The SQL</summary>

```sql
-- (same query repeated for easy copy)
```
</details>

**Follow-up ideas:**
- Break this down by week to see the trend?
- Add site-level detail to see which sites are heaviest?
