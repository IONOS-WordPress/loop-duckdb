# list files (requires s3 loop data to be downloaded)

```sql
-- list all json files in local/s3 recursive
select * from glob('/local/s3/**/*.json')
```

```sql
-- list all json files in local/s3
select * from glob('/local/s3/*/*.json')
```

```sql
-- list /local
select * from glob('/local/*/')
```

```sql
-- list all loop directories by day
select * from glob('/local/*/*/')
```

> duckdb provides functions to filter the returned filenames, count theirs contents and much more.

# query a superset of the json loop files (requires s3 loop data to be downloaded)

```sql
-- only import json files in `s3/2023-11-14`
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
FROM read_json('/local/2023-11-14/*.json', ignore_errors=1);
```

See https://duckdbsnippets.com/snippets/2/using-the-exclude-function-in-duckdb for more.

# Links

https://www.seachess.net/notes/handling-json-with-duckdb/

https://www.confessionsofadataguy.com/using-duckdb-to-read-json-files-in-s3/

https://nishtahir.com/notes-on-the-duckdb-ui/

https://www.seachess.net/notes/handling-json-with-duckdb/

https://www.confessionsofadataguy.com/using-duckdb-to-read-json-files-in-s3/

https://nishtahir.com/notes-on-the-duckdb-ui/

https://duckdb.org/docs/stable/sql/dialect/friendly_sql.html

https://duckdb.org/docs/stable/sql/statements/pivot.html

https://duckdb.org/2024/11/29/duckdb-tricks-part-3.html#excluding-columns-from-a-table

