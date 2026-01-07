# About

Provides tooling to explore and analyze `ionos-loop` data using DuckDB.

# Requirements

- `bash`

- `docker`

- `pnpm`

Duckdb will be started using docker so you dont need to have duckdb installed on your machine.

# Setup

- `pnpm install`

- Create a `.secrets` file and configure the AWS credentials (see the `*.example` file templates).

  - Credentials can be obtained from https://dcd.ionos.com/latest/#/key-management.

  - Log in using the "Loop User".

# Commands

## Download DuckDB database from S3

A prepared DuckDB database can be downloaded from S3.

- `pnpm download-duckdb-s3` will download the notebook and DuckDB database from S3.

## Generate report

- `pnpm generate-report`

This command generates a new report in `./generate-report`. There will be 3 files after generation is done : 

- `generate-report.parquet` the parquet file containing all loop data used for report generation

- `generate-report.db` the duckdb database used for report generation. this database is based on the data from the parquet file.

- `generate-report.md` the loop report in markdown + mermaid format

### report generation

The report parts are located in `./scripts/generate-report-parts`. They will be executed in **alphabetical** order utilizing the [run-parts](https://man.archlinux.org/man/run-parts.8.en) command. 

> Each script located in `./scripts/generate-report-parts` must be executable. So you need to make it executable using `chmod +x ...` (or copy an existing one which is already executable).

The output of all scripts will be collected together into `./generate-report/generate-report.md` (Output will also be displayed in the terminal). 

### How to add new insights to the report

- choose where the new insight should appear in the report (remember report parts will be executed in alphabetical order). 

  An example : If you want your new insight beween `./scripts/generate-report-parts/050-php_versions.sh` and `./scripts/generate-report-parts/060-most-active-plugins.sh` you can name the script `./scripts/generate-report-parts/055-my-new-insight.sh`

  To append your new report part as last simply name it `<last used number + 1>-my-new-insight.sh` 

  > Your report part should be at positioned after `./scripts/generate-report-parts/030-generate-report-header.sh` which creates markdown report header.

- Make the script executable using `chmod +x ./scripts/generate-report-parts/055-my-new-insight.sh`

- To check everything is ok until this point enter the following content into the script 

  ```sh
  #!/usr/bin/env bash
  #
  # (name your insight purpose here) 
  # generates markdown output for my new insight
  # 

  readonly SQL=$(cat <<EOF
  -- select the 3 first rows of the loop_items table
  SELECT * from loop_items LIMIT 3;
  EOF

  readonly TITLE="My new insight"

  cat <<EOF
  # $TITLE

  $(echo $(ionos.loop-duckdb.exec_duckdb "$SQL" '-markdown'))
  EOF
  ```

  This skeleton will query the first 3 rows of table `loop_items` and will output the results as markdown table.
  
  > table `loop_items` contains all collected loop items

- start the report generation using `pnpm generate-report`

  The output should contain the output of your script at the desired location.

- Now the tricky part - how do you formulate your query ? 

  - Have a look at the loop json data files to get a clue about the data and structure.

  - open the Duckdb UI using `pnpm start-report-ui` and have a loom at the prepopulated tables to find the one fitting your needs. 

  - Now the real vibe coding trick making your life a lot more easier : copy the structure and **a few(!)** sample data from the duckdb ui into Gemini or whatever AI you prefer and ask the AI to generate the select statement matching your question.

  Example prompt:

  ```
  You are a DuckDB expert.

  I have a table `[paste table name here]` with the following structure:

  [paste table structure here]

  Here are some sample data in csv format:

  [paste the csv sample table data here]

  [your question here]
  ```

  It will work surprisingly good - trust me.
  
  - Check if the generated statement **might match* what you want.

  - Copy it over to the DuckDB UI and execute it their as the next check. 

  - If it feels good - enter it into variable SQL in your script and regenerate the report using `pnpm generate report`

    - if not instruct the AI to improve the generated query

**Have a look at the existing report parts to get a clue to output a table.**

### How to run only your report part

To run your only your own report script called `200-my-own-insight.sh` : 

- Head over to `./scripts/generate-report.sh` and change the `run-parts` command from

  `$(run-parts --regex '^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9]+)?$' ./scripts/${REPORT_NAME}-parts)`

  to 

  `$(run-parts --regex '^200-[a-zA-Z0-9_-]+(\.[a-zA-Z0-9]+)?$' ./scripts/${REPORT_NAME}-parts)`

  This will force `run-parts` to only run commands starting with `200-` - Gotcha !

### How to skip a single report part

Go into the report file and insert `exit` right before the first command. That's it !

## Develop sql in duckdb for report generation

The `pnpm generate-report` command will generate a duckdb database. 

Using command `pnpm start-report-ui` will start duckdb using the `./generate-report/generate-report.db` database generated by the `pnpm generate-report` command. You can open the browser based user interface of duckdb to play around and dig into the collected loop data.

## Duckdb MCP support

You need to install `uv` using `curl -LsSf https://astral.sh/uv/install.sh | sh` in order to have access to duckdb in gemini / copilot.