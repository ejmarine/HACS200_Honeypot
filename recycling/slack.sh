#!/bin/bash

token=$(cat token.env)

channel="C09LR132PA7"

curl -X POST \
    -H 'Content-type: application/json; charset=utf-8' \
    --data '{ "channel": "'$channel'", "icon_emoji": ":bot:", "text": "Foo" }' \
    $token

echo "Message sent to Slack"
