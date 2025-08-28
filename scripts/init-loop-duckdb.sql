-- script to create a duckdb containing all the s3 loop json files in ./s3

-- limit threads to 1 to prevent running in memory limits while importing the json files
SET threads = 1;

-- persist the s3 jason files in duckdb table loop_items
CREATE OR REPLACE TABLE loop_items AS
  SELECT
    *
  FROM (
  SELECT
    -- expose everything provided as json as separate columns except ...
    json_content.* EXCLUDE (filename, timestamp, instance),
    -- map filename to column file
    json_content.filename AS file, -- Use the filename from the subquery
    -- grep file_date from file and store it in a timestamp column
    strptime(
      regexp_extract(json_content.filename, '([0-9]{4}-[0-9]{2}-[0-9]{2})'),
      '%Y-%m-%d'
    ) AS file_date,
    -- (optional) normalize instance (currently nonsense)
    -- @TODO: do we have any other data to get a unique instance id if not set (look at the other json files) ?
    CASE
      WHEN json_extract(json_content, '$.instance') IS NOT NULL
      THEN json_extract(json_content, '$.instance') 
      ELSE NULL
    END AS instance,
    -- map timestamp to column timestamp and take file_date as fallback value
    CASE
      WHEN timestamp IS NOT NULL
      -- to_timestamp(timestamp) will return a TIMESTAMP with timezone, but we want just a TIMESTAMP without timezone
      THEN to_timestamp(timestamp)::TIMESTAMP
      ELSE file_date
    END AS timestamp,
  FROM (
    SELECT
      *
    FROM
      read_json(
        '/local/s3/**/*.json',
        filename = true, -- Crucial: Ensures the filename is included as a column
        ignore_errors = true,
        columns = {
          generic : 'JSON',
          user : 'JSON',
          theme : 'JSON',
          plugin: 'JSON',
          post : 'JSON',
          comment : 'JSON',
          surveys: 'JSON',
          instance : 'VARCHAR',
          timestamp : 'BIGINT',
          event : 'JSON'
        }
      )
  ) AS json_content);

-- populate each plugin of a single json file in a separate row
CREATE OR REPLACE TABLE themes as
SELECT
    * EXCLUDE(theme),
    unnest(json_transform(
      theme,
      '[{
        "id": "VARCHAR",
        "version": "VARCHAR",
        "active": "BOOLEAN",
        "parent_theme_slug": "VARCHAR",
        "auto_update": "BOOLEAN",
        "requires_php": "VARCHAR",
        "requires_wp": "VARCHAR"
      }]'
    )) AS theme
  FROM loop_items;
-- SELECT
--   filename,
--   unnest(json.theme) as theme
-- FROM read_json('/local/s3/*/*.json', ignore_errors=1) 
--   as json

-- populate each plugin of a single json file in a separate row
CREATE OR REPLACE TABLE plugins as
SELECT
    * EXCLUDE(plugin),
    unnest(json_transform(
      plugin,
      '[{
        "plugin_slug": "VARCHAR",
        "version": "VARCHAR",
        "active": "BOOLEAN",
        "auto_update": "BOOLEAN",
        "requires_php": "VARCHAR",
        "requires_wp": "VARCHAR"
      }]'
    )) AS plugin
  FROM loop_items;
-- SELECT
--   filename,
--   unnest(json.plugin) as plugin
-- FROM read_json('/local/s3/*/*.json', ignore_errors=1) 
--   as json

RESET threads;