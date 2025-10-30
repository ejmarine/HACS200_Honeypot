#!/bin/bash

read -p "Are you sure you want to clean the logs? This will delete all logs and data_zips" input

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

read -p "Are you sure you ABSOLUTELY SURE YOU WANT TO DELETE ALL LOGS AND DATA_ZIPS? This will delete all logs and data_zips" input

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

read -p "FINAL WARNING" input

if [ "$input" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

rm -rf logs/*/*.*

echo "Logs and data_zips deleted"