#!/bin/bash

# jsonify.sh - Script to append honeypot data to a JSON file
# Usage: ./jsonify.sh <json_file_path> <language> <num_commands> <commands_array> <attacker_ip> <connect_time> <disconnect_time> <duration> <honeypot_name> <public_ip>

# Check if minimum required arguments are provided
if [ $# -lt 11 ]; then
    echo "Usage: $0 <json_file_path> <language> <num_commands> <commands_array> <attacker_ip> <connect_time> <disconnect_time> <duration> <honeypot_name> <public_ip> <login>"
    echo "Example: $0 data.json 'English' 3 '[\"ls\",\"pwd\",\"whoami\"]' '192.168.1.100' '2024-01-01T10:00:00Z' '2024-01-01T10:05:00Z' '5m' 'honeypot-01' '203.0.113.42'"
    exit 1
fi

JSON_FILE="$1"
LANGUAGE="$2"
NUM_COMMANDS="$3"
COMMANDS_ARRAY="$4"
ATTACKER_IP="$5"
CONNECT_TIME="$6"
DISCONNECT_TIME="$7"
DURATION="$8"
HONEYPOT_NAME="$9"
PUBLIC_IP="${10}"
LOGIN="${11}"
# Create JSON file if it doesn't exist
if [ ! -f "$JSON_FILE" ]; then
    echo "[]" > "$JSON_FILE"
fi

# Create the JSON entry
JSON_ENTRY=$(cat <<EOF
{
  "language": "$LANGUAGE",
  "num_commands": $NUM_COMMANDS,
  "commands": $COMMANDS_ARRAY,
  "attacker_ip": "$ATTACKER_IP",
  "connect_time": "$CONNECT_TIME",
  "disconnect_time": "$DISCONNECT_TIME",
  "duration": "$DURATION",
  "honeypot_name": "$HONEYPOT_NAME",
  "public_ip": "$PUBLIC_IP",
  "login": "$LOGIN",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

echo "$JSON_ENTRY" >> "$JSON_FILE"