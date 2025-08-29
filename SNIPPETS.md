# list files (requires s3 loop data to be downloaded)

```sql
-- list all json files in local/s3 recursive
select * from glob('/local/s3/**/*.json')
```


```sql
-- list /local contents
select * from glob('/local/*/')
```

```sql
-- list all loop directories by day
select * from glob('/local/*/*/')
```

> duckdb provides functions to filter the returned filenames, count theirs contents and much more.

# query a superset of the json loop files (requires s3 loop data to be downloaded)

```sql
-- only query json files in `s3/2023-11-14`
SELECT * FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

> `ignore_errors=1` is needed since the json files share not the same schema. You can try it out without this option to see what happens.

# query a superset of the json loop files and have the filename available as additional column 

```sql
SELECT filename, * FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

the filename can be used in further queries to limit data to ... let's say only year 2024

# query only a some of the pieces of the loop json data superset (requires s3 loop data to be downloaded)

```sql
SELECT 
    json->'generic'->>'locale' AS locale,
    json->'generic'->>'core_version' AS core_version,
    json->'user'->>'total_users' AS total_users
FROM 
    read_json('/local/s3/2023-11-14/*.json', ignore_errors=1) as json;
```

you can even persist the query into a table by prepending a `CREATE [OR REPLACE] TABLE` statement before the query.

```sql
CREATE OR REPLACE TABLE generic_data AS
SELECT 
    json->'generic'->>'locale' AS locale,
    json->'generic'->>'core_version' AS core_version,
    json->'user'->>'total_users' AS total_users
FROM 
    read_json('/local/s3/2023-11-14/*.json', ignore_errors=1) as json;
```

# query loop json data superset and unnest the theme json array items to multiple rows (requires s3 loop data to be downloaded)

[Unnesting](https://duckdb.org/docs/stable/sql/query_syntax/unnest) is a powerful feature to 

See also https://duckdb.org/docs/stable/sql/query_syntax/unnest#unnesting-structs

```sql
SELECT *, unnest(theme) as _theme
FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

> see the difference between the original `theme` array column and the unnested `_theme` column

Here is another example unnesting all themes, plugins and posts for further investigation

```sql
SELECT 
  generic, 
  user, 
  unnest(theme) as theme, 
  unnest(plugin) as plugins, 
  unnest(post) as posts,
  surveys,
  comment
FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

You can even unnest json properties recursively (example is a bit useless but interesting) : 

```sql
SELECT 
  generic, 
  user, 
  unnest(theme) as theme, 
  unnest(plugin, recursive := true) as plugins, 
  unnest(post) as posts,
  surveys,
  comment
FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

# select everything `EXCEPT` some json properties from json loop data superset (requires s3 loop data to be downloaded)

Using `EXCEPT` in the select clause you can suppress some colums. 

Using this syntax is much shorter than enumerate every json property you want.

```sql
SELECT
  * EXCLUDE (theme, plugin, post),
  unnest(theme) as theme, 
  unnest(plugin) as plugins, 
  unnest(post) as posts,
FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1);
```

See https://duckdbsnippets.com/snippets/2/using-the-exclude-function-in-duckdb for more.

# select plugins and theme array items as separate columns from json loop data superset (requires s3 loop data to be downloaded)

```sql
-- requires downloaded s3 loop json files 
-- populate each plugin and theme of a single json file in a separate row
SELECT
  filename,
  json.generic as generic, 
  unnest(json.plugin) as plugin,
  unnest(json.theme) as theme,
FROM read_json('/local/s3/2023-11-14/*.json', ignore_errors=1) 
  as json
```

# list of all unique plugin_slugs

```sql
-- list of all unique plugins
select distinct plugin.plugin_slug as plugin_slug from plugins;
```

# how often occured a plugin_slug in loop_data

```sql
-- get occurrence of each plugin   
SELECT 
  plugin.plugin_slug as plugin_slug,
  COUNT(*) AS occurrence_count
FROM 
  plugins
GROUP BY 
  plugin_slug;
```

# top most used plugins (except our own plugins)

```sql
-- get (only non ionos) plugin installations by occurence
-- see duckdb-ui sidebar on the right and drill in to sse results
SELECT 
  plugin.plugin_slug as plugin_slug
FROM 
  plugins
WHERE 
  plugin_slug NOT LIKE '%ionos%'
```  

# improved version of 'top most used plugins (except our own plugins)'

```sql
-- get (only non ionos) plugin installations by occurence
-- see duckdb-ui sidebar on the right and drill in to sse results
SELECT
  plugin.plugin_slug as slug,
  COUNT(*) OVER (PARTITION BY slug) AS occurrences
FROM plugins
WHERE 
  slug NOT LIKE '%ionos%'
ORDER BY
  occurrences DESC
;
```

# get top most used themes 

```
-- get (only non ionos) plugin installations by occurence
-- see duckdb-ui sidebar on the right and drill in to sse results
SELECT
  theme.id as slug,
  COUNT(*) OVER (PARTITION BY slug) AS occurrences
FROM themes
ORDER BY
  occurrences DESC
;
```

# get top most used **KNOWN* themes  

```sql
-- get theme installations by occurence
-- see duckdb-ui sidebar on the right and drill in to sse results
SELECT
  theme.id as slug,
  theme.active as active
