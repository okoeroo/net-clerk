#!/bin/bash

LINE=$(netstat -nr | grep -num 1 "default")

if [[ $LINE == *"utun"* ]]; then
    echo "VPN is on"
    exit 0
else
    echo "VPN is off"
    exit 1
fi
