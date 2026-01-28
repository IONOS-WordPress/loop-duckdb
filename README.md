# About

Provides tooling to explore and analyze `ionos-loop` data using DuckDB.

This project downloads WordPress instance data from S3, converts it to DuckDB format, and generates comprehensive reports with analytics and visualizations.

# Requirements

- **bash** - Shell scripting environment
- **docker** - For running DuckDB and AWS CLI (no local installation needed)
- **pnpm** - Package manager for Node.js dependencies
- **uv** (optional) - Required for DuckDB MCP server integration with AI assistants

> DuckDB runs in Docker, so you don't need to install it locally.

# Quick Start

## Initial Setup (First Time)

1. **Install dependencies:**
   ```bash
   pnpm install
   ```

2. **Configure AWS credentials:**
   - Create a `.secrets` file (see `*.example` templates for format)
   - Obtain credentials from https://dcd.ionos.com/latest/#/key-management
   - Log in using the "Loop User"

3. **Download Loop data from S3:**
   ```bash
   pnpm download-loop-data-s3
   ```

4. **Generate the report and database:**
   ```bash
   pnpm generate-report
   ```

5. **(Optional) Install MCP server support:**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

## Regular Usage (After Initial Setup)

**Generate fresh reports:**
```bash
pnpm download-loop-data-s3  # Get latest data from S3
pnpm generate-report        # Generate new report
```

**Explore data interactively:**
```bash
pnpm start-report-ui        # Opens browser-based DuckDB UI
```

# Available Commands

This project provides the following npm scripts (defined in [package.json](package.json)):

## `pnpm download-loop-data-s3`

**Purpose**: Downloads Loop data from S3 bucket to local `./s3` directory

**Script**: `./scripts/download-loop-data-s3.sh`

**Prerequisites**:
- Docker installed and running
- AWS credentials configured in `.secrets` file

**What it does**:
1. Syncs all JSON files from the S3 `loop` bucket to `./s3/`
2. Excludes the `duckdb/*` directory from sync
3. Adjusts file permissions for local access

**Dependencies**: None (first step in the workflow)

**Output**: JSON files in `./s3/` directory

**Example**:
```bash
pnpm download-loop-data-s3
```

---

## `pnpm generate-report`

**Purpose**: Generates the report with database and markdown output (PDF optional)

**Script**: `./scripts/generate-report.sh`

**Prerequisites**:
- Loop data must exist in `./s3` directory (run `pnpm download-loop-data-s3` first)
- Docker installed and running

**What it does**:
1. Validates that `./s3` directory contains JSON files
2. Converts JSON data to Parquet format (`generate-report.parquet`)
3. Creates DuckDB database (`generate-report.db`)
4. Sets up tables: `loop_items`, `plugins`, `themes`, `events`
5. Creates views: `recent_loops` (latest loop per instance)
6. Executes all report parts in `./scripts/generate-report-parts/` (alphabetical order)
7. Generates markdown report (`generate-report.md`)
8. Formats markdown with Prettier
9. (Optional) Converts to PDF format (`generate-report.pdf`) if `--pdf` flag is used

**Dependencies**: Requires data from `pnpm download-loop-data-s3`

**Output**: 3-4 files in `./generate-report/` directory:
- `generate-report.parquet` - Parquet file with all loop data
- `generate-report.db` - DuckDB database
- `generate-report.md` - Markdown report with mermaid charts
- `generate-report.pdf` - PDF version of the report (only with `--pdf` flag)

**Command-line options**:
- `--verbose` - Enable verbose output showing which files are being processed (disabled by default)
- `--dry-run` - Show which scripts would run without executing them
- `--pdf` - Generate PDF output in addition to markdown (disabled by default)
- `--help` - Show help message with usage examples

**Examples**:
```bash
# Generate report (markdown only, no verbose output)
pnpm generate-report

# Generate report with PDF output
pnpm generate-report --pdf

# Generate report with verbose output
pnpm generate-report --verbose

# Generate report with both PDF and verbose output
pnpm generate-report --verbose --pdf

# Dry run to see which scripts would execute
pnpm generate-report --dry-run

# Generate only specific report parts (see Advanced Usage section)
pnpm generate-report '050*' '060*'

# Generate specific parts with PDF output
pnpm generate-report --pdf '050*' '060*'
```

---

## `pnpm start-report-ui`

**Purpose**: Starts the browser-based DuckDB UI for interactive data exploration

