# About

Provides tooling to explore and analyze `ionos-loop` data using DuckDB.

# Setup

- Create a `.env` and a `.secrets` file and configure the AWS credentials (see the `*.example` file templates).

  - Credentials can be obtained from https://dcd.ionos.com/latest/#/key-management.

  - Log in using the "Loop User".

# Commands

## Download DuckDB database from S3

A prepared DuckDB database can be downloaded from S3.

- `pnpm download-duckdb-s3` will download the notebook and DuckDB database from S3.

## Start DuckDB

- To start using DuckDB, you will need the data populated in a DuckDB database. There are various ways to get started:

  - Use the latest DuckDB Loop database from S3: see Download DuckDB database from S3.

    This is the preferred way to start. This command will download the Loop DuckDB database and the prepared DuckDB notebook.

  - Build the DuckDB data from scratch: see Download S3 Loop data.

- Enter the DuckDB environment to do some research: `pnpm start`

  You can interact with DuckDB using the terminal or the web UI.

  - Open http://localhost:4213/ in your browser. The browser UI supports persistent dickdb notebooks.

  - DuckDB can be gracefully shut down using `Ctrl+D`.

> Notebooks are preserved between launches in the `./duckdb/ui{.db,.wal}` files.

## (Optional) Export duckdb notebooks

To have the duckdb notebooks version in Git you can use `pnpm export-duckdb-notebooks`.

This will export the duckdb ui database to plain files versioned using GIT.

## (Optional) Import notebooks 

Notebooks contain prepared sql snippets for data evaluation.

They are kept in the repo as serialized files in `duckdb/ui`.

You can populate the duckdb ui database using `pnpm import-duckdb-notebooks`.

## (Optional) Upload DuckDB database to S3

The DuckDB database and notebooks can be shared using S3.

- `pnpm upload-duckdb-s3` will upload the notebook and DuckDB database to S3.

## (Optional) Recreate DuckDB database from S3 Loop data

If you want to recreate the DuckDB database from the latest Loop data:

  - Fetch the Loop data to your local machine: `pnpm start`

    This may take several hours to complete.
