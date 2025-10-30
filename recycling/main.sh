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
LOCK_FILE="/home/aces/HACS200_Honeypot/recycling/helpers/create.lock"

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
  # Clean up any leftover firewall rules from previous iteration
  if [ -n "$ATTACKER_IP" ]; then
    sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT 2>/dev/null
  fi
  sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP 2>/dev/null
  unset RANDOM_INDEX
  unset RANDOM_LANGUAGE
  RANDOM_INDEX=$((RANDOM % ${#LANGUAGES[@]}))
  RANDOM_LANGUAGE=${LANGUAGES[$RANDOM_INDEX]}

  LOGFILEPATH="${LOGS_FOLDER}/${CONTAINER}_$(date +%m-%d-%Y_%H-%M-%S)_${RANDOM_LANGUAGE}.log"
  OUTFILE="${LOGS_FOLDER}${CONTAINER}_$(date +%m-%d-%Y_%H-%M-%S)_${RANDOM_LANGUAGE}.out"

  echo $CONTAINER >> "$LOCK_FILE"
  while true; do
    if head -n 1 "$LOCK_FILE" | grep -q $CONTAINER; then
      break
    elif !(head -n 1 "$LOCK_FILE" | grep -q "^pot[0-9]\+$"); then
      sed -i '/^$/d' "$LOCK_FILE"
    fi
    sleep 1
  done

  /home/aces/HACS200_Honeypot/recycling/create.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT" "$RANDOM_LANGUAGE"

  sleep 5
  
  sed -i "s/$CONTAINER//g" "$LOCK_FILE"
  
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

  # Function to escape strings for JSON
  json_escape() {
    local string="$1"
    # Escape backslashes, quotes, and other special characters
    string="${string//\\/\\\\}"  # Escape backslashes first
    string="${string//\"/\\\"}"  # Escape double quotes
    string="${string//$'\n'/\\n}"  # Escape newlines
    string="${string//$'\r'/\\r}"  # Escape carriage returns
    string="${string//$'\t'/\\t}"  # Escape tabs
    echo "$string"
  }

  # Function to extract timestamp from log line (returns: "YYYY-MM-DD HH:MM:SS.MS")
  extract_timestamp() {
    echo "$1" | awk '{print $1, $2}'
  }

  # Function to convert timestamp to milliseconds since epoch
  timestamp_to_ms() {
    local timestamp="$1"
    # Split into date, time, and milliseconds
    local date_part=$(echo "$timestamp" | cut -d' ' -f1)
    local time_part=$(echo "$timestamp" | cut -d' ' -f2 | cut -d'.' -f1)
    local ms_part=$(echo "$timestamp" | cut -d' ' -f2 | cut -d'.' -f2)
    
    # Convert to seconds since epoch, then add milliseconds
    local seconds=$(date -d "$date_part $time_part" +%s)
    local total_ms=$((seconds * 1000 + 10#$ms_part))
    echo "$total_ms"
  }

  # Function to convert timestamp to seconds since epoch (for bot detection)
  timestamp_to_seconds() {
    local timestamp="$1"
    local date_part=$(echo "$timestamp" | cut -d' ' -f1)
    local time_part=$(echo "$timestamp" | cut -d' ' -f2 | cut -d'.' -f1)
    date -d "$date_part $time_part" +%s
  }

  # Initialize variables
  COMMANDS="["
  NUM_COMMANDS=0
  ATTACKER_IP=""
  CONNECT_TIME=""
  DISCONNECT_TIME=""
  DURATION=""
  LOGIN=""
  UNAME=""
  FIRST_COMMAND_TIME=""
  LAST_COMMAND_TIME=""
  IS_BOT="false"
  IS_NONINTERACTIVE="false"
  DISCONNECT_REASON=""
  
  # Start tail in background and capture PID for cleanup
  tail -F "$OUTFILE" 2>/dev/null &
  TAIL_PID=$!
  
  echo "[*] Waiting for attacker to connect..."
  
  #############################################################################
  # LOOP 1: Wait for connection and authentication (with 30-second timeout)
  #############################################################################
  unset line;
  ATTACKER_CONNECTED=false
  CONNECTION_START_TIME=0
  AUTHENTICATED=false
  
  while true; do
    # Read with 1-second timeout
    if read -r -t 1 line <&3; then
      
      if echo "$line" | grep -q "Attacker connected:"; then
          ATTACKER_IP=$(echo "$line" | cut -d':' -f4 | cut -d' ' -f2)
          echo "[*] Attacker IP: $ATTACKER_IP"
          ATTACKER_CONNECTED=true
          CONNECTION_START_TIME=$(date +%s)
          # Only allow SSH connections from the attacker's IP to the container's IP
          sudo /sbin/iptables -I INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP
          sudo /sbin/iptables -I INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT
      
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
          AUTHENTICATED=true
          CONNECT_TIME=$(extract_timestamp "$line")
          CONNECT_TIME_MS=$(timestamp_to_ms "$CONNECT_TIME")
          DURATION_START_MS=$CONNECT_TIME_MS
          
          # Send Slack notification with LOGIN info
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP connected with $LOGIN" &
          
          # Add logged in user ($UNAME) to the sudo group inside the container
          echo "[*] Granting sudo privileges to user $UNAME in $CONTAINER"
          sudo lxc exec "$CONTAINER" -- usermod -aG sudo "$UNAME"
          sudo lxc exec "$CONTAINER" -- bash -c "echo '$UNAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$UNAME"
          sudo lxc exec "$CONTAINER" -- chmod 440 /etc/sudoers.d/$UNAME
          
          # Display only custom banner after authentication (no system info)
          echo "[*] Setting up post-authentication banner"
          sudo lxc exec "$CONTAINER" -- chmod -x /etc/update-motd.d/* 2>/dev/null || true
          sudo lxc file push "/home/aces/HACS200_Honeypot/recycling/config/$CONTAINER.txt" "$CONTAINER/etc/motd"
          
          break  # Exit Loop 1, proceed to Loop 2
      
      elif echo "$line" | grep -q -e "Attacker closed the connection" -e "Attacker closed connection"; then
          if [ "$AUTHENTICATED" = false ]; then
              echo "[*] Attacker disconnected before authentication"
              /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected pre-auth" &
              # Remove iptables rules before recycling
              if [ -n "$ATTACKER_IP" ]; then
                  sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT 2>/dev/null
                  sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP 2>/dev/null
              fi
              # Recycle and restart without logging
              /home/aces/HACS200_Honeypot/recycling/recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"
              id=$((id+1))
              continue 2  # Continue outer honeypot loop
          fi
      fi
    fi
    
    # Check for 30-second authentication timeout
    if [ "$ATTACKER_CONNECTED" = true ] && [ "$AUTHENTICATED" = false ]; then
      CURRENT_TIME=$(date +%s)
      TIME_SINCE_CONNECT=$((CURRENT_TIME - CONNECTION_START_TIME))
      
      if [ $TIME_SINCE_CONNECT -ge 30 ]; then
        echo "[*] Authentication timeout reached (30 seconds) - attacker did not authenticate"
        /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP timeout (no auth in 30s)" &
        # Remove iptables rules before recycling
        if [ -n "$ATTACKER_IP" ]; then
            sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT 2>/dev/null
            sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP 2>/dev/null
        fi
        # Recycle and restart without logging
        /home/aces/HACS200_Honeypot/recycling/recycle.sh "$CONTAINER" "$EXTERNAL_IP" "$MITM_PORT"
        id=$((id+1))
        continue 2  # Continue outer honeypot loop
      fi
    fi
  done 3< <(tail -F "$OUTFILE" 2>/dev/null)
  
  #############################################################################
  # LOOP 2: Monitor authenticated session and collect data
  #############################################################################
  echo "[*] Starting monitoring with 10-minute timer..."
  
  unset line;
  LOOP_START_TIME=$(date +%s)
  LAST_ACTIVITY_TIME=$(date +%s)
  
  while true; do
    # Read with 1-second timeout
    if read -r -t 1 line <&3; then
      # Update last activity time when we get a line
      LAST_ACTIVITY_TIME=$(date +%s)
      
      if echo "$line" | grep -q "Attacker Keystroke: [TAB]"; then
          COMMANDS+="\"Autocompleted:\","
      
      elif echo "$line" | grep -q "line from reader:"; then
          COMMAND=$(echo "$line" | cut -d':' -f4)
          echo "[*] Command: $COMMAND"
          ESCAPED_CMD=$(json_escape "$COMMAND")
          COMMANDS+="\"$ESCAPED_CMD\","
          NUM_COMMANDS=$((NUM_COMMANDS+1))
          
          # Track timing for first and last commands using log timestamps
          CMD_TIMESTAMP=$(extract_timestamp "$line")
          if [ -z "$FIRST_COMMAND_TIME" ]; then
              FIRST_COMMAND_TIME=$(timestamp_to_seconds "$CMD_TIMESTAMP")
          fi
          LAST_COMMAND_TIME=$(timestamp_to_seconds "$CMD_TIMESTAMP")
      
      elif echo "$line" | grep -q "Noninteractive mode attacker command:"; then
          IS_NONINTERACTIVE="true"
          COMMAND=$(echo "$line" | cut -d':' -f4)
          echo "[*] Command: $COMMAND"
          ESCAPED_CMD=$(json_escape "$COMMAND")
          COMMANDS+="\"$ESCAPED_CMD\","
          NUM_COMMANDS=$((NUM_COMMANDS+1))
          DISCONNECT_TIME=$(extract_timestamp "$line")
          DISCONNECT_TIME_MS=$(timestamp_to_ms "$DISCONNECT_TIME")
          DURATION=$(( DISCONNECT_TIME_MS - DURATION_START_MS ))
          COMMANDS="${COMMANDS%,}]"  # Remove trailing comma before adding ]
          DISCONNECT_REASON="noninteractive"
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for noninteractive mode command" &
          break
      
      elif echo "$line" | grep -q -e "Attacker closed the connection" -e "Attacker closed connection"; then
          DISCONNECT_TIME=$(extract_timestamp "$line")
          DISCONNECT_TIME_MS=$(timestamp_to_ms "$DISCONNECT_TIME")
          DURATION=$(( DISCONNECT_TIME_MS - DURATION_START_MS ))
          COMMANDS="${COMMANDS%,}]"  # Remove trailing comma before adding ]
          DISCONNECT_REASON="self_disconnect"
          DURATION_SEC=$(echo "scale=3; $DURATION / 1000" | bc)
          /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected after ${DURATION_SEC}s" &
          break
      fi
    fi
    
    # Check timeout conditions on every iteration
    CURRENT_TIME=$(date +%s)
    TIME_SINCE_ACTIVITY=$((CURRENT_TIME - LAST_ACTIVITY_TIME))
    TOTAL_TIME=$((CURRENT_TIME - LOOP_START_TIME))
    
    # Check inactivity timeout (2.5 minutes = 150 seconds)
    if [ $TIME_SINCE_ACTIVITY -ge 150 ]; then
      echo "[*] Inactivity timeout reached (2.5 minutes) - breaking loop"
      DISCONNECT_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')
      DISCONNECT_TIME_MS=$(date +%s%3N)
      DURATION=$(( DISCONNECT_TIME_MS - DURATION_START_MS ))
      COMMANDS="${COMMANDS%,}]"  # Remove trailing comma before adding ]
      DISCONNECT_REASON="inactivity_timeout"
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for inactivity (2.5min)" &
      break
    fi
    
    # Check total timeout (10 minutes = 600 seconds)
    if [ $TOTAL_TIME -ge 600 ]; then
      echo "[*] Total timeout reached (10 minutes) - breaking loop"
      DISCONNECT_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')
      DISCONNECT_TIME_MS=$(date +%s%3N)
      DURATION=$(( DISCONNECT_TIME_MS - DURATION_START_MS ))
      COMMANDS="${COMMANDS%,}]"  # Remove trailing comma before adding ]
      DISCONNECT_REASON="session_timeout"
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP disconnected for total timeout (10min)" &
      break
    fi
  done 3< <(tail -F "$OUTFILE" 2>/dev/null)
  
  # Clean up background tail process
  kill -9 $TAIL_PID
  pkill -f "tail -F $OUTFILE"

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
  if [ -n "$ATTACKER_IP" ]; then
      sudo /sbin/iptables -D INPUT -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j ACCEPT 2>/dev/null
      sudo /sbin/iptables -D INPUT -d 172.20.0.1 -p tcp --dport "$MITM_PORT" -j DROP 2>/dev/null
  fi
  #sudo /sbin/iptables -D FORWARD -s "$ATTACKER_IP" -d 172.20.0.1 -p tcp --dport $MITM_PORT -j ACCEPT
  #sudo /sbin/iptables -D FORWARD -d 172.20.0.1 -p tcp --dport $MITM_PORT -j DROP
  # Send Slack notifications
  /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - Attacker $ATTACKER_IP ran: $COMMANDS" &
  
  
  if [ "$IS_BOT" = "true" ]; then
      /home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "$CONTAINER" "$CONTAINER - ⚠️ BOT DETECTED: Avg time between commands: ${AVG_TIME}s" &
  fi

  # Output session summary
  DURATION_SEC=$(echo "scale=3; $DURATION / 1000" | bc)
  echo "[*] Number of commands: $NUM_COMMANDS"
  echo "[*] Commands: ${COMMANDS}"
  echo "[*] Attacker IP: $ATTACKER_IP"
  echo "[*] Connect time: $CONNECT_TIME"
  echo "[*] Disconnect time: $DISCONNECT_TIME"
  echo "[*] Duration: ${DURATION}ms (${DURATION_SEC}s)"
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
