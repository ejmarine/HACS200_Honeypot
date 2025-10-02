#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <container_name> <external_ip> <mitm_port>"
  exit 1
fi

CONTAINER=$1
EXTERNAL_IP=$2
MITM_PORT=$3
LANGUAGE=$4

# Stop existing MITM process for this container if running
if forever list | grep -q "honeypot-$CONTAINER"; then
  forever stop "honeypot-$CONTAINER" 2>/dev/null
fi

# Kill any process still using our port just in case
PID=$(sudo lsof -t -i:"$MITM_PORT")
if [ -n "$PID" ]; then
  sudo kill -9 "$PID"
fi

# Create container if needed
if ! sudo lxc-ls | grep -qw "$CONTAINER"; then
  sudo lxc-create -n "$CONTAINER" -t download -- -d ubuntu -r focal -a amd64
fi

# Start container
sudo lxc-start -n "$CONTAINER"

# Wait until container gets an IP
until CONTAINER_IP=$(sudo lxc-info -n "$CONTAINER" -iH) && [ -n "$CONTAINER_IP" ]; do
  sleep 1
done

# Add external IP
sudo ip addr add "$EXTERNAL_IP"/16 brd + dev eth1 2>/dev/null
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

# Install SSH if need
sudo lxc-attach -n "$CONTAINER" -- apt update -y
sudo lxc-attach -n "$CONTAINER" -- apt install -y openssh-server

# Enable root login in sshd_config
sudo lxc-attach -n "$CONTAINER" -- sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo lxc-attach -n "$CONTAINER" -- systemctl restart ssh

files = "../honeypot_files/$LANGUAGE"

if [ -d "$files" ]; then
  sudo lxc-attach -n "$CONTAINER" -- mkdir -p /home/
  sudo lxc-file push "$files"/* "$CONTAINER"/root/ 2>/dev/null
else
  echo "Error: $files does not exist"
  exit 1
fi

# TODO FOR SAMUEL: CHANGE THE SSH BANNER TO THE LANGUAGE OF THE HONEYPOT
banner = "../honeypot_files/banners/$LANGUAGE.txt"
sudo lxc-attach -n "$CONTAINER" -- sed -i "s/^Banner.*$/Banner \/root\/banner.txt/" /etc/ssh/sshd_config
sudo lxc-attach -n "$CONTAINER" -- echo "$banner" > /root/banner.txt
sudo lxc-attach -n "$CONTAINER" -- systemctl restart ssh

# TODO IN GENERAL: CHANGE SYSTEM LANGUAGE TO THE LANGUAGE OF THE HONEYPOT
# Change system language inside the container to the selected language

# Map language names to locale codes
case "$LANGUAGE" in
  "English")
    LOCALE="en_US.UTF-8"
    ;;
  "Russian")
    LOCALE="ru_RU.UTF-8"
    ;;
  "Chinese")
    LOCALE="zh_CN.UTF-8"
    ;;
  "Hebrew")
    LOCALE="he_IL.UTF-8"
    ;;
  "Ukrainian")
    LOCALE="uk_UA.UTF-8"
    ;;
  "French")
    LOCALE="fr_FR.UTF-8"
    ;;
  "Spanish")
    LOCALE="es_ES.UTF-8"
    ;;
  *)
    LOCALE="en_US.UTF-8"
    ;;
esac

# Generate and set the locale in the container
sudo lxc-attach -n "$CONTAINER" -- locale-gen "$LOCALE"
sudo lxc-attach -n "$CONTAINER" -- update-locale LANG="$LOCALE"
sudo lxc-attach -n "$CONTAINER" -- bash -c "echo 'LANG=$LOCALE' > /etc/default/locale"

# Launch MITM
echo "[*] Starting MITM server on port $MITM_PORT..."
FOREVER_UID="honeypot-$CONTAINER"
sudo forever --uid "$FOREVER_UID" -a -l ~/"$CONTAINER".log start /home/student/MITM/mitm.js \
  -n "$CONTAINER" -i "$CONTAINER_IP" -p "$MITM_PORT" \
  --auto-access --auto-access-fixed 3 --debug


# Add iptables rules
sudo iptables -t nat -I POSTROUTING -s "$CONTAINER_IP" -d 0.0.0.0/0 -j SNAT --to-source "$EXTERNAL_IP"
sudo iptables -t nat -I PREROUTING -s 0.0.0.0/0 -d "$EXTERNAL_IP" -j DNAT --to-destination "$CONTAINER_IP"
sudo iptables -t nat -I PREROUTING -s 0.0.0.0/0 -d "$EXTERNAL_IP" -p tcp --dport 22 -j DNAT --to-destination 127.0.0.1:$MITM_PORT

echo "[+] MITM setup complete for $CONTAINER"
