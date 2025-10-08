COPY current_notebook_id FROM '/local/duckdb/ui/current_notebook_id.json' (FORMAT 'json');
COPY has_onboarded FROM '/local/duckdb/ui/has_onboarded.json' (FORMAT 'json');
COPY notebooks FROM '/local/duckdb/ui/notebooks.json' (FORMAT 'json');
COPY notebook_versions FROM '/local/duckdb/ui/notebook_versions.json' (FORMAT 'json');
