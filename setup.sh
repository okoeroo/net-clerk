#!/bin/bash

# Config and checks
NETSETUP="/usr/sbin/networksetup"
if [ ! -f "${NETSETUP}" ]; then
    echo "Can not find ${NETSETUP}. Reinstall MacOS or fake it better. Aborting setup."
    exit 1
fi

if [ -f "netclerk.conf" ]; then
    mv netclerk.conf{,.bak}
fi
cp netclerk.conf.default netclerk.conf
sed -i -e "s/my_default_username/$(id -n -u)/g" netclerk.conf


HAVE_CNTLM="yes"
CNTLM="/usr/local/bin/cntlm"
if [ ! -f "${CNTLM}" ]; then
    echo "Can not find ${CNTLM}. Skipping cntlm support and continuing without it. Install cntlm for automated enabling"
    HAVE_CNTLM="no"
fi
CNTLM_CONF="/usr/local/etc/cntlm.conf"
if [ ! -f "${CNTLM_CONF}" ]; then
    echo "Can not find ${CNTLM_CONF} for cntlm. Skipping cntlm support and continuing without it. Create a configuration file for cntlm first"
    HAVE_CNTLM="no"
fi



if [ -f "netclerk-ssid-work.list" ]; then
    cp netclerk-ssid-work.list{,.bak}
fi
echo "Your still to configure list with SSIDs" > netclerk-ssid-work.list

if [ -f "netclerk-ssid-home.list" ]; then
    cp netclerk-ssid-home.list{,.bak}
fi
HOMESSID=./netclerk-get-wifi-SSID.sh
echo $HOMESSID > netclerk-ssid-home.list

