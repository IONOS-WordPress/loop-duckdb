# AI Integration Guide

This project provides comprehensive AI integration through MCP (Model Context Protocol) servers and Claude Code skills, enabling AI assistants to explore, query, and generate insights from WordPress instance data.

## Overview

The project includes:
- **MCP Server**: DuckDB database access for querying WordPress instance data
- **Skills**: Specialized workflows for querying and creating report insights
- **Documentation**: Comprehensive guides and examples for working with the data

## MCP Servers

### DuckDB MCP Server

The project provides a DuckDB MCP server that enables AI assistants to query the Loop data database directly.

**Configuration** ([.mcp.json](.mcp.json)):
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

**Prerequisites**:
- Install `uv`: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Generate the database: `pnpm generate-report`

**Available Tool**: `mcp__duckdb__query`

The server runs in **readonly mode** to prevent accidental modifications to the database.

### Example Prompts: Querying the Database

Here are useful prompts for querying the database using the MCP server:

#### Basic Data Exploration

```
Show me the database schema - what tables are available?
```

```
What columns are available in the loop_items table?
```

```
Show me a sample row from the loop_items table so I can understand the data structure.
```

#### WordPress Version Analytics

```
What are the top 10 most common WordPress versions in use?
```

```
Show me the distribution of WordPress versions with percentages.
```

#### Plugin Analysis

```
What are the 20 most popular plugins (excluding IONOS plugins)?
```

```
How many instances have the WooCommerce plugin installed?
```

```
Show me plugins that are installed on more than 50% of instances.
```

#### PHP Version Analytics

```
What PHP versions are in use across all instances?
```

```
How many instances are still running PHP 7.x?
```

#### Theme Analysis

```
How many instances use the Extendify theme?
```

```
What are the most popular themes?
```

#### User Behavior Analytics

```
How many users logged in using SSO vs manual login in the last 7 days?
```

```
Show me the login activity for the last 30 days.
```

#### Feature Adoption

```
How many instances have the security features enabled?
```

```
What percentage of users have completed the getting started guide?
```

#### Time-Based Queries

```
Show me instances that haven't sent loop data in the last 7 days.
```

```
What's the average frequency of loop data updates?
```

#### Complex Analysis

```
Show me instances running outdated WordPress versions (older than 6.0) and what plugins they have installed.
```

```
Which plugins are most commonly used together? Show me the top 5 plugin combinations.
```

```
Are there any correlations between WordPress version and login frequency?
```

## Skills

Skills provide specialized workflows and knowledge for working with the project. They are configured in [.claude/settings.json](.claude/settings.json) and the skill documentation is located in [docs/skills/](./skills/).

### Available Skills

#### 1. DuckDB Skill (`duckdb`)

**Purpose**: Query and analyze WordPress instance data using DuckDB SQL.

**Use when you need to**:
- Query Loop data (plugins, themes, PHP/WordPress versions, user behavior, events)
- Generate reports or insights from the database
- Understand the database schema and available tables
- Create SQL queries for data analysis

**Documentation**: [docs/skills/duckdb/](./skills/duckdb/)
- [SKILL.md](./skills/duckdb/SKILL.md) - Overview and database schema
- [examples.md](./skills/duckdb/examples.md) - Query examples from the project
- [reference.md](./skills/duckdb/reference.md) - DuckDB SQL reference

**Example prompts**:
```
Use the duckdb skill to show me how to query plugin data.
```

```
I want to create a SQL query that shows WordPress version distribution. Help me using the duckdb skill.
```

```
Explain the database schema using the duckdb skill.
```

#### 2. Report Insight Skill (`report-insight`)

**Purpose**: Create and refactor report insights - bash scripts that analyze WordPress instance data and generate markdown reports with visualizations.

**Use when you need to**:
- Add new analytics sections to the report
- Modify or refactor existing report insights
- Generate data visualizations (tables and Mermaid charts)
- Create new report parts in `scripts/generate-report-parts/`

**Technology Stack**:
- ✅ Bash (shell scripting)
- ✅ jq (JSON processing)
- ✅ DuckDB SQL (queries)
- ✅ Mermaid (chart syntax)
- ❌ NO Python allowed

