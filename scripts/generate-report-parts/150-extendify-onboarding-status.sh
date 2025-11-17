#!/usr/bin/env bash

#
# generates security settings related questions markdown output for "extendify onboarding status"
# Pie chart of status
# 

SQL=$(cat <<EOF
WITH onboarding_counts AS (
  -- 1. Calculate the actual counts from the loop_items table
  SELECT
    JSON_EXTRACT_STRING(plugin_data, '$.extendify.extendify_onboarding_completed') AS extracted_status,
    COUNT(DISTINCT instance) AS unique_instance_count
  FROM
    loop_items
  GROUP BY
    extracted_status
),
onboarding_statuses AS (
  -- 2. Define all required status values for scaffolding: 'true', 'false', and NULL
  SELECT 'true' AS required_status
  UNION ALL
  SELECT 'false' AS required_status
  UNION ALL
  SELECT NULL::VARCHAR AS required_status
),
scaffolded_results AS (
  -- 3. Combine the required statuses with the actual counts, filling in 0s
  SELECT
    CASE s.required_status
      WHEN 'true' THEN 'completed'
      WHEN 'false' THEN 'not completed'
      ELSE 'null'
    END AS onboarding_status,
    COALESCE(c.unique_instance_count, 0) AS unique_instance_count
  FROM
    onboarding_statuses s
  LEFT JOIN
    onboarding_counts c
    ON s.required_status = c.extracted_status
)
-- 4. Final SELECT to calculate the percentage using a Window Function
SELECT
  onboarding_status,
  unique_instance_count,
  -- Calculate percentage: (Count * 100.0) / Total Count
  -- SUM(unique_instance_count) OVER () calculates the total sum across ALL rows
  ROUND(
    (unique_instance_count * 100.0) / SUM(unique_instance_count) OVER (), 2
  ) AS unique_instance_count_in_percent
FROM
  scaffolded_results
ORDER BY
  unique_instance_count DESC,
  onboarding_status
;
EOF
)

readonly TITLE="Extendify Onboarding Status"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "pie showData" , #  title \($title)
  (.[] | "  \"\(.onboarding_status)\" : \(.unique_instance_count)")
')
\`\`\`
EOF


