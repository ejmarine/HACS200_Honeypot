#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

CONFIG_FILE=$1

source "$CONFIG_FILE"

id=0

LANGUAGES=(English Russian Chinese Hebrew Ukrainian French Spanish)

mkdir -p "$LOGS_FOLDER"

while true; do
  RANDOM_INDEX=$((RANDOM % ${#LANGUAGES[@]}))
  RANDOM_LANGUAGE=${LANGUAGES[$RANDOM_INDEX]}

  LOGFILEPATH="${LOGS_FOLDER}/${CONTAINER}_$(date +%Y%m%d_%H%M%S)_${RANDOM_LANGUAGE}.log"

  cat RANDOM_LANGUAGE >> "$LOGFILEPATH"

  ./create.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT" "$RANDOM_LANGUAGE"

  echo "[*] Monitoring MITM log for attacker interaction..."

  # Watch MITM log from the end only
  tail -F "$LOGFILEPATH" | while read -r line; do
    if echo "$line" | grep -q "Opened shell for attacker"; then
    # ADD INACTIVE TIMEOUT
      if timeout 600s grep -q "Attacker closed connection"; then
        break
      fi
    fi
  done

  ./recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done