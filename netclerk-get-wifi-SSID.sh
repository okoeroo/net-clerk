AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport"

${AIRPORT} --getinfo | grep -E "[^B]SSID" | cut -d":" -f 2 | cut -d" " -f 2-
