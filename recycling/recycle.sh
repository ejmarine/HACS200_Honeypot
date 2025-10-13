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

# Stop MITM (forever)
forever list | grep -q "honeypot-$CONTAINER" && forever stop "honeypot-$CONTAINER"

# Remove iptables rules
if [ -n "$CONTAINER_IP" ]; then
  sudo iptables -t nat -D PREROUTING -d "$EXTERNAL_IP" -p tcp --dport 22 -j DNAT --to-destination 127.0.0.1:$MITM_PORT
  sudo iptables -t nat -D PREROUTING -d "$EXTERNAL_IP" -j DNAT --to-destination "$CONTAINER_IP"
  sudo iptables -t nat -D POSTROUTING -s "$CONTAINER_IP" -j SNAT --to-source "$EXTERNAL_IP"
fi

# Remove external IP
sudo ip addr del "$EXTERNAL_IP"/16 dev eth1 2>/dev/null

# Stop and destroy container
sudo lxc stop "$CONTAINER" --force 2>/dev/null
sudo lxc delete "$CONTAINER" 2>/dev/null

# Stop all forever processes (clean MITM & any leftovers)
forever stopall

# Calculate and display recycling time
RECYCLE_END_TIME=$(date +%s)
RECYCLE_DURATION=$((RECYCLE_END_TIME - RECYCLE_START_TIME))

echo "[+] Honeypot $CONTAINER has been recycled."
echo -e "\033[95m[+] Recycled in $RECYCLE_DURATION seconds\033[0m"