**Documentation**: [docs/skills/report-insight/](./skills/report-insight/)
- [SKILL.md](./skills/report-insight/SKILL.md) - Comprehensive guide for creating insights
- [examples.md](./skills/report-insight/examples.md) - Working examples from the project
- [reference.md](./skills/report-insight/reference.md) - Pattern library and techniques

**Example prompts**:
```
Use the report-insight skill to create a new insight showing the top 10 most active themes.
```

```
I want to add a new report section using the report-insight skill. It should analyze plugin update settings.
```

```
Help me refactor the existing WordPress version insight to include a bar chart.
```

### Example Prompts: Creating Insights

Here are useful prompts for creating new report insights:

#### Simple Analytics

```
I want to create a new report insight. The insight should show the distribution of theme usage across instances. Add a pie chart.
```

```
Create a new insight that counts how many instances have auto-updates enabled for plugins. Show the results in a markdown table.
```

```
Add a report section that analyzes the PHP versions in use, showing both count and percentage. Include both a table and a pie chart.
```

#### Feature Adoption Analysis

```
I want to create a new report insight. The insight should output how many unique users have the MCP feature enabled last month. Add a pie chart.
```

```
Create an insight showing the adoption rate of security features (XMLRPC, PEL, credentials checking, mail notify). Show each feature as a percentage.
```

```
Add a report insight that shows what percentage of users have completed each quicklink in the dashboard. Sort by completion rate.
```

#### Event-Based Analysis

```
Create a report insight analyzing user login patterns over the last 30 days. Show daily login counts with a breakdown of SSO vs manual logins.
```

```
Add an insight that tracks the most common events in the last 7 days. Show the top 10 events by frequency.
```

```
I want to see which instances had login failures in the last month. Create an insight with the count and a list of affected instances.
```

#### Comparative Analysis

```
Create an insight comparing WordPress versions to PHP versions. Show which WordPress versions are running on which PHP versions.
```

```
Add a report insight that shows the correlation between theme choice and plugin count. Do instances using certain themes tend to have more plugins?
```

```
Analyze the relationship between instance age (based on first loop timestamp) and feature adoption rates.
```

#### Time-Series Analysis

```
Create an insight showing how plugin installation trends have changed over the last 3 months. Which plugins are growing fastest?
```

```
Add a report showing user engagement trends - how many unique logins per week over the last 2 months?
```

#### Placement and Customization

When creating insights, you can specify:

```
Create an insight about [topic]. It should appear after the WordPress versions section (so around 045-*). Use a table and pie chart.
```

```
Add a new insight as the last section in the report (900-*) that summarizes the key findings. Just use markdown text, no charts.
```

```
Create an insight about [topic] and place it in the plugin analysis section (after 060-*). Use a mermaid bar chart instead of a pie chart.
```

## Database Schema

The DuckDB database contains several tables and views for analyzing WordPress instance data:

### Core Tables

- **`loop_items`**: Raw WordPress instance data (all fields from Loop JSON files)
- **`plugins`**: Active plugins (unnested from loop_items)
- **`themes`**: Active themes (unnested from loop_items)
- **`events`**: Events (unnested from loop_items)

### Important View

- **`recent_loops`**: Latest loop per instance

**Critical**: Always join with `recent_loops` when querying current state:
```sql
FROM loop_items
JOIN recent_loops ON loop_items.filename = recent_loops.filename
```

For detailed schema information, see [docs/skills/duckdb/SKILL.md](./skills/duckdb/SKILL.md).

## Workflow Examples

### Querying Data Directly

1. Ensure database exists: `pnpm generate-report`
2. Ask AI to query using the MCP server:
   ```
   Show me the top 10 WordPress versions in use.
   ```
3. AI uses `mcp__duckdb__query` tool to execute SQL
4. Results are returned for analysis

### Creating a New Report Insight

1. Request the insight with clear requirements:
   ```
   I want to create a new report insight. The insight should output how many unique users have the MCP feature enabled last month. Add a pie chart.
   ```

2. The AI will:
   - Use the `report-insight` skill
   - Clarify requirements (placement, exact metrics, visualization preferences)
   - Explore the database schema to understand data structure
   - Create a query plan and get your approval
   - Generate the bash script in `scripts/generate-report-parts/`
   - Make it executable
   - Test it: `pnpm generate-report 'NNN-insight-name.sh'`

