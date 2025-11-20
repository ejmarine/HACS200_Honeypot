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

# Function to extract timestamp from log line (returns: "YYYY-MM-DD HH:MM:SS.MS")
extract_timestamp() {
    echo "$1" | awk '{print $1, $2}'
}

# Function to convert timestamp to milliseconds since epoch
timestamp_to_ms() {
    local timestamp="$1"
    # Split into date, time, and milliseconds
    local date_part=$(echo "$timestamp" | cut -d' ' -f1)
    local time_part=$(echo "$timestamp" | cut -d' ' -f2 | cut -d'.' -f1)
    local ms_part=$(echo "$timestamp" | cut -d' ' -f2 | cut -d'.' -f2)
    
    local seconds=$(date -d "$date_part $time_part" +%s)
    local total_ms=$((seconds * 1000 + 10#$ms_part))
    echo "$total_ms"
}

# Calculate time from attacker connection to last command in .out file
# Returns milliseconds, or 0 if no commands found
calculate_mitm_time_to_last_command() {
    local out_file="$1"
    
    # Check if file exists
    if [ ! -f "$out_file" ]; then
        echo "0"
        return
    fi
    
    # Find the attacker connection timestamp
    local connection_line=$(grep "Attacker connected:" "$out_file" | head -n 1)
    if [ -z "$connection_line" ]; then
        echo "0"
        return
    fi
    local connect_timestamp=$(extract_timestamp "$connection_line")
    local connect_ms=$(timestamp_to_ms "$connect_timestamp" 2>/dev/null)
    if [ -z "$connect_ms" ]; then
        echo "0"
        return
    fi
    
    # Find the last command timestamp (either pattern)
    local last_command_line=$(grep -E "line from reader:|Noninteractive mode attacker command:" "$out_file" | tail -n 1)
    if [ -z "$last_command_line" ]; then
        echo "0"
        return
    fi
    local last_cmd_timestamp=$(extract_timestamp "$last_command_line")
    local last_cmd_ms=$(timestamp_to_ms "$last_cmd_timestamp" 2>/dev/null)
    if [ -z "$last_cmd_ms" ]; then
        echo "0"
        return
    fi
    
    # Calculate difference
    local time_diff=$((last_cmd_ms - connect_ms))
    echo "$time_diff"
}

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
echo "timestamp,honeypot_name,attacker_ip,public_ip,language,login,connect_time,disconnect_time,duration_ms,num_commands,commands,avg_time_between_commands,is_bot,is_noninteractive,disconnect_reason,time_to_last_command_ms" > "$OUTPUT_FILE"

echo "[*] Processing log files..."

# Process each log file
while IFS= read -r log_file; do
    [ -z "$log_file" ] && continue
    
    PROCESSED_FILES=$((PROCESSED_FILES + 1))
    filename=$(basename "$log_file")
    echo "[*] [$PROCESSED_FILES/$TOTAL_FILES] Processing: $filename"
    
    # Calculate MITM time to last command from corresponding .out file
    out_file="${log_file%.log}.out"
    mitm_time_to_last_cmd=$(calculate_mitm_time_to_last_command "$out_file")
    echo "    → MITM time to last command: ${mitm_time_to_last_cmd}ms"
    
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
    csv_lines=$(jq --arg mitm_time "$mitm_time_to_last_cmd" -r '
        # Handle both array input and single object
        if type == "array" then . else [.] end |
        .[] |
        # Escape quotes in commands array and convert to string
        .commands_str = (.commands | tostring | gsub("\""; "\"\"")) |
        # Handle both old "duration" and new "duration_ms" fields
        .duration_value = (if .duration_ms then .duration_ms else .duration end) |
        # Add the MITM time from bash variable
        .time_to_last_command_ms = $mitm_time |
        
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
            .disconnect_reason // "",
            .time_to_last_command_ms // "0"
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
echo "[*] Running Data Validation..."
echo "[*] ================================"

# Run Python validation and cleanup on the generated CSV
if command -v python3 &> /dev/null; then
    VALIDATION_LOG="data_collection/data_validation_errors.log"
    VALIDATION_STATS=$(python3 -c '
import csv
import json
import ast
import sys
from datetime import datetime

csv_file = "'"$OUTPUT_FILE"'"
validation_log = "'"$VALIDATION_LOG"'"

# Statistics counters
commands_split_count = 0
duration_errors = 0
num_commands_mismatches = 0
total_rows_processed = 0

# Read CSV
rows = []
try:
    with open(csv_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        
        for row in reader:
            total_rows_processed += 1
            modified = False
            
            # === 1. VALIDATE DURATION ===
            try:
                duration_ms = int(row["duration_ms"]) if row["duration_ms"] else 0
                if duration_ms < 0 or duration_ms > 600000:
                    # Log the error
                    with open(validation_log, "a", encoding="utf-8") as log_f:
                        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        log_entry = f"[{timestamp}] INVALID DURATION: {duration_ms}ms | Row: {row[\"timestamp\"]} | Honeypot: {row[\"honeypot_name\"]} | IP: {row[\"attacker_ip\"]}\n"
                        log_f.write(log_entry)
                    duration_errors += 1
            except (ValueError, KeyError):
                pass  # Keep original value if parsing fails
            
            # === 2. SPLIT COMMANDS BY SEMICOLONS ===
            try:
                # Parse the commands field (stored as string representation of array)
                commands_str = row.get("commands", "[]")
                
                # Handle CSV escaping: double quotes are escaped as ""
                commands_str = commands_str.replace("\"\"", "\"")
                
                # Parse the JSON array
                try:
                    commands = json.loads(commands_str)
                except json.JSONDecodeError:
                    # Fallback: try using ast.literal_eval
                    try:
                        commands = ast.literal_eval(commands_str)
                    except:
                        commands = []
                
                # Split each command by semicolons and flatten
                new_commands = []
                for cmd in commands:
                    if isinstance(cmd, str) and ";" in cmd:
                        # Split by semicolon and strip whitespace
                        parts = [part.strip() for part in cmd.split(";")]
                        # Filter out empty strings
                        parts = [p for p in parts if p]
                        new_commands.extend(parts)
                        commands_split_count += 1
                    else:
                        new_commands.append(cmd)
                
                # === 3. ENSURE NUM_COMMANDS MATCHES ARRAY LENGTH ===
                actual_num_commands = len(new_commands)
                original_num_commands = int(row["num_commands"]) if row["num_commands"] else 0
                
                if actual_num_commands != original_num_commands:
                    num_commands_mismatches += 1
                
                # Update the row
                row["num_commands"] = str(actual_num_commands)
                row["commands"] = json.dumps(new_commands).replace("\"", "\"\"")  # Re-escape for CSV
                
            except Exception as e:
                # If parsing fails, leave the row as-is
                pass
            
            rows.append(row)
    
    # Write back the updated CSV
    with open(csv_file, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    # Output statistics as a parseable format
    print(f"{total_rows_processed},{commands_split_count},{duration_errors},{num_commands_mismatches}")
    
except Exception as e:
    print(f"0,0,0,0")
    sys.exit(1)
' 2>/dev/null)

    # Parse validation statistics
    if [ -n "$VALIDATION_STATS" ]; then
        IFS=',' read -r VALIDATED_ROWS COMMANDS_SPLIT DURATION_ERRORS NUM_COMMAND_FIXES <<< "$VALIDATION_STATS"
        
        echo "[*] Validation complete!"
        echo "    → Rows validated: $VALIDATED_ROWS"
        echo "    → Commands split by semicolons: $COMMANDS_SPLIT"
        echo "    → Duration errors found: $DURATION_ERRORS"
        echo "    → num_commands mismatches fixed: $NUM_COMMAND_FIXES"
        
        if [ "$DURATION_ERRORS" -gt 0 ]; then
            echo "    → Duration errors logged to: $VALIDATION_LOG"
        fi
    else
        echo "[WARNING] Validation encountered an error"
    fi
else
    echo "[WARNING] Python3 not found, skipping validation"
fi

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

