#!/bin/bash

# data_collection.sh - Converts all JSON log files to a single CSV file
# Usage: ./data_collection.sh [output_file]
# Default output: logs/honeypot_data.csv

# Set default output path
DEFAULT_OUTPUT="/home/aces/HACS200_Honeypot/logs/honeypot_data.csv"
OUTPUT_FILE="${1:-$DEFAULT_OUTPUT}"

# Set logs directory
LOGS_DIR="/home/aces/HACS200_Honeypot/logs"

# Counters for statistics
TOTAL_FILES=0
PROCESSED_FILES=0
TOTAL_ENTRIES=0
FAILED_ENTRIES=0

echo "[*] Honeypot JSON to CSV Converter"
echo "[*] ================================"
echo "[*] Scanning for .log files in $LOGS_DIR"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "[ERROR] jq is not installed. Please install it first:"
    echo "        sudo apt-get install jq"
    exit 1
fi

# Find all .log files
LOG_FILES=$(find "$LOGS_DIR" -type f -name "*.log" 2>/dev/null)
TOTAL_FILES=$(echo "$LOG_FILES" | grep -c '^' 2>/dev/null || echo 0)

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "[*] No .log files found in $LOGS_DIR"
    exit 0
fi

echo "[*] Found $TOTAL_FILES log file(s)"
echo "[*] Output file: $OUTPUT_FILE"
echo ""

# Create/overwrite output file with CSV header
echo "timestamp,honeypot_name,attacker_ip,public_ip,language,login,connect_time,disconnect_time,duration,num_commands,commands,avg_time_between_commands,is_bot,is_noninteractive,disconnect_reason" > "$OUTPUT_FILE"

echo "[*] Processing log files..."

# Process each log file
while IFS= read -r log_file; do
    [ -z "$log_file" ] && continue
    
    PROCESSED_FILES=$((PROCESSED_FILES + 1))
    filename=$(basename "$log_file")
    echo "[*] [$PROCESSED_FILES/$TOTAL_FILES] Processing: $filename"
    
    # Use jq to parse multi-line JSON objects from the file
    # The -s (slurp) flag reads entire file, then we iterate over objects
    entries_converted=0
    
    # Parse JSON objects (handles both single-line and multi-line pretty-printed JSON)
    csv_lines=$(jq -r '
        # Handle both array input and single object
        if type == "array" then . else [.] end |
        .[] |
        # Escape quotes in commands array and convert to string
        .commands_str = (.commands | tostring | gsub("\""; "\"\"")) |
        
        # Build CSV line with proper escaping, using empty string for missing fields
        [
            .timestamp // "",
            .honeypot_name // "",
            .attacker_ip // "",
            .public_ip // "",
            .language // "",
            .login // "",
            .connect_time // "",
            .disconnect_time // "",
            (.duration | tostring) // "",
            (.num_commands | tostring) // "",
            .commands_str // "[]",
            .avg_time_between_commands // "",
            (.is_bot | tostring) // "",
            (.is_noninteractive | tostring) // "",
            .disconnect_reason // ""
        ] | @csv
    ' "$log_file" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$csv_lines" ]; then
        # Count entries and append to output
        entries_converted=$(echo "$csv_lines" | wc -l)
        echo "$csv_lines" >> "$OUTPUT_FILE"
        TOTAL_ENTRIES=$((TOTAL_ENTRIES + entries_converted))
        echo "    → Converted $entries_converted entries"
    else
        echo "[WARNING] Failed to parse JSON from $filename"
        FAILED_ENTRIES=$((FAILED_ENTRIES + 1))
    fi
    
done <<< "$LOG_FILES"

echo ""
echo "[*] ================================"
echo "[*] Conversion Complete!"
echo "[*] ================================"
echo "[*] Files processed: $PROCESSED_FILES"
echo "[*] Entries converted: $TOTAL_ENTRIES"
echo "[*] Failed entries: $FAILED_ENTRIES"
echo "[*] Output saved to: $OUTPUT_FILE"
echo ""

# Exit with error code if critical failure
if [ "$TOTAL_ENTRIES" -eq 0 ] && [ "$FAILED_ENTRIES" -gt 0 ]; then
    echo "[ERROR] No entries were successfully converted!"
    exit 1
fi

exit 0

