#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

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
  s3 sync /local/duckdb s3://loop/duckdb --exclude "README.md" 

