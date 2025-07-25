-- script to create a duckdb containing all the s3 loop json files in ./s3

-- limit threads to 1 to prevent running in memory limits while importing the json files
SET threads = 1;

-- persist the s3 jason files in duckdb table loop_items
CREATE OR REPLACE TABLE loop_items AS
SELECT filename, * FROM read_json_auto('/local/s3/**/*.json', ignore_errors=true);

RESET threads;