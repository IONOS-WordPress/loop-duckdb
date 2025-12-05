# .htaccess usage evaluation

Paste this snippet into the report ui duckdb notebook and enable one of the queries at the bottom

```sql
WITH
  customers_having_property_htaccess_md5 AS (
    -- latest loop dataset per unique customer having the 'htaccess_md5' property in 'hosting'
    SELECT
      *
    FROM
      (
        SELECT
          *,
          -- Assign a rank to each row within groups defined by 'instance'.
          ROW_NUMBER() OVER (
            PARTITION BY
              instance
            ORDER BY
              "timestamp" DESC
          ) as rn
        FROM
          loop_items
        WHERE
          -- 1. Ensure the top-level 'hosting' column is a JSON object
          JSON_TYPE(hosting) = 'OBJECT'
          AND
          -- 2. Ensure the nested 'htaccess_md5' property is also a JSON object
          JSON_TYPE(hosting -> 'htaccess_md5') = 'OBJECT'
      ) AS subquery
    WHERE
      -- Select only the latest row for each 'instance' (where the rank is 1).
      rn = 1
  ),
  customers_with_non_empty_htaccess_md5_property AS (
    -- latest loop dataset per unique customer having at least a single .htaccess file in htaccess_md5
    SELECT
      *
    FROM
      customers_having_property_htaccess_md5
    WHERE
      -- We check if the array of keys is NOT empty.
      JSON_KEYS(hosting -> 'htaccess_md5') IS NOT NULL
      AND JSON_ARRAY_LENGTH(JSON_KEYS(hosting -> 'htaccess_md5')) > 0
  ),
  flatten_htaccess_md5 as (
    -- flattened perpective : each htaccess file has it's own row
    SELECT
      t.key AS htaccess_file_path,
      -- Use the '->' operator for dynamic path extraction (t.key is not a constant)
      (hosting -> '$.htaccess_md5') ->> t.key AS md5_hash
    FROM
      customers_with_non_empty_htaccess_md5_property,
      -- Unnest the keys of the nested htaccess_md5 object
      UNNEST(JSON_KEYS(hosting -> '$.htaccess_md5')) AS t(key)
    order by
      htaccess_file_path
  ), 
  unique_htaccess_files AS (
    -- unique htaccess files (same path and checksum) including their usage count 
    SELECT
        htaccess_file_path,
        md5_hash,
        COUNT(*) AS frequency
    FROM
        flatten_htaccess_md5
    GROUP BY
        htaccess_file_path,
        md5_hash
    ORDER BY
      frequency DESC,
      htaccess_file_path ASC
  ),
  unique_htaccess_filepaths as (
    -- unique htaccess file paths including their usage count ignoring different checksums
    SELECT
      htaccess_file_path,
      SUM(frequency) AS accumulated_frequency
    FROM
        unique_htaccess_files
    GROUP BY
        htaccess_file_path
    ORDER BY
        accumulated_frequency DESC
  )

  -- query general .htaccess file usage
  SELECT
    -- count of unique customers have the htaccess_md5 feature 
    (SELECT COUNT(*) FROM customers_having_property_htaccess_md5) as customers_having_property_htaccess_md5,
    -- count of unique customers having at least a single .htaccess file
    (SELECT COUNT(*) FROM customers_with_non_empty_htaccess_md5_property) as customers_with_non_empty_htaccess_md5_property,

  -- query all .htaccess file paths and their usage (ignoring different contents)
  -- SELECT * FROM unique_htaccess_filepaths -- LIMIT 5

  -- query all .htaccess file paths (with the same contents) and their usage 
  -- SELECT * FROM unique_htaccess_files -- LIMIT 5
;
```
