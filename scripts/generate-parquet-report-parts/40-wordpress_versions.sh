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
