#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <container_name> <external_ip> <mitm_port>"
  exit 1
fi

CONTAINER=$1
EXTERNAL_IP=$2
MITM_PORT=$3

source "/home/aces/HACS200_Honeypot/recycling/config/$CONTAINER.conf"

# Start timing the recycling process
RECYCLE_START_TIME=$(date +%s)

# Get container IP (if it still exists)
CONTAINER_IP=$(sudo lxc list "$CONTAINER" -c 4 -f csv | awk '{print $1}')




# Stop MITM (screen)
SCREEN_NAME="$CONTAINER"
screen -S "$SCREEN_NAME" -X quit 2>/dev/null

# Kill all tail processes following files in the container's logs directory
echo "[*] Cleaning up tail processes for $CONTAINER..."
# Find all tail processes and check if they're following files with this container name
for pid in $(pgrep -x tail); do
  # Get the files this tail process is following
  if lsof -p "$pid" 2>/dev/null | grep -q "/aces/HACS200_Honeypot/logs/$CONTAINER"; then
    echo "[*] Killing tail process $pid following $CONTAINER logs"
    kill -9 "$pid" 2>/dev/null
  fi
done

# Additional cleanup: use pkill as backup for any remaining tail processes
pkill -f "tail -F.*$CONTAINER" 2>/dev/null

# Stop and destroy container
sudo lxc stop "$CONTAINER" --force 2>/dev/null
sudo lxc delete "$CONTAINER" 2>/dev/null


# Calculate and display recycling time
RECYCLE_END_TIME=$(date +%s)
RECYCLE_DURATION=$((RECYCLE_END_TIME - RECYCLE_START_TIME))

echo "[+] Honeypot $CONTAINER has been recycled."
echo -e "\033[95m[+] Recycled in $RECYCLE_DURATION seconds\033[0m"