# fail if any following command fails
set -eo pipefail

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

# verify all enviroinment variables properly configured
declare -a required_aws_env_vars=(
  "aws_access_key_id" 
  "aws_secret_access_key" 
  "aws_default_region" 
  "aws_endpoint_url"
)
for required_aws_env_var in "${required_aws_env_vars[@]}"; do
  if ! printenv "$required_aws_env_var" > /dev/null; then
   echo "Environment variable '$required_aws_env_var' not defined or empty."
   exit -1
  fi
done

mkdir -p ./duckdb