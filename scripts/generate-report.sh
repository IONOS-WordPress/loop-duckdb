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

# rm -rf "./${REPORT_NAME}"
# mkdir -p "./${REPORT_NAME}"

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

help() {
  # print everything in this script file after the '###help-message' marker
  printf "$(sed -e '1,/^###help-message/d' "$0")\n"
  exit 0
}

# wildcard args for the report parts to execute
POSITIONAL_ARGS=()
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"
PDF="${PDF:-false}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      help
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --pdf)
      PDF=true
      shift
      ;;
    *)
      # convert wildcard arguments to regex patterns
      POSITIONAL_ARGS+=($1)
      shift
      ;;
  esac
done

verbose() {
  [[ "$VERBOSE" =~ true|yes ]] && echo -e "\033[1;30m$1\033[0m" >&2 ||:
}

# create or truncate markdown report file
: > ./${REPORT_NAME}/${REPORT_NAME}.md

for script in "./scripts/${REPORT_NAME}-parts"/*; do
  # If no filters provided, process all scripts
  if [[ ${#POSITIONAL_ARGS[@]} -eq 0 ]]; then
    verbose "$script (no filter, processing all)"
  else
    # Check if the script matches any of the provided filters
    matched=''
    for filter in "${POSITIONAL_ARGS[@]}"; do
      if [[ "$(basename "$script")" == $filter ]]; then
        verbose "$script (filter matched: $filter)"
        matched=true
        break
      fi
    done

    if [[ "$matched" == '' ]]; then
      verbose "skipped $script (no filter matched)"
      continue
    fi
  fi

  # Execute the script if it's executable
  if [[ -x "$script" ]]; then
    if [[ "$DRY_RUN" =~ true|yes ]]; then
      echo "Dry run: $script"
    else
      $script | tee -a ./${REPORT_NAME}/${REPORT_NAME}.md
    fi
  else
    verbose "skipped $script (not executable)"
  fi
done

# format the markdown report using prettier
if [[ ! "$DRY_RUN" =~ true|yes ]]; then
  pnpm exec prettier --write ./${REPORT_NAME}/${REPORT_NAME}.md
  pnpm exec node scripts/report-2-pdf.js ./${REPORT_NAME}/${REPORT_NAME}.md
fi

exit 

###help-message

Usage: generate-report.sh [options] [report-part-wildcards...]

Generates the report by executing the report parts in alphabetical order and compiling them into a markdown file.

Options:
  --verbose           Enable verbose output.
  --dry-run           Show which scripts would be executed without running them.
  --help              Show this help message and exit.

Examples:
  ./generate-report.sh
    Generates the full report including all parts.

  ./generate-report.sh 030* 050* *nba* 140-security-settings
    Generates the report including only the parts that match the specified wildcards.

  ./generate-report.sh --pdf
    Generate the report and convert it to PDF format.

  ./generate-report.sh --pdf xxx
    Generate the report and convert it to PDF format without executing any report parts.

  ./generate-report.sh --verbose
    Enable verbose output (displaying which files are being processed).

  ./generate-report.sh --dry-run
    Show which scripts would be executed without running them.

  ./generate-report.sh --help
    Show this help message and exit.
