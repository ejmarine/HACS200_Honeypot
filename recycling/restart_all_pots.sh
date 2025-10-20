#!/bin/bash

# Script to restart all pot services
# This script will stop all running pots and restart them

echo "[*] Restarting all pot services..."

# Function to stop a specific pot
stop_pot() {
    local container_name=$1
    local mitm_port=$2
    
    echo "[*] Stopping $container_name..."
    
    # Kill any processes running on the MITM port
    MITM_PIDS=$(lsof -ti tcp:"$mitm_port" 2>/dev/null)
    if [ -n "$MITM_PIDS" ]; then
        echo "[*] Killing MITM processes on port $mitm_port: $MITM_PIDS"
        kill -9 $MITM_PIDS 2>/dev/null
    fi
    
    # Quit any existing screen session for this container
    screen -S "$container_name" -X quit 2>/dev/null
    
    # Stop and delete the container if it exists
    if lxc list -c n --format csv | grep -q "^$container_name$"; then
        echo "[*] Stopping and deleting container $container_name"
        sudo lxc stop "$container_name" 2>/dev/null
        sudo lxc delete "$container_name" 2>/dev/null
    fi
}

# Function to start a specific pot
start_pot() {
    local config_file=$1
    local container_name=$(basename "$config_file" .conf)
    
    echo "[*] Starting $container_name..."
    
    # Start the main script in background
    nohup ./main.sh "$config_file" > "../logs/${container_name}/restart_$(date +%Y%m%d_%H%M%S).log" 2>&1 &
    
    echo "[*] $container_name started (PID: $!)"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[*] Working directory: $SCRIPT_DIR"

# Stop all existing pots
echo "[*] Stopping all existing pot services..."

# Stop pot1
stop_pot "pot1" "6010"

# Stop pot2  
stop_pot "pot2" "6011"

# Stop pot3
stop_pot "pot3" "6012"

# Stop pot4
stop_pot "pot4" "6013"

echo "[*] All pots stopped. Waiting 5 seconds before restarting..."
sleep 5

# Start all pots
echo "[*] Starting all pot services..."

# Start pot1
if [ -f "config/pot1.conf" ]; then
    start_pot "config/pot1.conf"
else
    echo "[!] Warning: pot1.conf not found"
fi

# Start pot2
if [ -f "config/pot2.conf" ]; then
    start_pot "config/pot2.conf"
else
    echo "[!] Warning: pot2.conf not found"
fi

# Start pot3
if [ -f "config/pot3.conf" ]; then
    start_pot "config/pot3.conf"
else
    echo "[!] Warning: pot3.conf not found"
fi

# Start pot4
if [ -f "config/pot4.conf" ]; then
    start_pot "config/pot4.conf"
else
    echo "[!] Warning: pot4.conf not found"
fi

echo "[*] All pot services restart completed!"
echo "[*] Check logs in ../logs/ directory for individual pot logs"
echo "[*] Use 'screen -ls' to see running screen sessions"
echo "[*] Use 'lsof -i :6010-6013' to check MITM ports"
