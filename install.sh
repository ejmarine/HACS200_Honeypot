#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi


if [ -d "MITM" ]; then
    echo "MITM directory already exists, skipping clone."
elif ! git clone https://github.com/UMD-ACES/MITM; then
    echo "Failed to clone MITM repository"
    exit 1
fi

apt install -y lxc lxd
apt install -y npm
apt install -y screen
npm install -g forever
npm install -g pm2
chmod -R 755 ./*

create_services_for_confs() {
  local conf_files
  conf_files=$(find . -type f -name "*.conf")
  for conf in $conf_files; do
    # Extract honeypot name: assume filename is like "potNAME.conf"
    conf_filename=$(basename "$conf")
    honeypot_name="${conf_filename%.conf}"

    service_name="honeypot-${honeypot_name}.service"
    service_path="/etc/systemd/system/${service_name}"

    if [ -f "$service_path" ]; then
      # Remove (stop and disable) existing service before (re)creating
      echo "Service $service_name already exists, removing..."
      systemctl stop "$service_name"
      systemctl disable "$service_name"
      rm -f "$service_path"
      echo "Service $service_name removed."
      continue
    fi

    # Example: edit ExecStart as needed for your application
    cat <<EOF > "$service_path"
[Unit]
Description=Honeypot $honeypot_name Service

[Service]
Type=simple
WorkingDirectory=$(pwd)/recycling
ExecStart=$(pwd)/recycling/main.sh $(pwd)/recycling/config/$honeypot_name.conf
ExecStopPost=$(pwd)/recycling/helpers/slack.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo "Created service: $service_name"
    systemctl daemon-reload
    systemctl enable "$service_name"
    systemctl start "$service_name"
    echo "Started and enabled $service_name"
  done
}

# Call the function
create_services_for_confs
