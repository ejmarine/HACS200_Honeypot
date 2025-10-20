#!/bin/bash

# Script to check status of all pot services
# This script shows the current status of all pots

echo "[*] Checking status of all pot services..."
echo "=========================================="

# Function to check a specific pot
check_pot() {
    local container_name=$1
    local mitm_port=$2
    
    echo "[*] Checking $container_name (port $mitm_port):"
    
    # Check if container exists and is running
    if lxc list -c n --format csv | grep -q "^$container_name$"; then
        echo "  ✓ Container $container_name exists"
        if lxc list -c n,s --format csv | grep "^$container_name," | grep -q "RUNNING"; then
            echo "  ✓ Container $container_name is running"
        else
            echo "  ✗ Container $container_name is not running"
        fi
    else
        echo "  ✗ Container $container_name does not exist"
    fi
    
    # Check if MITM port is in use
    MITM_PIDS=$(lsof -ti tcp:"$mitm_port" 2>/dev/null)
    if [ -n "$MITM_PIDS" ]; then
        echo "  ✓ MITM server running on port $mitm_port (PID: $MITM_PIDS)"
    else
        echo "  ✗ No MITM server on port $mitm_port"
    fi
    
    # Check if screen session exists
    if screen -list | grep -q "$container_name"; then
        echo "  ✓ Screen session '$container_name' exists"
    else
        echo "  ✗ No screen session for '$container_name'"
    fi
    
    echo ""
}

# Check all pots
check_pot "pot1" "6010"
check_pot "pot2" "6011" 
check_pot "pot3" "6012"
check_pot "pot4" "6013"

echo "=========================================="
echo "[*] Summary:"
echo "  - Use 'screen -ls' to see all screen sessions"
echo "  - Use 'lxc list' to see all containers"
echo "  - Use 'lsof -i :6010-6013' to check MITM ports"
echo "  - Use '/home/aces/HACS200_Honeypot/recycling/restart_all_pots.sh' to restart all services"
