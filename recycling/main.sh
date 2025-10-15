#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

# Gain run access to scripts

chmod 766 *

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

if ! lxc profile list | grep -q "$CONTAINER"; then
  sudo lxc profile copy default $CONTAINER
else
  sudo lxc profile delete $CONTAINER
  sudo lxc profile copy default $CONTAINER
fi
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

  echo "[*] Starting MITM server on port $MITM_PORT..."
  # Kill any processes running on mitm port
  MITM_PIDS=$(lsof -ti tcp:"$MITM_PORT")
  if [ -n "$MITM_PIDS" ]; then
    echo "[*] Killing processes on port $MITM_PORT: $MITM_PIDS"
    kill -9 $MITM_PIDS
  fi
  # Start new screen session with MITM

  screen -S $CONTAINER -X quit 2>/dev/null

  screen -dmS $CONTAINER node /root/honeypots/MITM/mitm/index.js $CONTAINER >> "../logs/$CONTAINER.out"

  echo "[*] MITM server started"

  # Watch MITM log from the end only

  COMMANDS=()
  NUM_COMMANDS=0
  ATTACKER_IP=""
  CONNECT_TIME=""
  DISCONNECT_TIME=""
  DURATION=""

  tail -F "../logs/$CONTAINER.out" | while read -r line; do
    # Wait until "[LXC-Auth] Attacker authenticated and is inside container" is read
    if echo "$line" | grep -q "Attempting to connect to honeypot:"; then
      ATTACKER_IP=$(echo "$line" | cut -':' -f4)
      echo "[*] Attacker IP: $ATTACKER_IP"
    elif echo "$line" | grep -q "\[LXC-Auth\] Attacker authenticated and is inside container"; then
      echo "[*] Attacker has authenticated and is inside the container"
      CONNECT_TIME=$(date +%s)
    elif echo "$line" | grep -q "line from reader:"; then
        COMMAND=$(echo "$line" | cut -d':' -f4)
        echo "[*] Command: $COMMAND"
        COMMANDS+=("$COMMAND")
        NUM_COMMANDS=$((NUM_COMMANDS+1))
    elif echo "$line" | grep -q "Attacker ended the shell"; then
        DISCONNECT_TIME=$(date +%s)
        DURATION=$((DISCONNECT_TIME - CONNECT_TIME))
        echo "[*] Number of commands: $NUM_COMMANDS"
        echo "[*] Commands: ${COMMANDS[@]}"
        echo "[*] Attacker IP: $ATTACKER_IP"
        echo "[*] Connect time: $CONNECT_TIME"
        echo "[*] Disconnect time: $DISCONNECT_TIME"
        echo "[*] Duration: $DURATION"
        break
    fi
  done

  ./recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done