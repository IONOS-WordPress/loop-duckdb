#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

if [[ -f './duckdb/loop-duckdb.db' ]]; then
  echo "DuckDB database already exists locally. Do you really want to overwrite it? (y/n)"
  
  read -r confirmation
  if [[ "$confirmation" == "y" ]]; then
    find ./duckdb -type f ! -name 'README.md' -delete
    echo "Existing DuckDB database files deleted."
  else 
    echo "Exiting without downloading DuckDB database."
    exit 0
  fi
fi

# aws-cli runs always as root so we need to ajust permissions before and after the sync
docker run \
  -q \
  --rm \
  -ti \
  -v $(pwd)/duckdb:/local/duckdb \
  -e "AWS_ACCESS_KEY_ID=${aws_access_key_id}" \
  -e "AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}" \
  -e "AWS_DEFAULT_REGION=${aws_default_region}" \
  -e "AWS_ENDPOINT_URL=${aws_endpoint_url}" \
  -e "AWS_REQUEST_CHECKSUM_CALCULATION=when_required" \
  -e "AWS_RESPONSE_CHECKSUM_VALIDATION=when_required" \
  amazon/aws-cli \
  s3 sync s3://loop/duckdb /local/duckdb --exclude "README.md" --exclude "duckdb/ui*" --exclude "duckdb/notebooks/*"

if [[ -d "./duckdb" ]]; then
  docker run \
    -q \
    -v $(pwd)/duckdb:/local \
    --rm \
    library/bash \
    -c "chmod -R a+rw /local && chown -R 1000:1000 /local"
fi