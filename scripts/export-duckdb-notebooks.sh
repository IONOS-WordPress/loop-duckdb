#!/usr/bin/env bash

#
# export notebooks to sql files 
# 

source ./scripts/include/bootstrap.sh

if [[ ! -f './duckdb/ui.db' ]]; then
  cat <<EOF
Cannot export notebooks : DuckDB ui database (./duckdb/ui.db) does not exist.

You have 2 options to get a ui database:

- Start the Loop application once which will create a fresh empty ui database, then stop it again using Ctrl-C

  pnpm start

- Download the existing ui database from S3 using the command: 

  pnpm run download-duckdb-s3

EOF

  exit 1
fi

# #
# # param $1 the sql query executed in duckdb ui
# # optional param $2 additional duckdb arguments 
# #
# # usage: query_duckdb_ui "<sql_query>"
# #
# function query_duckdb_ui() {
#   DUCKDB_ARGS="${2:-}"
#   docker run \
#     -q \
#     --rm \
#     -v $(pwd)/scripts/init-loop-duckdb.sql:/local/init-loop-duckdb.sql \
#     -v $(pwd)/duckdb:/local/duckdb \
#     --net host \
#     --entrypoint /usr/bin/bash \
#     datacatering/duckdb:v1.3.2 -c "
#       /duckdb -readonly /local/duckdb/ui.db $DUCKDB_ARGS <<EOSQL
# $1
# EOSQL
#     "
# }

# query_duckdb_ui 'SELECT * FROM notebooks' '-json' | jq -r '.[].id' | while read notebook_id; do
#   echo "Exporting notebook: $notebook_id"
#   # jq '.[].json' <(query_duckdb_ui "SELECT * FROM notebook_versions WHERE notebook_id ='$notebook_id' AND expires IS NULL;" '-json' | jq -r '.')
#   notebook_name=$(jq -r '.[].title' <(query_duckdb_ui "SELECT title FROM notebook_versions WHERE notebook_id ='$notebook_id' AND expires IS NULL;" '-json'))
#   echo "Notebook name: $notebook_name"
#   # jq -r '.[].title' <(query_duckdb_ui "SELECT title FROM notebook_versions WHERE notebook_id ='$notebook_id' AND expires IS NULL;" '-json' | jq -r '.')
#   notebook_cells=$(jq -r '.[].json' <(query_duckdb_ui "SELECT json FROM notebook_versions WHERE notebook_id ='$notebook_id' AND expires IS NULL;" '-json'))
#   echo "$notebook_cells" | jq .
# done

docker run \
  -q \
  --rm \
  -v $(pwd)/scripts/init-loop-duckdb.sql:/local/init-loop-duckdb.sql \
  -v $(pwd)/duckdb:/local/duckdb \
  -ti \
  --net host \
  --entrypoint /usr/bin/bash \
  datacatering/duckdb:v1.3.2 -c "
    # start duckdb
    /duckdb -readonly /local/duckdb/ui.db <<-EOSQL
export database '/local/duckdb/ui' (format 'json');
.quit
EOSQL

    # adjust file permissions of loop-duckdb database
    chmod -R a+rw /local/duckdb/ui
    chown -R 1000:1000 /local/duckdb/ui
  "