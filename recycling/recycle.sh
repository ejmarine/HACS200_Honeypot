#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <container_name> <external_ip> <mitm_port>"
  exit 1
fi

CONTAINER=$1
EXTERNAL_IP=$2
MITM_PORT=$3

# Start timing the recycling process
RECYCLE_START_TIME=$(date +%s)

# Get container IP (if it still exists)
CONTAINER_IP=$(sudo lxc list "$CONTAINER" -c 4 -f csv | awk '{print $1}')

# Stop MITM (screen)
SCREEN_NAME="honeypot-$CONTAINER"
screen -S "$SCREEN_NAME" -X quit 2>/dev/null


# Stop and destroy container
sudo lxc stop "$CONTAINER" --force 2>/dev/null
sudo lxc delete "$CONTAINER" 2>/dev/null


# Calculate and display recycling time
RECYCLE_END_TIME=$(date +%s)
RECYCLE_DURATION=$((RECYCLE_END_TIME - RECYCLE_START_TIME))

echo "[+] Honeypot $CONTAINER has been recycled."
echo -e "\033[95m[+] Recycled in $RECYCLE_DURATION seconds\033[0m"