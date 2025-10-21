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
export -f query_duckdb

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

cat <<EOF | tee report.md
---
title: IONOS Loop Usage Report
author: WordPress Hosting Team
creation date: $(date +'%Y-%m-%d %H:%M')
time period: all time until now
---

$(run-parts --regex '^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9]+)?$' ./scripts/generate-report-parts)
EOF
