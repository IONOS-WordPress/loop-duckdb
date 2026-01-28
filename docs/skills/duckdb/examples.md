# DuckDB Query Examples

This document provides practical examples of DuckDB queries used in the loop-duckdb project. All examples are derived from actual queries in [scripts/generate-report-parts](../../scripts/generate-report-parts/).

> **Prerequisites**: Before running any queries, ensure the database exists by running `pnpm generate-report`. See [SKILL.md](SKILL.md) for details.

## Table of Contents

1. [Basic Table Creation](#basic-table-creation)
2. [JSON Processing](#json-processing)
3. [Aggregation Queries](#aggregation-queries)
4. [Window Functions](#window-functions)
5. [Event Analysis](#event-analysis)
6. [Working with Recent Data](#working-with-recent-data)

---

## Basic Table Creation

### Create Table from Parquet File

```sql
CREATE OR REPLACE TABLE loop_items AS
  SELECT *
  FROM './generate-report/generate-report.parquet';
```

Source: [020-create-duckdb-database.sh:9-13](../../scripts/generate-report-parts/020-create-duckdb-database.sh#L9-L13)

---

## JSON Processing

### Unnest JSON Array with Schema

Transform a JSON array of plugins into structured rows:

```sql
CREATE OR REPLACE TABLE plugins AS
  SELECT
    timestamp,
    instance,
    filename,
    unnest(json_transform(
      wordpress->'active_plugins',
      '[{
        "plugin_slug": "VARCHAR",
        "version": "VARCHAR",
        "auto_update": "BOOLEAN"
      }]'
    )) AS plugin
  FROM loop_items;
```

Source: [020-create-duckdb-database.sh:16-30](../../scripts/generate-report-parts/020-create-duckdb-database.sh#L16-L30)

### Transform JSON Object

Convert a JSON object to a structured type:

```sql
CREATE OR REPLACE TABLE themes AS
  SELECT
    timestamp,
    instance,
    filename,
    json_transform(
      wordpress->'active_theme',
      '{
        "id": "VARCHAR",
        "version": "VARCHAR",
        "parent_theme_slug": "VARCHAR",
        "auto_update": "BOOLEAN"
      }'
    ) AS theme
  FROM loop_items;
```

Source: [020-create-duckdb-database.sh:33-48](../../scripts/generate-report-parts/020-create-duckdb-database.sh#L33-L48)

### Extract Nested JSON Values

```sql
SELECT
  json_extract_string(event.payload, '$.type') AS login_type,
  COUNT(*) AS total_logins
FROM events
WHERE event.name = 'login'
GROUP BY login_type;
```

Source: [080-logins.sh:16-28](../../scripts/generate-report-parts/080-logins.sh#L16-L28)

### Dynamic JSON Key Access

```sql
WITH UnpivotedNBA AS (
  SELECT
    instance,
    nba_data,
    unnest(json_keys(nba_data)) AS nba_key
  FROM NBAStatus
  WHERE nba_data IS NOT NULL
)
SELECT
  nba_key,
  json_extract_string(nba_data, '$.' || nba_key) AS status
FROM UnpivotedNBA;
```

Source: [110-nbas-dismissed.sh:19-38](../../scripts/generate-report-parts/110-nbas-dismissed.sh#L19-L38)

---

## Aggregation Queries

### Count with Percentage Calculation

Calculate version distribution with percentages:

```sql
WITH
  php_versions AS (
    SELECT
      CAST(hosting->'php_version' AS text) AS php_version
    FROM loop_items
    JOIN recent_loops ON loop_items.filename = recent_loops.filename
  ),
  php_version_counts AS (
    SELECT
      php_version,
      COUNT(*) AS occurrence_count
    FROM php_versions
    GROUP BY php_version
  ),
  total_count AS (
    SELECT
      COUNT(DISTINCT instance) AS total_instances
    FROM recent_loops
  )
SELECT
  pvc.php_version,
  pvc.occurrence_count,
  ROUND(pvc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM php_version_counts AS pvc,
     total_count AS tc
ORDER BY pvc.occurrence_count DESC;
```

Source: [050-php_versions.sh:7-43](../../scripts/generate-report-parts/050-php_versions.sh#L7-L43)

### Conditional Aggregation with CASE

```sql
WITH _plugins AS (
  SELECT
    CASE
      WHEN plugin_slug LIKE '01-ext%' THEN 'Extendify License'
      ELSE plugin_slug
    END AS slug,
    instance
  FROM plugins
  JOIN recent_loops ON plugins.filename = recent_loops.filename
  WHERE plugin_slug NOT LIKE 'ionos-%'
)
SELECT
  slug,
  COUNT(*) AS occurrence_count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT instance) FROM recent_loops), 2) AS percentage
FROM _plugins
GROUP BY slug
ORDER BY occurrence_count DESC;
```

Source: [060-most-active-plugins.sh:8-53](../../scripts/generate-report-parts/060-most-active-plugins.sh#L8-L53)

---

## Window Functions

### Get Most Recent Record Per Instance

Use `ROW_NUMBER()` to filter to the latest record per instance:

```sql
CREATE OR REPLACE VIEW recent_loops AS
  SELECT
    filename,
    instance,
    timestamp
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY instance
        ORDER BY "timestamp" DESC
      ) AS rn
    FROM loop_items
  )
  WHERE rn = 1;
```

Source: [020-create-duckdb-database.sh:68-86](../../scripts/generate-report-parts/020-create-duckdb-database.sh#L68-L86)

---

## Event Analysis

### Count Distinct Instances by Event Type

```sql
SELECT
  -- SSO Login Count
  COUNT(DISTINCT CASE
    WHEN event.name = 'login'
      AND json_extract_string(event.payload, '$.type') = 'sso'
    THEN instance
    ELSE NULL
  END) AS sso,

  -- Manual Login Count
  COUNT(DISTINCT CASE
    WHEN event.name = 'login'
      AND json_extract_string(event.payload, '$.type') = 'default'
    THEN instance
    ELSE NULL
  END) AS manual,

  -- All Logins
  COUNT(DISTINCT CASE
    WHEN event.name = 'login'
    THEN instance
    ELSE NULL
  END) AS both
FROM events
WHERE event.name = 'login';
```

Source: [080-logins.sh:48-73](../../scripts/generate-report-parts/080-logins.sh#L48-L73)

### Boolean Aggregation with bool_or

```sql
WITH CustomerLoginTypes AS (
  SELECT
    instance,
    json_extract_string(event.payload, '$.type') AS login_type
  FROM events
  WHERE event.name = 'login'
  GROUP BY instance, login_type
),
CustomerUsageSummary AS (
  SELECT
    instance,
    bool_or(login_type = 'sso') AS used_sso,
    bool_or(login_type = 'default') AS used_manual
  FROM CustomerLoginTypes
  GROUP BY instance
)
SELECT
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = FALSE THEN 1 END) AS sso_only,
  COUNT(CASE WHEN used_sso = FALSE AND used_manual = TRUE THEN 1 END) AS manual_only,
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = TRUE THEN 1 END) AS both
FROM CustomerUsageSummary;
```

Source: [080-logins.sh:88-124](../../scripts/generate-report-parts/080-logins.sh#L88-L124)

### Time-Based Event Filtering

```sql
SELECT
  COUNT(DISTINCT instance) AS active_instances
FROM events
WHERE
  timestamp >= current_timestamp - INTERVAL 7 DAY
  AND event.name = 'login';
```

Source: [080-logins.sh:47-72](../../scripts/generate-report-parts/080-logins.sh#L47-L72)

---

## Working with Recent Data

### Join with Recent Loops View

Most queries join with the `recent_loops` view to ensure analysis of current state only:

```sql
SELECT
  CAST(hosting->'core_version' AS text) AS wordpress_version,
  COUNT(*) AS occurrence_count
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
GROUP BY wordpress_version
ORDER BY occurrence_count DESC;
```

Source: [040-wordpress_versions.sh:8-43](../../scripts/generate-report-parts/040-wordpress_versions.sh#L8-L43)

---

## Type Casting

### Cast JSON to Text

```sql
SELECT
  CAST(hosting->'php_version' AS text) AS php_version,
  CAST(hosting->'core_version' AS text) AS wordpress_version
FROM loop_items;
```

### Cast to Numeric with Precision

```sql
SELECT
  (COUNT(*) * 100.0 / total)::NUMERIC(5, 2) AS percentage
FROM my_table;
```

Source: [110-nbas-dismissed.sh:43](../../scripts/generate-report-parts/110-nbas-dismissed.sh#L43)

---

## Tips and Best Practices

1. **Use CTEs for Readability**: Break complex queries into logical steps using `WITH` clauses

2. **Join with recent_loops**: Always join with `recent_loops` when analyzing current state to avoid duplicate instances

3. **JSON Schema Definitions**: When using `json_transform()`, always specify the target schema for type safety

4. **Percentage Calculations**: Use `ROUND()` and multiply by 100.0 (not 100) to ensure float division

5. **Window Functions**: Use `ROW_NUMBER()` with `PARTITION BY` to deduplicate data based on business logic

6. **Type Casting**: Explicitly cast JSON values to appropriate types (`text`, `VARCHAR`, `NUMERIC`, etc.)

7. **NULL Handling**: Use `IS NOT NULL` checks when working with optional JSON fields

8. **Conditional Aggregation**: Use `COUNT(CASE WHEN ... END)` for multiple aggregations in a single pass

---

## Query Execution Methods

### Using the MCP Server

The recommended way to query the database is through the MCP server, which AI assistants can use directly:

```javascript
// The MCP server provides a query tool
{
  "tool": "mcp__duckdb__query",
  "parameters": {
    "query": "SELECT * FROM loop_items LIMIT 10"
  }
}
```

### Using the Interactive UI

Start the browser-based DuckDB UI:
```bash
pnpm start-report-ui
```

### Creating Report Parts

When creating custom report parts in `scripts/generate-report-parts/`, use the `ionos.loop-duckdb.exec_duckdb` function:

```bash
# Example from a report part script
readonly SQL="
  SELECT * FROM loop_items LIMIT 3;
"

# Query with markdown output
ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'

# Query with JSON output
ionos.loop-duckdb.exec_duckdb "$SQL" '-json'
```

**Output format flags:**
- `-markdown` - Great for reports and documentation
- `-json` - Useful for programmatic processing
- (default) - Standard table output
