RUNPATH=${RUNPATH:-.}

# Check if an input file was provided
if [ -z $1 ]; then
    return 2
fi
LISTFILE="$1"


SSID=$($RUNPATH/get-wifi-SSID.sh)
cat "${LISTFILE}" | while read LINE_SSID; do 
    if [ "$SSID" = "$LINE_SSID" ]; then
        echo "Home Network detect: $SSID"
        exit 11
    fi
done
RC=$?

if [ $RC -eq 11 ]; then
    exit 0
else
    echo "Not at Home"
    exit 1
fi

