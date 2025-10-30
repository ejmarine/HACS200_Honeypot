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
echo "timestamp,honeypot_name,attacker_ip,public_ip,language,login,connect_time,disconnect_time,duration_ms,num_commands,commands,avg_time_between_commands,is_bot,is_noninteractive,disconnect_reason" > "$OUTPUT_FILE"

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

with open("'"$log_file"'", "r") as f:
    content = f.read()

# Fix 1: Remove trailing commas before closing brackets/braces
content = re.sub(r",(\s*[\]}])", r"\1", content)

# Fix 2: Quote unquoted strings in commands array (handles multiple commands)
# Process line by line to avoid corrupting other fields
def fix_commands_line(line):
    # Only process lines that contain "commands":
    if "\"commands\":" not in line:
        return line
    
    # Match the commands array on this line only (not multiline)
    match = re.search(r"\"commands\":\s*\[([^\]]*)\]", line)
    if not match:
        return line
    
    array_content = match.group(1).strip()
    
    # If array is empty, just ensure no trailing comma in array
    if not array_content:
        return re.sub(r"\"commands\":\s*\[\s*\],?", "\"commands\": [],", line)
    
    # Remove trailing comma from array content if present
    if array_content.endswith(","):
        array_content = array_content[:-1].strip()
    
    # Split by comma and quote each unquoted element
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
                cmd = current.strip().rstrip(",")
                # If already quoted, remove quotes and re-escape properly
                if cmd.startswith("\"") and cmd.endswith("\"") and len(cmd) > 2:
                    cmd = cmd[1:-1]
                    cmd = cmd.replace("\\\"", "QUOTE_PLACEHOLDER")
                    cmd = cmd.replace("\\", "\\\\")
                    cmd = cmd.replace("QUOTE_PLACEHOLDER", "\\\"")
                    cmd = "\"" + cmd + "\""
                elif not (cmd.startswith("\"") and cmd.endswith("\"")):
                    cmd = cmd.replace("\\", "\\\\").replace("\"", "\\\"")
                    cmd = "\"" + cmd + "\""
                commands.append(cmd)
            current = ""
        else:
            current += char
    
    # Add the last command
    if current.strip():
        cmd = current.strip().rstrip(",")
        # If already quoted, remove quotes and re-escape properly
        if cmd.startswith("\"") and cmd.endswith("\"") and len(cmd) > 2:
            # Remove outer quotes
            cmd = cmd[1:-1]
            # Un-escape quotes first (\" becomes ")
            cmd = cmd.replace("\\\"", "QUOTE_PLACEHOLDER")
            # Now escape all backslashes properly
            cmd = cmd.replace("\\", "\\\\")
            # Restore and properly escape quotes
            cmd = cmd.replace("QUOTE_PLACEHOLDER", "\\\"")
            # Re-wrap
            cmd = "\"" + cmd + "\""
        elif not (cmd.startswith("\"") and cmd.endswith("\"")):
            # Not quoted at all, escape and quote
            cmd = cmd.replace("\\", "\\\\").replace("\"", "\\\"")
            cmd = "\"" + cmd + "\""
        commands.append(cmd)
    
    # Build the fixed line
    if commands:
        fixed_line = re.sub(r"\"commands\":\s*\[[^\]]*\]", 
                           "\"commands\": [" + ", ".join(commands) + "]", line)
    else:
        fixed_line = re.sub(r"\"commands\":\s*\[[^\]]*\]", "\"commands\": []", line)
    
    return fixed_line

# Process line by line
lines = content.split("\n")
fixed_lines = [fix_commands_line(line) for line in lines]
content = "\n".join(fixed_lines)

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
        # Handle both old "duration" and new "duration_ms" fields
        .duration_value = (if .duration_ms then .duration_ms else .duration end) |
        
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
            (.duration_value | tostring) // "",
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
            
            # Show original vs fixed content for debugging
            echo "    ├─ Original commands line:"
            grep "\"commands\":" "$log_file" 2>/dev/null | head -n 1 | sed 's/^/    │  /' || echo "    │  (not found)"
            echo "    ├─ After Python fix:"
            if [ -f "$FIXED_FILE" ]; then
                grep "\"commands\":" "$FIXED_FILE" 2>/dev/null | head -n 1 | sed 's/^/    │  /' || echo "    │  (not found)"
                echo "    ├─ Fixed file first 10 lines:"
                head -n 10 "$FIXED_FILE" | cat -A | sed 's/^/    │  /'
            else
                echo "    │  (FIXED_FILE not created)"
            fi
            
            # Show file size
            file_size=$(wc -c < "$log_file")
            echo "    └─ Original file size: $file_size bytes"
            
            # Keep failed files for debugging
            if [ -f "$FIXED_FILE" ]; then
                DEBUG_FILE="/tmp/honeypot_debug_$(basename "$log_file").fixed"
                cp "$FIXED_FILE" "$DEBUG_FILE" 2>/dev/null
                echo "    └─ Debug: Saved fixed file to $DEBUG_FILE"
            fi
        fi
        FAILED_ENTRIES=$((FAILED_ENTRIES + 1))
    fi
    
    # Clean up temp files (keep ERROR_FILE and FIXED_FILE for debugging if failed)
    if [ $jq_exit_code -eq 0 ]; then
        rm -f "$ERROR_FILE" "$FIXED_FILE"
    else
        rm -f "$ERROR_FILE"  # Keep FIXED_FILE for debugging
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

