#!/usr/bin/env bash

#
# generates markdown output for login related questions of the report
# 

TITLE="How do Ionos users login ?"

SQL="
  SELECT
    event.payload->'type' AS login_type,
    COUNT(*) AS total_logins
  FROM 
    events
  WHERE 
    event.name = 'login'
    AND tenant = 'ionos'
  GROUP BY 
    login_type
  ;
"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.login_type)\" : \(.total_logins)")
')
\`\`\`
EOF

######################################################################################

INTERVAL_DAYS=7

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

TITLE="Active customers logged into WordPress in the last ${INTERVAL_DAYS} days"

cat <<EOF

# $TITLE

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
      bool_or(login_type = 'default') AS used_manual
  FROM
      CustomerLoginTypes
  GROUP BY
      instance
)
-- 3. Final Query: Count customers based on their usage summary into a single row
SELECT
  -- Count customers who used only SSO
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = FALSE THEN 1 END) AS sso,

  -- Count customers who used only Manual (default)
  COUNT(CASE WHEN used_sso = FALSE AND used_manual = TRUE THEN 1 END) AS manual,

  -- Count customers who used Both types
  COUNT(CASE WHEN used_sso = TRUE AND used_manual = TRUE THEN 1 END) AS both
FROM
  CustomerUsageSummary;
"

TITLE="How do users log in ?"

cat <<EOF

# $TITLE

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
  "  \"Manual Only\": \(.manual)\n" +
  # Format and append the Both data
  "  \"Both Types\": \(.both)"
')
\`\`\`
EOF
