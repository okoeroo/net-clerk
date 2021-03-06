#!/bin/bash +x

RUN_MODE="normal"
if [ "$1" = "--test" ]; then
    RUN_MODE="test"
fi
if [ "$1" = "--debug" ]; then
    RUN_MODE="debug"
fi
export RUN_MODE



# Recommended not to touch
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
SCRIPT_DIR="$(cd "$( dirname "$0" )" && pwd)"
RUNPATH="${SCRIPT_DIR}"
export RUNPATH

# Custom config file
CONFIG_FILE="${RUNPATH}/netclerk.conf"
. "${CONFIG_FILE}"


# Config and checks
NETSETUP="/usr/sbin/networksetup"
if [ ! -f "${NETSETUP}" ]; then
    echo "Can not find ${NETSETUP}. Reinstall MacOS or fake it better"
    exit 1
fi

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


# Functions
check_cntlm() {
    ps auxwww | grep $(basename $CNTLM)
}

write_log() {
    if [ "$RUN_MODE" = "test" ]; then
        return 0;
    fi

    echo $* >> ${STATUS_DUMP_FILE}.tmp
    if [ "$RUN_MODE" = "debug" ]; then
        echo $*
    fi
}

flush_log() {
    # must have something to flush
    if [ -f ${STATUS_DUMP_FILE}.tmp ]; then
        mv ${STATUS_DUMP_FILE}{.tmp,}
    fi
}

write_autogen_source_file() {
if [ "$1" = "on" ]; then

# Write source-able file for .bashrc or .profile
cat > ${RUNPATH:-.}/netclerk-autogen-status.source <<EOF
# Autogenerated from netclerk.sh
export HTTP_PROXY=localhost:6565
export HTTPS_PROXY=localhost:6565
EOF

else

# Write source-able file for .bashrc or .profile
cat > ${RUNPATH:-.}/netclerk-autogen-status.source <<EOF
# Autogenerated from netclerk.sh
# Intended to be empty
EOF

fi

}


turn_proxy_on() {
    write_log "turn_proxy_on()"
    if [ "$RUN_MODE" = "test" ]; then
        echo "Skipping netsetup due to test mode"
        return 0;
    fi

    # WLAN
    RET=$(${NETSETUP} -setwebproxy       "${WLAN_SERVICE_NAME}" "${PROXY_HTTP_HOST}" "${PROXY_HTTP_PORT}")
    write_log "${RET}"
    RET=$(${NETSETUP} -setsecurewebproxy "${WLAN_SERVICE_NAME}" "${PROXY_HTTP_HOST}" "${PROXY_HTTP_PORT}")
    write_log "${RET}"

    ${NETSETUP} -setwebproxystate        "${WLAN_SERVICE_NAME}" on
    ${NETSETUP} -setsecurewebproxystate  "${WLAN_SERVICE_NAME}" on

    # LAN
    ${NETSETUP} -setwebproxy       "${LAN_SERVICE_NAME}" "${PROXY_HTTP_HOST}" "${PROXY_HTTP_PORT}"
    ${NETSETUP} -setsecurewebproxy "${LAN_SERVICE_NAME}" "${PROXY_HTTP_HOST}" "${PROXY_HTTP_PORT}"

    ${NETSETUP} -setwebproxystate        "${LAN_SERVICE_NAME}" on
    ${NETSETUP} -setsecurewebproxystate  "${LAN_SERVICE_NAME}" on

    # Set proxy on in source file for scripts and tools to source from the shell
    write_autogen_source_file on

    # Flush DNS cache
    killall -HUP mDNSResponder
}

turn_proxy_off() {
    write_log "turn_proxy_off()"
    if [ "$RUN_MODE" = "test" ]; then
        echo "Skipping netsetup due to test mode"
        return 0;
    fi

    ${NETSETUP} -setwebproxystate        "${WLAN_SERVICE_NAME}" off
    ${NETSETUP} -setsecurewebproxystate  "${WLAN_SERVICE_NAME}" off

    ${NETSETUP} -setwebproxystate        "${LAN_SERVICE_NAME}" off
    ${NETSETUP} -setsecurewebproxystate  "${LAN_SERVICE_NAME}" off

    # Set proxy on in source file for scripts and tools to source from the shell
    write_autogen_source_file off

    # Flush DNS cache
    killall -HUP mDNSResponder
}

stop_hammertime() {
    for ((i=1;i<$1;i++)); do
        echo -n "."
        sleep 0.1
    done
    echo -en "\r"
    for ((i=1;i<$1;i++)); do
        echo -n " "
    done
    echo -en "\r"
    sleep 0.1
}

run() {
    # Spot VPN to be enabled, if it is: enable proxy.
    RET=$(${RUNPATH:-.}/netclerk-if-the-vpn-active.sh)
    RC=$?
    write_log "${RET}"
    if [ $RC -eq 0 ]; then
        write_log "VPN detected, turning ON proxy"
        turn_proxy_on
        return
    fi

    # Spot work network, if it does: enable proxy.
    NETWORK_DESIGNATION="Work"
    RET=$(${RUNPATH:-.}/netclerk-if-on-listed-ssid.sh "${SSID_LIST_WORK}" "${NETWORK_DESIGNATION}")
    RC=$?
    write_log "${RET}"

    if [ $RC -eq 2 ]; then
        write_log "Error detected: no config file for if-on-listed-ssid"
        echo "Error detected: no config file for if-on-listed-ssid"
        exit 1
    elif [ $RC -eq 0 ]; then
        write_log "Office Network detected: turning ON proxy"
        turn_proxy_on
        return
    fi

    # Spot home network, if it does: disable proxy.
    NETWORK_DESIGNATION="Home"
    RET=$(${RUNPATH:-.}/netclerk-if-on-listed-ssid.sh "${SSID_LIST_HOME}" "${NETWORK_DESIGNATION}")
    RC=$?
    write_log "${RET}"

    if [ $RC -eq 2 ]; then
        write_log "Error detected: no config file for if-on-listed-ssid"
        echo "Error detected: no config file for if-on-listed-ssid"
        exit 1
    elif [ $RC -eq 0 ]; then
        write_log "Home Network detected: turning OFF proxy"
        turn_proxy_off
        return
    fi

    # All else
    write_log "Other network detected, assuming no proxy: turning OFF proxy" 
    turn_proxy_off
    return
}

deal_with_proxy_tool() {
    RET=$(pgrep cntlm)
    RC=$?
    write_log "cntlm pid ${RET}"
    if [ ${RC} -ne 0 ]; then
        write_log "Activating cntlm as $SUDO_USER"
        sudo -u $SUDO_USER screen -d -m ${CNTLM} -f -c ${CNTLM_CONF}
    fi
}

########### Main ##########
if [ "${RUN_MODE}" = "test" ]; then
    echo "Running in test mode"
    run

    # clean
    exit 0
fi
if [ "${RUN_MODE}" = "debug" ]; then
    echo "Running in debug mode"
fi


echo "Network State Executor has started as PID $$ and running as EUID ${EUID}"
if [ ${EUID} -ne 0 ]; then
    echo "-> Not running with root privileges yet, must elevate rights to control the universe..."
    sudo $0
    exit 0
fi

# stop_hammertime 17

# infinity
while true; do
    # Main func
    run

    # Keep CNTLM alive
    if [ ${HAVE_CNTLM} = "yes" ]; then
        # Check proxy active otherwise activate
        deal_with_proxy_tool
    fi

    stop_hammertime 14

    flush_log
done

