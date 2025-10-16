#!/bin/bash

token=$(cat token.env)

channel="C09LR132PA7"

curl -X POST -H "Authorization: Bearer $token" \
     -H "Content-Type: application/json" \
     --data '{"channel":"'$channel'","text":"Hello from curl!"}' \
     https://slack.com/api/chat.postMessage

echo "Message sent to Slack"