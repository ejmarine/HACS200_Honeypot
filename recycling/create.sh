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
# Remove any existing lines and add the required settings
sudo lxc exec "$CONTAINER" -- sed -i '/^#\?PermitRootLogin/d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo lxc exec "$CONTAINER" -- sed -i '/^#\?PasswordAuthentication/d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo lxc exec "$CONTAINER" -- bash -c 'echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf'
sudo lxc exec "$CONTAINER" -- bash -c 'echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf'
# Add MaxStartups 1 to the sshd_config so only one unauthenticated connection is allowed at a time
sudo lxc exec "$CONTAINER" -- sed -i '/^#\?MaxSessions/d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo lxc exec "$CONTAINER" -- bash -c 'echo "MaxSessions 1" >> /etc/ssh/sshd_config.d/60-cloudimg-settings.conf'
# Remove the Banner setting from the container's sshd_config if present
sudo lxc exec "$CONTAINER" -- sed -i '/^Banner /d' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf


# Set maximum number of logins for all users to 1
sudo lxc exec "$CONTAINER" -- bash -c "echo '* hard maxlogins 1' >> /etc/security/limits.conf"


sudo lxc exec "$CONTAINER" -- systemctl restart ssh

echo "DEBUG: Copying in banner of language $LANGUAGE"

# TODO FOR SAMUEL: CHANGE THE SSH BANNER TO THE LANGUAGE OF THE HONEYPOT
banner="/home/aces/HACS200_Honeypot/honeypot_files/banners/$LANGUAGE.txt"
cp "$banner" "/home/aces/HACS200_Honeypot/recycling/config/$CONTAINER.txt"


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
  
echo "DEBUG: Setting locale of $LANGUAGE in $CONTAINER"
# Generate and set the locale in the container
sudo lxc exec "$CONTAINER" -- locale-gen "$LOCALE"
sudo lxc exec "$CONTAINER" -- update-locale LANG="$LOCALE"
sudo lxc exec "$CONTAINER" -- bash -lc "echo 'LANG=$LOCALE' > /etc/default/locale"
# EFREM: TZ setting, could be halucinating - Teddy
sudo lxc exec "$CONTAINER" -- bash -lc "echo 'TZ=$TZ' > /etc/timezone"
sudo lxc exec "$CONTAINER" -- bash -lc "ln -sf /usr/share/zoneinfo/$TZ /etc/localtime"

# Calculate and display creation time
CREATE_END_TIME=$(date +%s)
CREATE_DURATION=$((CREATE_END_TIME - CREATE_START_TIME))

echo "[+] MITM setup complete for $CONTAINER"
echo -e "\033[95m[+] Created in $CREATE_DURATION seconds\033[0m"
