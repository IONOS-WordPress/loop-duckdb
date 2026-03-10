#!/usr/bin/env bash

#
# generates CSV report with plugin versions and instance counts
#

readonly SQL="
WITH
  _plugin_versions AS (
    SELECT
      plugins.plugin.plugin_slug as plugin,
      CAST(plugins.plugin."version" AS VARCHAR) as version,
      plugins.instance
    FROM
      plugins
      JOIN recent_loops ON plugins.filename = recent_loops.filename
  )
SELECT
  plugin,
  version,
  COUNT(DISTINCT instance) AS instance_count
FROM
  _plugin_versions
WHERE
  plugin NOT LIKE 'ionos-%'
GROUP BY
  plugin,
  version
ORDER BY
  plugin ASC,
  version ASC,
  instance_count DESC
"

readonly CSV_EXPORT_SQL="
.mode csv
.header on
.output ${REPORT_NAME}/plugin_versions_by_instance.csv
$(echo "$SQL")
"

readonly REPORT_NAME="${REPORT_NAME:-generate-report}"
readonly CSV_OUTPUT="${REPORT_NAME}/plugin_versions_by_instance.csv"
readonly TITLE="Plugin Versions by Instance Count"

ionos.loop-duckdb.exec_duckdb "$SQL" '-csv' > "$CSV_OUTPUT"
