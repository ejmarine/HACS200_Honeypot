#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

CONFIG_FILE=$1

source "$CONFIG_FILE"

id=0

LANGUAGES=(English Russian Chinese Hebrew Ukrainian French Spanish)


# Not currently working, but trying to copy a base container to increase speed
if lxc list -c n --format csv | grep -q "base-container"; then
  sudo lxc stop "base-container"
  sudo lxc delete "base-container"
fi

# Check if the 'base' image exists; if not, create and publish it
if ! lxc image list | grep -q "base"; then
  echo "[*] Creating base container"
  sudo lxc launch ubuntu:20.04 base-container
  sudo lxc publish base-container --alias base --force
  sudo lxc stop base-container
  sudo lxc delete base-container
fi

sudo lxc profile copy default $CONTAINER
lxc profile device set $CONTAINER eth0 ipv4.address=$INTERNAL_IP


mkdir -p "$LOGS_FOLDER"

#Start honeypot loop
while true; do
  RANDOM_INDEX=$((RANDOM % ${#LANGUAGES[@]}))
  RANDOM_LANGUAGE=${LANGUAGES[$RANDOM_INDEX]}

  LOGFILEPATH="${LOGS_FOLDER}/${CONTAINER}_$(date +%m-%d-%Y_%H-%M-%S)_${RANDOM_LANGUAGE}.log"

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
    sleep 120
    break
  done

  ./recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done