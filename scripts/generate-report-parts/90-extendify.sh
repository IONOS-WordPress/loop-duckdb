#!/usr/bin/env bash

#
# generates markdown output for extendify related questions of the report
# 

readonly SQL="
SELECT
  count(DISTINCT CASE WHEN theme.id = 'extendable' THEN instance END) AS 'using extendable',
  count(DISTINCT CASE WHEN theme.id <> 'extendable' THEN instance END) AS 'other theme'
FROM
  themes;
"

TITLE="How many of our customers use extendify ?"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)",
    (.[] | to_entries[] | "  \(.key) : \(.value)")
')
\`\`\`
EOF

