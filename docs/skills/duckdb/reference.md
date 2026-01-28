# DuckDB Reference

This document provides references to DuckDB documentation and key SQL syntax used in the loop-duckdb project.

## Official Documentation

- **DuckDB Homepage**: https://duckdb.org
- **Documentation**: https://duckdb.org/docs/
- **SQL Reference**: https://duckdb.org/docs/sql/introduction

## Core SQL Syntax

### Data Definition Language (DDL)

- [CREATE TABLE](https://duckdb.org/docs/sql/statements/create_table) - Create tables
- [CREATE VIEW](https://duckdb.org/docs/sql/statements/create_view) - Create views
- [CREATE OR REPLACE](https://duckdb.org/docs/sql/statements/create_table#create-or-replace) - Idempotent table/view creation

### Data Query Language (DQL)

- [SELECT](https://duckdb.org/docs/sql/query_syntax/select) - Query data
- [FROM](https://duckdb.org/docs/sql/query_syntax/from) - Specify data sources
- [WHERE](https://duckdb.org/docs/sql/query_syntax/where) - Filter rows
- [GROUP BY](https://duckdb.org/docs/sql/query_syntax/groupby) - Aggregate data
- [ORDER BY](https://duckdb.org/docs/sql/query_syntax/orderby) - Sort results
- [LIMIT](https://duckdb.org/docs/sql/query_syntax/limit) - Limit result rows

### Common Table Expressions (CTEs)

- [WITH Clause](https://duckdb.org/docs/sql/query_syntax/with) - Define temporary named result sets

## JSON Functions

DuckDB provides comprehensive JSON support:

### JSON Operators

- [JSON Operators](https://duckdb.org/docs/extensions/json#json-extraction-functions) - `->` and `->>`
  - `->` returns JSON
  - `->>` returns text

### JSON Functions

- [json_transform()](https://duckdb.org/docs/extensions/json#transforming-json) - Convert JSON to structured types
- [json_extract_string()](https://duckdb.org/docs/extensions/json#json-extraction-functions) - Extract string values
- [json_keys()](https://duckdb.org/docs/extensions/json#json-extraction-functions) - Get object keys

**Documentation**: https://duckdb.org/docs/extensions/json

## Array Functions

- [unnest()](https://duckdb.org/docs/sql/functions/nested#unnesting) - Expand arrays into rows
- [Array Functions Overview](https://duckdb.org/docs/sql/functions/nested)

## Window Functions

Window functions perform calculations across rows related to the current row:

- [Window Functions Overview](https://duckdb.org/docs/sql/window_functions)
- [ROW_NUMBER()](https://duckdb.org/docs/sql/window_functions#row_number) - Assign sequential numbers
- [PARTITION BY](https://duckdb.org/docs/sql/window_functions#partition-by-clause) - Divide result set
- [ORDER BY (in windows)](https://duckdb.org/docs/sql/window_functions#order-by-clause) - Order within partitions

## Aggregate Functions

- [COUNT()](https://duckdb.org/docs/sql/functions/aggregates#count) - Count rows
- [SUM()](https://duckdb.org/docs/sql/functions/aggregates#sum) - Sum values
- [AVG()](https://duckdb.org/docs/sql/functions/aggregates#avg) - Calculate average
- [MIN()/MAX()](https://duckdb.org/docs/sql/functions/aggregates#min-max) - Find min/max values
- [ROUND()](https://duckdb.org/docs/sql/functions/numeric#round) - Round numeric values
- [bool_or()](https://duckdb.org/docs/sql/functions/aggregates#bool_or-bool_and) - Boolean OR aggregation
- [Aggregate Functions Overview](https://duckdb.org/docs/sql/functions/aggregates)

## Conditional Expressions

- [CASE](https://duckdb.org/docs/sql/expressions/case) - Conditional logic
- [COALESCE()](https://duckdb.org/docs/sql/expressions/case#coalesce) - Return first non-null value

## Type Casting

- [CAST()](https://duckdb.org/docs/sql/expressions/cast) - Convert between types
- [Type Casting with `::`](https://duckdb.org/docs/sql/expressions/cast#casting-to-numeric-types) - Postgres-style casting
- [Data Types](https://duckdb.org/docs/sql/data_types/overview) - Available data types

## File Formats

### Parquet

DuckDB has native Parquet support:

- [Parquet Files](https://duckdb.org/docs/data/parquet/overview) - Read/write Parquet
- [Querying Parquet](https://duckdb.org/docs/data/parquet/overview#reading-parquet-files) - Direct queries on files

### CSV

- [CSV Files](https://duckdb.org/docs/data/csv/overview) - Read/write CSV

## Date and Time

- [Date/Time Functions](https://duckdb.org/docs/sql/functions/date) - Date/time operations
- [INTERVAL](https://duckdb.org/docs/sql/data_types/interval) - Time intervals
- [current_timestamp](https://duckdb.org/docs/sql/functions/date#current_timestamp) - Current timestamp

Example:
```sql
WHERE timestamp >= current_timestamp - INTERVAL 7 DAY
```

## String Functions

- [String Functions](https://duckdb.org/docs/sql/functions/char) - String operations
- [LIKE](https://duckdb.org/docs/sql/functions/patternmatching#like) - Pattern matching
- [String Operators](https://duckdb.org/docs/sql/functions/char#string-operators) - Concatenation, etc.

## JOINs

- [JOIN Types](https://duckdb.org/docs/sql/query_syntax/from#joins) - INNER, LEFT, RIGHT, FULL
- [JOIN Syntax](https://duckdb.org/docs/sql/query_syntax/from#join-types)

## Performance and Optimization

### Indexes

- [Indexes](https://duckdb.org/docs/sql/indexes) - Create and use indexes

### Query Profiling

- [EXPLAIN](https://duckdb.org/docs/dev/profiling) - Query execution plans
- [EXPLAIN ANALYZE](https://duckdb.org/docs/dev/profiling#explain-analyze) - Actual execution statistics

### Best Practices

- [Performance Guide](https://duckdb.org/docs/guides/performance/overview) - Optimization tips
- [Import Data](https://duckdb.org/docs/data/overview) - Efficient data loading

## Extensions

DuckDB supports various extensions:

- [JSON Extension](https://duckdb.org/docs/extensions/json) - JSON processing
- [Parquet Extension](https://duckdb.org/docs/extensions/parquet) - Parquet file support (built-in)
- [All Extensions](https://duckdb.org/docs/extensions/overview) - Complete list

## MCP Server Integration

For using DuckDB with Model Context Protocol:

- **mcp-server-duckdb**: Python-based MCP server for DuckDB
- **Installation**: `uvx mcp-server-duckdb` (automatically installed when using the MCP server)
- **Documentation**: See MCP server documentation for API details

> **Prerequisites**: The database must exist before the MCP server can query it. Generate the database by running:
> ```bash
> pnpm generate-report
> ```

### MCP Server Usage

The MCP server provides a `query` tool that executes SQL queries:

```json
{
  "tool": "query",
  "parameters": {
    "query": "SELECT * FROM loop_items LIMIT 10"
  }
}
```

Configuration in `.mcp.json`:
```json
{
  "mcpServers": {
    "duckdb": {
      "command": "uvx",
      "args": [
        "mcp-server-duckdb",
        "--db-path",
        "generate-report/generate-report.db",
        "--readonly"
      ]
    }
  }
}
```

## Command-Line Interface

### Project Commands

**Generate the report and database:**
```bash
pnpm generate-report
```

**Start the interactive DuckDB UI:**
```bash
pnpm start-report-ui
```

**Download Loop data from S3:**
```bash
pnpm download-loop-data-s3
```

**Generate specific report parts:**
```bash
# Run specific parts with wildcards
pnpm exec ./scripts/generate-report.sh '050*' '060*'

# Preview what would run
pnpm exec ./scripts/generate-report.sh --dry-run --verbose
```

### DuckDB CLI

- [Command Line Client](https://duckdb.org/docs/api/cli) - Interactive SQL shell
- [CLI Parameters](https://duckdb.org/docs/api/cli#command-line-arguments) - Startup options

### Generic DuckDB Commands

```bash
# Start DuckDB with a database file
duckdb generate-report/generate-report.db

# Execute query from command line
duckdb database.db "SELECT * FROM table LIMIT 10"

# Read from stdin
echo "SELECT 42" | duckdb

# Output as JSON
duckdb database.db -json "SELECT * FROM table"

# Output as Markdown
duckdb database.db -markdown "SELECT * FROM table"
```

### Dot Commands

Inside the DuckDB CLI:

- `.help` - Show help
- `.tables` - List tables
- `.schema [TABLE]` - Show schema
- `.mode` - Set output mode
- `.read [FILE]` - Execute SQL from file
- `.exit` or `.quit` - Exit DuckDB

## Additional Resources

### Learning Resources

- [Friendly SQL](https://duckdb.org/docs/guides/sql_features/friendly_sql) - DuckDB's SQL enhancements
- [Samples](https://duckdb.org/docs/guides/index) - Practical guides and examples
- [FAQ](https://duckdb.org/faq) - Frequently asked questions

### Community

- [GitHub Repository](https://github.com/duckdb/duckdb) - Source code
- [Discord](https://discord.duckdb.org) - Community chat
- [Blog](https://duckdb.org/news) - News and updates

### Python Integration

While this project uses the MCP server, DuckDB also has excellent Python support:

- [Python API](https://duckdb.org/docs/api/python/overview) - Python client
- [Pandas Integration](https://duckdb.org/docs/guides/python/sql_on_pandas) - Query Pandas DataFrames

## Quick Reference Card

### Most Common Operations

| Operation | Syntax |
|-----------|--------|
| Create table | `CREATE TABLE name AS SELECT ...` |
| Query JSON | `json_field->'key'` or `json_field->>'key'` |
| Transform JSON | `json_transform(json_col, 'schema')` |
| Unnest array | `unnest(array_col)` |
| Window function | `ROW_NUMBER() OVER (PARTITION BY col ORDER BY col2)` |
| CTE | `WITH cte_name AS (SELECT ...) SELECT ...` |
| Cast type | `CAST(col AS type)` or `col::type` |
| Time filter | `WHERE timestamp >= current_timestamp - INTERVAL 7 DAY` |
| Percentage | `ROUND(count * 100.0 / total, 2)` |
| Conditional count | `COUNT(CASE WHEN condition THEN 1 END)` |

---

## Project-Specific Notes

### Database Schema

For the current database schema and table structure, refer to:
- [020-create-duckdb-database.sh](../../scripts/generate-report-parts/020-create-duckdb-database.sh) - Schema creation

### Query Examples

For practical examples used in this project, see:
- [examples.md](examples.md) - Real queries from the project
- [scripts/generate-report-parts/](../../scripts/generate-report-parts/) - Source scripts
