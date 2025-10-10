#!/usr/bin/env bash

#
# generates markdown output for most active plugins section of the report
# 

readonly SQL="
-- [real insight]
-- select latest loop data unique for each customer and accumulate the most active (used) plugins
WITH
  recent_plugins AS (
    SELECT
      p.plugin.plugin_slug,
      p.instance,
      p.plugin.active
    FROM
      plugins AS p
      JOIN recent_loops AS rl ON p.file = rl.recent_loop_file
  ),
  plugin_counts AS (
    -- Calculate the occurrence count for each plugin
    SELECT
      plugin_slug AS slug,
      COUNT(*) AS occurrence_count
    FROM
      recent_plugins
    WHERE
      active = true -- OR active = false
      -- exclude our own plugins
      AND plugin_slug NOT LIKE 'ionos-%'
    GROUP BY
      slug
  ),
  total_count AS (
    -- Calculate the total number of instances from the view
    SELECT
      COUNT(DISTINCT instance) AS total_instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pc.slug,
  pc.occurrence_count,
  ROUND(pc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM
  plugin_counts AS pc,
  total_count AS tc
ORDER BY
  pc.occurrence_count DESC
"

readonly TITLE="Most active plugins"

cat <<EOF

# $TITLE

> **IONOS plugins are excluded from the report.**

$(query_duckdb "$SQL LIMIT 20;" '-markdown')

\`\`\`mermaid
$(echo $(query_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.slug)\" : \(.occurrence_count)")
')
\`\`\`
EOF
