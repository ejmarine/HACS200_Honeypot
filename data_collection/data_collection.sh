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
    
    # Create temporary files
    ERROR_FILE=$(mktemp)
    FIXED_FILE=$(mktemp)
    
    # Try to fix common JSON malformations in the file
    # This handles legacy logs with unquoted commands and trailing commas
    if command -v python3 &> /dev/null; then
        python3 -c '
import sys
import re

content = open("'"$log_file"'", "r").read()

# Fix 1: Remove trailing commas before closing brackets/braces
content = re.sub(r",(\s*[\]}])", r"\1", content)

# Fix 2: Quote unquoted strings in commands array (handles multiple commands)
def fix_commands(match):
    prefix = match.group(1)
    array_content = match.group(2).strip()
    
    if not array_content:
        return match.group(0)  # Empty array, no change needed
    
    # If content already starts with quote, assume its properly formatted
    if array_content.startswith("\""):
        return match.group(0)
    
    # Split by comma and quote each element
    # Handle cases like: echo '"'"'test'"'"', ls, pwd
    commands = []
    current = ""
    in_quotes = False
    quote_char = None
    
    for char in array_content:
        if char in ("'"'"'", "\"") and (not in_quotes or char == quote_char):
            in_quotes = not in_quotes
            quote_char = char if in_quotes else None
            current += char
        elif char == "," and not in_quotes:
            if current.strip():
                # Escape any double quotes in the command
                cmd = current.strip().replace("\\", "\\\\").replace("\"", "\\\"")
                commands.append("\"" + cmd + "\"")
            current = ""
        else:
            current += char
    
    # Add the last command
    if current.strip():
        cmd = current.strip().replace("\\", "\\\\").replace("\"", "\\\"")
        commands.append("\"" + cmd + "\"")
    
    if commands:
        return prefix + "[" + ", ".join(commands) + "]"
    return match.group(0)

content = re.sub(r"(\"commands\":\s*\[)\s*([^\]]+?)\s*\]", fix_commands, content, flags=re.DOTALL)

print(content, end="")
' > "$FIXED_FILE" 2>/dev/null
    else
        # Fallback: just remove trailing commas with sed
        sed 's/,\s*\]/]/g' "$log_file" > "$FIXED_FILE"
    fi
    
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
    ' "$FIXED_FILE" 2>"$ERROR_FILE")
    
    jq_exit_code=$?
    
    if [ $jq_exit_code -eq 0 ] && [ -n "$csv_lines" ]; then
        # Count entries and append to output
        entries_converted=$(echo "$csv_lines" | wc -l)
        echo "$csv_lines" >> "$OUTPUT_FILE"
        TOTAL_ENTRIES=$((TOTAL_ENTRIES + entries_converted))
        echo "    → Converted $entries_converted entries"
    else
        # Check if file is empty
        if [ ! -s "$log_file" ]; then
            echo "[WARNING] Skipped $filename (empty file)"
        else
            echo "[WARNING] Failed to parse JSON from $filename"
            
            # Show the specific error from jq
            if [ -s "$ERROR_FILE" ]; then
                error_msg=$(head -n 1 "$ERROR_FILE")
                echo "    ├─ Error: $error_msg"
            fi
            
            # Show file size and first few lines to help debug
            file_size=$(wc -c < "$log_file")
            first_line=$(head -n 1 "$log_file" | cut -c1-80)
            echo "    ├─ File size: $file_size bytes"
            echo "    └─ First line: $first_line"
        fi
        FAILED_ENTRIES=$((FAILED_ENTRIES + 1))
    fi
    
    # Clean up temp files
    rm -f "$ERROR_FILE" "$FIXED_FILE"
    
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

