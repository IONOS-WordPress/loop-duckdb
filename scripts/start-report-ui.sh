#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

if [[ ! -f "./generate-report/generate-report.db" ]]; then
  pnpm run generate-report
fi

docker run \
  -q \
  --rm \
  -v $(pwd)/generate-report/generate-report.db:/local/generate-report.db \
  --net host \
  -it \
  --entrypoint /usr/bin/bash \
  datacatering/duckdb:v1.3.2 -c "
    # start duckdb
    /duckdb -ui /local/generate-report.db
  "
