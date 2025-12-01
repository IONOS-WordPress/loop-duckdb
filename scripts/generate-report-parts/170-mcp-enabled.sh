#!/usr/bin/env bash

#
# generates a pie chart for ionos essentials "mcp enabled status"
# Pie chart of status
# 

SQL=$(cat <<EOF
SELECT
  -- Count of unique instances NOT having the 'mcp' property
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_STRING(plugin_data, 'mcp') IS NULL THEN instance
    ELSE NULL
  END) AS no_mcp,

  -- Total unique instances *with* the 'mcp' property (formerly calculated by filtering)
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_STRING(plugin_data, 'mcp') IS NOT NULL THEN instance
    ELSE NULL
  END) AS instances_with_mcp_support,

  -- Count of unique instances where mcp is explicitly set to {"settings":false} (Disabled)
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_STRING(plugin_data, 'mcp') = '{"settings":false}' THEN instance
    ELSE NULL
  END) AS mcp_disabled,

  -- Count of unique instances where mcp exists but IS NOT set to {"settings":false} (Enabled/Other state)
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_STRING(plugin_data, 'mcp') IS NOT NULL
      AND JSON_EXTRACT_STRING(plugin_data, 'mcp') != '{"settings":false}' THEN instance
    ELSE NULL
  END) AS mcp_enabled
FROM loop_items
;
EOF
)

readonly TITLE="MCP status"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
  "pie showData title MCP feature status" ,
  (.[] | "  \"without MCP\" : \(.no_mcp)"),
  (.[] | "  \"MCP enabled\" : \(.mcp_enabled)"),
  (.[] | "  \"MCP disabled\" : \(.mcp_disabled)")
')
\`\`\`
EOF
  

