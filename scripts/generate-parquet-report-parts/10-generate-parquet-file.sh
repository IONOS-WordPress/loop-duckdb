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
    FROM read_json(
      ARRAY['$LOOP_JSON_FILES'], 
      filename = true, -- Crucial: Ensures the filename is included as a column
      ignore_errors = true,
      columns = {
        version: 'VARCHAR',
        hosting: 'JSON',
        wordpress: 'JSON',
        events: 'JSON',
        clicks: 'JSON',
        plugin_data: 'JSON',
        instance: 'VARCHAR',
        timestamp: 'BIGINT',
      },
      auto_detect=true
    )
  )
  TO './${REPORT_NAME}/${REPORT_NAME}.parquet' (FORMAT PARQUET);
"

