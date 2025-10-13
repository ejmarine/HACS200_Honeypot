#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <container_name> <external_ip>"
  exit 1
fi

CONTAINER=$1
EXTERNAL_IP=$2
MITM_PORT=6010

# Get container IP (if it still exists)
CONTAINER_IP=$(sudo lxc-info -n "$CONTAINER" -iH 2>/dev/null)

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
sudo lxc-stop -n "$CONTAINER" 2>/dev/null
sudo lxc-destroy -n "$CONTAINER" 2>/dev/null

# Stop all forever processes (clean MITM & any leftovers)
forever stopall

echo "[+] Honeypot $CONTAINER has been recycled."