#!/usr/bin/env bash

#
# generates markdown output for most active themes section of the report
# 

readonly SQL="
WITH
  _themes AS (
    SELECT
      themes.theme.id,
      themes.instance
    FROM
      themes
    JOIN recent_loops ON themes.filename = recent_loops.filename
  ),
  theme_counts AS (
    -- Calculate the occurrence count for each theme
    SELECT
      id as slug,
      COUNT(*) AS occurrence_count
    FROM
      _themes
    GROUP BY
      slug
  ),
  total_count AS (
    -- Calculate the total number of instances
    SELECT
      COUNT(DISTINCT instance) AS instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  theme_counts.slug,
  theme_counts.occurrence_count,
  ROUND(theme_counts.occurrence_count * 100.0 / instances, 2) AS percentage
FROM
  theme_counts,
  total_count
ORDER BY
  theme_counts.occurrence_count DESC
"

readonly TITLE="Most active themes"

cat <<EOF

# $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 20;" '-markdown')

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.slug)\" : \(.occurrence_count)")
')
\`\`\`
EOF
