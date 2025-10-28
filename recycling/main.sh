#!/bin/bash

/root/honeypots/network/startup

js_files=$(find /home/aces/HACS200_Honeypot/recycling/config -type f -name "*.js")
for js in $js_files; do
  cp "$js" /root/honeypots/MITM/config/
  chmod 755 "$js"
done


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


# Check if the honeypot snapshot exists; if not, create it
if ! lxc list -c n --format csv | grep -q "^honeypot-base$"; then
  echo "[*] Base container snapshot not found, creating it..."
  /home/aces/HACS200_Honeypot/recycling/prepare_snapshot.sh
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
  /root/honeypots/network/startup
  sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT
  sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP
  unset RANDOM_INDEX
  unset RANDOM_LANGUAGE
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
  FIRST_COMMAND_TIME=""
  LAST_COMMAND_TIME=""
  IS_BOT="false"
  IS_NONINTERACTIVE="false"
  DISCONNECT_REASON=""
  
  # Start tail in background and capture PID for cleanup
  tail -F "$OUTFILE" 2>/dev/null &
  TAIL_PID=$!
  
  echo "[*] Waiting for attacker to connect..."
  
  # Merged loop: Monitor all connections from start to finish
  unset line;
  CONNECTION_STARTED=false
  LOOP_START_TIME=0
  LAST_ACTIVITY_TIME=0
  
  while true; do
    # Read with 1-second timeout
    if read -r -t 1 line <&3; then
      # Update last activity time when we get a line (only if connection started)
      if [ "$CONNECTION_STARTED" = true ]; then
        LAST_ACTIVITY_TIME=$(date +%s)
      fi

      if echo "$line" | grep -q "Attacker connected:"; then
          ATTACKER_IP=$(echo "$line" | cut -d':' -f4 | cut -d' ' -f2)
          echo "[*] Attacker IP: $ATTACKER_IP"
          # Initialize connection tracking
          CONNECTION_STARTED=true
          CONNECT_TIME=$(date)
          DURATION=$(date +%s)
          LOOP_START_TIME=$(date +%s)
          LAST_ACTIVITY_TIME=$(date +%s)
          # Only allow SSH connections from the attacker's IP to the container's IP
          sudo /sbin/iptables -I INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP
          sudo /sbin/iptables -I INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT

      elif echo "$line" | grep -q "Noninteractive mode attacker command:"; then
          IS_NONINTERACTIVE="true"
          COMMAND=$(echo "$line" | cut -d':' -f4)
          echo "[*] Command: $COMMAND"
          COMMANDS+="$COMMAND,"
          NUM_COMMANDS=$((NUM_COMMANDS+1))
          DISCONNECT_TIME=$(date)
          DURATION=$(( $(date +%s) - DURATION ))
          COMMANDS+="]"
          DISCONNECT_REASON="noninteractive"
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for noninteractive mode command" &
          break
          

      elif echo "$line" | grep -q -e "Attacker closed the connection" -e "Attacker closed connection"; then
          DISCONNECT_TIME=$(date)
          DURATION=$(( $(date +%s) - DURATION ))
          COMMANDS+="]"
          DISCONNECT_REASON="self_disconnect"
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected after $DURATION s" &
          break

      elif echo "$line" | grep -q "Adding the following credentials:"; then

          LOGIN=$(echo "$line" | cut -d':' -f4,5 | tr -d '"' | sed 's/^ *//')

          UNAME=$(echo "$LOGIN" | cut -d':' -f1)
          
          honey_files="/home/aces/HACS200_Honeypot/honeypot_files/$RANDOM_LANGUAGE/"

          echo "DEBUG: Copying honeypot files of $RANDOM_LANGUAGE to $CONTAINER"
          if [ -d "$honey_files" ]; then
            sudo lxc exec "$CONTAINER" -- mkdir -p /home/$UNAME/
            sudo lxc file push -r "$honey_files"* "$CONTAINER/home/$UNAME/" 2>/dev/null
            sudo lxc exec "$CONTAINER" -- touch "/home/$UNAME/.hushlogin"
          else
            echo "Error: $honey_files does not exist"
            exit 1
          fi

          echo "[*] Login: $LOGIN"

      elif echo "$line" | grep -q "\[LXC-Auth\] Attacker authenticated and is inside container"; then
          echo "[*] Attacker has authenticated and is inside the container"
          echo "[*] Starting monitoring with 10-minute timer..."
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP connected with $LOGIN" &
          # Add logged in user ($UNAME) to the sudo group inside the container
          echo "[*] Granting sudo privileges to user $UNAME in $CONTAINER"
          sudo lxc exec "$CONTAINER" -- usermod -aG sudo "$UNAME"
          sudo lxc exec "$CONTAINER" -- bash -c "echo '$UNAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$UNAME"
          sudo lxc exec "$CONTAINER" -- chmod 440 /etc/sudoers.d/$UNAME
          
      elif echo "$line" | grep -q "Attacker Keystroke: [TAB]"; then
          COMMANDS+="Autocompleted:"
      
      elif echo "$line" | grep -q "line from reader:"; then
          COMMAND=$(echo "$line" | cut -d':' -f4)
          echo "[*] Command: $COMMAND"
          COMMANDS+="$COMMAND,"
          NUM_COMMANDS=$((NUM_COMMANDS+1))
          
          # Track timing for first and last commands
          if [ -z "$FIRST_COMMAND_TIME" ]; then
              FIRST_COMMAND_TIME=$(date +%s)
          fi
          LAST_COMMAND_TIME=$(date +%s)
      fi
    fi
    
    # Check timeout conditions on every iteration (only if connection started)
    if [ "$CONNECTION_STARTED" = true ]; then
      CURRENT_TIME=$(date +%s)
      TIME_SINCE_ACTIVITY=$((CURRENT_TIME - LAST_ACTIVITY_TIME))
      TOTAL_TIME=$((CURRENT_TIME - LOOP_START_TIME))
      
      # Check inactivity timeout (2.5 minutes = 150 seconds)
      if [ $TIME_SINCE_ACTIVITY -ge 150 ]; then
        echo "[*] Inactivity timeout reached (2.5 minutes) - breaking loop"
        DISCONNECT_TIME=$(date)
        DURATION=$(( $(date +%s) - DURATION ))
        COMMANDS+="]"
        DISCONNECT_REASON="inactivity_timeout"
        /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for inactivity (2.5min)" &
        break
      fi
      
      # Check total timeout (10 minutes = 600 seconds)
      if [ $TOTAL_TIME -ge 600 ]; then
        echo "[*] Total timeout reached (10 minutes) - breaking loop"
        DISCONNECT_TIME=$(date)
        DURATION=$(( $(date +%s) - DURATION ))
        COMMANDS+="]"
        DISCONNECT_REASON="session_timeout"
        /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for total timeout (10min)" &
        break
      fi
    fi
  done 3< <(tail -F "$OUTFILE" 2>/dev/null)
  
  # Clean up background tail process
  kill $TAIL_PID 2>/dev/null

  # Calculate average time between commands if there are 2+ commands
  if [ $NUM_COMMANDS -ge 2 ]; then
      TOTAL_TIME_BETWEEN=$((LAST_COMMAND_TIME - FIRST_COMMAND_TIME))
      AVG_TIME=$(echo "scale=2; $TOTAL_TIME_BETWEEN / ($NUM_COMMANDS - 1)" | bc)
      
      # Flag as bot if average < 1 second
      if [ $(echo "$AVG_TIME < 1" | bc) -eq 1 ]; then
          IS_BOT="true"
      fi
  else
      AVG_TIME="N/A"
  fi

  # Remove iptables rules
  sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT
  sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP
  #sudo /sbin/iptables -D FORWARD -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport $MITM_PORT -j ACCEPT
  #sudo /sbin/iptables -D FORWARD -d 172.20.0.1 -p tcp --dport $MITM_PORT -j DROP
  # Send Slack notifications
  /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP ran: $COMMANDS" &
  
  
  if [ "$IS_BOT" = "true" ]; then
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - ⚠️ BOT DETECTED: Avg time between commands: ${AVG_TIME}s" &
  fi

  # Output session summary
  echo "[*] Number of commands: $NUM_COMMANDS"
  echo "[*] Commands: ${COMMANDS}"
  echo "[*] Attacker IP: $ATTACKER_IP"
  echo "[*] Connect time: $CONNECT_TIME"
  echo "[*] Disconnect time: $DISCONNECT_TIME"
  echo "[*] Duration: $DURATION"
  echo "[*] Login: $LOGIN"
  echo "[*] Average time between commands: $AVG_TIME seconds"
  echo "[*] Bot detected: $IS_BOT"
  echo "[*] Noninteractive mode: $IS_NONINTERACTIVE"
  echo "[*] Disconnect reason: $DISCONNECT_REASON"
  echo "#########################################" >> "$OUTFILE"
  
  # Log to JSON
  /home/aces/HACS200_Honeypot/recycling/helpers/jsonify.sh "$LOGFILEPATH" "$RANDOM_LANGUAGE" "$NUM_COMMANDS" "$COMMANDS" "$ATTACKER_IP" "$CONNECT_TIME" "$DISCONNECT_TIME" "$DURATION" "$CONTAINER" "$EXTERNAL_IP" "$LOGIN" "$AVG_TIME" "$IS_BOT" "$IS_NONINTERACTIVE" "$DISCONNECT_REASON"

  /home/aces/HACS200_Honeypot/recycling/recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"

  id=$((id+1))
done
