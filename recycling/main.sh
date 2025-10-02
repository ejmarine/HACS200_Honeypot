#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

CONFIG_FILE=$1

source "$CONFIG_FILE"

id=0

LANGUAGES=(English Russian Chinese Hebrew Ukrainian French Spanish)


echo "[*] Creating base container"
sudo lxc launch ubuntu:20.04 "base container"

mkdir -p "$LOGS_FOLDER"

while true; do
  RANDOM_INDEX=$((RANDOM % ${#LANGUAGES[@]}))
  RANDOM_LANGUAGE=${LANGUAGES[$RANDOM_INDEX]}

  LOGFILEPATH="${LOGS_FOLDER}/${CONTAINER}_$(date +%m-%d-%Y_%H:%M:%S)_${RANDOM_LANGUAGE}.log"

  echo "$RANDOM_LANGUAGE" >> "$LOGFILEPATH"

  ./create.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT" "$RANDOM_LANGUAGE"

  echo "[*] Monitoring MITM log for attacker interaction..."

  # Watch MITM log from the end only
  tail -F "$LOGFILEPATH" | while read -r line; do
    #if echo "$line" | grep -q "Opened shell for attacker"; then
    # ADD INACTIVE TIMEOUT
      #if timeout 600s grep -q "Attacker closed connection"; then
      #  break
      #fi
      
    #fi
    echo "[*] Testing the recycle.sh script after 1 minute..."
    sleep 60
    break
  done

  ./recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done