**Script**: `./scripts/start-report-ui.sh`

**Prerequisites**:
- Docker installed and running
- Optionally, run `pnpm generate-report` first to create the database

**What it does**:
1. Checks if `./generate-report/generate-report.db` exists
2. If database doesn't exist, automatically runs `pnpm generate-report`
3. Starts DuckDB with web UI on http://localhost (default port)
4. Mounts the database in read-write mode for exploration

**Dependencies**:
- Auto-generates database if not present (calls `pnpm generate-report`)
- If database exists: None (can run independently)

**Output**: Interactive browser UI at http://localhost

**Example**:
```bash
pnpm start-report-ui
```

---

## `pnpm detect-plugins-using-htaccess-phpini-or-dropins`

**Purpose**: Analyzes plugins that use `.htaccess`, `php.ini`, or WordPress drop-ins

**Script**: `./snippets/plugins_using_htaccess_phpini_or_dropins.sh snippets/500-most-active-plugins.csv`

**Prerequisites**:
- CSV file with plugin list (`snippets/500-most-active-plugins.csv`)

**What it does**:
- Analyzes plugins for specific file usage patterns
- Useful for identifying plugins with special server requirements

**Dependencies**: None (standalone utility script)

**Example**:
```bash
pnpm detect-plugins-using-htaccess-phpini-or-dropins
```

# Workflow Summary

## Script Dependencies

```
Initial Setup:
1. pnpm install
2. Configure .secrets file
3. pnpm download-loop-data-s3  → downloads JSON files to ./s3
4. pnpm generate-report        → requires ./s3 data
                                → generates ./generate-report/* files

Interactive Exploration:
pnpm start-report-ui           → requires ./generate-report/generate-report.db
                                → auto-runs pnpm generate-report if needed

Utility Scripts:
pnpm detect-plugins-using-htaccess-phpini-or-dropins  → standalone
```

## Data Flow

```
S3 Bucket (loop)
    ↓
[pnpm download-loop-data-s3]
    ↓
./s3/*.json (Raw Loop Data)
    ↓
[pnpm generate-report]
    ↓
./generate-report/
    ├── generate-report.parquet  (Converted data)
    ├── generate-report.db       (DuckDB database)
    ├── generate-report.md       (Markdown report)
    └── generate-report.pdf      (PDF report)
    ↓
[pnpm start-report-ui] → Interactive UI
```

# Advanced Usage

## Report Generation Details

### Report Parts Execution

The report parts are located in `./scripts/generate-report-parts/`. They will be executed in **alphabetical** order by the generate-report script.

> Each script located in `./scripts/generate-report-parts` must be executable. Make it executable using `chmod +x ...` (or copy an existing executable one).

The output of all scripts will be collected together into `./generate-report/generate-report.md` (and displayed in the terminal).

### How to Add New Insights to the Report

1. **Choose where the new insight should appear** (remember: alphabetical order)

   Example: To insert between `050-php_versions.sh` and `060-most-active-plugins.sh`, name your script `055-my-new-insight.sh`

   To append as the last part: `<last number + 1>-my-new-insight.sh`

   > Position your report part after `030-generate-report-header.sh` which creates the markdown report header.

2. **Make the script executable:**
   ```bash
   chmod +x ./scripts/generate-report-parts/055-my-new-insight.sh
   ```

3. **Start with this skeleton:**

   ```sh
   #!/usr/bin/env bash
   #
   # generates markdown output for my new insight
   #

   readonly SQL="
   -- select the 3 first rows of the loop_items table
   SELECT * from loop_items LIMIT 3;
   "

   readonly TITLE="My new insight"

   cat <<EOF
   # $TITLE

   $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown')
   EOF
   ```

   This skeleton will query the first 3 rows of table `loop_items` and output the results as a markdown table.

   > Table `loop_items` contains all collected loop items

4. **Test the report generation:**
   ```bash
   pnpm generate-report
   ```

   The output should contain your script at the desired location.

5. **Develop your SQL query:**

   - Look at the loop JSON data files to understand the data structure
   - Open the DuckDB UI using `pnpm start-report-ui` and explore the prepopulated tables
   - **Pro tip**: Copy table structure and sample data into an AI assistant and ask it to generate the query

   Example prompt for AI:
   ```
   You are a DuckDB expert.

   I have a table `[paste table name here]` with the following structure:

   [paste table structure here]

   Here are some sample data in csv format:

   [paste the csv sample table data here]

   [your question here]
   ```

   - Check if the generated statement looks correct
   - Test it in the DuckDB UI
   - If it works, add it to your script's SQL variable and regenerate the report
   - If not, ask the AI to improve the query

