#!/bin/bash

# Script to analyze WordPress plugins for specific characteristics.

# Check if a CSV file is provided as an argument.
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_csv_file>"
  exit 1
fi

CSV_FILE="$1"
# Create a directory for logs if it doesn't exist.
LOG_DIR="plugins_using_htaccess_phpini_or_dropins_logs"
mkdir -p "$LOG_DIR"
# Define the main log file.
LOG_FILE="$LOG_DIR/analysis_results.log"
# Define the CSV output file.
CSV_OUTPUT_FILE="$LOG_DIR/analysis_results.csv"
# Temporary directory for downloading and extracting plugins (used as a cache).
TMP_DIR="plugin_temp"
mkdir -p "$TMP_DIR"

# List of known WordPress drop-in files.
# See: https://wordpress.org/documentation/article/must-use-plugins/
DROP_INS=(
  "advanced-cache.php"
  "db.php"
  "db-error.php"
  "install.php"
  "maintenance.php"
  "object-cache.php"
  "php-error.php"
  "fatal-error-handler.php"
  "sunrise.php"
  "blog-deleted.php"
  "blog-inactive.php"
  "blog-suspended.php"
)

# Clear the log and CSV files before starting.
> "$LOG_FILE"
> "$CSV_OUTPUT_FILE"

# Write the header to the CSV file.
echo "slug,writes_htaccess,writes_phpini,acts_as_dropin" > "$CSV_OUTPUT_FILE"

# Read the CSV file, skipping the header row.
# Assumes the plugin slug is in the first column.
tail -n +2 "$CSV_FILE" | while IFS=, read -r slug_path rest; do
  # Extract the plugin slug from the path.
  plugin_slug=$(echo "$slug_path" | cut -d'/' -f1 | tr -d '"')

  if [ -z "$plugin_slug" ]; then
    echo "Skipping empty plugin slug." | tee -a "$LOG_FILE"
    continue
  fi

  echo "Analyzing plugin: $plugin_slug" | tee -a "$LOG_FILE"

  PLUGIN_DIR="$TMP_DIR/$plugin_slug"

  # Check if the plugin is already extracted (cached).
  if [ -d "$PLUGIN_DIR" ] && [ -n "$(ls -A "$PLUGIN_DIR")" ]; then
    echo "  - Using cached and extracted version of $plugin_slug" | tee -a "$LOG_FILE"
  else
    # If not cached, download and extract it.
    DOWNLOAD_URL="https://downloads.wordpress.org/plugin/${plugin_slug}.zip"
    ZIP_FILE="$TMP_DIR/${plugin_slug}.zip"

    if ! wget -q -O "$ZIP_FILE" "$DOWNLOAD_URL"; then
      echo "  - Failed to download $plugin_slug" | tee -a "$LOG_FILE"
      continue
    fi

    mkdir -p "$PLUGIN_DIR"
    if ! unzip -q -d "$PLUGIN_DIR" "$ZIP_FILE"; then
      echo "  - Failed to unzip $plugin_slug" | tee -a "$LOG_FILE"
      rm "$ZIP_FILE" # Remove corrupted zip file
      continue
    fi

    # Remove the zip file after successful extraction to only cache the directory.
    rm "$ZIP_FILE"
  fi

  # --- Analysis ---
  writes_htaccess="No"
  writes_phpini="No"
  acts_as_dropin="No"

  # 1. Check for .htaccess modifications.
  if grep -r -i -q -E --include='*.php' "\.htaccess['\"]" "$PLUGIN_DIR"; then
    writes_htaccess="Yes"
  fi
  echo "  - Writes to .htaccess: $writes_htaccess" | tee -a "$LOG_FILE"

  # 2. Check for php.ini modifications.
  if grep -r -i -q -E --include='*.php' "php\.ini['\"]" "$PLUGIN_DIR"; then
    writes_phpini="Yes"
  fi
  echo "  - Writes to php.ini: $writes_phpini" | tee -a "$LOG_FILE"

  # 3. Check for drop-in files.
  for drop_in in "${DROP_INS[@]}"; do
    # Find files with the drop-in name within the plugin's directory.
    if find "$PLUGIN_DIR" -type f -name "$drop_in" | read -r; then
      acts_as_dropin="Yes"
      echo "  - Acts as a drop-in: Yes (found $drop_in)" | tee -a "$LOG_FILE"
      break
    fi
  done

  if [ "$acts_as_dropin" = "No" ]; then
    echo "  - Acts as a drop-in: No" | tee -a "$LOG_FILE"
  fi

  # --- CSV Output ---
  echo "$plugin_slug,$writes_htaccess,$writes_phpini,$acts_as_dropin" >> "$CSV_OUTPUT_FILE"

  echo "" | tee -a "$LOG_FILE"

done

echo "Analysis complete. Results are in $LOG_FILE and $CSV_OUTPUT_FILE"
