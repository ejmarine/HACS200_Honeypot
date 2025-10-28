#!/bin/bash

# Script to prepare a base container snapshot for fast honeypot deployment
# This snapshot will have SSH pre-installed and configured

SNAPSHOT_NAME="honeypot-snapshot"
BASE_CONTAINER="honeypot-base"

echo "[*] Preparing base container snapshot for honeypot system..."

# Check if base container already exists
if lxc list -c n --format csv | grep -q "^${BASE_CONTAINER}$"; then
  echo "[*] Base container ${BASE_CONTAINER} already exists, removing it..."
  sudo lxc stop "${BASE_CONTAINER}" --force 2>/dev/null
  sudo lxc delete "${BASE_CONTAINER}" 2>/dev/null
fi

# Create the base container
echo "[*] Creating base container ${BASE_CONTAINER}..."
sudo lxc launch ubuntu:20.04 "${BASE_CONTAINER}"

# Wait until container gets an IP (indicating it's fully started)
echo "[*] Waiting for container to initialize..."
until CONTAINER_IP=$(sudo lxc list "${BASE_CONTAINER}" -c 4 -f csv | awk '{print $1}') && [ -n "$CONTAINER_IP" ]; do
  sleep 1
done

# Install SSH server
echo "[*] Installing SSH server in base container..."
sudo lxc exec "${BASE_CONTAINER}" -- apt update >/dev/null 2>&1
sudo lxc exec "${BASE_CONTAINER}" -- apt install -y openssh-server >/dev/null 2>&1

# Configure SSH settings
echo "[*] Configuring SSH settings..."
sudo lxc exec "${BASE_CONTAINER}" -- sed -i '/^#\?PermitRootLogin/d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo lxc exec "${BASE_CONTAINER}" -- sed -i '/^#\?PasswordAuthentication/d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo lxc exec "${BASE_CONTAINER}" -- bash -c 'echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf'
sudo lxc exec "${BASE_CONTAINER}" -- bash -c 'echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf'
sudo lxc exec "${BASE_CONTAINER}" -- sed -i '/^Banner /d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Restart SSH to apply settings
sudo lxc exec "${BASE_CONTAINER}" -- systemctl restart ssh

# Stop the container before taking snapshot
echo "[*] Stopping base container..."
sudo lxc stop "${BASE_CONTAINER}"

# Delete old snapshot if it exists
if lxc info "${BASE_CONTAINER}" 2>/dev/null | grep -q "^  ${SNAPSHOT_NAME}"; then
  echo "[*] Removing old snapshot..."
  sudo lxc delete "${BASE_CONTAINER}/${SNAPSHOT_NAME}"
fi

# Create snapshot
echo "[*] Creating snapshot ${SNAPSHOT_NAME}..."
sudo lxc snapshot "${BASE_CONTAINER}" "${SNAPSHOT_NAME}"

echo "[+] Base container snapshot created successfully!"
echo "[+] Snapshot: ${BASE_CONTAINER}/${SNAPSHOT_NAME}"