**Have a look at the existing report parts to see how to output tables and charts.**

### Testing Your Report Part in Isolation

To test only your specific report part during development:

```bash
# Test with dry-run to see what would execute (without verbose output)
pnpm generate-report --dry-run '055-my-new-insight.sh'

# Test with verbose and dry-run to see detailed execution info
pnpm generate-report --verbose --dry-run '055-my-new-insight.sh'

# Run only your report part
pnpm generate-report '055-my-new-insight.sh'

# Run your report part with verbose output to see processing details
pnpm generate-report --verbose '055-my-new-insight.sh'

# Run your report part and generate PDF
pnpm generate-report --pdf '055-my-new-insight.sh'
```

### How to Run Only Specific Report Parts

The generate-report script supports wildcard filtering to run only specific report parts. You can pass one or more wildcard patterns as arguments:

**Examples:**

Run only your own report script called `200-my-own-insight.sh`:
```bash
./scripts/generate-report.sh 200-my-own-insight.sh
```

Run all scripts starting with `200-`:
```bash
./scripts/generate-report.sh '200*'
```

Run multiple specific parts using wildcards:
```bash
pnpm generate-report 030* 050* '*nba*' 140-security-settings
```

This will execute only:
- Scripts matching `030*` (e.g., `030-generate-report-header.sh`)
- Scripts matching `050*` (e.g., `050-php_versions.sh`)
- Scripts containing `nba` anywhere in the name (e.g., `110-nbas-dismissed.sh`)
- The exact script `140-security-settings.sh`

You can combine options with filters:
```bash
# Dry run with verbose output
./scripts/generate-report.sh --verbose --dry-run '200*'

# Generate with PDF output
./scripts/generate-report.sh --pdf '200*'

# All options together
./scripts/generate-report.sh --verbose --pdf '200*'
```

### How to Skip a Single Report Part

**Option 1: Using wildcard filtering (recommended)**

Run only the parts you want by specifying them explicitly. For example, to skip `050-php_versions.sh`, run all other parts:
```bash
# First, check what would run (use --verbose to see detailed list)
pnpm generate-report --dry-run

# With verbose output to see which scripts match
pnpm generate-report --verbose --dry-run

# Run everything except 050* by listing all the parts you want
pnpm generate-report 010* 020* 030* 040* 060* 070* 080* 090* 1*
```

**Option 2: Temporarily disable execution**

Make the script non-executable:
```bash
chmod -x ./scripts/generate-report-parts/050-php_versions.sh
```

To re-enable it later:
```bash
chmod +x ./scripts/generate-report-parts/050-php_versions.sh
```

**Option 3: Early exit in the script**

Insert `exit 0` at the beginning of the script (after the shebang):
```bash
#!/usr/bin/env bash
exit 0

# Rest of the script...
```

## Developing SQL Queries in DuckDB

The `pnpm generate-report` command generates a DuckDB database.

Use `pnpm start-report-ui` to start DuckDB with the `./generate-report/generate-report.db` database generated by `pnpm generate-report`. You can open the browser-based user interface to explore and query the collected loop data.

The UI allows you to:
- Browse tables and views
- Execute SQL queries interactively
- Export results in various formats
- Inspect table schemas and data

## DuckDB MCP Support

The project includes MCP (Model Context Protocol) server integration for DuckDB, allowing AI assistants to query the report database directly.

### Installation

Install `uv` (required for the MCP server):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Configuration

The MCP server is configured in [.mcp.json](.mcp.json) and uses the readonly database at `generate-report/generate-report.db`.

### Usage with AI Assistants

The DuckDB skill is documented in [docs/skills/duckdb](docs/skills/duckdb):
- **[SKILL.md](docs/skills/duckdb/SKILL.md)** - Overview and database schema
- **[examples.md](docs/skills/duckdb/examples.md)** - Query examples from the project
- **[reference.md](docs/skills/duckdb/reference.md)** - DuckDB SQL reference and documentation links

AI assistants (Claude Code, Gemini CLI, VS Code Copilot) can use the MCP server to execute queries against the report database.

# Project Structure

