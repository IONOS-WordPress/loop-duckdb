#!/usr/bin/env bash

set -euo pipefail

REPORT_NAME="${REPORT_NAME:-generate-report}"
CSV_OUTPUT="$REPORT_NAME/plugin_versions_by_instance.csv"
TITLE="Plugin Versions by Instance (latest only, ≥500 instances)"

mkdir -p "$REPORT_NAME"

# SQL for plugin versions with percentage column
SQL="
WITH total_instances AS (
  SELECT COUNT(DISTINCT recent_loops.instance) AS total FROM recent_loops
),
numbered_plugins AS (
  SELECT
    ROW_NUMBER() OVER (
      ORDER BY COUNT(DISTINCT recent_loops.instance) DESC, plugins.plugin.plugin_slug ASC
    ) AS nr,
    plugins.plugin.plugin_slug AS plugin,
    CAST(plugins.plugin.version AS VARCHAR) AS version,
    COUNT(DISTINCT recent_loops.instance) AS instance_count,
    ROUND(COUNT(DISTINCT recent_loops.instance) * 100.0 / (SELECT total FROM total_instances), 2) AS percentage
  FROM plugins
  JOIN recent_loops
    ON plugins.filename = recent_loops.filename
  WHERE plugins.plugin.plugin_slug NOT LIKE '01-ext-%'
  GROUP BY plugin, version
  HAVING COUNT(DISTINCT recent_loops.instance) >= 100
)
SELECT *
FROM numbered_plugins
ORDER BY nr;
"

# CSV export
ionos.loop-duckdb.exec_duckdb "$SQL" '-csv' > "$CSV_OUTPUT"

# Get total number of distinct instances
TOTAL_INSTANCES=$(ionos.loop-duckdb.exec_duckdb \
  "SELECT COUNT(DISTINCT instance) FROM recent_loops;" \
  '-list')

# Markdown report with pie chart
cat <<EOF
# $TITLE

**Total instances analyzed:** $TOTAL_INSTANCES

| # | Plugin | Version | Instance Count | Share of Instances (%) |
|---|--------|---------|----------------|-----------------------|
$(ionos.loop-duckdb.exec_duckdb "$SQL;" '-markdown')

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \(.plugin) \(.version) : \(.instance_count)")
')
\`\`\`

**Note:**  
01-ext plugins are excluded.  
Only plugin versions installed on **at least 500 instances** are included.

---

The full data is exported as CSV:  
\`$CSV_OUTPUT\`
EOF