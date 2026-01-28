# About

Skills extend AI client capabilities

# MCP servers

The MCP server `duckdb` is able to operate on the report database `generate-report/generate-report.db`

```json
"duckdb": {
  "command": "uvx",
  "args": [
    "mcp-server-duckdb",
    "--db-path",
    "generate-report/generate-report.db",
    "--readonly"
  ]
}
```

# Cloude Code

## configuration

- `.claude/settings.json` : project specific settings

- `.claude/CLAUDE.md` : claude specific `AGENTS.md` wrapper

- `.mcp.json` : project specific MCP servers, at least the `chrome-devtools` mcp server

# Gemini CLI

# configuration

`.gemini/settings.json` :

`.gemini/skills` are directly linked from `docs/skills`

# vscode copilot

- `.mcp.json` : project specific MCP servers, at least the `chrome-devtools` mcp server

Skills will be derived by vscode/copilot from the claude/gemini settings and given project structure.

## Usage

see docs/ai-integration.md