```
loop-duckdb/
├── .mcp.json                          # MCP server configuration
├── .secrets                           # AWS credentials (create this, not in git)
├── package.json                       # npm scripts and dependencies
├── README.md                          # This file
├── docs/
│   └── skills/duckdb/                # DuckDB skill documentation
│       ├── SKILL.md                   # Overview and schema
│       ├── examples.md                # Query examples
│       └── reference.md               # DuckDB reference
├── scripts/
│   ├── download-loop-data-s3.sh      # Downloads JSON data from S3
│   ├── generate-report.sh             # Main report generation script
│   ├── start-report-ui.sh            # Starts DuckDB UI
│   └── generate-report-parts/        # Individual report sections
│       ├── 010-generate-parquet-file.sh
│       ├── 020-create-duckdb-database.sh
│       ├── 030-generate-report-header.sh
│       ├── 040-wordpress_versions.sh
│       ├── 050-php_versions.sh
│       ├── 060-most-active-plugins.sh
│       ├── 070-most-active-themes.sh
│       ├── 080-logins.sh
│       ├── 090-extendify.sh
│       ├── 100-getting-started-finished.sh
│       ├── 110-nbas-dismissed.sh
│       ├── 120-nbas-completed-dismissed.sh
│       ├── 130-quicklinks-usage.sh
│       ├── 140-security-settings.sh
│       ├── 150-extendify-onboarding-status.sh
│       ├── 160-maintenance-status.sh
│       └── 170-mcp-enabled.sh
├── snippets/
│   └── plugins_using_htaccess_phpini_or_dropins.sh  # Plugin analysis utility
├── s3/                                # Downloaded Loop data (git-ignored)
│   └── *.json
└── generate-report/                   # Generated output (git-ignored)
    ├── generate-report.parquet
    ├── generate-report.db
    ├── generate-report.md
    └── generate-report.pdf
```

# Directory Reference

This section explains the purpose of each top-level directory in the project.

## Configuration Directories

### `.claude/`
**Purpose**: Configuration for Claude Code AI assistant

**Contents**:
- `CLAUDE.md` - Project instructions for Claude
- `settings.json` - Claude-specific settings
- `settings.local.json` - Local overrides (not in git)

**When to modify**: When customizing Claude AI assistant behavior for this project

---

### `.gemini/`
**Purpose**: Configuration for Google Gemini CLI AI assistant

**Contents**:
- `GEMINI.md` - Project instructions for Gemini
- `settings.json` - Gemini-specific settings
- Skills are symlinked from `docs/skills/`

**When to modify**: When customizing Gemini AI assistant behavior for this project

---

### `.vscode/`
**Purpose**: VS Code workspace settings

**Contents**: Editor-specific configuration and preferences

**When to modify**: When customizing VS Code behavior for this project

---

## Documentation Directories

### `docs/`
**Purpose**: Project documentation and AI assistant skills

**Contents**:
- `skills/duckdb/` - DuckDB skill documentation for AI assistants
  - `SKILL.md` - Overview and database schema
  - `examples.md` - Query examples from the project
  - `reference.md` - DuckDB SQL reference

**When to modify**: When adding new documentation or AI skills

---

## Source Code Directories

### `scripts/`
**Purpose**: Main automation scripts for the project

**Contents**:
- `download-loop-data-s3.sh` - Downloads JSON data from S3
- `generate-report.sh` - Main report generation script
- `start-report-ui.sh` - Starts DuckDB interactive UI
- `generate-report-parts/` - Modular report section generators
  - `010-generate-parquet-file.sh` - Converts JSON to Parquet
  - `020-create-duckdb-database.sh` - Creates database schema
  - `030-generate-report-header.sh` - Generates report header
  - `040-170-*.sh` - Various report sections (WordPress versions, PHP versions, plugins, themes, logins, etc.)

**When to modify**:
- When adding new report sections (add scripts to `generate-report-parts/`)
- When modifying report generation logic
- When adding new utility scripts

---

### `snippets/`
**Purpose**: Utility scripts and analysis tools

**Contents**:
- `plugins_using_htaccess_phpini_or_dropins.sh` - Plugin analysis utility
- `500-most-active-plugins.csv` - Sample data for plugin analysis
- `*.md` - Analysis documentation

**When to modify**: When adding one-off analysis scripts or utilities

---

## Data Directories

### `s3/` *(git-ignored)*
**Purpose**: Local copy of Loop data downloaded from S3

**Contents**: JSON files containing WordPress instance data

**Populated by**: `pnpm download-loop-data-s3`

