---
name: report-insights
description: Create and refactor report insights for analyzing WordPress instance data. Use when adding new analytics sections to the report, modifying existing insights, or creating data visualizations with DuckDB queries and Mermaid charts. Provides templates and best practices for report generation scripts.
compatibility: Requires bash, DuckDB database at generate-report/generate-report.db, jq for JSON processing, and the ionos.loop-duckdb.exec_duckdb function. Scripts must be executable and follow naming conventions.
metadata:
  database-location: generate-report/generate-report.db
  mcp-server: duckdb
  report-parts-directory: scripts/generate-report-parts
  output-formats: markdown, mermaid-charts
  version: "1.0"
  prerequisites: Database must exist (run pnpm generate-report first)
  allowed-languages: bash, jq only - NO Python
allowed-tools: mcp__duckdb__query Read Write Edit Bash
---

# Report Insights Skill

Use this skill when creating or refactoring report insight scripts that analyze WordPress instance data and generate markdown reports with visualizations.

## ⚠️ CRITICAL: Technology Stack Requirements

**MANDATORY TECHNOLOGY RESTRICTIONS:**

**✅ ALLOWED:**
- **Bash** - Shell scripting for report generation
- **jq** - JSON processing and transformation
- **DuckDB SQL** - Database queries via `ionos.loop-duckdb.exec_duckdb`
- **Mermaid** - Chart syntax for visualizations

**❌ FORBIDDEN:**
- **NO Python** - Do not use Python scripts, modules, or libraries
- **NO Python imports** - No `import`, `pip`, `python`, or `.py` files
- **NO other programming languages** - Stick to bash and jq only

**When generating insights:**
- Use bash for orchestration and output formatting
- Use jq for JSON processing and transformation
- Use DuckDB SQL for data queries
- Use Mermaid syntax (generated via jq) for charts

**Why this restriction?**
- Ensures minimal dependencies
- Maintains consistent tooling across all insights
- Simplifies deployment and execution
- All required tools (bash, jq, DuckDB) are already available

## IMPORTANT: Documentation Priority

**ALWAYS prioritize the official DuckDB documentation over examples in this skill.**

