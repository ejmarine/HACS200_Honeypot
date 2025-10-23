#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <container_name> <message>"
  exit 1
fi

container_name=$1
message=$2

# Sanitize message to remove quotes
message=$(echo "$message" | tr -d '"' | tr -d "'")

# Determine which environment file to use based on container name
if [ "$container_name" = "all" ] || [ -z "$container_name" ]; then
  # Use default URL for 'all' or when no container specified
  url=$(cat /root/url.env)
else
  # Use container-specific environment file if it exists
  if [ -f "/root/${container_name}.env" ]; then
    url=$(cat /root/${container_name}.env)
  else
    # Fallback to default URL if container-specific file doesn't exist
    url=$(cat /root/url.env)
  fi
fi

# Formats the message properly
get_data_json() {
  cat <<EOF
{"icon_emoji": ":bot:", "text": "$message" }
EOF
}

# Sends the message to Slack webhook
curl -X POST -H 'Content-type: application/json; charset=utf-8' --data "$(get_data_json)" $url