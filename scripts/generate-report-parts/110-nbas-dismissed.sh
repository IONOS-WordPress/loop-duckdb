#!/usr/bin/env bash

#
# generates nba related questions markdown output for "nbas dismissed"
# Are NBAs used? Especially: are they dismissed? What’s dismissed
# Most dismissed actions? => need to be changed
# Table: nba | completed % | dismissed % | done % | count
# 

readonly SQL="
WITH NBAStatus AS (
    -- Extract the entire nba_status object as a JSON type
    SELECT
        instance,
        plugin_data->'ionos-essentials'->'dashboard'->>'nba_status' AS nba_data
    FROM
        loop_items
),
UnpivotedNBA AS (
    -- Get list of all keys from the NBA object and UNNEST them
    SELECT
        instance,
        t1.nba_data,
        unnest(json_keys(t1.nba_data)) AS nba_key
    FROM
        NBAStatus t1
    WHERE
        t1.nba_data IS NOT NULL -- Only proceed if the nba_status object exists
),
StatusLookup AS (
    -- Extract the status value for each key.
    SELECT
        instance,
        nba_key,
        -- Dynamically extract the value based on the nba_key
        json_extract_string(nba_data, '$.' || nba_key) AS status
    FROM
        UnpivotedNBA
)
-- Aggregate and calculate percentages
SELECT
    nba_key AS nba,
    (COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(DISTINCT instance))::NUMERIC(5, 2) AS 'completed %',
    (COUNT(CASE WHEN status = 'dismissed' THEN 1 END) * 100.0 / COUNT(DISTINCT instance))::NUMERIC(5, 2) AS 'dismissed %',
    -- 'done' is interpreted as status is NULL or empty string (meaning the item is present but status is complete/pending)
    (COUNT(CASE WHEN status IS NULL OR status = '' THEN 1 END) * 100.0 / COUNT(DISTINCT instance))::NUMERIC(5, 2) AS 'done %',
    COUNT(DISTINCT instance) AS count
FROM
    StatusLookup
GROUP BY
    nba_key
ORDER BY
    count DESC, nba_key
;
"

readonly TITLE="What NBAs are used?"

cat <<EOF

# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))
EOF