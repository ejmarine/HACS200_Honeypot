#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <message>"
  exit 1
fi

message=$1

echo "[*] Sending message to Slack: $message"

token=$(cat token.env)

channel="C09LR132PA7"

get_data_json() {
  cat <<EOF
{ "channel": "$channel", "icon_emoji": ":bot:", "text": "$message" }
EOF
}

curl -X POST -H 'Content-type: application/json; charset=utf-8' --data "$(get_data_json)" $token

echo "Message sent to Slack"
