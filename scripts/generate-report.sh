#!/usr/bin/env bash

#
# generate markdown report with mermaid diagrams from duckdb database
#

source ./scripts/include/bootstrap.sh

if [[ ! -f "./duckdb/loop-duckdb.db" ]]; then
  # add "create and populate duckdb database"  sql arg to duckdb start command if duckdb database does not exist
  DUCKDB_CMD="-init /local/init-loop-duckdb.sql"

  if [[ ! -d "./s3" ]] || ! find ./s3 -type f -name "*.json" -print -quit > /dev/null; then
    echo './s3 directory does not exist or is empty. Please run "pnpm -s download-s3-loop-bucket" to download the loop data from S3.';
    exit 1;
  fi
fi

#
# param $1 the sql query executed in duckdb
# optional param $2 additional duckdb arguments 
#
# usage: query_duckdb "<sql_query>"
#
function query_duckdb() {
  ADDITIONAL_DUCKDB_ARGS="${2:-}"

  docker run \
    -q \
    --rm \
    -v $(pwd)/s3:/local/s3 \
    -v $(pwd)/scripts/init-loop-duckdb.sql:/local/init-loop-duckdb.sql \
    -v $(pwd)/duckdb:/local/duckdb \
    --net host \
    -it \
    --entrypoint /usr/bin/bash \
    datacatering/duckdb:v1.3.2 -c "
      # copy duckdb ui database to it's desired location if it exists
      if [[ -f /local/duckdb/ui.db ]]; then
        mkdir -p /root/.duckdb/extension_data/ui
        cp /local/duckdb/ui.* /root/.duckdb/extension_data/ui/
      fi

      # start duckdb
      /duckdb $DUCKDB_CMD $ADDITIONAL_DUCKDB_ARGS /local/duckdb/loop-duckdb.db <<EQSQL
$1
.quit
EQSQL

      # adjust file permissions of loop-duckdb database
      chmod -R a+rw /local/duckdb
      chown -R 1000:1000 /local/duckdb
    "
}

query_duckdb "
CREATE OR REPLACE VIEW recent_loops AS
SELECT
  file AS recent_loop_file,
  instance
FROM
  (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY
          instance
        ORDER BY
          "timestamp" DESC
      ) AS rn
    FROM
      loop_items
  )
WHERE
  rn = 1;
"

# @TODO : extract RecentPlugins to a macro or view to avoid duplication

most_active_plugins_markdown=$(query_duckdb "
-- [real insight]
-- select latest loop data unique for each customer and accumulate the most active (used) plugins
WITH
  RecentPlugins AS (
    SELECT
      p.plugin.plugin_slug,
      p.instance,
      p.plugin.active
    FROM
      plugins AS p
      JOIN recent_loops AS rl ON p.file = rl.recent_loop_file
  ),
  PluginCounts AS (
    -- Calculate the occurrence count for each plugin
    SELECT
      plugin_slug AS slug,
      COUNT(*) AS occurrence_count
    FROM
      RecentPlugins
    WHERE
      active = true -- OR active = false
    GROUP BY
      slug
  ),
  TotalCount AS (
    -- Calculate the total number of instances from the view
    SELECT
      COUNT(*) AS total_instances -- better : COUNT(DISTINCT instance) AS total_instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pc.slug,
  pc.occurrence_count,
  (pc.occurrence_count * 100.0 / tc.total_instances) AS percentage
FROM
  PluginCounts AS pc,
  TotalCount AS tc
ORDER BY
  pc.occurrence_count DESC
LIMIT 10;
" "-markdown"
)


most_active_plugins_json=$(query_duckdb "
-- [real insight]
-- select latest loop data unique for each customer and accumulate the most active (used) plugins
WITH
    RecentPlugins AS (
    SELECT
      p.plugin.plugin_slug,
      p.instance,
      p.plugin.active
    FROM
      plugins AS p
      JOIN recent_loops AS rl ON p.file = rl.recent_loop_file
  ),
  PluginCounts AS (
    -- Calculate the occurrence count for each plugin
    SELECT
      plugin_slug AS slug,
      COUNT(*) AS occurrence_count
    FROM
      RecentPlugins
    WHERE
      active = true -- OR active = false
    GROUP BY
      slug
  ),
  TotalCount AS (
    -- Calculate the total number of instances
    SELECT
      COUNT(*) AS total_instances -- better : COUNT(DISTINCT instance) AS total_instances
    FROM
      recent_loops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pc.slug,
  pc.occurrence_count,
  (pc.occurrence_count * 100.0 / tc.total_instances) AS percentage
FROM
  PluginCounts AS pc,
  TotalCount AS tc
ORDER BY
  pc.occurrence_count DESC
LIMIT 10;
" "-json"
)

cat <<EOF | tee report.md
---
title: Loop Usage Report
author: IONOS WordPress Hosting Team
date: $(date +%Y-%m-%d)
---

# Most active plugins  

$most_active_plugins_markdown

\`\`\`mermaid
$(echo "$most_active_plugins_json" | jq -r --arg title "Most active plugins" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.slug)\" : \(.occurrence_count)")
')
\`\`\`
EOF
