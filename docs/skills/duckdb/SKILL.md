---
name: duckdb
description: Query and analyze WordPress instance data using DuckDB SQL. Use when you need to query Loop data (plugins, themes, PHP/WordPress versions, user behavior, events), generate reports, create database insights, or understand the schema. Provides ready-to-use query patterns for common analytics tasks.
compatibility: Requires DuckDB MCP server (mcp-server-duckdb via uvx), pnpm, and Docker. Database must be generated with 'pnpm generate-report' before querying.
metadata:
  database-location: generate-report/generate-report.db
  mcp-server: duckdb
  version: "1.0"
allowed-tools: mcp__duckdb__query Read Bash
---

# DuckDB Skill

Use this skill when working with the DuckDB database in the loop-duckdb project for analyzing WordPress instance data.

## When to Use This Skill

Use this skill when you need to:
- Query WordPress instance data (plugins, themes, versions, user behavior)
- Analyze Loop data using SQL
- Generate reports or insights from the database
- Create new report sections
- Understand the database schema and available tables

**Do NOT use this skill for**: Report generation commands (those are documented in the main README)

## Quick Start

### Database Location

The DuckDB database is at: `generate-report/generate-report.db`

**CRITICAL**: Before querying, ensure the database exists:
```bash
pnpm generate-report
```

If the database doesn't exist, run the command above. It will:
1. Download Loop data from S3 (if needed)
2. Create the database with all tables and views
3. Generate reports in `./generate-report/`

## Query the Database

### Using MCP Server (Recommended)

Use the `mcp__duckdb__query` tool to execute SQL queries:

```sql
-- Example: Get the 10 most common WordPress versions
SELECT
  CAST(hosting->'core_version' AS text) AS wordpress_version,
  COUNT(*) AS count
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
GROUP BY wordpress_version
ORDER BY count DESC
LIMIT 10;
```

The MCP server runs in **readonly mode** - you cannot modify the database.

### Using Interactive UI

For exploration and query development:
```bash
pnpm start-report-ui
```

This opens a browser UI where you can browse tables and test queries.

## Database Schema

### Core Tables

**`loop_items`** - Raw WordPress instance data
- All fields from the Loop JSON files
- Use this for accessing nested JSON data
- Always join with `recent_loops` to get current state

**`plugins`** - Active plugins (unnested from loop_items)
```sql
-- Schema
SELECT timestamp, instance, filename, plugin
-- plugin contains: plugin_slug, version, auto_update
```

**`themes`** - Active themes (unnested from loop_items)
```sql
-- Schema
SELECT timestamp, instance, filename, theme
-- theme contains: id, version, parent_theme_slug, auto_update
```

**`events`** - Events (unnested from loop_items)
```sql
-- Schema
SELECT timestamp, instance, filename, event
-- event contains: name, payload (JSON), timestamp
```

### Critical View

**`recent_loops`** - Latest loop per instance
```sql
-- Schema
SELECT filename, instance, timestamp
```

**IMPORTANT**: Always join with this view when querying current state:
```sql
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
```

This ensures you're analyzing the most recent data for each WordPress instance.

## Common Query Patterns

### Get Current State Data

Always join with `recent_loops`:
```sql
SELECT
  CAST(hosting->'php_version' AS text) AS php_version,
  COUNT(*) AS count
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
GROUP BY php_version;
```

### Access JSON Fields

Use `->` for JSON objects, cast to text:
```sql
CAST(hosting->'php_version' AS text)
CAST(wordpress->'active_plugins' AS text)
```

### Query Plugin/Theme Data

Use the unnested tables:
```sql
-- Most common plugins
SELECT
  plugins.plugin.plugin_slug,
  COUNT(DISTINCT plugins.instance) AS instance_count
FROM plugins
JOIN recent_loops ON plugins.filename = recent_loops.filename
WHERE plugins.plugin.plugin_slug NOT LIKE 'ionos-%'
GROUP BY plugins.plugin.plugin_slug
ORDER BY instance_count DESC
LIMIT 20;
```

### Analyze Events

```sql
-- Login types in last 7 days
SELECT
  json_extract_string(event.payload, '$.type') AS login_type,
  COUNT(*) AS count
FROM events
WHERE
  event.name = 'login'
  AND timestamp >= current_timestamp - INTERVAL 7 DAY
GROUP BY login_type;
```

## DuckDB Features Available

### JSON Functions
- `json_transform(json_col, 'schema')` - Convert JSON to structured type
- `json_extract_string(json_col, '$.path')` - Extract string value
- `->` / `->>` - Navigate JSON (-> returns JSON, ->> returns text)
- `json_keys(json_obj)` - Get object keys

### Array Functions
- `unnest(array_col)` - Expand array into rows

### Window Functions
- `ROW_NUMBER() OVER (PARTITION BY col ORDER BY col2)` - Ranking
- Used in `recent_loops` view to get latest per instance

### Aggregations
- `COUNT(DISTINCT col)` - Count unique values
- `bool_or(condition)` - Boolean OR aggregation
- `ROUND(value, decimals)` - Round numbers

### CTEs (WITH Clauses)
Use for readable, multi-stage queries:
```sql
WITH php_versions AS (
  SELECT CAST(hosting->'php_version' AS text) AS version
  FROM loop_items
  JOIN recent_loops ON loop_items.filename = recent_loops.filename
)
SELECT version, COUNT(*)
FROM php_versions
GROUP BY version;
```

## Creating Report Parts

When adding new report sections to `scripts/generate-report-parts/`:

1. **Name your script**: Use numbering like `055-my-insight.sh` (alphabetical order)
2. **Make it executable**: `chmod +x scripts/generate-report-parts/055-my-insight.sh`
3. **Use this template**:

```bash
#!/usr/bin/env bash

readonly SQL="
-- Your DuckDB query here
SELECT * FROM loop_items LIMIT 3;
"

readonly TITLE="My Report Section"

cat <<EOF
# $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
EOF
```

4. **Test it**: `pnpm generate-report '055-my-insight.sh'`

The `ionos.loop-duckdb.exec_duckdb` function is available in report scripts:
- First param: SQL query
- Second param (optional): Output format (`-markdown`, `-json`, or omit for table)

## Tips for Writing Queries

1. **Always join with recent_loops** when querying current state
2. **Cast JSON values** explicitly: `CAST(col AS text)`
3. **Use CTEs** for complex queries (WITH clauses)
4. **Calculate percentages**: `ROUND(count * 100.0 / total, 2)` (use 100.0, not 100)
5. **Conditional counts**: `COUNT(CASE WHEN condition THEN 1 END)`
6. **Exclude IONOS plugins** from reports: `WHERE plugin_slug NOT LIKE 'ionos-%'`
7. **Test in UI first**: Use `pnpm start-report-ui` to develop queries interactively

## Additional Resources

See [examples.md](examples.md) for comprehensive query examples.

See [reference.md](reference.md) for DuckDB SQL reference and documentation links.

See [README.md](../../../README.md) for report generation workflow.

## Troubleshooting

**"Database not found"**
→ Run `pnpm generate-report` to create it

**"Table does not exist"**
→ Check you're using correct table names: `loop_items`, `plugins`, `themes`, `events`, `recent_loops`

**"Results seem wrong"**
→ Ensure you joined with `recent_loops` to get current state only

**"Query too slow"**
→ Regenerate database if data is stale: `pnpm generate-report`
