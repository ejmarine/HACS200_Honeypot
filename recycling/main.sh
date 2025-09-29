#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

CONFIG_FILE=$1

source "$CONFIG_FILE"

id=0

LOGFILE="$LOGFILE$id"

while true; do
  ./create.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  echo "[*] Monitoring MITM log for attacker interaction..."

  # Watch MITM log from the end only
  tail -F "$LOGFILE" | while read -r line; do
    if echo "$line" | grep -q "Opened shell for attacker"; then
      if timeout 600s grep -q "Attacker closed connection"; then
        break
      fi
    fi
  done

  ./recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
  LOGFILE="$LOGFILE$id"
done