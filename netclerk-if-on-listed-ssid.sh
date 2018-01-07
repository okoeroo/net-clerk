#!/bin/bash

RUNPATH=${RUNPATH:-.}

# Check if an input file was provided
if [ -z $1 ]; then
    exit 2
fi
LISTFILE="$1"
NETWORK_DESIGNATION="$2"


SSID=$($RUNPATH/netclerk-get-wifi-SSID.sh)
cat "${LISTFILE}" | while read LINE_SSID; do 
    if [ "$SSID" = "$LINE_SSID" ]; then
        if [ -z ${NETWORK_DESIGNATION} ]; then
            echo "SSID detected: $SSID"
        else
            echo "SSID for ${NETWORK_DESIGNATION} detected: $SSID"
        fi
        exit 11
    fi
done
RC=$?

if [ $RC -eq 11 ]; then
    exit 0
else
    exit 1
fi

