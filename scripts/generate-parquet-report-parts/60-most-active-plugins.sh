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
      plugin_slug AS slug,
      COUNT(*) AS occurrence_count
    FROM
      _plugins
    WHERE
      -- exclude our own plugins
      plugin_slug NOT LIKE 'ionos-%'
    GROUP BY
      slug
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
