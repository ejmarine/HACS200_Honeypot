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