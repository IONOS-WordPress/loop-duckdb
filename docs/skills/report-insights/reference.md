# Report Insights Reference

Comprehensive reference for creating and maintaining report insight scripts in the loop-duckdb project.

**IMPORTANT**: Patterns in this reference are examples only. Always consult the [official DuckDB documentation](https://duckdb.org/docs/sql/introduction) as your primary reference for SQL syntax.

## Table of Contents

1. [External Documentation References](#external-documentation-references)
2. [Script Structure Reference](#script-structure-reference)
3. [Naming Conventions](#naming-conventions)
4. [SQL Pattern Library](#sql-pattern-library)
5. [Visualization Patterns](#visualization-patterns)
6. [Available Tables and Views](#available-tables-and-views)
7. [Common CTEs](#common-ctes)
8. [Bash Techniques](#bash-techniques)
9. [Error Handling](#error-handling)

---

## External Documentation References

**Priority**: Always use these official resources as your primary reference.

### DuckDB SQL Documentation

Official DuckDB documentation for SQL syntax and functions:

- **SQL Introduction**: [https://duckdb.org/docs/sql/introduction](https://duckdb.org/docs/sql/introduction)
- **SQL Statements**: [https://duckdb.org/docs/sql/statements/select](https://duckdb.org/docs/sql/statements/select)
- **JSON Functions**: [https://duckdb.org/docs/extensions/json](https://duckdb.org/docs/extensions/json)
- **Aggregate Functions**: [https://duckdb.org/docs/sql/functions/aggregates](https://duckdb.org/docs/sql/functions/aggregates)
- **Window Functions**: [https://duckdb.org/docs/sql/window_functions](https://duckdb.org/docs/sql/window_functions)
- **Common Table Expressions (CTEs)**: [https://duckdb.org/docs/sql/query_syntax/with](https://duckdb.org/docs/sql/query_syntax/with)
- **Data Types**: [https://duckdb.org/docs/sql/data_types/overview](https://duckdb.org/docs/sql/data_types/overview)

### Mermaid Chart Documentation

Official Mermaid documentation for chart syntax:

- **Mermaid Overview**: [https://mermaid.js.org/intro/](https://mermaid.js.org/intro/)
- **Pie Chart Syntax**: [https://mermaid.js.org/syntax/pie.html](https://mermaid.js.org/syntax/pie.html)
- **Chart Configuration**: [https://mermaid.js.org/config/setup/modules/mermaidAPI.html](https://mermaid.js.org/config/setup/modules/mermaidAPI.html)

---

## Script Structure Reference

### Complete Script Anatomy

```bash
#!/usr/bin/env bash              # Shebang (required)

#                                # Comment block describing:
# Description of insight         # - What it analyzes
# Additional context             # - Any special considerations
#                                # - Business questions it answers

readonly SQL="                   # SQL query (readonly for safety)
-- SQL comments explaining logic
WITH cte1 AS (...),             # Use CTEs for readability
     cte2 AS (...)
SELECT ...
FROM ...
JOIN recent_loops ...           # Always join with recent_loops
"

readonly TITLE="Insight Title"  # Title for markdown section

cat <<EOF                        # Heredoc for output

# $TITLE                         # Markdown heading

> **Note: Context if needed**   # Optional note (blockquote)

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')  # Table output

\`\`\`mermaid                    # Optional visualization
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq ...)
\`\`\`
EOF
```

### Script Header Requirements

**Shebang**: Always `#!/usr/bin/env bash` (more portable than `#!/bin/bash`)

**Comments**: Multi-line block explaining purpose
```bash
#
# Generates analysis for [specific feature/metric]
# Answers: [business questions]
# Special considerations: [any]
#
```

**Variable Declarations**: Use `readonly` for constants
```bash
readonly SQL="..."
readonly TITLE="..."
```

---

## Naming Conventions

### File Naming

**Format**: `NNN-descriptive-name.sh`

**Rules**:
- `NNN` = 3-digit number (010-999)
- Use hyphens for word separation
- Lowercase only
- Descriptive but concise

**Number Allocation**:

| Range | Purpose | Examples |
|-------|---------|----------|
| 010-020 | Data preparation | `010-generate-parquet-file.sh`, `020-create-duckdb-database.sh` |
| 030 | Report initialization | `030-generate-report-header.sh` |
| 040-050 | Core metrics | `040-wordpress_versions.sh`, `050-php_versions.sh` |
| 060-080 | Usage analysis | `060-most-active-plugins.sh`, `070-most-active-themes.sh`, `080-logins.sh` |
| 090-100 | Third-party integrations | `090-extendify.sh`, `100-getting-started-finished.sh` |
| 110-140 | Feature usage | `110-nbas-dismissed.sh`, `130-quicklinks-usage.sh`, `140-security-settings.sh` |
| 150-170 | Advanced features | `150-extendify-onboarding-status.sh`, `160-maintenance-status.sh`, `170-mcp-enabled.sh` |
| 180+ | Custom insights | Reserved for future use |

### Inserting New Scripts

To insert between existing scripts, use decimal-like numbering:

- Between `050` and `060`: Use `055`
- Between `055` and `060`: Use `057` or `058`
- If all `05X` are taken: Use `059` or renumber existing scripts

---

## SQL Pattern Library

**IMPORTANT**: These patterns are project-specific examples only. Always consult the [official DuckDB SQL documentation](https://duckdb.org/docs/sql/introduction) for authoritative SQL syntax and functions. For JSON operations, refer to [DuckDB JSON functions documentation](https://duckdb.org/docs/extensions/json).

**Official DuckDB documentation takes precedence over these examples.**

### Pattern: Version Distribution

**Use case**: Analyze distribution of WordPress/PHP versions

```sql
WITH
  versions AS (
    SELECT CAST(field->'version' AS text) AS version_number
    FROM loop_items
    JOIN recent_loops ON loop_items.filename = recent_loops.filename
  ),
  version_counts AS (
    SELECT version_number, COUNT(*) AS occurrence_count
    FROM versions
    GROUP BY version_number
  ),
  total_count AS (
    SELECT COUNT(DISTINCT instance) AS total_instances
    FROM recent_loops
  )
SELECT
  vc.version_number,
  vc.occurrence_count,
  ROUND(vc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM version_counts AS vc, total_count AS tc
ORDER BY vc.occurrence_count DESC
```

### Pattern: Plugin/Theme Analysis

**Use case**: Analyze plugin or theme usage

```sql
WITH
  items AS (
    SELECT
      plugins.plugin.plugin_slug,
      plugins.instance
    FROM plugins
    JOIN recent_loops ON plugins.filename = recent_loops.filename
  ),
  item_counts AS (
    SELECT
      CASE
        WHEN plugin_slug LIKE 'special%' THEN 'Special Category'
        ELSE plugin_slug
      END AS slug,
      COUNT(*) AS occurrence_count
    FROM items
    WHERE plugin_slug NOT LIKE 'ionos-%'  -- Exclude internal plugins
    GROUP BY slug
  ),
  total AS (
    SELECT COUNT(DISTINCT instance) AS instances
    FROM recent_loops
  )
SELECT
  ic.slug,
  ic.occurrence_count,
  ROUND(ic.occurrence_count * 100.0 / t.instances, 2) AS percentage
FROM item_counts AS ic, total AS t
ORDER BY ic.occurrence_count DESC
```

### Pattern: Event Analysis

**Use case**: Analyze user events (logins, clicks, etc.)

```sql
-- Time-based event analysis
SELECT
  json_extract_string(event.payload, '$.type') AS event_type,
  COUNT(*) AS total_events,
  COUNT(DISTINCT instance) AS unique_instances
FROM events
WHERE
  event.name = 'specific_event'
  AND timestamp >= current_timestamp - INTERVAL 7 DAY
GROUP BY event_type
ORDER BY total_events DESC
```

### Pattern: Boolean Feature Analysis

**Use case**: Analyze on/off features

```sql
WITH unique_instances AS (
  SELECT DISTINCT
    instance,
    (plugin_data->'plugin'->'setting'->>'option')::BOOLEAN AS feature_enabled
  FROM loop_items
  JOIN recent_loops ON loop_items.filename = recent_loops.filename
)
SELECT
  COUNT(CASE WHEN feature_enabled IS TRUE THEN 1 END) AS enabled,
  COUNT(CASE WHEN feature_enabled IS FALSE THEN 1 END) AS disabled,
  COUNT(CASE WHEN feature_enabled IS NULL THEN 1 END) AS unknown
FROM unique_instances
```

### Pattern: Multi-Category Analysis

**Use case**: Categorize instances into multiple groups

```sql
WITH categorized AS (
  SELECT
    instance,
    bool_or(condition1) AS uses_feature1,
    bool_or(condition2) AS uses_feature2
  FROM events
  JOIN recent_loops ON events.filename = recent_loops.filename
  GROUP BY instance
)
SELECT
  COUNT(CASE WHEN uses_feature1 AND NOT uses_feature2 THEN 1 END) AS feature1_only,
  COUNT(CASE WHEN NOT uses_feature1 AND uses_feature2 THEN 1 END) AS feature2_only,
  COUNT(CASE WHEN uses_feature1 AND uses_feature2 THEN 1 END) AS both,
  COUNT(CASE WHEN NOT uses_feature1 AND NOT uses_feature2 THEN 1 END) AS neither
FROM categorized
```

### Pattern: Nested JSON Extraction

**Use case**: Extract deeply nested JSON data

```sql
SELECT
  instance,
  -- Simple path
  (field->>'key') AS simple_value,
  -- Nested path
  (field->'level1'->'level2'->>'key') AS nested_value,
  -- Cast to specific type
  (field->'setting'->>'option')::BOOLEAN AS boolean_value,
  -- Extract from JSON string
  json_extract_string(field->'data', '$.path.to.value') AS extracted_value
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
```

### Pattern: LATERAL Join (Advanced)

**Use case**: Unnest JSON object keys dynamically

```sql
WITH LatestInstances AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY instance ORDER BY timestamp DESC) AS rn
  FROM loop_items
)
SELECT
  i.instance,
  t.key AS setting_name,
  t.value AS setting_value
FROM LatestInstances AS i,
  LATERAL (
    SELECT
      unnest(json_keys(i.field->'settings')) AS key,
      (i.field->'settings')->(unnest(json_keys(i.field->'settings'))) AS value
  ) AS t
WHERE i.rn = 1
```

---

## Visualization Patterns

**IMPORTANT**: For authoritative Mermaid syntax, always consult the [official Mermaid pie chart documentation](https://mermaid.js.org/syntax/pie.html). The examples below are project-specific templates only.

### Pie Chart - Basic

**Use case**: Simple distribution

```bash
\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.category_column)\" : \(.count_column)")
')
\`\`\`
```

### Pie Chart - With Percentages

```bash
\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.category) (\(.percentage)%)\" : \(.count)")
')
\`\`\`
```

### Pie Chart - Key-Value Object

**Use case**: When SQL returns object with key-value pairs

```bash
\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | to_entries[] | "  \"\(.key)\" : \(.value)")
')
\`\`\`
```

### Pie Chart - Formatted Labels

**Use case**: Custom label formatting

```bash
\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData" ,
    (.[] | "  \"\(.name | gsub("\""; "")) (\(.count) instances)\" : \(.count)")
')
\`\`\`
```

### Chart Limitations

- **Maximum items**: 10-12 for readability
- **Label length**: Keep labels under 30 characters
- **Special characters**: Escape quotes in labels
- **Zero values**: May not render or cause issues

---

## Schema Discovery

### Using MCP Server for Schema Exploration

**CRITICAL**: Before writing SQL queries:
1. **First**: Explore the database schema using the DuckDB MCP server (`mcp__duckdb__query`)
2. **Second**: Consult [official DuckDB documentation](https://duckdb.org/docs/sql/introduction) for SQL syntax
3. **Third**: Use project examples as templates

**Essential schema discovery queries**:

```sql
-- List all tables
SHOW TABLES;

-- Describe table structure
DESCRIBE loop_items;
DESCRIBE plugins;
DESCRIBE themes;
DESCRIBE events;

-- Preview table data
SELECT * FROM loop_items LIMIT 1;

-- Inspect JSON structure
SELECT hosting, wordpress, plugin_data FROM loop_items LIMIT 1;

-- Explore nested JSON paths
SELECT plugin_data->'ionos-essentials' FROM loop_items LIMIT 1;

-- List columns in a table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'loop_items';
```

**Workflow for unknown data structures**:

1. **Start with broad query**: `SELECT * FROM table LIMIT 1`
2. **Inspect JSON fields**: `SELECT json_field FROM table LIMIT 1`
3. **Navigate nested structure**: `SELECT json_field->'nested' FROM table LIMIT 1`
4. **Extract specific values**: `SELECT json_field->'nested'->>'value' FROM table LIMIT 5`
5. **Build final query** with confidence in column names and types

**Example discovery workflow**:

```sql
-- Step 1: See what's in plugin_data
SELECT plugin_data FROM loop_items LIMIT 1;
-- Result shows: {"ionos-essentials": {...}, ...}

-- Step 2: Explore ionos-essentials structure
SELECT plugin_data->'ionos-essentials' FROM loop_items LIMIT 1;
-- Result shows: {"security": {...}, "dashboard": {...}}

-- Step 3: Navigate to security settings
SELECT plugin_data->'ionos-essentials'->'security' FROM loop_items LIMIT 1;
-- Result shows: {"IONOS_SECURITY_FEATURE_OPTION_XMLRPC": "true", ...}

-- Step 4: Build the extraction query
SELECT
  (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_XMLRPC')::BOOLEAN AS xmlrpc
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
LIMIT 5;
```

## Available Tables and Views

### loop_items

**Description**: Raw WordPress instance data from JSON files

**Key Columns**:
- `timestamp` - Data collection timestamp
- `instance` - Unique instance identifier
- `filename` - Source file name
- `hosting` - JSON object with hosting info (PHP version, core version)
- `wordpress` - JSON object with WordPress data (active_plugins, active_theme)
- `plugin_data` - JSON object with plugin-specific data
- `events` - JSON array of events

**Usage**: Join with `recent_loops` for current state analysis

### plugins

**Description**: Unnested active plugins from loop_items

**Schema**:
```sql
SELECT
  timestamp,      -- When data was collected
  instance,       -- Instance identifier
  filename,       -- Source file
  plugin          -- Struct with: plugin_slug, version, auto_update
FROM plugins
```

**Usage**: Join with `recent_loops`, filter out IONOS plugins

### themes

**Description**: Unnested active theme from loop_items

**Schema**:
```sql
SELECT
  timestamp,      -- When data was collected
  instance,       -- Instance identifier
  filename,       -- Source file
  theme           -- Struct with: id, version, parent_theme_slug, auto_update
FROM themes
```

**Usage**: Join with `recent_loops` for current theme analysis

### events

**Description**: Unnested events from loop_items

**Schema**:
```sql
SELECT
  timestamp,      -- When event occurred
  instance,       -- Instance identifier
  filename,       -- Source file
  event           -- Struct with: name, payload (JSON), timestamp
FROM events
```

**Usage**: Filter by event.name, extract payload data, time-based analysis

### recent_loops (VIEW)

**Description**: Most recent loop record per instance

**Schema**:
```sql
SELECT
  filename,       -- Most recent file for instance
  instance,       -- Instance identifier
  timestamp       -- Latest timestamp
FROM recent_loops
```

**Usage**: Join target for current state queries - ALWAYS use this

**Created by**: [020-create-duckdb-database.sh](../../../scripts/generate-report-parts/020-create-duckdb-database.sh)

---

## Common CTEs

### Get Total Instance Count

```sql
total_count AS (
  SELECT COUNT(DISTINCT instance) AS total_instances
  FROM recent_loops
)
```

### Filter to Recent Data

```sql
recent_data AS (
  SELECT *
  FROM loop_items
  JOIN recent_loops ON loop_items.filename = recent_loops.filename
)
```

### Calculate Percentages

```sql
WITH counts AS (...),
total AS (SELECT COUNT(DISTINCT instance) AS total FROM recent_loops)
SELECT
  counts.*,
  ROUND(counts.count * 100.0 / total.total, 2) AS percentage
FROM counts, total
```

### Conditional Categorization

```sql
categorized AS (
  SELECT
    instance,
    CASE
      WHEN condition1 THEN 'Category A'
      WHEN condition2 THEN 'Category B'
      ELSE 'Category C'
    END AS category
  FROM recent_data
)
```

---

## Bash Techniques

### Heredoc with Variables

```bash
cat <<EOF
# $TITLE

$(command_substitution)

> **Note: $VARIABLE interpolation works**
EOF
```

### Heredoc without Variable Interpolation

```bash
cat <<'EOF'
# Literal $TITLE - not interpolated
EOF
```

### Multiple Queries in Script

```bash
readonly SQL1="SELECT ..."
readonly SQL2="SELECT ..."

cat <<EOF
# Section 1
$(ionos.loop-duckdb.exec_duckdb "$SQL1" '-markdown')

# Section 2
$(ionos.loop-duckdb.exec_duckdb "$SQL2" '-markdown')
EOF
```

### Conditional Output

```bash
if [[ condition ]]; then
  cat <<EOF
  # Conditional Section
  $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
  EOF
fi
```

### Comments in SQL

```bash
readonly SQL="
-- This is a SQL comment
SELECT ... -- Inline comment
/*
Multi-line
comment
*/
"
```

---

## Error Handling

### Common Errors

**"Command not found: ionos.loop-duckdb.exec_duckdb"**
- Cause: Script run outside generate-report.sh context
- Solution: Always run via `pnpm generate-report`

**"Syntax error near unexpected token"**
- Cause: Unescaped special characters in heredoc
- Solution: Check backticks, quotes, parentheses

**"Table does not exist"**
- Cause: Database not generated or wrong table name
- Solution: Run `pnpm generate-report` to create database

**"jq: parse error"**
- Cause: Invalid JSON from SQL query
- Solution: Test SQL output format, check JSON structure

### Debugging Techniques

**Test SQL in DuckDB UI**:
```bash
pnpm start-report-ui
# Paste query and test
```

**Test script in isolation**:
```bash
pnpm generate-report --verbose '055-my-script.sh'
```

**Check SQL output format**:
```bash
# Add to script temporarily
echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq '.'
```

**Validate jq syntax**:
```bash
echo '[{"key":"value"}]' | jq -r '(.[] | "\(.key)")'
```

---

## Best Practices Summary

### Documentation Priority

1. **Always consult [official DuckDB documentation](https://duckdb.org/docs/sql/introduction) first** for SQL syntax
2. **Use [DuckDB JSON documentation](https://duckdb.org/docs/extensions/json)** for JSON operations
3. **Use MCP server** to explore schema before writing queries
4. **Use project examples** as templates only, not as definitive references

### Schema Exploration

1. Always explore schema first using MCP server before writing queries
2. Use `DESCRIBE` to understand table structure
3. Use `SELECT ... LIMIT 1` to inspect JSON structure
4. Navigate JSON paths incrementally to understand nesting
5. Consult official DuckDB documentation for correct syntax
6. Test column names and types before building final query

### SQL

1. **Refer to official DuckDB docs** for authoritative SQL syntax
2. Always join with `recent_loops` for current state
3. Use CTEs for readability (see [DuckDB CTE docs](https://duckdb.org/docs/sql/query_syntax/with))
4. Add comments explaining complex logic
5. Use `100.0` for percentage calculations (not `100`)
6. Filter out IONOS-specific data when appropriate
7. Use `DISTINCT` when counting unique instances
8. Handle NULL values explicitly

### Bash

1. Use `readonly` for constants
2. Make scripts executable (`chmod +x`)
3. Add descriptive comments at top
4. Use heredocs for multi-line output
5. Test in isolation before full report run
6. Follow naming conventions

### Visualizations

1. Limit pie charts to <= 10 items
2. Use descriptive labels
3. Escape special characters
4. Test mermaid syntax
5. Include titles for context

### Testing

1. Develop queries in DuckDB UI first
2. Test script with `--dry-run`
3. Run script in isolation
4. Validate output format
5. Check percentages sum correctly
6. Verify chart renders properly

---

## Quick Reference Commands

```bash
# Make script executable
chmod +x scripts/generate-report-parts/NNN-name.sh

# Test single script
pnpm generate-report 'NNN-name.sh'

# Test with verbose output
pnpm generate-report --verbose 'NNN-name.sh'

# Dry run (see what would execute)
pnpm generate-report --dry-run 'NNN*'

# Open DuckDB UI for query development
pnpm start-report-ui

# Generate full report
pnpm generate-report

# Generate specific sections
pnpm generate-report '040*' '050*' '060*'
```

---

## Additional Resources

**Priority order for references**:
1. **[Official DuckDB documentation](https://duckdb.org/docs/)** - Primary reference for SQL syntax
2. **[Official Mermaid documentation](https://mermaid.js.org/)** - Primary reference for chart syntax
3. [SKILL.md](SKILL.md) - Main skill guide with patterns and workflows
4. [examples.md](examples.md) - Complete working examples from the project
5. [DuckDB skill](../duckdb/SKILL.md) - Database querying reference
6. [Project README](../../../README.md) - Overall project documentation
