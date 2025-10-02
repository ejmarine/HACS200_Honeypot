#!/bin/bash

if [ -d "MITM" ]; then
    echo "MITM directory already exists, skipping clone."
elif ! git clone https://github.com/UMD-ACES/MITM; then
    echo "Failed to clone MITM repository"
    exit 1
fi

apt install -y npm
npm install -g forever
npm install -g pm2
chmod -r +x ./*