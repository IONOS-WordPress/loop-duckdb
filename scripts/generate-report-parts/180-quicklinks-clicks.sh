#!/usr/bin/env bash

#
# generates quicklinks click analytics for "Quicklinks usage"
# How often each quicklink is clicked
# What percentage of users clicked on each quicklink
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
ClicksUnnested AS (
  -- 3. Unnest the clicks object ONLY from the latest records (rn = 1)
  SELECT
    i.instance,
    t.key AS quicklink_id,
    t.value::INTEGER AS click_count
  FROM
    LatestInstances AS i
  CROSS JOIN
    LATERAL (SELECT * FROM json_each(i.clicks)) AS t(key, value)
  WHERE
    i.rn = 1 
    AND i.clicks IS NOT NULL
)
-- 4. Calculate click statistics per quicklink
SELECT
  quicklink_id,
  SUM(click_count) AS "Total Clicks",
  COUNT(DISTINCT instance) AS "Instances Clicked",
  ROUND((COUNT(DISTINCT instance) * 100.0) / (SELECT total_count FROM TotalInstances), 2) AS "Users Clicked (%)",
  ROUND(SUM(click_count)::NUMERIC / COUNT(DISTINCT instance), 2) AS "Avg Clicks per User"
FROM
  ClicksUnnested
GROUP BY
  quicklink_id
ORDER BY
  CASE quicklink_id
    WHEN 'add-new-page' THEN 1
    WHEN 'add-new-post' THEN 2
    WHEN 'edit-site-navigation' THEN 3
    WHEN 'change-styles' THEN 4
    WHEN 'edit-header' THEN 5
    WHEN 'edit-footer' THEN 6
    WHEN 'add-plugins' THEN 7
    WHEN 'upload-media' THEN 8
    ELSE 999
  END;
EOF
)

readonly TITLE="Quicklinks Click Analytics"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))

\\\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "bar" , 
  "  x: [" + ([.[].quicklink_id] | map("\"" + . + "\"") | join(",")) + "]",
  "  y: [" + ([.[]."Total Clicks"] | join(",")) + "]"
')
\\\`
EOF
