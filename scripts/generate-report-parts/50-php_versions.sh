#!/usr/bin/env bash

#
# generates markdown output for php versions of the report
# 

readonly SQL="
WITH
    php_versions AS (
    SELECT
      CAST(hosting->'php_version' as text) as php_version
    FROM
      loop_items
    JOIN recent_loops ON loop_items.filename = recent_loops.filename
  ),
  php_version_counts AS (
    -- Calculate the count for each php version
    SELECT
      php_version,
      COUNT(*) AS occurrence_count
    FROM
      php_versions
    GROUP BY
      php_version
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
  pvc.php_version,
  pvc.occurrence_count,
  ROUND(pvc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM
  php_version_counts AS pvc,
  total_count AS tc
ORDER BY
  pvc.occurrence_count DESC
"

readonly TITLE="PHP versions"

cat <<EOF

# $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL;" '-markdown' | sed 's/"/ /g')

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \(.php_version) : \(.occurrence_count)")
')
\`\`\`
EOF
