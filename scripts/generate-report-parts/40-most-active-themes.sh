#!/usr/bin/env bash

#
# generates markdown output for most active plugins section of the report
# 

readonly SQL="
-- [real insight]
-- select latest loop data unique for each customer and accumulate the most active (used) themes
--
WITH
  recent_themes AS (
    SELECT
      t.theme.id,
      t.instance,
      t.theme.active
    FROM
      themes AS t
      JOIN recent_loops AS rl ON t.file = rl.recent_loop_file
  ),
  theme_counts AS (
    -- Calculate the occurrence count for each theme
    SELECT
      id as slug,
      COUNT(*) AS occurrence_count
    FROM
      recent_themes
    WHERE
      active = true -- OR active = false
    GROUP BY
      slug
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
  pc.slug,
  pc.occurrence_count,
  ROUND(pc.occurrence_count * 100.0 / tc.total_instances, 2) AS percentage
FROM
  theme_counts AS pc,
  total_count AS tc
ORDER BY
  pc.occurrence_count DESC
"

readonly TITLE="Most active themes"

cat <<EOF

# $TITLE

$(query_duckdb "$SQL LIMIT 20;" '-markdown')

\`\`\`mermaid
$(echo $(query_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.slug)\" : \(.occurrence_count)")
')
\`\`\`
EOF