When writing SQL queries:
1. **First**: Use the MCP server to explore the database schema
2. **Second**: Consult the [official DuckDB documentation](https://duckdb.org/docs/sql/introduction)
3. **Third**: Reference examples in this skill as templates only

**Official DuckDB Resources** (use these as primary references):
- **SQL Syntax**: [https://duckdb.org/docs/sql/introduction](https://duckdb.org/docs/sql/introduction)
- **JSON Functions**: [https://duckdb.org/docs/extensions/json](https://duckdb.org/docs/extensions/json)
- **Aggregate Functions**: [https://duckdb.org/docs/sql/functions/aggregates](https://duckdb.org/docs/sql/functions/aggregates)
- **Window Functions**: [https://duckdb.org/docs/sql/window_functions](https://duckdb.org/docs/sql/window_functions)
- **CTEs**: [https://duckdb.org/docs/sql/query_syntax/with](https://duckdb.org/docs/sql/query_syntax/with)

**Mermaid Documentation** (for charts):
- **Pie Charts**: [https://mermaid.js.org/syntax/pie.html](https://mermaid.js.org/syntax/pie.html)

## When to Use This Skill

Use this skill when you need to:
- Create new analytics sections for the report
- Modify or refactor existing report insights
- Generate data visualizations (tables and charts)

**Do NOT use this skill for**: Database queries only (use the `duckdb` skill instead)

## Agent Workflow Instructions

### ⚠️ MANDATORY: Interactive User Communication

**YOU MUST use the AskUserQuestion tool for ALL user interactions during execution.**

**DO NOT:**
- ❌ Ask questions in your text responses and wait for the user to reply
- ❌ Say "please confirm..." or "let me know..." without using the tool
- ❌ Make assumptions when requirements are unclear
- ❌ Skip user approval steps

**DO:**
- ✅ Use AskUserQuestion immediately when you need clarification
- ✅ Present clear options with descriptions for user to choose from
- ✅ Get explicit approval before implementing changes
- ✅ Ask follow-up questions using the tool if the answer raises new questions

### Using the AskUserQuestion Tool

**CRITICAL: Use the AskUserQuestion tool whenever you need user input, clarification, or approval.**

The AskUserQuestion tool is your primary mechanism for interacting with the user during execution. You MUST use it instead of waiting for the user to respond in chat.

**When to use AskUserQuestion:**
- Requirements are ambiguous or underspecified
- Multiple approaches are possible and you need the user to choose
- You need approval before implementing changes
- You need specific details (e.g., placement, naming, format preferences)
- You want confirmation that your plan meets user expectations

**Example usage scenarios:**

**Scenario 1: Clarifying placement**
```
AskUserQuestion:
  questions:
    - question: "Where should this insight appear in the report?"
      header: "Placement"
      multiSelect: false
      options:
        - label: "After WordPress Versions (045-xyz.sh)"
          description: "Places the insight in the WordPress analysis section"
        - label: "After Plugin Analysis (125-xyz.sh)"
          description: "Groups it with plugin-related insights"
        - label: "At the end (900-xyz.sh)"
          description: "Adds it as a final summary section"
```

**Scenario 2: Choosing visualization format**
```
AskUserQuestion:
  questions:
    - question: "What visualization format should be used?"
      header: "Format"
      multiSelect: false
      options:
        - label: "Markdown table only"
          description: "Simple table format, best for detailed data"
        - label: "Pie chart only"
          description: "Visual chart, best for proportional data (max 10 items)"
        - label: "Both table and chart"
          description: "Comprehensive view with table and chart"
```

**Scenario 3: Getting plan approval**
```
AskUserQuestion:
  questions:
    - question: "Which implementation approach should I use?"
      header: "Approach"
      multiSelect: false
      options:
        - label: "Simple aggregation (Recommended)"
          description: "Fast query, groups by category and counts"
        - label: "Window functions"
          description: "More complex, allows ranking and percentile calculations"
        - label: "CTE-based analysis"
          description: "Multi-step analysis, easier to debug but slightly slower"
```

**Best practices:**
- Keep header text short (max 12 characters)
- Provide 2-4 clear options with meaningful descriptions
- Mark recommended options with "(Recommended)" in the label
- Use multiSelect: true when options are not mutually exclusive
- Never skip using this tool - waiting for chat responses breaks the workflow

### Clarifying Ambiguous Requests

**ALWAYS use the AskUserQuestion tool when requirements are not clearly defined.**

**Example - Adding a New Insight:**
- **User request**: "Add a new insight about xyz"
- **Required clarifications** (use AskUserQuestion for each):
  1. Where should this insight appear in the report? (after/before which existing insight?)
  2. What specific aspect of "xyz" should be analyzed?
  3. What visualization format is preferred (table, chart, both)?
- **Derive insight filename**: Based on user's response, determine the appropriate `NNN` number for the script name (e.g., if it should appear after `040-wordpress_versions.sh`, suggest `045-xyz-analysis.sh`)

### Creating a New Insight

When creating a new insight, follow this workflow:

1. **Understand the requirements**
   - **Use AskUserQuestion** to clarify anything ambiguous
   - Ask about:
     - Placement in the report (filename number)
     - Specific data to be analyzed
     - Visualization preferences (table, chart, both)
   - **Example**: Use AskUserQuestion with multiSelect: false to present placement options

2. **Create and explain a query plan**
   - Explore the database schema using `mcp__duckdb__query`
   - Draft the SQL query approach
   - Explain to the user:
     - What tables/views will be queried
     - What data will be extracted
     - How the data will be aggregated/calculated
     - What output format will be used (markdown table, chart, both)

3. **Get user approval**
   - Present the plan clearly
   - **Use AskUserQuestion** to ask: "Does this approach meet your requirements?"
   - **Example**: Present 2-3 approach options with descriptions of trade-offs
   - Wait for confirmation before proceeding

4. **Implement the insight**
   - Create the script file with appropriate naming (e.g., `175-mcp-enabled-last-month.sh`)
   - Make it executable: `chmod +x scripts/generate-report-parts/175-mcp-enabled-last-month.sh`
   - Test it: `pnpm generate-report '175-mcp-enabled-last-month.sh'` (outputs markdown to stdout)

### Refactoring an Existing Insight

When refactoring an insight, follow this workflow:

1. **Understand the change request**
   - **Use AskUserQuestion** to clarify what needs to be changed and why
   - Ask about:
     - Specific problems with current implementation
     - Desired outcomes and goals
     - Any constraints or preferences

2. **Analyze the current implementation**
   - Read the existing script
   - Explain to the user:
     - What the current implementation does
     - How it queries and processes data
     - What output it generates

3. **Create a refactoring plan**
   - Explain what needs to change to meet the refactoring goals
   - Describe:
     - Which parts of the query will be modified
     - What new logic will be added
     - How the output will change
     - Any potential impacts on other parts of the report

4. **Get user approval**
   - Present the refactoring plan
   - **Use AskUserQuestion** to ask: "Does this refactoring plan align with your goals?"
   - **Example**: Present 2-4 refactoring approach options with trade-offs
   - Wait for confirmation before making changes

5. **Implement the refactoring**
   - Make the changes to the script
   - Test thoroughly: `pnpm generate-report '175-mcp-enabled-last-month.sh'`
   - Verify the markdown output meets expectations
   - Compare before/after output if needed

## Quick Start Workflow

1. **Explore schema** using `mcp__duckdb__query` tool:
   ```sql
   SHOW TABLES;
   DESCRIBE loop_items;
   SELECT * FROM loop_items LIMIT 1;
   ```

2. **Develop query** in DuckDB UI:
   ```bash
   pnpm start-report-ui
   ```

3. **Create script** in `scripts/generate-report-parts/NNN-name.sh`:
   - `NNN` = 3-digit number determining execution order
   - See [reference.md](reference.md#naming-conventions) for number ranges

4. **Make executable**:
   ```bash
   chmod +x scripts/generate-report-parts/NNN-name.sh
   ```

5. **Test** (outputs generated markdown):
   ```bash
   # Test your insight script - outputs the generated markdown to stdout
   pnpm generate-report '175-mcp-enabled-last-month.sh'

   # Or with verbose logging to see which files are being processed
   pnpm generate-report --verbose '175-mcp-enabled-last-month.sh'
   ```

## Script Template

**IMPORTANT**: Only use bash and jq. NO Python allowed.

```bash
#!/usr/bin/env bash

#
# Description of what this insight analyzes
#
# TECHNOLOGY: bash + jq + DuckDB SQL only (NO Python)
#

readonly SQL="
-- Consult https://duckdb.org/docs/sql/introduction for SQL syntax
-- Always join with recent_loops for current state
SELECT ...
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
"

readonly TITLE="Your Insight Title"

cat <<EOF

# $TITLE

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
EOF
```

**Template with Mermaid Chart (using jq for JSON processing):**

```bash
#!/usr/bin/env bash

#
# Description of what this insight analyzes
#
# TECHNOLOGY: bash + jq + DuckDB SQL only (NO Python)
#

readonly SQL="
SELECT category, count
FROM ...
ORDER BY count DESC
"

readonly TITLE="Your Insight Title"

cat <<EOF

# $TITLE

## Data Table

$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')

## Visualization

\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.category)\" : \(.count)")
')
\`\`\`
EOF
```

**Key points:**
- Use bash heredocs (`cat <<EOF`) for multi-line output
- Use jq for JSON transformation (e.g., DuckDB JSON output → Mermaid syntax)
- Never use Python scripts or modules
- All data processing is done via DuckDB SQL

## Essential Requirements

### 0. Use Only Bash and jq (NO Python)

**MANDATORY**: All insight scripts MUST use only:
- **Bash** for scripting
- **jq** for JSON processing
- **DuckDB SQL** for queries

**FORBIDDEN**:
- ❌ Python scripts or modules
- ❌ `import` statements
- ❌ `.py` files
- ❌ Any other programming languages

### 1. Always Join with recent_loops

**CRITICAL**: Every query analyzing current state MUST join with `recent_loops`:

```sql
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
```

### 2. Use Official DuckDB Syntax

Refer to [official DuckDB documentation](https://duckdb.org/docs/sql/introduction) for:
- SQL statements and syntax
- JSON operations: [DuckDB JSON docs](https://duckdb.org/docs/extensions/json)
- Aggregate functions: [DuckDB aggregates](https://duckdb.org/docs/sql/functions/aggregates)
- Window functions: [DuckDB window functions](https://duckdb.org/docs/sql/window_functions)

### 3. Calculate Percentages Correctly

Use `100.0` (not `100`) for float division:

```sql
ROUND(count * 100.0 / total, 2) AS percentage
```

### 4. Exclude IONOS Plugins

When analyzing plugins:

```sql
WHERE plugin_slug NOT LIKE 'ionos-%'
```

## Schema Exploration

**Before writing queries**, explore the database schema using `mcp__duckdb__query`:

```sql
-- List tables
SHOW TABLES;

-- Table structure
DESCRIBE loop_items;

-- Sample data
SELECT * FROM loop_items LIMIT 1;

-- Explore JSON (see https://duckdb.org/docs/extensions/json)
SELECT plugin_data->'ionos-essentials' FROM loop_items LIMIT 1;
```

**Workflow**:
1. Use MCP server to discover columns and data types
2. Consult [official DuckDB JSON documentation](https://duckdb.org/docs/extensions/json) for JSON operations
3. Test query fragments incrementally
4. Build final query based on official DuckDB syntax

See [reference.md](reference.md#schema-discovery) for detailed workflows.

## Output Formats

### Markdown Tables

```bash
$(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
```

### Mermaid Pie Charts

See [official Mermaid documentation](https://mermaid.js.org/syntax/pie.html) for syntax.

```bash
\`\`\`mermaid
$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL LIMIT 10;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.category)\" : \(.count)")
')
\`\`\`
```

**Note**: Limit pie charts to ≤10 data points for readability.

## Testing

### Testing Single Insights

**Test a single insight script** by passing its filename to `generate-report`:

```bash
# Test your insight - outputs the generated markdown to stdout
pnpm generate-report '175-mcp-enabled-last-month.sh'
```

**Output**: The command will execute only the specified script and output the generated markdown content to stdout. This allows you to:
- Verify the markdown formatting is correct
- Check that tables and charts render properly
- Debug SQL queries and jq transformations
- Iterate quickly without running the full report

### Testing Options

```bash
# Develop queries interactively in DuckDB UI
pnpm start-report-ui

# Test single script (outputs markdown)
pnpm generate-report '175-mcp-enabled-last-month.sh'

# Verbose mode - shows which files are being processed
pnpm generate-report --verbose '175-mcp-enabled-last-month.sh'

# Dry run - see what would execute without running
pnpm generate-report --dry-run '175-mcp-enabled-last-month.sh'

# Generate with PDF output
pnpm generate-report --pdf '175-mcp-enabled-last-month.sh'

# Test multiple insights
pnpm generate-report '170-*.sh' '180-*.sh'
```

### Testing Workflow

1. **Develop SQL query** in DuckDB UI (`pnpm start-report-ui`)
2. **Create insight script** with the query
3. **Make executable** (`chmod +x scripts/generate-report-parts/175-mcp-enabled-last-month.sh`)
4. **Test immediately** (`pnpm generate-report '175-mcp-enabled-last-month.sh'`)
5. **Review markdown output** in stdout
6. **Iterate** until output is correct

## Common Patterns

For query patterns, see:
- **Official DuckDB docs**: [https://duckdb.org/docs/sql/introduction](https://duckdb.org/docs/sql/introduction) (primary reference)
- [examples.md](examples.md) - Working examples from the project
- [reference.md](reference.md) - Pattern library and techniques

**Remember**: Official DuckDB documentation takes precedence over skill examples.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script not executing | `chmod +x scripts/generate-report-parts/NNN-name.sh` |
| Query returns no results | Verify `recent_loops` join and database has data |
| Mermaid chart error | Check jq syntax, limit to ≤10 items, verify JSON format |
| Percentage doesn't sum to 100% | Check for NULL values, use `DISTINCT` correctly |
| Can't find `ionos.loop-duckdb.exec_duckdb` | Function only available in generate-report.sh context |
| SQL syntax error | Consult [official DuckDB SQL docs](https://duckdb.org/docs/sql/introduction) |
| Need complex data transformation | Use jq for JSON processing - NO Python allowed |
| Want to use Python | **FORBIDDEN**: Use bash + jq instead. All scripts must be bash-only |

## Additional Resources

**Priority order for reference**:
1. **Official DuckDB documentation**: [https://duckdb.org/docs/](https://duckdb.org/docs/) - **Use this first**
2. **Official Mermaid documentation**: [https://mermaid.js.org/](https://mermaid.js.org/) - **Use this for charts**
3. [reference.md](reference.md) - Comprehensive patterns and techniques reference
4. [examples.md](examples.md) - Complete working examples from the project
5. [DuckDB skill](../duckdb/SKILL.md) - Database querying reference
