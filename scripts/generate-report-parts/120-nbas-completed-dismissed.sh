#!/usr/bin/env bash

#
# generates nba related questions markdown output for "nbas dismissed" and "NBAs still open (at time of retrieval)"
# Single value: Percent of overall nbas done
# 

SQL() {
  cat <<EOF
WITH LatestInstances AS (
  -- 1. Identify the single, most recent record for each unique instance.
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY instance ORDER BY "timestamp" DESC) AS rn
  FROM
    loop_items
),
UnnestedNBAs AS (
  -- 2. Unnest the NBA statuses ONLY from the latest records (rn = 1).
  SELECT
    i.instance,
    t.key,
    t.value
  FROM
    LatestInstances AS i,
    LATERAL (
      SELECT 
        unnest(json_keys((i.plugin_data->'ionos-essentials'->'dashboard'->'nba_status'))) AS key,
        (i.plugin_data->'ionos-essentials'->'dashboard'->'nba_status')->(unnest(json_keys((i.plugin_data->'ionos-essentials'->'dashboard'->'nba_status')))) AS value
    ) AS t
  WHERE
    i.rn = 1 -- Filter down to only the latest record per instance
)
-- 3. Calculate the overall percentage from the de-duplicated, unnested data.
SELECT
  -- Calculate the percentage: (Total Completed / Total NBAs) * 100
  SUM(CASE 
    WHEN value::VARCHAR = '$1' THEN 1 
    ELSE 0 
  END) * 100.0 / COUNT(key) AS overall_percentage
FROM
  UnnestedNBAs;
EOF
}

cat <<EOF

# How many NBAs are done (per unique customer) ?

**$(echo $(ionos.loop-duckdb.exec_duckdb "$(SQL '"completed"')" '-json') | jq -r '.[0] | (.overall_percentage)')%** of all NBAs are completed.

# How many NBAs are still open (at time of retrieval) ?

**$(echo $(ionos.loop-duckdb.exec_duckdb "$(SQL 'null')" '-json') | jq -r '.[0] | (.overall_percentage)')%** of all NBAs are open.
EOF