3. Review the generated markdown output

4. Regenerate full report to see it in context: `pnpm generate-report`

### Refactoring an Existing Insight

1. Identify the script to refactor:
   ```
   I want to improve the WordPress versions insight (040-wordpress_versions.sh). Can you add a bar chart in addition to the existing pie chart?
   ```

2. The AI will:
   - Read the existing script
   - Explain current implementation
   - Propose changes
   - Get your approval
   - Implement and test the changes

## Testing and Development

### Interactive Query Development

```bash
# Start the DuckDB UI for interactive exploration
pnpm start-report-ui
```

Open http://localhost to:
- Browse tables and views
- Test SQL queries interactively
- Export results
- Inspect schemas

### Testing Report Insights

```bash
# Test a single insight script (outputs markdown to stdout)
pnpm generate-report '175-mcp-enabled-last-month.sh'

# Test with verbose logging
pnpm generate-report --verbose '175-mcp-enabled-last-month.sh'

# Test multiple insights
pnpm generate-report '170-*.sh' '180-*.sh'

# Dry run to see what would execute
pnpm generate-report --dry-run '175-*.sh'

# Generate with PDF output
pnpm generate-report --pdf '175-mcp-enabled-last-month.sh'
```

### Full Report Generation

```bash
# Generate complete report (markdown)
pnpm generate-report

# Generate with verbose output
pnpm generate-report --verbose

# Generate with PDF output
pnpm generate-report --pdf
```

## Configuration Files

### MCP Server Configuration

**File**: [.mcp.json](.mcp.json)

Configures the DuckDB MCP server with database path and readonly mode.

### Claude Code Settings

**File**: [.claude/settings.json](.claude/settings.json)

```json
{
  "enabledMcpjsonServers": ["duckdb"],
  "enableAllProjectMcpServers": true,
  "permissions": {
    "allow": ["mcp__duckdb__*", "Bash(find:*)", "Bash(chmod:*)"]
  },
  "skillDirs": ["./docs/skills"]
}
```

Configures:
- Enabled MCP servers
- Permissions for MCP tools and bash commands
- Skill directory location

## Requirements

To use the AI integration features:

1. **uv** (for MCP server): `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. **Generated database**: `pnpm generate-report`
3. **AI assistant** with MCP support:
   - Claude Code CLI
   - Google Gemini CLI
   - VS Code with Copilot (with MCP support)
   - Other MCP-compatible AI assistants

## Tips for Effective AI Interaction

### When Querying Data

- Start with broad questions, then drill down
- Ask for sample data first to understand structure
- Request explanations of complex queries
- Ask for multiple visualization options

### When Creating Insights

- Be specific about what data you want to analyze
- Specify placement in the report (before/after which section)
- Indicate visualization preferences (table, chart, both)
- Request the AI use relevant skills (duckdb or report-insight)

### When You're Unsure

- Ask the AI to explore the schema first
- Request multiple approach options with trade-offs
- Start with a simple version, then iterate
- Use the interactive UI to prototype queries

## Troubleshooting

### "MCP server not found"

**Solution**: Install uv:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### "Database not found"

**Solution**: Generate the database:
```bash
pnpm generate-report
```

### "Permission denied" for MCP tools

**Solution**: Check [.claude/settings.json](.claude/settings.json) includes:
```json
{
  "permissions": {
    "allow": ["mcp__duckdb__*"]
  }
}
```

### "Skill not found"

**Solution**: Verify skill directory is configured:
```json
{
  "skillDirs": ["./docs/skills"]
}
```

### Query returns no results

**Solution**:
- Verify database has data: `pnpm start-report-ui`
- Check if you joined with `recent_loops` for current state
- Ensure database is up-to-date: `pnpm download-loop-data-s3 && pnpm generate-report`

## Additional Resources

- [Main README](../README.md) - Project overview and setup
- [DuckDB Skill Documentation](./skills/duckdb/) - Query reference and examples
- [Report Insight Skill Documentation](./skills/report-insight/) - Creating insights guide
- [DuckDB Official Documentation](https://duckdb.org/docs/) - SQL reference
- [Mermaid Documentation](https://mermaid.js.org/) - Chart syntax reference
- [MCP Protocol Specification](https://modelcontextprotocol.io/) - Understanding MCP
