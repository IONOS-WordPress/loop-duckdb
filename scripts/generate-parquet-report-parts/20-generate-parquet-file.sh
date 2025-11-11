#!/usr/bin/env bash

#
# create/overwrite parquet file from json files in ./s3 directory
#

# gather matching (containing '{"version":"1.0"') loop files in the format "file1.json, file2.json, file3.json"
LOOP_JSON_FILES=$(find ./s3 -type f -name '*.json' | xargs grep -l '{"version":"1.0"' | sed ':a;N;$!ba;s/\n/\x27,\x27/g;s/\x27,\x27$//')

[[ -z "$LOOP_JSON_FILES" ]] && {
    echo "No matching LOOP JSON files found."
    exit 1
}

ionos.loop-duckdb.exec_duckdb "
  -- create parquet file from loop json files
  ATTACH ':memory:' AS in_memory;
  COPY (
    SELECT 
      filename, 
      * EXCLUDE (timestamp),
      to_timestamp(timestamp) AS timestamp -- timestamp was a bigint, convert to timestamp type
    FROM read_json(['$LOOP_JSON_FILES'], auto_detect=true)
  )
  TO './${REPORT_NAME}/${REPORT_NAME}.parquet' (FORMAT PARQUET);
"

min_max=$(ionos.loop-duckdb.exec_duckdb "
  SELECT 
    STRFTIME(MIN(timestamp), '%Y-%m-%d %H:%M:%S') AS min, 
    STRFTIME(MAX(timestamp), '%Y-%m-%d %H:%M:%S') AS max 
  FROM './${REPORT_NAME}/${REPORT_NAME}.parquet';
" '-json')

cat <<EOF 
---
title: IONOS Loop Usage Report
author: WordPress Hosting Team
creation date: $(date +'%Y-%m-%d %H:%M')
time period: $(jq -r '.[0] | "\(.min) - \(.max)"' <<< "$min_max")
---
EOF