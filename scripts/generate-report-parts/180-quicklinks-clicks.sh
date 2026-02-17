#!/usr/bin/env bash

#
# generates quicklinks click analytics for "Quicklinks usage"
# How often each quicklink is clicked
# What percentage of users clicked on each quicklink
#

SQL=$(cat <<EOF
WITH AllInstances AS (
  -- 1. Get all records (including historical) for each instance
  SELECT
    instance,
    clicks
  FROM
    loop_items
  WHERE
    clicks IS NOT NULL
),
TotalInstances AS (
  -- 2. Calculate total number of unique instances
  SELECT COUNT(DISTINCT instance) AS total_count
  FROM loop_items
),
ClicksUnnested AS (
  -- 3. Unnest the clicks object from ALL records for each instance
  SELECT
    i.instance,
    t.key AS quicklink_id,
    t.value::INTEGER AS click_count
  FROM
    AllInstances AS i
  CROSS JOIN
    LATERAL (SELECT * FROM json_each(i.clicks)) AS t(key, value)
  WHERE
    i.clicks IS NOT NULL
),
ClicksSummed AS (
  -- 4. Sum clicks per instance per quicklink
  SELECT
    instance,
    quicklink_id,
    SUM(click_count) AS total_instance_clicks
  FROM
    ClicksUnnested
  GROUP BY
    instance,
    quicklink_id
)
-- 5. Calculate aggregated statistics per quicklink
SELECT
  quicklink_id,
  SUM(total_instance_clicks) AS "Total Clicks on this Quicklink",
  COUNT(DISTINCT instance) AS "Different Users Clicked on this Quicklink",
  ROUND((COUNT(DISTINCT instance) * 100.0) / (SELECT total_count FROM TotalInstances), 2) AS "Engagement Rate (%)",
  ROUND(SUM(total_instance_clicks)::NUMERIC / COUNT(DISTINCT instance), 2) AS "Average Clicks per User"
FROM
  ClicksSummed
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

\`\`\`mermaid
---
config:
    xyChart:
        width: 1000
        height: 600
        showDataLabel: false
---
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "xychart-beta" , 
  "  x-axis [" + ([.[].quicklink_id] | map("\"" + . + "\"") | join(",")) + "]",
  "  bar [" + ([.[]."Total Clicks on this Quicklink"] | join(",")) + "]"
')
\`\`\`
EOF
