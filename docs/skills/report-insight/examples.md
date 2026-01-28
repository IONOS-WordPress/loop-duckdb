# Report Insights Examples

Complete, working examples of report insight scripts from the loop-duckdb project. All examples are real scripts from `scripts/generate-report-parts/`.

## ⚠️ CRITICAL: Technology Requirements

**ALL examples use ONLY:**
- ✅ **Bash** for scripting
- ✅ **jq** for JSON processing
- ✅ **DuckDB SQL** for queries

**NO Python is used or allowed in any insight script.**

## IMPORTANT: Documentation Priority

**These examples are templates only. Always prioritize official documentation:**

1. **First**: Consult [official DuckDB documentation](https://duckdb.org/docs/sql/introduction) for SQL syntax
2. **Second**: Use the DuckDB MCP server to explore the database schema
3. **Third**: Use these examples as templates

## Before You Begin

**Use the DuckDB MCP server to explore the database schema before writing queries:**

```sql
-- See available tables
SHOW TABLES;

-- Understand table structure
DESCRIBE loop_items;

-- Inspect sample data
SELECT * FROM loop_items LIMIT 1;

-- Explore JSON fields (see https://duckdb.org/docs/extensions/json)
SELECT hosting, wordpress, plugin_data FROM loop_items LIMIT 1;
```

**For SQL syntax**, refer to:
- [DuckDB SQL Introduction](https://duckdb.org/docs/sql/introduction)
- [DuckDB JSON Functions](https://duckdb.org/docs/extensions/json)

See the [SKILL.md](SKILL.md) and [reference.md](reference.md) for detailed workflows.

## Table of Contents

1. [WordPress Versions](#example-1-wordpress-versions)
2. [Most Active Plugins](#example-2-most-active-plugins)
3. [Extendify Usage](#example-3-extendify-usage)
4. [User Logins](#example-4-user-logins)
5. [Quicklinks Usage](#example-5-quicklinks-usage)
6. [Security Settings](#example-6-security-settings)

---

## Example 1: WordPress Versions

**File**: `040-wordpress_versions.sh`

**Purpose**: Analyze WordPress version distribution across instances

**Pattern**: Version distribution with percentage and visualization

```bash
#!/usr/bin/env bash

#
# generates markdown output for the wordpress versions section of the report
# 

readonly SQL="
WITH
    wp_versions AS (
    SELECT
      CAST(hosting->'core_version' as text) as wordpress_version
    FROM
      loop_items
    JOIN recent_loops ON loop_items.filename = recent_loops.filename
  ),
  wordpress_version_counts AS (
    -- Calculate the count for each php version
    SELECT
      wordpress_version,
      COUNT(*) AS occurrence_count
    FROM
      wp_versions
    GROUP BY
      wordpress_version
  ),
  total_count AS (
    -- Calculate the total number of instances
    SELECT
      COUNT(DISTINCT instance) AS total_instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pvc.wordpress_version,
  pvc.occurrence_count,
  ROUND(pvc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM
  wordpress_version_counts AS pvc,
  total_count AS tc
ORDER BY
  pvc.occurrence_count DESC
"

readonly TITLE="WordPress versions"

cat <<EOF

# $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL;" '-markdown' | sed 's/"/ /g')

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \(.wordpress_version) : \(.occurrence_count)")
')
\`\`\`
EOF
```

**Key Techniques**:
- CTEs for step-by-step data transformation
- JSON field casting: `CAST(hosting->'core_version' as text)`
- Percentage calculation with proper float division (`100.0`)
- Markdown table and Mermaid pie chart
- `sed` to remove quotes from output
- `LIMIT 10` for pie chart (avoid clutter)

---

## Example 2: Most Active Plugins

**File**: `060-most-active-plugins.sh`

**Purpose**: Analyze plugin usage distribution

**Pattern**: Plugin analysis with CASE normalization and exclusions

```bash
#!/usr/bin/env bash

#
# generates markdown output for most active plugins section of the report
# 

readonly SQL="
WITH
  _plugins AS (
    SELECT
      plugins.plugin.plugin_slug,
      plugins.instance
    FROM
      plugins
      JOIN recent_loops ON plugins.filename = recent_loops.filename
  ),
  plugin_counts AS (
    -- Calculate the occurrence count for each plugin
    SELECT
      CASE
        WHEN plugin_slug LIKE '01-ext%' THEN 'Extendify License'
        ELSE plugin_slug
      END AS slug,
      COUNT(*) AS occurrence_count
    FROM
      _plugins
    WHERE
      -- exclude our own plugins
      plugin_slug NOT LIKE 'ionos-%'
    GROUP BY
      CASE
        WHEN plugin_slug LIKE '01-ext%' THEN 'Extendify License'
        ELSE plugin_slug
      END
  ),
  total_count AS (
    -- Calculate the total number of instances from the view
    SELECT
      COUNT(DISTINCT instance) AS instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  plugin_counts.slug,
  plugin_counts.occurrence_count,
  ROUND(plugin_counts.occurrence_count * 100.0 / total_count.instances, 2) AS percentage
FROM
  plugin_counts,
  total_count
ORDER BY
  plugin_counts.occurrence_count DESC
"

readonly TITLE="Most active plugins"

cat <<EOF

# $TITLE

> **IONOS plugins are excluded from the report.**

$(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 20;" '-markdown')

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.slug)\" : \(.occurrence_count)")
')
\`\`\`
EOF
```

**Key Techniques**:
- Using `plugins` unnested table
- CASE statement for normalizing plugin names
- Excluding internal plugins: `WHERE plugin_slug NOT LIKE 'ionos-%'`
- Adding context note with blockquote
- Escaped quotes in jq for labels with spaces

---

## Example 3: Extendify Usage

**File**: `090-extendify.sh`

**Purpose**: Analyze Extendify theme usage

**Pattern**: Simple binary distribution (using vs not using)

```bash
#!/usr/bin/env bash

#
# generates markdown output for extendify related questions of the report
# 

readonly SQL="
SELECT
  count(DISTINCT CASE WHEN theme.id = 'extendable' THEN instance END) AS 'using extendable',
  count(DISTINCT CASE WHEN theme.id <> 'extendable' THEN instance END) AS 'other theme'
FROM
  themes;
"

TITLE="How many of our customers use extendify ?"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
    "pie showData",
    (.[] | to_entries[] | "  \"\(.key)\" : \(.value)")
')
\`\`\`
EOF
```

**Key Techniques**:
- Conditional counting with CASE
- Using `themes` table
- `to_entries[]` jq pattern for key-value objects
- Simple query without CTEs when appropriate

---

## Example 4: User Logins

**File**: `080-logins.sh`

**Purpose**: Analyze login behavior (SSO vs manual)

**Pattern**: Event analysis with multiple queries and visualizations

```bash
#!/usr/bin/env bash

#
# generates markdown output for login related questions of the report
# 

TITLE="How do Ionos users login ?"

SQL="
  WITH unique_instance_data AS (
  SELECT
    filename,
    (hosting->>'tenant') AS tenant
  FROM loop_items
)
  SELECT
    event.payload->>'type' AS login_type,
    COUNT(*) AS total_logins
  FROM 
    events,
    unique_instance_data
  WHERE 
    event.name = 'login'
    AND tenant = 'ionos'
    AND unique_instance_data.filename = events.filename
  GROUP BY 
    login_type
  ;
"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.login_type)\" : \(.total_logins)")
')
\`\`\`
EOF

######################################################################################

INTERVAL_DAYS=7

SQL="
SELECT
  -- SSO Login Count
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' AND json_extract_string(event.payload, '$.type') = 'sso' THEN instance
      ELSE NULL
  END) AS sso,

  -- Manual (Default) Login Count
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' AND json_extract_string(event.payload, '$.type') = 'default' THEN instance
      ELSE NULL
  END) AS manual,

  -- All Login Count
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' THEN instance
      ELSE NULL
  END) AS both
FROM
  events
WHERE
  timestamp >= current_timestamp - INTERVAL ${INTERVAL_DAYS} DAY
  AND event.name = 'login';
;
"

TITLE="Active customers logged into WordPress in the last ${INTERVAL_DAYS} days"

cat <<EOF

# $TITLE

($(date +"%Y-%m-%d") - $(date -d "7 days ago" +"%Y-%m-%d"))

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
EOF

######################################################################################

SQL="
WITH CustomerLoginTypes AS (
  SELECT
    instance,
    json_extract_string(event.payload, '$.type') AS login_type
  FROM
    events
  WHERE
    event.name = 'login'
  GROUP BY
    1, 2
),
CustomerUsageSummary AS (
  SELECT
      instance,
      bool_or(login_type = 'sso') AS used_sso,
      bool_or(login_type = 'default') AS used_manual
  FROM
      CustomerLoginTypes
  GROUP BY
      instance
)
SELECT
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = FALSE THEN 1 END) AS sso,
  COUNT(CASE WHEN used_sso = FALSE AND used_manual = TRUE THEN 1 END) AS manual,
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = TRUE THEN 1 END) AS both
FROM
  CustomerUsageSummary;
"

TITLE="How do users log in ?"

cat <<EOF

# $TITLE

> sso, manual or mixing both login types

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  .[0] |
  "pie showData title \($title)\n" +
  "  \"SSO Only\": \(.sso)\n" +
  "  \"Manual Only\": \(.manual)\n" +
  "  \"Both Types\": \(.both)"
')
\`\`\`
EOF
```

**Key Techniques**:
- Multiple queries in one script
- Event filtering: `WHERE event.name = 'login'`
- JSON payload extraction: `json_extract_string(event.payload, '$.type')`
- Time-based filtering: `INTERVAL ${INTERVAL_DAYS} DAY`
- Boolean aggregation: `bool_or()`
- Shell variable interpolation: `${INTERVAL_DAYS}`
- Date formatting: `date +"%Y-%m-%d"`
- Multi-line jq with explicit newlines

---

## Example 5: Quicklinks Usage

**File**: `130-quicklinks-usage.sh`

**Purpose**: Analyze NBA/quicklink completion rates

**Pattern**: Complex LATERAL join with JSON key extraction

```bash
#!/usr/bin/env bash

#
# generates quicklinks related questions markdown output for "Clicks:Quick Links usage"
# % of users having used the quick link # of clicks per user
# 

SQL=$(cat <<EOF
WITH LatestInstances AS (
  -- 1. Identify the single, most recent record for each unique instance
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY instance ORDER BY "timestamp" DESC) AS rn
  FROM
    loop_items
),
NBAsUnnested AS (
  -- 2. Unnest the NBA statuses ONLY from the latest records (rn = 1)
  SELECT
    i.instance,
    t.key AS quick_link,
    t.value
  FROM
    LatestInstances AS i,
    LATERAL (
      SELECT 
        unnest(json_keys((i.plugin_data -> 'ionos-essentials' -> 'dashboard' -> 'nba_status'))) AS key,
        (i.plugin_data -> 'ionos-essentials' -> 'dashboard' -> 'nba_status') -> (unnest(json_keys((i.plugin_data -> 'ionos-essentials' -> 'dashboard' -> 'nba_status')))) AS value
    ) AS t
  WHERE
    i.rn = 1 
)
-- 3. Calculate the percentage per quick link
SELECT
  quick_link,
  COUNT(DISTINCT instance) AS "Total Instances Available",
  SUM(CASE WHEN value::VARCHAR = '"completed"' THEN 1 ELSE 0 END) AS "Completed Instances",
  ROUND((SUM(CASE WHEN value::VARCHAR = '"completed"' THEN 1 ELSE 0 END) * 100.0) / COUNT(DISTINCT instance), 2) AS "Completion Percentage (%)"
FROM
  NBAsUnnested
GROUP BY
  quick_link
ORDER BY
  "Completion Percentage (%)" DESC;
EOF
)

readonly TITLE="How many users have clicked on quick links?"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "pie showData" , #  title \($title)
  (.[] | "  \"\(.quick_link)\" : \(.["Completion Percentage (%)"])")
')
\`\`\`
EOF
```

**Key Techniques**:
- LATERAL join for dynamic JSON key extraction
- ROW_NUMBER() window function for deduplication
- `json_keys()` for dynamic key extraction
- Accessing columns with spaces: `.["Completion Percentage (%)"]`
- Heredoc for complex SQL: `SQL=$(cat <<EOF ... EOF)`

---

## Example 6: Security Settings

**File**: `140-security-settings.sh`

**Purpose**: Analyze security feature adoption

**Pattern**: Boolean field analysis with UNION pivoting

**Schema Discovery Used**:
Before writing this query, the schema was explored to find the security settings:
```sql
-- Step 1: Find where security settings are stored
SELECT plugin_data FROM loop_items LIMIT 1;

-- Step 2: Navigate to security
SELECT plugin_data->'ionos-essentials'->'security' FROM loop_items LIMIT 1;

-- Step 3: See all available settings
SELECT json_keys(plugin_data->'ionos-essentials'->'security') FROM loop_items LIMIT 1;
-- Result: ["IONOS_SECURITY_FEATURE_OPTION_XMLRPC", "IONOS_SECURITY_FEATURE_OPTION_PEL", ...]

-- Step 4: Test extraction
SELECT
  (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_XMLRPC')::BOOLEAN
FROM loop_items LIMIT 5;
```

```bash
#!/usr/bin/env bash

#
# generates security settings related questions markdown output for "Security Settings"
# Individual % on/off for each setting
# % of Customers still on the default 
# Table: Setting | % on 
# 

SQL=$(cat <<EOF
WITH unique_instance_data AS (
  SELECT DISTINCT
    instance,
    (hosting->'tenant') AS tenant,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_XMLRPC')::BOOLEAN AS xmlrpc_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_PEL')::BOOLEAN AS pel_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_CREDENTIALS_CHECKING')::BOOLEAN AS credentials_checking_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_MAIL_NOTIFY')::BOOLEAN AS mail_notify_enabled
  FROM loop_items
),
metrics AS (
  SELECT
    COUNT(instance) AS total_instances,
    SUM(CASE WHEN xmlrpc_enabled IS TRUE THEN 1 ELSE 0 END) AS xmlrpc_count,
    SUM(CASE WHEN pel_enabled IS TRUE THEN 1 ELSE 0 END) AS pel_count,
    SUM(CASE WHEN credentials_checking_enabled IS TRUE THEN 1 ELSE 0 END) AS credentials_checking_count,
    SUM(CASE WHEN mail_notify_enabled IS TRUE THEN 1 ELSE 0 END) AS mail_notify_count
  FROM unique_instance_data
)
SELECT 'IONOS_SECURITY_FEATURE_OPTION_XMLRPC' AS setting, (xmlrpc_count * 100.0 / total_instances) AS percentage
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_PEL', (pel_count * 100.0 / total_instances)
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_CREDENTIALS_CHECKING', (credentials_checking_count * 100.0 / total_instances)
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_MAIL_NOTIFY', (mail_notify_count * 100.0 / total_instances)
  FROM metrics;
EOF
)

readonly TITLE="Security settings"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))
EOF
```

**Key Techniques**:
- Casting JSON to boolean: `(field->>'option')::BOOLEAN`
- SELECT DISTINCT for deduplication
- Multiple field extraction in one CTE
- UNION ALL for pivoting rows
- Calculating individual percentages
- No visualization (table only)

---

## Common Patterns Summary

### Pattern: Basic Distribution

```bash
readonly SQL="
WITH items AS (...),
     counts AS (SELECT item, COUNT(*) as count FROM items GROUP BY item),
     total AS (SELECT COUNT(*) as total FROM items)
SELECT counts.*, ROUND(count * 100.0 / total, 2) as pct
FROM counts, total
ORDER BY count DESC
"
```

### Pattern: Event Analysis

```bash
readonly SQL="
SELECT
  json_extract_string(event.payload, '$.field') AS field,
  COUNT(*) AS count
FROM events
WHERE event.name = 'event_type'
  AND timestamp >= current_timestamp - INTERVAL 7 DAY
GROUP BY field
"
```

### Pattern: Boolean Feature

```bash
readonly SQL="
SELECT
  COUNT(CASE WHEN feature THEN 1 END) AS enabled,
  COUNT(CASE WHEN NOT feature THEN 1 END) AS disabled
FROM table
JOIN recent_loops ...
"
```

---

## Testing Examples

Test any example by passing its filename to `generate-report`:

```bash
# Copy script to generate-report-parts/
cp example.sh scripts/generate-report-parts/999-test.sh

# Make executable
chmod +x scripts/generate-report-parts/999-test.sh

# Test it - outputs the generated markdown to stdout
pnpm generate-report '999-test.sh'

# Or test an existing insight directly
pnpm generate-report '175-mcp-enabled-last-month.sh'

# Clean up
rm scripts/generate-report-parts/999-test.sh
```

---

## Additional Resources

- [SKILL.md](SKILL.md) - Main skill guide
- [reference.md](reference.md) - Comprehensive reference
- [scripts/generate-report-parts/](../../../scripts/generate-report-parts/) - All source scripts
