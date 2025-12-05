#!/usr/bin/env bash

#
# fire and forget script executing a duckdb command against a in memory duckdb instance
# useful to develop import scripts
#

source ./scripts/include/bootstrap.sh

if [[ ! -f "./one-shot.duckdb.sql" ]]; then
  echo "One-shot SQL file not found - generating one!"
  cat <<EOF > ./one-shot.duckdb.sql
-- enter your sql script here
-- it will be executed immediately when starting the command again in the in memory database
EOF
  exit -1
fi

docker run \
  -q \
  -v $(pwd)/s3:/local/s3 \
  -v $(pwd)/one-shot.duckdb.sql:/local/one-shot.duckdb.sql \
  -v $(pwd)/duckdb:/local/duckdb \
  --net host \
  -it \
  --rm \
  --entrypoint /usr/bin/bash \
  datacatering/duckdb:v1.3.2 -c "
    # start duckdb
    /duckdb -noheader --init /local/one-shot.duckdb.sql
  "
