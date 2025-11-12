#!/usr/bin/env bash

#
# generate report header
#

min_max=$(ionos.loop-duckdb.exec_duckdb "
  SELECT 
    STRFTIME(MIN(timestamp), '%Y-%m-%d %H:%M:%S') AS min, 
    STRFTIME(MAX(timestamp), '%Y-%m-%d %H:%M:%S') AS max 
  FROM loop_items;
" '-json')

cat <<EOF 
---
title: IONOS Loop Usage Report
author: WordPress Hosting Team
creation date: $(date +'%Y-%m-%d %H:%M')
time period: $(jq -r '.[0] | "\(.min) - \(.max)"' <<< "$min_max")
---
EOF