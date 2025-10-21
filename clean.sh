#!/bin/bash

input -m "Are you sure you want to clean the logs? This will delete all logs and data_zips"

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

input -m "Are you sure you ABSOLUTELY SURE YOU WANT TO DELETE ALL LOGS AND DATA_ZIPS? This will delete all logs and data_zips"

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

input -m "FINAL WARNING"

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

rm -rf logs/*/*.*

echo "Logs and data_zips deleted"