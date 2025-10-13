#!/bin/bash

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <container_name> <external_ip> <mitm_port> <language>"
  exit 1
fi

CONTAINER=$1
EXTERNAL_IP=$2
MITM_PORT=$3
LANGUAGE=$4

# Start timing the creation process
CREATE_START_TIME=$(date +%s)

# Stop existing MITM process for this container if running
if forever list | grep -q "honeypot-$CONTAINER"; then
  echo "[*] Stopping existing MITM process for $CONTAINER"
  forever stop "honeypot-$CONTAINER" 2>/dev/null
fi

# Kill any process still using our port just in case
PID=$(sudo lsof -t -i:"$MITM_PORT")
if [ -n "$PID" ]; then
  echo "[*] Killing process still using port $MITM_PORT"
  sudo kill -9 "$PID"
fi

echo "[*] Checking if container $CONTAINER exists"
if sudo lxc list -c n --format csv | grep -q "$CONTAINER"; then
  echo "[*] Container $CONTAINER already exists, removing it..."
  sudo lxc stop "$CONTAINER" --force 2>/dev/null
  sudo lxc delete "$CONTAINER" 2>/dev/null
fi
# Create container if needed (LXD)
echo "[*] Creating container $CONTAINER"
sudo lxc launch base -p $CONTAINER $CONTAINER


# Start container (safe if already running)
sudo lxc start "$CONTAINER" 2>/dev/null

# Wait until container gets an IP
until CONTAINER_IP=$(sudo lxc list "$CONTAINER" -c 4 -f csv | awk '{print $1}') && [ -n "$CONTAINER_IP" ]; do
  sleep 1
done

sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# Install SSH if need
echo "[*] Configuring SSH in $CONTAINER"
sudo lxc exec "$CONTAINER" -- apt install -y openssh-server >/dev/null 2>&1

# Enable root login in sshd_config
sudo lxc exec "$CONTAINER" -- sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo lxc exec "$CONTAINER" -- systemctl restart ssh

files="../honeypot_files/$LANGUAGE"

echo "[*] Copying honeypot files to $CONTAINER"
if [ -d "$files" ]; then
  sudo lxc exec "$CONTAINER" -- mkdir -p /home/
  sudo lxc file push "$files"/* "$CONTAINER"/root/ 2>/dev/null
else
  echo "Error: $files does not exist"
  exit 1
fi

# TODO FOR SAMUEL: CHANGE THE SSH BANNER TO THE LANGUAGE OF THE HONEYPOT
banner="../honeypot_files/banners/$LANGUAGE.txt"
echo "[*] Setting banner in $CONTAINER"
sudo lxc exec "$CONTAINER" -- sed -i "s/^Banner.*$/Banner \/root\/banner.txt/" /etc/ssh/sshd_config
sudo lxc exec "$CONTAINER" -- bash -lc "echo \"$banner\" > /root/banner.txt"
sudo lxc exec "$CONTAINER" -- systemctl restart ssh

# Correct way to set the banner
# banner_path="../honeypot_files/banners/$LANGUAGE.txt"
# if [ -f "$banner_path" ]; then
#     sudo lxc file push "$banner_path" "$CONTAINER/root/banner.txt"
#     sudo lxc exec "$CONTAINER" -- sed -i "s/^#\?Banner.*/Banner \/root\/banner.txt/" /etc/ssh/sshd_config
#     sudo lxc exec "$CONTAINER" -- systemctl restart ssh
# else
#     echo "Warning: Banner file not found at $banner_path"
# fi



# TODO IN GENERAL: CHANGE SYSTEM LANGUAGE TO THE LANGUAGE OF THE HONEYPOT
# Change system language inside the container to the selected language

# Map language names to locale codes
case "$LANGUAGE" in
  "English")
    LOCALE="en_US.UTF-8"
    TZ="America/New_York"
    ;;
  "Russian")
    LOCALE="ru_RU.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  "Chinese")
    LOCALE="zh_CN.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  "Hebrew")
    LOCALE="he_IL.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  "Ukrainian")
    LOCALE="uk_UA.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  "French")
    LOCALE="fr_FR.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  "Spanish")
    LOCALE="es_ES.UTF-8"
    TZ="Asia/Tokyo"
    ;;
  *)
    LOCALE="en_US.UTF-8"
    TZ="America/New_York"
    ;;
esac
  
echo "[*] Setting locale in $CONTAINER"
# Generate and set the locale in the container
sudo lxc exec "$CONTAINER" -- locale-gen "$LOCALE"
sudo lxc exec "$CONTAINER" -- update-locale LANG="$LOCALE"
sudo lxc exec "$CONTAINER" -- bash -lc "echo 'LANG=$LOCALE' > /etc/default/locale"
# EFREM: TZ setting, could be halucinating - Teddy
sudo lxc exec "$CONTAINER" -- bash -lc "echo 'TZ=$TZ' > /etc/timezone"
sudo lxc exec "$CONTAINER" -- bash -lc "ln -sf /usr/share/zoneinfo/$TZ /etc/localtime"

# Launch MITM
echo "[*] Starting MITM server on port $MITM_PORT..."
SCREEN_NAME="honeypot-$CONTAINER"
# Kill existing screen session if it exists
screen -S "$SCREEN_NAME" -X quit 2>/dev/null
# Start new screen session with MITM
screen -dmS $SCREEN_NAME node /root/honeypots/MITM/mitm/index.js config/$CONTAINER.js

# Calculate and display creation time
CREATE_END_TIME=$(date +%s)
CREATE_DURATION=$((CREATE_END_TIME - CREATE_START_TIME))

echo "[+] MITM setup complete for $CONTAINER"
echo -e "\033[95m[+] Created in $CREATE_DURATION seconds\033[0m"
