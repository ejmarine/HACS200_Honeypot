#!/bin/bash

if ! git clone https://github.com/UMD-ACES/MITM; then
    echo "Failed to clone MITM repository"
    exit 1
fi

apt install -y npm
npm install -g forever
npm install -g pm2
chmod -r +x ./*