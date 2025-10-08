#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

if [[ ! -d './duckdb/ui' ]]; then
  cat <<EOF
Cannot import notebooks : exported DuckDB ui notebooks (folder ./duckdb/ui) does not exist.
EOF

  exit 1
fi

if [[ -f './duckdb/ui.db' ]]; then
  echo "DuckDB ui database already exists locally. Do you really want to overwrite it? (y/n)"
  
  read -r confirmation
  if [[ "$confirmation" == "y" ]]; then
    rm -rf ./duckdb/ui.*
    echo "Existing DuckDB ui database files deleted."
  else 
    echo "Exiting without importing DuckDB ui notebooks."
    exit 0
  fi
fi

docker run \
  -q \
  --rm \
  -v $(pwd)/scripts/init-loop-duckdb.sql:/local/init-loop-duckdb.sql \
  -v $(pwd)/duckdb:/local/duckdb \
  -ti \
  --net host \
  --entrypoint /usr/bin/bash \
  datacatering/duckdb:v1.3.2 -c "
    /duckdb /local/duckdb/ui.db <<-EOSQL
import database '/local/duckdb/ui';
.quit
EOSQL

    # adjust file permissions of loop-duckdb database
    chmod -R a+rw /local/duckdb/ui.*
    chown -R 1000:1000 /local/duckdb/ui.*
  "

echo "DuckDB ui notebooks imported successfully."