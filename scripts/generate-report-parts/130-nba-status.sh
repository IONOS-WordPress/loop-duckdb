#!/usr/bin/env bash

#
# generates NBA status related questions markdown output for "NBA Status completion"
# % of users having completed NBA status items # of users having seen the NBA status item
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
TotalInstances AS (
  -- 2. Calculate total number of unique instances
  SELECT COUNT(DISTINCT instance) AS total_count
  FROM LatestInstances
  WHERE rn = 1
),
NBAsUnnested AS (
  -- 3. Unnest the NBA statuses ONLY from the latest records (rn = 1)
  SELECT
    i.instance,
    t.key AS nba_status,
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
-- 4. Calculate the percentage per NBA status based on ALL instances
SELECT
  nba_status,
  COUNT(DISTINCT instance) AS "Instances with NBA Status Available",
  SUM(CASE WHEN value::VARCHAR = '"completed"' THEN 1 ELSE 0 END) AS "Completed Instances",
  ROUND((SUM(CASE WHEN value::VARCHAR = '"completed"' THEN 1 ELSE 0 END) * 100.0) / (SELECT total_count FROM TotalInstances), 2) AS "Completion Percentage (% of all instances)",
  ROUND((COUNT(DISTINCT instance) * 100.0) / (SELECT total_count FROM TotalInstances), 2) AS "Seen At Least Once (% of all customers)"
FROM
  NBAsUnnested
GROUP BY
  nba_status
ORDER BY
  "Completion Percentage (% of all instances)" DESC;
EOF
)

readonly TITLE="How many users have completed NBA status items?"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))

\\\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "pie showData",
  (.[] | "  \"\(.nba_status)\" : \(.\"Completion Percentage (% of all instances)\")")
')
\\\`
EOF