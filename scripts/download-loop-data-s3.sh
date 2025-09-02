#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

# sync local copy of the s3 bucket with the loop data 
if [[ -d "./s3" ]]; then
  docker run -v $(pwd)/s3:/local --rm library/bash -c "chmod -R a+rw /local && chown -R 1000:1000 /local"
fi

echo "Syncing s3://loop bucket to local directory 's3'..."

# aws-cli runs always as root so we need to ajust permissions before and after the sync
docker run \
  -q \
  --rm \
  -ti \
  -v $(pwd)/s3:/local/s3 \
  -e "AWS_ACCESS_KEY_ID=${aws_access_key_id}" \
  -e "AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}" \
  -e "AWS_DEFAULT_REGION=${aws_default_region}" \
  -e "AWS_ENDPOINT_URL=${aws_endpoint_url}" \
  amazon/aws-cli \
  s3 sync s3://loop /local/s3 --exclude "duckdb/*"

if [[ -d "./s3" ]]; then
  docker run \
    -q \
    -v $(pwd)/s3:/local \
    --rm \
    library/bash \
    -c "chmod -R a+rw /local && chown -R 1000:1000 /local"
fi