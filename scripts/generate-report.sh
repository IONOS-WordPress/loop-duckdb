#!/usr/bin/env bash

# fail if any following command fails
set -eo pipefail

# make name of this script available in a variable without extension
export readonly REPORT_NAME=$(basename "$0" .sh)

# load the `.env`, `.env.local` and `.secrets` file from path in parameter $1 if `.env`/`.secrets` file exists.
# bash will source the `.env`/`.secrets` and export any variable/functions declared in the file to the caller.
#
# @TODO: if the sourced file is a executable it will be executed and its output will be sourced end exported to the caller script
#
# @param $1 (optional, default is `pwd`) path to current package sub directory
#
function ionos.loop-duckdb.load_env() {
  local path=$(realpath "${1:-$(pwd)}")
  local CURRENT_ALLEXPORT_STATE="$(shopt -po allexport)"
  # enable export all variables bash feature
  set -a
  for file in "$path/"{.env,.secrets,.env.local}; do
    if [[ -f "$file" ]]; then
      # include .env/.secret files into current bash process
      source "$file"
    fi
  done
  # restore the value of allexport option to its original value.
  eval "$CURRENT_ALLEXPORT_STATE" >/dev/null
}
export -f ionos.loop-duckdb.load_env

# load .env/.secrets files
ionos.loop-duckdb.load_env

rm -rf "./${REPORT_NAME}"
mkdir -p "./${REPORT_NAME}"

if [[ ! -d "./s3" ]] || ! find ./s3 -type f -name "*.json" -print -quit > /dev/null; then
  echo './s3 directory does not exist or is empty. Please run "pnpm -s download-s3-loop-bucket" to download the loop data from S3.';
  exit 1;
fi

#
# param $1 the sql query executed in duckdb
# optional param $2 additional duckdb arguments 
#
# usage: exec_duckdb "<sql_query>"
#
function ionos.loop-duckdb.exec_duckdb() {
  OPTIONAL_DUCKDB_ARGS="${2:-}"

  docker run \
    -q \
    --rm \
    -v $(pwd)/s3:/local/s3 \
    -v $(pwd)/${REPORT_NAME}:/local/${REPORT_NAME} \
    --net host \
    -it \
    --entrypoint /usr/bin/bash \
    datacatering/duckdb:v1.3.2 -c "
      # start duckdb
      cd /local

      /duckdb $OPTIONAL_DUCKDB_ARGS ./${REPORT_NAME}/${REPORT_NAME}.db <<EQSQL
$1
.quit
EQSQL

      # adjust file permissions of loop-duckdb database
      chmod -R a+rw /local/${REPORT_NAME}
      chown -R 1000:1000 /local/${REPORT_NAME}
    "
}
export -f ionos.loop-duckdb.exec_duckdb

cat <<EOF | tee ./${REPORT_NAME}/${REPORT_NAME}.md
$(run-parts --regex '^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9]+)?$' ./scripts/${REPORT_NAME}-parts)
EOF
