#!/usr/bin/env bash

#
# generates markdown output for "Is the Getting Started Dialog finished?""
# 

readonly SQL="
SELECT
  -- Use json_extract_string to access the nested key.
  -- COALESCE is used to give a friendly label to NULL/missing values.
  COALESCE(
      json_extract_string(
          plugin_data,
          '$.ionos-essentials.dashboard.ionos_essentials_nba_setup_completed'
      ),
      'not completed'
  ) AS nba_setup_status,
  -- Count the unique users (instances) for each status
  COUNT(DISTINCT instance) AS unique_instance_count
FROM
  loop_items
GROUP BY
  nba_setup_status
ORDER BY
  unique_instance_count DESC
;
"

readonly TITLE="Is the Getting Started Dialog finished?"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
    "pie showData",
    (.[] | "  \"\(.nba_setup_status)\" : \(.unique_instance_count)")
')
\`\`\`
EOF