FROM themes
WHERE
  active=true
  and (slug LIKE '%elementor%' or slug LIKE '%divi%' or slug LIKE '%block%')
  and slug NOT ILIKE '%child%'
;
```

# select all loop items for a single instance 

```sql
-- select all loop items for a single instance 
SELECT
  *
FROM
  loop_items
WHERE
--  file = '/local/s3/2025-08-28/0eaae944-4a57-4236-b76e-cbb20e068ca2.json'
 instance LIKE '7cdbe7d2d8306623c02dd6d35206acd6c49fca4fca82c9d82e7ea4ead52d7032'
;
```

# select all loop items for a single loop json file

```sql
-- select all loop items for a single loop json file
SELECT
  plugin.plugin_slug AS slug,
  COUNT(*) AS occurrence_count
FROM
  plugins
WHERE
  file like '/local/s3/2025-08-28/%'
GROUP BY
  slug
ORDER BY
  occurrence_count DESC
;
```

# select latest loop data unique for each customer and accumulate the installed plugins


```sql
-- 
-- select latest loop data unique for each customer and accumulate the installed plugins
--
WITH RecentLoops AS (
  SELECT
    file AS recent_loop_file
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY instance ORDER BY "timestamp" DESC) as rn
    FROM
      loop_items
  )
  WHERE rn = 1
)
SELECT
  p.plugin.plugin_slug,
  p.instance
FROM
  plugins AS p
JOIN
  RecentLoops AS rl
ON
  p.file = rl.recent_loop_file;
```

# select latest loop data unique for each customer and accumulate the most active (used) plugins

```sql
-- 
-- select latest loop data unique for each customer and accumulate the most active (used) plugins
--
WITH
  RecentLoops AS (
    SELECT
      file AS recent_loop_file
    FROM
      (
        SELECT
          *,
          ROW_NUMBER() OVER (
            PARTITION BY
              instance
            ORDER BY
              "timestamp" DESC
          ) as rn
        FROM
          loop_items
      )
    WHERE
      rn = 1
  ),
  RecentPlugins AS (
    SELECT
      p.plugin.plugin_slug,
      p.instance,
      p.plugin.active
    FROM
      plugins AS p
      JOIN RecentLoops AS rl ON p.file = rl.recent_loop_file
  ),
  PluginCounts AS (
    -- Calculate the occurrence count for each plugin
    SELECT
      plugin_slug AS slug,
      COUNT(*) AS occurrence_count
    FROM
      RecentPlugins
    WHERE
      active = true -- OR active = false
    GROUP BY
      slug
  ),
  TotalCount AS (
    -- Calculate the total number of instances
    SELECT
      COUNT(*) AS total_instances
    FROM
      RecentLoops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pc.slug,
  pc.occurrence_count,
  (pc.occurrence_count * 100.0 / tc.total_instances) AS percentage
FROM
  PluginCounts AS pc,
  TotalCount AS tc
ORDER BY
  pc.occurrence_count DESC;
```

# select latest loop data unique for each customer and accumulate the most active (used) themes

```sql
-- 
-- select latest loop data unique for each customer and accumulate the most active (used) themes
--
WITH
  RecentLoops AS (
    SELECT
      file AS recent_loop_file
    FROM
      (
        SELECT
          *,
          ROW_NUMBER() OVER (
            PARTITION BY
              instance
            ORDER BY
              "timestamp" DESC
          ) as rn
        FROM
          loop_items
--        WHERE
--          plugin like '%"elementor"%'
      )
    WHERE
      rn = 1
  ),
  RecentThemes AS (
    SELECT
      t.theme.id,
      t.instance,
      t.theme.active
    FROM
      themes AS t
      JOIN RecentLoops AS rl ON t.file = rl.recent_loop_file
  ),
  ThemeCounts AS (
    -- Calculate the occurrence count for each theme
    SELECT
      id as slug,
      COUNT(*) AS occurrence_count
    FROM
      RecentThemes
    WHERE
      active = true -- OR active = false
    GROUP BY
      slug
  ),
  TotalCount AS (
    -- Calculate the total number of instances
    SELECT
      COUNT(*) AS total_instances
    FROM
      RecentLoops
  )
  -- Select the slug, its count, and the percentage of the total
SELECT
  pc.slug,
  pc.occurrence_count,
  (pc.occurrence_count * 100.0 / tc.total_instances) AS percentage
FROM
  ThemeCounts AS pc,
  TotalCount AS tc
ORDER BY
  pc.occurrence_count DESC;
```

# Links

https://rmoff.net/2025/03/14/kicking-the-tyres-on-the-new-duckdb-ui/

https://www.seachess.net/notes/handling-json-with-duckdb/

https://www.confessionsofadataguy.com/using-duckdb-to-read-json-files-in-s3/

https://nishtahir.com/notes-on-the-duckdb-ui/

https://www.seachess.net/notes/handling-json-with-duckdb/

https://www.confessionsofadataguy.com/using-duckdb-to-read-json-files-in-s3/

https://nishtahir.com/notes-on-the-duckdb-ui/

https://duckdb.org/docs/stable/sql/dialect/friendly_sql.html

https://duckdb.org/docs/stable/sql/statements/pivot.html

https://duckdb.org/2024/11/29/duckdb-tricks-part-3.html#excluding-columns-from-a-table

