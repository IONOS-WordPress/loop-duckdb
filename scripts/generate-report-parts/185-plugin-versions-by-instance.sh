#!/usr/bin/env bash

set -euo pipefail

REPORT_NAME="${REPORT_NAME:-generate-report}"
CSV_OUTPUT="$REPORT_NAME/plugin_versions_by_instance.csv"
TITLE="Plugin-Versionen nach Instanz (nur aktuellste, ≥500 Instanzen)"

mkdir -p "$REPORT_NAME"

# SQL für Plugin-Versionen mit Prozent-Spalte
SQL="
WITH total_instances AS (
  SELECT COUNT(DISTINCT recent_loops.instance) AS total FROM recent_loops
),
numbered_plugins AS (
  SELECT
    ROW_NUMBER() OVER (
      ORDER BY COUNT(DISTINCT recent_loops.instance) DESC, plugins.plugin.plugin_slug ASC
    ) AS nr,
    plugins.plugin.plugin_slug AS plugin,
    CAST(plugins.plugin.version AS VARCHAR) AS version,
    COUNT(DISTINCT recent_loops.instance) AS instance_count,
    ROUND(COUNT(DISTINCT recent_loops.instance) * 100.0 / (SELECT total FROM total_instances), 2) AS percentage
  FROM plugins
  JOIN recent_loops
    ON plugins.filename = recent_loops.filename
  WHERE plugins.plugin.plugin_slug NOT LIKE '01-ext-%'
  GROUP BY plugin, version
  HAVING COUNT(DISTINCT recent_loops.instance) >= 500
)
SELECT *
FROM numbered_plugins
ORDER BY nr;
"

# CSV export
ionos.loop-duckdb.exec_duckdb "$SQL" '-csv' > "$CSV_OUTPUT"

# Markdown-Report
cat <<EOF
# $TITLE

| # | Plugin | Version | Instanzanzahl | Anteil an Instanzen (%) |
|---|--------|---------|---------------|------------------------|
$(ionos.loop-duckdb.exec_duckdb "$SQL;" '-markdown')

**Hinweis:**  
01-ext-Plugins sind ausgeschlossen.  
Es werden nur Plugin-Versionen berücksichtigt, die auf **mindestens 500 Instanzen** installiert sind.

---

Die vollständigen Daten sind als CSV exportiert:  
\`$CSV_OUTPUT\`
EOF