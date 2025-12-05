#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

if [[ ! -f "./duckdb/loop-duckdb.db" ]]; then
  # add "create and populate duckdb database"  sql arg to duckdb start command if duckdb database does not exist
  DUCKDB_CMD="-init /local/init-loop-duckdb.sql"

  if [[ ! -d "./s3" ]] || ! find ./s3 -type f -name "*.json" -print -quit > /dev/null; then
    echo './s3 directory does not exist or is empty. Please run "pnpm -s download-s3-loop-bucket" to download the loop data from S3.';
    exit 1;
  fi
fi

if [[ ! -f './duckdb/ui.db' ]]; then
  echo "DuckDB ui database does not exist locally. Will import them automatically."
  pnpm run import-duckdb-notebooks
else
  echo "DuckDB ui database already exists locally."
fi

# preserve checksums of duckdb database files
declare -A database_file_checksums
for file in $(find ./duckdb -type f ! -name 'README.md'); do
  database_file_checksums["$file"]=$(sha256sum "$file")
done

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
    /duckdb -ui $DUCKDB_CMD /local/duckdb/loop-duckdb.db

    # persist duckdb ui database if exists
    if [[ -f /root/.duckdb/extension_data/ui/ui.db ]]; then
      cp -r /root/.duckdb/extension_data/ui/* /local/duckdb/
    fi

    # adjust file permissions of loop-duckdb database
    chmod -R a+rw /local/duckdb
    chown -R 1000:1000 /local/duckdb
  "

# check if some database files have changed since last run
declare database_files_changed=()
for file in $(find ./duckdb -type f ! -name 'README.md'); do
  if [[ -z "${database_file_checksums["$file"]}" ]]; then
    database_files_changed+=("$file")
  elif [[ "${database_file_checksums["$file"]}" != "$(sha256sum "$file")" ]]; then
    database_files_changed+=("$file")
  fi
done

if [[ -n "${database_files_changed[@]}" ]]; then
  echo "The following database files have changed: ${database_files_changed[*]}"
  echo "You can upload the duckdb database to S3 with 'pnpm -s upload-duckdb-s3'."
else
  echo "No changes detected in the duckdb database files."
fi
