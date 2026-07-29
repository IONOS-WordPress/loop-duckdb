#!/usr/bin/env bash

source ./scripts/include/bootstrap.sh

if ! command -v s5cmd >/dev/null; then
  echo "s5cmd not found. Install it from https://github.com/peak/s5cmd (or 'go install github.com/peak/s5cmd/v2@latest')."
  exit 1
fi

mkdir -p ./s3

echo "Syncing s3://loop bucket to local directory 's3'..."

# s5cmd runs as the current user, so no permission fixups are needed.
# credentials are taken from the AWS_* variables exported by bootstrap.sh,
# the endpoint from S3_ENDPOINT_URL (s5cmd does not read AWS_ENDPOINT_URL).
AWS_ACCESS_KEY_ID="${aws_access_key_id}" \
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}" \
AWS_REGION="${aws_default_region}" \
S3_ENDPOINT_URL="${aws_endpoint_url}" \
  s5cmd sync 's3://loop/*' ./s3/
