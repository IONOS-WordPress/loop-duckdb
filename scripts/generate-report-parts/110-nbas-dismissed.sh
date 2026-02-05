#!/usr/bin/env bash

#
# generates nba related questions markdown output for "nbas dismissed"
# Are NBAs used? Especially: are they dismissed? What's dismissed
# 
# Table: nba | count | completed % | dismissed % | not started %
# 

readonly SQL="
WITH NBAStatus AS (
    SELECT instance, plugin_data->'ionos-essentials'->'dashboard'->>'nba_status' AS nba_data
    FROM loop_items
    WHERE plugin_data->'ionos-essentials'->'dashboard'->>'nba_status' IS NOT NULL
),
UnpivotedNBA AS (
    SELECT instance, unnest(json_keys(nba_data)) AS nba_key, json_extract_string(nba_data, '$.' || nba_key) AS status
    FROM NBAStatus
),
TotalInstances AS (
    SELECT COUNT(DISTINCT instance) AS total_count FROM loop_items
),
SummaryByNBA AS (
    SELECT
        nba_key,
        COUNT(DISTINCT instance) AS instances_with_nba,
        COUNT(DISTINCT CASE WHEN status = 'completed' THEN instance END) AS completed_count,
        COUNT(DISTINCT CASE WHEN status = 'dismissed' THEN instance END) AS dismissed_count,
        COUNT(DISTINCT CASE WHEN status IS NULL THEN instance END) AS not_started_count
    FROM UnpivotedNBA
    GROUP BY nba_key
)
SELECT
    nba_key AS nba,
    instances_with_nba AS count,
    (completed_count * 100.0 / (SELECT total_count FROM TotalInstances))::NUMERIC(5, 2) AS 'completed %',
    (dismissed_count * 100.0 / (SELECT total_count FROM TotalInstances))::NUMERIC(5, 2) AS 'dismissed %',
    (not_started_count * 100.0 / (SELECT total_count FROM TotalInstances))::NUMERIC(5, 2) AS 'not started %'
FROM SummaryByNBA
ORDER BY instances_with_nba DESC, nba_key
;
"

readonly TITLE="What NBAs are used?"

cat <<EOFMD

# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))
EOFMD
