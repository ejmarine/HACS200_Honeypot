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
  OUTFILE="${LOGS_FOLDER}${CONTAINER}_$(date +%m-%d-%Y_%H-%M-%S)_${RANDOM_LANGUAGE}.out"

  /home/aces/HACS200_Honeypot/recycling/create.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT" "$RANDOM_LANGUAGE"

  echo "[*] Monitoring MITM log for attacker interaction..."

  echo "[*] Starting MITM server on port $MITM_PORT..."
  # Kill any processes running on mitm port
  MITM_PIDS=$(lsof -ti tcp:"$MITM_PORT")
  if [ -n "$MITM_PIDS" ]; then
    echo "[*] Killing processes on port $MITM_PORT: $MITM_PIDS"
    kill -9 $MITM_PIDS
  fi
  # Start new screen session with MITM

  screen -S "$CONTAINER" -X quit 2>/dev/null

  screen -dmS "$CONTAINER" sh -c "node /root/honeypots/MITM/mitm/index.js $CONTAINER >> $OUTFILE 2>&1"

  echo "[*] MITM server started"

  # Initialize variables
  COMMANDS="["
  NUM_COMMANDS=0
  ATTACKER_IP=""
  CONNECT_TIME=""
  DISCONNECT_TIME=""
  DURATION=""
  LOGIN=""
  
  # Start tail in background and capture PID for cleanup
  tail -F "$OUTFILE" 2>/dev/null &
  TAIL_PID=$!
  
  echo "[*] Waiting for attacker to connect..."
  
  # First loop: Wait for attacker to connect and authenticate
  unset line;
  while true; do
    # Read with 1-second timeout
    if read -r -t 1 line <&3; then
      if echo "$line" | grep -q "Attacker connected:"; then
          ATTACKER_IP=$(echo "$line" | cut -d':' -f4 | cut -d' ' -f2)
          echo "[*] Attacker IP: $ATTACKER_IP"

      elif echo "$line" | grep -q "Adding the following credentials:"; then
          LOGIN=$(echo "$line" | cut -d':' -f4,5 | tr -d '"')
          echo "[*] Login: $LOGIN"

      elif echo "$line" | grep -q "\[LXC-Auth\] Attacker authenticated and is inside container"; then
          CONNECT_TIME=$(date)
          DURATION=$(date +%s)
          echo "[*] Attacker has authenticated and is inside the container"
          echo "[*] Starting monitoring with 10-minute timer..."
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "C09LR132PA7" "$CONTAINER - Attacker $ATTACKER_IP connected with $LOGIN" &
          break
      fi
    fi
  done 3< <(tail -F "$OUTFILE" 2>/dev/null)
  
  # Second loop: Monitor attacker activity with timers
  # Initialize timeout tracking after connection
  LOOP_START_TIME=$(date +%s)
  LAST_ACTIVITY_TIME=$(date +%s)
  
  unset line;
  while true; do
    # Read with 1-second timeout
    if read -r -t 1 line <&3; then
      # Update last activity time when we get a line
      LAST_ACTIVITY_TIME=$(date +%s)
      
      if echo "$line" | grep -q "line from reader:"; then
          COMMAND=$(echo "$line" | cut -d':' -f4)
          echo "[*] Command: $COMMAND"
          COMMANDS+="$COMMAND,"
          NUM_COMMANDS=$((NUM_COMMANDS+1))

      elif echo "$line" | grep -q "Attacker ended the shell"; then
          DISCONNECT_TIME=$(date)
          DURATION=$(( $(date +%s) - DURATION ))
          COMMANDS+="]"

          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "C09LR132PA7" "$CONTAINER - Attacker $ATTACKER_IP disconnected after $DURATION s" &
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "C09LR132PA7" "$CONTAINER - Attacker ran: $COMMANDS" &

          echo "[*] Number of commands: $NUM_COMMANDS"
          echo "[*] Commands: ${COMMANDS}"
          echo "[*] Attacker IP: $ATTACKER_IP"
          echo "[*] Connect time: $CONNECT_TIME"
          echo "[*] Disconnect time: $DISCONNECT_TIME"
          echo "[*] Duration: $DURATION"
          echo "[*] Login: $LOGIN"
          echo "#########################################" >> "$OUTFILE"
          
          /home/aces/HACS200_Honeypot/recycling/helpers/jsonify.sh "$LOGFILEPATH" "$RANDOM_LANGUAGE" "$NUM_COMMANDS" "[${COMMANDS}]" "$ATTACKER_IP" "$CONNECT_TIME" "$DISCONNECT_TIME" "$DURATION" "$CONTAINER" "$EXTERNAL_IP" "$LOGIN"
          break
      fi
    fi
    
    # Check timeout conditions on every iteration
    CURRENT_TIME=$(date +%s)
    TIME_SINCE_ACTIVITY=$((CURRENT_TIME - LAST_ACTIVITY_TIME))
    TOTAL_TIME=$((CURRENT_TIME - LOOP_START_TIME))
    
    # Check inactivity timeout (3 minutes = 180 seconds)
    if [ $TIME_SINCE_ACTIVITY -ge 180 ]; then
      echo "[*] Inactivity timeout reached (3 minutes) - breaking loop"
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "C09LR132PA7" "$CONTAINER - Inactivity timeout reached (3 minutes) - breaking loop" &
      break
    fi
    
    # Check total timeout (10 minutes = 600 seconds)
    if [ $TOTAL_TIME -ge 600 ]; then
      echo "[*] Total timeout reached (10 minutes) - breaking loop"
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "C09LR132PA7" "$CONTAINER - Total timeout reached (10 minutes) - breaking loop" &
      break
    fi
  done 3< <(tail -F "$OUTFILE" 2>/dev/null)
  
  # Clean up background tail process
  kill $TAIL_PID 2>/dev/null

  /home/aces/HACS200_Honeypot/recycling/recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done