#!/usr/bin/env bash

#
# define recent_loops in database
#

ionos.loop-duckdb.exec_duckdb "
-- disable progress bar to prevent the progress output from being included in the report
SET enable_progress_bar = false;

-- table with all loop items
CREATE OR REPLACE TABLE loop_items AS
  SELECT
    *
  FROM
    './${REPORT_NAME}/${REPORT_NAME}.parquet';

-- table with unnest active plugins
CREATE OR REPLACE TABLE plugins as
  SELECT
    timestamp,
    instance,
    filename,
    unnest(json_transform(
      wordpress->'active_plugins',
      '[{
        \"plugin_slug\": \"VARCHAR\",
        \"version\": \"VARCHAR\",
        \"auto_update\": \"BOOLEAN\"
      }]'
    )) AS plugin
  FROM
    loop_items;

-- table with unnest active theme
CREATE OR REPLACE TABLE themes as
  SELECT
    timestamp,
    instance,
    filename,
    json_transform(
      wordpress->'active_theme',
      '{
        \"id\": \"VARCHAR\",
        \"version\": \"VARCHAR\",
        \"parent_theme_slug\": \"VARCHAR\",
        \"auto_update\": \"BOOLEAN\"
      }'
    ) AS theme
  FROM
    loop_items;

-- table with unnest events
CREATE OR REPLACE TABLE events as
  SELECT
    timestamp,
    instance,
    filename,
    unnest(json_transform(
      loop_items.events,
      '[{
        \"name\": \"VARCHAR\",
        \"payload\": \"JSON\",
        \"timestamp\": \"BIGINT\"
      }]'
    )) AS event
  FROM
    loop_items;

-- view with most recent loop item per instance
CREATE OR REPLACE VIEW recent_loops AS
  SELECT
    filename,
    instance,
    timestamp
  FROM
    (
      SELECT
        *,
        ROW_NUMBER() OVER (
          PARTITION BY
            instance
          ORDER BY
            "timestamp" DESC
        ) AS rn
      FROM loop_items
    )
  WHERE
    rn = 1;
"
