#!/usr/bin/env bash

#
# create/overwrite parquet file from json files in ./s3 directory
#

ionos.loop-duckdb.exec_duckdb "
  -- limit threads to 1 to prevent running in memory limits while importing the json files
  SET threads = 1;

  -- disable progress bar to prevent the progress output from being included in the report
  SET enable_progress_bar = false;

  -- create parquet file from loop json files
  ATTACH ':memory:' AS in_memory;
  COPY (
    SELECT 
      filename, 
      * EXCLUDE (timestamp),
      to_timestamp(timestamp) AS timestamp -- timestamp was a bigint, convert to timestamp type
    FROM read_json_auto(
      './s3/2026-01-1*/*.json', 
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
      }
    ) 
    WHERE
      version = '1.0'
  )
  TO './${REPORT_NAME}/${REPORT_NAME}.parquet' (FORMAT PARQUET, OVERWRITE TRUE);
"

