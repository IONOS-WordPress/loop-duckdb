#!/usr/bin/env bash

#
# generates security settings related questions markdown output for "Security Settings"
# Individual % on/off for each setting
# % of Customers still on the default 
# Table: Setting | % on 
# 

SQL=$(cat <<EOF
WITH unique_instance_data AS (
  -- 1. Select distinct instances to avoid counting duplicates
  SELECT DISTINCT
    instance,
    -- Extract the boolean value for each security setting.
    -- We compare the extracted JSON fragment (which is 'true' or 'false') to 'true'.
    (hosting->'tenant') AS tenant, -- Optionally include tenant for context/filtering
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_XMLRPC')::BOOLEAN AS xmlrpc_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_PEL')::BOOLEAN AS pel_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_CREDENTIALS_CHECKING')::BOOLEAN AS credentials_checking_enabled,
    (plugin_data->'ionos-essentials'->'security'->>'IONOS_SECURITY_FEATURE_OPTION_MAIL_NOTIFY')::BOOLEAN AS mail_notify_enabled
  FROM loop_items
),
metrics AS (
  -- 2. Calculate the total unique instances and the count of 'true' values for each setting
  SELECT
    COUNT(instance) AS total_instances,
    SUM(CASE WHEN xmlrpc_enabled IS TRUE THEN 1 ELSE 0 END) AS xmlrpc_count,
    SUM(CASE WHEN pel_enabled IS TRUE THEN 1 ELSE 0 END) AS pel_count,
    SUM(CASE WHEN credentials_checking_enabled IS TRUE THEN 1 ELSE 0 END) AS credentials_checking_count,
    SUM(CASE WHEN mail_notify_enabled IS TRUE THEN 1 ELSE 0 END) AS mail_notify_count
  FROM unique_instance_data
)
-- 3. Pivot the results and calculate the final percentage
SELECT 'IONOS_SECURITY_FEATURE_OPTION_XMLRPC' AS setting, (xmlrpc_count * 100.0 / total_instances) AS percentage
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_PEL', (pel_count * 100.0 / total_instances)
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_CREDENTIALS_CHECKING', (credentials_checking_count * 100.0 / total_instances)
  FROM metrics
  UNION ALL
SELECT 'IONOS_SECURITY_FEATURE_OPTION_MAIL_NOTIFY', (mail_notify_count * 100.0 / total_instances)
  FROM metrics;
EOF
)

readonly TITLE="Security settings"

cat <<EOF
# $TITLE

$(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))
EOF


