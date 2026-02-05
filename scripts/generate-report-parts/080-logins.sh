#!/usr/bin/env bash

#
# generates markdown output for login related questions of the report
# 

TITLE="How do Ionos users login ?"
SUBTITLE="Count of logins by type"

SQL="
  WITH unique_instance_data AS (
  SELECT
    filename,
    (hosting->>'tenant') AS tenant
  FROM loop_items
)
  SELECT
    CASE 
      WHEN event.payload->>'type' = 'default' THEN 'password'
      ELSE event.payload->>'type'
    END AS login_type,
    COUNT(*) AS total_logins
  FROM 
    events,
    unique_instance_data
  WHERE 
    event.name = 'login'
    AND tenant = 'ionos'
    AND unique_instance_data.filename = events.filename
  GROUP BY 
    login_type
  ;
"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL;" '-json') | jq -r --arg title "$SUBTITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.login_type)\" : \(.total_logins)")
')
\`\`\`
EOF

TITLE="Users using SSO from CP vs from wp-login "

SQL="
SELECT
  -- SSO Login Count: Unique instances where the event name is 'login' and payload type is 'sso'
  COUNT(DISTINCT CASE
      WHEN json_extract_string(event.payload, '$.source') == 'wp-login' THEN instance
      ELSE NULL
  END) AS wp,

  -- Manual (Default) Login Count: Unique instances where the event name is 'login' and payload type is 'default'
  COUNT(DISTINCT CASE
      WHEN json_extract_string(event.payload, '$.source') == 'control-panel' THEN instance
      ELSE NULL
  END) AS controlpanel,
  COUNT(DISTINCT CASE
      WHEN (json_extract_string(event.payload, '$.source') == 'wp-login' OR json_extract_string(event.payload, '$.source') == 'control-panel') THEN instance
      ELSE NULL
  END) AS overall
FROM
  events
WHERE
  -- Filter for events that happened in the last $INTERVAL_DAYS days (last week)
  -- timestamp >= current_timestamp - INTERVAL 7 DAY
  event.name = 'login'
  AND NOT json_extract_string(event.payload, '$.source') == ''; -- Optional: filter down to just login events for performance
;
"

cat <<EOF

## $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')

EOF


TITLE="Are the password logins done by admins or non-admins?"

SQL="
SELECT 
  json_extract_string(event.payload, '$.is_admin') as is_admin,
  COUNT(*) as occurrence_count 
FROM events 
WHERE is_admin IS NOT NULL 
GROUP BY is_admin;
"

cat <<EOF

## $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')

EOF

######################################################################################

INTERVAL_DAYS=7
TITLE="Active customers logged into WordPress in the last ${INTERVAL_DAYS} days"
SQL="
SELECT
  -- SSO Login Count: Unique instances where the event name is 'login' and payload type is 'sso'
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' AND json_extract_string(event.payload, '$.type') = 'sso' THEN instance
      ELSE NULL
  END) AS sso,

  -- Manual (Default) Login Count: Unique instances where the event name is 'login' and payload type is 'default'
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' AND json_extract_string(event.payload, '$.type') = 'default' THEN instance
      ELSE NULL
  END) AS manual,

  -- All Login Count: Unique instances where the event name is 'login' (regardless of type)
  COUNT(DISTINCT CASE
      WHEN event.name = 'login' THEN instance
      ELSE NULL
  END) AS both
FROM
  events
WHERE
  -- Filter for events that happened in the last $INTERVAL_DAYS7 days (last week)
  timestamp >= current_timestamp - INTERVAL ${INTERVAL_DAYS} DAY
  AND event.name = 'login'; -- Optional: filter down to just login events for performance
;
"


cat <<EOF

## $TITLE

($(date +"%Y-%m-%d") - $(date -d "7 days ago" +"%Y-%m-%d"))

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
EOF

######################################################################################

SQL="
WITH CustomerLoginTypes AS (
  -- 1. Get all unique (customer, login_type) pairs
  SELECT
    instance,
    json_extract_string(event.payload, '$.type') AS login_type
  FROM
    events
  WHERE
    event.name = 'login'
  GROUP BY
    1, 2
),
CustomerUsageSummary AS (
  -- 2. Summarize usage for each customer (instance) using boolean flags
  SELECT
      instance,
      bool_or(login_type = 'sso') AS used_sso,
      bool_or(login_type = 'default') AS used_password
  FROM
      CustomerLoginTypes
  GROUP BY
      instance
)
-- 3. Final Query: Count customers based on their usage summary into a single row
SELECT
  -- Count customers who used only SSO
  COUNT(CASE WHEN used_sso = TRUE AND used_password = FALSE THEN 1 END) AS sso,

  -- Count customers who used only Password (default)
  COUNT(CASE WHEN used_sso = FALSE AND used_password = TRUE THEN 1 END) AS password,

  -- Count customers who used Both types
  COUNT(CASE WHEN used_sso = TRUE AND used_password = TRUE THEN 1 END) AS both
FROM
  CustomerUsageSummary;
"

TITLE="How do users log in ?"

cat <<EOF

## $TITLE

> sso, manual or mixing both login types

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  # Select the first (and only) object in the array
  .[0] |
  # Start the chart definition
  "pie showData title \($title)\n" +
  # Format and append the SSO data
  "  \"SSO Only\": \(.sso)\n" +
  # Format and append the Manual data
  "  \"Password Only\": \(.manual)\n" +
  # Format and append the Both data
  "  \"Both Types\": \(.both)"
')
\`\`\`
EOF

