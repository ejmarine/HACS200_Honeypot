#!/bin/bash

# Optional flag: "1" means update npm and install packages
UPDATE_NPM_FLAG="$1"

SLEEP_TIME=15

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Check if update flag is set to "1"
if [ "$UPDATE_NPM_FLAG" = "0" ]; then
  echo "Updating npm and installing packages..."
  npm update -g npm
  npm install
  apt install -y lxc lxd
  apt install -y npm
  apt install -y screen
  npm install -g forever
  npm install -g pm2
  echo "npm update and package installation completed."
fi


if [ -d "MITM" ]; then
    echo "MITM directory already exists, skipping clone."
elif ! git clone https://github.com/UMD-ACES/MITM; then
    echo "Failed to clone MITM repository"
    exit 1
fi



chmod -R 755 /home/aces/HACS200_Honeypot/*

create_services_for_confs() {
  # Copy all .js files to /root/honeypots/MITM/config/
  local js_files=$(find . -type f -name "*.js")
  for js in $js_files; do
    cp "$js" /root/honeypots/MITM/config/
  done

  local conf_files
    conf_files=$(find /home/aces/HACS200_Honeypot -type f -name "*.conf")
  
  # First pass: stop and disable all existing services
  for conf in $conf_files; do
    conf_filename=$(basename "$conf")
    honeypot_name="${conf_filename%.conf}"
    service_name="honeypot-${honeypot_name}.service"
    service_path="/etc/systemd/system/${service_name}"

    if [ -f "$service_path" ]; then
      echo "Service $service_name already exists, stopping and disabling..."
      systemctl stop "$service_name"
      systemctl disable "$service_name"
      rm -f "$service_path"
      echo "Service $service_name removed."
    fi
  done
  
  # Stop all containers
  echo "[*] Stopping all existing containers..."
  for container in $(lxc list -c n --format csv | grep -v "NAME" | grep -v "^$"); do
    if [ -n "$container" ]; then
      echo "[*] Stopping container: $container"
      lxc stop "$container" --force 2>/dev/null || true
    fi
  done

  # Delete all containers
  echo "[*] Deleting all existing containers..."
  for container in $(lxc list -c n --format csv | grep -v "NAME" | grep -v "^$"); do
    if [ -n "$container" ]; then
      echo "[*] Deleting container: $container"
      lxc delete "$container" --force 2>/dev/null || true
    fi
  done
  
  echo "[*] All services stopped and containers deleted."
  echo "[*] Recreating services and containers..."
  
  # Second pass: recreate all services
  for conf in $conf_files; do
    # Extract honeypot name: assume filename is like "potNAME.conf"
    conf_filename=$(basename "$conf")
    honeypot_name="${conf_filename%.conf}"

    service_name="honeypot-${honeypot_name}.service"
    service_path="/etc/systemd/system/${service_name}"

    # Example: edit ExecStart as needed for your application
    cat <<EOF > "$service_path"
[Unit]
Description=Honeypot $honeypot_name Service

[Service]
Type=simple
WorkingDirectory=/home/aces/HACS200_Honeypot/recycling
ExecStartPre=/bin/sleep $SLEEP_TIME
ExecStartPre=/home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "all" "$honeypot_name - Starting Service"
ExecStart=/home/aces/HACS200_Honeypot/recycling/main.sh /home/aces/HACS200_Honeypot/recycling/config/$honeypot_name.conf
ExecStopPost=/home/aces/HACS200_Honeypot/recycling/helpers/slack.sh "all" "$honeypot_name - ERROR: Service Stopped"
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

    echo "Created service: $service_name"
    systemctl daemon-reload
    systemctl enable "$service_name"
    systemctl start "$service_name"
    echo "Started and enabled $service_name"
    sleep 15
    SLEEP_TIME=$((SLEEP_TIME + 15))
  done
}

# Call the function
create_services_for_confs