**Size**: Can be large (hundreds of MB to GBs)

**When to clean**: Can be removed and re-downloaded anytime

---

### `generate-report/` *(git-ignored)*
**Purpose**: Generated report output directory

**Contents**:
- `generate-report.parquet` - Converted data in columnar format
- `generate-report.db` - DuckDB database
- `generate-report.md` - Markdown report
- `generate-report.pdf` - PDF report

**Populated by**: `pnpm generate-report`

**Size**: Several hundred MB (database can be large)

**When to clean**: Can be removed and regenerated anytime

---

### `duckdb/`
**Purpose**: Legacy DuckDB files and notebooks (for reference)

**Contents**:
- `ui/` - Exported notebook files
- `*.db` - Old database files
- Documentation from previous versions

**Status**: Legacy/reference material

**When to modify**: Generally not modified (use `generate-report/` instead)

---

## Working Directories *(git-ignored)*

### `plugin_temp/`
**Purpose**: Temporary directory for plugin analysis

**Contents**: Downloaded plugin files for analysis

**Created by**: Plugin analysis utilities in `snippets/`

**When to clean**: Can be removed anytime (will be recreated as needed)

---

### `plugins_using_htaccess_phpini_or_dropins_logs/`
**Purpose**: Logs from plugin analysis runs

**Contents**: Log files from plugin analysis scripts

**Created by**: `snippets/plugins_using_htaccess_phpini_or_dropins.sh`

**When to clean**: Can be removed anytime

---

## Archive Directories

### `ATTIC/`
**Purpose**: Archived legacy code and documentation

**Contents**:
- `one-shot.duckdb.sql` - Legacy SQL script
- `README-LEGACY.md` - Old documentation
- `scripts/` - Deprecated scripts
- `SNIPPETS.md` - Old code snippets

**Status**: Historical reference only

**When to modify**: Generally not modified (archived material)

---

## Node.js Directories *(git-ignored)*

### `node_modules/`
**Purpose**: Installed npm dependencies

**Contents**: Node.js packages (prettier, md-to-pdf, mermaid)

**Populated by**: `pnpm install`

**When to clean**: Run `pnpm install` to recreate

---

## Directory Summary Table

| Directory | Purpose | Git Tracked | Size | Can Delete? |
|-----------|---------|-------------|------|-------------|
| `.claude/` | Claude AI config | Yes | Small | No |
| `.gemini/` | Gemini AI config | Yes | Small | No |
| `.vscode/` | VS Code settings | Yes | Small | No |
| `docs/` | Documentation | Yes | Small | No |
| `scripts/` | Automation scripts | Yes | Small | No |
| `snippets/` | Utility scripts | Yes | Small | No |
| `s3/` | Downloaded data | **No** | Large | Yes* |
| `generate-report/` | Generated output | **No** | Large | Yes* |
| `duckdb/` | Legacy files | Partial | Medium | Use with caution |
| `plugin_temp/` | Plugin analysis temp | **No** | Large | Yes |
| `plugins_using_.../` | Analysis logs | **No** | Small | Yes |
| `ATTIC/` | Archived code | Yes | Small | Use with caution |
| `node_modules/` | npm packages | **No** | Medium | Yes* |

\* Can be regenerated by running the appropriate command

# Troubleshooting

## "s3 directory does not exist or is empty"

**Solution**: Run `pnpm download-loop-data-s3` to download the Loop data from S3 first.

## "AWS credentials not configured"

**Solution**: Create a `.secrets` file with AWS credentials (see setup section).

## Report generation fails

**Solution**:
1. Ensure Docker is running
2. Check that `./s3` directory contains JSON files
3. Run with `--verbose` flag for detailed output to see which scripts are executing:
   ```bash
   pnpm generate-report --verbose
   ```
4. Use `--dry-run` to see what would execute without running:
   ```bash
   pnpm generate-report --dry-run
   ```

## DuckDB UI won't start

**Solution**:
1. Ensure Docker is running
2. Check if port is already in use
3. If database doesn't exist, it will be auto-generated (requires `./s3` data)

## Permission errors with Docker

**Solution**: The scripts handle permissions automatically, but if issues persist:
```bash
# Fix permissions on s3 directory
docker run -v $(pwd)/s3:/local --rm library/bash -c "chmod -R a+rw /local"

# Fix permissions on generate-report directory
docker run -v $(pwd)/generate-report:/local --rm library/bash -c "chmod -R a+rw /local"
```
